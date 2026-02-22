#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
ln -sf "../../scripts/pre-commit" "$REPO_ROOT/.git/hooks/pre-commit"
chmod +x "$REPO_ROOT/scripts/pre-commit"
chmod +x "$REPO_ROOT/scripts/git-format-staged"
echo "Pre-commit hook installed."
