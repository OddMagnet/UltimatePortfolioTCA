#!/usr/bin/env bash
set -euo pipefail

# Runs SwiftLint and SwiftFormat in lint mode, without changing any files.
# Called from the Xcode build phase, but also works when run by hand.

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS_DIR/tool-paths.sh"

PROJECT_ROOT="${SRCROOT:-$(dirname "$SCRIPTS_DIR")}"

# Both configs use paths relative to the project root, so results must not
# depend on where this script was called from.
cd "$PROJECT_ROOT"

SWIFTLINT_BIN="$(resolve_tool swiftlint)"
if [ -n "$SWIFTLINT_BIN" ]; then
    "$SWIFTLINT_BIN" lint --config "$PROJECT_ROOT/.swiftlint.yml" --quiet
else
    echo "warning: SwiftLint not installed. Run 'brew bundle' to install."
fi

SWIFTFORMAT_BIN="$(resolve_tool swiftformat)"
if [ -n "$SWIFTFORMAT_BIN" ]; then
    "$SWIFTFORMAT_BIN" --lint \
        "$PROJECT_ROOT/UltimatePortfolioTCA" \
        "$PROJECT_ROOT/UltimatePortfolioTCATests" \
        --config "$PROJECT_ROOT/.swiftformat" \
        --lenient
else
    echo "warning: SwiftFormat not installed. Run 'brew bundle' to install."
fi
