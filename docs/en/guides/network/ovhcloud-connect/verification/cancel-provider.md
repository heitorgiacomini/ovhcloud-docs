{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — cancel-provider.mdx

- **Previous-doc source:** none (new guide) — no previous cancellation guide. CP nav path and config-removal terms cross-reference occ-provider-control-panel.
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| CP nav path: Bare Metal Cloud > Network > OVHcloud Connect | 18 | previous occ-provider-control-panel line 37 (same nav path) |
| vRack association can be removed/dissociated in the CP | 24 | previous occ-provider-control-panel §Step 2 "Attach a vRack" (removal is the inverse) |
| PoP/BGP configuration can be deleted | 25 | previous occ-provider-control-panel lines 158-167: "Delete configuration" cascades to AZ and routing |
| Provider connection uses a provider-operated virtual circuit (service key flow) | 9, 38, 53 | previous occ-provider-control-panel §Step 1: provider portal + service key provisions the circuit |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Cancellation via My offers and services (autorenew/services) → "..." → "Cancel my subscription" | 30, 31 | Standard OVHcloud manager billing/autorenew cancellation flow; /#/billing/autorenew/services canonical path |
| OCC Provider spans two separately billed contracts (OVHcloud subscription + provider circuit) | 9, 51 | Consistent with order-provider billing model; standard provider two-contract structure |
| Cancelling one side does not cancel the other; provider may keep billing if the circuit stays up | 9, 36, 51 | Logical consequence of the two-contract model; consistent across order/cancel provider guides |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Cancel the virtual circuit / connection in the provider's portal | 38, 45, 53 | Provider-portal-specific procedure; no OVHcloud source — needs provider docs / live confirmation |
| Provider terms: minimum commitment, notice periods, early termination fees | 14 | Provider-contract-specific; no OVHcloud source |
| OVHcloud commitment period and billing cycle for cancellation | 15, 32 | OCC Provider billing-cycle/effective-date behaviour not documented; needs PM/billing confirmation |
| Confirmation/effective cancellation date behaviour | 32 | Cancellation UI behaviour not in old docs/manager-beta cache; needs live manager walk |

## Summary
- Category 1: 4 · Category 2: 3 · Category 3: 4
- Notes: New guide, no previous cancellation equivalent. The service-key/provider-circuit context and CP nav carry over (category 1); the manager autorenew flow and two-contract billing are verifiable (category 2). Provider-portal cancellation steps and billing-cycle specifics need live/PM validation (category 3).
