# Structured Edit Discipline

> **Canonical (portable anchor rule):** `submodules/zanshin-pi-extension/kit/kihon/structured-edit.md`  
> Invoked: `/kihon edit`

## Field Notes — Python safety net

After any Write or StrReplace on a `.py` file, the PostToolUse hook at `.claude/hooks/py-edit-check.sh` runs automatically and injects two signals into context:

1. **AST parse result** — catches syntax breakage immediately
2. **Top-level function inventory** — `grep -n "^def "` output so a dropped function is visible in the next turn, not at commit time

The hook output is the detection layer. The kit anchor rule is what prevents the failure in the first place.
