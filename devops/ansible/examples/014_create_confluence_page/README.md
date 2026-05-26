# 014 — Create a Confluence Page from an Ansible Playbook

Publish structured content to Confluence using the REST API — no extra
collections required, only `ansible.builtin.uri` which ships with Ansible core.

The primary use case is **creating a permanent record of validations
orchestrated by an Ansible play**: which checks ran, which hosts were targeted,
and what the outcome was, all stamped with a timestamp and published
automatically at the end of the play.

---

## Use Cases

- Permanent validation records (post-deployment, post-patching, compliance runs)
- Change-management evidence tied to a specific playbook execution
- Automated runbook output published into a team space
- Incident response timelines written from play tasks

---

## Quick Start

```bash
cd ansible/examples/014_create_confluence_page

# Option A — credentials from an encrypted vars file (recommended)
cp vault.example.yml vault.yml
# Edit vault.yml with real values
ansible-vault encrypt vault.yml

ansible-playbook playbook.yml \
  -e @vault.yml \
  -e confluence_base_url=https://yourorg.atlassian.net \
  -e confluence_space_key=OPS \
  --ask-vault-pass

# Option B — start with the minimal example
ansible-playbook simple_playbook.yml \
  -e confluence_base_url=https://yourorg.atlassian.net \
  -e confluence_username=you@example.com \
  -e confluence_api_token=ATATT... \
  -e confluence_space_key=OPS
```

---

## Files

| File | Purpose |
|---|---|
| `simple_playbook.yml` | Minimal example — create a page with static content |
| `playbook.yml` | Full example — run validations, compose a results table, create or update a page |
| `vault.example.yml` | Credential template (copy to `vault.yml` and encrypt) |

---

## Authentication

### Confluence Cloud

Use your Atlassian **account email** as the username and an **API token** as the
password. Passwords are not accepted for API access on Cloud.

Generate a token at:
`https://id.atlassian.com/manage-profile/security/api-tokens`

### Confluence Data Center / Server

Use either:
- **Username + password** (basic auth)
- **Username + Personal Access Token (PAT)** as the password field — preferred

Generate a PAT at:
`Profile → Personal Access Tokens` (Confluence 7.9+ / Data Center)

Both authentication methods use the same variable names:

```yaml
vault_confluence_username: "svc-ansible"
vault_confluence_api_token: "<token-or-password>"
```

---

## Variables Reference

| Variable | Default | Description |
|---|---|---|
| `confluence_base_url` | `https://yourorg.atlassian.net` | Base URL (no trailing slash) |
| `confluence_username` | `{{ vault_confluence_username }}` | Email (Cloud) or username |
| `confluence_api_token` | `{{ vault_confluence_api_token }}` | API token or PAT |
| `confluence_validate_certs` | `true` | TLS certificate validation |
| `confluence_space_key` | `OPS` | Target Confluence space key |
| `confluence_page_title` | `Validation Record — <date>` | Page title (used as idempotency key) |
| `confluence_parent_page_id` | `""` | Parent page ID (empty = space root) |
| `confluence_page_body` | *(composed by tasks)* | Page content in Storage Format |

---

## How the Idempotency Works

The playbook checks whether a page with the given title already exists in the
space before writing. On the first run it creates the page; on subsequent runs
it updates it (incrementing the Confluence version number). The title is the
idempotency key — if you change it, a new page is created.

```
GET /wiki/rest/api/content?title=<title>&spaceKey=<key>
       │
       ├── 0 results → POST /wiki/rest/api/content       (create)
       └── 1 result  → PUT  /wiki/rest/api/content/<id>  (update, version+1)
```

---

## Page Content Format

Confluence uses its own **Storage Format** — an XHTML dialect. Key elements:

