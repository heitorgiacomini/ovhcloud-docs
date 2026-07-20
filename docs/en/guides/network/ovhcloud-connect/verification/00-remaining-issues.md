{/* Internal verification ledger — not a published guide. Do not add to the sidebar / build. */}

# OVHcloud Connect — Remaining unverified claims (ledger)

Running list of **category-3** claims (new & not verifiable from the previous docs / SOT / contract / website) that are still open after the per-guide verification pass. Fully-resolved items (corrected or removed this pass) are **not** listed here — see each guide's report for those.

**Coverage:** **all 28 guides + cross-connect-loa reviewed (complete).** Large third-party sets (providers, resilient/simple-architecture cloud tabs) are grouped rather than listed row-by-row — see each guide's report for the itemised list.

**Type key:**
- **live-CP/API** — closable now with the authenticated Manager / API (read-only) we have access to
- **live-mutate** — would require mutating the shared OVHcloud test backend (a techwriter must not) — leave to PM/dev
- **PM** — needs product/PM confirmation (wording, onboarding, process)
- **third-party** — out of OVHcloud's scope (provider portal, other clouds)
- **operational** — illustrative/environment-specific example output; correctness needs a live run

| # | Related guide | Unverified claim | Type | How to close |
|---|---|---|---|---|
| 1 | cancel-provider | Cancel the virtual circuit / connection in the provider's portal | third-party | Provider's own documentation; out of OVHcloud scope |
| 2 | cancel-provider | Provider terms (minimum commitment, notice periods, early-termination fees) | third-party | Provider contract; out of OVHcloud scope |
| 3 | faq | Reaching AWS/Azure/GCP is out of scope, handled by third-party providers | third-party | Correct scoping statement; the linked procedures are third-party |
| 4 | faq | Links to AWS/Azure/GCP "resilient" tutorials | third-party | Depends on resilient-architecture third-party procedures |
| 5 | faq / incident-followup | Support-ticket flow — exact in-portal category labels | live-CP | Help Centre confirmed as entry point (linked from dashboard); the ServiceNow ticket portal crashes under automation, so exact labels need a manual check |
| 6 | faq | Bandwidth-change "plan during a maintenance window" | operational | Operational advice; no OVHcloud source (the Change bandwidth action itself is live-verified) |
| 7 | glossary | AZ = geographically distant yet low-latency characterisation | PM | Exact phrasing needs PM sign-off (multi-az diagram corroborates ~30 km / <1 ms) |
| 8 | glossary | Region deployed in Europe / North America / Asia-Pacific (generic wording) | PM | Confirm against the website regions page |
| 9 | incident-followup | RCA / post-incident report can be requested from OVHcloud support | PM | Support-process claim; no doc source |
| 10 | incident-followup | Escalation via support portal + account manager for priority handling | PM | Support-process claim; no doc source |
| 11 | l3-bgp | `resourceId` in `POST /config/pop` response is the new `popId` | live-mutate | Needs a create call or an open task; guide no longer depends on it (points to `GET .../config/pop`) |
| 12 | l3-static | Verify-connectivity expected outputs (traceroute via 192.0.2.1, ping reply) | operational | Illustrative example values; environment-specific |
| 13 | l3-static | Static routing form labels ("Network Focus" / "Next hop") | live-CP | Static type is disabled once an AZ has a BGP rule; open the form on an AZ with no routing rule |
| 14 | limits | Provider must have a presence at the chosen OVHcloud PoP | PM | Provider onboarding specifics; PM confirm |
| 15 | monitor | Python snippet returns `service['status']` key name | live-CP/API | Run `GET /ovhCloudConnect/{serviceName}` (read-only) to confirm the field |
| 16 | monitor | Diagnostics "See result" / "Download result" exact casing | live-CP | Run a diagnostic to populate the Diagnostics tab, then read the per-entry actions |
| 17 | multi-az | "Test failover by simulating a link outage" operational step | operational | Needs a live failover observation (/walk-guide) |
| 18 | occ-direct-control-panel-setup | Order funnel steps ("Select OVHcloud Connect Direct") | live-CP | "Order" button confirmed on the list page; the funnel steps were not walked |
| 19 | occ-direct-control-panel-setup | Troubleshooting specifics (SFP/transceiver compat, max-prefix behaviour, Active/Idle states) | operational | Diagnostic thresholds/state labels; operational, needs a live test |
| 20 | occ-provider-control-panel-setup | Order funnel steps ("Select OVHcloud Connect Provider") | live-CP | "Order" button confirmed on the list page; the funnel steps were not walked |
| 21 | occ-provider-control-panel-setup | Provisioning "usually fast (minutes to hours for on-demand providers)" | third-party | Provider-portal-specific timing; no OVHcloud source |
| 22 | occ-provider-control-panel-setup | Troubleshooting specifics (service-key-entry validation, provisioning-delay behaviour, latency/packet-loss checks) | third-party | Provider-portal + operational diagnostics; no OVHcloud source |
| 23 | order-direct | Website order-funnel steps + prep-list order inputs | live-CP | "Order" button confirmed on the list page; funnel not walked |
| 24 | order-provider | Website order-funnel steps + provider provisioning sequence | live-CP / third-party | funnel not walked; provider-side provisioning is third-party |
| 25 | pop-locations-regions | Region list missing newer 3-AZ regions (Milan `eu-south-mil` confirmed reachable live) | PM / live | reconcile against the live "Add an AZ" set / OCC webpage |
| 26 | pop-locations-regions | Madrid facility naming: guide "Digital Realty - MAD2" vs Manager "Interxion – MAD2" | PM | confirm preferred label |
| 27 | providers | ~9 third-party provider marketing descriptions + external URLs + on-demand/multicloud claims | third-party | run /verify-links; descriptions have no OVHcloud source |
| 28 | slas | Config-tier marketing labels + SLA void / maintenance-exclusion / report-promptly clauses (4) | PM / contract | confirm exact OCC specific-conditions wording |
| 29 | troubleshooting | CP "locked" port behaviour; provider-portal status strings; 80%-bandwidth rule of thumb; exact in-portal support labels; OVHcloud BGP timer specifics (5) | mixed (live-CP / third-party / PM) | per-item; see troubleshooting.md |
| 30 | vrack-network-setup | "No VLAN / no trunk" per-router framing; GET/POST datacenter response schemas incl. `regionType`/`available` (3-AZ live-corroborated) (6) | live-API / PM | one `GET .../datacenter` + task GET call; router-limitation framing needs PM |
| 31 | resilient-architecture | Third-party AWS/Azure/GCP console procedures, vendor recommendations, editorial matrices, illustrative values (~20) | third-party / operational | intentional multi-cloud addition; cloud/provider docs + live test |
| 32 | simple-architecture | Third-party AWS/Azure/GCP console procedures, editorial matrices, illustrative examples (~15) | third-party / operational | same as resilient-architecture |
| 33 | cross-connect-loa | DC-operator LOA-for-removal policy; provider-handles-cross-connect; cross-connect lead times (3) | third-party | data-centre-operator / provider process |

