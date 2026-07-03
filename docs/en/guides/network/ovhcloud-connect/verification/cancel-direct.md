{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — cancel-direct.mdx

- **Previous-doc source:** none (new guide) — no previous cancellation guide. CP nav path and config-removal terms cross-reference occ-direct-control-panel; API from api.json.
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| CP nav path: Bare Metal Cloud > Network > OVHcloud Connect | 20 | previous occ-direct-control-panel line 27 (same nav path) |
| vRack association can be removed/dissociated in the CP | 28 | previous occ-direct-control-panel: "Attach a vRack" (association exists; removal is the inverse); associate-vrack §Removing the association |
| PoP/BGP configuration can be deleted (PoP config deletion removes AZ + routing) | 29 | previous occ-direct-control-panel lines 184-193: "Delete configuration" cascades to AZ and routing |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Cancellation via My offers and services page (autorenew/services) → "..." → "Cancel my subscription" | 34, 35 | Standard OVHcloud manager billing/autorenew cancellation flow; /#/billing/autorenew/services is the canonical manager path |
| API: POST /ovhCloudConnect/{serviceName}/terminate terminates the service | 69 | SOT api.json: /ovhCloudConnect/{serviceName}/terminate exists |
| Direct = physical cross-connect owned by customer, decommissioned separately with PoP operator | 9, 17, 39-45 | Authoritative facts: Direct = customer-managed cross-connect; consistent with order-direct/cross-connect-loa |
| Some facilities require an LOA for cross-connect removal | 44 | Standard data-centre cross-connect practice; cross-connect-loa guide |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Service "renews automatically until you disable auto-renewal or request cancellation" | 9 | Auto-renew behaviour specific to OCC Direct billing terms; not in old docs/contract excerpt — needs PM/billing confirmation |
| "Cancellation typically takes effect at the end of the current billing period" | 18, 37 | Effective-date/billing-cycle behaviour for OCC cancellation not documented; needs PM/billing confirmation |
| "Minimum contract term / early cancellation may incur fees" | 16 | Depends on commitment terms; not in the contract facts provided — needs PM confirmation |
| Confirmation email sent with effective cancellation date; may be asked for a reason | 36, 37 | Cancellation UI behaviour not in old docs/manager-beta cache; needs live manager walk |

## Summary
- Category 1: 3 · Category 2: 4 · Category 3: 4
- Notes: New guide with no previous cancellation equivalent. Config-removal and CP nav carry over (category 1); the terminate API and manager autorenew flow are verifiable (category 2). Billing-cycle, auto-renew, and cancellation-UI specifics need PM/live validation (category 3).
