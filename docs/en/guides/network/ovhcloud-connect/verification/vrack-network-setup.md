{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — vrack-network-setup.mdx

- **Previous-doc source:** `ovhcloud-connect-old/occ-layer3.mdx` + `ovhcloud-connect-old/occ-direct-control-panel.mdx` (also `api.mdx` for DC config; `troubleshooting.mdx` for IP reservation rules)
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| AZ config = OVHcloud-side L3 routing instance inside the vRack | 11, 45 | previous occ-layer3 L24 "routing instance inside the L3 domain ... two devices A and B" |
| Routing instance = two physical devices labelled A and B (redundancy) | 45 | previous occ-layer3 L24 |
| One AZ configuration per AZ you want to reach | 11, 45 | previous occ-layer3 L42–43 (one L3 domain per DC; subnet not stretched) |
| First 3 usable IPs reserved by OVHcloud | 49, 52–56 | previous occ-layer3 IP Net A table; troubleshooting L150 "first three reserved" |
| .1 = VRRP virtual gateway (first usable IP) | 54 | previous occ-layer3 IP Net A table "A.B.C.1 OVHcloud virtual router (if enabled)" |
| .2 = OVHcloud router A; .3 = OVHcloud router B | 55–56 | previous occ-layer3 IP Net A table |
| VRRP provides gateway redundancy between A and B | 70 | previous occ-layer3 L86–87 |
| VRID assigned by OVHcloud (not configurable) | 75 | previous occ-layer3 L89 "VRID value is provided by OVHcloud" |
| Master device = A by default | 76 | previous occ-layer3 L90 "VRRP is master on A device" |
| One VRRP instance per AZ | 77 | previous occ-layer3 L88 "only one VRRP instance" |
| Enabling BGP on AZ disables VRRP | 78, 83 | previous occ-layer3 L96 |
| With BGP you must peer with both device A and B (≤4 BGP peers/AZ) | 83 | previous occ-layer3 L101, L103 |
| One subnet cannot be stretched between two AZs; use distinct subnets per AZ | 66, 193–194 | previous occ-layer3 L43 |
| CP path: Bare Metal Cloud > Network > OVHcloud Connect | 35 | previous occ-direct-control-panel L27 |
| /28 minimum subnet per AZ | 63, 135 | previous occ-direct-control-panel L112 "/28 or higher"; api.mdx L127 "any size from /28" |
| API: GET .../datacenter (list available AZs) | 101 | api.json route exists; previous api.mdx L103 |
| API: POST .../config/pop/{popId}/datacenter (create AZ config) | 127 | api.json route exists; previous api.mdx L122 |
| API DC params: datacenterId, ovhBgpArea, subnet | 133–135 | previous api.mdx L125–127 |
| API: GET .../config/pop (list PoP configs) | 123 | api.json route exists |
| API: DELETE .../config/pop/{popId}/datacenter/{datacenterId} | 201 | api.json route exists; previous api.mdx L177 |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| AZ subnet default gateway = VRRP virtual IP (point services at it) | 81 | previous occ-layer3 VRRP model (virtual gateway is first usable IP) |
| /28 minimum is enforced by the API | 63 | previous api.mdx L127 "any size is accepted from /28" (minimum = /28) |
| Any address range accepted (private RFC 1918 or public), must not overlap | 64–66 | Authoritative facts: addressing is NON-restrictive (any private or public range) |
| ovhBgpArea = any ASN except reserved 65501/65502/65519; must differ from customer ASN; 35540 valid | 134 | Authoritative facts + troubleshooting L159–162 |
| API: GET .../config/pop/{popId}/datacenter/{datacenterId} (verify) | 155 | api.json route exists |
| API: GET .../task/{id} (monitor task progress) | 171 | api.json route exists |
| Terraform-style / repeated POST .../datacenter per AZ for multi-AZ | 177–191 | api.json POST route exists; terraform.json `ovh_vrack_ovhcloudconnect` confirms IaC model |
| Deleting an AZ config stops private traffic to/from that AZ; remove dependent extras first | 203–205 | previous occ-direct-control-panel L179 (deleting AZ deletes routing configs) + api.mdx recursive-delete model |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| No VLAN support / no 802.1Q tagging on the vRack router; all traffic untagged | 91 | previous occ-limits lists "802.1q tag" unsupported for L3, but the per-AZ-router "no VLAN/no trunk" framing is new; router-level behaviour needs live/PM confirmation |
| No trunk support (cannot carry multiple VLANs over one trunk) | 92 | Not in previous docs; router capability claim — needs live/PM validation |
| GET .../datacenter response fields: name, region, regionType "3-AZ", available | 106–112 | `regionType`/`3-AZ`/`eu-west-gra` not in api.json/docs/manager-beta; response schema needs a live `GET .../datacenter` call. **Live-corroborated (authenticated CP):** the AZ-configuration tabs display **"3-AZ"** region badges (e.g. "Europe (Italy - Milan) 3-AZ", region code `eu-south-mil-c`), so the `regionType` = "3-AZ" concept is real; only the exact API field names remain to confirm. |
| "Only AZs where available is true can receive a new configuration" | 115 | Depends on the `available` response field above; needs live API confirmation |
| POST .../datacenter response fields: function=addDatacenterConfiguration, resourceId, status todo→doing→done | 141–149 | Task response schema/enum not in SOT cache; needs live API |
| Verify response fields: id/datacenterId/subnet/ovhBgpArea/status | 160–166 | DC GET response schema not in SOT cache; illustrative — needs live API |

## Summary
- Category 1: 20 · Category 2: 8 · Category 3: 6
- Notes: The IP-addressing and VRRP core (first-3-reserved, .1 gateway / .2 A / .3 B, one VRRP instance/AZ, VRID by OVHcloud, master A, BGP-disables-VRRP) is a faithful, verifiable carryover from occ-layer3, and all API routes exist in api.json. Category-3 is concentrated in (a) the new "no VLAN / no trunk" per-router limitation framing and (b) example API response-body schemas — including the `regionType`/`3-AZ`/`available` datacenter fields, which are absent from every SOT source and need live API or PM confirmation.
