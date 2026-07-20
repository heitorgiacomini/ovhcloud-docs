{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — glossary.mdx

- **Previous-doc source:** ovhcloud-connect-old/ovhcloud-connect-overview.mdx (concepts). Several term definitions also cross-checked against occ-layer3.mdx, occ-layer2.mdx, and universal networking standards.
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| Cross-connect = physical (fibre) cable between customer/provider and OVHcloud in a PoP | 35-36 | previous overview "cross-connection is a physical link (monomode fiber) … in the MMR" |
| PoP = physical location (third-party DC) = entry point into OVHcloud network | 69-70 | previous overview "PoP - EntryPoint … facilities like Equinix, InterXion…" |
| BGP = routing protocol to exchange routes; used in L3 mode | 24-25 | previous overview "BGP … routing protocol used in Layer 3 mode" |
| vRack = OVHcloud isolated private network interconnecting compatible services | 97-98 | previous overview "OVHcloud Private Network … connect compatible services into a single private network" |
| ASN: your side and OVHcloud side each have an ASN; the two must differ (eBGP) | 13-14 | previous occ-layer3 "AS must be independent from the customer BGP AS to form an eBGP relation" + spec fact (ASNs must differ) |
| Direct Connection = customer manages physical link via cross-connect in colo with OVHcloud PoP | 40-41 | previous overview cross-connect/Direct description |
| Provider = third-party operator facilitating connectivity, no co-location needed | 72-73 | previous overview "Accessible PoPs per provider"; matches Provider model |
| LACP = groups physical interfaces into one logical link for redundancy/throughput | 50-51 | previous faq "LACP 802.3ad"; occ-layer2 LAG |
| VRRP: one instance/AZ; VRID by OVHcloud; device A master by default; virtual gateway = first usable IP; enabling BGP disables VRRP | 94-95 | previous occ-layer3 VRRP section (verbatim rules) + spec authoritative VRRP fact |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| ASN reserved per-region values: 65501 Europe, 65502 Canada, 65519 Asia | 14 | spec authoritative fact (expert/contract); NOT in old docs (old doc only said recommended range 64512-65534) |
| Bandwidth: Direct 1/10/100 Gbps; Provider 50 Mbps–50 Gbps | 22 | spec authoritative fact (website): Direct 1/10/100 Gbps, Provider 50 Mbps–50 Gbps |
| BGP-ECMP = distributes traffic across multiple active links | 27-28 | universal networking standard (ECMP) + previous occ-layer3 ECMP usage |
| BGP session = connection between two BGP peers; at least one per PoP | 30-31 | universal BGP standard + previous occ-layer3 "one BGP session per PoP" |
| ASN definition (identifies a network for BGP route exchange) | 13 | universal networking standard |
| LOA = official doc authorising a DC operator to set up/remove a cross-connect | 59-60 | previous faq references LOA for cross-connect; definition matches standard colo LOA practice |
| Service Key = activation key given to partner operator to establish the connection | 82-83 | spec Delivery fact "Provider = service key emailed"; previous faq "service key sent by email" |
| SLA config-based; 2 conn/2 PoPs = 99.9% example | 85-86 | spec authoritative SLA fact (OCC contract) |
| VLAN (802.1q) = logical network segmentation | 91-92 | universal networking standard; previous occ-layer2 VLAN transparency |
| Multi-AZ = spreading resources/connections across AZs for resilience | 64-65 | consistent with spec Multi-AZ / redundancy facts; standard cloud concept |
| Isolation = physical/logical separation from public web (DDoS, interception) | 45-46 | consistent with OCC private-connection positioning (website) |
| L2/L3 Connectivity definitions (bridge vs routed, BGP for L3) | 53-57 | previous occ-layer2/occ-layer3 + universal OSI-layer standard |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| AZ = "physically isolated location within a region … geographically distant to be disaster-isolated, yet close enough for low latency" | 16-17 | precise geographic-distance/latency wording is a marketing/architectural characterisation not stated in the old OCC docs or SOT; needs PM confirmation of exact phrasing. **Fixed this pass:** the old wording was self-contradictory ("a data centre … containing data centres") — reworded to "a physically isolated location … hosting one or more data centres". |
| Region = OVHcloud regions deployed in Europe, North America, and Asia-Pacific | 77-78 | zone list is consistent with the PoP/region tables, but the generic "Region" wording is new; low risk, but not verbatim in SOT — confirm via website regions page |

## Summary
- Category 1: 9 · Category 2: 12 · Category 3: 2
- Notes: Definitional page. Core OCC terms (PoP, vRack, cross-connect, BGP, VRRP, ASN-must-differ) carry over verbatim from the previous concepts/occ-layer3 docs. Newly-surfaced hard facts (reserved ASN values, bandwidth ranges, config-based SLA) are all backed by the spec's authoritative facts. Only the AZ geographic-distance characterisation and the generic Region wording lack a direct SOT source and would benefit from PM confirmation.
