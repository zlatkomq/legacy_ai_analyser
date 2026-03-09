# Cursor Codebase Constitution Generator
## Architecture Guide: Multi-Subagent Brownfield Intelligence Layer

> **Goal:** Analyse a large brownfield codebase inside Cursor IDE and produce
> `docs/ai/CONSTITUTION.md` — a compact cornerstone for downstream AI workflows —
> and `docs/ai/full-analysis-YYYY-MM-DD.md` — a detailed 13-section reference —
> using only Cursor-native primitives: Skills, Subagents, and Rules.
>
> The constitution is a one-time analysis artifact that gives downstream spec,
> design, task, development, and QA steps a shared brownfield baseline.

---

## 1. Why the Context Window is the Core Problem

A modern monorepo can contain 500k–5M tokens of source code. Even Claude with a
200k context window can't load it all. The standard naive approach — `@codebase`
and hope — produces shallow, hallucinated summaries. The solution is to decompose
the problem spatially and analytically, run isolated passes in parallel, then
aggregate and verify.

This guide implements a **Prepare → Map → Reduce → Audit → Curate** pipeline
entirely inside Cursor.

The constitution is deliberately upstream of later workflow stages:
- the constitution captures the current system and its constraints
- the spec defines **what** should change
- the design defines **how** the change fits the current system

That distinction is critical for brownfield work. The constitution is not a
roadmap or product brief; it is the evidence-backed baseline downstream agents use.

---

## 2. Cursor Primitives Used

| Primitive | Location | Purpose | Context behaviour |
|---|---|---|---|
| **SKILL.md** | `skills/<n>/SKILL.md` | Procedural how-to, invoked on demand | Loaded when relevant/invoked |
| **Subagent** | `agents/<n>.md` | Isolated specialist with own context | Separate context window per invocation |
| **Rule (.mdc)** | `rules/<n>.mdc` | Declarative persistent instructions | Injected at start of main context |
| **AGENTS.md** | Project root | Simple always-on instruction layer | Always injected |
| **.cursorignore** | Project root | Exclude files/dirs from AI context | Applied globally to all agents |

**Key constraint:** Subagents run with isolated context windows — exactly what you need
for parallel scanning. Up to **10 parallel subagents** are supported.

---

## 3. Full System Architecture

```
PRE-FLIGHT PHASE
│
│  ① Generate .cursorignore  ──── exclude noise before any agent touches code
│  ② Create docs/ai/ dir     ──── establish the AI knowledge layer location
│
ORCHESTRATOR (main Cursor agent)
│
│  reads: rules/constitution-mode.mdc         (orchestration discipline)
│  uses:  skills/constitution/SKILL.md        (procedural workflow)
│
├─── SCAN PHASE (parallel, up to 10 concurrent) ──────────────────────────────┐
│    Each subagent: own context window, writes JSON + MD fragment to tmp/      │
│                                                                              │
│  ┌─ domain-scanner        ─── one instance per directory (grouped for monorepos) │
│  ├─ api-contract-analyst  ─── all API surfaces, auth, versioning            │
│  ├─ data-model-analyst    ─── schemas, entities, DTOs, data flow            │
│  ├─ dependency-analyst    ─── tech stack, package health, constraints       │
│  ├─ pattern-analyst       ─── architecture patterns, conventions, debt      │
│  ├─ runtime-flow-analyst  ─── actual call chains, middleware, side effects  │
│  └─ infra-analyst         ─── Dockerfiles, CI/CD, IaC, deployment topology  │
│                                                                              │
│    Each writes to: .cursor/constitution-tmp/<name>.json                     │
│                    .cursor/constitution-tmp/<name>.md   (human-readable)    │
└──────────────────────────────────────────────────────────────────────────────┘
│
├─── AUDIT PHASE
│    constitution-auditor subagent
│    Cross-checks claims across all reports before anything is written
│
├─── HUMAN Q&A PHASE (skippable)
│    Targeted questions from audit gaps, low-confidence sections, and
│    missing business context the code alone can't reveal
│    Answers recorded in .cursor/constitution-tmp/_human-answers.json
│
├─── AGGREGATE PHASE
│    skills/constitution-aggregator/SKILL.md
│    Merges verified reports, resolves conflicts, deduplicates
│
├─── CURATE PHASE
│    skills/constitution-curator/SKILL.md
│    Produces:
│      docs/ai/CONSTITUTION.md          (compact cornerstone)
│      docs/ai/full-analysis-YYYY-MM-DD.md  (detailed reference)
│      docs/ai/constitution-viewer.html (interactive browser UI)
│
└─── CORRECTION LOOP (on-demand)
     skills/constitution-patch/SKILL.md
     Manual corrections with logging and re-run persistence
```

