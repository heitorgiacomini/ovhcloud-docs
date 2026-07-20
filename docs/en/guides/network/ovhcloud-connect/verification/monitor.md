{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — monitor.mdx

- **Previous-doc source:** ovhcloud-connect-old/occ-diagnostics.mdx
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| L3 diagnostic **Default** = fetches BGP session state; triggered by the "Check BGP peering" action | 70 | previous occ-diagnostics L22 + instructions L42. **Live-verified (authenticated CP):** the L3 diagnostic is launched from the PoP-configuration row action menu as **"Check BGP peering"** (not the old "Diagnostic POP" segment / "BGP Peering Test" button). Guide updated. |
| L3 diagnostic **Routes** = routing table learned by OVHcloud via BGP (received from customer) | 71 | previous occ-diagnostics L23 |
| L3 diagnostic **Advertised-Routes** = routing table advertised by OVHcloud | 72 | previous occ-diagnostics L24 |
| L2 diagnostic **MAC Address** = list of MAC addresses on the L2 segment (devices/vRack) | 78 | previous occ-diagnostics L28 |
| Launch flow: "POP Configuration" panel → "Diagnostic POP" segment → ellipsis `...` → select diagnostic → "Launch diagnostic" | 82-85 | previous occ-diagnostics L42-48 |
| "Get the list of my MAC addresses" button label (L2) | 84 | previous occ-diagnostics L69 |
| Retrieve flow: "Diagnostics" tab, each entry has ID + timestamp; ellipsis → "See result" / "Download result" (.txt) | 89-91 | previous occ-diagnostics L50-55, 73-78 |
| Retention: only diagnostics from the **last seven days** are accessible; archive to keep | 97 | previous occ-diagnostics L84 |
| Rate limit: **10 diagnostics per type, per service, per 24 h**, applied independently per type | 98 | previous occ-diagnostics L86 |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| CP nav: Bare Metal Cloud → Network → OVHcloud Connect | 11 | manager-beta cache path; consistent across all new OCC guides |
| Control Panel shows connection status (link up/down) | 20 | api.json `GET /ovhCloudConnect/{serviceName}/interface/{id}/status`; previous api.mdx LightStatus |
| Control Panel shows optical IN/OUT values | 22 | previous troubleshooting "IN/OUT optical values"; api.json interface/status |
| `GET /ovhCloudConnect/{service_name}` returns service status | 39 | api.json — endpoint exists |
| `GET /ovhCloudConnect/{service_name}/config/pop` returns a **list of popIds**; per-PoP status via `.../config/pop/{popId}/status` | 43 | api.json — endpoints exist; **live-confirmed** the list endpoint returns popIds (l3-bgp session). **Fixed this pass:** the snippet previously labelled `/config/pop` as "Get PoP configuration and BGP state" (it only returns IDs) — corrected to list IDs then fetch each PoP's `/status`. |
| Diagnostics also available via `/ovhCloudConnect/{serviceName}/diagnostic/...` | 102 | api.json `GET`/`POST /ovhCloudConnect/{serviceName}/diagnostic`, `GET .../diagnostic/{id}` |
| No always-on dashboard / no bandwidth-usage dashboard / no alerting in CP | 9,25,51 | consistent with previous docs (no such feature documented) + product scope |
| Service overview panels & PoP-table statuses: **Specifications** (PoP, vRack, Bandwidth, State, Number of ports); **Link status** / **Optical statuses** (checked every 5 min) / **BGP status** | 19-23 | **Live-verified (authenticated CP):** confirmed the panel/column labels. Guide updated from "Connection status"/"Optical values"/"Service details" to the real labels. |
| BFD-driven failover / Multi-AZ failover test (best practice) | 128 | previous occ-layer3 (BFD default); authoritative facts |
| Diagnostics run in real time against OVHcloud-side equipment | 62 | previous occ-diagnostics L87 ("launched in real-time") |
| SNMP/bgpstream/exabgp/Datadog/Zabbix/PRTG/Grafana as customer-side tools | 53-56 | generic networking practice; explicitly framed as non-OVHcloud |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Python `ovh.Client(endpoint='ovh-eu')` snippet returns `service['status']` key name | 40 | Response field name not confirmed in cache (model not captured); needs live API (the `GET /ovhCloudConnect/{serviceName}` service object wasn't fetched in the live session) |
| Retrieval sub-labels "See result" / "Download result" exact casing in current CP | 91 | Present in old docs; the live Diagnostics tab was empty so the per-entry action labels could not be re-confirmed (columns confirmed: Diagnostic ID / Date / Name / Scope / Status) |

## Summary
- Category 1: 9 · Category 2: 11 · Category 3: 2
- Notes: Strong carryover of the diagnostics facts (types, retention 7 days, 10/type/service/24 h) verbatim from occ-diagnostics. New material is the API/customer-tooling framing, all verifiable via api.json. Fixed this pass: (a) the Python snippet mislabelled `GET /config/pop` as returning PoP config/BGP state — corrected to list popIds then fetch each PoP's `/status`; (b) **live CP pass** — the diagnostic launch flow was corrected to the real "Check BGP peering" PoP-row action (was old-manager "Diagnostic POP" / "BGP Peering Test"), and the CP-visibility labels were corrected to the real ones (Specifications panel; Link status / Optical statuses / BGP status). Remaining category-3: the `service['status']` response key and the exact "See result"/"Download result" casing (Diagnostics tab was empty in the live session — columns confirmed).
