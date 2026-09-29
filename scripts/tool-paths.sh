#!/usr/bin/env bash
# Locates the code quality tools, wherever they happen to be installed.
# Sourced by scripts/pre-commit and scripts/lint.sh.
#
# Checks PATH first, which covers terminal-launched tooling, then the common
# install locations, which cover GUI-launched tooling such as Xcode: apps
# started from the Dock only inherit the PATH built by path_helper, and neither
# Homebrew nor Nix per-user profiles are guaranteed to be part of it.

resolve_tool() {
    local tool_name="$1"
    local user_name="${USER:-$(id -un)}"
    local candidate
    local search_paths=(
        "/opt/homebrew/bin/$tool_name"
        "/usr/local/bin/$tool_name"
        "/etc/profiles/per-user/$user_name/bin/$tool_name"
    )

    if command -v "$tool_name" >/dev/null 2>&1; then
        command -v "$tool_name"
        return
    fi

    for candidate in "${search_paths[@]}"; do
        if [ -x "$candidate" ]; then
            echo "$candidate"
            return
        fi
    done
}
