# AGENTS.md

## Constitution Generation

This project uses a multi-agent constitution generation framework.
The resulting constitution is the current-system truth layer for downstream AI work:
spec, design, task composition, development, and QA.

**When asked to generate, analyse, or update the codebase constitution:**
→ Use the `/constitution` skill (or read and follow `skills/constitution/SKILL.md`).
→ Do NOT improvise or write a constitution directly. The skill defines a
  Prepare → Scan → Audit → Aggregate → Curate pipeline with parallel subagents.
→ Requires Cursor 2.4+ (parallel subagents).
→ Monorepo/workspace projects are auto-detected (pnpm, npm, nx, turbo, lerna).
→ Pipeline progress is tracked via `_status-*.json` files in `.cursor/constitution-tmp/`.
→ Use `/constitution-patch` to correct errors — corrections survive re-runs.
→ Monorepo scaling with wave execution is automatic for large workspaces.
→ Treat the constitution as current-state truth and constraints, not as a feature spec.
→ Low-confidence or `[NEEDS REVIEW]` sections must not be treated as authoritative
  without human validation.

**When working on source code or downstream artifacts (spec/design/tasks/QA):**
→ Use `docs/ai/CONSTITUTION.md` as **preamble / guardrails** in the prompt — paste it
  (or the relevant part) so the AI respects project conventions, constraints, and
  DO/DO NOT rules.
→ Let the spec define `what`; let the design define `how`.
→ For full detail, reference `docs/ai/full-analysis-*.md` when needed.
