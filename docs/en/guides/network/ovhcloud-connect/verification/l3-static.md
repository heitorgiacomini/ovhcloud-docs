{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — l3-static.mdx

- **Previous-doc source:** `ovhcloud-connect-old/occ-layer3.mdx` + `ovhcloud-connect-old/occ-direct-control-panel.mdx` + `ovhcloud-connect-old/api.mdx`
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| L3 static involves PoP configuration + AZ extra (network) configuration | 13–14 | previous api.mdx steps 2–3 + "static route" option L131–140 |
| Static route defined by next-hop IP + destination subnet | 47, 65 | previous occ-direct-control-panel L143–146 (Network Focus + Next hop); api.mdx L138–140 |
| CP path: Bare Metal Cloud > Network > OVHcloud Connect | 40, 55 | previous occ-direct-control-panel L27 |
| CP button "Attach a vRack" | 57 | previous occ-direct-control-panel L33 |
| CP "Add a PoP configuration"; select L3; Customer ASN + OVHcloud ASN + /30 | 58 | previous occ-direct-control-panel L67, L73–77 |
| CP "Add a configuration" for AZ; OVHcloud ASN + /28 (or higher) | 59 | previous occ-direct-control-panel L103, L109–112 |
| CP "..." > "Add routing configuration"; choose Static; Network Focus + Next hop | 60–65 | previous occ-direct-control-panel L124, L141–146 |
| Multiple static routes can be added in the same AZ | 67, 164–166 | previous occ-direct-control-panel L150 |
| With static routing VRRP remains active (devices A/B share virtual gateway) | 140–141 | previous occ-layer3 L86–96 (VRRP in DC; BGP disables it → static keeps it) |
| VRRP virtual gateway = first usable IP of AZ /28; routers A/B take next two; first 3 reserved | 141 | previous occ-layer3 IP Net A table (.1 gateway, .2 router A, .3 router B); troubleshooting L150 "first three reserved" |
| /30 peering subnet; first IP OVHcloud, second yours | 37, 93, 129–130 | previous occ-layer3 IP Net B table; api.mdx L90 |
| Static routing supported at DC/AZ (VRRP configured; static routes possible) | 132 | previous occ-layer3 L92; api.mdx L129 "next steps for static routing" |
| API: GET .../interface | 77 | api.json route exists; previous api.mdx L57 |
| API: POST .../config/pop (L3) with interfaceId, type, customerBgpArea, subnet | 84, 88–93 | api.json route exists; previous api.mdx L83–90 |
| API: POST .../config/pop/{popId}/datacenter/{datacenterId}/extra (network) | 144 | api.json route exists; previous api.mdx L135 |
| API extra (network) params: type=network, nextHop, subnet | 149–152 | previous api.mdx L138–140 |
| API: DELETE .../extra/{extraId} and DELETE .../config/pop/{popId} | 252, 254 | api.json routes exist; previous api.mdx L172, L182 |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Static routing: no automatic failover; manual route updates; no ECMP/load balancing | 26–27, 241–243 | Universal routing standard (static routes are non-dynamic; no reconvergence/ECMP) |
| BGP reconverges automatically / dynamic route updates (comparison table) | 26–27 | Universal BGP standard |
| Customer ASN: public or private 64512–65534 (still required for L3 PoP peering) | 92 | previous occ-layer3 L98; RFC 6996 private ASN range |
| /30: first IP OVHcloud (.1), second your router (.2) | 93, 129–130 | previous occ-layer3 IP Net B table |
| First 3 IPs of the /28 reserved for OVHcloud | 141 | Authoritative facts + troubleshooting L150 |
| API: GET .../config/pop/{popId} | 108 | api.json route exists |
| API: GET .../config/pop/{popId}/datacenter/{datacenterId}/extra/{extraId} | 178 | api.json route exists |
| API: GET .../config/pop/{popId}/datacenter/{datacenterId}/extra (list) | 196 | api.json route exists |
| API: GET .../interface/{id}/status | 223 | api.json route exists |
| API: GET .../config/pop/{popId}/status | 227 | api.json route exists |
| API: POST .../diagnostic | 231 | api.json route exists |
| Static routing not recommended for multi-AZ (use BGP) | 244 | Consistent with previous occ-layer3 multi-DC/BGP resilience model |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| PoP GET response example fields (id/interfaceId/customerBgpArea/ovhBgpArea/subnet/status) | 114–122 | Response-body schema not in SOT api.json (routes only); illustrative — needs live API |
| Extra (network) GET response fields (id/type/bgpNeighborArea/bgpNeighborIp/nextHop/subnet/status) | 183–191 | Extra GET response schema not in SOT cache; needs live API confirmation |
| Diagnostic enum names: diagPeering, diagPeeringExtra, diagRoutes, diagMacs | 234 | Not in api.json / manager-beta / docs; previous diagnostics guide uses Default/Routes/Advertised-Routes/MAC Address — needs live API/PM validation |
| Verify-connectivity expected outputs (traceroute via 192.0.2.1, ping reply) | 213–217 | Illustrative example values; environment-specific — needs live test |

## Summary
- Category 1: 20 · Category 2: 12 · Category 3: 4
- Notes: Clean carryover of the CP static-routing procedure, /30 and /28 IP rules, VRRP-remains-active-with-static behaviour, and the network extra params. All API routes verified in api.json. Category-3 items are limited to example response-body schemas (not stored in the SOT cache) and the diagnostic enum spellings that diverge from the previous UI labels. The static-vs-BGP comparison table is standard networking knowledge.
