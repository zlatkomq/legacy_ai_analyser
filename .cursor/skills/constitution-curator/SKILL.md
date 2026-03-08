---
name: constitution-curator
description: >
  Reads .cursor/constitution-tmp/_merged.json and writes the final
  docs/ai/constitution.md following the canonical template. Invoke after
  aggregation completes.
version: 2.1.0
---

# Constitution Curator

## Purpose

Write `docs/ai/constitution.md` from the merged, audited intermediate data.
This is the document that all future AI generation work will reference.

## Steps

1. Read `.cursor/constitution-tmp/_merged.json`
2. Also read all `docs/ai/constitution-fragments/*.md` for narrative context
3. **Compare with existing constitution (if present):**
   - If `docs/ai/constitution.md` already exists, read it
   - For each of the 12 sections, compare the new data against existing content
   - Track: added sections, removed content, modified claims, changed confidence levels, new/resolved debt items
   - Store this diff for step 8
4. Write `docs/ai/constitution.md` following the template below exactly
   - Use today's date as the version in `YYYY.MM.DD` format (e.g., `2026.03.08`)
   - Do NOT hardcode version `1.0`
5. For any section with `needs_human_review: true`: add a visible warning block
6. Generate `docs/ai/constitution-cheatsheet.md` — the condensed version for AISDLC agent injection (see Cheat Sheet Template below)
7. Generate `docs/ai/constitution-viewer.html` — a self-contained interactive viewer (see Viewer Template below)
8. **Generate changelog (if this is a re-run):**
   - If step 3 found an existing constitution, write `docs/ai/constitution-changelog.md`:
     ```markdown
     # Constitution Changelog

     ## [YYYY.MM.DD] (current run)

     ### Changed
     - [List section-by-section changes: added/removed/modified content]

     ### Confidence changes
     - [List sections where confidence level changed, with old → new]

     ### Summary
     X sections unchanged, Y sections modified, Z new items added

     ---
     [Preserve previous changelog entries if docs/ai/constitution-changelog.md already exists]
     ```
   - If this is a first run (no existing constitution), skip the changelog
9. Report: "Constitution written — <section count> sections, ~<word count> words. Cheat sheet and viewer generated."
   - If changelog was generated, also report: "Changelog updated with <change count> changes since previous version."

## Template

---

# constitution.md — [Project Name] AI Generation Contract

> **Version:** [YYYY.MM.DD]
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

## Cheat Sheet Template

After writing the full constitution, generate `docs/ai/constitution-cheatsheet.md` by
condensing the full constitution into ~500-800 words. This is the default context
document injected into every AISDLC agent (spec, design, tasks, code, test, review).

The cheat sheet MUST include these sections and nothing else:

```markdown
# [Project Name] — AI Constitution Cheat Sheet

> Condensed from `docs/ai/constitution.md` (v[YYYY.MM.DD]).
> This is the default context for all AISDLC agents. For full detail on any
> section, reference the complete constitution.

## System

[One-line: framework / language / runtime / database / key infrastructure]
[One-line: what the system is and does]
[One-line: package manager and module format constraints]

## Architecture

[One-line: architectural style and layer summary]
[One-line: list all domains by name]

## Critical runtime facts

[3-7 bullet points: the things that will break generated code if ignored.
 Extract from sections 6 (Runtime) and 11 (Sensitive Zones).
 Focus on: implicit middleware/interceptors, auth patterns, scoping rules,
 streaming patterns, anything that is invisible but always active.]

## File structure for new features

[The file template from section 7, condensed to the essential tree]

## Naming

[Condensed naming rules: files, classes, variables, DB fields, events — one line each]

## DO

[All DO rules from section 9, numbered — keep the file references]

## DO NOT

[All DO NOT rules from section 9, numbered — keep the file references]

## Testing

[2-3 lines: framework, location, mocking approach, minimum requirements per feature]

## API conventions

[2-3 lines: style, auth, versioning, pagination, error format, date format]

## HIGH AI-risk debt (will reproduce if not countered)

[Only debt items with AI Risk = HIGH or Critical from section 10.
 One line per item: ID + location + issue. Skip LOW and MEDIUM AI Risk items.]

## Sensitive zones (require human review)

[One line per zone: path — what to watch for. From section 11.]
```

### Cheat sheet rules

- Target 500-800 words. If the full constitution has 40 debt items, the cheat sheet
  should only include the 5-10 with HIGH or Critical AI Risk.
- Keep file path references — they're the most actionable part.
- DO and DO NOT rules should be copied verbatim from section 9, not re-summarised.
- The "Critical runtime facts" section is the highest-value section — these are the
  things that will silently break generated code. Spend the most care here.
- Do not include: the full entity map, the full endpoint inventory, the full dependency
  table, confidence metadata, or analysis gaps. Those live in the full constitution.

---

## Viewer Template

After writing the cheat sheet, generate `docs/ai/constitution-viewer.html` — a single
self-contained HTML file that renders the constitution as an interactive browsable UI.

### How it works

The viewer embeds constitution data as a JSON object inside a `<script>` tag, then
renders it with vanilla HTML/CSS/JS. No React, no build step, no external dependencies
except Google Fonts. Just open the file in a browser.

