# Detecting Changed Directories in GitHub Actions

## Overview

Detecting which directories have changed is crucial for optimizing CI/CD pipelines. Instead of running all jobs, you can selectively run only the jobs needed for the changed parts of your codebase.

## Methods Comparison

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| Native `git diff` | No dependencies, full control | More complex, requires git knowledge | Custom logic, full control |
| `tj-actions/changed-files` | Feature-rich, maintained | External dependency | Most use cases |
| `dorny/paths-filter` | Simple conditional logic | Less flexible for matrices | Simple path-based triggers |
| GitHub API | Access to PR metadata | Requires API calls, token | Complex PR workflows |

## Method 1: Native Git Diff (Recommended for Flexibility)

### Basic Pattern

```yaml
jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      changed-dirs: ${{ steps.detect.outputs.changed-dirs }}
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Important: fetch history for comparison
      
      - name: Detect changes
        id: detect
        run: |
          # Determine comparison range
          if [ "${{ github.event_name }}" == "pull_request" ]; then
            BASE="${{ github.event.pull_request.base.sha }}"
            HEAD="${{ github.event.pull_request.head.sha }}"
          else
            BASE="${{ github.event.before }}"
            HEAD="${{ github.sha }}"
          fi
          
          # Get changed directories
          CHANGED=$(git diff --name-only "$BASE" "$HEAD" | \
            cut -d'/' -f1 | \
            sort -u | \
            jq -R -s -c 'split("\n") | map(select(length > 0))')
          
          echo "changed-dirs=$CHANGED" >> $GITHUB_OUTPUT
```

### Extract Specific Directory Levels

```bash
# Top-level directories only
git diff --name-only "$BASE" "$HEAD" | cut -d'/' -f1 | sort -u

# Second-level (e.g., apps/example-app -> example-app)
git diff --name-only "$BASE" "$HEAD" | \
  grep '^apps/' | \
  cut -d'/' -f2 | \
  sort -u

# Full path to depth 2 (e.g., apps/example-app)
git diff --name-only "$BASE" "$HEAD" | \
  cut -d'/' -f1-2 | \
  sort -u

# Filter by pattern
git diff --name-only "$BASE" "$HEAD" | \
  grep '^apps/' | \
  cut -d'/' -f1-2 | \
  sort -u
```

### Handle Edge Cases

```bash
# Handle first push to branch (no previous commit)
if [ "${{ github.event.before }}" == "0000000000000000000000000000000000000000" ]; then
  BASE="origin/main"  # Compare against main branch
else
  BASE="${{ github.event.before }}"
fi

# Handle empty results
CHANGED=$(git diff --name-only "$BASE" "$HEAD" | cut -d'/' -f1 | sort -u)
if [ -z "$CHANGED" ]; then
  echo "changed-dirs=[]" >> $GITHUB_OUTPUT
else
  CHANGED_JSON=$(echo "$CHANGED" | jq -R -s -c 'split("\n") | map(select(length > 0))')
  echo "changed-dirs=$CHANGED_JSON" >> $GITHUB_OUTPUT
fi
```

## Method 2: tj-actions/changed-files (Recommended for Simplicity)

### Basic Usage

```yaml
steps:
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0
  
  - name: Get changed files
    id: changed-files
    uses: tj-actions/changed-files@v44
    with:
      files: apps/**
      json: true
      dir_names: true
      dir_names_max_depth: 2
  
  - name: Process changes
    run: |
      echo "Changed: ${{ steps.changed-files.outputs.all_changed_files }}"
```

### Advanced Options

```yaml
- uses: tj-actions/changed-files@v44
  with:
    # Only files in specific directories
    files: |
      apps/**
      infrastructure/**
    
    # Exclude patterns
    files_ignore: |
      **/*.md
      **/.gitignore
    
    # Output format
    json: true                    # JSON array output
    dir_names: true               # Return directory names, not files
    dir_names_max_depth: 2        # Depth of directory names
    
    # Comparison
    since_last_remote_commit: true  # Compare with remote
    
    # Performance
    fetch_depth: 0                # History depth (0 = all)
```

### Extract Directory Names

```yaml
- name: Build matrix from changed files
  id: matrix
  run: |
    CHANGED='${{ steps.changed-files.outputs.all_changed_files }}'
    
    # Extract app directories
    APPS=$(echo "$CHANGED" | jq -c '[.[] | 
      select(startswith("apps/")) | 
      split("/")[1]] | 
      unique')
    
    echo "matrix=$APPS" >> $GITHUB_OUTPUT
```

## Method 3: dorny/paths-filter (Path-Based Conditionals)

### Static Filters

