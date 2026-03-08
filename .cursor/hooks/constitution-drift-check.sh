#!/bin/bash
# constitution-drift-check.sh — Detect edits to files that affect the constitution
#
# Called by Cursor's postToolUse hook. Receives JSON via stdin with tool_name
# and tool_input fields. Outputs additional_context if the edited file matches
# a constitution-sensitive pattern.

set -e

# Read JSON from stdin
INPUT=$(cat)

# Extract the file path from tool_input (handles both Edit and Write tools)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Check if constitution exists — no point warning about drift if there's nothing to drift from
if [ ! -f "docs/ai/constitution.md" ]; then
  exit 0
fi

# Match against constitution-sensitive file patterns
SECTION=""
ANALYSTS=""

case "$FILE_PATH" in
  *schema.prisma*|*migrations/*.sql*)
    SECTION="Data Model (section 4)"
    ANALYSTS="data-model-analyst"
    ;;
  *package.json|*requirements.txt|*pyproject.toml|*Cargo.toml)
    SECTION="Tech Stack (section 3)"
    ANALYSTS="dependency-analyst"
    ;;
  *openapi.yaml|*openapi.json|*swagger.json|*swagger.yaml)
    SECTION="API Contract (section 5)"
    ANALYSTS="api-contract-analyst"
    ;;
  *routes/*.ts|*routes/*.js|*controllers/*.ts|*controllers/*.js)
    SECTION="API Contract (section 5) and Runtime Behaviour (section 6)"
    ANALYSTS="api-contract-analyst + runtime-flow-analyst"
    ;;
  *middleware/*.ts|*middleware/*.js|*interceptor*.ts|*guard*.ts)
    SECTION="Runtime Behaviour (section 6)"
    ANALYSTS="runtime-flow-analyst"
    ;;
  *)
    # Not a constitution-sensitive file
    exit 0
    ;;
esac

# Output additional_context for the agent
cat <<EOF
{
  "additional_context": "Constitution drift warning: ${FILE_PATH} was edited. This file affects the ${SECTION} section of docs/ai/constitution.md. Consider re-running: ${ANALYSTS}."
}
EOF
