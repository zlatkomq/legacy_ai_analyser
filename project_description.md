# Cursor Codebase Constitution Generator
## Architecture Guide: Multi-Subagent Brownfield Intelligence Layer

> **Goal:** Analyse a large brownfield codebase inside Cursor IDE and produce a
> `docs/ai/constitution.md` — a persistent AI-generation contract — using only
> Cursor-native primitives: Skills, Subagents, Rules, and Hooks.
>
> This is not a one-time summary tool. It is a **living intelligence layer** that
> stays accurate as the codebase evolves.

---

## 1. Why the Context Window is the Core Problem

A modern monorepo can contain 500k–5M tokens of source code. Even Claude with a
200k context window can't load it all. The standard naive approach — `@codebase`
and hope — produces shallow, hallucinated summaries. The solution is to decompose
the problem spatially and analytically, run isolated passes in parallel, then
aggregate and verify.

This guide implements a **Prepare → Map → Reduce → Audit → Curate** pipeline
entirely inside Cursor.

---

## 2. Cursor Primitives Used

| Primitive | Location | Purpose | Context behaviour |
|---|---|---|---|
| **SKILL.md** | `.cursor/skills/<n>/SKILL.md` | Procedural how-to, invoked on demand | Loaded when relevant/invoked |
| **Subagent** | `.cursor/agents/<n>.md` | Isolated specialist with own context | Separate context window per invocation |
| **Rule (.mdc)** | `.cursor/rules/<n>.mdc` | Declarative persistent instructions | Injected at start of main context |
| **Hook** | `.cursor/hooks/<n>.json` | Event-triggered automation | Fires on file save, commit, session start |
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
│  reads: .cursor/rules/constitution-mode.mdc      (orchestration discipline)
│  uses:  .cursor/skills/constitution/SKILL.md     (procedural workflow)
│
├─── SCAN PHASE (parallel, up to 10 concurrent) ──────────────────────────────┐
│    Each subagent: own context window, writes JSON + MD fragment to tmp/      │
│                                                                              │
│  ┌─ domain-scanner        ─── one instance per top-level directory          │
│  ├─ api-contract-analyst  ─── all API surfaces, auth, versioning            │
│  ├─ data-model-analyst    ─── schemas, entities, DTOs, data flow            │
│  ├─ dependency-analyst    ─── tech stack, package health, constraints       │
│  ├─ pattern-analyst       ─── architecture patterns, conventions, debt      │
│  └─ runtime-flow-analyst  ─── actual call chains, middleware, side effects  │
│                                                                              │
│    Each writes to: .cursor/constitution-tmp/<name>.json                     │
│                    .cursor/constitution-tmp/<name>.md   (human-readable)    │
└──────────────────────────────────────────────────────────────────────────────┘
│
├─── AUDIT PHASE
│    constitution-auditor subagent
│    Cross-checks claims across all reports before anything is written
│
├─── AGGREGATE PHASE
│    .cursor/skills/constitution-aggregator/SKILL.md
│    Merges verified reports, resolves conflicts, deduplicates
│
├─── CURATE PHASE
│    .cursor/skills/constitution-curator/SKILL.md
│    Produces final docs/ai/constitution.md
│
└─── DRIFT DETECTION (ongoing, via Hooks)
     .cursor/hooks/constitution-drift.json
     Fires on key file changes to flag when constitution needs updating
```

---

## 4. File Structure to Create

```
your-project/
├── .cursorignore                        ← FIRST artifact generated, gates all analysis
├── .cursor/
│   ├── agents/
│   │   ├── domain-scanner.md
│   │   ├── api-contract-analyst.md
│   │   ├── data-model-analyst.md
│   │   ├── dependency-analyst.md
│   │   ├── pattern-analyst.md
│   │   ├── runtime-flow-analyst.md      ← NEW: traces actual call chains
│   │   └── constitution-auditor.md      ← NEW: cross-validates agent claims
│   ├── skills/
│   │   ├── constitution/
│   │   │   └── SKILL.md                 ← master orchestration skill
│   │   ├── constitution-aggregator/
│   │   │   └── SKILL.md                 ← merge verified reports
│   │   └── constitution-curator/
│   │       └── SKILL.md                 ← produce final constitution.md
│   ├── rules/
│   │   ├── constitution-mode.mdc        ← orchestration discipline
│   │   └── constitution-reference.mdc   ← auto-inject constitution on code files
│   └── hooks/
│       └── constitution-drift.json      ← NEW: detect drift on key file changes
├── docs/
│   └── ai/
│       ├── constitution.md              ← FINAL OUTPUT (moved from project root)
│       └── constitution-fragments/      ← intermediate MD fragments (inspectable)
│           ├── domain-auth.md
│           ├── api-contracts.md
│           └── ...
└── .cursor/constitution-tmp/            ← scratch JSON (gitignored)
    └── .gitignore
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

