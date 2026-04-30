# GitOps Lab — App-of-Apps with ArgoCD

This lab teaches the components / groups / cluster cascade pattern for GitOps with ArgoCD. You add a live application component to a shared cluster by editing four files and pushing — without running `oc apply`.

---

## Prerequisites

**Tools**
- `git` installed and configured (`git config user.name` and `user.email`)
- `oc` CLI with access to the lab cluster

**Access**
- Push access to the shared lab repo (URL and credentials from your instructor)
- ArgoCD UI URL and read access (from your instructor)

**Knowledge**
- Basic Git workflow (clone, commit, push)
- No ArgoCD experience required

---

## Getting Started

1. Get the repo URL, credentials, and ArgoCD UI URL from your instructor.

2. Clone the repo:
   ```bash
   git clone <repo-url>
   cd <repo-name>
   ```

3. Open the ArgoCD UI and confirm the `example` Application is **Synced / Healthy** — this is your working reference.

4. Follow [LAB-GUIDE.md](LAB-GUIDE.md) from Step 1 through the stretch goal.

---

## Time

~1 hour.
