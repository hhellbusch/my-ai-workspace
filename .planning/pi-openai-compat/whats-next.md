# pi-openai-compat — session handoff

## What was done

Debugging and fixing quota tracking in the pi-openai-compat extension.

**Root cause findings:**
- LiteLLM MaaS does NOT send `X-Ratelimit-*` headers on streaming responses
- `/user/info` quota is nested under `user_info` (not top-level)
- Dollar spend tracks monthly budget, NOT the per-minute TPM/RPM limits that cause actual 429s

**What's now working:**
- Dollar spend display in status bar: `$157/$10K 2%` (polled from `/user/info`)
- Sliding-window RPM/TPM tracking built locally from Pi usage events
- 429 detection and rate-limit error display in status bar

**What still needs validation:**
- The RPM/TPM sliding window tracking was added this session but not tested (hit 429 before it could be verified)
- After `/reload`, send a message and check if the status bar shows `rps:N/5000  NNK/5M tpm` in the quota slot
- If still showing dollar spend only, check that `quota.rpmLimit` and `quota.tokenLimit` are being populated from `/user/info`

## The actual rate limit issue

TPM limit: 5,000,000/minute — but with 120K context per turn, each request costs ~120K+ tokens. Under active debugging that burns through fast. Compacting context is the right move.

**Feedback to consider giving LiteMaaS admin:**
- The 429 error body contains the reset time but it arrives in the error stream, not as a header — hard to catch cleanly
- Adding standard `Retry-After` header on 429 streaming responses would help clients back off gracefully

## Extension state
- Repo: `submodules/pi-openai-compat/`
- Cache: `~/.pi/agent/git/github.com/hhellbusch/pi-openai-compat/`
- Latest commit: `4f1d949`