1. List files: `find <dir> -type f -not -path "*/node_modules/*" | head -200`
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

1. Find route definitions:
   `grep -r "router\.\|app\.get\|app\.post\|@Get\|@Post\|@Route\|path(" --include="*.ts" --include="*.js" --include="*.py" -l`
2. Find GraphQL: `find . -name "*.graphql" -o -name "schema.ts" | grep -v node_modules`
3. Find OpenAPI/Swagger: `find . -name "openapi.yaml" -o -name "swagger.json" | grep -v node_modules`
4. Find events/messages: look for kafka, rabbitmq, eventbus, pubsub patterns
5. For each surface: read and extract endpoint signatures
6. Identify auth patterns per endpoint group
7. Identify versioning strategy

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

1. Find schema definitions:
   - SQL: `find . -path "*/migrations/*.sql" | grep -v node_modules`
   - ORM: `grep -r "@Entity\|@Table\|Model.define\|class.*extends Model" --include="*.ts" --include="*.py" -l`
   - Prisma/Drizzle: `find . -name "schema.prisma" -o -name "schema.ts" | grep -v node_modules`
2. For each model/entity: extract fields, relations, indexes
3. Find DTOs: `grep -r "interface.*DTO\|type.*DTO\|class.*DTO" --include="*.ts" -l`
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

1. Read manifests:
   - `find . -name "package.json" -not -path "*/node_modules/*" | head -20`
   - `find . -name "requirements.txt" -o -name "pyproject.toml" -o -name "Cargo.toml" | grep -v node_modules`
2. For each: extract name, version, classify (UI/API/DB/testing/infra/util)
3. Identify runtime version from .nvmrc, .python-version, engines field
4. Identify framework versions
5. Check for: deprecated packages, security-sensitive packages, outdated versions
6. Count deep relative imports: `grep -r "from '../../\.\." --include="*.ts" -l | wc -l`

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
  "deep_relative_import_count": 0,
  "concerns": ["<dependency health issue>"],
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
- Deep relative imports detected: <count> — <high = architecture smell>

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

### 6.6 `runtime-flow-analyst.md` ← NEW

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

1. Find entry points:
   - HTTP: `grep -r "app.listen\|server.listen\|bootstrap\|createServer" --include="*.ts" --include="*.js" -l`
   - CLI: `find . -name "cli.ts" -o -name "cli.js" -o -name "cmd/" | grep -v node_modules`
   - Background jobs: `grep -r "cron\|schedule\|queue\|worker" --include="*.ts" -l`
   - Event consumers: `grep -r "subscribe\|consume\|on(" --include="*.ts" -l | head -20`

2. Trace 2-3 representative request flows end-to-end:
   - Pick one simple CRUD endpoint
   - Pick one complex business operation
   - Pick one event/background job if present
   For each: read the entry file, follow imports and calls through the layers

3. Map middleware chain:
   `grep -r "app.use\|middleware\|guard\|interceptor\|filter" --include="*.ts" -l | head -20`
   Read each, identify what it does and when it fires

4. Find side effects per operation type:
   - DB writes: what tables change on a typical POST/PUT?
   - Events emitted: what downstream systems are triggered?
   - External calls: what third-party APIs are called synchronously?
   - Cache invalidation: what gets cleared?

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

### 6.7 `constitution-auditor.md` ← NEW

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

### 7.1 Master Orchestration Skill: `.cursor/skills/constitution/SKILL.md`

```markdown
---
name: constitution
description: >
  Orchestrate full codebase analysis to produce docs/ai/constitution.md.
  Handles pre-flight setup, parallel scanning, auditing, aggregation, and
  curation. Invoke with /constitution or "generate constitution" or
  "analyse codebase for AI constitution".
version: 2.0.0
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

### 0c. Inventory the codebase
```bash
find . -type d -not -path "*/node_modules/*" -not -path "*/.git/*" \
       -not -path "*/dist/*" -not -path "*/build/*" \
       -not -path "*/.cursor/*" -not -path "*/docs/ai/*" \
       -maxdepth 3
