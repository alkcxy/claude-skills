---
name: my-oncall-triage
description: >-
  Use when an on-call alert arrives (PagerDuty, Datadog, Slack) for the Lodging Shopping Experience
  rotation. Accepts a Datadog monitor URL/ID or free-text alert description. Verifies tarmac
  auth, fetches the monitor details, then runs structured triage: Datadog (real or noise) →
  Splunk (error chain) → Spinnaker (deploy correlation if needed). Produces a triage report.
---

# On-Call Alert Triage — Lodging Shopping Experience

For the **Lodging Shopping Experience Apps Escalation** rotation
(`lodgingshoppingexperienceappsescalation`). Accepts any alert format (Datadog monitor URL, Slack notification, free text) and produces
a structured triage report.

Reference doc: `<base_dir>/../docs/TRIAGE-QUICK.md` — service quick links,
rollback steps, escalation contacts. Read it explicitly when needed (see Step 5b).

---

## Step 0 — Verify tarmac authentication

Run all five checks in parallel before any query:

```bash
tarmac auth status --output json 2>&1
tarmac datadog auth status --output json 2>&1
tarmac splunk auth status --output json 2>&1
tarmac backstage auth status --output json 2>&1
tarmac spinnaker auth status --output json 2>&1
```

For each unauthenticated service, show the exact login command to run in a separate terminal:

| Service | Login command |
|---|---|
| Okta (global) | `tarmac auth login --device` |
| Datadog | `tarmac datadog auth login` |
| Splunk | `tarmac splunk auth login --manual --env prod` |
| Backstage | `tarmac backstage auth login` |
| Spinnaker | `tarmac spinnaker auth login --manual` |

> **Splunk**: the `--manual` flag bypasses the Mac Keychain prompt. Without it, the interactive
> flow tries to write to the system keyring and triggers macOS dialogs that block the terminal.

Wait for user confirmation for each missing service before proceeding. Do not skip this step —
queries fail silently when tokens are expired.

Spinnaker unauthenticated is **non-blocking**: only needed if Step 4 reveals a deploy correlation.
Datadog and Splunk are blocking.

---

## Step 1 — Parse the alert input

The skill accepts any of these as input:
- Datadog monitor URL: `https://expediagroup.datadoghq.com/monitors/12345`
- Datadog monitor ID (bare number): `12345`
- Slack notification (free text containing a monitor URL or service name)
- Free text describing the alert

**If the input contains a Datadog monitor URL or ID**, extract the ID and fetch the monitor
immediately — this gives you the service name, alert condition, threshold, and current state
before any other query:

```bash
tarmac datadog monitors get <monitor-id> -o json
```

From the monitor response, extract:
- `query` or `tags` → **service name** (look for `service:<name>` tag)
- `overall_state` → current state (Alert / Warn / OK / No Data)
- `message` → runbook link or escalation contact if present

If the input is free text with no monitor ID, ask the user for the Datadog monitor URL or
service name before proceeding.

---

## Step 2 — Datadog: real or noise?

Run in parallel:

```bash
# Monitor details (if you have the ID)
tarmac datadog monitors get <monitor-id> -o json

# Error rate last 2h — use positive duration (NOT -2h, it inverts timestamps)
tarmac datadog metrics query \
  "sum:trace.http.request.errors{service:<svc>}.as_count()" \
  --from 2h -o json

# p99 latency
tarmac datadog metrics query \
  "avg:trace.http.request.duration.by.service.99p{service:<svc>}" \
  --from 2h -o json

# Pod restarts
tarmac datadog metrics query \
  "sum:kubernetes.containers.restarts{kube_deployment:<svc>}" \
  --from 2h -o json
```

> **tarmac known behaviour**: `--from` expects a positive duration (`2h`, `30m`, `1d`) — NOT a
> negative value like `-2h`, which inverts `from_date`/`to_date` and returns an empty series.
> If a query returns `{"status":"error","series":[]}`, check that `from_date < to_date` in the
> response. If Datadog is unavailable, document the failure in the report and use Splunk as the
> primary signal.

**Real vs noise verdict:**

| Pattern | Verdict |
|---|---|
| Sustained error rate + high latency + pod restarts | **Real** — continue |
| Isolated spike < 2 min, then recovered | Likely noise — monitor for 5 min |
| Error rate only, latency ok, no restarts | Possible noise — check Splunk before deciding |

If noise confirmed: close with a note and stop.

---

## Step 3 — Splunk: error chain

### 3a. Resolve the correct index

Do not assume the index — look it up via Backstage first:

```bash
tarmac backstage catalog get <svc> -o json
```

Look for logging annotations (`splunkIndex`, `monitoring`, or `backstage.io/*` annotations).
If not found, use cross-index discovery:

```bash
tarmac splunk search query \
  'index=* splunk_server_group=rcp sourcetype="kube:container:<svc>" | stats count by index | sort -count | head 5' \
  --env prod --earliest -30m -o json
```

