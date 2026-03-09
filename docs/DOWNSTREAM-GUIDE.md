# Downstream Integration Guide

How downstream agents (spec, design, tasks, implementation, QA) should consume
the constitution outputs.

---

## Primary use (for now): preamble / guardrails

**Use the constitution as preamble in the prompt.** Paste `CONSTITUTION.md` (or the
sections that matter for the task) into the system prompt or context so the AI treats
it as guardrails: constraints, patterns, and DO/DO NOT rules it must respect.

No need for JSON lookups or section-by-section pulls unless you want them. The rest
of this guide describes optional, deeper integration when you need it.

---

## Outputs available

| File | Format | Size | Use case |
|------|--------|------|----------|
| `docs/ai/CONSTITUTION.md` | Markdown | ~600-800 words | Default context preamble for all agents |
| `docs/ai/constitution.json` | JSON | ~2-5 KB | Structured lookups (ORM? Auth? Patterns?) |
| `docs/ai/full-analysis-*.md` | Markdown | ~3000-6000 words | Deep dives when an agent needs section detail |

---

## Which output to use when

### Always load: `CONSTITUTION.md`

Every downstream agent should receive `CONSTITUTION.md` as part of its system prompt
or context preamble. It's small enough (~800 words) to fit alongside any task prompt.

```
You are a [spec/design/task/implementation/QA] agent.

Read the project constitution below. It defines the constraints, patterns,
and rules of the existing system. Your work must respect these constraints.

<constitution>
{contents of docs/ai/CONSTITUTION.md}
</constitution>
```

### Use for lookups: `constitution.json`

When an agent needs to make a specific decision based on project facts, use
`constitution.json` instead of parsing Markdown. Common lookups:

```python
# What ORM does the project use?
constitution["data_model"]["orm"]["name"]  # "Prisma"

# What auth strategy?
constitution["api"]["auth_strategy"]  # "JWT Bearer"

# What are the DO NOT rules?
constitution["rules"]["do_not"]  # ["DO NOT query DB from controllers — ...", ...]

# What test framework?
constitution["testing"]["framework"]  # "Vitest"

# Is the data model section trustworthy?
constitution["confidence"]["sections"]["data_model"]["needs_review"]  # false
```

### Use for deep dives: `full-analysis-*.md`

When a specific task requires more detail than the compact constitution provides,
pull the relevant section(s) from the full analysis. Use the section numbers as
stable references:

| Section | Pull when... |
|---------|-------------|
| 4. Data Model | Agent is designing schema changes or new entities |
| 5. API Contract | Agent is designing new endpoints or modifying existing ones |
| 6. Runtime Behaviour | Agent needs to understand middleware chain or side effects |
| 7. Infrastructure | Agent is modifying CI/CD, Docker, or deployment config |
| 8. Coding Conventions | Agent needs detailed naming/error/async rules beyond the compact version |
| 11. Technical Debt | Agent is working in a debt-heavy area and needs to know what to avoid |
| 12. Sensitive Zones | Agent is touching security-critical or fragile code |

---

## Integration patterns per downstream stage

### Spec agent (what should change)

**Context:** `CONSTITUTION.md` (full)
**Also pull:** Sections 4-5 from full analysis if the spec touches data model or API

