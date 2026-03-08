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
writes into `docs/ai/constitution.md`.

## Steps

1. List all files: `ls -la .cursor/constitution-tmp/`
   Skip `_status-*.json`, `_pipeline.json`, and `_merged.json` (if present from a previous run).

2. Read the audit report FIRST: `.cursor/constitution-tmp/audit-report.json`
   This tells you which claims to accept, flag, or exclude.

3. Read all other JSON report files in this order:
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
