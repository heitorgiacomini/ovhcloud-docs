{/*
NOTE: This is an internal PR/review report, not a published guide. It has no frontmatter on
purpose and must not be added to the sidebar. Delete before merge or keep out of the build.
*/}

# OVHcloud Connect — Deviation & Fact-Check Report

Fact-check of the **new** OVHcloud Connect (OCC) documentation revamp against the **previous**
documentation and the authoritative sources. The goal of the revamp was to expand and modernise the
docs — this report keeps that intent and flags **only content that is false, contradicted, or
unverifiable**, so the true expansion can stay and the hallucinations can be removed.

- **Method:** every claim in the 28 new guides was cross-checked against (a) the 12 previous OCC
  guides, (b) the shared SOT cache (`api.json`, `manager-beta.json`, `terraform.json`, `docs.json`),
  (c) the **OCC contract** (Conditions Particulières — authoritative for SLA/commercial terms).
- **Run date:** 2026-07-03
- **New guides:** `docs/en/guides/network/ovhcloud-connect/*.mdx` (28 files)
- **Previous docs (reference):** `docs/en/guides/network/ovhcloud-connect-old/*.mdx` (12 files)
- **SOT cache:** `.claude/skills/_shared/SOT-cache/` (manager-beta: ok; api & terraform: preserved 2026-04-24; docs: ok)
- **Contract:** `Conditions Particulières – OVHcloud Connect`, v. 28/09/2020 (SLA, penalties, term, delivery).
- **Website:** `https://www.ovhcloud.com/fr/network/ovhcloud-connect/` (bandwidth tiers, partner list, L2/L3, SLA).

## Authoritative bandwidth & provider facts (from the OVHcloud website)

The website **resolves the bandwidth and provider questions** — and reverses several audit findings
that were based only on the previous docs / Manager enum. The expanded content here is largely
**correct**; do not delete it.

**Bandwidth tiers (guaranteed, unlimited):**

| Offer | Tiers |
|---|---|
| **OVHcloud Connect Direct** | 1 Gbps, 10 Gbps, 100 Gbps |
| **OVHcloud Connect Provider** | 50 Mbps, 100 Mbps, 200 Mbps, 500 Mbps, 1 Gbps, 2 Gbps, 5 Gbps, 10 Gbps, 25 Gbps, 50 Gbps |

→ So "50 Mbps–50 Gbps" **is accurate for Provider**; it must simply be scoped to Provider (Direct is 1/10/100 Gbps). The only real error is quoting a range **without** distinguishing the two offers.

**Provider partners (website — the commercial SOT):** Digital Realty · Colt Technology Services · Console Connect · Megaport · Equinix · InterCloud · Orange Business Services · RISQ (Québec).

→ **Orange Business Services, Digital Realty, InterCloud/BSO, and RISQ are legitimate partners** — the audit's "remove, fabricated" verdict (based on the `manager-beta` `partners.*` enum) is **overturned**. "BSO (formerly Intercloud)" in the guide is **correct** (BSO acquired InterCloud; the website's "InterCloud" is the old brand). Only open nuance: **PacketFabric** appears in the Manager enum but not on the website (keep with a note / verify). SLA "up to 99.99 %" and both L2/L3 are confirmed on the website. No Juniper/Cisco/SD-WAN on the website.

## Authoritative SLA & commercial facts (from the OCC contract)

The contract **confirms an SLA exists**, but it is tied to the **redundancy configuration** — the
new docs' "single vs redundant" tiering is wrong in the details:

| Configuration | Monthly availability SLA |
|---|---|
| 1 connection on 1 PoP | **No commitment** |
| 2 connections on 1 PoP ("Local redundant connection") | **No commitment** |
| 2 connections on 2 PoPs ("High Availability – Level 1") | **99.9 %** |
| 4 connections on 2 PoPs to 2 datacentres ("High Availability – Level 2") | **99.99 %** |

