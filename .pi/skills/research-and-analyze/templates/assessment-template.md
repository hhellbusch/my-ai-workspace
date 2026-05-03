# Verification Assessment: {{Article Title}}

**Source:** {{article URL}}
**Assessment date:** {{date}}
**Sources checked:** {{N}} of {{total}} cited references
**Sources unreachable:** {{N}}

---

## Summary

{{3-5 sentence overview of what the analysis found. Is the article generally trustworthy? Where does it fall short? What should readers know?}}

---

## Confidence by Topic Area

| Topic area | Confidence | Basis |
| --- | --- | --- |
| {{area}} | **High** / **Medium-High** / **Medium** / **Medium-Low** / **Low** / **Unverifiable** | {{1-line explanation}} |

---

## Key Findings

**1. {{Finding title}}**
{{Evidence and explanation. Reference specific batch findings.}}

**2. {{Finding title}}**
{{Evidence and explanation.}}

**3. {{Finding title}}**
{{Evidence and explanation.}}

---

## What to Trust

{{List of topic areas / claims that are well-supported and can be cited confidently}}

## What to Verify Independently

{{Claims that are directionally correct but need additional context or caveats}}

## What to Discard or Caveat Heavily

{{Claims that are misleading, unsupported, or stripped of essential context}}

---

## Methodology

- **Tool:** research-and-analyze skill (fetch → analyze → synthesize pipeline)
- **Fetcher:** `fetch-sources.py` with `requests` + `beautifulsoup4` + `markdownify`
- **Analysis approach:** Batch comparison of article claims against source content
- **Sources checked:** {{N}} of {{total}} ({{percentage}}%)
- **Unreachable sources:** {{list with reasons}}
- **Limitations:** {{e.g., PDFs not parsed, paywalled content, non-English sources}}
