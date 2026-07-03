{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — simple-architecture.mdx

- **Previous-doc source:** none (new guide)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| _(none — this guide has no previous-doc equivalent; only claims that also appear in occ-layer3/occ-limits/overview would qualify, and those are covered as carryover concepts in section 2)_ | — | previous mapping: `simple-architecture→NONE` |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| A single connection on a single PoP carries no availability SLA | 86 | OCC contract SLA tiers: 1 conn = none (spec authoritative facts) |
| Direct requires equipment co-located in the same data centre as an OVHcloud PoP; Provider is the managed alternative | 44-45, 23 | Direct = L2 & L3 / co-located; Provider = L3 managed (spec: L2/L3 + delivery) |
| Direct install uses an LOA / cross-connect at the data centre; Provider uses a service key shared with the provider | 49-50 | Delivery: Direct = LOA/cross-connect; Provider = service key emailed (spec) |
| One BGP session between on-premises router and OVHcloud, advertise/accept prefixes | 52-59 | BGP: 1 session/PoP; L3 BGP model (previous occ-layer3) |
| BGP session should reach state `Established` | 76 | Universal BGP standard (RFC 4271 FSM state) |
| OVHcloud Connect Direct offers 1, 10 or 100 Gbps; Provider offers 50 Mbps up to 50 Gbps | 294 | website: Direct 1/10/100 Gbps; Provider 50 Mbps–50 Gbps (spec) |
| Jumbo frames up to 9000 bytes supported on the OVHcloud side | 435 | Optics/MTU: jumbo up to 9000 (previous occ-limits) |
| Azure ExpressRoute Private Peering uses ASN 12076 | 360, 365 | Universal, verifiable Microsoft ExpressRoute fact |
| GCP Cloud Router uses ASN 16550 by default; custom ASN configurable | 426, 489, 494 | Universal, verifiable Google Cloud fact |
| OVHcloud-side ASN: any ASN except reserved 65501 (EU) / 65502 (CA) / 65519 (Asia), and must differ from the peer ASN | 365, 494 | ASN rule (spec authoritative facts; previous troubleshooting) |
| Private ASN range 64512–65534 is a valid choice | 365, 426, 494 | Universal, verifiable (RFC 6996 private ASN range) |
| Requires non-overlapping IP ranges between customer/cloud and OVHcloud subnets | 25, 172, 255, 271, 391 | IP addressing / no-overlap requirement (previous occ-layer3) |
| `GET /ovhCloudConnect/{serviceName}` API endpoint exists | 350, 482 | SOT api.json line 22835 (endpoint path present) |
| PoP location must be a facility where OVHcloud has a PoP | 118, 192 | PoP/region table authoritative in previous overview |
| Provider list exists for shared connectivity (cross-referenced) | 120, 171, 180, 201 | website provider list (spec: Digital Realty, Colt, Megaport, Equinix, etc.) |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| "Good for / Not recommended for" suitability matrices (dev/test, PoC, small offices vs. business-critical) | 33-38, 106-109, 279-284, 399-404 | Editorial guidance; no OVHcloud source defines these categories — PM/editorial judgement |
| AWS: create Direct Connect connection → Connections; Private VIF associated with VPC/VGW; note ASN, peer IPs, VLAN ID | 190-194 | Third-party AWS console procedure — no OVHcloud source; needs live test |
| AWS hosted-connection-via-provider workflow and cloud-router bridging steps | 213-216, 230-238 | Provider-portal + AWS specifics; not confirmable from OVHcloud sources |
| Three-segment BGP table (AWS VIF / provider bridge / OVHcloud Connect) | 224-234 | Composite third-party topology; no OVHcloud source for provider-side segments |
| Azure: Create ExpressRoute, note Service Key GUID; Peerings → Azure private; /30 primary/secondary subnets; VLAN ID | 288-333 | Third-party Azure portal procedure — needs live test |
| Azure verification labels ("Provider status: Provisioned", peering "State: Enabled") | 348-349 | Azure portal UI strings — provider/portal specific, not OVHcloud-controlled |
| OVHcloud service status value `active` returned by the API | 350, 482 | Endpoint exists (SOT) but the specific status enum value is not confirmed in cache — enum detail needs live API check |
| Azure troubleshooting matrix (circuit stuck "Enabling", peering not established, etc.) | 371-376 | Third-party diagnostic scenarios — no OVHcloud source; needs live validation |
| GCP: Dedicated vs Partner Interconnect distinction and "use Partner for this tutorial" | 408-415 | Third-party GCP concept/guidance — not an OVHcloud fact |
| GCP: create Cloud Router (Hybrid Connectivity → Cloud Routers), region europe-west1 for Paris | 419-426 | Third-party GCP console procedure; region-to-PoP mapping is editorial |
| GCP: Partner Interconnect VLAN attachment steps, MTU per Google options, pairing key format `<random>/<region>/<edge-availability-domain>` | 428-438 | GCP portal specifics — provider/portal detail, needs live test |
| GCP VLAN attachment state transitions ("Waiting for provider" → "Pending customer" → Activate) | 457-460, 501-505 | Third-party GCP UI workflow — not OVHcloud-controlled |
| GCP troubleshooting matrix | 499-505 | Third-party diagnostic scenarios — needs live validation |
| Provider "cloud router" bridging concept and per-provider circuit-creation steps (all cloud tabs) | 209-218, 304-321, 440-451 | Provider-portal specifics — explicitly deferred to provider docs; no OVHcloud source |
| Billing across AWS + provider + OVHcloud; latency depends on region distance + intermediate hops | 256-257 | Cost/latency operational claims — not confirmable from cache; needs PM/live data |
| Example IP prefixes / test IPs (10.0.0.0/16, 172.16.0.0/16, 169.254.100.0/30, ping targets) | 56-57, 73-75, 131, 146-153, 248-249, 330-331, 338, 468-469 | Illustrative examples only — not factual claims to verify |

## Summary
- Category 1: 0 · Category 2: 15 · Category 3: 15
- Notes: New guide with no previous-doc equivalent, so section 1 is empty as expected. The On-Premises and WAN tabs are largely category 2 (grounded in OVHcloud BGP/bandwidth/SLA facts). The AWS/Azure/GCP tabs are dominated by category 3 — third-party console procedures, portal UI strings, and provider cloud-router bridging that have no OVHcloud source and need live validation. The `active` service-status value is the one OVHcloud-side item whose enum is not confirmable in the cache.
