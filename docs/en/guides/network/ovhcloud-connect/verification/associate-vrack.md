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
| Alternative association from the vRack page (vRack private network > Manage your vRack > select the OCC service under "Your eligible services" > Add) | 44-45 | Confirmed via live Manager (screenshot from docs owner) |
| Removal from the vRack page (Manage your vRack > select the OCC service in "Your vRack" > Remove) | 85-92 | Confirmed via live Manager (screenshot from docs owner) |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
_None — the "few minutes" timing claim was removed from the guide. It is unverifiable and not contractually defined; the OCC contract (Art. 4) states delivery times are non-guaranteed objectives._

## Summary
- Category 1: 5 · Category 2: 5 · Category 3: 0
- Notes: Fully reconciled. Core "Attach a vRack" CP step and both vRack API calls carry over from the previous Direct CP/API guides (category 1); Terraform resource confirmed in SOT. The vRack-page add/remove flows were confirmed against the live Manager (category 2). Removed: the VLAN "consistency" claim (not in the previous docs; vRack is Layer 2 and does not manage VLANs) and the "few minutes" timing claim (unverifiable; contract Art. 4 makes delivery times non-guaranteed).
