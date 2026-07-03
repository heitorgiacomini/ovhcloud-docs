{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — slas.mdx

- **Previous-doc source:** none (new guide) — no previous OCC doc covered SLAs. Facts verified against the OCC contract (spec authoritative facts) and occ-diagnostics for the monitoring cross-reference.
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

No previous SLA guide exists, so section 1 is empty by design. All SLA numbers map directly onto the spec's authoritative OCC-contract fact.

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| (none) | — | no previous OCC doc covered SLAs |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| SLA = contractual monthly-availability commitment; level depends on configuration | 9,13 | spec authoritative SLA fact (config-based, availability only) |
| 1 connection on 1 PoP → no commitment | 25 | spec SLA fact "1 conn = none" |
| 2 connections on 1 PoP → no commitment | 26 | spec SLA fact "2 conn/1 PoP = none" |
| 2 connections on 2 PoPs → 99.9% | 27 | spec SLA fact "2 conn/2 PoPs = 99.9%" |
| 4 connections on 2 PoPs to 2 datacentres → 99.99% | 28 | spec SLA fact "4 conn/2 PoPs/2 DCs = 99.99%" |
| Only redundant configs across two PoPs qualify for an availability commitment | 30 | spec SLA fact (single / same-PoP pair = none) |
| Scope = OVHcloud portion only, PoP to datacentre; excludes third-party Virtual Circuit; no latency SLA | 17 | spec SLA fact "Scope PoP→DC only, availability only" |
| Service credits by measured availability: 99.9–99% = 10%; 99–95% = 20%; below 95% = 30% | 47-49 | spec SLA fact "service credits 10/20/30%" |
| Service credits capped at 30% of monthly cost per month | 51 | spec SLA fact "capped 30%/mo" |
| Claims must be submitted within one month of the support-ticket closure | 51 | spec SLA fact "claim within 1 month" |
| OCC provides on-demand diagnostics, not a continuous uptime dashboard/alerting | 57 | previous occ-diagnostics (on-demand diagnostics model); spec Diagnostics fact |
| Higher SLA tiers require redundant connections; single connection cannot claim 99.99% | 39 | spec SLA tiering (4 conn required for 99.99%) |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Config-tier marketing labels "Local redundant connection" / "High Availability – Level 1" / "High Availability – Level 2" | 26-28 | exact contractual tier names are not in the spec's fact list or SOT; verify against the actual OCC specific-conditions wording |
| "Incorrect BGP config or unsupported setups may void the SLA" | 35 | SLA-invalidation conditions not enumerated in the spec facts; confirm against contract |
| "Downtime during announced maintenance is typically excluded from SLA calculations" | 38 | maintenance-exclusion clause not in spec facts; confirm exact contract wording |
| Report incidents "promptly" via official support channels as an SLA prerequisite | 37 | prerequisite phrasing not in spec facts; confirm against contract |

## Summary
- Category 1: 0 · Category 2: 12 · Category 3: 4
- Notes: New guide, no previous equivalent (section 1 empty as expected). All the core SLA numbers — the four config tiers, the 10/20/30% credits, the 30%/month cap, the one-month claim window, and the PoP→DC availability-only scope — match the spec's authoritative OCC-contract fact exactly. The category-3 items are the tier marketing labels and the SLA-prerequisite/exclusion clauses, whose precise contractual wording should be confirmed against the OCC specific conditions.
