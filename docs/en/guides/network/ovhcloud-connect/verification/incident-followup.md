{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — incident-followup.mdx

- **Previous-doc source:** none (new guide) — content overlaps ovhcloud-connect-old/troubleshooting.mdx (support flow) only
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| _(none — no mapped previous guide; per spec, section 1 empty is expected)_ | — | mapping: incident-followup → NONE |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| CP nav: Bare Metal Cloud → Network → OVHcloud Connect | 48 | manager-beta cache path; consistent across new OCC guides |
| SLA scope = PoP-to-datacentre segment only | 9 | OCC contract (scope PoP→DC only, availability only) |
| Service credits are tied to an open ticket | 9,92 | OCC contract (claim via ticket, within 1 month of closure) |
| SLA tiers: 2 conn / 2 PoPs = 99.9%; 4 conn / 2 PoPs / 2 DCs = 99.99% | 92 | OCC contract (authoritative SLA facts) |
| Service credits 10/20/30% of monthly cost, capped 30%/month, claim within 1 month of ticket closure | 92 | OCC contract (authoritative SLA facts) |
| API-based incident retrieval endpoints exist | (concept) | api.json `GET /ovhCloudConnect/{serviceName}/incident`, `.../incident/{id}` |
| Linux diagnostic commands (ping/traceroute/mtr) | 35-37 | universal networking tooling |
| Collect timestamp (UTC), service name/ID, PoP, VLAN ID, symptoms, interface/BGP status, traceroute, MTR, recent changes | 19-26 | standard incident triage; fields all map to real service attributes |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Support ticket flow: Support → Create a ticket → select Network / OVHcloud Connect category | 52-53 | CP support-portal flow not in old docs/cache; needs live CP |
| RCA / post-incident report can be requested from OVHcloud support | 89 | Support-process claim; no OVHcloud doc source; PM confirm |
| Escalation via support portal + account manager for priority handling | 79-83 | Support-process claim; no source; PM confirm |
| Status & scheduled-maintenance pages "accessible from the Control Panel" | 44 | Exact CP location unverified; needs live CP |
| "Ticket status checked regularly through the Control Panel" | 72 | CP ticket-tracking specifics unverified |

## Summary
- Category 1: 0 · Category 2: 8 · Category 3: 5
- Notes: No mapped previous guide (section 1 empty, as expected). The SLA / service-credit facts are fully backed by the OCC contract; the rest is standard triage. Category 3 is entirely support-process / CP-flow wording that needs live CP or PM confirmation, not a factual risk to networking claims.
