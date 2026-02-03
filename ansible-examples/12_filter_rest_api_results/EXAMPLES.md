# Additional Examples - REST API Filtering

This document contains additional real-world examples and use cases for filtering REST API results in Ansible.

## Table of Contents

- [CI/CD Integration](#cicd-integration)
- [Multi-Environment Deployments](#multi-environment-deployments)
- [Credential Rotation](#credential-rotation)
- [Security Auditing](#security-auditing)
- [Cost Management](#cost-management)
- [Disaster Recovery](#disaster-recovery)
- [Multi-Cloud Scenarios](#multi-cloud-scenarios)

---

## CI/CD Integration

### Example 1: Filter Credentials in GitLab CI

```yaml
---
- name: Get S3 credentials for CI/CD pipeline
  hosts: localhost
  gather_facts: no
  vars:
    api_endpoint: "{{ lookup('env', 'S3_API_ENDPOINT') }}"
    api_token: "{{ lookup('env', 'API_TOKEN') }}"
    ci_environment: "{{ lookup('env', 'CI_ENVIRONMENT_NAME') }}"  # staging, production
    ci_project: "{{ lookup('env', 'CI_PROJECT_NAME') }}"

  tasks:
    - name: Fetch S3 credentials from API
      ansible.builtin.uri:
        url: "{{ api_endpoint }}"
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      register: s3_api

    - name: Filter credentials for this project and environment
      ansible.builtin.set_fact:
        project_creds: >-
          {{
            s3_api.json.credentials |
            selectattr('bucket_name', 'equalto', ci_environment + '-' + ci_project + '-data') |
            first
          }}

    - name: Export credentials for next CI stages
      ansible.builtin.copy:
        content: |
          export AWS_ACCESS_KEY_ID="{{ project_creds.access_key }}"
          export AWS_SECRET_ACCESS_KEY="{{ project_creds.secret_key }}"
          export AWS_DEFAULT_REGION="{{ project_creds.region }}"
          export S3_BUCKET="{{ project_creds.bucket_name }}"
        dest: "{{ lookup('env', 'CI_PROJECT_DIR') }}/s3_credentials.env"
        mode: '0600'

    - name: Create Kubernetes secret manifest
      ansible.builtin.copy:
        content: |
          apiVersion: v1
          kind: Secret
          metadata:
            name: s3-credentials
            namespace: {{ ci_project }}
          type: Opaque
          stringData:
            access-key: {{ project_creds.access_key }}
            secret-key: {{ project_creds.secret_key }}
            bucket-name: {{ project_creds.bucket_name }}
            region: {{ project_creds.region }}
        dest: "{{ lookup('env', 'CI_PROJECT_DIR') }}/k8s-s3-secret.yaml"
```

### Example 2: Jenkins Pipeline Integration

```yaml
---
- name: Prepare S3 credentials for Jenkins job
  hosts: localhost
  gather_facts: no
  vars:
    jenkins_job_name: "{{ job_name }}"
    build_environment: "{{ build_env | default('staging') }}"

  tasks:
    - name: Get all S3 credentials
      ansible.builtin.uri:
        url: "https://api.example.com/s3-credentials"
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      register: credentials_api

    - name: Filter for Jenkins artifacts bucket
      ansible.builtin.set_fact:
        jenkins_s3: >-
          {{
            credentials_api.json |
            selectattr('bucket_name', 'equalto', build_environment + '-jenkins-artifacts') |
            first
          }}

    - name: Write credentials to Jenkins workspace
      ansible.builtin.template:
        src: aws_credentials.j2
        dest: "{{ workspace }}/aws_credentials"
        mode: '0600'
      vars:
        workspace: "{{ lookup('env', 'WORKSPACE') }}"
```

---

## Multi-Environment Deployments

### Example 3: Deploy Different Credentials to Different Environments

```yaml
---
- name: Deploy environment-specific S3 credentials
  hosts: all
  vars:
    s3_api_url: "https://api.example.com/s3-credentials"
    
  tasks:
    - name: Fetch all S3 credentials
      ansible.builtin.uri:
        url: "{{ s3_api_url }}"
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      delegate_to: localhost
      run_once: true
      register: all_s3_creds

    - name: Filter credentials by inventory group
      ansible.builtin.set_fact:
        env_credentials: >-
          {{
            all_s3_creds.json.credentials |
            selectattr('bucket_name', 'search', '^' + group_names[0] + '-') |
            list
          }}

    - name: Deploy credentials to application servers
      ansible.builtin.template:
        src: s3_config.ini.j2
        dest: /etc/myapp/s3_config.ini
        owner: myapp
        group: myapp
        mode: '0600'
      vars:
        app_bucket: "{{ env_credentials | selectattr('bucket_name', 'search', 'app-data') | first }}"
        log_bucket: "{{ env_credentials | selectattr('bucket_name', 'search', 'app-logs') | first }}"
```

### Example 4: Blue-Green Deployment with Separate S3 Buckets

```yaml
---
- name: Blue-Green deployment with filtered S3 credentials
  hosts: localhost
  vars:
    deployment_color: "{{ color | default('blue') }}"  # blue or green
    
  tasks:
    - name: Get S3 credentials
      ansible.builtin.uri:
        url: "https://api.example.com/s3-credentials"
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      register: s3_response

    - name: Filter for active deployment bucket
      ansible.builtin.set_fact:
        active_bucket_creds: >-
          {{
            s3_response.json.credentials |
            selectattr('bucket_name', 'equalto', 'prod-' + deployment_color + '-data') |
            first
          }}

    - name: Configure application with active bucket
      ansible.builtin.debug:
        msg: "Deploying with {{ deployment_color }} bucket: {{ active_bucket_creds.bucket_name }}"
```

---

## Credential Rotation

### Example 5: Rotate and Update Old Credentials

```yaml
---
- name: Identify and rotate old S3 credentials
  hosts: localhost
  vars:
    rotation_threshold_days: 90
    
  tasks:
    - name: Get all S3 credentials with metadata
      ansible.builtin.uri:
        url: "https://api.example.com/s3-credentials/detailed"
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      register: s3_detailed

    - name: Calculate credential age
      ansible.builtin.set_fact:
        credentials_with_age: >-
          {{
            s3_detailed.json.credentials |
            map('combine', {
              'age_days': (
                (ansible_date_time.epoch | int) -
                (item.last_rotated | to_datetime('%Y-%m-%d')).strftime('%s') | int
              ) / 86400 | int
            })
          }}
      loop: "{{ s3_detailed.json.credentials }}"

    - name: Filter credentials needing rotation
      ansible.builtin.set_fact:
        rotation_needed: >-
          {{
            credentials_with_age |
            json_query('[?age_days>`' + (rotation_threshold_days | string) + '`]')
          }}

    - name: Display credentials for rotation
      ansible.builtin.debug:
        msg:
          - "Credentials requiring rotation:"
          - "{{ rotation_needed | map(attribute='bucket_name') | list }}"

    - name: Trigger rotation via API
      ansible.builtin.uri:
        url: "https://api.example.com/s3-credentials/rotate"
        method: POST
        headers:
          Authorization: "Bearer {{ api_token }}"
        body_format: json
        body:
          bucket_name: "{{ item.bucket_name }}"
      loop: "{{ rotation_needed }}"
      register: rotation_results
```

### Example 6: Update Application Servers After Rotation

```yaml
---
- name: Update applications with newly rotated credentials
  hosts: app_servers
  vars:
    rotated_buckets: "{{ rotation_results.results | map(attribute='json.bucket_name') | list }}"
    
  tasks:
    - name: Fetch updated credentials
      ansible.builtin.uri:
        url: "https://api.example.com/s3-credentials"
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      delegate_to: localhost
      run_once: true
      register: updated_creds

    - name: Filter only rotated credentials
      ansible.builtin.set_fact:
        my_rotated_creds: >-
          {{
            updated_creds.json.credentials |
            selectattr('bucket_name', 'in', rotated_buckets) |
            list
          }}

    - name: Update application configuration
      ansible.builtin.template:
        src: s3_config.j2
        dest: /etc/myapp/s3_config.ini
        owner: myapp
        mode: '0600'
      notify: restart application
```

---

## Security Auditing

### Example 7: Audit Bucket Access and Generate Report

```yaml
---
- name: Security audit of S3 bucket access
  hosts: localhost
  gather_facts: yes
  
  tasks:
    - name: Fetch all S3 credentials and access logs
      ansible.builtin.uri:
        url: "https://api.example.com/s3-credentials/audit"
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      register: audit_data

    - name: Filter production buckets
      ansible.builtin.set_fact:
        prod_buckets: >-
          {{
            audit_data.json.credentials |
            selectattr('metadata.tags.environment', 'equalto', 'production') |
            list
          }}

    - name: Identify unencrypted production buckets
      ansible.builtin.set_fact:
        security_violations: >-
          {{
            prod_buckets |
            rejectattr('metadata.compliance.encrypted', 'equalto', true) |
            list
          }}

    - name: Identify buckets without MFA delete
      ansible.builtin.set_fact:
        mfa_violations: >-
          {{
            prod_buckets |
            rejectattr('metadata.security.mfa_delete', 'equalto', true) |
            list
          }}

    - name: Generate security audit report
      ansible.builtin.copy:
        content: |
          # S3 Security Audit Report
          
          **Date:** {{ ansible_date_time.iso8601 }}
          **Auditor:** Ansible Automation
          
          ## Summary
          
          - Total production buckets: {{ prod_buckets | length }}
          - Unencrypted buckets: {{ security_violations | length }}
          - Buckets without MFA delete: {{ mfa_violations | length }}
          
          ## Unencrypted Buckets (CRITICAL)
          
          {% for bucket in security_violations %}
          ### {{ bucket.bucket_name }}
          - **Owner:** {{ bucket.metadata.owner }}
          - **Region:** {{ bucket.region }}
          - **Action Required:** Enable encryption
          
          {% endfor %}
          
          ## MFA Delete Not Enabled (HIGH)
          
          {% for bucket in mfa_violations %}
          - {{ bucket.bucket_name }} (Owner: {{ bucket.metadata.owner }})
          {% endfor %}
          
        dest: "/tmp/s3_security_audit_{{ ansible_date_time.date }}.md"

    - name: Send alert if violations found
      ansible.builtin.debug:
        msg: "ALERT: {{ security_violations | length }} security violations found!"
      when: security_violations | length > 0
```

### Example 8: Check for Overly Permissive Access

```yaml
---
- name: Audit bucket access permissions
  hosts: localhost
  
  tasks:
    - name: Get bucket credentials with access metadata
      ansible.builtin.uri:
        url: "https://api.example.com/s3-credentials/permissions"
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      register: permissions_data

    - name: Filter buckets with public access
      ansible.builtin.set_fact:
        public_buckets: >-
          {{
            permissions_data.json.credentials |
            selectattr('metadata.access.public_read', 'equalto', true) |
            list +
            permissions_data.json.credentials |
            selectattr('metadata.access.public_write', 'equalto', true) |
            list |
            unique
          }}

    - name: Filter production buckets with wildcard access
      ansible.builtin.set_fact:
        wildcard_access: >-
          {{
            permissions_data.json.credentials |
            selectattr('metadata.tags.environment', 'equalto', 'production') |
            json_query('[?metadata.access.principal==`*`]')
          }}

    - name: Generate permissions audit
      ansible.builtin.debug:
        msg:
          - "PUBLIC ACCESS BUCKETS: {{ public_buckets | map(attribute='bucket_name') | list }}"
          - "WILDCARD PRINCIPAL (PROD): {{ wildcard_access | map(attribute='bucket_name') | list }}"
```

---

## Cost Management

### Example 9: Identify Expensive Storage and Optimize

```yaml
---
- name: Cost analysis and optimization for S3 buckets
  hosts: localhost
  
  tasks:
    - name: Fetch bucket costs and storage metrics
      ansible.builtin.uri:
        url: "https://api.example.com/s3-credentials/costs"
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      register: cost_data

    - name: Filter expensive buckets (>$100/month)
      ansible.builtin.set_fact:
        expensive_buckets: >-
          {{
            cost_data.json.credentials |
            json_query('[?metadata.cost.monthly_cost_usd>`100`]') |
            sort(attribute='metadata.cost.monthly_cost_usd', reverse=true)
          }}

    - name: Filter non-production expensive buckets
      ansible.builtin.set_fact:
        optimization_targets: >-
          {{
            expensive_buckets |
            rejectattr('metadata.tags.environment', 'equalto', 'production') |
            list
          }}

    - name: Generate cost optimization report
      ansible.builtin.copy:
        content: |
          # S3 Cost Optimization Report
          
          ## Expensive Non-Production Buckets
          
          Total potential monthly savings: ${{ optimization_targets | map(attribute='metadata.cost.monthly_cost_usd') | sum }}
          
          {% for bucket in optimization_targets %}
          ### {{ bucket.bucket_name }}
          - **Environment:** {{ bucket.metadata.tags.environment }}
          - **Monthly Cost:** ${{ bucket.metadata.cost.monthly_cost_usd }}
          - **Storage:** {{ bucket.metadata.size_gb }}GB
          - **Recommendation:** {% if bucket.metadata.tags.environment == 'development' %}Delete after 30 days{% else %}Move to Glacier{% endif %}
          
          {% endfor %}
        dest: "/tmp/s3_cost_optimization_{{ ansible_date_time.date }}.md"
```

---

## Disaster Recovery

### Example 10: Verify Backup Bucket Configuration

```yaml
---
- name: Verify S3 backup and disaster recovery configuration
  hosts: localhost
  
  tasks:
    - name: Get all S3 bucket configurations
      ansible.builtin.uri:
        url: "https://api.example.com/s3-credentials/backup-config"
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      register: backup_config

    - name: Filter production data buckets
      ansible.builtin.set_fact:
        prod_data_buckets: >-
          {{
            backup_config.json.credentials |
            selectattr('metadata.tags.environment', 'equalto', 'production') |
            selectattr('bucket_name', 'search', '-data$') |
            list
          }}

    - name: Verify backup configuration for each
      ansible.builtin.set_fact:
        backup_issues: >-
          {{
            prod_data_buckets |
            rejectattr('metadata.backup.enabled', 'equalto', true) |
            list +
            prod_data_buckets |
            selectattr('metadata.backup.enabled', 'equalto', true) |
            rejectattr('metadata.backup.cross_region', 'equalto', true) |
            list
          }}

    - name: Report backup configuration issues
      ansible.builtin.debug:
        msg:
          - "DISASTER RECOVERY ISSUES:"
          - "Buckets without backup: {{ backup_issues | selectattr('metadata.backup.enabled', 'undefined') | map(attribute='bucket_name') | list }}"
          - "Buckets without cross-region backup: {{ backup_issues | selectattr('metadata.backup.cross_region', 'equalto', false) | map(attribute='bucket_name') | list }}"
      when: backup_issues | length > 0
```

---

## Multi-Cloud Scenarios

### Example 11: Filter Credentials Across Multiple Cloud Providers

```yaml
---
- name: Manage multi-cloud object storage credentials
  hosts: localhost
  vars:
    cloud_provider: "{{ provider | default('aws') }}"  # aws, gcp, azure
    
  tasks:
    - name: Fetch all cloud storage credentials
      ansible.builtin.uri:
        url: "https://api.example.com/cloud-storage/credentials"
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      register: all_cloud_creds

    - name: Filter by cloud provider
      ansible.builtin.set_fact:
        provider_creds: >-
          {{
            all_cloud_creds.json.credentials |
            selectattr('provider', 'equalto', cloud_provider) |
            list
          }}

    - name: Further filter by region and environment
      ansible.builtin.set_fact:
        regional_prod_creds: >-
          {{
            provider_creds |
            selectattr('metadata.environment', 'equalto', 'production') |
            selectattr('region', 'search', '^us-') |
            list
          }}

    - name: Display multi-cloud summary
      ansible.builtin.debug:
        msg:
          - "Provider: {{ cloud_provider }}"
          - "Total credentials: {{ provider_creds | length }}"
          - "Production US credentials: {{ regional_prod_creds | length }}"
          - "Buckets: {{ regional_prod_creds | map(attribute='bucket_name') | list }}"
```

---

## See Also

- [README.md](README.md) - Complete documentation
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Filter syntax reference
- Example playbooks:
  - `simple_filter.yml`
  - `filter_patterns.yml`
  - `practical_example.yml`
  - `advanced_filters.yml`

