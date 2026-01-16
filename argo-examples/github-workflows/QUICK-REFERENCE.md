# GitHub Actions Quick Reference
## Dynamic Matrix + Changed Directories

## 🎯 Core Pattern

### Generate List → Use in Matrix

```yaml
jobs:
  generate:
    outputs:
      matrix: ${{ steps.set.outputs.matrix }}
    steps:
      - id: set
        run: echo "matrix=[\"a\",\"b\"]" >> $GITHUB_OUTPUT

  process:
    needs: generate
    strategy:
      matrix:
        item: ${{ fromJSON(needs.generate.outputs.matrix) }}
    steps:
      - run: echo "${{ matrix.item }}"
```

## 📂 Detect Changed Directories

### Method 1: Native Git (Most Flexible)

```yaml
steps:
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0

  - id: detect
    run: |
      BASE="${{ github.event.pull_request.base.sha || github.event.before }}"
      HEAD="${{ github.sha }}"
      
      # Top-level directories
      DIRS=$(git diff --name-only "$BASE" "$HEAD" | \
        cut -d'/' -f1 | sort -u | \
        jq -R -s -c 'split("\n") | map(select(length > 0))')
      
      echo "dirs=$DIRS" >> $GITHUB_OUTPUT
```

### Method 2: Changed Apps Specifically

```yaml
- id: detect
  run: |
    BASE="${{ github.event.pull_request.base.sha || github.event.before }}"
    HEAD="${{ github.sha }}"
    
    # Extract app names from apps/ directory
    APPS=$(git diff --name-only "$BASE" "$HEAD" | \
      grep '^apps/' | \
      cut -d'/' -f2 | \
      sort -u | \
      jq -R -s -c 'split("\n") | map(select(length > 0))')
    
    echo "apps=$APPS" >> $GITHUB_OUTPUT
```

### Method 3: tj-actions/changed-files

```yaml
- uses: tj-actions/changed-files@v44
  id: changed
  with:
    files: apps/**
    json: true
    dir_names: true
    dir_names_max_depth: 2

- run: echo "${{ steps.changed.outputs.all_changed_files }}"
```

## 🔄 Complete Flow

```yaml
jobs:
  detect:
    outputs:
      apps: ${{ steps.find.outputs.apps }}
      has-changes: ${{ steps.find.outputs.has-changes }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - id: find
        run: |
          BASE="${{ github.event.pull_request.base.sha || github.event.before }}"
          APPS=$(git diff --name-only "$BASE" "${{ github.sha }}" | \
            grep '^apps/' | cut -d'/' -f2 | sort -u | \
            jq -R -s -c 'split("\n") | map(select(length > 0))')
          
          HAS=$(echo "$APPS" | jq 'length > 0')
          echo "apps=$APPS" >> $GITHUB_OUTPUT
          echo "has-changes=$HAS" >> $GITHUB_OUTPUT

  deploy:
    needs: detect
    if: needs.detect.outputs.has-changes == 'true'
    strategy:
      matrix:
        app: ${{ fromJSON(needs.detect.outputs.apps) }}
      fail-fast: false
    steps:
      - run: echo "Deploy ${{ matrix.app }}"
```

## 🎨 Matrix Formats

### Simple Array

```json
["app1", "app2", "app3"]
```

```yaml
strategy:
  matrix:
    app: ${{ fromJSON(needs.gen.outputs.apps) }}
```

Access: `${{ matrix.app }}`

### Object Array

```json
{
  "include": [
    {"app": "app1", "env": "dev"},
    {"app": "app2", "env": "prod"}
  ]
}
```

```yaml
strategy:
  matrix: ${{ fromJSON(needs.gen.outputs.matrix) }}
```

Access: `${{ matrix.app }}` and `${{ matrix.env }}`

### Multi-Dimensional

```json
{
  "app": ["app1", "app2"],
  "env": ["dev", "prod"]
}
```

Creates: app1/dev, app1/prod, app2/dev, app2/prod

## ⚠️ Common Pitfalls

### ❌ Missing fromJSON()
```yaml
# WRONG
matrix:
  app: ${{ needs.gen.outputs.apps }}

# RIGHT
matrix:
  app: ${{ fromJSON(needs.gen.outputs.apps) }}
```

