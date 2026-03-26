#!/bin/bash
# codesop installer — one-click setup for AI coding SOP
# Usage: curl -sSL <raw-url> | bash
# Or: bash install.sh

set -euo pipefail

REPO_DIR="$HOME/codesop"

echo "=== codesop installer ==="

# 1. Clone or update repo
if [ -d "$REPO_DIR/.git" ]; then
  echo "[1/2] Repo exists, pulling latest..."
  cd "$REPO_DIR" && git pull --quiet 2>/dev/null || echo "  (no remote yet, skipping pull)"
else
  echo "[1/2] Cloning repo to $REPO_DIR..."
  git clone https://github.com/veniai/codesop.git "$REPO_DIR" --quiet
fi

echo "[2/2] Running host-aware setup..."
bash "$REPO_DIR/setup" --host auto

echo ""
echo "=== Done! ==="
echo ""
echo "codesop is installed with a single source repo and host-specific runtimes."
echo "  - AGENTS.md (universal instructions)"
echo "  - Host-specific skill runtimes"
echo "  - agents/openai.yaml (Codex agent config)"
echo "  - codesop (CLI entrypoint)"
echo ""
echo "To update: codesop update"
echo "To resync after local edits: codesop setup auto"
