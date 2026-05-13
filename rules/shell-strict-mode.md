# Shell Strict Mode

All shell scripts (`*.sh`, `*.bash`) must start with strict mode enabled.
Inline shell blocks in CI configs (GitHub Actions, GitLab CI, Tekton, etc.) and Makefiles must also use strict mode.

## Required header

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- `set -e` — exit immediately on error
- `set -u` — treat unset variables as errors
- `set -o pipefail` — propagate errors through pipes (e.g. `false | true` fails)

## CI inline scripts

Every `run:` / `script:` block that contains more than a single command must start with `set -euo pipefail`.

For single-command `run:` blocks, strict mode is optional but encouraged.

## Makefiles

Recipe lines that invoke bash directly should pass the flags via the shell invocation:

```makefile
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
```

## Exceptions

If a script intentionally needs to survive errors (e.g. a cleanup/trap handler), note the reason in a comment at the top.