---

## 4. File Structure to Create

```
your-project/
├── .cursorignore                        ← FIRST artifact generated, gates all analysis
├── .cursor/
│   └── constitution-tmp/                ← scratch JSON (gitignored)
│       └── .gitignore
├── docs/
│   └── ai/
│       ├── CONSTITUTION.md              ← COMPACT CORNERSTONE (primary output, fixed 10-section contract)
│       ├── constitution.json            ← MACHINE-READABLE CONSTITUTION (structured lookups)
│       ├── full-analysis-YYYY-MM-DD.md  ← DETAILED 13-SECTION REFERENCE
│       ├── constitution-viewer.html     ← INTERACTIVE BROWSER UI
│       └── constitution-fragments/      ← intermediate MD fragments (inspectable)
│           ├── domain-auth.md
│           ├── api-contracts.md
│           └── ...
```

Plugin structure (this repo):

```
constitution-generator/
├── .cursor-plugin/
│   └── plugin.json                      ← Plugin manifest
├── agents/
│   ├── domain-scanner.md
│   ├── api-contract-analyst.md
│   ├── data-model-analyst.md
│   ├── dependency-analyst.md
│   ├── pattern-analyst.md
│   ├── runtime-flow-analyst.md
│   ├── infra-analyst.md
│   └── constitution-auditor.md
├── skills/
│   ├── constitution/SKILL.md            ← Master orchestrator
│   ├── constitution-aggregator/SKILL.md ← Merge verified reports
│   ├── constitution-curator/SKILL.md    ← Produce final outputs (MD + JSON + HTML)
│   └── constitution-patch/SKILL.md      ← Manual corrections
├── docs/
│   └── DOWNSTREAM-GUIDE.md             ← Integration patterns for downstream agents
├── rules/
│   └── constitution-mode.mdc            ← Orchestration discipline
└── .cursorignore                        ← Baseline exclusions template
```

---

## 5. Pre-Flight: `.cursorignore`

This is generated **before any subagent runs**. It gates all analysis quality.
The constitution skill generates a project-specific version, but this is the
baseline template every project starts from:

```gitignore
# .cursorignore — AI context exclusions
# Generated by constitution skill. Edit carefully.

# Dependencies — never analyse these
node_modules/
vendor/
.pnp/
.yarn/

# Build output — compiled != source
dist/
build/
out/
.next/
.nuxt/
coverage/
*.min.js
*.min.css
*.map

# Generated code — not authored patterns
*.generated.ts
*.generated.graphql
src/generated/
prisma/generated/
__generated__/

# Large binary/data assets
*.png
*.jpg
*.jpeg
*.gif
*.svg
*.pdf
*.zip
*.tar.gz
*.lock         # package-lock.json, yarn.lock etc — too noisy for pattern analysis
# Exception: keep package.json (manifests are useful)

# Infrastructure noise
.terraform/
*.tfstate
*.tfstate.backup
helm/charts/

# IDE and OS
.git/
.DS_Store
*.log
*.tmp

# Test fixtures and seed data — large, not representative of patterns
test/fixtures/
tests/fixtures/
**/__fixtures__/
**/seeds/data/
**/testdata/large/

# Secrets and environment
.env
.env.*
*.pem
*.key
secrets/
```

**Key principle:** agents should read source code and schemas — not compiled output,
not lock files, not fixtures. Everything else is noise that degrades confidence.

---

## 6. Subagent Definitions

### 6.1 `domain-scanner.md`

