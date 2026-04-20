# Dynamic Matrix & Changed Directories - Complete Index

## 📚 Documentation Overview

This collection provides everything you need to implement dynamic matrices and changed directory detection in GitHub Actions.

## 🚀 Quick Start (Choose Your Path)

### Path 1: I want to see working examples first
1. Start with [`simple-dynamic-matrix.yml`](./simple-dynamic-matrix.yml)
2. Check [`QUICK-REFERENCE.md`](./QUICK-REFERENCE.md) for patterns
3. Deploy with [`deploy-changed-apps-matrix.yml`](./deploy-changed-apps-matrix.yml)

### Path 2: I want to understand the concepts
1. Read [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md)
2. Read [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md)
3. Review [`METHOD-COMPARISON.md`](./METHOD-COMPARISON.md)
4. Try [`simple-dynamic-matrix.yml`](./simple-dynamic-matrix.yml)

### Path 3: I need a production-ready solution
1. Review [`deploy-changed-apps-matrix.yml`](./deploy-changed-apps-matrix.yml)
2. Consult [`METHOD-COMPARISON.md`](./METHOD-COMPARISON.md) to pick your approach
3. Use [`QUICK-REFERENCE.md`](./QUICK-REFERENCE.md) as you build
4. Refer to detailed guides as needed

## 📖 Documentation Files

### 📘 Guides (Comprehensive)

| File | Purpose | Audience | Length |
|------|---------|----------|--------|
| [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md) | Complete guide to dynamic matrices | All levels | ~15 min |
| [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md) | All methods for detecting changes | All levels | ~20 min |
| [`METHOD-COMPARISON.md`](./METHOD-COMPARISON.md) | Compare detection approaches | Decision makers | ~10 min |

### 📗 Reference (Quick Lookup)

| File | Purpose | Audience | Length |
|------|---------|----------|--------|
| [`QUICK-REFERENCE.md`](./QUICK-REFERENCE.md) | Syntax cheat sheet | Developers | ~5 min |

### 📙 Examples (Working Code)

| File | Description | Complexity | Best For |
|------|-------------|-----------|----------|
| [`simple-dynamic-matrix.yml`](./simple-dynamic-matrix.yml) | Minimal example | ⭐ Basic | Learning |
| [`dynamic-matrix-example.yml`](./dynamic-matrix-example.yml) | Multiple patterns | ⭐⭐⭐ Advanced | Reference |
| [`detect-changed-directories.yml`](./detect-changed-directories.yml) | All detection methods | ⭐⭐⭐ Advanced | Comparison |
| [`deploy-changed-apps-matrix.yml`](./deploy-changed-apps-matrix.yml) | Production workflow | ⭐⭐⭐⭐ Expert | Production |

## 🎯 By Use Case

### Use Case: Deploy Only Changed Apps

**What you need:**
1. Detect changed directories → [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md)
2. Create dynamic matrix → [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md)
3. Deploy strategy → [`deploy-changed-apps-matrix.yml`](./deploy-changed-apps-matrix.yml)

**Quick reference:**
```yaml
# Detect
git diff --name-only $BASE $HEAD | grep '^apps/' | cut -d'/' -f2 | sort -u

# Matrix
strategy:
  matrix:
    app: ${{ fromJSON(needs.detect.outputs.apps) }}
```

---

### Use Case: Dynamic Matrix from Any Source

**What you need:**
1. Matrix fundamentals → [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md)
2. Example patterns → [`dynamic-matrix-example.yml`](./dynamic-matrix-example.yml)
3. Syntax reference → [`QUICK-REFERENCE.md`](./QUICK-REFERENCE.md)

**Quick reference:**
```yaml
generate:
  outputs:
    matrix: ${{ steps.set.outputs.matrix }}
  steps:
    - id: set
      run: echo "matrix=[...]" >> $GITHUB_OUTPUT

process:
  needs: generate
  strategy:
    matrix:
      item: ${{ fromJSON(needs.generate.outputs.matrix) }}
```

---

### Use Case: Choose the Right Detection Method

