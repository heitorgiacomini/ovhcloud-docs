{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — multi-az.mdx

- **Previous-doc source:** ovhcloud-connect-old/occ-layer3.mdx (BGP path selection / VRRP / ECMP rules)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| AS-path prepending is configurable only on customer devices, not on the OVHcloud side | 33-34 | previous occ-layer3 "AS path prepending is not configurable on OVHcloud devices" + spec fact |
| MED is the OVHcloud-side alternative for active/passive path selection with two PoPs; lower MED preferred | 34 | previous occ-layer3 "Using MED is an alternative"; spec fact (MED lower preferred, OVHcloud-side) |
| Use AS-path prepending and/or MED to make one path primary and another backup with two PoPs | 24,30-34 | previous occ-layer3 BGP path selection section (AS-path prepend or MED for active/passive) |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Multi-AZ = distributing resources/connections across ≥2 physically separated AZs within a region | 9 | consistent with spec redundancy tiering (2 PoPs / 2 DCs) and standard cloud Multi-AZ concept |
| A single link through a single PoP is a single point of failure | 13 | spec SLA fact: 1 connection = no commitment; single-path = SPoF (verifiable, logical) |
| Redundancy achieved via redundant connections through different PoPs/AZs with automatic reroute | 15,23 | spec fact (2 conn/2 PoPs = 99.9%) + previous occ-layer3 ECMP auto-failover |
| Recommended pattern: order two OCC services in two different PoPs | 23 | spec redundancy fact (2 conn/2 PoPs); previous occ-layer3 two-PoP topology |
| Distribute OVHcloud resources across multiple AZs in the same region | 25 | consistent with L3 full-mesh within a region (previous occ-layer3) |
| Local Preference: set higher LocalPref on primary-link routes | 32 | universal BGP standard (LocalPref is a valid, standard attribute for primary/backup selection) |
| When-to-use matrix (test=single, non-critical=single+monitoring, business-critical/regulated=Multi-AZ) | 40-45 | advisory guidance consistent with the SLA tiering; not a hard technical claim |
| Architecture-overview image (multi-az/image.png) depicts redundant PoP/AZ topology | 19 | **Visually verified this pass:** the diagram correctly shows a 3-AZ region (AZ-1/2/3, ~30 km / <1 ms apart), OVHcloud Connect fanning to two PoPs (A & B) each with an OVHcloud Connect Router → customer routers → Customer Network, labelled "Layer 3 mode, SLA up to 99.99%". Accurate; also corroborates the SLA tier and the glossary AZ definition. |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| "Test failover by simulating a link outage and verifying traffic switches to the backup path" as an operational step | 26 | procedural/operational guidance; correctness of the observed failover behaviour needs live validation (/walk-guide) |

## Summary
- Category 1: 3 · Category 2: 8 · Category 3: 1
- Notes: The path-selection facts (AS-path prepend customer-side only, MED as OVHcloud-side alternative) are verbatim carryovers from occ-layer3. The Multi-AZ framing, two-PoP redundancy recommendation, and LocalPref usage are all confirmed by the spec's redundancy/SLA facts and universal BGP standards. The architecture diagram was visually reviewed this pass and is accurate (→ category 2). The only remaining category-3 item is the live failover-test step, which is operational by nature.