- **Penalties (service credits):** availability 99.9–99 % → 10 %; 99–95 % → 20 %; < 95 % → 30 % of the impacted service's monthly cost. Total capped at **30 %/month**; must be claimed within **1 month** of the incident ticket closure.
- **Scope:** SLA covers only the OCC service **from the OVHcloud PoP to the Datacenter**; it excludes the third-party **Virtual Circuit** (Provider). "Unavailability" = simultaneous loss of connectivity to **all** the customer's vRACKs caused by OCC infrastructure failure; performance degradation alone does not count.
- **Delivery:** delivery times shown on the website are **non-guaranteed objectives**.
- **Term/billing:** Initial term starts on effective provisioning **or 30 calendar days after the first LOA** (Direct only); auto-renews; cancel by disabling auto-payment ≥ 24 h before term — **this validates the `cancel-direct` / `cancel-provider` flow**.
- **Bandwidth:** "various bandwidth capacities are listed on the website" — the contract fixes **no** numeric range, so specific figures like "50 Mbps–50 Gbps" remain unverified.
- **Redundancy configs** named by the contract: "Local redundant connection", "High Availability – Level 1", "High Availability – Level 2" — useful canonical vocabulary for the architecture guides.

## Severity & category legend

| Severity | Meaning |
|---|---|
| **ERROR** | Contradicts the previous docs / an authoritative source, or is fabricated. Must fix. |
| **WARNING** | Unverifiable against any source; likely hallucinated (often AWS/Azure/GCP-flavoured). Verify or remove. |
| **INFO** | Cosmetic or divergent-but-plausible; low priority. |

| Category | Scope |
|---|---|
| **T-CP** | Control Panel path / button labels |
| **T-API** | API endpoints & parameters |
| **T-TF** | Terraform resources |
| **T-CC** | Conceptual / numeric claims |
| **T-LK** | Internal links |
| **T-VENDOR** | Juniper / Cisco vendor content |
| **T-SDWAN** | SD-WAN content |
| **T-SCHEMA** | Diagrams / images |

---

## Executive summary — the seven systemic problems

1. **Fabricated vendor configuration (T-VENDOR).** The previous docs contain **zero Juniper** content and only a few **Cisco** commands for *disabling autonegotiation*. The revamp added full **Juniper JunOS** and **Cisco IOS/IOS-XE/NX-OS** router configuration and `show`-command blocks across `l3-bgp`, `l3-static`, `troubleshooting`, `monitor`, `incident-followup`, `resilient-architecture`, and both `*-control-panel-setup` guides. **All of it is fabricated** and must be removed.
2. **SD-WAN (T-SDWAN).** SD-WAN appears **nowhere** in the previous docs or anywhere in the SOT cache. Every mention (`providers`, `simple-architecture`, `resilient-architecture`) is invented — including the "overlay/underlay" framing lifted from generic cloud-interconnect (AWS) material.
3. **Wrong OVHcloud peering ASN "35540" (T-CC).** Multiple guides (`l3-bgp`, `resilient-architecture`, `troubleshooting`, `faq`) state OVHcloud peers with **AS 35540**. The authoritative OVHcloud-side ASNs are the reserved **65501 (Europe) / 65502 (Canada) / 65519 (Asia)**, and **AS65501 is a documented known-bad value** ("do not use"). 35540 is OVH's *public* AS and is wrong here.
4. **Invented numbers (T-CC).** Fabricated BGP convergence times (30–90 s), bandwidth ranges (50 Mbps–50 Gbps), MTU (1500 / 1440), route limits (4000), a "16 services per PoP" quota, and per-PoP 100 Gbps availability marks — none exist in any source. True figures: link speeds 1/10/100 Gbps, jumbo up to 9000 bytes, 100 prefixes/session, 4 BGP peers/DC, 1 session/PoP. **Note:** the SLA percentages 99.9 %/99.99 % are **real** (contract) but are **mis-tiered** in the docs — they attach to redundancy *configurations* (HA Level 1/2), not to a vague "single vs redundant" split. See the SLA table above.
5. **AWS/Azure/GCP hallucination (T-CC).** `simple-architecture`, `resilient-architecture`, and `faq` carry large AWS Direct Connect / Azure ExpressRoute / GCP Interconnect procedures (Transit Gateway, ExpressRoute circuits, Partner Interconnect, pairing keys, etc.) presented as OVHcloud procedure. None is grounded in OVHcloud reality.
6. **Control Panel path wrong everywhere (T-CP).** Every guide with a CP nav line drops the top-level universe: it must be **`Bare Metal Cloud` > `Network` > `OVHcloud Connect` > select your solution**.
7. **Missing real CP instructions (T-CP).** The two guides that replace the previous CP walkthroughs — `occ-direct-control-panel-setup` and `occ-provider-control-panel-setup` — contain **none** of the actual Control Panel configuration steps (Attach a vRack, Add a PoP configuration with the **/30** subnet, Add an AZ configuration with the **/28** subnet, Add routing configuration). `order-direct` / `order-provider` invent a CP "order wizard" that does not exist (OCC is ordered on ovhcloud.com).