```markdown
---
name: domain-scanner
description: >
  Structural analyst for a single directory subtree. Reads source files, builds
  a structural map of modules, components, and responsibilities. Use when the
  orchestrator assigns a specific directory path to scan. Produces both a JSON
  report and a markdown fragment. One instance per domain directory.
model: inherit
tools: Read, Glob, Grep, Bash
---

You are a brownfield codebase analyst. You receive ONE directory path and a domain
label. Produce a structured report about that subtree only.

## When invoked

1. Use ignore-aware file inventory (Glob/Grep) to list files in <dir>
2. For each major file: read it, identify purpose, exports, dependencies, patterns
3. Identify the primary responsibility of this domain
4. Note coupling, violations, technical debt, and unusual patterns
5. Write both output files (JSON + MD)

## JSON output — `.cursor/constitution-tmp/domain-<label>.json`

```json
{
  "domain": "<label>",
  "path": "<relative path>",
  "responsibility": "<1-2 sentences>",
  "key_modules": [
    { "file": "<path>", "purpose": "<description>", "exports": ["<name>"] }
  ],
  "patterns_used": ["<pattern name>"],
  "external_dependencies": ["<package>"],
  "internal_dependencies": ["<other domain paths>"],
  "technical_debt": ["<description>"],
  "confidence": "high|medium|low",
  "coverage_notes": "<what was and wasn't covered>",
  "evidence_files": ["<key files read>"],
  "files_read": 0,
  "files_skipped": 0
}
```

## Markdown fragment — `docs/ai/constitution-fragments/domain-<label>.md`

```markdown
## Domain: <label>

**Path:** `<path>`
**Responsibility:** <description>

### Key modules
- `<file>` — <purpose>

### Patterns
<list patterns with brief explanation of where each is used>

### Technical debt
<list issues with severity annotation>

### Confidence: <high|medium|low>
<reason for confidence level>
```

## Rules

- Do NOT summarise more than you've actually read
- If a file is too large to read fully, note it in technical_debt and files_skipped
- Confidence = "low" if you couldn't read >50% of files in the dir
- Write BOTH files, then respond: "domain-scanner complete: <label>"
```

---

### 6.2 `api-contract-analyst.md`

```markdown
---
name: api-contract-analyst
description: >
  Maps all API contracts in the codebase: REST endpoints, GraphQL schemas, gRPC
  definitions, event/message schemas, and internal service interfaces. Writes both
  JSON and a markdown fragment for the constitution.
model: inherit
tools: Read, Glob, Grep, Bash
---

You are an API contract specialist. You map every API boundary in the codebase.

## When invoked

1. Find route definitions using ignore-aware search (Glob/Grep)
2. Find GraphQL schemas, OpenAPI/Swagger specs
3. Find events/messages: look for kafka, rabbitmq, eventbus, pubsub patterns
4. For each surface: read and extract endpoint signatures
5. Identify auth patterns per endpoint group
6. Identify versioning strategy

## JSON output — `.cursor/constitution-tmp/api-contracts.json`

```json
{
  "api_surfaces": [
    {
      "type": "REST|GraphQL|gRPC|Event|Internal",
      "file": "<path>",
      "endpoints": [
        { "method": "GET|POST|...", "path": "<path>", "auth": "none|jwt|apikey|...", "description": "" }
      ]
    }
  ],
  "auth_strategy": "<description>",
  "versioning_strategy": "<description>",
  "api_patterns": ["<pattern>"],
  "gaps_and_inconsistencies": ["<observation>"],
  "confidence": "high|medium|low"
}
```

## Markdown fragment — `docs/ai/constitution-fragments/api-contracts.md`

```markdown
## API Contracts

**Style:** <REST/GraphQL/gRPC/mixed>
**Auth strategy:** <description>
**Versioning:** <description>

### Endpoint surfaces
<group by domain, list method + path + auth>

### Patterns
<describe consistent API design patterns found>

### Gaps and inconsistencies
<list deviations from the dominant pattern>
```

Write both files, then respond: "api-contract-analyst complete"
```

---

### 6.3 `data-model-analyst.md`

