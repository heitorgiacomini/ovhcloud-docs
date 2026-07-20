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
| Per-PoP "Low-latency OVHcloud Region" single-region mapping (Frankfurt→Limburg, Lille→Roubaix, London→Erith, Paris→Paris, Warsaw→Warsaw, Montreal→Beauharnois, Toronto→Toronto, Mumbai→Mumbai, Singapore→Singapore; Madrid = "-") | 82-120 | **Confirmed factual by the docs owner** (see README "Discrepancies flagged"); the "indicative / not guaranteed" hedge was removed and the mapping is treated as verified. |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| **Region list may be incomplete** — Milan (Italy, `eu-south-mil`) 3-AZ is a reachable OCC AZ but is **absent from the Europe accessible-regions list** | 68-76 | **Live-pass finding (authenticated CP):** a Paris-PoP (TH2) test service had an AZ configuration in **"Europe (Italy - Milan) 3-AZ" (`eu-south-mil-c`)**, so Milan is reachable in the Europe zone yet is not listed. The list predates the newer 3-AZ regions — reconcile against the live "Add an AZ" region set / OCC webpage (likely more missing regions). Not edited into the guide pending the full authoritative list. |
| Madrid PoP facility name: guide says **"Digital Realty - MAD2"**, Manager shows **"Interxion – MAD2"** | 86 | **Live-pass finding:** Interxion is a Digital Realty brand, so both refer to the same facility, but the Manager/LOA display "Interxion – MAD2". Confirm the preferred label with PM. |

## Summary
- Category 1: 11 · Category 2: 4 · Category 3: 2
- Notes: The PoP inventory and the accessible-region sets are a faithful carryover of the previous overview's authoritative table (all listed PoPs and region codes match). The per-PoP "Low-latency OVHcloud Region" column — the one genuinely new element — was **confirmed factual by the docs owner** and moved to category 2 (hedge removed). Two live-pass findings remain category 3: the region list is missing the newer 3-AZ regions (Milan confirmed reachable in the live Manager) and needs reconciliation against the authoritative list, and the Madrid facility is displayed as "Interxion – MAD2" in the Manager (vs "Digital Realty - MAD2" in the guide).
