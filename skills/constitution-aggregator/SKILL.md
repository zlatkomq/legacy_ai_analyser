---
name: constitution-aggregator
description: >
  Merges all partial JSON and MD reports from .cursor/constitution-tmp/ into a
  single coherent intermediate representation, applying audit findings to flag
  uncertain content. Invoke after auditor completes.
version: 2.1.0
---

# Constitution Aggregator

## Purpose

Merge all scan reports into one verified intermediate structure that the curator
uses to produce `docs/ai/full-analysis-YYYY-MM-DD.md` and `docs/ai/CONSTITUTION.md`.

## Steps

1. List all files: `ls -la .cursor/constitution-tmp/`
   Skip `_status-*.json`, `_pipeline.json`, and `_merged.json` (if present from a previous run).

2. Read the audit report FIRST: `.cursor/constitution-tmp/audit-report.json`
   This tells you which claims to accept, flag, or exclude.

2.5. Read `_corrections.json` if it exists (check both `.cursor/constitution-tmp/_corrections.json`
   and `docs/ai/constitution-corrections.json` as fallback). For each correction:
   - Find the matching claim in the agent reports by section and original_claim text
   - Override that claim with the corrected_claim value
   - If original_claim no longer matches any agent report content, flag it as a stale
     correction in the merged output under `"stale_corrections": [...]`
   - Report stale correction count to the user so they can review

3. Read all other JSON report files in this order:
   - dependencies.json (tech stack — sets the frame)
   - patterns.json (architecture — shapes everything else)
   - data-model.json
   - api-contracts.json
   - runtime-flow.json
   - infra.json (infrastructure and deployment — if present)
   - domain-*.json (all domain scanner outputs — if a domain report has a `packages`
     array, unpack each package as a separate domain entry in the merged structure)

4. Build merged structure covering:
   - System identity (name, type, language, runtime, framework)
   - Architecture narrative (from patterns + domains)
   - Tech stack contract (from dependencies)
   - Data model (from data-model + cross-checked against domains)
   - API surface (from api-contracts + cross-checked against runtime-flow)
   - Runtime behaviour (from runtime-flow — this is the unique section static tools miss)
   - Infrastructure & Deployment (from infra — deployment targets, CI/CD, containerisation, env vars, topology)
   - Cross-domain concerns (auth, error handling, logging, events)
   - AI generation rules (derived from patterns — DO and DO NOT lists)
   - Technical debt register (all issues from all reports, deduplicated, sorted by severity)
   - Sensitive zones (security-relevant files, fragile areas, AI caution zones)

4.5. For every major constitution section in the merged structure, include section metadata:
   - `confidence`: section-level confidence (`high|medium|low`)
   - `confidence_reason`: why that confidence level was assigned
   - `evidence_files`: the most relevant source files or manifests that support the section
   - `unresolved_gaps`: what is still inferred, missing, or weakly evidenced
   - `downstream_use`: how downstream spec/design/tasks/dev/QA steps should use the section
   Keep these grounded in agent evidence (`files_read_list`, report contents, and audit findings),
   not generic filler text.

5. For every item marked in `sections_to_flag_in_constitution` in the audit report:
   annotate the merged structure with `"confidence": "low"` and `"needs_human_review": true`,
   while preserving the `evidence_files` and `unresolved_gaps` that explain why review is needed

6. Write merged output to `.cursor/constitution-tmp/_merged.json`

7. Report: "Aggregation complete: <domain count> domains, <endpoint count> endpoints,
   <issue count> debt items, <flagged count> sections flagged for review."