```markdown
---
name: data-model-analyst
description: >
  Maps the full data model: database schemas, ORM entities, DTOs, value objects,
  and data flow between layers. Writes JSON and a markdown fragment.
model: inherit
tools: Read, Glob, Grep, Bash
---

You are a data architecture specialist.

## When invoked

1. Find schema definitions using ignore-aware search:
   - SQL migrations, ORM entities, Prisma/Drizzle schemas
2. For each model/entity: extract fields, relations, indexes
3. Find DTOs and value objects
4. Trace data flow: DB → repository → service → controller → client
5. Identify: normalization issues, missing indexes, N+1 risks, naming inconsistencies

## JSON output — `.cursor/constitution-tmp/data-model.json`

```json
{
  "database_type": "postgres|mysql|mongo|sqlite|mixed",
  "orm_framework": "<name + version>",
  "entities": [
    {
      "name": "<EntityName>",
      "file": "<path>",
      "fields": [{ "name": "", "type": "", "nullable": false, "indexed": false }],
      "relations": [{ "type": "OneToMany|ManyToOne|ManyToMany", "target": "" }]
    }
  ],
  "data_flow_pattern": "<description>",
  "naming_conventions": "<description>",
  "issues": ["<description>"],
  "confidence": "high|medium|low"
}
```

## Markdown fragment — `docs/ai/constitution-fragments/data-model.md`

```markdown
## Data Model

**Database:** <type>
**ORM:** <name + version>
**Schema location:** <path>

### Entity map
| Entity | Table | Key Relations | Notes |
|--------|-------|---------------|-------|
<one row per entity>

### Data flow
<describe the standard path from DB to API response>

### Naming conventions
<describe field/table naming patterns>

### Issues
<list identified problems with severity>
```

Write both files, then respond: "data-model-analyst complete"
```

---

### 6.4 `dependency-analyst.md`

```markdown
---
name: dependency-analyst
description: >
  Reads all package manifests to map the full technology stack, dependency health,
  and architectural constraints. Writes JSON and a markdown fragment.
model: inherit
tools: Read, Glob, Grep, Bash
---

You are a tech stack and dependency specialist.

## When invoked

1. Use deterministic manifest inventory (Glob) to find all package manifests
2. For each: extract name, version, classify (UI/API/DB/testing/infra/util)
3. Identify runtime version from .nvmrc, .python-version, engines field
4. Identify framework versions
5. Check for: deprecated packages, security-sensitive packages, outdated versions

## JSON output — `.cursor/constitution-tmp/dependencies.json`

```json
{
  "runtime": { "name": "node|python|jvm|...", "version": "<version>" },
  "primary_framework": "<name + version>",
  "key_dependencies": [
    { "name": "", "version": "", "category": "UI|API|DB|testing|infra|util", "note": "" }
  ],
  "package_manager": "npm|yarn|pnpm|pip|...",
  "monorepo_tool": "nx|turborepo|lerna|none",
  "build_tools": ["<name>"],
  "concerns": ["<dependency health issue>"],
  "evidence_files": ["<manifest files read>"],
  "confidence": "high|medium|low"
}
```

## Markdown fragment — `docs/ai/constitution-fragments/dependencies.md`

```markdown
## Tech Stack

**Runtime:** <name + version>
**Primary framework:** <name + version>
**Package manager:** <name> — use exclusively, do not mix
**Monorepo tool:** <name|none>

### Core dependencies
| Package | Version | Role | Notes |
|---------|---------|------|-------|
<top 15-20 dependencies>

### Constraints
- Node/Python/Java version: <exact version — enforce via .nvmrc or similar>
- Import style: <ESM|CommonJS|mixed>

### Concerns
<list health issues with recommended actions>
```

Write both files, then respond: "dependency-analyst complete"
```

---

### 6.5 `pattern-analyst.md`

