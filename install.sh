#!/usr/bin/env bash
# Symlink each skill in this repo into ~/.claude/skills/.
# Idempotent: re-running is safe and only reports changes.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

mkdir -p "$target_dir"

linked=0
skipped=0
already=0
conflicts=0

shopt -s nullglob
for skill_md in "$repo_root"/*/SKILL.md; do
    skill_dir="$(dirname "$skill_md")"
    skill_name="$(basename "$skill_dir")"
    link_path="$target_dir/$skill_name"

    if [ -L "$link_path" ]; then
        current_target="$(readlink "$link_path")"
        if [ "$current_target" = "$skill_dir" ]; then
            echo "= $skill_name (already linked)"
            already=$((already + 1))
        else
            echo "! $skill_name: symlink exists but points to $current_target — leaving untouched" >&2
            conflicts=$((conflicts + 1))
        fi
    elif [ -e "$link_path" ]; then
        echo "! $skill_name: $link_path exists and is not a symlink — leaving untouched" >&2
        conflicts=$((conflicts + 1))
    else
        ln -s "$skill_dir" "$link_path"
        echo "+ $skill_name -> $skill_dir"
        linked=$((linked + 1))
    fi
done

echo
echo "Done. linked=$linked already=$already conflicts=$conflicts"
if [ "$conflicts" -gt 0 ]; then
    echo "Some skills were not installed due to conflicts. Resolve them in $target_dir and re-run." >&2
    exit 1
fi