### ❌ Missing Job Outputs
```yaml
# WRONG
jobs:
  gen:
    steps:
      - id: set
        run: echo "matrix=..." >> $GITHUB_OUTPUT

# RIGHT
jobs:
  gen:
    outputs:
      matrix: ${{ steps.set.outputs.matrix }}
    steps:
      - id: set
        run: echo "matrix=..." >> $GITHUB_OUTPUT
```

### ❌ Invalid JSON
```yaml
# WRONG
echo "apps=app1,app2" >> $GITHUB_OUTPUT

# RIGHT
echo 'apps=["app1","app2"]' >> $GITHUB_OUTPUT
```

### ❌ Empty Matrix
```yaml
# WRONG - job runs with no iterations
strategy:
  matrix:
    app: ${{ fromJSON(needs.gen.outputs.apps) }}  # apps=[]

# RIGHT - skip if empty
if: needs.gen.outputs.apps != '[]'
strategy:
  matrix:
    app: ${{ fromJSON(needs.gen.outputs.apps) }}
```

### ❌ Insufficient Git History
```yaml
# WRONG - can't compare
- uses: actions/checkout@v4

# RIGHT - fetch history
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
```

## 🔍 Debug Tips

### Show Generated Matrix
```yaml
- name: Debug
  run: |
    echo "Matrix JSON:"
    echo '${{ needs.gen.outputs.matrix }}' | jq .
    
    echo "Will create these jobs:"
    echo '${{ needs.gen.outputs.matrix }}' | jq -r '.include[] | "\(.app)/\(.env)"'
```

### Show Changed Files
```yaml
- name: Debug
  run: |
    BASE="${{ github.event.pull_request.base.sha || github.event.before }}"
    echo "Comparing $BASE..${{ github.sha }}"
    git diff --name-only "$BASE" "${{ github.sha }}"
```

### Validate JSON
```yaml
- name: Validate
  run: |
    echo '${{ steps.gen.outputs.matrix }}' | jq empty
```

## 💡 Conditional Logic

### Skip if No Changes
```yaml
deploy:
  needs: detect
  if: needs.detect.outputs.has-changes == 'true'
```

### Deploy All if Core Changed
```yaml
- id: strategy
  run: |
    if git diff --name-only "$BASE" "$HEAD" | grep -q '^infrastructure/'; then
      ALL_APPS=$(find apps -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | jq -R -s -c 'split("\n") | map(select(length > 0))')
      echo "apps=$ALL_APPS" >> $GITHUB_OUTPUT
    else
      # Only changed apps
    fi
```

### PR vs Push Behavior
```yaml
validate:
  if: github.event_name == 'pull_request'
  # Dry-run only

deploy:
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  # Actual deployment
```

## 🚀 Matrix Options

```yaml
strategy:
  matrix:
    app: ${{ fromJSON(needs.gen.outputs.apps) }}
  fail-fast: false      # Continue if one fails
  max-parallel: 3       # Limit concurrent jobs
```

## 📊 Useful Comparisons

| Scenario | Base Ref | Head Ref |
|----------|----------|----------|
| Pull Request | `github.event.pull_request.base.sha` | `github.event.pull_request.head.sha` |
| Push | `github.event.before` | `github.sha` |
| First Push | `origin/main` | `github.sha` |

## 📁 Path Extraction Examples

```bash
# apps/my-app/file.yaml → my-app
cut -d'/' -f2

# apps/my-app/file.yaml → apps/my-app
cut -d'/' -f1-2

# Get unique, filter by prefix
grep '^apps/' | cut -d'/' -f2 | sort -u

# Convert to JSON array
jq -R -s -c 'split("\n") | map(select(length > 0))'
```

## 📖 Full Documentation

- **Dynamic Matrix Guide:** [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md)
- **Changed Directories Guide:** [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md)

## 💻 Working Examples

- `simple-dynamic-matrix.yml` - Minimal example
- `dynamic-matrix-example.yml` - Comprehensive patterns
- `detect-changed-directories.yml` - All detection methods
- `deploy-changed-apps-matrix.yml` - Complete real-world example

