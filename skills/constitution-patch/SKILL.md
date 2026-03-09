---
name: constitution-patch
description: >
  Apply a manual correction to the constitution. Accepts a section reference,
  error description, and correct information. Updates full-analysis-*.md, CONSTITUTION.md,
  viewer, and logs the correction for future re-runs. Invoke with /constitution-patch
  or "correct the constitution" or "fix constitution error".
version: 2.0.0
---

# Constitution Patch — Manual Correction Skill

## Purpose

Apply a targeted correction to `docs/ai/full-analysis-*.md` (the detailed reference)
when the user identifies an inaccuracy. If the correction affects content that also
appears in `docs/ai/CONSTITUTION.md` (the compact cornerstone), update that too.
Corrections are logged so they survive full re-runs of the pipeline.

## Input

The user provides:
1. **Section reference** — which section contains the error (e.g., "section 4", "Data Model", "tech stack")
2. **Error description** — what is wrong (e.g., "says we use PostgreSQL but we use MySQL")
3. **Correct information** — what it should say instead

If the user doesn't provide all three, ask for the missing parts before proceeding.

## Steps

### 1. Read current full analysis

Find the latest `docs/ai/full-analysis-*.md`. If none exists, abort with:
"No full analysis found. Run `/constitution` first to generate one."

### 2. Locate the claim

Find the section matching the user's reference. Search for text that matches the
error description. If the exact claim can't be found, show the user the relevant
section and ask them to point to the specific text.

### 3. Apply the correction

Replace the incorrect claim with the correct information inline. Add an annotation
comment immediately after the corrected text:

```markdown
<!-- Manually corrected YYYY-MM-DD -->
```

### 4. Update CONSTITUTION.md

Read `docs/ai/CONSTITUTION.md`. If the corrected content appears in the
compact cornerstone (even in condensed form), update it there too with the same annotation.

### 5. Update viewer

Read `docs/ai/constitution-viewer.html`. Find the corresponding data in the embedded
`CONSTITUTION_DATA` JSON object and update it to reflect the correction.

### 6. Log the correction

Read `.cursor/constitution-tmp/_corrections.json` (create if it doesn't exist).
Append a new correction entry:

```json
{
  "corrections": [
    {
      "id": "corr-<NNN>",
      "timestamp": "<ISO 8601>",
      "section": "<section name>",
      "original_claim": "<what was wrong>",
      "corrected_claim": "<correct info>",
      "source": "<user-provided source or 'user correction'>",
      "applied_to": ["full-analysis-YYYY-MM-DD.md", "CONSTITUTION.md", "viewer.html"]
    }
  ]
}
```

The `id` field should increment from the last correction ID in the file (start at
`corr-001` if the file is new).

### 7. Back up corrections

Copy `_corrections.json` to `docs/ai/constitution-corrections.json` so corrections
survive `.cursor/constitution-tmp/` cleanup. This is the durable copy.

If `docs/ai/constitution-corrections.json` already exists, merge — don't overwrite.
The `_corrections.json` in tmp is always the primary; the backup is a safety copy.

### 8. Update changelog

Read `docs/ai/constitution-changelog.md` (create if it doesn't exist).

If the latest entry already has a `### Manual corrections` subsection, append to it.
Otherwise, add a new subsection:

```markdown
### Manual corrections
- [corr-<NNN>] <section>: <brief description of correction>
```

### 9. Report

Tell the user:
- What was corrected and where
- Which files were updated
- The correction ID for reference
- "This correction will be preserved on future re-runs of the constitution pipeline."

## Error handling

- Section not found: list available sections and ask user to clarify
- Claim not found in section: show section content and ask user to identify the text
- Constitution doesn't exist: direct user to run `/constitution` first
- Viewer update fails: warn but don't block — full-analysis-*.md is the primary artifact