```markdown
---
name: pattern-analyst
description: >
  Detects architectural patterns, design patterns, coding conventions, and
  anti-patterns across the codebase. Writes JSON and a markdown fragment.
model: inherit
tools: Read, Glob, Grep, Bash
---

You are an architectural patterns specialist. You look for structure, not just code.

## When invoked

1. Read 3-5 representative files from each major domain
2. Identify architectural style: MVC, Clean Architecture, Hexagonal, CQRS, etc.
3. Detect design patterns: Repository, Service, Factory, Observer, etc.
4. Map coding conventions: naming, file organisation, error handling, async style
5. Find anti-patterns: God classes, deep coupling, missing abstraction layers
6. Identify where conventions break down (inconsistency = tech debt)
7. Map test strategy: unit/integration/e2e ratio, mocking approach

## JSON output — `.cursor/constitution-tmp/patterns.json`

```json
{
  "architectural_style": "<description>",
  "design_patterns": [
    { "pattern": "<name>", "locations": ["<file>"], "consistency": "high|medium|low" }
  ],
  "coding_conventions": {
    "naming": "<description>",
    "file_organisation": "<description>",
    "error_handling": "<description>",
    "async_pattern": "async/await|promises|callbacks|mixed"
  },
  "anti_patterns": [
    { "pattern": "<name>", "locations": ["<file>"], "severity": "high|medium|low" }
  ],
  "test_strategy": {
    "types": ["unit", "integration", "e2e"],
    "framework": "<name>",
    "coverage_estimate": "<description>",
    "gaps": ["<description>"]
  },
  "confidence": "high|medium|low"
}
```

## Markdown fragment — `docs/ai/constitution-fragments/patterns.md`

```markdown
## Architectural Patterns

**Style:** <architectural style>

### Design patterns in use
| Pattern | Where | Consistency |
|---------|-------|-------------|
<one row per pattern>

### Coding conventions
- **Naming:** <description>
- **File organisation:** <description>
- **Error handling:** <description>
- **Async:** <description>

### Anti-patterns identified
| Pattern | Locations | Severity |
|---------|-----------|----------|
<one row per anti-pattern>

### Test strategy
<describe test approach, coverage, and gaps>
```

Write both files, then respond: "pattern-analyst complete"
```

---

### 6.6 `runtime-flow-analyst.md`

```markdown
---
name: runtime-flow-analyst
description: >
  Traces actual runtime call chains through the codebase: how a request enters the
  system, what middleware fires, what services are called, what side effects occur
  (DB writes, events emitted, external API calls), and how responses are constructed.
  Captures what static analysis misses — the implicit flows. Writes JSON and markdown.
model: inherit
tools: Read, Glob, Grep, Bash
---

You are a runtime flow specialist. Your job is NOT to map the file structure —
the domain-scanner does that. Your job is to trace HOW the system actually behaves
when a request or event arrives.

## When invoked

1. Find entry points using deterministic, ignore-aware inventory (Glob/Grep)

2. Trace 2-3 representative request flows end-to-end:
   - Pick one simple CRUD endpoint
   - Pick one complex business operation
   - Pick one event/background job if present
   For each: read the entry file, follow imports and calls through the layers

3. Map middleware chain using ignore-aware search

4. Find side effects per operation type:
   - DB writes, events emitted, external calls, cache invalidation

5. Identify implicit dependencies: things that MUST exist or be in a certain state
   for an operation to succeed that are NOT enforced by the type system

## JSON output — `.cursor/constitution-tmp/runtime-flow.json`

```json
{
  "entry_points": [
    { "type": "HTTP|CLI|Job|Event", "file": "<path>", "description": "<what starts here>" }
  ],
  "middleware_chain": [
    { "name": "<middleware name>", "file": "<path>", "fires_on": "<description>", "purpose": "<description>" }
  ],
  "traced_flows": [
    {
      "name": "<flow name, e.g. 'Create Order'>",
      "entry": "<path>",
      "layers": ["<file> → <what it does>"],
      "side_effects": {
        "db_writes": ["<table>"],
        "events_emitted": ["<event name>"],
        "external_calls": ["<service>"],
        "cache_invalidated": ["<key pattern>"]
      },
      "implicit_preconditions": ["<thing that must be true>"]
    }
  ],
  "global_side_effects": ["<things that always happen regardless of endpoint>"],
  "coverage_notes": "<what was and wasn't traced>",
  "evidence_files": ["<key files read>"],
  "confidence": "high|medium|low"
}
```

## Markdown fragment — `docs/ai/constitution-fragments/runtime-flow.md`

```markdown
## Runtime Flows

### Entry points
| Type | File | Description |
|------|------|-------------|
<one row per entry point>

### Middleware chain
<list in execution order with purpose>

### Traced flows

