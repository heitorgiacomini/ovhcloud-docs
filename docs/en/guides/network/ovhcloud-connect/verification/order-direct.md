{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — order-direct.mdx

- **Previous-doc source:** ovhcloud-connect-old/occ-direct-control-panel.mdx (post-delivery CP config only; ordering flow, LOA, delivery/term facts are NOT in the previous CP guide — sourced from contract/website)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| Direct delivers a dedicated Layer 2 and Layer 3 connection | 9 | Authoritative facts: Direct = L2 & L3; previous occ-direct-control-panel offers both L2 and L3 PoP configs |
| After delivery the service appears in the CP for configuration (BGP, static routing, vRack association) | 11, 34, 36 | previous occ-direct-control-panel: post-delivery CP config (Attach a vRack, PoP L2/L3, routing BGP/Static) |
| CP nav path: Bare Metal Cloud > Network > OVHcloud Connect > select service | 36 | previous occ-direct-control-panel line 27 (same nav path) |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| OCC Direct is ordered from the OVHcloud website, not the Control Panel | 11, 28 | Authoritative facts (delivery: Direct); website order flow. Not in previous CP guide (which starts post-delivery) |
| Direct bandwidth options 1, 10 or 100 Gbps | 20, 28 | website: Direct bandwidth 1/10/100 Gbps |
| BGP peering needs your ASN (public or private) | 21 | Authoritative facts: any ASN allowed except reserved 65501/65502/65519; previous occ-layer3 |
| OVHcloud issues a Letter of Authorization (LOA) after order validation | 30, 58 | Authoritative facts (delivery: Direct = light OR 60 days OR manual arrangement; LOA); contract |
| Service delivered when OVHcloud detects light, or 60 days after order, or by manual arrangement | 60, 64, 66 | Authoritative facts (delivery: Direct = light OR 60 days OR manual arrangement) |
| Beyond 60 days, even without detected light, the service is considered operational | 64 | Authoritative facts (delivery); contract |
| Billed monthly; pricing depends on PoP location and bandwidth tier | 70, 71 | website/contract billing model |
| Initial term starts on effective provisioning, or 30 days after first LOA, whichever comes first | 72 | Authoritative facts: initial term = provisioning or 30 days after first LOA (Direct, contract) |
| Cross-connect fees from the data centre operator are separate/billed by operator | 73 | Standard cross-connect model; contract (OVHcloud bills only the OCC service) |
| API: GET /ovhCloudConnect lists services | 47 | SOT api.json: /ovhCloudConnect endpoints exist |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Website order steps: "select the OVHcloud Connect Direct offer, choose PoP location and bandwidth, provide contact details, complete the order" | 28 | Website order-funnel UI/labels not in any OVHcloud doc source or manager-beta cache; needs live website walk |
| "What you will need" prep list values (IP plan / peering subnet, cross-connect cage/cabinet references) as order inputs | 19-24 | Presented as order-form inputs; the order UI fields are not in old docs/SOT — needs live order flow to confirm which are actually collected |

## Summary
- Category 1: 3 · Category 2: 10 · Category 3: 2
- Notes: The previous CP guide only covers post-delivery configuration, so the entire ordering/LOA/delivery/term content is new — but almost all of it is verifiable against the contract and website (category 2). Only the exact website order-funnel labels and which prep fields are actually collected need a live walk (category 3).
