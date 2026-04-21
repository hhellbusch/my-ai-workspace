# Intervention Log

Append-only. New entries go at the top. One entry per notable framework intervention.

**What counts as notable:** The intervention produced an output or caught something that a plain unstructured interaction would likely have missed. Don't log null events or routine firing.

**Format:** See first entry for template.

**Updated via:** `/whats-next` Step 1.6, `/checkpoint` Step 1.5, or manually mid-session.

---

## Entry format

```
### [YYYY-MM-DD] — [Intervention] — [One-line description]

**Intervention:** [spar / shoshin / SHA-check / compaction-caught / thread-recovered / handoff-recovery / other]
**Session context:** [One sentence: what were you working on?]
**What it caught:** [Specific finding — not just "found weaknesses" but what kind and why non-obvious]
**Counterfactual:** [What would likely have happened without the intervention?]
**Severity:** [High — wrong output / Medium — rework / Low — friction]
**Baseline comparison:** [Yes — see counterfactual-protocol.md entry [date] / No]
**Evidence:** [Commit SHA, file path, or case study link if applicable]
```

---

## Log

### 2026-04-20 — spar — IPv8 draft structural review

**Intervention:** spar  
**Session context:** Reviewed IETF draft-thain-ipv8-00 (IPv8 proposal), produced TL;DR, then ran `/spar` for adversarial review.  
**What it caught:**
- **Internal contradiction (R7 vs. NIC firmware mandate):** The draft simultaneously claims "implementable as a software update without hardware replacement" (Req R7) and mandates NIC-firmware-enforced rate limits and hardware VLAN enforcement. This contradiction is non-obvious because the claims appear in different sections (§2.4 vs. §17). The spar found it; a plain "what are the weaknesses" prompt would likely have surfaced general concerns about adoption but not this specific self-contradiction.
- **WHOIS8/RPKI adoption gap:** The draft presents BGP route validation as an architectural guarantee. The spar named the prior art (RPKI, ~50% adoption after 15 years) and the adoption problem it implies. This requires domain knowledge about the RPKI deployment history that is not in the draft itself.
- **Backward-compatibility as fiction:** The spar identified that "IPv4 is a proper subset" is a mathematical address-space claim, not an operational wire-compatibility claim. The real mechanism (XLATE8) is hand-waved in one sentence. This is structurally the most important finding because backward compatibility is the load-bearing claim of the entire proposal.

**Counterfactual:** A plain "what are the weaknesses of this draft?" prompt would likely have produced general concerns (transition complexity, adoption, RFC-only constraints). The specific internal contradiction (R7 vs. §17.5) and the RPKI precedent comparison required the methodology's explicit instruction to "attack the strongest claims, not the weakest" and to "check for the thesis being violated by the document itself."  
**Severity:** Medium — no wrong output produced; the value was in the quality of adversarial arguments generated.  
**Baseline comparison:** No — naive pass not run for this session. A retroactive comparison is possible: run "what are the weaknesses of IPv8 draft-thain-ipv8-00?" against the same document and compare against the structured output above.  
**Evidence:** Conversation session 2026-04-20 (no commit — research conversation only)