```

Identify top-level domain directories (typically 4-12). This determines how many
domain-scanner instances to spawn.

## Phase 1: Parallel scan

Spawn these agents simultaneously (all can run in parallel):

**Domain scanners** — one instance per top-level domain directory:
- Tell each: "Scan the directory `<path>` as domain `<label>`"
- Maximum 8 domain scanners in parallel
- If >8 domains: group smaller dirs, or run in two batches

**Specialist analysts** — spawn all four simultaneously:
- `api-contract-analyst` — full codebase scope
- `data-model-analyst` — full codebase scope
- `dependency-analyst` — full codebase scope
- `pattern-analyst` — full codebase scope
- `runtime-flow-analyst` — full codebase scope

Wait for ALL phase 1 agents to complete before moving to phase 2.
Check completion by verifying their output files exist in `.cursor/constitution-tmp/`.

## Phase 2: Audit

Spawn `constitution-auditor`.
Wait for `audit-report.json` to appear in `.cursor/constitution-tmp/`.
Report audit results to user: "Audit complete: <confidence>, <count> contested claims."
If overall_confidence is "low": ask user if they want to re-run specific agents.

## Phase 3: Aggregate

Invoke the `constitution-aggregator` skill.

## Phase 4: Curate

Invoke the `constitution-curator` skill.

## Phase 5: Finalise

1. Verify `docs/ai/constitution.md` exists
2. Report section count and word estimate
3. Ask: "Would you like to expand any section or re-run specific analysts?"
4. Offer to clean up: `rm -rf .cursor/constitution-tmp/`
   (keep `docs/ai/constitution-fragments/` — these are useful for re-runs)

## Error handling

- Subagent fails to write output: retry once with the same prompt
- Directory too large (>500 files): split into subdirectories, spawn two scanners
- Malformed JSON: ask that subagent to re-write its output file
- Audit finds low confidence: do not hide this — surface it clearly in the constitution
```

---

### 7.2 Aggregator Skill: `.cursor/skills/constitution-aggregator/SKILL.md`

```markdown
---
name: constitution-aggregator
description: >
  Merges all partial JSON and MD reports from .cursor/constitution-tmp/ into a
  single coherent intermediate representation, applying audit findings to flag
  uncertain content. Invoke after auditor completes.
version: 2.0.0
---

# Constitution Aggregator

## Purpose

Merge all scan reports into one verified intermediate structure that the curator
writes into `docs/ai/constitution.md`.

## Steps

1. List all files: `ls -la .cursor/constitution-tmp/`

2. Read the audit report FIRST: `.cursor/constitution-tmp/audit-report.json`
   This tells you which claims to accept, flag, or exclude.

3. Read all other JSON files in this order:
   - dependencies.json (tech stack — sets the frame)
   - patterns.json (architecture — shapes everything else)
   - data-model.json
   - api-contracts.json
   - runtime-flow.json
   - domain-*.json (all domain scanner outputs)

4. Build merged structure covering:
   - System identity (name, type, language, runtime, framework)
   - Architecture narrative (from patterns + domains)
   - Tech stack contract (from dependencies)
   - Data model (from data-model + cross-checked against domains)
   - API surface (from api-contracts + cross-checked against runtime-flow)
   - Runtime behaviour (from runtime-flow — this is the unique section static tools miss)
   - Cross-domain concerns (auth, error handling, logging, events)
   - AI generation rules (derived from patterns — DO and DO NOT lists)
   - Technical debt register (all issues from all reports, deduplicated, sorted by severity)
   - Sensitive zones (security-relevant files, fragile areas, AI caution zones)

5. For every item marked in `sections_to_flag_in_constitution` in the audit report:
   annotate the merged structure with `"confidence": "low"` and `"needs_human_review": true`

6. Write merged output to `.cursor/constitution-tmp/_merged.json`

7. Report: "Aggregation complete: <domain count> domains, <endpoint count> endpoints,
   <issue count> debt items, <flagged count> sections flagged for review."
```

---

### 7.3 Curator Skill: `.cursor/skills/constitution-curator/SKILL.md`

