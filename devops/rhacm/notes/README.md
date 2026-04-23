# RHACM Notes

Informal RHACM quick references and working notes. These are operational references — configurations, port requirements, patterns used regularly — not structured troubleshooting guides (those live in `rhacm/troubleshooting/`).

## Contents

- **[networking-requirements-2.16.md](networking-requirements-2.16.md)** — Required network connectivity between the ACM hub cluster and managed clusters (ports, directions, situational requirements) based on ACM 2.16 docs
- **[search-setup.md](search-setup.md)** — First-time setup for RHACM Search: enabling the hub service, deploying the per-cluster collector addon, and verifying results

## Adding New Notes

When adding a new note:
1. Use a descriptive filename with kebab-case
2. Link it from this README
3. If it grows into a full troubleshooting guide, move it to `rhacm/troubleshooting/` with the standard symptom → cause → fix structure

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for review status details.*
