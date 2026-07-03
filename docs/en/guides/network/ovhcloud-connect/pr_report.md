{/*
NOTE: This is an internal PR/review report, not a published guide. It has no frontmatter on
purpose and must not be added to the sidebar. Delete before merge or keep out of the build.
*/}

# OVHcloud Connect — Fact-Check & Correction Report (verified)

Full fact-check of the OVHcloud Connect (OCC) documentation revamp against every source of truth,
followed by correction of all confirmed issues and an **independent verification pass**. The revamp's
intent (expand and modernise the docs) is preserved — expanded content that is **true** was kept;
only fabrications and contradicted facts were removed or corrected.

- **Run date:** 2026-07-03
- **Guides audited:** 27 `*.mdx` under `docs/en/guides/network/ovhcloud-connect/`
- **Status:** ✅ All confirmed issues corrected and verified. See residual/live-check items at the end.

## Sources of truth

| Source | Used for |
|---|---|
| Previous documentation (`docs/en/guides/network/ovhcloud-connect-old/`, 12 guides) | Ground truth for CP labels, IP/ASN/BGP rules, diagnostics, delivery |
| SOT cache (`.claude/skills/_shared/SOT-cache/`: `api.json`, `manager-beta.json`, `terraform.json`, `docs.json`) | API endpoints, Manager labels, Terraform resources, link/slug validity |
| **OCC contract** (Conditions Particulières – OVHcloud Connect, v. 28/09/2020) | SLA, penalties/service credits, term, delivery |
| **ovhcloud.com** (`/fr/network/ovhcloud-connect/`) | Bandwidth tiers, provider partner list, L2/L3, headline SLA |

## Authoritative values (reference)

- **L2/L3**: Direct = L2 **and** L3; Provider = **L3 only**.
- **ASN**: OVHcloud-side reserved per region — **65501 Europe / 65502 Canada / 65519 Asia** (never "35540"). Customer ASN: **64512–65534** or a public ASN. Known issue: **do not use AS65501**.
- **IP addressing**: PoP link **/30**; AZ/DC **/28** (first 3 IPs reserved: `.1` VRRP virtual gateway = first usable IP, `.2`/`.3` OVHcloud routers A/B).
- **BGP**: 1 session/PoP (no eBGP multihop); ≤4 peers/DC; ≤100 prefixes/session; **BFD on by default**; **ECMP auto with 2+ PoPs (≤4 paths)**; **AS-path prepend = customer-side only**, use **MED** for OVHcloud/inbound; enabling BGP disables VRRP; no BGP+static mix in one DC.
- **Bandwidth**: Direct **1 / 10 / 100 Gbps**; Provider **50 Mbps – 50 Gbps**. Jumbo frames up to **9000 bytes**. IPv6 **not supported** on L3.
- **SLA (contract, config-based)**: 1 conn = no commitment · 2 conn/1 PoP = no commitment · 2 conn/2 PoPs (HA L1) = **99.9%** · 4 conn/2 PoPs/2 DCs (HA L2) = **99.99%**. Service credits 10/20/30%, capped 30%/month, claim within 1 month. Scope: PoP→Datacenter only (excludes provider Virtual Circuit); availability only (no latency/response-time SLA).
- **Diagnostics**: L3 = Default / Routes / Advertised-Routes; L2 = MAC Address. Retention 7 days; max 10/type/service/24h. No uptime dashboard or alerting feature.
- **Providers** (ovhcloud.com): Digital Realty, Colt, Console Connect, Megaport, Equinix, InterCloud/BSO, Orange Business Services, RISQ. Use "**service key**".
- **CP navigation**: `Bare Metal Cloud` > `Network` > `OVHcloud Connect` > select solution.
- **Vendors**: no Juniper/Cisco/SD-WAN anywhere (all fabricated in the revamp; removed).

## Corrections applied (by theme)

1. **Vendor content removed** — all Juniper & Cisco router config, `show`-command blocks, and residual bare Cisco commands (`show ip bgp summary`, `show interfaces`, …) replaced with vendor-neutral guidance. Files: l3-bgp, l3-static, troubleshooting, monitor, incident-followup, resilient-architecture, occ-direct-control-panel-setup, simple-architecture, faq.
2. **SD-WAN removed** — every reference incl. overlay/underlay + the fabricated resilient Cisco BGP block + SD-WAN diagram. Files: providers, simple-architecture, resilient-architecture.
3. **ASN 35540 → region reserved ASNs** (65501/65502/65519, + "don't use 65501" caveat); customer ASN examples moved into 64512–65534. Files: l3-bgp, l3-static, vrack-network-setup, troubleshooting, faq, architecture guides.
4. **SLA re-tiered to the contract** (config-based table + real service-credit ladder; removed invented latency/response-time SLA and uptime-dashboard/alerting claims). Files: slas, faq, glossary, simple-architecture, resilient-architecture, incident-followup.
5. **Bandwidth scoped by offer** (Direct 1/10/100 Gbps; Provider 50 Mbps–50 Gbps). Files: glossary, providers, order-provider, faq, architecture.
6. **BGP facts corrected** — BFD on by default; ECMP auto with 2+ PoPs; AS-path prepend customer-side only + MED; VRRP virtual gateway = first usable IP; AZ /28 first-3-IPs reserved; `ovhBgpArea` is the region ASN (not auto-assigned); prerequisite AZ/datacenter step noted. Files: l3-bgp, l3-static, vrack-network-setup, multi-az, resilient-architecture.
7. **Invented numbers removed** — MTU 1500/1440, hold-time 90 s, convergence 30–90 s, "4000 routes", "16 services per PoP" quota, per-PoP 100 Gbps availability columns. Files: limits, troubleshooting, faq, pop-locations-regions, resilient-architecture.
8. **CP instructions restored & fixed** — real config steps (Attach a vRack → PoP /30 → AZ /28 → routing BGP/Static) added to both `*-control-panel-setup` guides and to l3-bgp/l3-static; CP nav path corrected (`Bare Metal Cloud`) in all guides; fabricated CP "order wizard" removed from order-direct/order-provider; `Attach a vRack` made primary in associate-vrack; "service key" used consistently.
9. **L2/L3 wording** — dropped "Direct only" from the L2 heading; added a "Supported network layers" column to the introduction table.
10. **Diagrams** — 3 ASCII topology diagrams fact-checked and redrawn as SVGs (l3-bgp, l3-static, vrack-network-setup); fabricated SD-WAN/foreign-cloud SVGs removed.
11. **Foreign-cloud content** — AWS/Azure/GCP sections in the architecture guides kept but marked with a third-party callout; OVHcloud-specific invented numbers inside them corrected.
12. **Providers** — kept all legitimate partners; stripped unverifiable marketing metrics; "pairing key" → "service key".
13. **Terraform** — removed the unverified provider version floor (`>= 2.7.0`).

