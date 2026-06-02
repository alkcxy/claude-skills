#!/usr/bin/env bash
# Pull latest changes and re-run install.sh to link any new skills.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

if [ -n "$(git status --porcelain)" ]; then
    echo "Working tree has local changes. Commit or stash before updating." >&2
    git status --short >&2
    exit 1
fi

current_branch="$(git rev-parse --abbrev-ref HEAD)"
echo "Updating $current_branch..."
git pull --ff-only

echo
"$repo_root/install.sh"
