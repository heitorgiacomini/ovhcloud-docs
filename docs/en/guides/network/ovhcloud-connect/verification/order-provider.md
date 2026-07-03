{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — order-provider.mdx

- **Previous-doc source:** ovhcloud-connect-old/occ-provider-control-panel.mdx (Step 1 "Ordering your solution" covers the service-key flow; ordering funnel, bandwidth, billing are otherwise new)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| Provider is always a Layer 3 service | 9, 18 | Authoritative facts: Provider = L3 only; previous occ-provider-control-panel line 52 (requires L3) |
| After ordering you receive a service key (emailed) | 26, 40 | previous occ-provider-control-panel line 29: "order confirmation via email, along with a service key" |
| Enter the service key in the provider's portal, then create the connection to OVHcloud | 34, 41 | previous occ-provider-control-panel lines 31-33: go to provider portal, enter service key, confirm order |
| Status changes to "Active" in the Control Panel once provisioned | 42 | previous occ-provider-control-panel line 33: status changes to "Active" |
| Provider is L3, so you need an ASN and peering IPs for BGP | 18 | Authoritative facts: Provider = L3 only; previous occ-provider-control-panel L3 PoP config (Customer ASN, /30) |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| OCC Provider is ordered from the OVHcloud website, not the Control Panel | 24 | Authoritative facts (delivery: Provider = service key emailed); order flow on website |
| Provider bandwidth ranges from 50 Mbps to 50 Gbps (options vary by provider) | 17, 20 | website: Provider bandwidth 50 Mbps–50 Gbps |
| The service key identifies your order and lets the provider provision the connection | 26, 40 | Authoritative facts (delivery: Provider = service key emailed); previous occ-provider-control-panel §Step 1 |
| OVHcloud bills you monthly for the OCC Provider service | 47 | contract/website billing model |
| Provider bills separately for their virtual circuit | 48 | Standard two-contract provider model; consistent with cancel-provider two-side model |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| Website order steps: "Select the OVHcloud Connect Provider offer, choose PoP location and bandwidth, complete the order" | 24 | Website order-funnel UI/labels not in old docs or SOT; needs live website walk |
| "Provider provisions the link (virtual or physical)" then "OVHcloud activates the connection" sequence | 40-42 | Provider-side provisioning behaviour is provider-portal-specific; no OVHcloud source — provider procedure, needs live confirmation |

## Summary
- Category 1: 5 · Category 2: 5 · Category 3: 2
- Notes: The service-key flow and L3-only nature carry over cleanly from the previous provider CP guide (category 1). New content (website funnel, bandwidth 50 Mbps–50 Gbps, billing) is verifiable except the exact website labels and provider-portal specifics.
