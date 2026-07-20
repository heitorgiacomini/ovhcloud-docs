{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — occ-provider-control-panel-setup.mdx

- **Previous-doc source:** ovhcloud-connect-old/occ-provider-control-panel.mdx (full CP configuration flow, L3 only)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| Provider is always a Layer 3 service | 9, 17, 49, 84 | Authoritative facts: Provider = L3 only; previous occ-provider-control-panel line 52 (requires L3) |
| Service key given to provider; provider provisions the connection; status becomes "Active" | 31, 37-45 | previous occ-provider-control-panel §Step 1 (service key, provider portal, status → "Active") |
| CP nav path: Bare Metal Cloud > Network > OVHcloud Connect > select solution | 20, 49 | previous occ-provider-control-panel lines 33, 37 (same nav path) |
| "Attach a vRack" button; select existing vRack from drop-down; confirmation message | 53 | previous occ-provider-control-panel lines 41-45 (same button + drop-down + confirmation) |
| PoP configuration: click **"Configure port"** to open the **"Add a PoP configuration"** form; **Type is locked to L3** | 59 | previous occ-provider-control-panel line 57 + **live-verified (authenticated CP, Provider service)**: button "Configure port"; the form states *"The provider's service can only have an L3 PoP configuration"*. Guide corrected this pass. |
| L3 PoP fields: **User ASN**, OVHcloud ASN, Subnetwork in /30 | 61-65 | previous occ-provider-control-panel lines 63-67 + **live-verified**: customer field labelled **"User ASN"** (not "Customer ASN"). Guide corrected this pass. |
| AZ configuration: **"Add an AZ"**, select availability zone | 69 | previous occ-provider-control-panel line 77 + **live-verified**: button is **"Add an AZ"** (was "Add a configuration"). Guide corrected this pass. |
| L3 AZ fields: OVHcloud ASN (may differ from PoP), /28 subnetwork (or larger) | 69-74 | previous occ-provider-control-panel lines 83-86 + **live-verified** (AZ table columns: OVHcloud ASN, Subnetwork) |
| Routing: **"Routing rules"** on the AZ opens **"Add a routing configuration."**; choose BGP or Static | 78 | previous occ-provider-control-panel lines 98-102 + **live-verified**: opened via **"Routing rules"** (was "Add routing configuration"). Guide corrected this pass. |
| BGP routing fields: **User ASN**, IP Neighbour (within AZ subnetwork) | 80 | previous occ-provider-control-panel lines 108-111 + **live-verified**: labels **"User ASN"** (`bgpNeighborArea`) and **"IP Neighbour"** (`bgpNeighborIp`). Guide corrected this pass. |
| Static routing fields: Network Focus (CIDR prefix), Next hop (gateway IP in range) | 81 | previous occ-provider-control-panel lines 117-120. **Not re-confirmed live** — Static type is disabled once an AZ already has a BGP rule; old-doc-sourced. |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Provider is provider-managed; no need to be co-located with OVHcloud | 9 | Authoritative facts / product model: Provider builds the link via virtual circuit |
| Router must support BGP peering | 17 | Authoritative facts: Provider = L3 only (BGP peering required) |
| Order Provider: choose provider, PoP location, bandwidth; OVHcloud generates a service key | 28-31 | website order flow + Authoritative facts (delivery: Provider = service key emailed); order-provider guide |
| BGP peering between your (or provider's) router and OVHcloud PoP | 85 | Authoritative facts: Provider L3 BGP; occ-layer3 |
| CP shows **Service status "Active"** + PoP **Link status / BGP status** columns | 45, 93 | **Live-verified (authenticated CP)**: all test services show Service status = "Active" in the list; the PoP configuration table exposes Link/BGP status columns. (Provider-portal-side status tracking is third-party.) |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Order step "Select OVHcloud Connect Provider" as a CP action | 28 | Ordering is a website funnel (per order-provider), not a CP action. The OCC list page has an **"Order"** button (live-verified), but the funnel steps were not walked. |
| Provisioning "usually fast (minutes to hours for on-demand providers)" | 43 | Provider-portal-specific timing; no OVHcloud source — needs live/provider confirmation |
| Troubleshooting specifics (service-key-entry validation, provisioning-delay behaviour, latency/packet-loss checks) | 103-106 | Provider-portal + operational diagnostics; no OVHcloud source — needs live test |

## Summary
- Category 1: 11 · Category 2: 5 · Category 3: 3
- Notes: Near-verbatim carryover of the Provider CP configuration flow. **This pass the CP walkthrough was live-verified against the authenticated Manager (on a real Provider service)** and the guide corrected to current labels: **"User ASN"** (was "Customer ASN"), PoP config opened via **"Configure port"** with the **Type locked to L3** ("The provider's service can only have an L3 PoP configuration"), **"Add an AZ"** (was "Add a configuration"), **"Routing rules"** (was "Add routing configuration"); "Attach a vRack", "Service keys" tab, Service key value, and Provider field confirmed. CP status ("Active" + Link/BGP status columns) live-verified → moved to category 2. **Screenshots were removed** this pass (kept only `fig-1.svg`). Remaining category-3 (3): the order funnel (website, not walked), provider-portal provisioning timing (third-party), and provider-portal troubleshooting specifics (third-party). (Static routing form labels stay old-doc-sourced — noted within category 1.)
