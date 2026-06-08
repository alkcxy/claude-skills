# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A collection of personal skills for Claude Code, installed as symlinks into `~/.claude/skills/` so that a `git pull` is all that's needed to update them. No build step.

## Commands

```bash
# Install (or re-run to add newly added skills)
./install.sh

# Pull latest and link any new skills
./update.sh

# Remove only symlinks pointing to this repo
./uninstall.sh
```

Target directory resolution (mirrors Claude Code's own precedence):
1. `$CLAUDE_SKILLS_DIR` if set
2. `$CLAUDE_CONFIG_DIR/skills` if `CLAUDE_CONFIG_DIR` is set
3. `~/.claude/skills` as default

`install.sh` is idempotent and non-destructive: it skips a skill if a name collision exists (symlink pointing elsewhere, or a regular file) and exits with code 1 if any conflict was found.

## Adding a skill

1. `mkdir my-skill-name` (kebab-case, prefix `my-` by convention)
2. Create `my-skill-name/SKILL.md` with this frontmatter:

```markdown
---
name: my-skill-name
description: One sentence describing *when* this skill activates. Claude uses this to decide whether to load it.
---

# Skill title

Body in markdown.
```

3. Commit and push. On already-installed hosts, `./update.sh` picks it up automatically.

## Architecture

Each skill is a self-contained directory containing exactly one `SKILL.md`. The scripts discover skills by globbing `*/SKILL.md` — no registry or manifest. Symlinks are absolute paths so the repo can be cloned anywhere.

Claude Code loads a skill when its `description` matches the user's intent, or when called explicitly via `/<name>` or the `Skill` tool.

## Available skills

| Skill | Activates when |
|-------|---------------|
| `my-plan` | Starting a story/feature — reads issue, verifies environment, checks framework config, identifies prerequisites before touching code |
| `my-tdd` | Implementing a feature — red-green-refactor cycle, non-happy paths, cross-user auth tests, manual test plan when no automated suite exists |
| `my-review` | Closing a story/PR — manual test, branch-accurate description, workaround documentation, non-paternalistic output |
| `my-validate` | Fact-checking an argumentative text — 5-phase process: claim inventory, fact verification, evidence coherence, logical flow, steelmanning with 🟢/🟡/🔴 classification |
| `my-agentic-docs` | Setting up or auditing AI context files (`AGENTS.md`/`CLAUDE.md`) — symlink pattern, per-area scoping, drift detection, cross-account context isolation |
