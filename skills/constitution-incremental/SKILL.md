---
name: constitution-incremental
description: >
  Incrementally update the constitution by re-running only the agents affected by
  recent code changes. Requires a previous full scan. Uses git diff to determine
  which files changed and maps them to the relevant agents. Invoke with
  /constitution-incremental or "incremental constitution update".
version: 1.0.0
---

# Constitution Incremental Update

## Purpose

Update `docs/ai/constitution.md` efficiently by re-running only the agents whose
input files have changed since the last scan. Reuses cached reports for unchanged
areas, then re-aggregates and re-curates.

## Step 1: Check prerequisites

Read `.cursor/constitution-tmp/_scan-metadata.json`.

If the file does not exist:
- Tell the user: "No previous scan found. Running a full scan instead."
- Invoke the `constitution` skill (full pipeline) and abort this incremental flow.

If the file exists, extract `last_scan_commit` and `last_scan_timestamp`.

Verify the commit still exists:
```bash
git cat-file -t <last_scan_commit>
```

If the commit doesn't exist (e.g., after a force push or rebase):
- Tell the user: "Previous scan commit no longer exists in git history. Running full scan."
- Invoke the `constitution` skill and abort this incremental flow.

## Step 2: Determine changed files

```bash
git diff --name-only <last_scan_commit> HEAD
```

If no files changed: report "No changes since last scan at <timestamp>. Constitution is up to date." and exit.

## Step 3: Map changed files to agents

Use the pattern table below to determine which agents need to re-run:

| File Pattern | Primary Agent(s) | Secondary Agent(s) |
|-------------|-------------------|---------------------|
| `schema.prisma`, `migrations/*`, `**/entity*`, `**/model*` | `data-model-analyst` | — |
| `package.json`, `*lock*`, `requirements.txt`, `pyproject.toml`, `Cargo.toml` | `dependency-analyst` | `pattern-analyst` |
| `routes/*`, `controllers/*`, `openapi.*`, `swagger.*` | `api-contract-analyst`, `runtime-flow-analyst` | `data-model-analyst` (if endpoint touches models) |
| `middleware/*`, `interceptor*`, `guard*`, `filter*` | `runtime-flow-analyst` | — |
| `Dockerfile*`, `.github/workflows/*`, `.gitlab-ci.yml`, `Jenkinsfile`, `*.tf`, `serverless.yml`, `fly.toml`, `vercel.json`, `netlify.toml` | `infra-analyst` | — |
| `**/test*`, `**/__tests__/*`, `**/*.spec.*`, `**/*.test.*` | `pattern-analyst` | — |
| Files within a domain directory (matched against `agent_file_coverage` from previous scan) | `domain-scanner:<label>` for that domain | — |

**Secondary agents** are triggered as cascade effects — they are added to the re-run
list because their analysis depends on the primary agent's domain.

**Domain mapping:** For files not matching any specialist pattern, check
`_scan-metadata.json` → `agent_file_coverage` to determine which domain-scanner
originally covered that file's directory. If the file is in a new directory not
covered by any previous scanner, flag it as a new domain requiring a domain-scanner.

## Step 4: Report plan to user

Present the plan before executing:

```
Incremental update plan:
  Changed files: <count> files since <last_scan_timestamp>
  Agents to re-run: <list of agent names>
  Agents reusing cache: <list of agent names>
  Estimated scope: <percentage of full scan>

Proceed? (yes/no)
```

Wait for user confirmation. If denied, exit without changes.

## Step 5: Write incremental scope hint

Write `.cursor/constitution-tmp/_incremental-scope.json`:

```json
{
  "scan_type": "incremental",
  "base_commit": "<last_scan_commit>",
  "head_commit": "<current HEAD SHA>",
  "changed_files": ["<list>"],
  "agents_to_rerun": ["<list>"],
  "agents_cached": ["<list>"],
  "cascade_triggers": [
    { "primary": "<agent>", "secondary": "<agent>", "reason": "<why>" }
  ]
}
```

This file is read by the auditor to scope its verification work.

## Step 6: Spawn only affected agents

For each agent in `agents_to_rerun`:
- Spawn it with the same instructions as a full scan
- The agent writes fresh output files (overwriting cached versions)

For domain scanners: only spawn scanners for affected domains, not all domains.

Wait for all spawned agents to complete (check `_status-*.json` files).

## Step 7: Scoped audit

Spawn `constitution-auditor`. It will read `_incremental-scope.json` and:
- Focus verification on re-run agents' reports
- Note cached reports in its output (accepted from previous scan)
- Still check for cross-report contradictions between fresh and cached reports

## Step 8: Re-aggregate and re-curate

Invoke `constitution-aggregator` — it reads ALL report files (fresh + cached),
merges them, and applies any corrections from `_corrections.json`.

Invoke `constitution-curator` — it writes the updated constitution, cheatsheet,
viewer, and changelog. The changelog should note this was an incremental update.

## Step 9: Update scan metadata

Write `.cursor/constitution-tmp/_scan-metadata.json`:

```json
{
  "last_scan_commit": "<current HEAD SHA>",
  "last_scan_timestamp": "<ISO 8601>",
  "scan_type": "incremental",
  "agents_run": ["<list of agents that ran in this update>"],
  "agent_file_coverage": {
    "<agent-name>": ["<files that agent read>"]
  }
}
```

**Important:** Merge `agent_file_coverage` — for agents that re-ran, use their
fresh `files_read_list`. For cached agents, preserve the previous coverage mapping.

## Step 10: Report

Tell the user:
- How many agents re-ran vs. were cached
- Constitution updated at `docs/ai/constitution.md`
- Changelog updated with incremental changes
- "Run `/constitution` for a full re-scan if needed."

## Error handling

- Git not available: abort with error, suggest full scan
- Scan metadata corrupt: fall back to full scan
- Agent fails during incremental run: offer to retry that agent or fall back to full scan
- All files changed: warn that this is effectively a full scan and suggest using `/constitution` instead