The spec agent uses the constitution to understand:
- What already exists (so it doesn't re-spec existing features)
- What constraints exist (so the spec is feasible within current architecture)
- What's marked as technical debt (so it can reference known issues)

```
Given the constitution, write a specification for: [feature description]

The constitution defines WITHIN WHAT. Your spec defines WHAT should change.
Do not propose changes that violate the constitution's DO NOT rules.
If the feature requires violating a constraint, flag it explicitly as a
constitution exception that needs human approval.
```

**Key `constitution.json` lookups:**
- `architecture.domains` — understand domain boundaries before scoping
- `api.style` + `api.auth_strategy` — respect existing API patterns
- `rules.do_not` — know what's off-limits

---

### Design agent (how the change fits)

**Context:** `CONSTITUTION.md` (full) + spec document
**Also pull:** Sections 2, 6, 8 from full analysis

The design agent uses the constitution to:
- Place new code in the right directories (`## File Structure`)
- Follow established patterns (`## Design Patterns`)
- Respect runtime behaviour and middleware chains
- Use the correct error handling, async, and import patterns

```
Given the constitution and the following spec, design the implementation:

[spec content]

The constitution defines WITHIN WHAT. The spec defines WHAT.
Your design defines HOW the change fits within the existing system.
Follow the patterns in the constitution exactly. If the spec requires
a new pattern, justify it explicitly.
```

**Key `constitution.json` lookups:**
- `design_patterns` — which patterns to follow
- `file_structure.new_feature_template` — where to put new files
- `naming` — exact naming conventions per category
- `code_rules` — error handling, async, imports

---

### Task decomposition agent (breaking design into tasks)

**Context:** `CONSTITUTION.md` (compact) + design document
**Also pull:** Section 9 (Test Strategy) from full analysis

The task agent uses the constitution to:
- Ensure each task follows the file structure convention
- Include testing requirements per task (from `## Testing`)
- Flag tasks that touch sensitive zones
- Order tasks to respect domain boundaries

```
Given the constitution and the following design, decompose into
implementation tasks:

[design content]

Each task must:
1. Specify which files to create/modify (following ## File Structure)
2. Include test requirements (following ## Testing)
3. Reference specific DO/DO NOT rules that apply to that task
4. Flag if it touches a sensitive zone from the constitution
```

**Key `constitution.json` lookups:**
- `file_structure` — file placement per task
- `testing.required_types` — what tests each task needs
- `sensitive_zones` — flag tasks in sensitive areas
- `confidence.sections` — warn if working in low-confidence areas

---

### Implementation agent (writing code)

**Context:** `CONSTITUTION.md` (full) + task description
**Also pull:** Section 8 (Coding Conventions) from full analysis if writing non-trivial code

The implementation agent uses the constitution as its primary style guide:
- `## DO` and `## DO NOT` are the most critical sections — check every generated
  file against these rules
- `## Naming` governs every identifier
- `## Code Rules` governs every function body
- `## Design Patterns` governs every architectural decision

```
Given the constitution and the following task, write the implementation:

[task content]

Before writing any code, check:
1. Does my file placement match ## File Structure?
2. Does my naming match ## Naming?
3. Does my error handling match ## Code Rules?
4. Am I following every applicable rule in ## DO?
5. Am I violating any rule in ## DO NOT?
```

**Key `constitution.json` lookups:**
- `rules.do` + `rules.do_not` — validate every file
- `naming` — validate every identifier
- `code_rules.error_handling` — validate error patterns
- `testing.framework` + `testing.mocking` — write correct tests

---

### QA / Review agent (validating implementation)

**Context:** `CONSTITUTION.md` (full) + implementation diff
**Also pull:** Sections 9, 11, 12 from full analysis

The QA agent uses the constitution as a review checklist:
- Does the implementation follow `## DO` rules?
- Does it violate any `## DO NOT` rules?
- Are tests present and following `## Testing` conventions?
- Does it touch sensitive zones without human review flagged?
- Does it introduce or worsen technical debt?

```
Given the constitution and the following code changes, review for
constitution compliance:

[diff content]

Check each change against:
1. Every rule in ## DO and ## DO NOT
2. Naming conventions in ## Naming
3. Pattern compliance with ## Design Patterns
4. Test coverage per ## Testing requirements
5. Sensitive zone proximity per full analysis section 12
```

**Key `constitution.json` lookups:**
- `rules.do` + `rules.do_not` — primary checklist
- `sensitive_zones` — flag changes near sensitive areas
- `confidence.sections` — note if review area has low confidence

---

## Handling low-confidence sections

When `constitution.json` reports `needs_review: true` for a section, downstream
agents should:

1. **Not treat that section as authoritative** — use it as a hint, not a rule
2. **Flag it in their output** — "Note: the constitution's data model section is
   marked [NEEDS REVIEW]. The following design decisions should be validated by
   a human before implementation."
3. **Prefer conservative choices** — when in doubt, don't introduce new patterns
   in uncertain areas

---

## Keeping downstream agents in sync

When the constitution is re-generated (via `/constitution`), all downstream
artifacts that were produced from the previous constitution should be reviewed.

Downstream agents should check the `baseline_date` field in `constitution.json`
and warn if their source constitution is older than the current one:

```python
if task_constitution_date < current_constitution["baseline_date"]:
    warn("This task was designed against an older constitution baseline. "
         "Review for compatibility with the current constitution.")
```
