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
| PoP configuration: click **"Configure port"** to open the **"Add a PoP configuration"** form; choose **Type** L2 or L3 | 66 | previous occ-direct-control-panel lines 57, 67 + **live-verified (authenticated CP)**: button is "Configure port", modal titled "Add a PoP configuration", Type = L2/L3 select. Guide corrected this pass. |
| L2 = transparent point-to-point link | 68 | previous occ-direct-control-panel §Configuration (L2 PoP config); Direct supports L2 |
| L3 PoP fields: **User ASN**, OVHcloud ASN, Subnetwork in /30 | 69-75 | previous occ-direct-control-panel lines 73-77 + **live-verified**: the customer field is labelled **"User ASN"** (help "Your AS BGP number…"), not "Customer ASN". Guide corrected this pass. |
| AZ configuration: **"Add an AZ"**, select availability zone | 79 | previous occ-direct-control-panel lines 91, 103 + **live-verified**: button is **"Add an AZ"** (was "Add a configuration"). Guide corrected this pass. |
| L3 AZ fields: OVHcloud ASN (may differ from PoP), /28 subnetwork (or larger) | 79-84 | previous occ-direct-control-panel lines 109-112 + **live-verified** (AZ table columns: OVHcloud ASN, Subnetwork) |
| Routing: **"Routing rules"** on the AZ opens **"Add a routing configuration."**; choose BGP or Static | 88 | previous occ-direct-control-panel lines 124-130 + **live-verified**: opened via **"Routing rules"** (was "Add routing configuration"); one routing type per AZ. Guide corrected this pass. |
| BGP routing fields: **User ASN**, IP Neighbour (within AZ subnetwork) | 90 | previous occ-direct-control-panel lines 134-137 + **live-verified**: labels **"User ASN"** (`bgpNeighborArea`) and **"IP Neighbour"** (`bgpNeighborIp`). Guide corrected this pass. |
| Static routing fields: Network Focus (CIDR prefix), Next hop (gateway IP in range) | 91 | previous occ-direct-control-panel lines 143-146. **Not re-confirmed live** — the Static routing type is disabled once an AZ already has a BGP rule, so the Static form could not be opened; old-doc-sourced. |
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
| CP status columns: **Link status** (up/down), **BGP status**, **Optical statuses**, **Configuration status** | 103-104 | **Live-verified (authenticated CP)**: the PoP configuration table exposes these status columns. (In the test service link/BGP read "Down"; the positive "up"/"Established" wording wasn't captured, but the status columns exist as described.) |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Order step "Select OVHcloud Connect Direct" as a CP action | 29 | Ordering is a website funnel (per order-direct), not a CP action; label/placement needs live confirmation. The OCC list page has an **"Order"** button (live-verified), but the funnel steps were not walked. |
| Troubleshooting table specifics (SFP/transceiver compatibility, maximum-prefix limits behaviour, "Active"/"Idle" states) | 113-116 | Diagnostic/state labels and thresholds not in old docs/SOT — operational, needs live test |

## Summary
- Category 1: 11 · Category 2: 8 · Category 3: 2
- Notes: Near-verbatim carryover of the Direct CP configuration flow. **This pass the entire CP walkthrough was live-verified against the authenticated Manager (English UI)** and the guide was corrected to the current labels: **"User ASN"** (was "Customer ASN"), PoP config opened via **"Configure port"** (modal "Add a PoP configuration"), **"Add an AZ"** (was "Add a configuration"), **"Routing rules"** (was "Add routing configuration"); "Attach a vRack", "OVHcloud ASN", "Subnetwork in /30", "IP Neighbour" and the L2/L3 Type select confirmed as-written. The PoP status columns (Link status / BGP status / Optical statuses / Configuration status) were live-verified → moved to category 2. **Screenshots were removed** from the guide this pass (kept only the `fig-1.svg` steps-overview diagram) per the no-screenshots decision. Remaining category-3 (2): the order funnel (website, not walked) and the operational troubleshooting specifics. (Separately, the Static routing form labels stay old-doc-sourced — noted within category 1 — because the Static type is disabled on an AZ that already has a BGP rule.)