**Provider roster is mostly correct** (verified against the website — see the bandwidth & provider block above). Digital Realty, Colt, Console Connect, Megaport, Equinix, InterCloud, Orange Business Services, and RISQ are all legitimate partners. Remaining nuances only: the "BSO (formerly Intercloud)" naming (website says "InterCloud") and PacketFabric (in the Manager enum, not on the website). The audit's initial "remove these providers" verdict — based on the Manager enum alone — is **overturned** by the website.

**What is clean.** `overview`, `introduction`, `logs-forwarding`, and `automation` are faithful, accurate ports. `pop-locations-regions` has the correct PoP/region names (only the added bandwidth columns are fabricated). All API endpoints referenced across the set **do exist** in the cache — there are no invented API routes; the API issues are missing steps and misdescribed parameters.

---

## Per-guide findings

### overview.mdx
_Clean — faithful re-slug of the previous overview. Essentials/links resolve._ No findings.

### introduction.mdx
_Faithful concepts port._ Note the pain-point fix belongs here:
- [INFO][T-CC] line 29 — heading `### Layer 2 (L2) service - OVHcloud Connect Direct only` carries availability info in the title. **Fix (requested):** rename to `### Layer 2 (L2) service` and add a row to the "How does it work?" table (lines 24–27) stating L2/L3 support: **Direct = L2 & L3, Provider = L3 only**. (Pre-existing in old docs; corrected now.)

