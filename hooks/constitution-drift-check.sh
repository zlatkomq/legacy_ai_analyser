#!/usr/bin/env bash
# constitution-drift-check.sh — Detect edits to files that affect the constitution
#
# Called by Cursor's postToolUse hook. Receives JSON via stdin with tool_name
# and tool_input fields. Outputs additional_context if the edited file matches
# a constitution-sensitive pattern.

set -euo pipefail

# Read JSON from stdin
INPUT="$(cat || true)"

if [ -z "$INPUT" ]; then
  exit 0
fi

# Extract file_path safely from known hook payload shapes.
FILE_PATH=""
if command -v jq >/dev/null 2>&1; then
  FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null || true)"
elif command -v python3 >/dev/null 2>&1; then
  FILE_PATH="$(
    printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    payload = json.load(sys.stdin)
except Exception:
    print("")
    raise SystemExit(0)

tool_input = payload.get("tool_input", {})
value = tool_input.get("file_path") or payload.get("file_path") or ""
print(value)
' 2>/dev/null || true
  )"
fi

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
  *Dockerfile*|*docker-compose*|*.tf|*serverless.yml|*fly.toml|*vercel.json|*netlify.toml|*Procfile)
    SECTION="Infrastructure & Deployment (section 7)"
    ANALYSTS="infra-analyst"
    ;;
  *.github/workflows/*|*.gitlab-ci.yml|*Jenkinsfile|*.circleci/*)
    SECTION="Infrastructure & Deployment (section 7)"
    ANALYSTS="infra-analyst"
    ;;
  *)
    # Not a constitution-sensitive file
    exit 0
    ;;
esac

# Output additional_context for the agent
cat <<EOF
{
  "additional_context": "Constitution drift warning: ${FILE_PATH} was edited. This file affects the ${SECTION} section of docs/ai/constitution.md. Consider re-running: ${ANALYSTS}. Use /constitution-incremental for a targeted update."
}
EOF
