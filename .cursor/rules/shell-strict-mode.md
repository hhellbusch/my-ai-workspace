---
description: Enforce strict mode in shell/bash scripts with set -euo pipefail
globs: **/*.sh,**/*.bash
alwaysApply: false
---

# Shell strict mode

All shell scripts (`*.sh`, `*.bash`) must start with strict mode enabled.

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

## Inline scripts

For short inline scripts in CI or Makefiles, add the flags to the shebang line or
as the first command:

```yaml
# GitHub Actions / GitLab CI
run: |
  set -euo pipefail
  ./deploy.sh
```

## Exceptions

If a script intentionally needs to survive errors (e.g. a cleanup/trap handler),
note the reason in a comment at the top:

```bash
#!/usr/bin/env bash
# strict mode intentionally omitted: cleanup must run even on partial failure
```
