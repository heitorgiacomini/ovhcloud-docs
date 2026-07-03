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

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Named DC operators (Equinix, Interxion/Digital Realty, Telehouse) as examples | 34 | Illustrative operator names; Digital Realty is a listed provider, others need confirmation as DC operators |
| Some data centres require an LOA for removal | 59 | DC-operator-specific policy; no OVHcloud source |
| Provider "typically handles the cross-connect for you" | 73 | Provider-specific behaviour; no OVHcloud source |
| A-end / Z-end submission fields to the DC operator | 37-39 | Third-party DC ordering process; no OVHcloud source |
| Cross-connect installation timelines "vary by data centre" | 44,72 | Third-party lead-time claim; no OVHcloud source |

## Summary
- Category 1: 4 · Category 2: 7 · Category 3: 5
- Notes: The LOA-content and delivery-trigger facts carry over verifiably from the previous troubleshooting/faq guides. New procedural material about ordering from the DC operator is inherently third-party (data-centre-operator process), landing several rows in category 3 — expected for an LOA-ordering workflow.
