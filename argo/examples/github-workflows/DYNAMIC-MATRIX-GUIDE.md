# GitHub Actions Dynamic Matrix Guide

## Overview

This guide explains how to create a GitHub Actions workflow where one job generates a list that is used in a matrix strategy in a subsequent job.

## The Pattern

```yaml
jobs:
  generate:
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - id: set-matrix
        run: echo "matrix=<JSON>" >> $GITHUB_OUTPUT

  process:
    needs: generate
    strategy:
      matrix: ${{ fromJSON(needs.generate.outputs.matrix) }}
```

## Key Components

### 1. Job Outputs

The first job must define `outputs` at the job level:

```yaml
generate-list:
  outputs:
    apps: ${{ steps.discover.outputs.apps }}
```

### 2. Step Outputs

The step must write to `$GITHUB_OUTPUT`:

```yaml
- id: discover
  run: |
    APPS='["app1", "app2", "app3"]'
    echo "apps=$APPS" >> $GITHUB_OUTPUT
```

### 3. Job Dependencies

The second job must depend on the first using `needs`:

```yaml
process:
  needs: generate-list
```

### 4. Matrix Definition

Use `fromJSON()` to parse the string output:

```yaml
strategy:
  matrix:
    app: ${{ fromJSON(needs.generate-list.outputs.apps) }}
```

## Matrix Formats

### Simple Array

**Generate:**
```json
["app1", "app2", "app3"]
```

**Use:**
```yaml
strategy:
  matrix:
    app: ${{ fromJSON(needs.generate.outputs.apps) }}
```

**Access in steps:**
```yaml
- run: echo "Processing ${{ matrix.app }}"
```

### Object with Multiple Dimensions

**Generate:**
```json
{
  "include": [
    {"app": "app1", "env": "dev"},
    {"app": "app2", "env": "prod"}
  ]
}
```

**Use:**
```yaml
strategy:
  matrix: ${{ fromJSON(needs.generate.outputs.matrix) }}
```

**Access in steps:**
```yaml
- run: echo "Deploy ${{ matrix.app }} to ${{ matrix.env }}"
```

### Multiple Independent Dimensions

**Generate:**
```json
{
  "app": ["app1", "app2"],
  "environment": ["dev", "prod"]
}
```

**Use:**
```yaml
strategy:
  matrix: ${{ fromJSON(needs.generate.outputs.matrix) }}
```

This creates a full cross-product: app1/dev, app1/prod, app2/dev, app2/prod

## Common Patterns

### 1. Directory Discovery

```yaml
- name: Find directories
  id: discover
  run: |
    DIRS=$(find ./apps -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | jq -R -s -c 'split("\n") | map(select(length > 0))')
    echo "dirs=$DIRS" >> $GITHUB_OUTPUT
```

### 2. Read from YAML File

```yaml
- name: Read from config
  id: discover
  run: |
    # Requires yq to be installed
    CLUSTERS=$(yq eval '.clusters | keys | @json' config.yaml)
    echo "clusters=$CLUSTERS" >> $GITHUB_OUTPUT
```

### 3. Git Changed Files

```yaml
- name: Find changed apps
  id: discover
  run: |
    # Get changed files and extract unique app directories
    CHANGED_APPS=$(git diff --name-only HEAD^ HEAD | grep '^apps/' | cut -d'/' -f2 | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))')
    echo "apps=$CHANGED_APPS" >> $GITHUB_OUTPUT
```

### 4. Conditional Matrix (Skip if Empty)

```yaml
generate:
  outputs:
    apps: ${{ steps.discover.outputs.apps }}
    has-apps: ${{ steps.discover.outputs.has-apps }}
  steps:
    - id: discover
      run: |
        APPS='["app1", "app2"]'
        HAS_APPS=$(echo "$APPS" | jq 'length > 0')
        echo "apps=$APPS" >> $GITHUB_OUTPUT
        echo "has-apps=$HAS_APPS" >> $GITHUB_OUTPUT

process:
  needs: generate
  if: needs.generate.outputs.has-apps == 'true'
  strategy:
    matrix:
      app: ${{ fromJSON(needs.generate.outputs.apps) }}
```

## Common Pitfalls

### 1. ❌ Forgetting `fromJSON()`

```yaml
# WRONG - treats the string literally
matrix:
  app: ${{ needs.generate.outputs.apps }}

# CORRECT - parses JSON
matrix:
  app: ${{ fromJSON(needs.generate.outputs.apps) }}
```

### 2. ❌ Invalid JSON Format

```yaml
# WRONG - not valid JSON
echo "apps=app1,app2,app3" >> $GITHUB_OUTPUT

# CORRECT - valid JSON array
echo 'apps=["app1","app2","app3"]' >> $GITHUB_OUTPUT
```

### 3. ❌ Multiline JSON Without Delimiters

```yaml
# WRONG - GitHub Actions may truncate
echo "matrix={...}" >> $GITHUB_OUTPUT

# CORRECT - use EOF delimiters for complex JSON
echo "matrix<<EOF" >> $GITHUB_OUTPUT
echo '{"include":[...]}' >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT
```

### 4. ❌ Missing Job-Level Outputs

```yaml
# WRONG - outputs defined only at step level
generate:
  steps:
    - id: set
      run: echo "matrix=..." >> $GITHUB_OUTPUT

# CORRECT - must also define at job level
generate:
  outputs:
    matrix: ${{ steps.set.outputs.matrix }}
  steps:
    - id: set
      run: echo "matrix=..." >> $GITHUB_OUTPUT
```

### 5. ❌ Empty Matrix

If your generated list is empty `[]`, the matrix job will be skipped without error. Use conditional checks if you need to handle this:

```yaml
process:
  needs: generate
  if: needs.generate.outputs.has-items == 'true'
```

## Advanced Features

### Matrix Options

```yaml
strategy:
  matrix: ${{ fromJSON(needs.generate.outputs.matrix) }}
  fail-fast: false      # Continue other jobs if one fails
  max-parallel: 3       # Limit concurrent jobs
```

### Exclude Combinations

```yaml
strategy:
  matrix:
    app: ["app1", "app2"]
    env: ["dev", "prod"]
    exclude:
      - app: "app1"
        env: "prod"  # Don't deploy app1 to prod
```

### Dynamic Excludes

Generate the exclude list in your generation job:

```json
{
  "app": ["app1", "app2"],
  "env": ["dev", "prod"],
  "exclude": [
    {"app": "app1", "env": "prod"}
  ]
}
```

## Examples in This Repository

1. **`simple-dynamic-matrix.yml`** - Minimal example showing the core pattern
2. **`dynamic-matrix-example.yml`** - Comprehensive example with multiple patterns
3. **`deploy-argocd-apps.yml`** - Real-world usage (directory discovery)

## Testing Your Matrix

To test matrix generation without running full deployments:

```yaml
- name: Debug matrix
  run: |
    echo "Matrix JSON:"
    echo '${{ needs.generate.outputs.matrix }}' | jq .
    
    echo "Matrix will create these jobs:"
    echo '${{ needs.generate.outputs.matrix }}' | jq -r '.include[] | "- \(.app) / \(.env)"'
```

## References

- [GitHub Actions: Matrix Strategy](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
- [GitHub Actions: Outputs](https://docs.github.com/en/actions/using-jobs/defining-outputs-for-jobs)
- [GitHub Actions: Contexts](https://docs.github.com/en/actions/learn-github-actions/contexts#needs-context)

