#!/usr/bin/env bash
# Remove only the symlinks in Claude Code's skills directory that point into this repo.
# Leaves regular files and third-party symlinks untouched.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Same resolution as install.sh — see comment there.
target_dir="${CLAUDE_SKILLS_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills}"

if [ ! -d "$target_dir" ]; then
    echo "$target_dir does not exist. Nothing to do."
    exit 0
fi

removed=0
skipped=0

shopt -s nullglob
for skill_md in "$repo_root"/*/SKILL.md; do
    skill_dir="$(dirname "$skill_md")"
    skill_name="$(basename "$skill_dir")"
    link_path="$target_dir/$skill_name"

    if [ -L "$link_path" ]; then
        current_target="$(readlink "$link_path")"
        if [ "$current_target" = "$skill_dir" ]; then
            rm "$link_path"
            echo "- $skill_name"
            removed=$((removed + 1))
        else
            echo "= $skill_name: symlink points elsewhere ($current_target), skipped" >&2
            skipped=$((skipped + 1))
        fi
    elif [ -e "$link_path" ]; then
        echo "= $skill_name: not a symlink, skipped" >&2
        skipped=$((skipped + 1))
    fi
done

echo
echo "Done. removed=$removed skipped=$skipped"