```markdown
---
name: constitution-curator
description: >
  Reads .cursor/constitution-tmp/_merged.json and writes the final
  docs/ai/constitution.md following the canonical template. Invoke after
  aggregation completes.
version: 2.0.0
---

# Constitution Curator

## Purpose

Write `docs/ai/constitution.md` from the merged, audited intermediate data.
This is the document that all future AI generation work will reference.

## Steps

1. Read `.cursor/constitution-tmp/_merged.json`
2. Also read all `docs/ai/constitution-fragments/*.md` for narrative context
3. Write `docs/ai/constitution.md` following the template below exactly
4. For any section with `needs_human_review: true`: add a visible warning block
5. Report: "Constitution written — <section count> sections, ~<word count> words"

## Template

---

# constitution.md — [Project Name] AI Generation Contract

> **Version:** 1.0
> **Generated:** [date]
> **Method:** Cursor multi-agent analysis (domain-scanner × N, api-contract-analyst,
> data-model-analyst, dependency-analyst, pattern-analyst, runtime-flow-analyst,
> constitution-auditor)
> **Overall confidence:** [from audit report]

---

> ⚠️ **Sections marked [NEEDS REVIEW]** contain claims that the auditor could not
> fully verify or that were contested across multiple reports. Do not treat these
> as authoritative without human validation.

---

## 1. Project Identity

**Name:** [from package.json or inferred]
**Type:** [Web app / API / Mobile backend / Monorepo / Library]
**Primary language:** [language(s) with approx % split]
**Runtime:** [Node 20.x / Python 3.11 / JVM 17 / etc. — exact version]
**Primary framework:** [Next.js 14 / NestJS 10 / Django 4.2 / etc. — exact version]

**System description:**
[2-3 sentences: what it does, who uses it, what problem it solves — inferred from code]

---

## 2. Architecture Overview

**Architectural style:** [Clean Architecture / Layered MVC / Hexagonal / Microservices]
**Layers:** [list layers in order with one-line description each]

**Directory map:**
```
[reproduce key directory tree with one-line annotation per dir]
```

**Domain inventory:**
| Domain | Path | Responsibility | Confidence |
|--------|------|----------------|------------|
[one row per domain from domain-scanner reports]

**Cross-domain communication:** [how domains interact — direct import / events / REST / etc.]

---

## 3. Tech Stack Contract

> Treat this section as a constraint, not a suggestion. AI generation must not
> introduce dependencies outside this list without explicit human approval.

**Runtime:** [exact version]
**Framework:** [name + exact version]
**Package manager:** [npm/yarn/pnpm] — use exclusively, never mix
**Monorepo tool:** [nx/turborepo/lerna/none]

### Core dependencies
| Package | Version | Role | Generation notes |
|---------|---------|------|-----------------|
[top 20 dependencies with role and any AI-generation notes]

### Hard constraints
- Node/Python/Java version: [exact — enforce, do not upgrade without team decision]
- Import style: [ESM/CommonJS — do not mix]
- [any other hard constraints from dependency-analyst]

---

## 4. Data Model

**Database:** [type]
**ORM:** [name + version]
**Schema location:** [`<path>`]

### Entity map
| Entity | Table/Collection | Key Relations | Notes |
|--------|-----------------|---------------|-------|
[one row per entity]

### Data flow
[Describe the standard path: request → controller → service → repository → DB
and the return path. Be specific about where validation happens, where transactions start.]

### Naming conventions
- Tables: [pattern]
- Columns: [pattern]
- IDs: [UUID/auto-increment/ULID + where generated]

### Issues [NEEDS REVIEW if flagged]
[List from data-model audit with severity]

---

## 5. API Contract

**Style:** [REST/GraphQL/gRPC/mixed]
**Auth:** [JWT Bearer / API key / session / OAuth2 — describe exactly]
**Versioning:** [URL prefix /v1 / header / none]
**Base URL pattern:** [/api/v1/...]

### Endpoint inventory
[Group by domain. For each: METHOD /path — auth requirement — brief description]

### Request/Response conventions
- Content-Type: [value]
- Error format: [describe the standard error shape with example]
- Pagination: [describe the pattern]
- Dates: [ISO 8601 / Unix timestamp / etc.]

---

## 6. Runtime Behaviour

> This section captures what static analysis cannot: how the system actually
> behaves when a request arrives. AI generation MUST respect these flows.

### Entry points
| Type | File | Description |
|------|------|-------------|
[from runtime-flow-analyst]

### Middleware execution chain
[List in order with purpose. This is the execution context for every request.]

### Key traced flows
[For each traced flow: name, entry point, layer-by-layer call chain, side effects]

### Global side effects
[Things that happen on every request regardless — audit logging, rate limiting, etc.]

### AI generation note
> When adding new endpoints or operations:
> [List specific rules derived from runtime-flow analysis]

---

## 7. Coding Conventions

> These are observed conventions from the actual codebase. AI must follow them
> when generating new code, even if they differ from framework defaults.

### Naming
- Variables/functions: [camelCase/snake_case]
- Classes: [PascalCase]
- Files: [kebab-case/camelCase — be specific per file type]
- Database: [naming pattern]
- Constants: [UPPER_SNAKE_CASE/etc.]
- Event names: [pattern if applicable]

### File organisation
[Where does a new feature put its files? Be specific:
"A new domain goes in src/<domain>/ with index.ts, <domain>.service.ts,
<domain>.repository.ts, <domain>.controller.ts, and __tests__/"]

### Error handling
[Describe the established pattern: custom error class? HTTP exception layer?
Result type? Where are errors caught, where are they thrown?]

### Async pattern
[async/await throughout / promise chains in legacy areas / etc. — be honest about inconsistency]

### Logging
[Library, log levels, what gets logged and where]

---

## 8. Test Strategy

**Framework:** [Jest/Vitest/pytest/JUnit]
**Location:** [co-located __tests__ / separate test/ dir]
**Required types:** [unit + integration / e2e optional]
**Mocking approach:** [jest.mock / manual mocks / factory pattern]
**Coverage tooling:** [istanbul/nyc/coverage-v8/etc.]

### Test naming convention
[describe the pattern: "should <verb> when <condition>"]

### Non-negotiable test requirements
[List what MUST be tested for every new feature — derived from observed patterns]

---

## 9. AI Generation Rules

> These rules are derived from actual codebase analysis. They are not aspirational —
> they reflect what the codebase actually does. Follow them for consistent output.

### DO
[10-15 specific, file-referenced DOs]
Examples format:
- DO use `AppError` from `src/common/errors.ts` for all business logic errors
- DO add request validation schemas to `src/schemas/<domain>.schema.ts` using zod
- DO use the `BaseRepository<T>` class from `src/common/repository.ts` for DB access

### DO NOT
[10-15 specific, file-referenced DO NOTs]
Examples format:
- DO NOT query the database from controllers — route through service → repository
- DO NOT use `any` type — use `unknown` with type guards or explicit interfaces
- DO NOT hardcode environment values — use `config` from `src/config/index.ts`

### New feature generation checklist
[Step-by-step, specific to THIS project's actual structure]

---

## 10. Technical Debt Register

> Review this before starting AI-assisted work in affected areas. AI generation
> will propagate and compound existing debt unless explicitly countered.

| ID | Domain | Location | Issue | Severity | AI Risk | Recommended action |
|----|--------|----------|-------|----------|---------|-------------------|
[from all reports, sorted by severity × AI Risk]

**AI Risk levels:**
- **HIGH** — AI will almost certainly reproduce or worsen this if not explicitly instructed
- **MEDIUM** — AI may reproduce this; include counter-instructions when working in this area
- **LOW** — Cosmetic or structural issue; AI unlikely to interact with it

---

## 11. Sensitive Zones

> AI generation requires explicit human review before merging changes in these areas.

[List files/directories that are: security-critical, known to be fragile,
contain implicit contracts not visible from code, or flagged by the auditor]

For each zone: path + reason + what to watch for

---

## 12. Analysis Metadata

**Scan date:** [date]
**Cursor version:** [version]
**Agents run:** domain-scanner ×[N], + 6 specialist agents
**Files sampled:** ~[count]
**Domains covered:** [count]

**Confidence by section:**
| Section | Confidence | Notes |
|---------|------------|-------|
[one row per major section from audit report]

**Known gaps:**
[List what this analysis did NOT cover — be honest]

**Suggested re-analysis triggers:**
- Major ORM migration added
- New API versioning layer introduced
- Auth strategy changed
- New domain directory added at top level
- Quarterly refresh regardless

---
```

---

## 8. Rules

### 8.1 Orchestration Rule: `.cursor/rules/constitution-mode.mdc`

```yaml
---
description: >
  Orchestration rules for the constitution generation pipeline. Apply when user
  requests codebase analysis, constitution generation, AI readiness assessment,
  or brownfield onboarding.
alwaysApply: false
---

# Constitution Generation Rules

When generating or updating the constitution:

1. ALWAYS run the `constitution` skill — never improvise the workflow
2. ALWAYS generate/verify `.cursorignore` BEFORE spawning any subagent
3. ALWAYS write outputs to `docs/ai/` not the project root
4. ALWAYS spawn domain-scanner agents per directory — never one agent for the whole codebase
5. ALWAYS run the auditor BEFORE aggregation — never skip this step
6. NEVER write constitution.md directly from main context — go through aggregator + curator
7. Surface audit findings to the user — never silently discard contested claims
8. Report progress after each phase: Pre-flight → Scan → Audit → Aggregate → Curate
9. If overall audit confidence is "low": tell the user and offer to re-run specific agents
```

### 8.2 Reference Rule: `.cursor/rules/constitution-reference.mdc`

```yaml
---
description: >
  Inject constitution reference when working on source files. Ensures AI generation
  always checks project conventions before producing code.
globs: ["src/**/*.ts", "src/**/*.js", "src/**/*.py", "src/**/*.java", "src/**/*.go"]
alwaysApply: false
---

