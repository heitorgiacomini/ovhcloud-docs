{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — l3-bgp.mdx

- **Previous-doc source:** `ovhcloud-connect-old/occ-layer3.mdx` + `ovhcloud-connect-old/occ-direct-control-panel.mdx` + `ovhcloud-connect-old/api.mdx` (also `troubleshooting.mdx` for ASN rules)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| L3 has two levels: PoP configuration + AZ (DC) configuration | 13–14 | previous occ-layer3 "PoP/EntryPoint and DC/EndPoint"; api.mdx steps 2–3 |
| eBGP session between customer router and OVHcloud at the PoP | 13, 35 | previous occ-layer3 "BGP is mandatory in a PoP" |
| /30 peering subnet for the PoP link; first IP OVHcloud, second yours | 53, 84, 123–124 | previous occ-layer3 IP Net B table (/30, .1 OVHcloud, .2 customer); api.mdx "subnet: a /30 IPv4 block" |
| /28 subnet (or larger) from vRack for the AZ | 55 | previous occ-direct-control-panel "/28 or higher"; api.mdx "any size accepted from /28" |
| CP path: Bare Metal Cloud > Network > OVHcloud Connect | 29, 44 | previous occ-direct-control-panel L27 identical navigation |
| CP button "Attach a vRack" (associate a vRack) | 46 | previous occ-direct-control-panel L33 "Attach a vRack" |
| CP button "Add a PoP configuration"; select L3 | 47 | previous occ-direct-control-panel L57/L67 |
| PoP L3 inputs: Customer ASN, OVHcloud ASN, /30 subnetwork | 49–53 | previous occ-direct-control-panel table L73–77 |
| CP button "Add a configuration" for AZ; enter OVHcloud ASN + /28 | 55 | previous occ-direct-control-panel L103/L109–112 |
| CP "..." > "Add routing configuration"; choose BGP; Customer ASN + IP Neighbour | 56 | previous occ-direct-control-panel L124–137 |
| Customer ASN differs from OVHcloud ASN (eBGP) | 83, 125 | previous occ-layer3 L98; troubleshooting L162 |
| Reserved OVHcloud ASNs 65501 (EU) / 65502 (CA) / 65519 (Asia) | 83, 125 | previous troubleshooting L159–161 |
| Enabling BGP at AZ level disables VRRP | 141 | previous occ-layer3 L96; api.mdx L144 |
| Must peer with both device A and device B (≤4 BGP peers/AZ) | 141 | previous occ-layer3 L103 + L101 |
| BFD activated by default on all sessions; recommended on your side | 141 | previous occ-layer3 L104 |
| ECMP auto with 2+ PoPs; AS-path prepend and/or MED for path selection | 222 | previous occ-layer3 L100, L116, L124 |
| AS-path prepending is customer-side only; MED is OVHcloud-side alternative (lower preferred) | 222 | previous occ-layer3 L122 "AS path prepending is not configurable on OVHcloud devices"; L124 MED alternative |
| API: GET /ovhCloudConnect/{serviceName}/interface | 68 | api.json route exists; previous api.mdx L57 |
| API: POST /ovhCloudConnect/{serviceName}/config/pop | 74 | api.json route exists; previous api.mdx L83 |
| API PoP params: interfaceId, type, customerBgpArea, ovhBgpArea, subnet | 79–84 | previous api.mdx L86–90 lists these exact params |
| API: POST .../config/pop/{popId}/datacenter/{datacenterId}/extra (bgp) | 144 | api.json route exists; previous api.mdx L146 |
| API extra (BGP) params: type=bgp, bgpNeighborArea, bgpNeighborIp | 149–152 | previous api.mdx L149–151 |
| API: DELETE .../config/pop/{popId}/datacenter/{datacenterId}/extra/{extraId} | 238 | api.json route exists; previous api.mdx L172 |
| API: DELETE .../config/pop/{popId} | 240 | api.json route exists; previous api.mdx L182 |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Customer ASN: public ASN or private 64512–65534 | 25, 82 | previous occ-layer3 L98 "recommended value 64512-65534"; RFC 6996 private ASN range (standard) |
| OVHcloud ASN can be any ASN except reserved region values; AS35540 valid example | 83, 125 | Authoritative facts: any ASN except 65501/65502/65519; AS35540 valid |
| /30: first IP = OVHcloud peer (.1), second = your router (.2) | 84, 123–124 | previous occ-layer3 IP Net B table (.1 OVHcloud, .2 customer) |
| API: GET .../config/pop/{popId} | 103 | api.json route exists (not in previous api.mdx) |
| API: GET .../config/pop/{popId}/status | 130 | api.json route exists |
| API: GET .../config/pop/{popId}/datacenter/{datacenterId}/extra/{extraId} | 166 | api.json route exists |
| API: GET .../config/pop/{popId}/statistics (accepted prefixes) | 206 | api.json route exists; standard BGP prefix stats |
| API: POST .../diagnostic | 212 | api.json route exists |
| BGP path selection / ECMP up to 4 paths | 222 | previous occ-layer3 L116 "up to 4 paths" |
| Troubleshooting: TCP 179 for BGP; states Active/Idle/Established | 227–232 | Universal BGP standard (well-known BGP port and FSM states) |
| API: GET .../interface/{id}/status and /statistics for link/error checks | 229, 231 | api.json routes exist |
| API: GET .../task for pending tasks | 232 | api.json route exists |
| PoP GET response schema: `id`/`interfaceId`/`type`/`customerBgpArea`/`ovhBgpArea`/`subnet`/`status` | 108–116 | **Live-confirmed** (authenticated API, `GET /config/pop/{popId}`): all 7 field names match the guide's example exactly (live sample: `{id:3369, interfaceId:257, type:"l3", customerBgpArea:333, ovhBgpArea:65001, subnet:"192.168.0.200/30", status:"active"}`). Only the illustrative values differ. |
| Extra-BGP GET response schema: `id`/`type`/`bgpNeighborArea`/`bgpNeighborIp`/`nextHop`/`subnet`/`status` | 174–183 | **Live-confirmed** (authenticated API, `GET .../datacenter/{dcId}/extra/{extraId}`): all 7 field names match exactly, including `nextHop` and `subnet` being `null` (live sample: `{bgpNeighborArea:64000, bgpNeighborIp:"10.0.5.10", id:3071, nextHop:null, status:"active", subnet:null, type:"bgp"}`). Only the illustrative values differ. |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| resourceId in POST /config/pop response is the new popId | 97 | **Cannot be verified from a techwriter's test access** — confirming it requires a mutating `POST /config/pop` (or an OCC service with an open task), and the shared OVHcloud test backend must not be mutated for a doc check. Follows the standard OVHcloud task/`resourceId` pattern; the guide no longer depends on it — it now also points to the read-only `GET .../config/pop` list to obtain the `popId`. |

## Summary
- Category 1: 25 · Category 2: 14 · Category 3: 1
- Notes: Well-grounded guide — the CP procedure, ASN rules, IP/subnet rules, VRRP-vs-BGP interaction, BFD, ECMP, and MED/AS-path facts all carry over cleanly and match the authoritative facts. All API routes exist in api.json. Fixed this pass: the fabricated diagnostic enum names (`diagPeering`/`diagPeeringExtra`/`diagRoutes`/`diagMacs`) were removed and replaced with a pointer to the verified diagnostic types (Monitor guide) + API console. The remaining category-3 items are API response-body example schemas only (the SOT cache stores routes, not request/response models) — illustrative, needing a live API call to confirm exact field names. **CP walkthrough live-verified & corrected this pass** (authenticated Manager): `Customer ASN` → **`User ASN`**; the PoP config is opened via **`Configure port`** (modal titled "Add a PoP configuration"); AZ button is **`Add an AZ`** (was "Add a configuration"); routing is added via **`Routing rules`** (was "Add routing configuration"). `IP Neighbour`, `OVHcloud ASN`, `Subnetwork in /30` and `Attach a vRack` confirmed as-written.
