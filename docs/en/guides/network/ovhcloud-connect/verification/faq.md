{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — faq.mdx

- **Previous-doc source:** ovhcloud-connect-old/faq.mdx
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| OCC = private connection to OVHcloud vRack without an internet VPN tunnel | 11 | previous faq.mdx L10 |
| OCC compatible with all vRack-enabled OVHcloud products (BMS, Public Cloud, HPC/VMware) | 105-111 | previous faq.mdx L12-14 |
| OVHcloud does not host customer routers; need own rack in a PoP facility | 34 | previous faq.mdx L46-48 |
| Provider delivered as soon as the service key is emailed (minutes after order) | 59-60 | previous faq.mdx L58 |
| Direct delivered when light detected, or 60 days after order, or manual arrangement | 54-55 | previous faq.mdx L60-66 |
| LOA sent by OVHcloud after order to authorise cross-connect | 53 | previous faq.mdx L66 |
| Single-mode fibre; SFP 1000LX/LH or 10G-LR | (implied via Direct speeds) | previous faq.mdx L52 |
| Reserved ASNs 65501 (EU) / 65502 (CA) / 65519 (Asia); customer & OVH ASN differ | 91 | previous troubleshooting L158-162 |
| Redundancy: local within a PoP, geographical between two PoPs (Multi-AZ / BGP) | 150,152 | previous faq.mdx L42 (L3 redundancy mechanisms) |
| IPv6 not supported on L3 | 99 | previous occ-limits.mdx L48 (IPv6 listed under L3 unsupported features) |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Direct speeds 1/10/100 Gbps | 21,67 | ovhcloud.com (authoritative bandwidth facts) |
| Provider speeds 50 Mbps–50 Gbps | 21,67 | ovhcloud.com (authoritative bandwidth facts) |
| Any ASN allowed except reserved values; AS35540 valid; private 64512–65534 common | 91 | authoritative facts (corrected ASN rule) |
| Max 100 prefixes per BGP session | 95 | authoritative facts (occ-limits) |
| Jumbo frames up to 9000 bytes | 103 | authoritative facts (occ-limits) |
| BFD enabled by default; failover < 1 s | 119,164 | authoritative facts (occ-layer3) |
| SLA tiers: 1 conn none / 2 conn 1 PoP none / 2 conn 2 PoPs 99.9% / 4 conn 2 PoPs 2 DCs 99.99% | 143-146 | OCC contract (authoritative SLA facts) |
| SLA covers PoP-to-DC path only, excludes third-party Virtual Circuit | 148 | OCC contract |
| 60-day interconnection window before Direct billing starts | 54-55 | authoritative delivery facts; troubleshooting Issue 9 |
| Ordering via CP, API, or Terraform | 47 | api.json + terraform.json (both exist) |
| API EU/CA endpoints eu.api.ovh.com / ca.api.ovh.com, /v1/ovhCloudConnect/ | 214-217 | api.json namespace ovhCloudConnect v1; OVHcloud multi-region endpoints |
| Terraform via ovh/ovh provider manages OCC resources | 208 | terraform.json `ovh_vrack_ovhcloudconnect` |
| Public Cloud: attach project to same vRack + private network on instances | 111 | vRack integration (standard OVHcloud) |
| HPC/VMware: same vRack + port groups | 107 | vRack integration (standard OVHcloud) |
| Bandwidth can be changed via the CP "Change bandwidth" action (Direct port-speed change may still need new optics/cross-connect) | 73-76 | **Live-verified (authenticated CP):** the PoP-configuration row action menu includes **"Change bandwidth"**. **Fixed this pass:** the previous answer ("bandwidth changes require ordering a new service") was wrong and was rewritten to point to the Change bandwidth action. |
| Multiple OCC services can share one vRack | 131 | authoritative facts (multi-service same vRack) |
| Delivery/lead time: Direct on light detection or 60 days after order; Provider as soon as the service key is provisioned; times non-guaranteed | 20-23 | previous faq.mdx (Direct light/60-day, Provider service-key) + OCC contract Art. 4 (delivery times are non-guaranteed) |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Reaching AWS/Azure/GCP is out of scope, handled by third-party providers | 127 | Correct scoping statement, but references third-party clouds — no OVHcloud source for the linked procedures |
| Links to AWS/Azure/GCP "resilient" tutorials | 158-160 | Point to resilient-architecture; the multi-cloud procedures themselves are third-party |
| Support-ticket flow (open the Help Centre, start a request, select the OVHcloud Connect service) | 195-201 | **Live-checked (Playwright, authenticated):** the Help Centre is the support entry point and is linked from the Manager dashboard ("Centre d'aide"). The ServiceNow ticket portal itself would not render under automation (its `spinnerLoading` script crashes, then the SSO session drops), so the exact in-portal category labels remain unconfirmed. Wording kept generic and service-based to match the real flow. |
| Bandwidth-change "plan during a maintenance window" | 74 | Operational advice; no OVHcloud source |

## Summary
- Category 1: 10 · Category 2: 17 · Category 3: 4
- Notes: Solid overlap with the previous FAQ (vRack, delivery, no router hosting, ASN rules, IPv6-not-supported). Quantitative claims (bandwidth, SLA, prefixes, MTU, BFD) are backed by the contract / ovhcloud.com / authoritative facts. Fixed this pass: lead time reframed to the contract's non-guaranteed delivery + old-doc facts (→ verifiable); the unsupported "contact support for >100 prefixes" claim removed; the support-ticket steps reworded to the verified entry point (the Help Centre, linked from the Manager dashboard) and kept service-based. Live Playwright note: login and the Manager dashboard were verified authenticated, but the ServiceNow ticket portal crashes under automation (`spinnerLoading` error → `session_timeout`), so exact in-portal labels stay unconfirmed — the item remains category 3.
