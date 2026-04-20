---
review:
  status: unreviewed
---

# When the Repository Becomes the Resume

> **Audience:** Anyone using AI assistants with a persistent workspace, codebase, or document collection — where the AI reads the artifacts and forms a working model of who you are.
> **Purpose:** Documents how an AI assistant consistently misidentified the workspace owner as an "infrastructure engineer" across multiple sessions, despite explicit corrections. Names the mechanism (corpus-to-identity conflation), traces the two compounding sources, and identifies the structural fix.

---

## What Happened

Across several sessions, the AI consistently framed the workspace owner as an infrastructure or platform engineer: writing README scope statements, suggesting content framing, and making organizational recommendations all through that lens.

The owner is a full-stack software engineer, systems engineer, and scientist working across multiple domains. They corrected this framing once during a session ("there will be more here eventually"), and then again more directly ("why do you keep thinking I'm an infrastructure engineer??").

The AI's response: it recognized the error immediately, traced the causes, and fixed the meta-document. But the fact that it took two explicit corrections — and that the pattern persisted across sessions — makes this worth naming.

---

## The Two Compounding Sources

### Source 1: The meta-document set the frame

The first lines of `.cursorrules` — the document loaded at the start of every session — read:

> *"This workspace contains practical DevOps examples, configurations, and troubleshooting guides for enterprise Kubernetes and OpenShift environments."*

That sentence is accurate as a description of the technical reference content. But as an opener for the workspace's primary orientation document, it anchors every session to a single domain. The AI reads this first, forms a working model of "this is an infrastructure workspace," and that frame colors everything that follows — even when contradicting signals appear later.

### Source 2: The dominant technical corpus reinforced it

The `devops/` directory contains 20+ OpenShift troubleshooting guides, 13 Ansible playbooks, ArgoCD GitOps patterns, RHACM multi-cluster configurations, and Vault integrations. When the AI scans the repository, this content is the largest single technical signal.

What gets missed: the owner's actual breadth. The essays span AI-assisted development, learning theory, organizational culture, and Zen practice. The philosophy track has nothing to do with Kubernetes. The stated purpose of the workspace is "public-facing repository for all things generated with AI" — explicitly wide audience, explicitly multiple domains.

But the essay track doesn't produce the same strength of categorical signal that six product directories of infrastructure tooling does. Infrastructure content is dense, repetitive-pattern, and categorically strong. Essays are genre-ambiguous and domain-light.

---

## The Mechanism: Corpus-to-Identity Conflation

The core mistake: **treating what someone has produced as who they are**.

A repository is a snapshot of work that has been committed so far — not a complete portrait of the person who built it. What's visible is a function of:

- What work has had time to accumulate
- Which projects were mature enough to document
- Which domain's tooling generates dense, categorically-obvious artifacts

The AI inherited the frame from the meta-document, found the dominant technical content consistent with that frame, and concluded with confidence. The conclusion was accurate about the *current content* and wrong about the *person*.

This is subtly different from the other failure modes in this collection:

| Failure mode | Mechanism | This case |
|---|---|---|
| [Meta-document drift](meta-document-drift.md) | Document becomes stale over time | The document was accurate — it was the *inference* that was wrong |
| [Anchoring bias](debugging-ai-judgment.md) | AI locks onto early framing | ✓ Shares this — `.cursorrules` opener anchors every session |
| [Stale context](stale-context-in-long-sessions.md) | AI ignores updates made by other sessions | ✓ Shares this across sessions — correction didn't persist |
| **Corpus-to-identity conflation** | AI treats artifact collection as personal identity | This case — new mechanism |

---

## Why Explicit Correction Didn't Stick

Corrections made inside a session don't persist to the next one. The meta-document is re-read at every session start, re-anchoring the frame. A correction that never made it into the document had no recovery path — each new session started from the same wrong premise.

This is the structural reason the pattern repeated. It wasn't the AI ignoring the correction; it was the correction existing only in ephemeral session context while the anchoring framing lived in persistent files.

---

## The Fix

**Two parts:**

**1. Identity-first meta-documents, not content-first:**

The `.cursorrules` opener was rewritten to describe the *person and their intent* before describing the content:

> *"Public workspace of a full-stack software engineer, systems engineer, and scientist working across multiple domains... Do not infer the person's identity or primary domain from the dominant technical content."*

The explicit anti-inference instruction is not elegant, but it is necessary. Without it, the content inventory that follows will anchor the model regardless of the opener's framing.

**2. Treat dominant content as sample bias, not ground truth:**

When a corpus has a strong technical skew, that skew reflects what was built first — not the owner's ceiling or primary identity. The appropriate reading: "this domain has the most material so far" rather than "this domain defines this person."

---

## The Broader Pattern

Any persistent AI workspace develops a dominant content profile over time. The content that accumulates first, most densely, or in the most categorically-obvious form will anchor the AI's model of who the workspace belongs to.

This creates a latent bias that:
- Persists across sessions (because it lives in persistent files)
- Compounds over time (more infrastructure content = stronger infrastructure signal)
- Resists correction (session-level corrections don't survive session boundaries)
- Affects framing, recommendations, and tone — not just explicit identity statements

**The fix generalizes:** meta-documents should describe the person's *intent and breadth* explicitly, not just the current contents. "The technical content currently reflects X — that's what has accumulated so far, not a ceiling on scope" is the pattern.

This is especially relevant for AI workspaces that are expected to grow into new domains — which is most of them.

---

## Connection to Related Case Studies

| Case Study | Relationship |
|---|---|
| [When the Meta-Document Tries to Be the Catalog](meta-document-drift.md) | Meta-documents shape AI behavior across sessions — same mechanism for persistence |
| [Debugging Your AI Assistant's Judgment](debugging-ai-judgment.md) | Anchoring on early framing; zero-base evaluation as the structural fix |
| [The Frictionless Entity](frictionless-entity.md) | AI agreeing with whatever frame is presented — including an incorrectly narrow one |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
