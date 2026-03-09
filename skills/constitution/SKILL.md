---
name: constitution
description: >
  Orchestrate full codebase analysis to produce docs/ai/constitution.md.
  Handles pre-flight setup, parallel scanning, auditing, aggregation, and
  curation. Invoke with /constitution or "generate constitution" or
  "analyse codebase for AI constitution".
version: 2.1.0
---

# Codebase Constitution Generator

## Purpose

Produce `docs/ai/constitution.md` — a durable, audited AI-generation contract
for a brownfield project — by running a Prepare → Map → Audit → Reduce → Curate
pipeline using parallel Cursor subagents.

## Phase 0: Pre-flight (do this before spawning any subagent)

### 0a. Create directory structure
```bash
mkdir -p .cursor/constitution-tmp
mkdir -p docs/ai/constitution-fragments
```

### 0b. Generate .cursorignore
If `.cursorignore` does not exist, create it now using the baseline template from
section 5 of this architecture guide. If it exists, read it and confirm it covers:
- node_modules/, dist/, build/, coverage/
- *.lock, *.generated.*, *.min.js
- .env, *.pem, secrets/

If any of those are missing, add them before proceeding.

### 0b.5. Enforce ignore-aware discovery

From this point onward, treat `.cursorignore` as an active contract, not a suggestion:

- Prefer `Glob`, `Grep`, and `Read` style discovery tools because they respect ignore rules
- Do NOT use raw shell `find` / `grep` as the primary inventory mechanism for scan coverage
- If a shell command is unavoidable for a niche case, manually exclude ignored paths and
  record the limitation in `_pipeline.json` or the relevant agent output
- Tell every spawned scanner that coverage must be deterministic and path-stable on reruns

### 0c. Detect workspace structure

Before listing directories, check if this is a monorepo/workspace project:

1. Check for `pnpm-workspace.yaml` → read workspace glob patterns
2. Check for root `package.json` → read `"workspaces"` field
3. Check for `nx.json` → read project references
4. Check for `turbo.json` → read pipeline configuration
5. Check for `lerna.json` → read packages configuration

