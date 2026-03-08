# AGENTS.md

## Constitution Generation

This project uses a multi-agent constitution generation framework.

**When asked to generate, analyse, or update the codebase constitution:**
→ Read and follow `.cursor/skills/constitution/SKILL.md` exactly.
→ Do NOT improvise or write a constitution directly. The skill defines a
  Prepare → Scan → Audit → Aggregate → Curate pipeline with parallel subagents.
→ Parallel mode requires Cursor 2.4+. Sequential fallback runs automatically on older versions.
→ Monorepo/workspace projects are auto-detected (pnpm, npm, nx, turbo, lerna).
→ Pipeline progress is tracked via `_status-*.json` files in `.cursor/constitution-tmp/`.
→ Re-runs produce a changelog at `docs/ai/constitution-changelog.md`.

**When working on source code:**
→ Check `docs/ai/constitution-cheatsheet.md` for project conventions and rules.
→ For full detail, reference `docs/ai/constitution.md`.
