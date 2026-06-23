# Lodging Shopping — Triage Quick Reference

> On-Call team: `lodgingshoppingexperienceappsescalation` · Channel: `#lodging-experience-oncall-help`
> Full guide: `ONCALL-EN.md` · Playbook: [MCShop/839106855](https://expediagroup.atlassian.net/wiki/spaces/MCShop/pages/839106855)

---

## Step 1 — Real or noise?

| Signal | Action |
|---|---|
| Datadog + Splunk + K8s all fire | **Real** — continue |
| Only Datadog fires | Wait 5 min, recheck |
| Brief spike, no Splunk errors | Likely noise — monitor |

```bash
tarmac datadog monitors get <monitor-id> -o json
tarmac datadog metrics query "sum:trace.http.request.errors{service:<svc>}.as_count()" --from -2h -o json
```

---

## Step 2 — Recent deploy?

| Check | Where |
|---|---|
| Last Spinnaker executions | [EALS](https://spinnaker.expedia.biz/#/applications/experience-api-lodging-search/executions) · [EALO](https://spinnaker.expedia.biz/#/applications/experience-api-lodging-offers/executions) · [EALP](https://spinnaker.expedia.biz/#/applications/experience-api-lodging-property/executions) · [PDEA](https://spinnaker.expedia.biz/#/applications/product-details-experience-api/executions) · [EAP](https://spinnaker.expedia.biz/#/applications/experience-api-pricing/executions) · [shopping-pwa](https://spinnaker.expedia.biz/#/applications/shopping-pwa) |
| Release tracker | [ebt-ss6-y7b](https://expediagroup.datadoghq.com/dashboard/ebt-ss6-y7b) |

```bash
tarmac spinnaker execution list <svc> --limit 10 -o json
```

> ⚠️ **Yoda config** (`dist-config-yoda-filestore`): after reverting a config change, **restart pods immediately** — cache TTL 15-30 min, do not wait (ref. INC7974877).

---

## Step 3 — Which layer?

| Symptom | Layer | Do |
|---|---|---|
| Blank page / GraphQL 400 after shared-ui bump | FE | Check [Core Web Vitals](https://expediagroup.datadoghq.com/dashboard/whj-cqg-5ux), shopping-pwa rollback |
| Core Web Vitals regress, backend healthy | FE/rendering | Check RUM, shopping-pwa deploy |
| APM errors in your span, downstream healthy | Your experience-api | Rollback your service |
| APM 502/503, slow downstream spans | Cascading | Notify downstream owner (see §Escalation) |
| Only one TnL variant affected | Gated code path | [Feature gates](https://expediagroup.datadoghq.com/dashboard/qem-2ae-wa6) → dial to control |

```bash
tarmac datadog metrics query "sum:resilience4j.circuitbreaker.state{service:<svc>} by {name,state}" --from -2h -o json
tarmac backstage metadata app get <svc> -o json   # owner, deps, tier
```

---

## Step 4 — Fix

### Rollback (default for deploy-correlated issues)

1. Spinnaker → disable pipeline (*Configure → Pipeline actions → Disable*)
2. **Start Manual Execution** on the `rollback` pipeline
3. Enter `Git Commit ID` + `helmChartVersion` from the **last successful** execution (field `version`) — not from GitHub
4. Monitor Datadog/Splunk → stable
5. Revert PR on GitHub → `READY FOR MERGE` + `JUMP THE QUEUE` → emergency approval in `#shopping-experience-api`
6. Re-enable pipeline

> Cancelling an in-progress deploy: cancel **each progressive deployment execution individually** — the parent Cancel does not revert already-updated pods.

### Forward fix
Revert PR → `READY FOR MERGE` + `JUMP THE QUEUE` → `#shopping-experience-api` approval → merge → monitor.

### TnL dial-down
[Feature gates dashboard](https://expediagroup.datadoghq.com/dashboard/qem-2ae-wa6) → EGTnL UI (`test-and-learn.expedia.com`) → move to control.

---

## Service quick links

| Service | APM | Dashboard | Splunk | Rollback |
|---|---|---|---|---|
| EALS (search → SRP) | [APM](https://expediagroup.datadoghq.com/apm/service/experience-api-lodging-search) | [DD](https://expediagroup.datadoghq.com/dashboard/868-8b5-3sm/experience-api-lodging-search) | [Splunk](https://splunk.prod.egmonitoring.expedia.com/en-US/app/bexg-lshop-experience-api-lodging-search/eals-error-monitor) | [Rollback](https://spinnaker.expedia.biz/#/applications/experience-api-lodging-search/executions?pipeline=rollback) |
| EALO (offers → PDP prices) | [APM](https://expediagroup.datadoghq.com/apm/service/experience-api-lodging-offers) | [DD](https://expediagroup.datadoghq.com/dashboard/5rx-uve-pxt/experience-api-lodging-offers) | [Splunk](https://splunk.prod.egmonitoring.expedia.com/en-US/app/bexg-lshop-experience-api-lodging-offers/ealo-error-monitor) | [Rollback](https://spinnaker.expedia.biz/#/applications/experience-api-lodging-offers/executions?pipeline=rollback) |
| EALP (property → entire PDP) | [APM](https://expediagroup.datadoghq.com/apm/service/experience-api-lodging-property) | [DD](https://expediagroup.datadoghq.com/dashboard/2kf-bqd-4az/experience-api-lodging-property) | [Splunk](https://splunk.prod.egmonitoring.expedia.com/en-US/app/bex-lshop-experience-api-lodging-property/ealp-error-monitor) | [Rollback](https://spinnaker.expedia.biz/#/applications/experience-api-lodging-property/executions?pipeline=rollback) |
| PDEA (gallery, amenities, nav) | [APM](https://expediagroup.datadoghq.com/apm/service/product-details-experience-api) | [DD](https://expediagroup.datadoghq.com/dashboard/z2a-5r2-zbm/product-details-experience-api) | [Log analysis](https://splunk.prod.egmonitoring.expedia.com/en-US/app/shopping-propexp-error-dashbord/propexp-log-analysis) | [Rollback](https://spinnaker.expedia.biz/#/applications/product-details-experience-api/executions?pipeline=rollback) |
| EAP (pricing → CKO) | [APM](https://expediagroup.datadoghq.com/apm/service/experience-api-pricing) | [DD](https://expediagroup.datadoghq.com/dashboard/zjq-r7j-jiy) | [Splunk](https://splunk.prod.egmonitoring.expedia.com/en-US/app/expediagroup-checkout-ecomm_checkout/search?earliest=-12h%40m&latest=now) | [Rollback](https://spinnaker.expedia.biz/#/applications/experience-api-pricing/executions?pipeline=Rollback) |
| PDES (pricing display) | [APM](https://expediagroup.datadoghq.com/apm/entity/service%3Aprice-display-experience-service) | [DD](https://expediagroup.datadoghq.com/dashboard/b7w-ppi-x9y/price-display-experience-service) | Splunk prod | [Rollback](https://spinnaker.expedia.biz/#/applications/price-display-experience-service/executions?pipeline=rollback) |
| shopping-pwa (FE) | — | [Core Web Vitals](https://expediagroup.datadoghq.com/dashboard/whj-cqg-5ux) | [PWA monitoring](https://pages.github.expedia.biz/Brand-Expedia/shopping-pwa/#/Prod-Monitoring,-Logging-and-Alerting) | [Spinnaker](https://spinnaker.expedia.biz/#/applications/shopping-pwa) |

---

## Escalation

```bash
tarmac datadog oncall who "lodgingshoppingexperienceappsescalation"   # who is on-call now
```

| Need | Channel |
|---|---|
| Emergency approval / incident coord | `#shopping-experience-api` |
| Downstream LSPS/LSDS (pricing) | `#offers-domain-support` |
| Downstream LSCS (content) | `#ask-eg-product-catalog-and-content` |
| Downstream Traveller API | `#ask-cko-platfom-traveler-api` |
| Pod / infra (CrashLoop, OOM) | `#ask-compute-platform` |
| NOC (infra change) | `#noc_chat` |