### glossary.mdx
- [WARNING][T-CC] line 22 — Bandwidth "from **50 Mbps to 10 Gbps**". Partly right/partly wrong vs website: Provider goes 50 Mbps–**50 Gbps**, Direct is 1/10/**100 Gbps**. The "10 Gbps" ceiling is wrong. → correct and scope by offer.
- [WARNING][T-CC] line 86 — SLA "e.g. 99.9%" example. 99.9 % is real (contract, HA Level 1) but must not be presented as a blanket figure. → tie to config or drop.

### providers.mdx  _(audit verdicts corrected against the website)_
- [OK][T-CC] lines 110–120 — **Orange Business Services** — **legitimate partner** (website). → keep; only remove the SD-WAN clause (below).
- [OK][T-CC] lines 66–76 — **Digital Realty** — **legitimate partner** (website lists it as a provider, not only a PoP operator). → keep.
- [OK][T-CC] lines 39–50 — "**BSO (formerly Intercloud)**" is **correct**: BSO acquired InterCloud (bso.co). The website's "InterCloud" is the pre-acquisition brand. → keep the guide's wording (it is more current than the website).
- [OK][T-CC] lines 122–132 — **RISQ (Québec)** — **legitimate partner** (website). → keep.
- [INFO][T-CC] — **PacketFabric** is in the Manager `partners.*` enum but not on the website; **Colt** is present on both. → optionally add PacketFabric with a note; not an error.
- [ERROR][T-SDWAN] line 114 — Orange "…including **SD-WAN**…". → remove the SD-WAN clause (no SD-WAN anywhere authoritative).
- [OK→scope][T-CC] line 27 — "bandwidth… typically from **50 Mbps to 50 Gbps**". **Correct for Provider** (website). → keep, but scope it to Provider (Direct is 1/10/100 Gbps).
- [WARNING][T-CC] lines 56, 82, 96 — vendor marketing metrics ("2,900 clouds", "700 data centres", "166 countries"…). Still unverified against any OVHcloud source and drift-prone. → strip specifics; link to provider pages.
- [WARNING][T-CC] lines 136–139 — "pairing key" should be "**service key**" (contract/old FAQ term); align with Provider = **L3-only**.

### pop-locations-regions.mdx
- PoP & region **names all match** the authoritative old table. Good.
- [ERROR][T-CC] lines 80–90, 102–105, 117–120 — per-PoP **1/10/100 Gbps availability columns** are fabricated (old table has no per-PoP capacity data). → remove columns, or source them.
- [INFO][T-CC] lines 82–90 — new per-PoP "low-latency region" mapping not in old source. → verify each pairing.
- [WARNING][T-LK] lines 47–51 — links into `resilient-architecture#aws/#azure/#gcp` (fabricated sections). → revisit after that guide is fixed.

### multi-az.mdx
- [ERROR][T-CC] line 24 — lists "AS-path prepending" without the caveat that **it is not configurable on OVHcloud devices** (use MED for inbound). Customer-side prepend (line 34) is fine. → add caveat.
- [WARNING][T-CC] lines 40–45 — "Multi-AZ **required** for regulated/compliance workloads". Opinion as rule. → soften to "recommended".

### slas.mdx  _(no previous doc equivalent — but now gradeable against the contract)_
The contract **confirms an SLA exists** — so this guide should be **corrected**, not deleted. The numbers are real; the tiering is wrong.
- [ERROR][T-CC] lines 28–29, 43 — tiered table (Single "up to 99.9%", Redundant "up to 99.99%"). **Wrong tiering.** Per contract: 1 connection = *no SLA*; 2 connections/1 PoP = *no SLA*; 2 connections/2 PoPs = **99.9 %**; 4 connections/2 PoPs/2 DCs = **99.99 %**. → replace with the contract table.
- [ERROR][T-CC] line 17 — "e.g. 99.9% monthly uptime" stated generically. → tie to HA Level 1 config.
- [WARNING→OK][T-CC] lines 47–52 — "service credits" — **confirmed by contract** (10/20/30 % penalty ladder, capped 30 %/month, claim within 1 month). → keep but replace with the real penalty figures; drop "priority support" (not in contract).
- [OK][T-CC] lines 38–43 — SLA prerequisites (exclusions) — **broadly confirmed** by the contract's exclusion list (force majeure, customer config/equipment, planned maintenance, suspension, hacking). → align wording to the contract's exclusions.
- [ERROR][T-CC] lines 17–19 — **latency SLA** + support/resolution response-time commitments. Contract SLA is **availability only** — no latency or response-time SLA. → remove.
- [ERROR][T-CC] — missing scope statement: SLA covers **PoP→Datacenter only** and **excludes the provider Virtual Circuit**. → add.
- [WARNING][T-CP] lines 57–60 — "view uptime/historical metrics" + "set up alerts". No such CP feature (only on-demand diagnostics). → point to `monitor`.

### limits.mdx
- [ERROR][T-CC] line 27 — "**16** OCC services per PoP per vRack". Contradicts old ("as many L3 as you want in the same vRack"). → remove/replace.
- Otherwise **accurate** (optics, autoneg, 512 MAC/10 Gb, jumbo 9000, 1 session/PoP, 100 prefixes, L2/L3 unsupported lists, Provider = L3-only). No other fixes.

### l3-bgp.mdx
- [ERROR][T-VENDOR] lines 162–187 — full **Cisco IOS/IOS-XE** BGP config block. Fabricated. → remove.
- [ERROR][T-VENDOR] lines 189–242 — full **Juniper JunOS** BGP config block. Fabricated. → remove.
- [ERROR][T-VENDOR] lines 248–262 — Cisco + Juniper verification command blocks. → remove.
- [ERROR][T-CP] line 29 — CP breadcrumb missing `Bare Metal Cloud` + "select your solution".
- [ERROR][T-CC] lines 36, 41, 93, 105 — hardcoded OVHcloud **ASN 35540**. → remove; `ovhBgpArea` is the OVHcloud-side private ASN.
- [ERROR][T-CC] line 63 — `ovhBgpArea` "auto-assigned". Contradicts old API (customer-supplied). → fix.
- [ERROR][T-CC] lines 25, 62 — stated customer ASN range 64512–65534 but example `65001` is out of range. → fix consistency.
- [ERROR][T-API] Step 4 (lines 112–138) — jumps to `.../datacenter/{datacenterId}/extra` without the prerequisite `POST .../config/pop/{popId}/datacenter` (+ /28 subnet). → add the step.
- [WARNING][T-CC] line 137 — example `bgpNeighborArea: 65501` — **reserved/known-bad**. → change + warn.
- [WARNING][T-API] line 284 — diagnostic enum names (`diagPeering`…) unverifiable. → verify.
- [INFO][T-CC] line 293 — add caveat: AS-path prepend is customer-side only; MED is the OVHcloud-side alternative.
- _Correct & preserved:_ 4 peers/DC, peer A & B, BFD default-on, VRRP-disabled-by-BGP (line 117).

### l3-static.mdx
- [ERROR][T-VENDOR] lines 178–191 — full **Cisco IOS/IOS-XE** static config block. → remove.
- [ERROR][T-VENDOR] lines 195–214 — full **Juniper JunOS** static config block. → remove.
- [ERROR][T-VENDOR] lines 220–234 — Cisco + Juniper verification blocks. → remove.
- [ERROR][T-CP] line 40 — CP breadcrumb missing `Bare Metal Cloud` + select solution.
- [ERROR][T-API] Step 4 (lines 111–137) — missing prerequisite `POST .../config/pop/{popId}/datacenter` (+ /28). → add.
- [WARNING][T-CC] line 116 — VRRP virtual IP called the "**second address**". Old: the **first** usable IP is the VRRP gateway; routers A/B are the next two. → fix.
- [INFO][T-CC] lines 20–30 — generic static-vs-BGP decision table (AWS-flavoured but not false). Low priority.

### order-direct.mdx
- [ERROR][T-CP] lines 26–38 — invented CP **order wizard** (`Order` > `OVHcloud Connect Direct` > selectors > `Confirm`). No such flow — OCC is ordered on ovhcloud.com. → replace with the website order flow + real post-order CP config.
- [ERROR][T-CP] line 24 — nav missing `Bare Metal Cloud`.
- [WARNING][T-CP] line 34 — "Preferred VLAN ID" order field — not real. → remove.
- [ERROR][T-CC] line 64 — "LOA delivered within minutes". → remove.
- [WARNING][T-CC] lines 70, 78 — "billing starts / minimum commitment" — align to the 60-day delivery rule; drop commitment claim.

### order-provider.mdx
- [ERROR][T-CP] lines 20–28 — invented CP order wizard + "choose provider from list" + "OVHcloud generates a pairing key" in CP. Real flow: order externally → enter **service key** in the provider portal → verify "Active" in CP. → rewrite.
- [ERROR][T-CP] line 22 — nav missing `Bare Metal Cloud`.
- [OK][T-CC] line 17 — "50 Mbps to 50 Gbps" bandwidth. **Correct for Provider** (website). → keep.
- [WARNING][T-VENDOR/CC] lines 38–71 — Megaport/Equinix/Console Connect portal step-by-steps. Unsourced, will rot. → collapse to "enter your service key in your provider's portal" + link.

### cancel-direct.mdx
- [ERROR][T-CP] line 20 — nav missing `Bare Metal Cloud` (or drop; cancellation lives under Billing).
- [INFO][T-CP] lines 34–35 — `My offers and services` > … > `Cancel my subscription` — verified in manager-beta. OK.
- [INFO][T-API] line 69 — `POST /ovhCloudConnect/{serviceName}/terminate` — verified (also needs `confirmTermination`). OK.

### cancel-provider.mdx
- [ERROR][T-CP] line 18 — nav missing `Bare Metal Cloud`.
- [WARNING][T-VENDOR] lines 38–42 — per-provider portal cancel verbs. → soften to "cancel in your provider's portal".

### associate-vrack.mdx
- [ERROR][T-CP] line 29 — nav missing `Bare Metal Cloud`.
- [WARNING][T-CP] lines 35–39 — associates via `Network` > `vRack` > `Add a service`. The authoritative OCC method is the **`Attach a vRack`** button on the OCC solution page. → document that as primary.
- [INFO][T-API] lines 45, 56 — `GET`/`POST /vrack/{serviceName}/ovhCloudConnect` — verified. OK.
- [INFO][T-TF] lines 65–68 — `ovh_vrack_ovhcloudconnect` (`service_name`, `ovh_cloud_connect`) — verified in terraform.json. OK.

### vrack-network-setup.mdx
- [ERROR][T-CP] line 35 — nav missing `Bare Metal Cloud`.
- [ERROR][T-CC] lines 54–60 — AZ subnet table claims **4** reserved IPs. Authoritative = **first 3** reserved on the /28. → fix to 3.
- [WARNING][T-API] line 174 — `/task/{taskId}` should be `/task/{id}`.
- [WARNING][T-CC] line 137 — verify `ovhBgpArea` POST-body field name against the API.
- _Correct:_ /28 (line 65), VRRP facts (lines 73–86). 

### occ-direct-control-panel-setup.mdx  _(worst offender)_
- [ERROR][T-CP] **whole guide** — none of the real CP config steps present: **Attach a vRack**, **Add a PoP configuration** (L2/L3, Customer ASN, OVHcloud ASN, **/30** subnet), **Add a configuration** (AZ, OVHcloud ASN, **/28** subnet), **Add routing configuration** (BGP/Static). → port the real steps from the previous CP guide.
- [ERROR][T-CP] line 21 — nav missing `Bare Metal Cloud`.
- [ERROR][T-VENDOR] line 73 — `show ip bgp summary` (Cisco) / `show bgp summary` (**Juniper**). → remove Juniper; drop/limit vendor CLI.
- [WARNING][T-VENDOR] line 72 — `show interfaces`. → replace with "confirm the port is up in the Control Panel".

