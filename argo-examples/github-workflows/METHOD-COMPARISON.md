# Method Comparison: Detecting Changed Directories

## Quick Decision Matrix

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Need simple path-based triggers?                                       │
│ ├─ Yes → Use dorny/paths-filter                                        │
│ └─ No → Continue                                                        │
│                                                                          │
│ Need dynamic matrix from directory discovery?                          │
│ ├─ Yes → Continue                                                       │
│ └─ No → Use simple conditional jobs                                     │
│                                                                          │
│ Comfortable with bash/git commands?                                     │
│ ├─ Yes → Use Native Git (most flexible)                                │
│ └─ No → Use tj-actions/changed-files                                   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Feature Comparison Table

| Feature | Native Git | tj-actions/changed-files | dorny/paths-filter |
|---------|-----------|-------------------------|-------------------|
| **No Dependencies** | ✅ | ❌ Requires action | ❌ Requires action |
| **Flexibility** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Ease of Use** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Matrix Generation** | ✅ Manual | ✅ Easy | ⚠️ Limited |
| **Complex Patterns** | ✅ Full regex | ✅ Globs | ✅ Globs |
| **Custom Logic** | ✅ Full control | ⚠️ Limited | ❌ Fixed |
| **Speed** | Fast | Fast | Fast |
| **Maintenance** | Low | Medium | Medium |

## Method Details

### 1. Native Git (`git diff`)

**Use When:**
- You need maximum flexibility
- Custom filtering logic required
- No external dependencies preferred
- Complex directory extraction needed
- Learning opportunity desired

**Pros:**
- ✅ No external dependencies
- ✅ Full control over logic
- ✅ Works with any git comparison
- ✅ Can combine multiple conditions
- ✅ Easy to debug
- ✅ Supports complex regex patterns

**Cons:**
- ❌ More verbose code
- ❌ Requires git/bash knowledge
- ❌ Manual JSON array construction
- ❌ More room for errors

**Example:**
```yaml
- id: detect
  run: |
    BASE="${{ github.event.pull_request.base.sha || github.event.before }}"
    APPS=$(git diff --name-only "$BASE" "${{ github.sha }}" | \
      grep '^apps/' | \
      cut -d'/' -f2 | \
      sort -u | \
      jq -R -s -c 'split("\n") | map(select(length > 0))')
    echo "apps=$APPS" >> $GITHUB_OUTPUT
```

**Best For:**
- Large teams with strong CI/CD knowledge
- Projects requiring custom logic
- When you need to combine multiple conditions

---

### 2. tj-actions/changed-files

**Use When:**
- You want simplicity with power
- Don't mind external dependencies
- Need feature-rich file detection
- Want maintained, tested solution

**Pros:**
- ✅ Simple configuration
- ✅ Well-maintained action
- ✅ Rich feature set
- ✅ Built-in JSON output
- ✅ Directory extraction
- ✅ Multiple output formats
- ✅ Good documentation

**Cons:**
- ❌ External dependency
- ❌ Potential breaking changes
- ❌ Less control over logic
- ❌ Version pinning needed

**Example:**
```yaml
- uses: tj-actions/changed-files@v44
  id: changed
  with:
    files: apps/**
    json: true
    dir_names: true
    dir_names_max_depth: 2
```

**Best For:**
- Teams wanting simple solutions
- Projects with existing action usage
- When you don't want to maintain detection logic

---

### 3. dorny/paths-filter

**Use When:**
- You need simple path-based conditionals
- Matrix is pre-defined
- Want true/false checks per path
- Need filter-based workflow control

**Pros:**
- ✅ Very simple configuration
- ✅ Clear filter definitions
- ✅ Boolean outputs
- ✅ YAML-based filters
- ✅ Good for job conditionals

**Cons:**
- ❌ Limited matrix generation
- ❌ Pre-defined filters only
- ❌ Less flexible
- ❌ Not ideal for dynamic discovery

**Example:**
```yaml
- uses: dorny/paths-filter@v3
  id: filter
  with:
    filters: |
      frontend: 'apps/frontend/**'
      backend: 'apps/backend/**'

# Use in conditions
if: steps.filter.outputs.frontend == 'true'
```

**Best For:**
- Simple conditional workflows
- Fixed set of paths/apps
- Job-level conditionals
- When you don't need dynamic matrices

---

## Use Case Recommendations

### Use Case 1: Monorepo with Multiple Apps

**Scenario:** Deploy only changed apps

**Recommended:** Native Git or tj-actions/changed-files

**Why:** Dynamic discovery of changed apps, flexible matrix generation

```yaml
# Discover changed apps → Generate matrix → Deploy each
detect → matrix: [app1, app2] → deploy(app1), deploy(app2)
```

---

### Use Case 2: Fixed Set of Services

**Scenario:** You have 5 known services, want to deploy only changed ones

**Recommended:** dorny/paths-filter

**Why:** Simple, clear, predefined paths

```yaml
filters:
  service-a: 'services/a/**'
  service-b: 'services/b/**'
  # etc.

# Then conditional jobs
deploy-a:
  if: needs.filter.outputs.service-a == 'true'
```

---

### Use Case 3: Complex Deployment Strategy

**Scenario:** Deploy all if core changed, only changed apps otherwise

**Recommended:** Native Git

**Why:** Need complex conditional logic

