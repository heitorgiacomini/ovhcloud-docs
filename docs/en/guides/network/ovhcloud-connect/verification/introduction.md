{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — introduction.mdx

- **Previous-doc source:** ovhcloud-connect-old/ovhcloud-connect-overview.mdx (+ faq.mdx, + occ-layer2.mdx / occ-layer3.mdx for topology facts)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| OVHcloud Connect is a dedicated, private connection bypassing the public Internet | 9 | previous overview "private, dedicated connection … bypassing the public internet" |
| Better security / lower latency / guaranteed bandwidth | 9,17 | previous overview + faq "quicker, more stable connection with guaranteed bandwidth" |
| Suited to hybrid/multi-cloud and network-extension use cases | 18 | previous overview "Network extension … eases hybrid cloud strategies" |
| Link established through a Point of Presence (PoP) where OVHcloud has equipment | 22 | previous overview "PoP - EntryPoint … facilities like Equinix, InterXion…" |
| Direct = you manage the physical cross-connect in a common PoP | 26 | previous overview "customer must order and manage the cross-connect for OVHcloud Connect Direct" |
| Direct supports L2 and L3 | 26 | previous overview Dedicated mode LACP (L2) or BGP-ECMP (L3); matches spec authoritative fact (Direct = L2 & L3) |
| L2 = data-link layer, transparent bridge, VLAN (802.1q) transparent, no routing | 31 | previous occ-layer2 "Transparent to VLANs … extended as-is"; faq "transparent to the Ethernet protocol" |
| L2 is strict point-to-point (one PoP + one AZ/DC) | 35,69 | previous occ-layer2 "Only one OVHcloud Connect L2 per vRack: each PoP can only be associated with one DC" |
| L2 redundancy only via LACP on the same PoP; backup via 2nd PoP not supported | 36,71 | previous occ-layer2 "redundancy cannot be exploited between two PoP … only solution is a LAG"; faq LACP 802.3ad |
| L3 = network layer, routing, routes exchange, BGP | 46,48 | previous occ-layer3 + overview "BGP … routing protocol used in Layer 3 mode" |
| L3 associated with vRack for private communication | 48 | previous overview "connected to your vRack with all compatible services" |
| L3 full-mesh between any PoP and any AZ of the same region | 52,75 | previous occ-layer3 "full mesh IP network between any PoP and any DC of the same region" |
| L3: several PoPs↔one AZ and several AZs↔one PoP; cannot link two PoPs | 77,78 | previous occ-layer3 rules (verbatim) |
| One L3 domain (subnet) maps to one AZ, cannot be stretched across 2 AZs/PoPs | 79 | previous occ-layer3 "One L3 domain cannot be stretched between two DCs or two PoPs" |
| As many L3 services as you want in the same vRack | 80 | previous occ-layer3 "as many OVHcloud Connect L3 as you want in the same vRack" |
| L2 and L3 can coexist in the same vRack | 86 | previous occ-layer3 "L2 can be mixed with several L3 in the same vRack" |
| Resilience via BGP multi-peer + ECMP with automatic failover across PoPs | 53 | previous occ-layer3 (ECMP, multi-PoP path selection) |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Provider = third-party provider handles the physical connection; L3 only | 27 | spec authoritative fact "Provider = L3 only"; confirmed by ovhcloud.com Provider offering |
| Provider best for orgs not co-located with OVHcloud / preferring managed connectivity | 27 | website Provider positioning; logically consistent with L3-only managed model |
| ECMP enabled automatically with ≥2 PoPs, up to 4 paths | 82 | previous occ-layer3 says ECMP auto with 2+ PoPs; "up to 4 paths" confirmed by spec authoritative fact (≤4 paths) — the "4" figure is new phrasing but verifiable |
| A single vRack can hold only one OCC L2 service | 69 | previous occ-layer2 states "one L2 per vRack" (present in old docs) — carryover-adjacent; kept here as it is verifiable |
| Architecture-overview image (introduction/image.png) depicts correct topology | 96 | **Visually verified this pass:** the diagram correctly shows vRack → Region → Availability Zone (Dedicated Servers / Instances / any vRack-compatible service) → OVHcloud Connect → Point of Presence → Network Equipment → Customer Network. Accurate conceptual topology; no live-product test needed. |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| _(none — the architecture-overview image was visually verified and moved to category 2)_ | — | — |

## Summary
- Category 1: 17 · Category 2: 5 · Category 3: 0
- Notes: Strong carryover from the previous overview + occ-layer2/occ-layer3 + faq. Most topology rules are verbatim from occ-layer3. New material (Provider = L3-only, explicit "up to 4 paths") is confirmed by the spec's authoritative facts. The architecture-overview diagram was visually reviewed this pass and is topologically correct, so it moves from category 3 to category 2 (no category-3 items remain).
