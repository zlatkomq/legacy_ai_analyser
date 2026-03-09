# Cursor Constitution Generator

A Cursor plugin that analyses a brownfield codebase and produces
`docs/ai/constitution.md` — a current-system truth layer for downstream AI workflows.

The constitution grounds later stages:
- spec creation (`what` should change)
- design (`how` the change fits the current system)
- task composition
- development
- QA

It does not replace spec or design. It gives those stages a brownfield baseline
derived from the existing codebase.

---

## Installation

### Option A — Cursor Marketplace (recommended)

1. Open the Marketplace panel in Cursor
2. Search **constitution-generator**
3. Install (project-scoped or user-level)
4. Run the project setup step below

### Option B — Manual (non-plugin)

Use the `non-plugin` branch and `install.sh`:

```bash
git clone https://github.com/zlatkomq/legacy_ai_analyser.git
cd legacy_ai_analyser
git checkout non-plugin
cd /path/to/your/project
bash /path/to/legacy_ai_analyser/install.sh
```

---

## Project setup (both options)

After installing the plugin, run this one-time setup in your target project:

```bash
# Copy baseline .cursorignore (if you don't have one already)
cp /path/to/plugin/.cursorignore .cursorignore

# Optional: add git hook for drift detection
cp /path/to/plugin/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Then open the project in Cursor and type in agent chat:

```
Generate a constitution for this codebase
```

---

## What's in the plugin

```
constitution-generator/
├── .cursor-plugin/
│   └── plugin.json                         ← Plugin manifest
├── agents/
│   ├── domain-scanner.md                   ← One instance per directory
│   ├── api-contract-analyst.md             ← Maps all API surfaces
│   ├── data-model-analyst.md               ← Schemas, entities, data flow
│   ├── dependency-analyst.md               ← Tech stack and package health
│   ├── pattern-analyst.md                  ← Architecture and coding patterns
│   ├── runtime-flow-analyst.md             ← Actual request/event call chains
│   ├── infra-analyst.md                    ← Infrastructure, CI/CD, deployment
│   └── constitution-auditor.md             ← Cross-validates all other agents
├── skills/
│   ├── constitution/SKILL.md               ← Master orchestrator (/constitution)
│   ├── constitution-aggregator/SKILL.md    ← Merges verified reports
│   ├── constitution-curator/SKILL.md       ← Writes final constitution.md
│   ├── constitution-patch/SKILL.md         ← Manual corrections (/constitution-patch)
│   └── constitution-incremental/SKILL.md  ← Incremental updates (/constitution-incremental)
├── rules/
│   ├── constitution-mode.mdc               ← Pipeline discipline rules
│   └── constitution-reference.mdc          ← Auto-checks constitution on code edits
├── hooks/
│   ├── constitution-drift.json             ← Drift detection hook
│   └── constitution-drift-check.sh         ← Drift detection script
├── .cursorignore                           ← Baseline exclusions template (copy to your project)
└── pre-commit-hook.sh                      ← Git hook template (copy to your project)
```

---

## Requirements

- **Cursor 2.4+** recommended (parallel subagent support)
- **Cursor < 2.4** supported via sequential fallback mode (slower but functional)
- An existing codebase to analyse
- Monorepo/workspace projects supported (pnpm, npm, nx, turbo, lerna)

---

## What it produces (in your project)

- `docs/ai/constitution.md` — full 13-section constitution with section-level confidence,
  evidence sources, and downstream-use guidance
- `docs/ai/constitution-cheatsheet.md` — condensed ~500-800 word version for agent context injection
- `docs/ai/constitution-viewer.html` — self-contained interactive browser UI
- `docs/ai/constitution-changelog.md` — section-by-section diff on re-runs

---

## Pipeline

```
Pre-flight → Parallel Scan (up to 14 agents) → Audit → Aggregate → Curate
```

- Incremental mode: `/constitution-incremental` — re-runs only agents affected by recent changes
- Manual corrections: `/constitution-patch` — corrections persist across re-runs
- Monorepo scaling: wave execution for large workspaces
- Sequential fallback: automatic for older Cursor versions

Estimated time: 10–25 min (parallel) or 30–60 min (sequential) depending on codebase size.

---

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Cursor plugin format — install via Cursor Marketplace |
| `non-plugin` | Legacy `install.sh` format — copy files directly into your project |