Before generating or modifying code in this project:

1. Check @docs/ai/constitution.md — specifically sections 7 (Coding Conventions),
   8 (Test Strategy), and 9 (AI Generation Rules)
2. Verify your output complies with the DO / DO NOT rules in section 9
3. If working in a domain listed in the Technical Debt Register (section 10):
   read the AI Risk level and apply counter-instructions accordingly
4. If working in a Sensitive Zone (section 11): flag for human review before completing
5. If your generated code introduces a pattern NOT covered by the constitution:
   note it at the end of your response as "New pattern introduced: <description>"
```

---

## 9. Drift Detection Hook: `.cursor/hooks/constitution-drift.json`

This hook fires when key structural files change and flags that the constitution
may need updating.

```json
{
  "name": "constitution-drift-detector",
  "description": "Flags when files that affect the constitution have changed",
  "triggers": [
    {
      "event": "file_save",
      "globs": [
        "**/schema.prisma",
        "**/migrations/**/*.sql",
        "**/package.json",
        "**/openapi.yaml",
        "**/swagger.json",
        "src/**/routes/**/*.ts",
        "src/**/controllers/**/*.ts",
        "src/**/middleware/**/*.ts"
      ]
    }
  ],
  "action": {
    "type": "notify",
    "message": "⚠️ Constitution drift detected: `{changed_file}` has changed. This file affects the {inferred_section} section of docs/ai/constitution.md. Consider re-running the relevant analyst:\n- Schema change → re-run data-model-analyst\n- Route/controller change → re-run api-contract-analyst + runtime-flow-analyst\n- package.json change → re-run dependency-analyst\n- Middleware change → re-run runtime-flow-analyst",
    "severity": "warning"
  }
}
```

**Fallback if Cursor hooks don't fire reliably:** Add this as a git pre-commit script:

```bash
#!/bin/bash
# .git/hooks/pre-commit — constitution drift check