## Quick-win candidates (closable with the current authenticated session)
- **#15** — one read-only `GET /ovhCloudConnect/{serviceName}` call.
- **#16** — launch one diagnostic on the test service, then read the Diagnostics-tab row actions.
- **#13** — open the routing-rule form on an AZ that has no routing rule yet (to reveal the Static fields).
- **#5** — a manual (non-automated) look at the Help Centre ticket funnel for the exact service/category labels.
- **#18 / #23 / #24** — walk (without submitting) the OCC order funnel from the "Order" button.
- **#30** — one read-only `GET .../config/pop/{popId}/datacenter` (+ `.../datacenter/{id}`) call to confirm the `regionType`/`available` schema (the "3-AZ" concept is already corroborated in the live Manager).
- **#25** — enumerate the live "Add an AZ" region list to reconcile the guide's accessible-regions table with the current 3-AZ regions.

## Closed this cycle (were category 3, now resolved/verified)
- Diagnostic enum hallucination (l3-bgp, l3-static) — removed.
- PoP & Extra API response schemas (l3-bgp, l3-static) — live-confirmed.
- Introduction & multi-az architecture diagrams — visually verified.
- Service-Details panel + diagnostics-launch labels (monitor) — live-verified.
- Bandwidth-change answer (faq) — corrected to the live "Change bandwidth" action.
- CP walkthrough labels (occ-direct/provider-cp-setup, l2, l3-bgp, l3-static) — live-verified ("User ASN", "Configure port", "Add an AZ", "Routing rules").
- Unsupported-features table (troubleshooting) — traced to occ-limits (→ category 1).
- Colt provider (providers) + per-PoP low-latency mapping (pop-locations-regions) — resolved earlier; reports reconciled.
- "Download LOA" + DC-operator names (cross-connect-loa) — live-verified.