### Generation instructions

1. Read `.cursor/constitution-tmp/_merged.json` (same data source as the constitution)
2. Transform the merged data into the `CONSTITUTION_DATA` JSON structure (schema below)
3. Embed the JSON and the rendering code into a single HTML file
4. Write to `docs/ai/constitution-viewer.html`

### Data schema

Transform the merged JSON into this structure and embed it as
`const CONSTITUTION_DATA = { ... }` inside a `<script>` tag:

```javascript
{
  projectName: "Project Name",
  version: "YYYY.MM.DD",
  generated: "YYYY-MM-DD",
  confidence: "high|medium-high|medium|low",
  sections: [
    {
      id: "identity",        // unique slug for navigation
      title: "Project Identity",
      icon: "◆",             // decorative icon for sidebar
      content: "Markdown-like text content...",
      // Section-specific fields (only include what applies):
      domains: [{ name, path, desc, confidence }],           // architecture only
      dependencies: [{ pkg, ver, role, note }],               // tech stack only
      constraints: ["constraint text"],                        // tech stack only
      entities: [{ name, table, relations, note }],           // data model only
      issues: [{ severity, text }],                           // data model only
      endpoints: [{ group, needsReview?, routes: [{ method, path, auth, desc }] }],  // api only
      flows: [{ name, type, entry, steps, sideEffects, preconditions }],  // runtime only
      globalEffects: ["text"],                                // runtime only
      aiNotes: ["text"],                                      // runtime only
      fileTemplate: [{ file, purpose }],                      // conventions only
      requirements: ["text"],                                 // testing only
      doRules: ["text"],                                      // ai rules only
      dontRules: ["text"],                                    // ai rules only
      checklist: ["text"],                                    // ai rules only
      items: [{ id, domain, location, issue, severity, aiRisk, action }],  // debt only
      zones: [{ path, reason, watch }],                       // sensitive only
      confidenceMap: [{ section, level, note }],              // metadata only
      gaps: ["text"],                                         // metadata only
      warning: "Warning text to display at top of section"    // any section
    }
  ]
}
```

### Section IDs and icons

Use these exact IDs and icons for consistency:

| ID | Title | Icon |
|----|-------|------|
| identity | Project Identity | ◆ |
| architecture | Architecture Overview | ◇ |
| techstack | Tech Stack Contract | ⬡ |
| datamodel | Data Model | ◈ |
| api | API Contract | ↔ |
| runtime | Runtime Behaviour | ⟳ |
| conventions | Coding Conventions | § |
| testing | Test Strategy | ✓ |
| rules | AI Generation Rules | ⚡ |
| debt | Technical Debt | ⚠ |
| sensitive | Sensitive Zones | 🔒 |
| metadata | Analysis Metadata | ℹ |

### Visual design requirements

The viewer must have:

1. **Dark sidebar** (left, 280px) with:
   - Project name and metadata header
   - Search input that filters sections by title and content
   - Navigation list with icons, section titles, and active state highlighting
   - Footer with scan metadata

2. **Content area** (right, scrollable) with:
   - Section title with icon
   - Rendered content with appropriate visual treatment per section type:
     - Tables for structured data (entities, dependencies, endpoints, debt)
     - Color-coded badges for HTTP methods (GET=blue, POST=green, PATCH=yellow, DELETE=red)
     - Color-coded badges for confidence levels (high=green, medium=amber, low=red)
     - Color-coded badges for severity levels (HIGH=red, MEDIUM=amber, LOW=grey)
     - Warning banners (amber) for sections with warnings or [NEEDS REVIEW]
     - Split-column layout for DO/DO NOT rules (green left, red right)
     - Flow diagrams with numbered steps, side effects, and preconditions
     - File template rendered as dark code block
     - Red-bordered cards for sensitive zones

3. **Typography:** IBM Plex Sans for body, IBM Plex Mono for code/paths. Load from Google Fonts CDN.

4. **Color scheme:** Slate palette. Sidebar: slate-900. Content: slate-50. Tables: alternating slate-50/white.

### HTML structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>[Project Name] — AI Constitution Viewer</title>
  <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600;700&family=IBM+Plex+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    /* All CSS inline — no external stylesheets */
  </style>
</head>
<body>
  <div id="app">
    <nav id="sidebar"><!-- sidebar content --></nav>
    <main id="content"><!-- section content --></main>
  </div>
  <script>
    const CONSTITUTION_DATA = { /* embedded JSON */ };
    // Vanilla JS rendering code
  </script>
</body>
</html>
```

### Viewer rules

- The HTML file must be fully self-contained — no external JS, no fetch calls, no build step
- All CSS must be inline in a `<style>` tag — no external stylesheets (Google Fonts CDN is the only external resource)
- The file should work when opened directly via `file://` protocol (no server needed)
- Clicking a section in the sidebar scrolls the content area to the top and renders that section
- Search should filter sections in real-time as the user types
- The viewer is read-only — no editing capability needed
- Target file size: under 50KB for most projects (the embedded JSON is the variable part)
