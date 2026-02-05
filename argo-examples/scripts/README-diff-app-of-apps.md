# ArgoCD App of Apps - Offline Diff Generator

Generate comprehensive diffs for ArgoCD App of Apps pattern without cluster connectivity.

## Overview

This script compares two git revisions and generates diffs for:
- **Parent App**: Changes to Application CRD definitions
- **Child Apps**: Changes to actual Kubernetes resources deployed by each child app

Perfect for release preparation, PR reviews, and change validation.

## Prerequisites

**Required:**
- `helm` (v3+)
- `git`

**Highly Recommended:**
- `yq` (v4+) - **Required for multiple sources support** ([install guide](https://github.com/mikefarah/yq))
  - Without `yq`, the script falls back to basic parsing that only supports single source applications

## Usage

```bash
./diff-app-of-apps.sh <old-revision> <new-revision> [environment]
```

### Parameters

- `old-revision`: Base git revision (tag, branch, or commit)
- `new-revision`: Target git revision to compare against
- `environment`: Environment name (default: `production`)
  - Must match your values file: `values-{environment}.yaml`

### Examples

```bash
# Compare two release tags
./diff-app-of-apps.sh v1.2.3 v1.2.4 production

# Compare branch to current working directory
./diff-app-of-apps.sh main HEAD staging

# Compare main to feature branch
./diff-app-of-apps.sh main feature/add-monitoring development
```

## How It Works

### Step 1: Extract Charts
Extracts the parent Helm chart from both git revisions using `git archive`.

### Step 2: Render Parent
Renders the parent Helm chart to generate Application CRD manifests for both revisions.

### Step 3: Extract Child Apps
Parses the Application CRDs to identify all child applications and their configurations.

**Supports both:**
- Single source (`spec.source`) - Traditional format
- Multiple sources (`spec.sources`) - ArgoCD v2.6+

### Step 4: Render Children
For each child app:
- Detects single vs multiple sources
- For single source apps:
  - Detects if it's a Helm chart or plain YAML
  - Extracts from the appropriate git revision
  - Renders manifests
- For multiple source apps:
  - Extracts all sources from git
  - Identifies chart source and values sources
  - Combines sources and renders with all values files

### Step 5: Generate Diffs
Creates unified diffs showing:
- Changes to Application CRD definitions (parent)
- Changes to Kubernetes resources (children)
- Notes which apps use multiple sources

## Output

The script generates organized artifacts in `/tmp/argocd-app-of-apps-diff-{PID}/`:

```
/tmp/argocd-app-of-apps-diff-12345/
├── old/
│   ├── parent/
│   │   ├── applications.yaml        # Application CRDs (old)
│   │   └── child-apps.list          # Extracted child app list
│   └── children/
│       ├── app1.yaml                # Rendered manifests (old)
│       ├── app2.yaml
│       └── ...
├── new/
│   ├── parent/
│   │   ├── applications.yaml        # Application CRDs (new)
│   │   └── child-apps.list
│   └── children/
│       ├── app1.yaml                # Rendered manifests (new)
│       ├── app2.yaml
│       └── ...
└── diffs/
    ├── parent-app.diff              # Parent Application changes
    ├── app1.diff                    # Child app changes
    ├── app2.diff
    └── ...
```

## Multiple Sources Support

The script **fully supports** ArgoCD's multiple sources feature (v2.6+).

### How Multiple Sources Work

Applications can have multiple sources for:
- **Chart in one repo, values in another**
- **Shared configuration across apps**
- **Environment-specific overrides from separate repo**

Example:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
spec:
  sources:
    # Source 0: Helm chart
    - repoURL: https://github.com/charts/repo
      path: my-chart
      helm:
        valueFiles:
          - $values/production.yaml
    # Source 1: Values
    - repoURL: https://github.com/values/repo
      ref: values
      path: environments/prod/
```

### Script Behavior

When the script encounters multiple sources:

1. ✅ **Detects all sources** - Parses both `source:` and `sources:` formats
2. ✅ **Extracts each source** - Pulls chart and values from different paths
3. ✅ **Combines sources** - Renders chart with all value files
4. ✅ **Shows in output** - Marks multi-source apps as `(multi-source)`

Example output:
```
Child apps:
  - monitoring
  - webapp (multi-source)
  - api (multi-source)
```

### Requirements

**`yq` is REQUIRED for multiple sources support.**

Without `yq`:
- Falls back to basic parsing
- Only supports single source apps
- Multi-source apps may be skipped or incorrectly parsed

Install yq:
```bash
# Linux
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# macOS
brew install yq
```

### Limitations

**Same Repository Only**

Currently supports multiple sources **only if all sources are in the same repository**:

✅ **Supported:**
```yaml
sources:
  - repoURL: https://github.com/org/repo
    path: charts/my-app
  - repoURL: https://github.com/org/repo  # Same repo
    path: values/prod/
    ref: values
```

❌ **Not Supported (Offline):**
```yaml
sources:
  - repoURL: https://github.com/org/charts-repo
    path: my-app
  - repoURL: https://github.com/org/values-repo  # Different repo
    path: production/
    ref: values
```

For external repos, the script notes them but cannot render offline.

## Limitations

### External Repositories

Child apps that reference external git repositories cannot be rendered offline:

```yaml
# External repository: https://github.com/other-org/repo
# Cannot render external repos in offline mode
```

This includes:
- Apps with sources from different repos
- Multi-source apps where sources are in different repos
- Apps referencing Helm charts from Helm repositories

**Workaround:** Clone external repos and adjust the script to use local paths.

### Helm Value Overrides

If child apps use:
- Helm parameters from the Application spec
- Additional values files not in the repository
- Encrypted secrets (Sealed Secrets, SOPS, etc.)

The rendered manifests may not match live deployments exactly.

### Complex Helm Dependencies

Child charts with external dependencies defined in `Chart.yaml` may fail to render without `helm dependency update`.

## Troubleshooting

### Script fails with "Could not extract chart"

**Cause:** Chart path doesn't exist in the specified revision.

**Solution:** Verify the path:
```bash
git ls-tree v1.2.3 charts/argocd-apps
```

### Empty diff when changes expected

**Causes:**
1. Changes only affect child apps, not Application CRDs (expected)
2. Chart values haven't changed for the specified environment
3. Changes are in a different path

**Debug:**
```bash
# Check if source files changed
git diff v1.2.3..v1.2.4 -- charts/ apps/

# Inspect rendered manifests
cat /tmp/argocd-app-of-apps-diff-*/old/children/my-app.yaml
cat /tmp/argocd-app-of-apps-diff-*/new/children/my-app.yaml
```

### "yq not found" warning

The script works without `yq` but uses basic parsing that may miss complex YAML structures.

**Without yq:**
- ❌ Multiple sources not supported
- ❌ Complex Application specs may fail
- ⚠️ Falls back to simple grep/awk parsing

**Install yq:**
```bash
# Linux
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# macOS
brew install yq

# Verify
yq --version  # Should show v4.x or higher
```

### Multi-source app showing "Could not render"

**Cause:** Sources are in different repositories (external).

**Debug:**
```bash
# Check the app definition
cat /tmp/argocd-app-of-apps-diff-*/new/parent/applications.yaml | \
  yq 'select(.metadata.name == "my-app") | .spec.sources'

# Look for different repoURL values
```

**Solution:** Clone the external repo locally and modify paths, or use online `argocd app diff`.

### Multi-source app values not applied

**Cause:** Values reference `$ref` not found or path incorrect.

**Debug:**
```bash
# Check extracted sources
ls -la /tmp/argocd-app-of-apps-diff-*/new/children/temp-my-app/

# Check helm flags used
cat /tmp/argocd-app-of-apps-diff-*/new/children/my-app.yaml
# Look for comment showing helm flags
```

**Solution:** Verify value file paths exist in the repository at the specified revision.

### Helm rendering fails for child app

**Causes:**
1. Missing Chart.yaml
2. Invalid Helm syntax
3. Missing dependencies

**Debug:**
```bash
# Try rendering manually
helm template my-app /tmp/argocd-app-of-apps-diff-*/new/apps/my-app/
```

## Integration with CI/CD

### GitHub Actions

```yaml
name: ArgoCD Diff Preview

on:
  pull_request:
    branches: [main]

jobs:
  diff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - name: Setup Helm
        uses: azure/setup-helm@v3
        
      - name: Generate Diff
        run: |
          ./scripts/diff-app-of-apps.sh \
            origin/main \
            HEAD \
            production \
            > diff-output.txt
            
      - name: Comment on PR
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const diff = fs.readFileSync('diff-output.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '## ArgoCD Diff\n\n```diff\n' + diff + '\n```'
            });
```

### GitLab CI

```yaml
argocd-diff:
  stage: test
  script:
    - ./scripts/diff-app-of-apps.sh $CI_MERGE_REQUEST_TARGET_BRANCH_NAME HEAD production
  only:
    - merge_requests
```

## Advanced Usage

### Custom Chart Path

Edit the script to change the chart location:

```bash
PARENT_CHART_PATH="infrastructure/argocd/apps"
```

### Multiple Environments

Compare all environments:

```bash
for env in development staging production; do
  echo "=== Environment: $env ==="
  ./diff-app-of-apps.sh v1.2.3 v1.2.4 $env
done
```

### Save Diffs for Later

```bash
WORK_DIR="/tmp/release-v1.2.4-diffs"
./diff-app-of-apps.sh v1.2.3 v1.2.4 production
# Artifacts remain in /tmp/argocd-app-of-apps-diff-{PID}/
# Move to permanent location if needed
```

## Best Practices

### Release Workflow

1. **Create feature branch**
   ```bash
   git checkout -b feature/update-app
   ```

2. **Make changes and commit**
   ```bash
   # Edit values, add apps, etc.
   git commit -am "Update application configuration"
   ```

3. **Generate diff before creating PR**
   ```bash
   ./scripts/diff-app-of-apps.sh main HEAD production
   ```

4. **Review changes**
   - Check parent app: Are Application CRDs correct?
   - Check child apps: Are resource changes expected?
   - Verify no unintended changes

5. **Create PR with diff in description**
   - Include diff summary in PR
   - Note any breaking changes
   - List affected applications

6. **Tag release after merge**
   ```bash
   git tag -a v1.2.4 -m "Release v1.2.4"
   git push origin v1.2.4
   ```

### Pre-Deployment Validation

```bash
# Compare what's deployed (tag) vs what will deploy (branch)
./scripts/diff-app-of-apps.sh v1.2.3-deployed feature/new-release production

# If satisfied, merge and tag
git checkout main
git merge feature/new-release
git tag v1.2.4
git push origin main v1.2.4
```

## Comparison with Online Methods

| Method | Pros | Cons |
|--------|------|------|
| **This Script (Offline)** | No cluster access needed<br>Works in CI/CD<br>Fast for large apps<br>Version controlled | Can't render external repos<br>May miss runtime values |
| **`argocd app diff --revision`** | Accurate to live state<br>Handles external repos<br>Uses actual Application config | Requires cluster access<br>Slower for many apps<br>Can't compare two git revisions |
| **`argocd app manifests`** | No deployment needed<br>Renders from ArgoCD config | Requires cluster access<br>One revision at a time |
| **GitHub Actions Workflow** | Automated on PR<br>Comments on PR | Requires GitHub<br>Complex setup |

## Related Documentation

- [App of Apps Pattern](../docs/patterns/APP-OF-APPS-PATTERN.md)
- [Multiple Sources Pattern](../docs/patterns/MULTIPLE-SOURCES-PATTERN.md) - Using multiple sources in ArgoCD
- [GitHub Diff Workflow](../github-workflows/README.md)
- [Test Diff Locally](./test-diff-locally.sh) - Single app comparison

## Contributing

Found a bug or want to add features?

1. Test your changes against the example apps
2. Update this README
3. Submit a PR with example output

## License

This script is part of the gemini-workspace DevOps examples collection.
