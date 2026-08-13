---
review:
  status: unreviewed
  notes: "Testing & verification deep dive — sandbox shift-left, automation levels."
---

# Testing & Verification — maturity deep dive

> **Audience:** Teams assessing how early defects are found and how much verification is automated.
>
> **Purpose:** Center the deck's **sandbox** story — who discovers bugs where — and connect to CI maturity.

**Related:** [Deployment](deployment-and-release.md) · [Code quality](code-quality.md) · [Trailhead](../software-systems-maturity.md#testing--verification)

---

## What this axis answers

*How far left do we push discovery — before production?*

---

## Sandbox discipline (2016 deck)

Each environment is isolated with its own backing services ([12-factor backing services](https://12factor.net/backing-services)). **Who finds the bug** maps to maturity:

| Stage | Responsible | Deck verdict |
|---|---|---|
| Development | Developer | Good |
| Integration | Team / QA | Good |
| Demo / QA | Team + stakeholders | Acceptable |
| Production | Customer | **Too late** |

Push verification left — production discovery is level 1 behavior regardless of test count.

Reference: [sandbox methodology (Scott Ambler)](http://www.agiledata.org/essays/sandboxes.html)

---

## Levels

| Level | Posture |
|---|---|
| **1** | Ad hoc manual testing; bugs in prod |
| **2** | Test plans documented |
| **3** | Automated unit/integration; runs in non-prod |
| **4** | CI gates merges; coverage informs risk |
| **5** | Performance/security tests; fix when found |

**Terms from deck:**

- **Regression** — verify unintended side effects  
- **Non-regression** — verify intended effect  
- **Smoke test** — minimal "does it run?" subset  

[TDD](https://martinfowler.com/bliki/TestDrivenDevelopment.html) is one path to level 3 — not the only path.

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| "QA will catch it" | Sandboxes skipped |
| Flaky tests ignored | CI trust erodes → level 4 theater |
| 100% coverage goal without assertion quality | Gaming metrics |
| No test env parity | Passes in test, fails in prod |

---

## Repo examples

| Topic | Path |
|---|---|
| Network verification script pattern | [cross-dc-network-test](../../../devops/ocp/examples/networking/cross-dc-network-test/README.md) (operational checks, not unit tests) |
| CI values / chart testing | [argo examples CI](../../../devops/argo/examples/README.md) |

**Gap:** no unified unit/integration maturity guide in-repo.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
