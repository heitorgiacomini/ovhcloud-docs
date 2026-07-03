{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — resilient-architecture.mdx

- **Previous-doc source:** none (new guide)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| _(none — this guide has no previous-doc equivalent; carryover BGP/ECMP/SLA concepts are listed in section 2)_ | — | previous mapping: `resilient-architecture→NONE` |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Two OVHcloud Connect services (Direct, Provider, or a mix) terminating at different PoPs for redundancy | 24, 44-48, 139, 153 | Multi-path resilience model consistent with SLA config tiers (spec/contract) |
| A multi-path architecture is needed to reach the config-based SLA tiers | 39, 147 | OCC contract: SLA is config-based (2 conn/2 PoPs = 99.9%, 4 conn/2 PoPs/2 DCs = 99.99%) |
| Two BGP sessions, one per link, with routing policies for path preference | 60-62, 161 | BGP model; multiple sessions (previous occ-layer3) |
| Local Preference controls outbound path preference (higher = preferred) | 68, 244-246 | Universal BGP standard |
| AS-path prepending makes a path look longer / less preferred; configurable only on your own (customer-side) devices, not on the OVHcloud side | 69, 247, 374, 516 | AS-path prepending is customer-side only (spec authoritative facts; previous occ-layer3) |
| MED signals a preferred path (lower = preferred); it is the OVHcloud-side alternative to AS-path prepending | 70, 247, 374-379, 516-521 | MED = OVHcloud-side alternative, lower preferred (spec; previous occ-layer3) |
| BFD is enabled by default on OVHcloud Connect BGP sessions and speeds up convergence | 90, 394 | BGP: BFD on by default (previous occ-limits/occ-layer3) |
| ECMP is automatically enabled with 2 or more PoPs, across up to 4 paths | 115, 164 | ECMP auto with 2+ PoPs, ≤4 paths (spec; previous occ-layer3) |
| One BGP session per PoP (no eBGP multihop) | 124 | BGP: 1 session/PoP, no eBGP multihop (previous occ-limits) |
| Up to 4 BGP peers per datacentre/AZ | 124 | BGP: ≤4 peers/DC (previous occ-limits) |
| Up to 100 prefixes advertised per BGP session | 126, 400 | BGP: ≤100 prefixes/session (previous occ-limits) |
| You cannot mix BGP and static routing in the same datacentre | 126 | previous occ-layer3 (BGP vs static per-DC) |
| Enabling BGP disables VRRP on that configuration | 127 | VRRP: enabling BGP disables VRRP (spec; previous occ-layer3) |
| Bandwidth per link: Direct 1, 10 or 100 Gbps; Provider 50 Mbps up to 50 Gbps | 128 | website: Direct 1/10/100 Gbps; Provider 50 Mbps–50 Gbps (spec) |
| Jumbo frames up to 9000 bytes supported on the OVHcloud side | 541 | Optics/MTU: jumbo up to 9000 (previous occ-limits) |
| Azure ExpressRoute Private Peering uses Provider ASN on the peer side; /30 subnets for BGP | 357-359 | Universal ExpressRoute private-peering config fact |
| GCP Cloud Router uses ASN 16550 by default | 454, 456 | Universal, verifiable Google Cloud fact |
| Non-overlapping IP ranges required between cloud VPC/VNet and OVHcloud subnets | 142, 201, 292, 421 | IP no-overlap requirement (previous occ-layer3) |
| Two AZs / Multi-AZ vRack for OVHcloud-side resilience (cross-ref to Multi-AZ guide) | 26-27, 291, 307, 420, 436 | Multi-AZ model (previous occ-layer3; Multi-AZ guide exists) |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| "Recommended for" matrix (business-critical, regulated, DR) | 35-40 | Editorial suitability guidance; no OVHcloud source — PM/editorial |
| Failover test procedure specifics (shut BGP session, verify reconvergence, restore) | 80-98, 174-179, 256-261 | Operational test steps; correct in principle but outcomes need live validation |
| Active/Active: equal Local Preference load-balances traffic; each link must handle full load alone on failure | 110-119 | Design guidance; load-balancing behaviour needs live test to confirm |
| AWS: two Direct Connect connections at different locations; Private VIF per connection via VGW/TGW | 218-225 | Third-party AWS console procedure — needs live test |
| "AWS recommends Transit Gateway with multiple Direct Connect Gateways" | 227 | Third-party AWS recommendation — no OVHcloud source |
| AWS: use Direct Connect Gateway with route priorities for failover | 248 | Third-party AWS routing feature — needs live validation |
| Azure: "Microsoft recommends two ExpressRoute circuits in different peering locations" | 300 | Third-party Microsoft recommendation — no OVHcloud source |
| Azure: create two ExpressRoute circuits, SKU Standard/Premium, Service Key per circuit | 311-324 | Third-party Azure portal procedure — needs live test |
| Azure: Premium recommended if VNets are in different regions than peering locations | 324 | Third-party Azure guidance — not an OVHcloud fact |
| Azure: connection weight (100 vs 50) to prefer a path; Virtual Network Gateways → Connections | 362-370 | Azure portal feature/UI — provider/portal specific, needs live test |
| Azure private peering /30 example subnets and VLAN IDs (169.254.100.0/30 etc.) | 358-360 | Illustrative + third-party; exact values portal-assigned |
| Azure Global Reach / FastPath / per-circuit route limits | 398-400 | Third-party Azure features — no OVHcloud source |
| GCP: "Google recommends VLAN attachments in different edge availability domains for 99.9%–99.99% SLA" and GCP SLA-tier table | 429, 440-444 | Third-party Google SLA claim/tiers — no OVHcloud source; verify against Google docs |
| GCP: create two Cloud Routers in different regions; two VLAN attachments in zone1/zone2 | 448-465 | Third-party GCP console procedure — needs live test |
| GCP: Cloud Router uses MED via custom route advertisements to influence its own path selection (GCP-internal) | 505-512 | Third-party GCP-internal mechanism — needs live validation |
| GCP VLAN attachment activation flow ("Pending customer" → Activate) | 497-499 | Third-party GCP UI workflow — not OVHcloud-controlled |
| GCP considerations: custom route advertisements, Dataplane v2 Pod CIDR, Shared VPC host-project, MTU per Google options | 538-541 | Third-party GCP specifics — no OVHcloud source |
| Provider "cloud router" bridging / per-path circuit-creation steps (all cloud tabs) | 235-240, 336-349, 477-491 | Provider-portal specifics — explicitly deferred to provider docs; no OVHcloud source |
| Cost considerations (2× each of AWS/provider/OVHcloud billing) | 264-271 | Operational/pricing claim — not confirmable from cache; needs PM |
| Illustrative MED/prepend values in failover tables (100/200, 1× prepend) | 376-379, 518-521 | Example configuration values — illustrative, not factual claims |

## Summary
- Category 1: 0 · Category 2: 19 · Category 3: 20
- Notes: New guide with no previous-doc equivalent, so section 1 is empty as expected. The On-Premises and WAN tabs are strongly category 2 — they are dense with verifiable OVHcloud BGP/ECMP/BFD/prefix/bandwidth/SLA facts that match the authoritative list. The AWS/Azure/GCP tabs are dominated by category 3: third-party console procedures, vendor recommendations (Transit Gateway, ExpressRoute Premium, GCP SLA tiers), portal UI strings, and provider cloud-router bridging, all needing live validation. AS-path-customer-side / MED-OVHcloud-side statements are consistently correct against the spec.