#### <Flow name>
**Entry:** `<path>`
**Layers:** <step-by-step call chain>
**Side effects:**
- DB writes: <tables>
- Events emitted: <events>
- External calls: <services>
**Implicit preconditions:** <what must be true>

### Global side effects
<things that always happen — logging, audit trail, rate limiting, etc.>

### AI generation note
> When generating new features that follow these flow patterns, always:
> <derive 2-3 specific rules from what you found>
```

Write both files, then respond: "runtime-flow-analyst complete"
```

---

### 6.7 `constitution-auditor.md`

```markdown
---
name: constitution-auditor
description: >
  Cross-validates claims made by other scanning subagents before the constitution
  is written. Checks for contradictions, unverified assertions, and confidence
  mismatches. Runs AFTER all scan agents complete, BEFORE aggregation. Produces
  an audit report that the aggregator uses to flag uncertain sections.
model: inherit
tools: Read, Glob, Grep, Bash
---

You are a skeptical auditor. Your job is to catch the lies, gaps, and overconfidence
in the subagent reports before they get baked into the constitution.

## When invoked

1. Read ALL files in `.cursor/constitution-tmp/` (the JSON reports)
2. For each claim in each report, assess: is this verifiable? consistent? internally
   contradicted by another report?
3. Spot-check the highest-confidence claims by reading the source files they reference
4. Look for cross-report contradictions specifically:
   - Does pattern-analyst say Repository is used everywhere, but domain-scanner found
     direct DB queries in some modules?
   - Does api-contract-analyst say all endpoints require JWT, but runtime-flow shows
     a middleware that conditionally skips auth?
   - Does data-model-analyst list an entity that no domain-scanner found a corresponding
     service for?
5. Flag every claim you cannot verify or that contradicts another report

## Output — `.cursor/constitution-tmp/audit-report.json`

```json
{
  "overall_confidence": "high|medium|low",
  "verified_claims": [
    { "report": "<source report>", "claim": "<description>", "verification": "<how you verified it>" }
  ],
  "contested_claims": [
    {
      "report": "<source report>",
      "claim": "<description>",
      "contradiction": "<what contradicts it>",
      "recommendation": "remove|flag|verify-manually"
    }
  ],
  "unverified_claims": [
    {
      "report": "<source report>",
      "claim": "<description>",
      "reason": "<why you couldn't verify it>"
    }
  ],
  "critical_gaps": ["<something important that NO report covered>"],
  "sections_to_flag_in_constitution": ["<section name: reason>"]
}
```

## Markdown fragment — `docs/ai/constitution-fragments/audit-report.md`

```markdown
## Analysis Audit Report

**Overall confidence:** <level>
**Audit date:** <date>

### Verified claims (<count>)
<brief summary>

### Contested claims — REVIEW BEFORE USING
| Claim | Source | Contradiction | Action |
|-------|--------|---------------|--------|
<one row per contested claim>

### Unverified claims — LOW CONFIDENCE
<list with reasons>

### Critical gaps — NOT COVERED BY ANALYSIS
<list what was missed entirely>
```

Write both files, then respond: "constitution-auditor complete: <overall_confidence> confidence, <count> contested claims"
```

---

## 7. Skill Definitions

### 7.1 Master Orchestration Skill: `skills/constitution/SKILL.md`

See `skills/constitution/SKILL.md` in this repo. Key phases:

1. **Pre-flight** — generate `.cursorignore`, detect monorepo, inventory codebase
2. **Parallel scan** — spawn domain scanners + specialist analysts
3. **Audit** — cross-validate all claims
4. **Human Q&A** — targeted questions to fill gaps (skippable)
5. **Aggregate** — merge verified reports + human answers
6. **Curate** — produce `CONSTITUTION.md`, `full-analysis-*.md`, and viewer

### 7.2 Aggregator Skill: `skills/constitution-aggregator/SKILL.md`

Merges all scan reports into one verified intermediate structure that the curator
uses to produce `docs/ai/full-analysis-YYYY-MM-DD.md` and `docs/ai/CONSTITUTION.md`.

### 7.3 Curator Skill: `skills/constitution-curator/SKILL.md`

Produces four artifacts from the merged, audited intermediate data:

