---
name: constitution-curator
description: >
  Reads .cursor/constitution-tmp/_merged.json and writes the final outputs:
  docs/ai/full-analysis-YYYY-MM-DD.md (detailed reference),
  docs/ai/CONSTITUTION.md (compact cornerstone for downstream agents),
  docs/ai/constitution-viewer.html (interactive viewer from full analysis).
  Invoke after aggregation completes.
version: 3.0.0
---

# Constitution Curator

## Purpose

Produce three artifacts from the merged, audited intermediate data:

1. **`docs/ai/full-analysis-YYYY-MM-DD.md`** — the detailed 13-section reference
   document. Used by the viewer and for human browsing. Can be re-generated
   periodically. Replaces the previous `docs/ai/constitution.md`.
2. **`docs/ai/CONSTITUTION.md`** — the compact, fixed cornerstone (~600-800 words)
   passed to every downstream agent (spec, design, tasks, code, review, QA).
   This is the primary output. Replaces the previous `docs/ai/constitution-cheatsheet.md`.
3. **`docs/ai/constitution-viewer.html`** — self-contained interactive viewer
   fed from the full analysis data.

## Steps

1. Read `.cursor/constitution-tmp/_merged.json`
2. Also read all `docs/ai/constitution-fragments/*.md` for narrative context
3. Write `docs/ai/full-analysis-YYYY-MM-DD.md` following the Full Analysis Template below
   - Use today's date in the filename and as the version
   - Include all 13 sections with confidence, evidence, and downstream-use metadata
   - For any section with `needs_human_review: true`: add a visible warning block
4. Write `docs/ai/CONSTITUTION.md` following the CONSTITUTION Template below
   - This is the compact cornerstone: ~600-800 words, 10 sections
   - Reference the full analysis baseline date
   - DO and DO NOT rules are the most critical part — be specific and file-referenced
5. Generate `docs/ai/constitution-viewer.html` (see Viewer Template below)
   - Fed from the full analysis data, not the compact CONSTITUTION
6. Report: "Full analysis written — <section count> sections, ~<word count> words.
   CONSTITUTION.md written — ~<word count> words. Viewer generated."

## CONSTITUTION Template (compact cornerstone)

This is the primary downstream artifact. Keep it under 800 words. Every downstream
agent (spec, design, tasks, code, review, QA) receives this as context.

```markdown
# [Project Name] — CONSTITUTION

> **Baseline:** YYYY-MM-DD
> **Role:** Fixed cornerstone for all downstream agents (spec, design, tasks, code, review, QA).
> The spec defines WHAT. The design defines HOW. This document defines WITHIN WHAT.

## System

[1-2 lines: name, stack (framework + language + runtime), what it does, package manager, module format]

## Architecture

[2-3 lines: architectural style, layers, domains, cross-domain communication pattern]

## Tech Stack

[Table of key dependencies with version and role — only the ones that matter for generation]
[1 line: forbidden additions / hard constraints]

## Design Patterns

[5-6 bullet points: the established patterns that all new code must follow.
 E.g. "API module per domain", "Hook per domain wrapping API", "Central HTTP client",
 "SSE via ReadableStream", "Response normalization at API boundary", etc.]

## File Structure

[Code block showing where new features go:
 src/api/<domain>.ts, src/hooks/use<Domain>.ts, src/components/<Name>.tsx, etc.]

## Naming

[4-5 lines: file naming, variable/function naming, component/type naming,
 hook naming, constant naming, API-backed field naming]

## Code Rules

[4-5 lines: error handling pattern, async pattern, import rules, state management, AbortSignal]

## Testing

[3-4 lines: framework, location, mocking approach, coverage target, known gaps]

## DO

[6-10 numbered items, file-referenced, actionable]

## DO NOT

[5-10 numbered items, file-referenced, actionable.
 Fold in key HIGH AI-risk debt items and sensitive zone warnings here.]
```

### CONSTITUTION rules

- Target 600-800 words maximum
- DO and DO NOT rules must be specific and file-referenced — these are the highest-value content
- Fold HIGH AI-risk debt items into DO NOT (don't keep a separate debt section)
- Fold sensitive zone warnings into DO NOT where relevant
- Do NOT include: endpoint inventories, entity maps, runtime flow traces, infrastructure
  details, analysis metadata, confidence tables, or changelog. Those live in the full analysis.
- Do NOT include section-level confidence/evidence/downstream-use metadata blocks.
  The compact constitution is a rules document, not an audit report.

## Full Analysis Template

Use the same 13-section template as version 2.1.0 of the curator (sections 1-13:
Project Identity, Architecture Overview, Tech Stack Contract, Data Model, API Contract,
Runtime Behaviour, Infrastructure & Deployment, Coding Conventions, Test Strategy,
AI Generation Rules, Technical Debt Register, Sensitive Zones, Analysis Metadata).

Include per-section confidence, evidence sources, and downstream-use metadata.
Include [NEEDS REVIEW] warning blocks where flagged.

The full analysis filename includes the date: `docs/ai/full-analysis-YYYY-MM-DD.md`.

## Viewer Template

Generate `docs/ai/constitution-viewer.html` — a single self-contained HTML file that
renders the **full analysis** as an interactive browsable UI. The viewer is fed from
the full analysis data (not the compact CONSTITUTION).

### Generation instructions

1. Read `.cursor/constitution-tmp/_merged.json` (same data source as the full analysis)
2. Transform the merged data into the `CONSTITUTION_DATA` JSON structure
3. Embed the JSON and the rendering code into a single HTML file
4. Write to `docs/ai/constitution-viewer.html`

### Section IDs and icons

| ID | Title | Icon |
|----|-------|------|
| identity | Project Identity | ◆ |
| architecture | Architecture Overview | ◇ |
| techstack | Tech Stack Contract | ⬡ |
| datamodel | Data Model | ◈ |
| api | API Contract | ↔ |
| runtime | Runtime Behaviour | ⟳ |
| infra | Infrastructure & Deployment | ⛭ |
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
   - Tables for structured data (entities, dependencies, endpoints, debt)
   - Color-coded badges for HTTP methods, confidence levels, severity levels
   - Warning banners for [NEEDS REVIEW] sections
   - Split-column layout for DO/DO NOT rules
   - File template rendered as dark code block
   - Red-bordered cards for sensitive zones

3. **Typography:** IBM Plex Sans for body, IBM Plex Mono for code/paths (Google Fonts CDN)
4. **Color scheme:** Slate palette. Sidebar: slate-900. Content: slate-50.

### Viewer rules

- Fully self-contained — no external JS, no fetch calls, no build step
- All CSS inline in `<style>` tag (Google Fonts CDN is the only external resource)
- Works when opened via `file://` protocol
- Clicking a section in the sidebar renders that section
- Search filters sections in real-time
- Read-only — no editing capability
- Target file size: under 50KB
