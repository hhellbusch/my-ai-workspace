# Multiple Sources Support - Changelog

## Summary

Updated the `diff-app-of-apps.sh` script and documentation to support ArgoCD's multiple sources feature (v2.6+).

## What Changed

### Script Enhancements (`scripts/diff-app-of-apps.sh`)

#### 1. Multiple Sources Detection
- ✅ Parses both `spec.source` (singular) and `spec.sources` (plural)
- ✅ Extracts all sources from Application definitions
- ✅ Stores source index, repo URL, path, target revision, and ref for each source

#### 2. Enhanced Rendering
- ✅ Detects chart source vs values sources automatically
- ✅ Combines multiple sources when rendering Helm charts
- ✅ Passes multiple `-f` flags to `helm template` for each values source
- ✅ Handles both Chart.yaml (Helm) and plain YAML manifests

#### 3. Better Output
- ✅ Shows which apps use multiple sources with `(multi-source)` indicator
- ✅ Provides clearer error messages for external repos
- ✅ Includes debug information in output files

### New Documentation

#### `docs/patterns/MULTIPLE-SOURCES-PATTERN.md`
Comprehensive guide covering:
- Single source vs multiple sources comparison
- Common patterns (separate repos, environment overrides, shared config)
- App of Apps with multiple sources
- Value file reference syntax (`$ref`)
- CLI usage with multiple sources
- Best practices and migration guide
- Troubleshooting

#### Updated `scripts/README-diff-app-of-apps.md`
- Added prerequisites note: **yq is required** for multiple sources
- Updated "How It Works" section with multiple sources details
- Added "Multiple Sources Support" section
- Enhanced limitations section
- Added multiple sources troubleshooting

### New Examples

#### `apps/example-single-source.yaml`
Traditional single source Application with inline values.

#### `apps/example-multiple-sources.yaml`
Three examples:
1. Multiple sources in same repo (chart + values separation)
2. Multiple sources in different repos (platform vs app team)
3. Multiple sources with shared configuration

## Requirements

### Critical Dependency: yq

**Without yq:**
- ❌ Multiple sources not supported
- ❌ Falls back to basic grep/awk parsing
- ⚠️ Only single source apps will work

**Install yq v4+:**
```bash
# Linux
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# macOS
brew install yq

# Verify
yq --version
```

## Supported Scenarios

### ✅ Fully Supported

1. **Single source apps** (traditional)
   ```yaml
   spec:
     source:
       repoURL: https://github.com/org/repo
       path: apps/my-app
   ```

2. **Multiple sources in same repo**
   ```yaml
   spec:
     sources:
       - repoURL: https://github.com/org/repo
         path: charts/my-app
       - repoURL: https://github.com/org/repo
         path: values/prod/
         ref: values
   ```

3. **Chart with multiple value files**
   ```yaml
   spec:
     sources:
       - path: charts/app
         helm:
           valueFiles:
             - values.yaml
             - $values/prod.yaml
             - $values/secrets.yaml
       - path: values/
         ref: values
   ```

### ⚠️ Partially Supported

**Multiple sources in different repos** - Only if repos are both local:
- Script detects and parses the configuration
- Shows sources in output
- Cannot fetch from external repos offline
- Notes them as "External repository: cannot render"

### ❌ Not Supported (Offline)

1. **External git repositories**
   ```yaml
   sources:
     - repoURL: https://github.com/external/repo
   ```

2. **Helm chart repositories**
   ```yaml
   sources:
     - repoURL: https://charts.example.com
       chart: my-chart
   ```

3. **OCI registries**
   ```yaml
   sources:
     - repoURL: oci://registry/charts
   ```

## Usage

### Basic Usage (Unchanged)

```bash
./scripts/diff-app-of-apps.sh v1.2.3 v1.2.4 production
```

### What's Different Now

The script automatically:
- Detects if apps use `source` or `sources`
- Extracts all sources for multi-source apps
- Combines them when rendering
- Shows `(multi-source)` indicator in output

**No changes to command-line interface required!**

### Example Output

```
[3/5] Extracting child app definitions...
✅ Found 5 child applications
Child apps:
  - monitoring
  - logging
  - ingress (multi-source)
  - webapp (multi-source)
  - api
```

## Migration Path

### If You're Already Using the Script

**No changes needed!** The script is backward compatible:
- Single source apps work exactly as before
- Multiple source apps now render correctly instead of failing

### If Your Apps Use Multiple Sources

1. **Install yq** (if not already installed)
   ```bash
   yq --version  # Check if installed
   ```

2. **Run the script as usual**
   ```bash
   ./scripts/diff-app-of-apps.sh main HEAD production
   ```

3. **Look for multi-source indicators**
   - Apps marked `(multi-source)` use the new feature
   - Verify they render correctly in output

## Known Issues

### Issue 1: External Repos Still Can't Be Rendered Offline

**Limitation:** Multiple sources with external repos can't be fetched offline.

**Example:**
```yaml
sources:
  - repoURL: https://github.com/platform/charts
  - repoURL: https://github.com/team/values  # External - can't fetch
```

**Workaround:**
- Use `argocd app manifests --revisions` with cluster connectivity
- Or clone external repos locally and modify script paths

### Issue 2: yq Dependency Now Critical

**Before:** Script worked (limited) without yq  
**After:** yq required for multiple sources

**Why:** Complex YAML parsing needed for multiple sources array

**Solution:** Install yq (see above)

## Testing

### Test Single Source Apps

```bash
# Should work with or without yq
./scripts/diff-app-of-apps.sh v1.0.0 v1.0.1 production
```

### Test Multiple Sources Apps

```bash
# Requires yq
command -v yq || echo "yq not found - install it first"

./scripts/diff-app-of-apps.sh main HEAD production
# Look for (multi-source) indicators
```

### Verify Output

```bash
# Check generated manifests
ls -la /tmp/argocd-app-of-apps-diff-*/new/children/

# Check if helm values were combined
cat /tmp/argocd-app-of-apps-diff-*/new/children/my-app.yaml | less
```

## Breaking Changes

**None.** The update is fully backward compatible.

## Future Enhancements

Potential improvements for future versions:

1. **External repo support** - Option to provide local paths for external repos
2. **Multi-repo cloning** - Auto-clone external repos if credentials provided
3. **Helm chart repos** - Support for `chart:` instead of `path:`
4. **OCI support** - Handle OCI-based Helm charts
5. **Parallel rendering** - Speed up by rendering apps in parallel

## Feedback

This is a significant enhancement. Please report:
- Apps that don't render correctly
- Unexpected behavior with multiple sources
- Performance issues with large applications
- Suggestions for improvements

## Related

- [Multiple Sources Pattern Documentation](docs/patterns/MULTIPLE-SOURCES-PATTERN.md)
- [Script README](scripts/README-diff-app-of-apps.md)
- [ArgoCD Multiple Sources Docs](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)