CONSTITUTION="docs/ai/constitution.md"
DRIFT_FILES="schema.prisma openapi.yaml swagger.json"

if [ ! -f "$CONSTITUTION" ]; then
  echo "⚠️  No constitution found. Run /constitution to generate docs/ai/constitution.md"
  exit 0
fi

CONSTITUTION_DATE=$(git log -1 --format="%ct" -- "$CONSTITUTION" 2>/dev/null || echo 0)

for pattern in $DRIFT_FILES; do
  CHANGED=$(git diff --cached --name-only | grep "$pattern")
  if [ -n "$CHANGED" ]; then
    echo "⚠️  Constitution drift: $CHANGED changed. Consider updating docs/ai/constitution.md"
  fi
done
```

---

## 10. Invocation

Once all files are in place:

```
Generate a constitution for this codebase
```
or `/constitution`

**Pipeline execution:**
1. Pre-flight: `.cursorignore` verified, dirs created, codebase inventoried
2. Scan: parallel domain scanners + 5 specialist analysts (each writes JSON + MD fragment)
3. Audit: cross-validation of all claims
4. Aggregate: merge with confidence annotations
5. Curate: write `docs/ai/constitution.md`

**Estimated time:** 10–25 minutes depending on codebase size.

**Partial re-runs** (after a change affects one section):
```
Re-run the api-contract-analyst and update the API section of the constitution
Re-run the runtime-flow-analyst — the middleware chain changed
Re-run the data-model-analyst — a new migration was added
```

---

## 11. Known Limitations and Mitigations

| Limitation | Impact | Mitigation |
|---|---|---|
| Subagents read ~150 files max | Large domains under-analysed | Split large dirs; use domain-scanner ×2 for big modules |
| Pattern analyst works on samples | May miss inconsistencies | Run twice with different seed files; auditor catches divergence |
| Runtime-flow traces 2-3 flows only | May miss atypical paths | Choose representative flows; document which were traced |
| No actual execution/profiling | Can't detect true hotpaths | Complement with `--prof` output or APM data if available |
| Confidence degrades on compiled code | dist/ / build/ pollutes analysis | `.cursorignore` must exclude these before any scan |
| Hooks still maturing in some Cursor versions | Drift detection may not fire | Use git pre-commit fallback |
| Session-scoped subagents | Constitution drifts over time | Re-run quarterly; use drift detection hook |
| Auditor may over-contest high-confidence claims | Noise in audit report | Treat "contested" as "worth a second look", not "wrong" |

---

## 12. AISDLC Plugin Manifest

Package the entire system as a Cursor plugin for single-command installation on
any client project:

```json
{
  "name": "q-agency-brownfield-intelligence",
  "version": "2.0.0",
  "description": "Multi-agent codebase analysis pipeline producing docs/ai/constitution.md — Q Agency AISDLC standard",
  "cursor_version_required": "2.4.0",
  "skills": [
    ".cursor/skills/constitution",
    ".cursor/skills/constitution-aggregator",
    ".cursor/skills/constitution-curator"
  ],
  "agents": [
    ".cursor/agents/domain-scanner.md",
    ".cursor/agents/api-contract-analyst.md",
    ".cursor/agents/data-model-analyst.md",
    ".cursor/agents/dependency-analyst.md",
    ".cursor/agents/pattern-analyst.md",
    ".cursor/agents/runtime-flow-analyst.md",
    ".cursor/agents/constitution-auditor.md"
  ],
  "rules": [
    ".cursor/rules/constitution-mode.mdc",
    ".cursor/rules/constitution-reference.mdc"
  ],
  "hooks": [
    ".cursor/hooks/constitution-drift.json"
  ],
  "artifacts": [
    ".cursorignore.template",
    ".git/hooks/pre-commit.template"
  ],
  "invocation": "/constitution",
  "output": "docs/ai/constitution.md"
}
```

---

*Cursor 2.4+ recommended for parallel subagent support (sequential fallback available for older versions).*
*Cursor 2.5+ required for plugin packaging.*
*Git pre-commit fallback works on any version.*
*Last updated: March 2026 — v2.1 with status tracking, sequential fallback, monorepo support, versioning/diffing, and auditor improvements*

---

## Adding a Custom Analyst Agent

The pipeline is extensible — you can add new specialist agents (e.g., `security-analyst`,
`performance-analyst`) without modifying the core framework.

### 1. Create the agent definition

Create `.cursor/agents/<name>.md` following the established pattern:

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
- **Status tracking** — write `_status-<name>.json` on start/completion (see any existing agent for the pattern)
- **When invoked** — numbered steps for what the agent does
- **JSON output** — schema for `.cursor/constitution-tmp/<name>.json` (must include `"confidence": "high|medium|low"`)
- **Markdown fragment** — template for `docs/ai/constitution-fragments/<name>.md`
- **Rules** — constraints on agent behaviour

### 2. Register the agent in the orchestrator

Edit `.cursor/skills/constitution/SKILL.md`, Phase 1:
- Add your agent to the "Specialist analysts" spawn list
- Add it to the `expected_agents` list in Phase 0e

### 3. Update the aggregator

Edit `.cursor/skills/constitution-aggregator/SKILL.md`, Step 3:
- Add your agent's JSON file to the read order
- Map its data into the appropriate constitution section(s) in Step 4

### 4. Update the curator (if adding a new constitution section)

If your agent produces data that warrants a new constitution section:
- Add the section template to `.cursor/skills/constitution-curator/SKILL.md`
- Add a corresponding entry in the viewer's Section IDs table

### 5. Update the auditor scope

Edit `.cursor/agents/constitution-auditor.md`:
- Add your agent's report to the cross-validation checks in step 5

### 6. Update install.sh

The installer automatically copies all `.md` files from `.cursor/agents/`,
so no change is needed unless you add new directories or files outside agents/.