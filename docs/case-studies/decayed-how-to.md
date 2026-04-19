# When How-To Instructions Outlive the Interface

> **Audience:** Anyone using AI to produce tutorials, walkthroughs, or step-by-step instructions referencing software interfaces.
> **Label:** `failure` — AI described interface steps from training data; the steps didn't match the current interface.

---

## The Setup

A document was being written to explain YouTube transcript workflows for a non-technical audience. One section described how to get a transcript from YouTube without any tools: click the `...` menu below the video, select "Show transcript," copy the text.

The instructions were specific, confident, and written as if verified. They were not verified. They came from training data.

---

## What Happened

The author tried to follow the instructions and couldn't find the button. Not in the location described. Possibly not present at all in their interface.

When challenged, the AI acknowledged it had described the YouTube UI from training data and couldn't verify whether those steps reflected the current interface. The feature may exist — YouTube has offered transcripts for years — but the exact path described didn't match what the author was seeing.

The instructions were removed. The section was rewritten around the `youtube-transcript-api` Python library (which calls YouTube's transcript API directly) and `youtubetranscript.com` (a web tool that does the same thing without setup). Both approaches bypass the UI entirely and are stable across interface changes.

---

## Why This Matters

This failure mode is distinct from [fabricated references](fabricated-references.md), though the root cause is the same:

| | Fabricated reference | Decayed how-to |
|---|---|---|
| **What happened** | AI invented a URL that never existed | AI described steps that may have existed but no longer matched |
| **How it looks** | Plausible URL, returns 404 | Confident instructions, feature not found |
| **Detection** | Click the link | Try to follow the steps |
| **Root cause** | AI generates plausible outputs without checking existence | AI describes interfaces from training data without checking currency |

Both carry identical confidence in the prose. Neither signals "this might be wrong."

Software interfaces are particularly vulnerable to this failure mode because:

1. **They change frequently.** YouTube, Google, Microsoft, and other large platforms redesign navigation, rename menu items, move features, and A/B test interfaces continuously. Training data captures one moment.

2. **The instructions look current.** Step-by-step UI instructions don't have a visible timestamp. A reader has no signal that the steps were accurate eighteen months ago but may not be now.

3. **The failure only appears at execution time.** A fabricated URL fails immediately when clicked. Decayed UI instructions fail when the reader tries to follow them — which may be days or weeks after the document was published.

4. **The AI has no way to verify.** Unlike external URLs (which can be fetched), UI steps cannot be checked without running a browser session against the live interface. The AI can only report what the interface looked like during training.

This is a specific instance of a broader pattern — AI asserting time-sensitive information confidently without flagging that it cannot verify currency. The same mechanism produces incorrect "current version" claims, wrong year references, and stale "as of [date]" assertions. The information was once accurate. The model doesn't know it has expired.

---

## The Fix

**Immediate:** Remove the UI instructions. Replace with approaches that don't depend on interface state:
- API-based transcript fetching (`youtube-transcript-api`) — stable across UI changes
- Web tools like `youtubetranscript.com` — consistent interface, purpose-built for transcript extraction

**Systemic:** Add a rule: AI-generated step-by-step instructions that reference a specific software interface require verification before publishing. This is analogous to the external URL verification rule added after the fabricated references incident — you cannot trust that the steps are current without checking them in the live interface.

For how-to content specifically: prefer approaches that are interface-independent where possible. API calls, command-line tools, and purpose-built web tools change less frequently than navigation menus in large consumer products.

---

## What This Connects To

The [fabricated references](fabricated-references.md) case study documents AI inventing a URL that never existed. This case documents a different but related failure: AI accurately describing something that existed but can no longer be found. Both are instances of the same root — AI generates confident, plausible-looking content without tracking whether it is currently true.

A related pattern is in the Ideas backlog: "the frozen clock — LLM defaults to stale current-year." That failure (AI defaulting to its training cutoff year) has the same root: time-sensitive assertions made without acknowledging that the model cannot verify the present. The decayed how-to is the interface-instruction version of the frozen clock.

The mitigation strategy is also the same: don't trust AI output about things that change — current versions, current dates, current interfaces. Either verify in the live environment or route around the dependency entirely (which is what the API-based fix did here).

---

## What the Human Brought

The author tried to follow the instructions. That's it — but it's the critical step. The AI presented the interface steps with the same confidence as everything else in the document. Nothing in the prose indicated they were less reliable than the surrounding content. The only way to catch decayed how-to instructions is to execute them, and the author did.

The follow-up question — "perhaps we could simply document the API instead?" — was also the author's, not the AI's. The AI admitted the problem; the human produced the better solution.

---

## Artifacts

| Artifact | What it is |
|---|---|
| [`docs/ai-engineering/youtube-video-analysis.md`](../ai-engineering/youtube-video-analysis.md) | The document where the UI instructions appeared and were corrected |
| [`docs/case-studies/fabricated-references.md`](fabricated-references.md) | Sibling case study — same root cause, different failure type |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
