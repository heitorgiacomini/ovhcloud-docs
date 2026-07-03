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
| PoP configuration menu: "Add a PoP configuration", select L3 | 59 | previous occ-provider-control-panel line 57 (L3 PoP config) |
| L3 PoP fields: Customer ASN, OVHcloud ASN, Subnetwork in /30 | 61-65 | previous occ-provider-control-panel lines 63-67 (identical table) |
| AZ configuration: "Add a configuration", select availability zone | 69 | previous occ-provider-control-panel line 77 (same button + AZ drop-down) |
| L3 AZ fields: OVHcloud ASN (may differ from PoP), /28 subnetwork (or larger) | 69-74 | previous occ-provider-control-panel lines 83-86 (identical table) |
| Routing: "..." button on AZ > "Add routing configuration"; choose BGP or Static | 78 | previous occ-provider-control-panel lines 98-102 (same buttons, same types) |
| BGP routing fields: Customer ASN, IP Neighbour (within AZ subnetwork) | 80 | previous occ-provider-control-panel lines 108-111 (identical) |
| Static routing fields: Network Focus (CIDR prefix), Next hop (gateway IP in range) | 81 | previous occ-provider-control-panel lines 117-120 (same fields; old doc labels this "Subnetwork") |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Provider is provider-managed; no need to be co-located with OVHcloud | 9 | Authoritative facts / product model: Provider builds the link via virtual circuit |
| Router must support BGP peering | 17 | Authoritative facts: Provider = L3 only (BGP peering required) |
| Order Provider: choose provider, PoP location, bandwidth; OVHcloud generates a service key | 28-31 | website order flow + Authoritative facts (delivery: Provider = service key emailed); order-provider guide |
| BGP peering between your (or provider's) router and OVHcloud PoP | 85 | Authoritative facts: Provider L3 BGP; occ-layer3 |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Order step "Select OVHcloud Connect Provider" as a CP action | 28 | Ordering is a website funnel (per order-provider), not a CP action; needs live confirmation |
| Provisioning "usually fast (minutes to hours for on-demand providers)" | 43 | Provider-portal-specific timing; no OVHcloud source — needs live/provider confirmation |
| Track status "in both OVHcloud Control Panel and provider's portal"; connection statuses "Active"/"Down"/"Pending" | 45, 93, 103-104 | Exact CP/provider status strings not in old docs/manager-beta cache — needs live confirmation |
| Troubleshooting specifics (service-key-entry validation, provisioning-delay behaviour, latency/packet-loss checks) | 103-106 | Provider-portal + operational diagnostics; no OVHcloud source — needs live test |

## Summary
- Category 1: 11 · Category 2: 4 · Category 3: 4
- Notes: Near-verbatim carryover of the Provider CP configuration flow — all CP steps, buttons, and L3 field tables (Attach a vRack, Add a PoP configuration L3, /30, /28, Add routing configuration, BGP/Static) match the previous occ-provider-control-panel guide (category 1). New content is the ordering/service-key wrapper (verifiable) plus provider-portal timing and CP/provider status strings that need a live walk (category 3).