## Per-guide verification result

| Guide | Result | Key corrections |
|---|---|---|
| overview | ✅ Clean | none needed |
| introduction | ✅ Clean | L2 heading + supported-layers column |
| glossary | ✅ Clean | bandwidth scoped; SLA tied to config |
| providers | ✅ Clean | service key; metrics stripped; SD-WAN removed; roster verified |
| pop-locations-regions | ✅ Clean | removed fabricated bandwidth columns; region-mapping caveat |
| multi-az | ✅ Clean | AS-path/MED caveat; "recommended" |
| slas | ✅ Clean | contract-based SLA + service-credit ladder + scope |
| limits | ✅ Clean | removed "16 services" quota |
| l3-bgp | ✅ Clean | vendor removed; ASN fixed; CP+API sections; SVG; prerequisite note |
| l3-static | ✅ Clean | vendor removed; ASN fixed; VRRP first-IP; CP+API; SVG |
| order-direct | ✅ Clean | order-wizard removed; website order; delivery/term aligned |
| order-provider | ✅ Clean | order-wizard removed; service key; provider portals collapsed |
| cancel-direct | ✅ Clean | CP nav; autorenew flow (contract-validated) |
| cancel-provider | ✅ Clean | CP nav; provider portal softened |
| associate-vrack | ✅ Clean | `Attach a vRack` primary; CP nav |
| vrack-network-setup | ✅ Clean | 3-IPs reserved; VRRP first-IP; `ovhBgpArea`; `/task/{id}`; SVG |
| occ-direct-control-panel-setup | ✅ Clean | real CP config steps; vendor CLI removed; CP nav |
| occ-provider-control-panel-setup | ✅ Clean | real L3 CP config steps; service key; CP nav |
| monitor | ✅ Clean | diagnostic type "Default"; removed invented dashboards/alerts/thresholds |
| troubleshooting | ✅ Clean | vendor removed; ASN/BFD/MTU/hold-time fixed |
| incident-followup | ✅ Clean | vendor removed; service credits aligned to contract |
| cross-connect-loa | ✅ Clean | SC/PC connector; LOA delivery softened; lead-times removed |
| logs-forwarding | ✅ Clean | (was already accurate) CP nav |
| automation | ✅ Clean | Terraform version floor removed |
| faq | ✅ Clean | ASN; multi-cloud neutralised; SLA; BFD; bandwidth; IPv6; MTU |
| simple-architecture | ✅ Clean | SD-WAN removed; third-party callouts; SLA/bandwidth/ASN fixed |
| resilient-architecture | ✅ Clean | vendor/SD-WAN removed; ECMP/AS-path/MED/SLA/constraints fixed; third-party callouts |

**Verification method:** mechanical token/MDX sweep (0 Juniper/Cisco/SD-WAN/35540/invented-number hits in guides; all code fences, `:::` callouts and `<Tabs>` balanced) + three independent read-only verification agents cross-checking every guide against the sources above. All flagged residuals (`ovhBgpArea` in vrack-network-setup; bare Cisco commands in troubleshooting/faq/simple-architecture) were fixed in this pass.

## Residual items (need a live Manager or a product decision — not fabrications)

- **CP button for opening the PoP config on Provider** — previous docs disagree (Direct: "Add a PoP configuration" button; Provider: "cogwheel"). Kept the consistent "Add a PoP configuration"; confirm against the live Manager.
- **PacketFabric** — present in the Manager partner enum but not on ovhcloud.com; not added to `providers` (decide whether to include).
- **Diagram SVGs are EN-only** — the three new topology SVGs have text baked in; add localized variants if/when the guides are translated.
- **`cross-connect-loa` "Download LOA"** — the `/loa` API endpoint exists; the exact CP control/label was unverified and softened.
- **Per-PoP low-latency region mapping** (`pop-locations-regions`) — kept with an "indicative" caveat; confirm exact PoP→region pairings if a definitive source exists.

## Notes

- No fabricated **API endpoints** were found at any point — all referenced routes exist in `api.json`; the Terraform `ovh_vrack_ovhcloudconnect` resource is correct.
- The `ovhcloud-connect-old/` reference folder and this report should be **excluded from the published build** (the report carries an MDX comment header and no frontmatter; keep it out of the sidebar).