### occ-provider-control-panel-setup.mdx  _(worst offender)_
- [ERROR][T-CP] **whole guide** — missing real L3 CP config steps (Attach a vRack, PoP L3 **/30**, AZ **/28**, routing config). → port from previous provider CP guide.
- [ERROR][T-CP] line 20 — nav missing `Bare Metal Cloud`.
- [INFO][T-CC] lines 17, 60 — "Provider is always Layer 3" — **correct** (Provider = L3-only).
- [WARNING][T-CC] lines 39–41 — per-provider portal verbs. → soften/link.

### monitor.mdx
- [ERROR][T-VENDOR] lines 118–138 — Cisco IOS + **Juniper JunOS** monitoring command blocks. → remove.
- [ERROR][T-CC] lines 68–70 — L3 diagnostic type named "**BGP Peering Test**". Old type name is "**Default**" (the button is "BGP Peering Test"). → fix.
- [WARNING][T-CC] lines 22–24 — "bandwidth usage graphs / error counters" CP metrics. No such CP feature. → verify/remove.
- [WARNING][T-CC] lines 49–56 — "your own monitoring tools" (SNMP, Datadog/Zabbix/Grafana…). Generic AWS-style advice. → mark generic or remove.
- [WARNING][T-CC] lines 110–116 — invented alert thresholds ("80% of capacity", "latency spike"). → remove numbers.
- [INFO][T-CP] line 11 — nav missing `Bare Metal Cloud`.
- _Correct:_ retention 7 days, 10/type/service/24h, diagnostic tables. `/diagnostic` endpoint verified.

