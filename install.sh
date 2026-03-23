#!/bin/bash
# codesop installer — one-click setup for AI coding SOP
# Usage: curl -sSL <raw-url> | bash
# Or: bash install.sh

set -e

REPO_DIR="$HOME/codesop"

echo "=== codesop installer ==="

# 1. Clone or update repo
if [ -d "$REPO_DIR/.git" ]; then
  echo "[1/3] Repo exists, pulling latest..."
  cd "$REPO_DIR" && git pull --quiet 2>/dev/null || echo "  (no remote yet, skipping pull)"
else
  echo "[1/3] Cloning repo to $REPO_DIR..."
  git clone https://github.com/veniai/codesop.git "$REPO_DIR" --quiet
fi

# 2. Create symlinks for AGENTS.md (universal instructions)
echo "[2/3] Setting up instruction file symlinks..."

# Claude Code
mkdir -p "$HOME/.claude"
ln -sfn "$REPO_DIR/AGENTS.md" "$HOME/.claude/CLAUDE.md"
echo "  ✓ Claude Code: ~/.claude/CLAUDE.md"

# Codex
mkdir -p "$HOME/.codex"
ln -sfn "$REPO_DIR/AGENTS.md" "$HOME/.codex/AGENTS.md"
echo "  ✓ Codex: ~/.codex/AGENTS.md"

# OpenCode / OpenClaw
mkdir -p "$HOME/.config/opencode"
ln -sfn "$REPO_DIR/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
echo "  ✓ OpenCode: ~/.config/opencode/AGENTS.md"

# 3. Create symlinks for SKILL.md
echo "[3/3] Setting up skill symlinks..."

# Claude Code
mkdir -p "$HOME/.claude/skills/codesop"
ln -sfn "$REPO_DIR/SKILL.md" "$HOME/.claude/skills/codesop/SKILL.md"
echo "  ✓ Claude Code: ~/.claude/skills/codesop/SKILL.md"

# OpenClaw
mkdir -p "$HOME/.agents/skills/codesop"
ln -sfn "$REPO_DIR/SKILL.md" "$HOME/.agents/skills/codesop/SKILL.md"
echo "  ✓ OpenClaw: ~/.agents/skills/codesop/SKILL.md"

# Codex
mkdir -p "$HOME/.codex/skills/codesop"
ln -sfn "$REPO_DIR/SKILL.md" "$HOME/.codex/skills/codesop/SKILL.md"
echo "  ✓ Codex: ~/.codex/skills/codesop/SKILL.md"

echo ""
echo "=== Done! ==="
echo ""
echo "6 symlinks created. All three tools can now read:"
echo "  - AGENTS.md (universal instructions)"
echo "  - SKILL.md (complete SOP)"
echo ""
echo "To update: cd ~/codesop && git pull"
echo "To edit:   cd ~/codesop && vim SKILL.md"
