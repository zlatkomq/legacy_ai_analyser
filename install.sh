#!/bin/bash
# install.sh — Install the Constitution Generator into your project
#
# Usage:
#   cd /path/to/your/project
#   bash /path/to/constitution-kit/install.sh
#
# Or copy the constitution-kit folder next to your project and run:
#   bash ../constitution-kit/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Cursor Constitution Generator — Installer ==="
echo ""
echo "Installing into: $(pwd)"
echo ""

# 1. Create directory structure
echo "[1/6] Creating directories..."
mkdir -p .cursor/agents
mkdir -p .cursor/skills/constitution
mkdir -p .cursor/skills/constitution-aggregator
mkdir -p .cursor/skills/constitution-curator
mkdir -p .cursor/rules
mkdir -p .cursor/hooks
mkdir -p .cursor/constitution-tmp
mkdir -p docs/ai/constitution-fragments

# 2. Copy .cursorignore (don't overwrite if exists)
echo "[2/6] Setting up .cursorignore..."
if [ -f .cursorignore ]; then
  echo "  ⚠️  .cursorignore already exists — skipping (review it manually)"
else
  cp "$SCRIPT_DIR/.cursorignore" .cursorignore
  echo "  ✓ Created .cursorignore"
fi

# 3. Copy agents
echo "[3/6] Installing subagents..."
cp "$SCRIPT_DIR/.cursor/agents/"*.md .cursor/agents/
echo "  ✓ 7 agents installed"

# 4. Copy skills
echo "[4/6] Installing skills..."
cp "$SCRIPT_DIR/.cursor/skills/constitution/SKILL.md" .cursor/skills/constitution/SKILL.md
cp "$SCRIPT_DIR/.cursor/skills/constitution-aggregator/SKILL.md" .cursor/skills/constitution-aggregator/SKILL.md
cp "$SCRIPT_DIR/.cursor/skills/constitution-curator/SKILL.md" .cursor/skills/constitution-curator/SKILL.md
echo "  ✓ 3 skills installed"

# 5. Copy rules and hooks
echo "[5/6] Installing rules and hooks..."
cp "$SCRIPT_DIR/.cursor/rules/"*.mdc .cursor/rules/
# Cursor hooks: hooks.json must live at .cursor/hooks.json (not in a subdirectory)
if [ -f .cursor/hooks.json ]; then
  echo "  ⚠️  .cursor/hooks.json already exists — merging manually may be needed"
  echo "      See $SCRIPT_DIR/.cursor/hooks/constitution-drift.json for the hook config to merge"
else
  cp "$SCRIPT_DIR/.cursor/hooks/constitution-drift.json" .cursor/hooks.json
  echo "  ✓ Created .cursor/hooks.json"
fi
cp "$SCRIPT_DIR/.cursor/hooks/constitution-drift-check.sh" .cursor/hooks/
chmod +x .cursor/hooks/constitution-drift-check.sh
echo "  ✓ 2 rules + 1 hook (with drift detection script) installed"

# 6. Set up tmp gitignore
echo "[6/6] Finalising..."
echo '*' > .cursor/constitution-tmp/.gitignore
echo '!.gitignore' >> .cursor/constitution-tmp/.gitignore

echo ""
echo "=== Installation complete ==="
echo ""
echo "Files installed:"
echo "  .cursorignore"
echo "  .cursor/agents/           (7 subagent definitions)"
echo "  .cursor/skills/           (3 skill definitions)"
echo "  .cursor/rules/            (2 rule files)"
echo "  .cursor/hooks.json        (Cursor hooks config — drift detection)"
echo "  .cursor/hooks/            (hook scripts)"
echo "  .cursor/constitution-tmp/ (scratch space, gitignored)"
echo "  docs/ai/                  (output directory)"
echo ""
echo "Next steps:"
echo "  1. Open this project in Cursor"
echo "  2. Review .cursorignore — adjust for your project's specifics"
echo "  3. In Cursor agent chat, type:"
echo "     Generate a constitution for this codebase"
echo ""
echo "Optional: Install git pre-commit hook for drift detection:"
echo "  cp $SCRIPT_DIR/pre-commit-hook.sh .git/hooks/pre-commit"
echo "  chmod +x .git/hooks/pre-commit"
