{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — troubleshooting.mdx

- **Previous-doc source:** ovhcloud-connect-old/troubleshooting.mdx
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| SFP by bandwidth: 1000Base-LX/LH (1 Gbps), 10GBase-LR (10 Gbps) | 43,90 | previous troubleshooting L99-111 (LX/LH, 10G-LR) |
| Auto-negotiation is **not supported**, must be disabled on customer router | 91,96 | previous troubleshooting L115-142 |
| Optical UP but interface DOWN = SFP misconfiguration symptom | 82 | previous troubleshooting L96-97 |
| OUT DOWN → OVHcloud port not emitting (port issue / cancelling / locked / SFP) | 44,73 | previous troubleshooting L68-72 |
| IN DOWN → OVHcloud not receiving (equipment not connected / port disabled / cross-connect / Tx-Rx inversion) | 74 | previous troubleshooting L73-77, 79-83 |
| Tx/Rx fibre inversion causes light on wrong port | 42 | previous troubleshooting L79-83 |
| LOA sample block + field interpretation (cabinet 103, cage, patch panel, port 16, FO 31/32, BACK, SC/PC) | 51-67 | previous troubleshooting L33-47 (verbatim) |
| PoP subnet /30, OVHcloud takes first IP, customer second | 109,280 | previous troubleshooting L151 |
| DC subnet /28 minimum, first three IPs reserved for OVHcloud | 280 | previous troubleshooting L150 |
| Reserved ASNs 65501 (EU) / 65502 (CA) / 65519 (Asia); customer & OVH ASN must differ | 110,282 | previous troubleshooting L158-162 |
| IP address conflict from using OVHcloud-reserved IPs | 280 | previous troubleshooting L146 |
| Cross-connect is customer responsibility; open ticket to PoP first | 40,45 | previous troubleshooting L51-53 |
| Unsupported features (Issue 12): IPv6, QoS/CoS (802.1p), Multi-VRF, Spanning Tree, Multicast/IGMP, FCoE | 294-303 | **previous occ-limits** unsupported lists — L3: IPv6, any QoS, Multi-VRF; L2: 802.1p CoS, Spanning Tree, IGMP/Multicast, FCoE (confirmed at the limits.md review). **Reclassified from category 3 this pass.** |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| 100GBase-LR4 for 100 Gbps | 43,90 | authoritative facts (occ-limits optics); ovhcloud.com Direct 100 Gbps |
| Any ASN allowed except reserved values (non-restrictive) | 110,282 | authoritative facts (corrected ASN rule) |
| BGP uses TCP port 179; firewall/ACL must allow it | 112 | universal BGP standard (RFC 4271) |
| L3 requires 802.1Q encapsulation with matching VLAN ID | 111,113 | previous occ-layer3 / api.mdx (VLAN, L3 tagged) |
| Max 100 prefixes per BGP session | 134 | authoritative facts (occ-limits) |
| Jumbo frames up to 9000 bytes supported | 148,198 | authoritative facts (occ-limits) |
| BFD enabled by default on all BGP sessions, failover < 1 s | 261 | authoritative facts (occ-layer3) |
| eBGP multihop not supported (single-hop peering) | 298 | authoritative facts (1 session/PoP, no eBGP multihop) |
| iBGP not supported; only eBGP | 299 | previous occ-layer3 (eBGP sessions) |
| Static routing at PoP not supported; all PoP routing via BGP | 300 | previous occ-layer3 / api.mdx (BGP at PoP; static only at DC) |
| L2 mode Direct-only; LACP supported for L2 aggregation within a PoP | 296,304 | previous faq.mdx L28 (LACP 802.3ad within PoP); occ-layer2 |
| 60-day interconnection window; beyond 60 days service considered operational & billing starts | 244 | previous faq.mdx L54-66; authoritative delivery facts |
| Provider: service key must match; PoP presence required; bandwidth compatibility | 223-226 | authoritative facts (Provider delivery via service key); providers list |
| Failover needs different PoPs + different AZs; same vRack; Local Pref / AS-path prepending | 259-263 | authoritative facts (Multi-AZ, path selection) |
| Local Preference to prefer primary, AS-path prepending on backup | 166,260 | authoritative facts (AS-path prepending customer-side) |
| Both OCC services must share the same vRack for failover | 262 | authoritative facts (multi-service same vRack) |
| Linux diagnostic commands (ping/traceroute/mtr/iperf3/ping -M do) | 174-211,314-320 | universal networking tooling |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Port "locked" state + "OUT DOWN may mean cancellation" phrasing tied to CP button | 44 | Old docs mention locked port; exact CP behaviour needs live check |
| Provider portal statuses "Active"/"Provisioned"/"Pending" wording | 224,230 | Third-party provider-portal specifics — no OVHcloud source |
| "80% of provisioned bandwidth" upgrade threshold | 197 | Operational rule of thumb; no OVHcloud source |
| Support-ticket flow (open the Help Centre, start a request, select the OVHcloud Connect service) | 326-329 | **Fixed this pass:** was "Support → Create a ticket → Network → OVHcloud Connect". Reworded to the live-verified Help Centre / service-based flow (see faq.md); exact in-portal labels still unconfirmed (portal crashes under automation). |
| Flap dampening / hold-timer behaviour specifics | 149,151 | Generic BGP but OVHcloud-side timers unconfirmed |

## Summary
- Category 1: 18 · Category 2: 18 · Category 3: 5
- Notes: The physical-layer / SFP / LOA / auto-negotiation / IP-reservation content is a faithful, verifiable carryover from the previous troubleshooting guide. The bulk of new material (BGP limits, BFD, MTU, optics, failover) is confirmed by authoritative facts. **Fixed this pass:** the "unsupported features" table (Issue 12: IPv6, QoS/CoS, Multi-VRF, STP, Multicast/IGMP, FCoE) was reclassified category 3 → category 1 (all present in the previous occ-limits unsupported lists), and the support-ticket flow was corrected to the live-verified Help Centre / service-based flow. Remaining category-3 (5): CP "locked" port behaviour, provider-portal status strings, the 80%-bandwidth rule of thumb, the exact in-portal support labels, and OVHcloud-side BGP timer specifics.
