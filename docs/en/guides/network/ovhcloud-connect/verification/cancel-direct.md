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
| Service renews automatically until you disable auto-renewal | 9 | **OCC contract Art. 5**: the service "se renouvèle automatiquement… sauf résiliation" |
| Cancelling takes effect at the end of the current term (service runs to its expiration date) | 18, 39 | **OCC contract Art. 5**: disable auto-payment ≥24h before term end; service terminated at the "Date d'Expiration" |
| Committed initial term; no mid-term termination (replaces the old "early fees" wording) | 16 | **OCC contract Art. 5**: the Durée Initiale is committed and the offer cannot be modified during execution; cancellation only stops renewal |

## 3. New & not verifiable without testing
_None — the unverifiable confirmation-email / "provide a reason" UI wording was removed from the guide._

## Summary
- Category 1: 3 · Category 2: 7 · Category 3: 0
- Notes: The OCC contract (Article 5) settles the renewal/cancellation mechanics — auto-renewal, cancel-by-disabling-auto-payment ≥24h before term end, and cancellation taking effect at the end of the current term are all confirmed (category 2). The misleading "early cancellation may incur fees" wording was corrected to the contract's actual mechanic (committed term, no mid-term termination), and the "≥24h before term end" precision was added to the guide. Only the cancellation-UI email/reason behaviour still needs a live-manager walk.