Update `search-splunk-config.json` memory with the discovered index.

### 3b. Top errors

```bash
tarmac splunk search query \
  'index="<index>" splunk_server_group=rcp sourcetype="kube:container:<svc>" level=ERROR \
   | stats count by message | sort -count | head 20' \
  --env prod --earliest -2h -o json
```

### 3c. Trace the upstream chain

If errors point to downstream calls (4xx/5xx status codes, timeouts, circuit breakers):

```bash
# Identify the downstream involved
tarmac splunk search query \
  'index="<index>" splunk_server_group=rcp sourcetype="kube:container:<svc>" \
   (statusCode=400 OR statusCode=503 OR "circuit breaker" OR "CallNotPermittedException" \
    OR "ReadTimeoutException") \
   | stats count by operationName | sort -count | head 10' \
  --env prod --earliest -2h -o json

# Timeline to establish when it started
tarmac splunk search query \
  'index="<index>" splunk_server_group=rcp sourcetype="kube:container:<svc>" level=ERROR \
   | timechart span=10m count' \
  --env prod --earliest -4h -o json
```

**Signals that point to a downstream problem (not ours):**
- `CallNotPermittedException` / circuit breaker OPEN or HALF_OPEN → downstream is failing
- `ReadTimeoutException` on an external host → timeout toward external service
- `statusCode=400` on a LocalExpert URL (`.localexpert.expedia.com`) → API contract change

If downstream, identify the owner:
```bash
tarmac backstage catalog get <downstream-service> -o json
```

---

## Step 4 — Spinnaker: deploy correlation

Run only if:
- Errors started abruptly (not gradually)
- The Splunk timeline shows a sharp spike at a time consistent with a deploy

```bash
tarmac spinnaker execution list <svc> --limit 10 -o json
```

Compare the last deploy timestamp with the error spike start (from Step 3b timeline).

> ⚠️ **Yoda config** (`dist-config-yoda-filestore`): if the spike is post-config-change and you
> see `RuntimeConfigException` / `UnknownSystemEvent`, **restart pods immediately** after reverting
> — do not wait for the cache TTL of 15–30 min (ref. INC7974877).

---

## Step 5 — Synthesis and recommendation

### 5a. Re-read the incident channel before synthesising

**Mandatory.** Before writing anything, fetch recent updates from the incident channel:

```
mcp__slack-mcp__search-slack("in:<inc-channel-name> incupdate", count=20)
```

Extract:
- Actions taken (rollback, restart, DB fix, vault key revert, redeploy)
- Who executed them and at what time
- Whether a formal restore was declared

Use this in the **Recovery** field of the report. Never write "spontaneous recovery" without
verifying there were no explicit actions in the channel — there almost always is one.

### 5b. Look up service quick links

Read `<base_dir>/../docs/TRIAGE-QUICK.md` and extract the row matching the
affected service. Use the per-service APM, Dashboard, Splunk, and Rollback links in the report.
If the rollback action is recommended, also read the rollback procedure from that file.

### 5c. Produce the structured report

```
## Triage — <service> — <date/time UTC>

**Verdict:** Real / Noise / Under investigation

**User impact:** [what the user sees]

**Root cause hypothesis:**
- [hypothesis 1, with evidence from Datadog/Splunk]
- [hypothesis 2 if ambiguous]

**Layer:** Our service / Downstream / FE

**Deploy correlated:** Yes (SHA: xxx, deployed at HH:MM UTC) / No

**Recovery:** [actions taken by whom at what time, from incident channel]

**Recommended action:**
- [ ] Rollback (Spinnaker pipeline `rollback`, use helmChartVersion from last successful execution)
- [ ] Forward fix (revert PR → READY FOR MERGE + JUMP THE QUEUE → #shopping-experience-api)
- [ ] TnL dial-down (Feature gates dashboard → EGTnL → move to control)
- [ ] Escalate downstream → [team/channel]
- [ ] Monitor (noise)

**Quick links:**
- APM: https://expediagroup.datadoghq.com/apm/service/<svc>
- Spinnaker rollback: https://spinnaker.expedia.biz/#/applications/<svc>/executions?pipeline=rollback
```

After the report, ask the user whether to proceed with the recommended action or explore alternatives.

---

## Quick escalation

```bash
tarmac datadog oncall who "lodgingshoppingexperienceappsescalation"
```

| Need | Channel |
|---|---|
| Emergency approval / incident coordination | `#shopping-experience-api` |
| Downstream LSPS/LSDS (pricing) | `#offers-domain-support` |
| Downstream LSCS (content) | `#ask-eg-product-catalog-and-content` |
| Pod / infra (CrashLoop, OOM) | `#ask-compute-platform` |
| NOC (infra change) | `#noc_chat` |