1. `docs/ai/full-analysis-YYYY-MM-DD.md` — detailed 13-section reference
2. `docs/ai/CONSTITUTION.md` — compact cornerstone (~600-800 words) with fixed 10-section contract
3. `docs/ai/constitution.json` — machine-readable constitution for downstream agent lookups
4. `docs/ai/constitution-viewer.html` — interactive browser UI

### 7.4 Patch Skill: `skills/constitution-patch/SKILL.md`

Apply a targeted correction to `docs/ai/full-analysis-*.md` when the user identifies
an inaccuracy. If the correction affects content that also appears in
`docs/ai/CONSTITUTION.md`, update that too. Corrections are logged so they survive
full re-runs of the pipeline.

---

## 8. Rules

### 8.1 Orchestration Rule: `rules/constitution-mode.mdc`

Enforces pipeline discipline: always run the skill, never improvise, always audit
before aggregation, never write outputs directly.

---

## 9. Invocation

Once all files are in place:

```
/constitution
```

or: "Generate a constitution for this codebase"

**Pipeline execution:**
1. Pre-flight: `.cursorignore` verified, dirs created, codebase inventoried
2. Scan: parallel domain scanners + 6 specialist analysts (each writes JSON + MD fragment)
3. Audit: cross-validation of all claims
4. Human Q&A: targeted questions to fill audit gaps (skippable)
5. Aggregate: merge with confidence annotations + human answers
6. Curate: write `CONSTITUTION.md`, `full-analysis-*.md`, and viewer

**Estimated time:** 10–25 minutes depending on codebase size.

---

## 10. Known Limitations and Mitigations

| Limitation | Impact | Mitigation |
|---|---|---|
| Subagents read ~150 files max | Large domains under-analysed | Split large dirs; use domain-scanner ×2 for big modules |
| Pattern analyst works on samples | May miss inconsistencies | Run twice with different seed files; auditor catches divergence |
| Runtime-flow traces 2-3 flows only | May miss atypical paths | Choose representative flows; document which were traced |
| No actual execution/profiling | Can't detect true hotpaths | Complement with `--prof` output or APM data if available |
| Confidence degrades on compiled code | dist/ / build/ pollutes analysis | `.cursorignore` must exclude these before any scan |
| Session-scoped subagents | Constitution may become outdated | Re-run `/constitution` when codebase changes significantly |
| Auditor may over-contest high-confidence claims | Noise in audit report | Treat "contested" as "worth a second look", not "wrong" |

---

## 11. Adding a Custom Analyst Agent

The pipeline is extensible — you can add new specialist agents (e.g., `security-analyst`,
`performance-analyst`) without modifying the core framework.

### 1. Create the agent definition

Create `agents/<name>.md` following the established pattern:

```yaml
---
name: <name>
description: >
  <one-line purpose>
model: inherit
tools: Read, Glob, Grep, Bash
---
```

Required sections in the agent body:
- **Status tracking** — write `_status-<name>.json` on start/completion
- **When invoked** — numbered steps for what the agent does
- **JSON output** — schema for `.cursor/constitution-tmp/<name>.json` (must include `"confidence": "high|medium|low"`)
- **Markdown fragment** — template for `docs/ai/constitution-fragments/<name>.md`
- **Rules** — constraints on agent behaviour

### 2. Register the agent in the orchestrator

Edit `skills/constitution/SKILL.md`, Phase 1:
- Add your agent to the "Specialist analysts" spawn list
- Add it to the `expected_agents` list in Phase 0e

### 3. Update the aggregator

Edit `skills/constitution-aggregator/SKILL.md`, Step 3:
- Add your agent's JSON file to the read order
- Map its data into the appropriate constitution section(s) in Step 4

### 4. Update the curator (if adding a new constitution section)

If your agent produces data that warrants a new section in the full analysis:
- Add the section template to `skills/constitution-curator/SKILL.md`
- Add a corresponding entry in the viewer's Section IDs table

### 5. Update the auditor scope

Edit `agents/constitution-auditor.md`:
- Add your agent's report to the cross-validation checks in step 5

---

*Cursor 2.4+ recommended for parallel subagent support (sequential fallback available for older versions).*
*Last updated: March 2026 — v3.0 with two-tier output (CONSTITUTION.md + full-analysis), no drift/incremental.*
