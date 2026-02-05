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

**Optional (recommended):**
- `yq` - For better YAML parsing ([install guide](https://github.com/mikefarah/yq))

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

### Step 4: Render Children
For each child app:
- Detects if it's a Helm chart or plain YAML
- Extracts from the appropriate git revision
- Renders manifests for comparison

### Step 5: Generate Diffs
Creates unified diffs showing:
- Changes to Application CRD definitions (parent)
- Changes to Kubernetes resources (children)

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

## Limitations

### External Repositories
Child apps that reference external git repositories cannot be rendered offline. The script will note these and skip them:

```yaml
# External repository: https://github.com/other-org/repo
# Cannot render external repos in offline mode
```

**Workaround:** Clone external repos and run the script against them separately.

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

**Install yq:**
```bash
# Linux
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# macOS
brew install yq
```

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
- [GitHub Diff Workflow](../github-workflows/README.md)
- [Test Diff Locally](./test-diff-locally.sh) - Single app comparison

## Contributing

Found a bug or want to add features?

1. Test your changes against the example apps
2. Update this README
3. Submit a PR with example output

## License

This script is part of the gemini-workspace DevOps examples collection.
