---
name: audit-dev-env
description: "Audit the local dev environment: installed tools, missing binaries, broken MCP servers, redundant accounts — prioritized by impact on Claude's effectiveness."
allowed-tools:
  - Bash
  - Read
metadata:
  version: 0.0.1
  author: Alessio Caradossi
  tags:
    - environment
    - tooling
    - audit
    - mcp
    - setup
    - diagnostics
    - validation
---

# Audit Dev Environment

Inspect what's installed, missing, broken, or redundant on this machine. Prioritize findings by impact on Claude's ability to help.

## Step 1 — CLI Tools

Run in parallel:

```bash
which git gh gradle java adb python3 node npm jq rg fd bat delta brew fzf 2>&1
```

Flag as missing only tools that are relevant to the current project type (Android → `adb`, `gradle`, `java`; web → `node`, `npm`; etc.).

---

## Step 2 — GitHub Auth

```bash
gh auth status 2>&1
```

For the configured account:
- Is it authenticated?
- Is the active account correct for the current working directory?
- Are token scopes sufficient (`repo`, `workflow`, `read:org`)?

---

## Step 3 — MCP Servers

### 3a. android-emulator

```bash
npx mcp-android-emulator --version 2>&1 | head -2
adb devices 2>&1 | head -5
emulator -list-avds 2>&1 | head -5
```

Report: package reachable, ADB running, at least one AVD defined.

### 3b. JetBrains MCP

```bash
lsof -i :64342 2>/dev/null | head -3
curl -s --max-time 3 http://localhost:64342/sse 2>&1 | head -3
```

- If nothing listens: **not running** — plugin installed but IDE closed or server not started (Settings → Tools → MCP Server).
- If port open but curl blocked: use `lsof` result alone to confirm the process.
- If SSE streams: **healthy**.

### 3c. Cloud MCPs

Cloud MCPs (e.g. Browserbase, Exa, or others loaded from `remote-settings.json`) need no local binary check — report them as available if listed in the session's deferred tools.

---

## Step 4 — Plugins

### kotlin-lsp
```bash
which kotlin-lsp 2>&1
brew list | grep kotlin 2>/dev/null
```

- If binary missing: plugin `kotlin-lsp@claude-plugins-official` is enabled but non-functional.
- If Serena plugin is also enabled, kotlin-lsp is redundant — suggest disabling it.

### Other plugins
List enabled plugins from `~/.claude/settings.json`. Flag any plugin listed in `enabledPlugins` whose required binary or dependency is missing.

---

## Step 5 — Java / Android SDK

```bash
java -version 2>&1
ls ~/Library/Android/sdk/cmdline-tools/latest/bin/ 2>/dev/null | head -5
ls ~/Library/Android/sdk/emulator/emulator 2>/dev/null
```

Report JDK version (expect 17 or 21 for Android). Flag if `cmdline-tools` is absent (needed for `sdkmanager` / AVD management).

---

## Step 6 — Report

Output a prioritized table:

```
🔴 Critical (blocks work)
  - <item>: <what's wrong> → <fix>

🟡 Degraded (reduces quality)
  - <item>: <what's wrong> → <fix>

🟢 OK
  - <item>: healthy
```

**Severity rules:**
- 🔴 Critical: JetBrains MCP down (IDE open), `gh` unauthenticated, android-emulator MCP broken with active Android project.
- 🟡 Degraded: kotlin-lsp missing binary, `fzf` missing, wrong `gh` account active for the current directory.
- 🟢 OK: everything else working.

Do **not** re-check items already verified healthy in this session. Report results, don't narrate the process.
