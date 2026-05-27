#!/usr/bin/env bash
# install-hooks.sh — install MemForge2 repo git hooks into .git/hooks/.
#
# Idempotent: safe to run repeatedly. Re-running overwrites the destination
# with the current source. Run this in any fresh clone (or at the start of
# any new session) to make sure hooks are active.
#
# Usage:  tools/install-hooks.sh

set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
    echo "install-hooks: not inside a git repo" >&2
    exit 1
fi

HOOK_SRC_DIR="$REPO_ROOT/tools/git-hooks"
HOOK_DEST_DIR="$REPO_ROOT/.git/hooks"

if [ ! -d "$HOOK_SRC_DIR" ]; then
    echo "install-hooks: source dir '$HOOK_SRC_DIR' not found" >&2
    exit 1
fi

mkdir -p "$HOOK_DEST_DIR"

installed=0
for src in "$HOOK_SRC_DIR"/*; do
    [ -f "$src" ] || continue
    name="$(basename "$src")"
    dest="$HOOK_DEST_DIR/$name"
    cp "$src" "$dest"
    chmod +x "$dest"
    echo "  installed: $dest"
    installed=$((installed + 1))
done

if [ "$installed" -eq 0 ]; then
    echo "install-hooks: no hooks found in $HOOK_SRC_DIR" >&2
    exit 1
fi

echo "ok — $installed hook(s) installed"