### troubleshooting.mdx
- [ERROR][T-VENDOR] lines 119–123 — **Juniper** autonegotiation command. → remove (old has only Cisco autoneg).
- [ERROR][T-VENDOR] lines 145–160, 184–201, 219–236, 289–303, 357–367, 411–438 — all **Juniper** blocks and expanded **Cisco** `show`/BGP command blocks. → remove Juniper; strip non-autoneg Cisco blocks.
- [ERROR][T-CC] line 136 — "peering with OVHcloud ASN **35540**". → replace with region reserved ASN.
- [ERROR][T-CC] line 353 — "BFD not enabled… confirm availability with support". Old: **BFD on by default**. → fix.
- [WARNING][T-CC] line 141 — BGP **MD5** auth mismatch. MD5 unmentioned in old docs. → verify/remove.
- [WARNING][T-CC] lines 214–215, 253, 283 — "default MTU 1500", "hold time 90 s". Not OCC facts. → mark generic or remove.
- [WARNING][T-CC] line 322 — "beyond 30 minutes contact support". Invented. → remove number.
- [WARNING][T-CC] line 397 — "802.1q VLAN tagging (L2) — Supported". Verify (old doesn't state it). 
- _Correct & preserved:_ optics table, Cisco autoneg commands, /30 & /28 rules, reserved ASNs 65501/65502/65519, 100 prefixes, delivery rule.

### incident-followup.mdx  _(no previous equivalent)_
- [ERROR][T-VENDOR] lines 39–46 — **Juniper** diagnostic command block. → remove.
- [WARNING][T-VENDOR] lines 30–37 — Cisco command block. → mark generic/remove.
- [WARNING][T-CC] lines 97, 108 — "SLA terms / service credits / RCA" process. No source. → verify/soften.
- [INFO][T-CP] line 64 — nav missing `Bare Metal Cloud`.
- [INFO][T-LK] lines 97, 108, 117 — links to `/slas` (fabricated). → revisit.

### cross-connect-loa.mdx
- [WARNING][T-CP] line 30 — "`Download LOA` option in the CP". `/loa` API endpoint exists; the CP UI element is unverified. → verify label.
- [WARNING][T-CC] lines 19–20, 74–75 — "LC connectors typical". Old LOA example shows **SC/PC**. → cite SC/PC, not LC.
- [INFO][T-CC] lines 42, 73 — installation fees / "1–10 business days". → soften "varies by DC".

### logs-forwarding.mdx
_Clean — accurate port. Log kinds, fields, and all API calls verified._
- [INFO][T-CP] line 29 — nav missing `Bare Metal Cloud`.

### automation.mdx
_Clean — all API endpoints and the Terraform resource verified._
- [WARNING][T-TF] line 91 — provider `version = ">= 2.7.0"` invented floor. → drop or verify.
- [INFO][T-API] lines 62–70 — hand-rolled curl signing example (new, illustrative). OK.

### faq.mdx
- [ERROR][T-CC] line 97 — "OVHcloud uses **ASN 35540**". → remove; region reserved ASN.
- [ERROR][T-CC] lines 131–147 — entire **multi-cloud** section (AWS Direct Connect / Azure ExpressRoute / GCP Interconnect, cloud-to-cloud transit). Fabricated. → remove/restrict.
- [ERROR][T-CC] lines 157–160 — SLA table (Single "~99.9%", Dual "~99.95–99.99%"). **Mis-tiered** vs contract (single = *no SLA*; 2 PoPs = 99.9 %; 4 conn/2 PoPs/2 DCs = 99.99 %; "99.95%" invented). → replace with the contract tiering.
- [ERROR][T-CC] lines 125, 178 — "BFD depends… confirm with support". Old: BFD on by default. → fix.
- [WARNING][T-CC] lines 21, 73, 109 — "50 Mbps–50 Gbps" is **correct for Provider** (keep, scope it); "100 Gbps" applies to **Direct**; but jumbo "**may be** supported" is wrong — jumbo 9000 **is** supported. → scope bandwidth by offer; state jumbo is supported.
- [WARNING][T-CC] line 105 — IPv6 "primarily IPv4, check for availability". Old: **IPv6 not supported**. → state flatly.
- [WARNING][T-CC] lines 108, 178 — "MTU 1500", "hold time 90 s → failover 30–90 s". → remove numbers.
- [INFO][T-CC] line 66 — omits the "manual arrangement with agent" third Direct-delivery case. → optionally add.

### simple-architecture.mdx  _(no previous equivalent — heavy hallucination)_
- CP-INSTRUCTIONS **missing**; foreign-console nav instead of OVHcloud CP.
- [ERROR][T-SDWAN] lines 106, 114 — "MPLS or SD-WAN", "SD-WAN gateway", "Hybrid SD-WAN deployments". → remove.
- [ERROR][T-CC] line 289 — "OCC bandwidth 1/10 Gbps" (omits 100 Gbps). → fix.
- [ERROR][T-CC] lines 357–362, 485–489 — uses reserved ASNs without the AS65501 caveat. → add.
- [WARNING][T-CC] lines 35–38, 86, 112, 276–279, 396–397 — invented SLA/uptime figures. → remove.
- [WARNING][T-CC] lines 166–257 (AWS), 259–373 (Azure), 376–501 (GCP) — foreign cloud-interconnect procedures. → remove or clearly mark as third-party.
- [T-SCHEMA] `fig-1..5.svg` — self-drawn box diagrams; fig-2 shows SD-WAN, fig-3/4/5 AWS/Azure/GCP. → remove/replace with the OVHcloud-authentic diagrams.

### resilient-architecture.mdx  _(no previous equivalent — heavy hallucination)_
- CP-INSTRUCTIONS **missing**.
- [ERROR][T-VENDOR] lines 64–90 — full **Cisco IOS** BGP config block (with wrong `remote-as 35540`). → remove.
- [ERROR][T-CC] lines 97, 398–401, 534–537 — **AS-path prepending shown as an OVHcloud-side action**. Contradicts "not configurable on OVHcloud devices". → remove from OVHcloud-side tables; use MED.
- [ERROR][T-SDWAN] lines 158, 170, 180, 188, 209–215 — SD-WAN overlay/underlay/controller. → remove.
- [ERROR][T-CC] lines 143, 187 — ECMP as optional "if supported". Old: **auto-enabled with 2+ PoPs, up to 4 paths**. → fix.
- [ERROR][T-CC] line 422 — "Azure 4000 routes/circuit" (out of scope); real OCC limit **100 prefixes/session** never stated. → fix.
- [ERROR][T-CC] lines 24, 44–48, 156–157 — omits OVHcloud constraints (1 session/PoP, no eBGP multihop, no BGP+static mix in same DC, VRRP disabled with BGP). → add.
- [WARNING][T-CC] lines 118, 416 — "BGP convergence 30–90 s". Invented. → remove.
- [WARNING][T-CC] lines 39, 169, 324, 447, 458–462 — SLA figures / GCP SLA tiers. → remove OVHcloud SLA %.
- [WARNING][T-CC] line 557 — "GCP 1440 MTU". Old: jumbo up to 9000. → fix.
- [WARNING][T-CC] lines 218–301 (AWS), 304–424 (Azure), 427–559 (GCP) — foreign dual-interconnect patterns. → remove/mark third-party.
- [INFO][T-CC] line 98 — "MED may not be honoured". Contradicts old (MED recommended). → fix.
- [T-SCHEMA] `fig-1..5.svg` — same AWS/Azure/GCP/SD-WAN box diagrams. → remove/replace.

---

## Requested fixes — mapping to pain points

| # | Pain point | Where | Action |
|---|---|---|---|
| 1 | L2/L3 title implies both; L2-only-in-title | `introduction.mdx` §L2 heading + "How it works" table | Rename heading; add L2/L3-support row (Direct = L2 & L3, Provider = L3-only). |
| 2 | Juniper/Cisco non-verifiable | `l3-bgp`, `l3-static`, `troubleshooting`, `monitor`, `incident-followup`, `resilient-architecture`, `occ-direct-control-panel-setup` | Remove all Juniper; remove fabricated Cisco config/`show` blocks; keep only the sanctioned Cisco autonegotiation-disable note as vendor-neutral guidance. |
| 3 | Missing CP instructions | `occ-direct-control-panel-setup`, `occ-provider-control-panel-setup`, `order-direct`, `order-provider`, `associate-vrack`, `vrack-network-setup` | Port real CP steps (Attach a vRack, PoP /30, AZ /28, routing config); fix `Bare Metal Cloud` nav everywhere; remove invented order wizard. |
| 4 | SD-WAN | `providers`, `simple-architecture`, `resilient-architecture` | Remove every SD-WAN reference incl. overlay/underlay + fig-2 diagrams. |
| 5 | Wrong schemas | `simple-architecture`, `resilient-architecture` (10 SVGs), placeholder `fig-1.svg` in order/CP guides | Remove/replace fabricated AWS/Azure/GCP/SD-WAN diagrams with OVHcloud-authentic schemas. |
| — | Fact-check everything | all 28 | See per-guide findings above. |

## Additional confirmed hallucinations to correct (beyond the 5 pain points)

- **ASN 35540** → reserved 65501/65502/65519 (with AS65501 "do not use" warning): `l3-bgp`, `resilient-architecture`, `troubleshooting`, `faq`.
- **Mis-tiered SLA %** → apply the contract's config-based table (see SLA block): `slas`, `faq`, `glossary`, `simple-architecture`, `resilient-architecture`. (The numbers are real — correct the tiering, don't delete.)
- **Bandwidth** → scope by offer: Direct 1/10/100 Gbps, Provider 50 Mbps–50 Gbps (both confirmed on the website): `glossary`, `providers`, `order-provider`, `faq`.
- **Provider roster** → keep the real partners (Digital Realty, Colt, Console Connect, Megaport, Equinix, InterCloud, Orange Business Services, RISQ); fix "BSO"→"InterCloud" naming; decide on PacketFabric: `providers`.
- **BFD "confirm with support"** → on by default: `troubleshooting`, `faq`.
- **ECMP "if supported"** → auto with 2+ PoPs (≤4 paths): `resilient-architecture`.
- **"16 services per PoP" quota** → remove: `limits`.
- **Invented MTU/convergence/route numbers** → remove: `troubleshooting`, `faq`, `resilient-architecture`.
- **AWS/Azure/GCP procedures** → remove or mark third-party: `simple-architecture`, `resilient-architecture`, `faq`.

## Notes for the reviewer

- No fabricated **API endpoints** were found — all referenced routes exist in `api.json`. Terraform `ovh_vrack_ovhcloudconnect` is correct.
- `overview`, `introduction`, `logs-forwarding`, `automation` need no factual changes.
- The previous docs' own minor inconsistency (occ-layer3 says DC "/29" once while the CP/API/troubleshooting all say **/28**) is resolved in favour of **/28** (authoritative).
- `pop-locations-regions` PoP/region names are correct; only remove the fabricated bandwidth-availability columns.