```yaml
- uses: dorny/paths-filter@v3
  id: filter
  with:
    filters: |
      frontend:
        - 'apps/frontend/**'
      backend:
        - 'apps/backend/**'
      infrastructure:
        - 'infrastructure/**'

- name: Check results
  run: |
    echo "Frontend changed: ${{ steps.filter.outputs.frontend }}"
    echo "Backend changed: ${{ steps.filter.outputs.backend }}"
```

### Use in Job Conditions

```yaml
jobs:
  detect:
    outputs:
      frontend: ${{ steps.filter.outputs.frontend }}
      backend: ${{ steps.filter.outputs.backend }}
    steps:
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            frontend: 'apps/frontend/**'
            backend: 'apps/backend/**'

  deploy-frontend:
    needs: detect
    if: needs.detect.outputs.frontend == 'true'
    steps:
      - run: echo "Deploy frontend"

  deploy-backend:
    needs: detect
    if: needs.detect.outputs.backend == 'true'
    steps:
      - run: echo "Deploy backend"
```

### Get List of Changed Filters

```yaml
- uses: dorny/paths-filter@v3
  id: filter
  with:
    list-files: json
    filters: |
      app1: 'apps/app1/**'
      app2: 'apps/app2/**'
      app3: 'apps/app3/**'

# Returns JSON array of filter names that matched
# e.g., ["app1", "app3"]
- run: echo "Changed: ${{ steps.filter.outputs.changes }}"
```

## Method 4: GitHub API (Advanced)

```yaml
- name: Get changed files via API
  run: |
    CHANGED_FILES=$(curl -s -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
      "https://api.github.com/repos/${{ github.repository }}/pulls/${{ github.event.pull_request.number }}/files" | \
      jq -r '.[].filename')
    
    CHANGED_DIRS=$(echo "$CHANGED_FILES" | cut -d'/' -f1 | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))')
    echo "changed-dirs=$CHANGED_DIRS" >> $GITHUB_OUTPUT
```

## Common Patterns

### Pattern 1: Deploy Only Changed Apps

```yaml
jobs:
  detect:
    outputs:
      apps: ${{ steps.detect.outputs.apps }}
      has-changes: ${{ steps.detect.outputs.has-changes }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - id: detect
        run: |
          BASE="${{ github.event.pull_request.base.sha || github.event.before }}"
          HEAD="${{ github.sha }}"
          
          APPS=$(git diff --name-only "$BASE" "$HEAD" | \
            grep '^apps/' | \
            cut -d'/' -f2 | \
            sort -u | \
            jq -R -s -c 'split("\n") | map(select(length > 0))')
          
          HAS_CHANGES=$(echo "$APPS" | jq 'length > 0')
          
          echo "apps=$APPS" >> $GITHUB_OUTPUT
          echo "has-changes=$HAS_CHANGES" >> $GITHUB_OUTPUT

  deploy:
    needs: detect
    if: needs.detect.outputs.has-changes == 'true'
    strategy:
      matrix:
        app: ${{ fromJSON(needs.detect.outputs.apps) }}
    steps:
      - run: echo "Deploy ${{ matrix.app }}"
```

### Pattern 2: Deploy All if Core Changed

```yaml
jobs:
  detect:
    outputs:
      core-changed: ${{ steps.detect.outputs.core-changed }}
      apps: ${{ steps.detect.outputs.apps }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - id: detect
        run: |
          BASE="${{ github.event.pull_request.base.sha || github.event.before }}"
          HEAD="${{ github.sha }}"
          
          # Check if core files changed
          CORE_CHANGED=$(git diff --name-only "$BASE" "$HEAD" | \
            grep -E '^(charts/|infrastructure/|hubs.yaml)' || true)
          
          if [ -n "$CORE_CHANGED" ]; then
            echo "core-changed=true" >> $GITHUB_OUTPUT
            # Get all apps
            ALL_APPS=$(find ./apps -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | jq -R -s -c 'split("\n") | map(select(length > 0))')
            echo "apps=$ALL_APPS" >> $GITHUB_OUTPUT
          else
            echo "core-changed=false" >> $GITHUB_OUTPUT
            # Get only changed apps
            CHANGED_APPS=$(git diff --name-only "$BASE" "$HEAD" | \
              grep '^apps/' | \
              cut -d'/' -f2 | \
              sort -u | \
              jq -R -s -c 'split("\n") | map(select(length > 0))')
            echo "apps=$CHANGED_APPS" >> $GITHUB_OUTPUT
          fi

  deploy:
    needs: detect
    strategy:
      matrix:
        app: ${{ fromJSON(needs.detect.outputs.apps) }}
    steps:
      - name: Deploy
        run: |
          if [ "${{ needs.detect.outputs.core-changed }}" == "true" ]; then
            echo "🔄 Core infrastructure changed - deploying ${{ matrix.app }}"
          else
            echo "📝 App-specific change - deploying ${{ matrix.app }}"
          fi
```

