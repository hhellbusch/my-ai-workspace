# lid-pi-extension — Design Brief

> Written: 2026-05-03 | SHA: f0df97c

## Intent

Bring LID's linked-intent discipline to pi sessions as a first-class extension —
auto-injected, depth-on-demand — without requiring Claude Code plugins.

The core value of LID is not the tooling; it's the habit of writing intent before
writing changes. The extension makes that habit cheap to maintain across sessions,
tools, and project types — including non-code workspaces where the standard
HLD → LLD → EARS → Tests → Code arrow doesn't map cleanly.

## Design decisions

**Standalone repo** — not bundled with zanshin-pi-extension. They address different
layers: Zanshin is session discipline (how to work with AI); LID is project/change
discipline (what to build). Loading both achieves integration. Neither depends on
the other.

**Non-code adaptation** — the LID arrow is scaled to change size:
- **Touch** (1–2 files, obvious): intent in the commit message
- **Change** (3–5 files, or any new command/skill/rule): Intent Note before executing
- **Restructure** (5+ files, new directories, architecture): full arrow:
  Intent → Design Note → Acceptance Criteria → Change

EARS syntax and `@spec` annotations are code-specific. This extension uses plain
acceptance criteria language. Semantic IDs are optional — useful for structural
changes, noise for small ones.

**L0 + depth-on-demand** — mirrors the zanshin pattern. The extension injects a
compact L0 block into the system prompt (`before_agent_start`). The full workflow
lives in `kit/LID-WORKFLOW.md` at an absolute path on disk. The agent reads it
when planning a change, not on every turn.

**No enforcement** — like LID itself, this extension makes costs visible and stops
for review; it does not block. The agent warns on bypasses; the user decides.

## Acceptance criteria

- `pi install git:https://github.com/hhellbusch/lid-pi-extension.git` works
- After install, every pi session receives the L0 block in the system prompt
- The L0 block correctly points to `kit/LID-WORKFLOW.md` at its installed path
- Agent reads `LID-WORKFLOW.md` when planning a 3+ file change without being asked
- Works alongside zanshin-pi-extension (both load, no conflict)
- Works in code projects and in non-code workspaces (like Field Notes)

## Repo structure

```
lid-pi-extension/
├── package.json
├── README.md
├── LICENSE
├── extensions/
│   └── lid-l0.ts          # before_agent_start hook
└── kit/
    ├── LID-WORKFLOW.md     # Full non-code workflow
    └── templates/
        ├── INTENT.md       # Intent Note template
        ├── DESIGN-NOTE.md  # Design Note template
        └── ACCEPTANCE.md   # Acceptance criteria template
```

## Cross-tool loading architecture

Decided: extensions load differently per tool, using each tool's native mechanism.
The discipline is identical; only the delivery path differs.

| Tool | Mechanism | Kit depth |
|---|---|---|
| Pi | `pi install` → `before_agent_start` hook | Absolute path from installed extension |
| Cursor | `.cursor/rules/lid.mdc` (alwaysApply) | Relative path to submodule/directory |
| Claude Code | `CLAUDE.md` section + on-demand read table | Relative path to submodule/directory |

For Cursor and Claude Code, the extension ships as a **git submodule** in the
workspace — that's the install mechanism. Pi ignores the submodule and uses
its own installed copy. Both coexist without conflict.

While the extension is being developed inside this workspace (`submodules/lid-pi-extension/`
directory), Cursor and Claude Code reference it by directory path. Once extracted
to its own repo, the directory becomes a submodule — paths stay the same.

**Why not drop the zanshin submodule?** The submodule is what gives Cursor and
Claude Code access to the kit files. Pi doesn't need it (uses the installed
extension), but removing it would break the Cursor rule and CLAUDE.md references.
Two delivery mechanisms for two tool contexts — correct separation.

## Paude workspace architecture (related decision)

Code projects should NOT be git submodules of this workspace. Each project gets
its own paude workspace (its own `/pvc/` volume). The extensions (zanshin, lid)
are installed per-workspace — they're the portability layer, not the git history.

This workspace is the knowledge/practice workspace. Code project workspaces are
separate. The `git-projects` folder pattern on local FS was right; the
formalization is per-project paude workspaces, not submodules.

Tool extensions (zanshin-pi-extension, lid-pi-extension) remain submodules of
this workspace because they ARE dependencies this workspace consumes.

## Relationship to LID upstream

This extension adapts LID's discipline for pi and non-code contexts. It does not
replace the upstream Claude Code plugins for code projects — those remain the
richest integration for software development. Projects that use both pi and Claude
Code can install this extension for pi sessions and the upstream plugins for
Claude Code sessions.

The non-code workflow defined here is a contribution back to the LID methodology
— worth opening a discussion with the LID repo once it's stable.
