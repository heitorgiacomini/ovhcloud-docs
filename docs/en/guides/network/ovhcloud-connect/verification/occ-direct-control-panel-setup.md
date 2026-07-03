{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — occ-direct-control-panel-setup.mdx

- **Previous-doc source:** ovhcloud-connect-old/occ-direct-control-panel.mdx (full CP configuration flow)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| CP nav path: Bare Metal Cloud > Network > OVHcloud Connect > select solution | 21, 58 | previous occ-direct-control-panel line 27 (same nav path) |
| "Attach a vRack" button; select existing vRack from drop-down; confirmation message | 62 | previous occ-direct-control-panel line 33-37 (same button + drop-down + confirmation) |
| PoP configuration menu: "Add a PoP configuration"; choose L2 or L3 | 66 | previous occ-direct-control-panel lines 57, 67 ("Add a PoP configuration", L2/L3 from drop-down) |
| L2 = transparent point-to-point link | 68 | previous occ-direct-control-panel §Configuration (L2 PoP config); Direct supports L2 |
| L3 PoP fields: Customer ASN, OVHcloud ASN, Subnetwork in /30 | 69-75 | previous occ-direct-control-panel lines 73-77 (identical table) |
| AZ configuration: "Add a configuration", select availability zone | 79 | previous occ-direct-control-panel lines 91, 103 (same button + AZ drop-down) |
| L3 AZ fields: OVHcloud ASN (may differ from PoP), /28 subnetwork (or larger) | 79-84 | previous occ-direct-control-panel lines 109-112 (identical table) |
| Routing: "..." button on AZ > "Add routing configuration"; choose BGP or Static | 88 | previous occ-direct-control-panel lines 124-130 (same buttons, same types) |
| BGP routing fields: Customer ASN, IP Neighbour (within AZ subnetwork) | 90 | previous occ-direct-control-panel lines 134-137 (identical) |
| Static routing fields: Network Focus (CIDR prefix), Next hop (gateway IP in range) | 91 | previous occ-direct-control-panel lines 143-146 (identical) |
| Multiple routing configs per AZ; first type (BGP/Static) applies to the rest | 93 | previous occ-direct-control-panel line 150 (same rule) |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Direct is self-managed L2 and L3, no third-party provider | 9 | Authoritative facts: Direct = L2 & L3, customer-managed cross-connect |
| Router must support BGP and single-mode fibre optic interfaces | 17 | Authoritative facts (optics): 1000Base-LX/LH, 10GBase-LR, 100GBase-LR4 (single-mode); occ-limits |
| Order Direct: choose PoP location and bandwidth (1, 10 or 100 Gbps) | 30-31 | website: Direct bandwidth 1/10/100 Gbps; order-direct guide |
| LOA emailed after order validation; contains DC/rack/cage reference + OVHcloud port designation | 37-42 | Authoritative facts (delivery: Direct, LOA); contract |
| L3 BGP: peer IP TCP port 179 | 114 | Universal networking standard (BGP over TCP/179) |
| ECMP / route-exchange verification via CP + router | 104-105 | Consistent with occ-layer3 (ECMP, BGP Established state) |
| API: /ovhCloudConnect PoP config uses /30 (PoP) and /28+ (AZ) | 75, 84 | Authoritative facts (IP): PoP /30, AZ /28 minimum; previous api.mdx lines 90, 127 |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Order step "Select OVHcloud Connect Direct" as a CP action | 29 | Ordering is a website funnel (per order-direct), not a CP action; label/placement needs live confirmation |
| Port shows "up" in the Control Panel; BGP session shows "Established" as CP status labels | 103-104 | Exact CP status strings ("up", "Established") not in old docs/manager-beta cache — needs live manager confirmation |
| Troubleshooting table specifics (SFP/transceiver compatibility, maximum-prefix limits behaviour, "Active"/"Idle" states) | 113-116 | Diagnostic/state labels and thresholds not in old docs/SOT — operational, needs live test |

## Summary
- Category 1: 11 · Category 2: 7 · Category 3: 3
- Notes: Near-verbatim carryover of the Direct CP configuration flow — every substantive CP step, button label, and field table (Attach a vRack, Add a PoP configuration, /30, /28, Add routing configuration, BGP/Static fields) matches the previous occ-direct-control-panel guide (category 1). New wrapper content (ordering, LOA, optics, bandwidth) is contract/website-verifiable; only CP status strings and a few troubleshooting specifics need a live walk.
