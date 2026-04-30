# ArgoCD Sync Settings Lab

This lab teaches ArgoCD sync configuration — automated sync, prune, self-heal, sync options, ignore differences, retry, sync waves, and hooks — through ten progressive exercises. Sync settings are controlled via your GitOps cascade values files, not the ArgoCD UI.

---

## Prerequisites

**Tools**
- `git` installed and configured (`git config user.name` and `user.email`)
- `oc` CLI with access to the lab cluster

**Access**
- Push access to the shared lab repo (URL and credentials from your instructor)
- ArgoCD UI URL and credentials (from your instructor)

**Knowledge**
- Basic Git workflow (clone, commit, push)
- Familiarity with the components / groups / cluster cascade pattern is helpful — the GitOps intro lab covers this, but the setup step here is self-contained

**Cluster**
- ArgoCD 2.6 or later (required for the multiple-sources feature used by the root app)

---

## Getting Started

The lab runs in three independent one-hour sessions. Session 1 is the prerequisite for Sessions 2 and 3; Sessions 2 and 3 can be taken in either order.

1. Get the repo URL, credentials, and ArgoCD UI URL from your instructor.

2. Clone the repo:
   ```bash
   git clone <repo-url>
   cd <repo-name>
   ```

3. Complete the one-time setup in [LAB-OVERVIEW.md](LAB-OVERVIEW.md) under **Setup — Register Your Component**. This registers your component and leaves it in the correct starting state for Session 1. Do not sync the Application yet.

4. Attend each session using the corresponding guide:
   - Session 1 — Sync Modes: [LAB-SESSION-1.md](LAB-SESSION-1.md)
   - Session 2 — Application-Level Controls: [LAB-SESSION-2.md](LAB-SESSION-2.md)
   - Session 3 — Resource-Level Control: [LAB-SESSION-3.md](LAB-SESSION-3.md)

5. Run the cleanup steps in [LAB-OVERVIEW.md](LAB-OVERVIEW.md) after your final session.

---

## Time

~1 hour per session. All three sessions total roughly 2–3 hours. For audiences new to ArgoCD, Session 1 (Exercises 1–4) is a solid standalone.
