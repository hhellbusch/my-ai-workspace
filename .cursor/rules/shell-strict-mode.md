---
description: Enforce strict mode in shell/bash scripts and CI inline scripts with set -euo pipefail
globs: **/*.sh,**/*.bash,**/*.yml,**/*.yaml,**/Makefile
alwaysApply: false
---

# Shell strict mode

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

## Examples

```bash
# ❌ BAD — silent failures, undefined variable silently expands to empty
#!/bin/bash
files=$(ls $DIR)
echo $files | grep foo

# ✅ GOOD — errors are loud and caught early
#!/usr/bin/env bash
set -euo pipefail
files=$(ls "$DIR")
echo "$files" | grep foo
```

## CI inline scripts (GitHub Actions, GitLab CI, Tekton, etc.)

Every `run:` / `script:` block that contains more than a single command must start
with `set -euo pipefail`:

```yaml
# ❌ BAD — a failed step is silently swallowed by the pipe
- name: Build
  run: |
    make build
    echo $OUTPUT | tee result.txt

# ✅ GOOD
- name: Build
  run: |
    set -euo pipefail
    make build
    echo "$OUTPUT" | tee result.txt
```

For single-command `run:` blocks, strict mode is optional but encouraged.

## Makefiles

Recipe lines that invoke bash directly should pass the flags via the shell invocation:

```makefile
# ❌ BAD
deploy:
	./scripts/deploy.sh && echo done

# ✅ GOOD — set SHELL and .SHELLFLAGS at the top of the Makefile
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

deploy:
	./scripts/deploy.sh
	echo "done"
```

## Exceptions

If a script intentionally needs to survive errors (e.g. a cleanup/trap handler),
note the reason in a comment at the top:

```bash
#!/usr/bin/env bash
# strict mode intentionally omitted: cleanup must run even on partial failure
```