```yaml
# Pseudo-logic:
if infrastructure/* changed:
  deploy all apps
else if apps/* changed:
  deploy only changed apps
else:
  skip deployment
```

---

### Use Case 4: Multi-Environment

**Scenario:** Different apps/envs based on branch

**Recommended:** Native Git + Custom Logic

**Why:** Environment-specific rules

```yaml
if branch == main:
  deploy to prod
elif branch == develop:
  deploy to staging
```

---

### Use Case 5: Simple Validation

**Scenario:** Run tests only for changed services

**Recommended:** dorny/paths-filter

**Why:** Simple true/false checks, no matrix needed

```yaml
test-frontend:
  if: needs.filter.outputs.frontend == 'true'
  
test-backend:
  if: needs.filter.outputs.backend == 'true'
```

---

## Performance Comparison

| Method | Setup Time | Execution Time | Complexity |
|--------|-----------|---------------|-----------|
| Native Git | ~5s | <1s | Medium |
| tj-actions | ~10s | <2s | Low |
| dorny/paths-filter | ~10s | <2s | Low |

All methods are fast enough for practical use. Choice should be based on features, not performance.

---

## Migration Guide

### From dorny/paths-filter → Native Git

**Before:**
```yaml
- uses: dorny/paths-filter@v3
  id: filter
  with:
    filters: |
      app1: 'apps/app1/**'
      app2: 'apps/app2/**'
```

**After:**
```yaml
- id: detect
  run: |
    BASE="${{ github.event.pull_request.base.sha || github.event.before }}"
    CHANGED=$(git diff --name-only "$BASE" "${{ github.sha }}" | \
      grep '^apps/' | cut -d'/' -f2 | sort -u | \
      jq -R -s -c 'split("\n") | map(select(length > 0))')
    echo "apps=$CHANGED" >> $GITHUB_OUTPUT
```

### From Static Matrix → Dynamic Matrix

**Before:**
```yaml
strategy:
  matrix:
    app: [app1, app2, app3]
```

**After:**
```yaml
detect:
  outputs:
    apps: ${{ steps.find.outputs.apps }}
  steps:
    - id: find
      run: |
        APPS=$(find apps -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | \
          jq -R -s -c 'split("\n") | map(select(length > 0))')
        echo "apps=$APPS" >> $GITHUB_OUTPUT

deploy:
  needs: detect
  strategy:
    matrix:
      app: ${{ fromJSON(needs.detect.outputs.apps) }}
```

---

## Troubleshooting Decision Tree

```
Problem: Not detecting changes
├─ Using Native Git?
│  ├─ Check fetch-depth: 0
│  ├─ Verify BASE/HEAD refs
│  └─ Debug with git diff --name-only
├─ Using tj-actions?
│  ├─ Check files pattern
│  ├─ Verify fetch_depth
│  └─ Check dir_names settings
└─ Using paths-filter?
   ├─ Verify filter patterns
   └─ Check list-files setting

Problem: Matrix is empty
├─ No changes detected
│  └─ Add conditional: if: needs.detect.outputs.apps != '[]'
├─ Wrong path pattern
│  └─ Debug: echo changed files
└─ JSON parsing issue
   └─ Validate: echo '$OUTPUT' | jq empty

Problem: Too many false positives
├─ Exclude patterns needed
│  ├─ Native: grep -v
│  ├─ tj-actions: files_ignore
│  └─ paths-filter: negative patterns
└─ Path depth wrong
   └─ Adjust cut -d'/' -f<level>
```

---

## Best Practices by Team Size

### Small Team (1-5 developers)
**Recommended:** tj-actions/changed-files or dorny/paths-filter
**Why:** Simple, maintained, less to learn

### Medium Team (5-20 developers)
**Recommended:** Native Git
**Why:** More control, team can maintain, flexibility for growth

### Large Team (20+ developers)
**Recommended:** Native Git with extensive testing
**Why:** Custom logic needed, full control, audit trail

---

## Example Workflows

Each method has working examples in this repository:

| File | Method | Complexity |
|------|--------|-----------|
| `simple-dynamic-matrix.yml` | Native Git | ⭐ Basic |
| `detect-changed-directories.yml` | All Methods | ⭐⭐⭐ Comprehensive |
| `deploy-changed-apps-matrix.yml` | Native Git | ⭐⭐⭐⭐ Production |

---

## Recommendation Summary

**Start with:** tj-actions/changed-files  
**Migrate to:** Native Git when you need more control  
**Use paths-filter:** For simple conditionals only

**Default Choice for Most Projects:**
```yaml
- uses: tj-actions/changed-files@v44
  with:
    files: apps/**
    json: true
    dir_names: true
```

Then extract to matrix:
```yaml
- id: matrix
  run: |
    APPS=$(echo '${{ steps.changed.outputs.all_changed_files }}' | \
      jq -c '[.[] | select(startswith("apps/")) | split("/")[1]] | unique')
    echo "apps=$APPS" >> $GITHUB_OUTPUT
```

Simple, reliable, maintainable.

---

## Further Reading

- [DYNAMIC-MATRIX-GUIDE.md](./DYNAMIC-MATRIX-GUIDE.md) - Complete matrix guide
- [CHANGED-DIRECTORIES-GUIDE.md](./CHANGED-DIRECTORIES-GUIDE.md) - Detailed detection guide
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Quick syntax reference

