{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — pop-locations-regions.mdx

- **Previous-doc source:** ovhcloud-connect-old/ovhcloud-connect-overview.mdx ("Accessible Regions per PoP" table)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

The spec states the PoP/region table is authoritative in the previous overview. I cross-checked every PoP and region in the new tabbed tables against that previous table.

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| Each PoP is tied to a geographic zone and can only reach OVHcloud regions in that same zone | 11 | previous overview "each PoP is associated with a geographic zone, and the OVHcloud regions … limited to the zone" |
| Europe accessible regions: Limburg/lim, Erith/eri, Gravelines/gra, Paris/par, Roubaix/rbx, Strasbourg/sbg, Warsaw/waw | 73-79 | previous overview Europe row (same 7 regions + codes) |
| Europe PoPs: Paris Equinix-PA3 / GlobalSwitch / Telehouse-TH2; Frankfurt Equinix-FR5; London Equinix-LD5 / Telehouse-West; Madrid Digital Realty-MAD2; Warsaw Equinix-WA2; Lille ETIX-ETX2 | 86-94 | previous overview Europe PoP list (all match) |
| North America regions: Beauharnois/bhs, Toronto/tor | 101-102 | previous overview NA row |
| North America PoPs: Montreal Cologix-MTL3; Toronto Equinix-TR1 | 108-109 | previous overview NA PoP list |
| Asia-Pacific regions: Singapore/sgp, Mumbai/mum | 115-116 | previous overview APAC row |
| Asia-Pacific PoPs: Singapore Equinix-SG1; Mumbai Equinix-MB2 | 123-124 | previous overview APAC PoP list |
| Direct requires presence/circuit in the same DC to install a cross-connect; Provider reaches the PoP from a different facility | 23-25 | previous overview + occ concepts (Direct manages cross-connect; Provider handles physical connectivity) |
| PoPs are inside carrier-neutral partner datacenters | 22 | previous overview "facilities like Equinix, InterXion, Telehouse or Global Switch" |
| Regions = geographical areas hosting data centres/services; each may contain PoPs | 18-19 | previous overview region/zone concept |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| ≥2 PoPs in different locations for high availability (single-site failure tolerance) | 45 | spec redundancy fact (2 conn/2 PoPs); previous occ-layer3 multi-PoP resilience |
| Guidance framework for choosing a PoP (proximity/latency, provider availability, redundancy, data residency, target region) | 33-59 | advisory content consistent with OCC model; each factor logically follows from documented behaviour (zone-bound reachability, Provider presence, redundancy) |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Per-PoP "Low-latency OVHcloud Region" single-region mapping (e.g. Frankfurt Equinix-FR5 → Limburg; Lille ETX2 → Roubaix; London → Erith; Paris → Paris; Warsaw → Warsaw; Montreal → Beauharnois; Toronto → Toronto; Mumbai → Mumbai; Singapore → Singapore) | 86-124 | this per-PoP low-latency column does NOT exist in the previous docs (old table only mapped zone→region-set, not PoP→single region). The guide itself hedges it as "indicative"/"guidance rather than a guarantee". Needs PM/network confirmation of each mapping |
| Madrid Digital Realty-MAD2 low-latency region = "-" (no listed region) | 90 | Madrid appears in the previous PoP list but had no dedicated region; the "no low-latency region" entry is new and unconfirmed — verify with PM |

## Summary
- Category 1: 11 · Category 2: 2 · Category 3: 2
- Notes: The PoP inventory and the accessible-region sets are a faithful carryover of the previous overview's authoritative table (all PoPs and region codes match). The genuinely new element is the added "Low-latency OVHcloud Region" per-PoP column, which the guide itself flags as indicative — this mapping has no previous-doc or SOT source and needs network/PM validation.