**If workspace configuration is found:**
- Use workspace package boundaries as domain directories instead of raw top-level dirs
- Record workspace type in `_pipeline.json` under `"workspace": { "type": "pnpm|npm|nx|turbo|lerna", "packages": [...] }`
- Tell each domain-scanner which workspace package it is scanning (see domain-scanner's "Workspace context" section)

**If no workspace configuration is found:** proceed with standard directory discovery.

### 0c.5. Read optional configuration

Check if `.cursor/constitution.config.json` exists. If it does, read it:

```json
{
  "concurrency_limit": 10,
  "max_files_per_scanner": 500,
  "grouping_strategy": "auto|scope|directory|size|none",
  "custom_groups": { "<label>": ["<glob patterns>"] }
}
```

All fields are optional. Defaults:
- `concurrency_limit`: 10
- `max_files_per_scanner`: 500
- `grouping_strategy`: "auto"
- `custom_groups`: {} (none)

Store the config values for use in Phase 0d and Phase 1.

### 0d. Inventory the codebase

If workspaces were detected in 0c, use the workspace package list as the domain list.

Otherwise, discover domains via ignore-aware file inventory:
- Build a stable inventory of source/config files with discovery tools that respect
  `.cursorignore`
- Derive domain directories from the inventory rather than from a raw shell directory walk
- Ignore support/noise paths that contain only generated output or internal framework files

Identify top-level domain directories (typically 4-12). This determines how many
domain-scanner instances to spawn.

### 0d.5. Domain grouping (monorepo scaling)

Count the number of domain packages (N) and calculate available domain slots:

```
specialist_count = 7  (6 specialists + auditor reserved)
slots_per_wave = concurrency_limit - specialist_count
```

**If N <= slots_per_wave:** single wave, no grouping needed. Each domain gets its own scanner.

**If N > slots_per_wave:** group domains to fit within concurrency limits.

Grouping priority order (use `grouping_strategy` from config, or "auto" which tries in order):

1. **Custom groups** — if `custom_groups` is configured, apply those first
2. **Scope grouping** — packages sharing an npm scope (`@scope/ui-*` → one scanner)
3. **Directory proximity** — packages in the same parent directory
4. **Size-based** — group smallest packages together until reaching ~`max_files_per_scanner` files
5. **Single packages** >500 files (or `max_files_per_scanner`) get their own dedicated slot

Record grouping in `_pipeline.json`:

```json
{
  "domain_groups": [
    {
      "group_label": "<label>",
      "packages": ["<package1>", "<package2>"],
      "total_files": 0,
      "wave": 1
    }
  ],
  "wave_count": 1,
  "concurrency_limit": 10
}
```

If no grouping is needed (N <= slots_per_wave), set `domain_groups` to null.

### 0e. Initialise pipeline status

Write `.cursor/constitution-tmp/_pipeline.json` to track the overall pipeline:

```json
{
  "started_at": "<ISO timestamp>",
  "phase": "scan",
  "mode": "parallel|sequential",
  "scan_type": "full",
  "workspace": null,
  "expected_agents": [
    "domain-scanner:<label1>",
    "domain-scanner:<label2>",
    "api-contract-analyst",
    "data-model-analyst",
    "dependency-analyst",
    "pattern-analyst",
    "runtime-flow-analyst",
    "infra-analyst"
  ]
}
```

If workspace structure was detected in 0c, populate the `"workspace"` field.

Each agent will write its own status file (`_status-<name>.json`) on completion,
so there are no concurrent write conflicts.

### 0f. Determine execution mode

**Parallel mode** (default): requires Cursor 2.4+ with subagent support.
**Sequential mode** (fallback): for older Cursor versions or when parallel spawning fails.

Attempt to spawn a single test subagent. If subagent spawning works, use parallel mode.
If it fails, fall back to sequential mode. Record the mode in `_pipeline.json`.

## Phase 1: Parallel scan (default mode)

Spawn these agents simultaneously (all can run in parallel):

**Domain scanners** — one instance per domain directory (or group):
- Tell each: "Scan the directory `<path>` as domain `<label>`"
- If this is a workspace project, tell each scanner its workspace package name
- If domains were grouped in Phase 0d.5, tell the scanner it is scanning a group
  (see domain-scanner's "Grouped scanning" section) and pass the `group_label` + `packages` list
- Tell each scanner to use ignore-aware, lexicographically stable coverage and to avoid
  arbitrary sampling caps
- **Wave execution** (when domain_groups exist and wave_count > 1):
  - Wave 1: all specialist analysts + first batch of domain groups (up to concurrency_limit)
  - Wait for Wave 1 completion via `_status-*.json`
  - Wave 2+: remaining domain groups (up to concurrency_limit per wave)
  - Report between waves: "Wave N/M complete: scanned [group labels]"
- **Single wave** (when all domains fit): spawn all domain scanners alongside specialists

**Specialist analysts** — spawn all six simultaneously:
- `api-contract-analyst` — full codebase scope
- `data-model-analyst` — full codebase scope
- `dependency-analyst` — full codebase scope
- `pattern-analyst` — full codebase scope
- `runtime-flow-analyst` — full codebase scope
- `infra-analyst` — full codebase scope

**Checking completion:** Read all `_status-*.json` files in `.cursor/constitution-tmp/`.
Each agent writes its own status file on completion. Verify every agent listed in
`_pipeline.json` → `expected_agents` has a corresponding status file with
`"status": "complete"`. If any show `"status": "failed"`, report the failure to the
user and offer to retry that agent.

Wait for ALL phase 1 agents to complete before moving to phase 2.

## Phase 1-SEQ: Sequential scan (fallback for older Cursor versions)

If parallel subagents are unavailable, run each agent sequentially in the main
context. Execute in this order (dependencies inform later agents):

1. `dependency-analyst` — sets the tech stack frame
2. `pattern-analyst` — identifies architecture and conventions
3. Domain-scanner instances — one at a time, per domain directory
4. `data-model-analyst` — schemas and entities
5. `api-contract-analyst` — API surfaces
6. `runtime-flow-analyst` — actual call chains and middleware
7. `infra-analyst` — infrastructure and deployment config

For each: read the agent definition from `.cursor/agents/<name>.md`, follow its
instructions exactly, write the same output files. Update the agent's status file
after each completes.

Report progress to the user after each agent: "Sequential scan: <N>/<total> agents
complete (<current agent name>)."

After all agents complete, proceed to Phase 2 (Audit) as normal.

## Phase 2: Audit

Update `_pipeline.json` → `"phase": "audit"`.
Spawn `constitution-auditor`.
Check for `_status-constitution-auditor.json` with `"status": "complete"`.
Report audit results to user: "Audit complete: <confidence>, <count> contested claims."
If overall_confidence is "low": ask user if they want to re-run specific agents.

## Phase 3: Aggregate

Update `_pipeline.json` → `"phase": "aggregate"`.
Invoke the `constitution-aggregator` skill.

## Phase 4: Curate

Update `_pipeline.json` → `"phase": "curate"`.
Invoke the `constitution-curator` skill.

## Phase 5: Finalise

Update `_pipeline.json` → `"phase": "complete"`.

1. Verify `docs/ai/constitution.md` exists
2. Verify `docs/ai/constitution-cheatsheet.md` exists
3. Verify `docs/ai/constitution-viewer.html` exists
4. Report section count and word estimate for constitution and cheat sheet
5. Report: "Viewer available at docs/ai/constitution-viewer.html — open in browser"
6. Ask: "Would you like to expand any section or re-run specific analysts?"
7. Preserve `_corrections.json`: if `.cursor/constitution-tmp/_corrections.json` exists,
   ensure `docs/ai/constitution-corrections.json` is up to date before any cleanup
8. Report correction count: if corrections exist, report how many were applied during this run
9. Write `_scan-metadata.json`: record `last_scan_commit` (current HEAD SHA),
   `last_scan_timestamp`, `scan_type: "full"`, `agents_run` (all agents), and
   `agent_file_coverage` (mapping each agent to the files it read, from `files_read_list`
   in each agent's status/output). This enables future incremental updates.
10. Offer to clean up: `rm -rf .cursor/constitution-tmp/`
    (keep `docs/ai/constitution-fragments/`, `docs/ai/constitution-corrections.json`,
    and `.cursor/constitution-tmp/_scan-metadata.json` — these are useful for re-runs)

## Error handling

- Subagent fails to write output: retry once with the same prompt
- Directory too large (>500 files): split into subdirectories, spawn two scanners
- Malformed JSON: ask that subagent to re-write its output file
- Audit finds low confidence: do not hide this — surface it clearly in the constitution