```xml
<!-- Plain text and headings -->
<h2>Section Title</h2>
<p>Paragraph text.</p>
<code>inline code</code>

<!-- Table -->
<table>
  <tbody>
    <tr><th>Column A</th><th>Column B</th></tr>
    <tr><td>Value 1</td><td>Value 2</td></tr>
  </tbody>
</table>

<!-- Confluence macro: info box -->
<ac:structured-macro ac:name="info">
  <ac:rich-text-body><p>This is an info box.</p></ac:rich-text-body>
</ac:structured-macro>

<!-- Confluence macro: warning box -->
<ac:structured-macro ac:name="warning">
  <ac:rich-text-body><p>Something needs attention.</p></ac:rich-text-body>
</ac:structured-macro>

<!-- Confluence macro: code block -->
<ac:structured-macro ac:name="code">
  <ac:parameter ac:name="language">bash</ac:parameter>
  <ac:plain-text-body><![CDATA[echo "hello"]]></ac:plain-text-body>
</ac:structured-macro>
```

Ansible Jinja2 templating (`{% for %}`, `{{ var }}`) works inside the body
string because it is evaluated before the REST call is made.

---

## Building a Validation Record

The full `playbook.yml` shows this pattern:

1. **Run checks** — use real tasks that register results
2. **Aggregate** — build a `validation_results` list with `name`, `host`, `result`, `detail`
3. **Compose body** — use a Jinja2 template in `set_fact` to build the HTML table
4. **Publish** — POST or PUT to the Confluence API

To wire in real validation tasks, replace the stub `set_fact` in Phase 1 with
your actual checks. Then populate `validation_results` from the registered
output:

```yaml
- name: Check service health
  ansible.builtin.uri:
    url: "http://{{ item }}/healthz"
    status_code: 200
  loop: "{{ target_hosts }}"
  register: health_check_results
  ignore_errors: true

- name: Build validation results list
  ansible.builtin.set_fact:
    validation_results: >-
      {{
        validation_results | default([]) + [{
          'name': 'Service health endpoint',
          'host': item.item,
          'result': 'PASS' if item.status == 200 else 'FAIL',
          'detail': 'HTTP ' ~ item.status | default('no response')
        }]
      }}
  loop: "{{ health_check_results.results }}"
```

---

## Nesting Pages Under a Parent

Set `confluence_parent_page_id` to the numeric ID of the parent page.
To find a page's ID, open it in Confluence and check the URL:
`/wiki/spaces/OPS/pages/123456789/My+Page` → ID is `123456789`.

Alternatively, look it up via the API:

```bash
curl -u you@example.com:ATATT... \
  "https://yourorg.atlassian.net/wiki/rest/api/content?title=My+Parent+Page&spaceKey=OPS" \
  | python3 -m json.tool | grep '"id"'
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| HTTP 401 Unauthorized | Wrong credentials | For Cloud, use email + API token (not password) |
| HTTP 403 Forbidden | Account lacks space permission | Grant "Add Pages" permission in Space Permissions |
| HTTP 404 on POST | Wrong base URL or path | Confirm `confluence_base_url` ends without `/wiki` |
| HTTP 400 on body | Malformed Storage Format XML | Validate body with an [online XML linter](https://xmllint.com) |
| Page created at wrong location | Parent ID wrong or missing | Verify parent ID with the API lookup above |
| Duplicate pages created | Title changed between runs | Keep `confluence_page_title` stable for idempotency |
| `SSL: CERTIFICATE_VERIFY_FAILED` | Self-signed cert (Server) | Set `confluence_validate_certs: false` for internal instances |

### Test your credentials manually

```bash
# Cloud
curl -u you@example.com:ATATT... \
  "https://yourorg.atlassian.net/wiki/rest/api/space" \
  | python3 -m json.tool

# Server / Data Center
curl -u username:token \
  "https://confluence.example.com/rest/api/space" \
  | python3 -m json.tool
```

A successful response lists accessible spaces. A `401` or `403` confirms a
credential or permission issue.

---

## API Reference

- [Confluence Cloud REST API](https://developer.atlassian.com/cloud/confluence/rest/v1/intro/)
- [Confluence Server REST API](https://developer.atlassian.com/server/confluence/confluence-rest-api-examples/)
- [Storage Format reference](https://confluence.atlassian.com/doc/confluence-storage-format-790796544.html)
- [Structured macro list](https://confluence.atlassian.com/doc/macros-139387.html)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
