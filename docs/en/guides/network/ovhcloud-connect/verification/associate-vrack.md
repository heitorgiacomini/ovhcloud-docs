{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — associate-vrack.mdx

- **Previous-doc source:** ovhcloud-connect-old/occ-direct-control-panel.mdx (Step 1 "Associating a vRack") + ovhcloud-connect-old/api.mdx (Step 1 "Configuring vRack")
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| CP nav path: Bare Metal Cloud > Network > OVHcloud Connect | 29, 37 | previous occ-direct-control-panel line 27 (same nav path) |
| Select the OVHcloud Connect service, click "Attach a vRack", select an existing vRack, confirm | 38-40 | previous occ-direct-control-panel line 33: "Attach a vRack" button + select existing vRack from drop-down |
| vRack association is a prerequisite for L2/L3 configuration | 11 | previous api.mdx line 30: "As a mandatory first step, the service must be interconnected with a vRack to enable the configuration" |
| API GET /vrack/{serviceName}/ovhCloudConnect returns eligible services | 50, 65 | previous api.mdx line 34 (same GET call); SOT api.json endpoint exists |
| API POST /vrack/{serviceName}/ovhCloudConnect associates OCC with the vRack (params: vRack name + OCC UUID) | 61-63 | previous api.mdx line 39 + line 42 (same POST call, same params); SOT api.json endpoint exists |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Traffic stays private and never touches the public internet | 21 | Authoritative/product fact: OCC is a private link; consistent across previous docs (no VPN over internet) |
| vRack service is free to create | 26 | ovhcloud.com: vRack is provided free of charge |
| Terraform resource ovh_vrack_ovhcloudconnect with args service_name and ovh_cloud_connect | 70-73 | SOT terraform.json: resource exists with exactly service_name + ovh_cloud_connect (both required) |
| VLAN ID in the OCC PoP configuration should match the VLAN used by resources in the vRack | 83 | Standard vRack/VLAN consistency requirement; consistent with occ-layer3 vRack VLAN model |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Alternative association from the vRack page: Network > vRack > select vRack > "Add a service" > find OVHcloud Connect > "Add" | 45 | vRack-page "Add a service" flow not in the previous OCC docs; button labels not in manager-beta cache for this path — needs live manager confirmation |
| Removal flow: Network > vRack > select vRack > find OCC service > "Remove" > confirm | 90-93 | vRack-page "Remove" flow/labels not in previous OCC docs or manager-beta cache — needs live manager confirmation |
| "Association is typically effective within a few minutes" | 42 | Timing claim not in old docs/SOT — operational, needs live confirmation |

## Summary
- Category 1: 5 · Category 2: 4 · Category 3: 3
- Notes: Strong carryover — the core "Attach a vRack" CP step and both vRack API calls come straight from the previous Direct CP and API guides (category 1), and the Terraform resource is confirmed in SOT. The vRack-page alternative/removal flows and the timing claim are the only items needing a live manager walk (category 3).
