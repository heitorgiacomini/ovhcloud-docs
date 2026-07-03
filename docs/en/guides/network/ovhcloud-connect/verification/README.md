{/* Internal verification index — not a published guide. Do not add to the sidebar / build. */}

# OVHcloud Connect — Verification pass (index)

Per-guide verification of the OCC revamp, classifying every substantive factual claim into three
buckets. Method: **`/fact-check` SOT-veracity** (SOT cache: `api.json`, `manager-beta.json`,
`terraform.json`, `docs.json`) **+ previous-doc comparison** (`ovhcloud-connect-old/`) **+ OCC
contract + ovhcloud.com**. One report per guide in this folder. Guides were **not** modified.

**Categories**
1. **Already present in the previous docs & verifiable**
2. **New (not in the previous docs) but verifiable** (SOT / contract / website / networking standard)
3. **New & not verifiable without testing** (needs `/walk-guide`, live Manager, live API, or PM)

## Per-guide counts

| Guide | 1. Present & verifiable | 2. New & verifiable | 3. New, needs testing | Report |
|---|---:|---:|---:|---|
| overview | 4 | 2 | 0 | [overview.md](overview.md) |
| introduction | 17 | 4 | 1 | [introduction.md](introduction.md) |
| glossary | 9 | 12 | 2 | [glossary.md](glossary.md) |
| providers | 0 | 5 | 11 | [providers.md](providers.md) |
| pop-locations-regions | 11 | 2 | 2 | [pop-locations-regions.md](pop-locations-regions.md) |
| multi-az | 3 | 7 | 2 | [multi-az.md](multi-az.md) |
| slas | 0 | 12 | 4 | [slas.md](slas.md) |
| limits | 24 | 9 | 1 | [limits.md](limits.md) |
| l3-bgp | 25 | 12 | 4 | [l3-bgp.md](l3-bgp.md) |
| l3-static | 20 | 12 | 4 | [l3-static.md](l3-static.md) |
| vrack-network-setup | 20 | 8 | 6 | [vrack-network-setup.md](vrack-network-setup.md) |
| order-direct | 3 | 10 | 2 | [order-direct.md](order-direct.md) |
| order-provider | 5 | 5 | 2 | [order-provider.md](order-provider.md) |
| cancel-direct | 3 | 4 | 4 | [cancel-direct.md](cancel-direct.md) |
| cancel-provider | 4 | 3 | 4 | [cancel-provider.md](cancel-provider.md) |
| associate-vrack | 5 | 4 | 3 | [associate-vrack.md](associate-vrack.md) |
| occ-direct-control-panel-setup | 11 | 7 | 3 | [occ-direct-control-panel-setup.md](occ-direct-control-panel-setup.md) |
| occ-provider-control-panel-setup | 11 | 4 | 4 | [occ-provider-control-panel-setup.md](occ-provider-control-panel-setup.md) |
| monitor | 9 | 10 | 3 | [monitor.md](monitor.md) |
| troubleshooting | 12 | 18 | 11 | [troubleshooting.md](troubleshooting.md) |
| incident-followup | 0 | 8 | 5 | [incident-followup.md](incident-followup.md) |
| cross-connect-loa | 4 | 7 | 5 | [cross-connect-loa.md](cross-connect-loa.md) |
| logs-forwarding | 21 | 2 | 0 | [logs-forwarding.md](logs-forwarding.md) |
| automation | 3 | 10 | 1 | [automation.md](automation.md) |
| faq | 9 | 16 | 7 | [faq.md](faq.md) |
| simple-architecture | 0 | 15 | 15 | [simple-architecture.md](simple-architecture.md) |
| resilient-architecture | 0 | 19 | 20 | [resilient-architecture.md](resilient-architecture.md) |
| **Total** | **233** | **227** | **126** | — |

## Recurring category-3 themes (what still needs live validation)

- **AWS / Azure / GCP procedures** (simple-architecture, resilient-architecture, faq) — third-party console/portal steps and provider cloud-router bridging; no OVHcloud source. Best validated with `/walk-guide` or removed if out of scope.
- **Provider-portal specifics & website order-funnel labels** (order-*, cancel-*, providers) — not in the previous docs or the manager-beta cache.
- **Live Control Panel status/state strings** (monitor, cancel-*, CP-setup guides) — e.g. service "Active"/"Pending" wording; needs the live Manager.
- **Diagnostic enum names** (`diagPeering`, `diagPeeringExtra`, `diagRoutes`, `diagMacs`) and **API response-body example schemas** (e.g. `regionType: "3-AZ"`, `available`) — the cache stores route paths only, not request/response models; needs the live API or PM.
- **Negative capability claims** (troubleshooting "unsupported features" table, IPv6-not-supported) — plausible and partly in the previous occ-limits, but the full list needs PM confirmation.

## Discrepancies flagged

- **providers** — ✅ **Resolved.** Colt (Colt Technology Services) added to the roster.
- **pop-locations-regions** — ✅ **Resolved.** The per-PoP low-latency region mapping is **factual** (confirmed by the docs owner); the "indicative / not guaranteed" hedge has been removed and these are now treated as verifiable (category 1/2).
- **/28 vs /29** — previous `occ-layer3` once states a DC minimum netmask of **/29**, while CP/API/troubleshooting (and the new guides) use **/28**. The new guides use /28 (authoritative); noting the previous-doc inconsistency for the record.
