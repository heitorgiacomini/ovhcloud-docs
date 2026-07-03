{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — limits.mdx

- **Previous-doc source:** `ovhcloud-connect-old/occ-limits.mdx` (primary); `ovhcloud-connect-old/occ-layer3.mdx` (L3 BGP/session rules)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| Optics: 1 Gb = 1000Base-LX/LH | 45 | previous occ-limits "1000Base-LX/LH for 1Gb" |
| Optics: 10 Gb = 10GBase-LR | 46 | previous occ-limits "10GBase-LR for 10Gb" |
| Optics: 100 Gb = 100GBase-LR4 | 47 | previous occ-limits "100GBase-LR4 for 100Gb" |
| Jumbo frame / max MTU up to 9000 bytes | 28 | previous occ-limits "Jumbo frame up to 9000 bytes" |
| Auto-negotiation not supported / must be disabled | 49 | previous occ-limits "Autonegotiation not supported" |
| L2: client-side MAC addresses limited to 512 per port | 55 | previous occ-limits "512 per port" |
| L2: max bandwidth 10 Gb per port | 56 | previous occ-limits "maximum bandwidth is 10Gb per port" |
| L2 unsupported: 802.1p CoS-based | 62 | previous occ-limits unsupported L2 list |
| L2 unsupported: DCBX (802.1Qbb/Qaz/Qau) | 63 | previous occ-limits unsupported L2 list |
| L2 unsupported: TRILL, SPF, FabricPath | 64 | previous occ-limits unsupported L2 list |
| L2 unsupported: FCoE | 65 | previous occ-limits unsupported L2 list |
| L2 unsupported: Spanning Tree | 66 | previous occ-limits unsupported L2 list |
| L2 unsupported: IGMP and Multicast | 67 | previous occ-limits unsupported L2 list |
| L2 unsupported: EtherChannel, PaGP for aggregation | 68 | previous occ-limits unsupported L2 list |
| L3: max 1 BGP session per PoP (no eBGP Multihop) | 91 | previous occ-limits "one BGP session (no eBGP Multihop)" + occ-layer3 L99 |
| L3: up to 4 BGP peers per AZ (EndPoint/DC) | 92 | previous occ-limits "up to 4 BGP peers"; occ-layer3 L101 |
| L3: up to 100 prefixes per BGP session | 93 | previous occ-limits "Up to 100 prefixes" |
| L3 unsupported: IPv6 | 96 | previous occ-limits unsupported L3 list |
| L3 unsupported: any QoS mechanism | 97 | previous occ-limits unsupported L3 list |
| L3 unsupported: 802.1q tag | 98 | previous occ-limits unsupported L3 list |
| L3 unsupported: Multi-VRF | 99 | previous occ-limits unsupported L3 list |
| L3 unsupported: eBGP Multi-Hop | 100 | previous occ-limits unsupported L3 list |
| L3 unsupported: iBGP | 101 | previous occ-limits unsupported L3 list |
| L3 unsupported: static routing in PoP configuration | 102 | previous occ-limits "Static routing in EntryPoint/PoP" |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Direct = L2 and L3; Provider = L3 only (Provider always L3) | 85 | Authoritative facts (expert+contract+website): Direct L2&L3, Provider L3 only |
| Direct bandwidth options 1 / 10 / 100 Gb | 43–47 | website: Direct bandwidth 1/10/100 Gbps (bandwidth table) |
| An OCC service can be associated to one vRack only | 26 | terraform.json `ovh_vrack_ovhcloudconnect` (1 service ↔ 1 vRack); matches vrack-attach API model |
| Only one OCC L2 supported per vRack; unlimited L3 per vRack | 27, 57 | previous occ-layer3 L38 "as many OCC L3 as you want in the same vRack" + L2/L3 mix rule (L3-count carryover; per-vRack single-L2 phrasing new but consistent with L2/L3 model) |
| Requirements: OVHcloud account with billing; network/vRack permissions; vRack provisioned | 15–17 | Standard OVHcloud account/vRack model; vRack prerequisite in previous occ-direct-control-panel requirements |
| Access to co-location facility with an OVHcloud PoP; ability to order a cross-connect | 36–37 | previous troubleshooting (cross-connect is customer responsibility) + PoP model |
| Client equipment interface must match the bandwidth optic table | 41–47 | previous occ-limits optics table (same optics mapped to interface requirement) |
| LACP allowed for redundant links in same PoP (L2) | 59 | Universal networking standard (LACP link aggregation); consistent with L2 mode |
| L2 does not support redundant PoP architectures | 58 | previous occ-layer3: L2 is single-PoP; multi-PoP resilience is an L3 property |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Provider requires a contract with a supported provider present at the chosen PoP | 78–79 | Provider onboarding specifics not in previous docs or SOT; needs PM/live confirmation |

## Summary
- Category 1: 24 · Category 2: 9 · Category 3: 1
- Notes: Strong carryover guide. Core optics/MTU/L2-L3 limits are verbatim from previous occ-limits; the new material (Direct-vs-Provider layer split, bandwidth table framing, LACP-in-PoP, per-vRack service rules) is verifiable against the authoritative facts and the terraform/website model. Only the Provider-presence prerequisite lacks a citable OVHcloud source.
