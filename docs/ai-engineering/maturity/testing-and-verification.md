---
review:
  status: unreviewed
  notes: "Testing & verification v2 — sandbox, DORA change failure rate, systems verification corpus."
---

# Testing & Verification — maturity deep dive

> **Audience:** Teams assessing how early defects are found and how much verification is automated — application, platform, and **operational pre-flight** work.
>
> **Purpose:** Center the deck's **sandbox** story (who finds bugs where), map levels to DORA **change failure rate**, and link verification patterns in this repo.

**Related:** [Deployment](deployment-and-release.md) · [Builds & artifacts](builds-and-artifacts.md) · [Code quality](code-quality.md) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) · [Trailhead](../software-systems-maturity.md#testing--verification)

---

## What this axis answers

*How far left do we push discovery — before production?*

Testing maturity is not test **count**. A large suite that runs only before release, or only in production via customers, stays low maturity. The deck's verdict: **customer discovers the problem = too late**.

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

Connects to [deployment](deployment-and-release.md) — promotion through environments should **increase fidelity**, not skip straight to prod.

---

## Levels

| Level | Posture |
|---|---|
| **0** | No test intent; production is the test environment |
| **1** | Ad hoc manual testing; bugs frequently found in prod |
| **2** | Test plans documented; cases and expected behaviors written |
| **3** | Automated unit/integration (or equivalent); runs in non-prod |
| **4** | CI gates merges; coverage or risk analysis informs what to run |
| **5** | Performance/security characterization; defects fixed when found |

**DORA/Accelerate alignment:** **Test automation** supports lower **change failure rate** and safer **deployment frequency** — but only when tests run **before** merge or promote, not after prod. See [DORA research note — testing axis](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md#testing-axis-dora-links).

**Joel Test #10** (testers): maps here — dedicated testers or **automated equivalent** ≈ L3+.

---

## Deck lineage (2016 → 2026)

| 2016 deck tier | 2026 level | Notes |
|---|---|---|
| No testing / ad-hoc; bugs in prod | **1** | Sandbox failure — customer finds bugs |
| Test plan documentation | **2** | Cases documented, execution may still be manual |
| Unit & integration automation; non-prod | **3** | Deck: "separate, non-production environment" |
| Integrated testing (CI/CD); coverage | **4** | Split from [builds](builds-and-artifacts.md) (CI hosts tests) |
| Performance & security; fix immediately | **5** | Characterization + response discipline |

---

## Terms (from deck)

| Term | Meaning in this model |
|---|---|
| **Regression** | Verify change did not cause **unintended** side effects (deck wording) |
| **Non-regression** | Verify change had **intended** effect |
| **Smoke test** | Minimal subset — "does it run?" |

[TDD](https://martinfowler.com/bliki/TestDrivenDevelopment.html) is one path to level 3 — not the only path.

**Systems engineering extension:** not all verification is xUnit. **Operational verification** (network probes, preflight gates, `helm template` + dry-run) counts toward L3–4 when automated and run before promote.

---

## Evidence in this workspace

| Level | What it looks like | Repo paths |
|---|---|---|
| **3–4** | Scenario regression harness (declarative + Ansible) | [bare-metal-dev-sandbox/HARNESS.md](../../../devops/bare-metal-dev-sandbox/HARNESS.md) · `scenarios/` |
| **3–4** | Pre-cutover network verification (isolated from workload) | [cross-dc-network-test/](../../../devops/ocp/examples/networking/cross-dc-network-test/README.md) |
| **4** | CI validate — lint, template, dry-run, diff on PR | [validate-pr.yaml](../../../devops/argo/examples/framework/pipelines/github-actions/validate-pr.yaml) · [github-workflows](../../../devops/argo/examples/github-workflows/README.md) |
| **4** | Promotion gates — test in lower env before prod branch | [framework promotion](../../../devops/argo/examples/framework/README.md) |
| **4** | Hands-on GitOps verification labs | [argo/labs/](../../../devops/argo/labs/README.md) |
| **4–5** | Live operator upgrade chain validation narrative | [operators-installer upstream PR doc](../../../devops/argo/examples/examples/operators-installer/docs/upstream-pr-description.md) |
| **4** | Docs/devops link + frontmatter checks | Root pre-commit |
| **Gap** | Unified app unit/integration testing guide | By design partial — platform corpus skew |

**Pattern:** [cross-dc-network-test](../../../devops/ocp/examples/networking/cross-dc-network-test/README.md) — prove the **layer below the workload** (network) before blaming Kafka — exemplifies sandbox discipline for systems work.

---

## Verification types (systems lens)

| Type | Typical home | Maturity signal |
|---|---|---|
| Unit / component | App repos | L3 automation |
| Integration / API | CI pipeline | L3–4 |
| Render / policy dry-run | GitOps CI | L4 gate ([builds](builds-and-artifacts.md) + this axis) |
| Operational / pre-flight | Scenario harness, runbooks | L3–4 when automated |
| Performance / security | Dedicated suites | L5 |
| Production observability | [Monitoring](monitoring-and-reliability.md) | Detect — not substitute for L3+ |

---

## AI era

| Observation | Testing implication |
|---|---|
| Agent claims "I tested it" locally | Not L3 until CI/automated suite runs on the PR |
| Agent-generated tests | Assertion quality matters — coverage theater at L4 |
| Faster code volume | Flaky tests erode CI trust faster — fix or delete |
| Eval harnesses for agents | Emerging L4–5 for **AI agents axis** — not a substitute for app regression |
| Missing test env parity | Same as pre-AI — passes locally, fails in prod |

**DORA:** AI may reduce time to write tests; **change failure rate** improves only when those tests gate promotion. See [AI agents deep dive](ai-agents-and-harnesses.md) for harness/eval overlap.

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| "QA will catch it" | Sandboxes skipped |
| Flaky tests ignored | CI trust erodes → level 4 theater |
| 100% coverage goal without assertion quality | Gaming metrics |
| No test env parity | Passes in test, fails in prod |
| Network/workload conflated in one debug session | Use layer-isolated verification ([cross-dc-network-test](../../../devops/ocp/examples/networking/cross-dc-network-test/README.md)) |
| Agent merge without CI green | Deployment L4 with testing L1 skew |

---

## Cross-axis dependencies

```text
Testing ──gates───────────────▶ Builds (CI must run tests)
Testing ──enables safe────────▶ Deployment (lower change failure rate)
Testing ──overlaps────────────▶ Code quality (review + lint + tests)
Testing ──complements─────────▶ Monitoring (detect what tests miss)
Builds ──hosts────────────────▶ Testing (pipeline stages)
AI agents ──needs─────────────▶ Testing (eval + CI on generated code)
```

---

## Teaching note — automation (from deck)

*"Testing the same thing over and over is mind-numbing and boring — good news, it can be automated!"*

The deck's progression from documented plans → automated suites → CI integration is the core story. For platform teams, **automate the boring verification** (lint, template, dry-run, scenario matrix) before asking humans to re-check the same YAML in every PR.

---

## Research and external validation

| Source | What it supports | Limit |
|---|---|---|
| [Ambler — sandboxes](http://www.agiledata.org/essays/sandboxes.html) | Environment isolation — deck reference | Agile data context |
| [Fowler — unit tests](https://martinfowler.com/bliki/UnitTest.html) | L3 automation | App-centric |
| [Fowler — TDD](https://martinfowler.com/bliki/TestDrivenDevelopment.html) | One path to L3 | Not mandatory |
| [DORA / Accelerate — test automation](https://dora.dev/) | Correlates with performance | Not sandbox-specific |
| Workspace | [Deployment v2](deployment-and-release.md) · [DORA note](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) | |

---

## Repo examples (index)

| Topic | Path |
|---|---|
| Bare-metal preflight harness | [bare-metal-dev-sandbox/](../../../devops/bare-metal-dev-sandbox/README.md) |
| Cross-DC network verification | [cross-dc-network-test/](../../../devops/ocp/examples/networking/cross-dc-network-test/README.md) |
| GitOps CI validation | [framework/pipelines/](../../../devops/argo/examples/framework/pipelines/) |
| GitOps labs | [argo/labs/](../../../devops/argo/labs/README.md) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