### Pattern 3: Exclude Documentation Changes

```yaml
- name: Get meaningful changes
  id: detect
  run: |
    BASE="${{ github.event.pull_request.base.sha || github.event.before }}"
    HEAD="${{ github.sha }}"
    
    # Get all changed files except docs
    CHANGED=$(git diff --name-only "$BASE" "$HEAD" | \
      grep -v '\.md$' | \
      grep -v '^docs/' | \
      cut -d'/' -f1 | \
      sort -u | \
      jq -R -s -c 'split("\n") | map(select(length > 0))')
    
    echo "changed-dirs=$CHANGED" >> $GITHUB_OUTPUT
```

### Pattern 4: Different Strategies Per Directory

```yaml
jobs:
  detect:
    outputs:
      apps: ${{ steps.detect.outputs.apps }}
      infrastructure: ${{ steps.detect.outputs.infrastructure }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - id: detect
        run: |
          BASE="${{ github.event.pull_request.base.sha || github.event.before }}"
          HEAD="${{ github.sha }}"
          
          # Detect changed apps
          APPS=$(git diff --name-only "$BASE" "$HEAD" | \
            grep '^apps/' | cut -d'/' -f2 | sort -u | \
            jq -R -s -c 'split("\n") | map(select(length > 0))')
          echo "apps=$APPS" >> $GITHUB_OUTPUT
          
          # Detect infrastructure changes (boolean)
          INFRA_CHANGED=$(git diff --name-only "$BASE" "$HEAD" | grep '^infrastructure/' || true)
          if [ -n "$INFRA_CHANGED" ]; then
            echo "infrastructure=true" >> $GITHUB_OUTPUT
          else
            echo "infrastructure=false" >> $GITHUB_OUTPUT
          fi

  deploy-apps:
    needs: detect
    if: needs.detect.outputs.apps != '[]'
    strategy:
      matrix:
        app: ${{ fromJSON(needs.detect.outputs.apps) }}
    steps:
      - run: echo "Deploy app: ${{ matrix.app }}"

  deploy-infrastructure:
    needs: detect
    if: needs.detect.outputs.infrastructure == 'true'
    steps:
      - run: echo "Deploy infrastructure"
```

## Troubleshooting

### Problem: No Changes Detected

**Cause:** Insufficient git history

**Solution:**
```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Fetch all history
```

### Problem: First Push to Branch Fails

**Cause:** `github.event.before` is all zeros

**Solution:**
```bash
if [ "${{ github.event.before }}" == "0000000000000000000000000000000000000000" ]; then
  BASE="origin/main"
else
  BASE="${{ github.event.before }}"
fi
```

### Problem: Empty Array Breaks Matrix

**Cause:** No changes detected, matrix receives `[]`

**Solution:**
```yaml
deploy:
  needs: detect
  if: needs.detect.outputs.apps != '[]'  # Skip if empty
  strategy:
    matrix:
      app: ${{ fromJSON(needs.detect.outputs.apps) }}
```

### Problem: Wrong Directories Detected

**Cause:** Incorrect path parsing

**Solution:** Test your parsing logic:
```bash
# Debug: Show all changed files
git diff --name-only "$BASE" "$HEAD"

# Debug: Show parsing steps
git diff --name-only "$BASE" "$HEAD" | cut -d'/' -f1
git diff --name-only "$BASE" "$HEAD" | cut -d'/' -f2
```

## Performance Considerations

### Shallow vs Full Clone

```yaml
# Fast but limited history (good for simple diffs)
- uses: actions/checkout@v4
  with:
    fetch-depth: 1

# Full history (needed for complex comparisons)
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
```

### Caching

```yaml
# Cache git repository for subsequent jobs
- uses: actions/cache@v4
  with:
    path: .git
    key: git-${{ github.sha }}
```

## Examples in This Repository

- `detect-changed-directories.yml` - Comprehensive examples of all methods
- `deploy-argocd-apps.yml` - Real-world usage with directory discovery
- `simple-dynamic-matrix.yml` - Basic dynamic matrix pattern

## References

- [Git diff documentation](https://git-scm.com/docs/git-diff)
- [tj-actions/changed-files](https://github.com/tj-actions/changed-files)
- [dorny/paths-filter](https://github.com/dorny/paths-filter)
- [GitHub Actions Contexts](https://docs.github.com/en/actions/learn-github-actions/contexts)

