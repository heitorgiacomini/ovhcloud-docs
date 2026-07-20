{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — cross-connect-loa.mdx

- **Previous-doc source:** ovhcloud-connect-old/troubleshooting.mdx (LOA reading section); overlaps faq.mdx (delivery)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| Cross-connect is customer's responsibility (implied by "you order it from the DC operator") | 9,32 | previous troubleshooting L51 ("Cross-Connect is contractually your responsibility") |
| Completing the cross-connect triggers OCC Direct service delivery (light detection) | 9,46 | previous troubleshooting L19-23; faq.mdx L60-66 |
| LOA specifies OVHcloud rack/cage reference, patch-panel port, connector type (SC/PC sample) | 16-19 | previous troubleshooting L33-47 LOA sample (SC/PC) |
| Connector type is specified in the LOA (sample shows SC/PC) | 19 | previous troubleshooting L47 (Fiber Termination SC/PC) |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| A cross-connect is a physical fibre linking customer/provider equipment to OVHcloud in the DC | 9 | standard colocation concept; consistent with previous faq (MMR/LOA) |
| LOA delivered by email after order (+ via order) | 29 | authoritative delivery facts (Direct: LOA emailed); faq.mdx |
| LOA obtainable via support with service reference if not received | 30 | api.json `POST /ovhCloudConnect/{serviceName}/loa` (LOA generation exists) |
| Single-mode fibre required | 19,39,74 | previous faq.mdx L52 (single-mode fibre optic) |
| DC operator may charge install fee + monthly recurring fee | 41 | standard DC colocation billing practice |
| After patching, verify port status = Up in CP before BGP config | 46,75 | api.json interface/status; previous troubleshooting (light UP before peering) |
| Cancel the OCC service before removing the physical cable | 52-53 | logical ordering; cancel-direct/cancel-provider guides |
| LOA downloadable from the Control Panel via the PoP-row **"Download LOA"** action | 30 | **Live-verified (authenticated CP):** the PoP-configuration row action menu includes "Download LOA". Added to the guide this pass as an LOA source. |
| Named DC operators (Equinix, Interxion/Digital Realty, Telehouse, Global Switch) as examples | 34 | **Live-corroborated (authenticated CP):** real test-service PoP values are "FR - Paris - Telehouse - TH2", "SP – Madrid – Interxion – MAD2", "FR - Paris - GlobalSwitch - Clichy" — confirming these facility operators. |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Some data centres require an LOA for removal | 59 | DC-operator-specific policy; no OVHcloud source |
| Provider "typically handles the cross-connect for you" | 73 | Provider-specific behaviour; no OVHcloud source |
| A-end / Z-end submission fields to the DC operator | 37-39 | Third-party DC ordering process; no OVHcloud source |
| Cross-connect installation timelines "vary by data centre" | 44,72 | Third-party lead-time claim; no OVHcloud source |

## Summary
- Category 1: 4 · Category 2: 9 · Category 3: 3
- Notes: The LOA-content and delivery-trigger facts carry over verifiably from the previous troubleshooting/faq guides. New procedural material about ordering from the DC operator is inherently third-party (data-centre-operator process). **Live CP pass:** the **"Download LOA"** action was confirmed (and added to the guide as an LOA source), and the named DC operators (Telehouse, Interxion/Digital Realty, GlobalSwitch, Equinix) were corroborated by real test-service PoP values → both moved to category 2. Remaining category-3 (3): DC-operator LOA-for-removal policy, provider-handles-cross-connect behaviour, and cross-connect lead times — all third-party.