**What you need:**
1. Decision guide → [`METHOD-COMPARISON.md`](./METHOD-COMPARISON.md)
2. Implementation examples → [`detect-changed-directories.yml`](./detect-changed-directories.yml)

**Quick decision:**
- **Simple conditional:** Use `dorny/paths-filter`
- **Dynamic matrix:** Use native `git diff` or `tj-actions/changed-files`
- **Complex logic:** Use native `git diff`

---

### Use Case: Optimize CI/CD Pipeline

**What you need:**
1. Change detection → [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md)
2. Matrix optimization → [`deploy-changed-apps-matrix.yml`](./deploy-changed-apps-matrix.yml)
3. Method comparison → [`METHOD-COMPARISON.md`](./METHOD-COMPARISON.md)

**Strategy:**
```
Changed apps only → Deploy changed
Core infrastructure changed → Deploy all
No changes → Skip
```

## 🔍 Common Questions

### Q: How do I generate a matrix from changed files?

**Answer:** Two steps:
1. Detect changes and output as JSON array
2. Use `fromJSON()` in matrix strategy

**See:**
- [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md) - The Pattern section
- [`simple-dynamic-matrix.yml`](./simple-dynamic-matrix.yml) - Working example
- [`QUICK-REFERENCE.md`](./QUICK-REFERENCE.md) - Core Pattern

---

### Q: What's the best way to detect changed directories?

**Answer:** Depends on your needs:
- **Simplicity:** `tj-actions/changed-files`
- **Flexibility:** Native `git diff`
- **Conditionals:** `dorny/paths-filter`

**See:**
- [`METHOD-COMPARISON.md`](./METHOD-COMPARISON.md) - Complete comparison
- [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md) - All methods

---

### Q: How do I deploy only changed apps?

**Answer:** Detect changed app directories, generate matrix, deploy each.

**See:**
- [`deploy-changed-apps-matrix.yml`](./deploy-changed-apps-matrix.yml) - Complete example
- [`QUICK-REFERENCE.md`](./QUICK-REFERENCE.md) - Complete Flow section

---

### Q: Can I deploy all apps if core infrastructure changed?

**Answer:** Yes! Check for infrastructure changes, then conditionally set the app list.

**See:**
- [`deploy-changed-apps-matrix.yml`](./deploy-changed-apps-matrix.yml) - See "Determine deployment strategy" step
- [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md) - Pattern 2

---

### Q: My matrix is empty, what do I do?

**Answer:** Add a conditional to skip the job if no changes detected.

```yaml
if: needs.detect.outputs.apps != '[]'
```

**See:**
- [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md) - Common Pitfalls #5
- [`QUICK-REFERENCE.md`](./QUICK-REFERENCE.md) - Common Pitfalls

---

### Q: How do I handle pull requests vs pushes differently?

**Answer:** Use event conditionals and different git comparison refs.

**See:**
- [`deploy-changed-apps-matrix.yml`](./deploy-changed-apps-matrix.yml) - See job conditions
- [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md) - Method 1

---

## 📊 Complexity Levels

### ⭐ Beginner
Start here if you're new to dynamic matrices or change detection.

**Resources:**
- [`simple-dynamic-matrix.yml`](./simple-dynamic-matrix.yml)
- [`QUICK-REFERENCE.md`](./QUICK-REFERENCE.md) - Core Pattern section
- [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md) - The Pattern section

### ⭐⭐ Intermediate
You understand basics, want more patterns.

**Resources:**
- [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md) - Full guide
- [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md) - Methods 1-2
- [`dynamic-matrix-example.yml`](./dynamic-matrix-example.yml)

### ⭐⭐⭐ Advanced
You need complex patterns and custom logic.

**Resources:**
- [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md) - All patterns
- [`METHOD-COMPARISON.md`](./METHOD-COMPARISON.md)
- [`detect-changed-directories.yml`](./detect-changed-directories.yml)

### ⭐⭐⭐⭐ Expert
Production-ready, optimized workflows.

**Resources:**
- [`deploy-changed-apps-matrix.yml`](./deploy-changed-apps-matrix.yml)
- All guides for reference
- [`METHOD-COMPARISON.md`](./METHOD-COMPARISON.md) - Performance section

## 🛠️ Tools & Resources

### Required Tools
- GitHub Actions (built-in)
- Git (built-in)
- `jq` (for JSON processing)

### Optional Actions
- `tj-actions/changed-files@v44`
- `dorny/paths-filter@v3`

### External Documentation
- [GitHub Actions: Matrix Strategy](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
- [GitHub Actions: Job Outputs](https://docs.github.com/en/actions/using-jobs/defining-outputs-for-jobs)
- [Git diff documentation](https://git-scm.com/docs/git-diff)

## 📝 Cheat Sheet

### Essential Syntax

```yaml
# Job outputs
job:
  outputs:
    key: ${{ steps.id.outputs.key }}

# Step outputs
steps:
  - id: id
    run: echo "key=value" >> $GITHUB_OUTPUT

# Matrix from output
strategy:
  matrix:
    item: ${{ fromJSON(needs.job.outputs.key) }}

# Detect changes
git diff --name-only $BASE $HEAD | cut -d'/' -f1 | sort -u

# JSON array
jq -R -s -c 'split("\n") | map(select(length > 0))'
```

## 🎓 Learning Path

### Week 1: Fundamentals
1. Read [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md)
2. Try [`simple-dynamic-matrix.yml`](./simple-dynamic-matrix.yml)
3. Experiment with static matrices first

### Week 2: Change Detection
1. Read [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md)
2. Try [`detect-changed-directories.yml`](./detect-changed-directories.yml)
3. Practice with `git diff` locally

### Week 3: Integration
1. Study [`deploy-changed-apps-matrix.yml`](./deploy-changed-apps-matrix.yml)
2. Implement in your project
3. Iterate based on needs

### Week 4: Optimization
1. Review [`METHOD-COMPARISON.md`](./METHOD-COMPARISON.md)
2. Optimize your implementation
3. Add error handling and edge cases

## 🎯 Success Criteria

You've mastered dynamic matrices and change detection when you can:

- ✅ Generate a dynamic matrix from any data source
- ✅ Detect changed directories in push and PR events
- ✅ Choose the right detection method for your use case
- ✅ Handle edge cases (empty matrices, first push, etc.)
- ✅ Deploy only changed components to optimize CI/CD
- ✅ Debug matrix generation issues
- ✅ Implement conditional deployment strategies

## 🆘 Getting Help

### Troubleshooting Steps
1. Check [`QUICK-REFERENCE.md`](./QUICK-REFERENCE.md) - Common Pitfalls
2. Review [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md) - Common Pitfalls section
3. See [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md) - Troubleshooting section
4. Compare your code with working examples

### Debug Checklist
- [ ] Job has `outputs` defined
- [ ] Step has `id` defined
- [ ] Using `fromJSON()` in matrix
- [ ] JSON is valid (test with `jq`)
- [ ] `fetch-depth: 0` for git operations
- [ ] Correct BASE/HEAD refs
- [ ] Handle empty arrays with conditionals

## 🎉 Quick Wins

### 1. Basic Dynamic Matrix (5 minutes)
Use [`simple-dynamic-matrix.yml`](./simple-dynamic-matrix.yml) as template

### 2. Detect Changed Directories (10 minutes)
Copy detection step from [`detect-changed-directories.yml`](./detect-changed-directories.yml)

### 3. Deploy Changed Apps (30 minutes)
Adapt [`deploy-changed-apps-matrix.yml`](./deploy-changed-apps-matrix.yml) to your needs

## 📅 Last Updated

January 2025

## 📄 Related Documentation

- [Main README](./README.md) - ArgoCD workflows overview
- [SETUP.md](./SETUP.md) - Setup instructions
- [WORKFLOW-DIAGRAM.md](./WORKFLOW-DIAGRAM.md) - Workflow visualizations

---

**Start here:** [`QUICK-REFERENCE.md`](./QUICK-REFERENCE.md) for immediate patterns, or [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md) for comprehensive understanding.

