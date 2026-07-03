{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — providers.mdx

- **Previous-doc source:** none (new guide) — no previous OCC doc lists individual providers. The old overview only linked out to the website "Accessible PoPs per provider".
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

Because there is no previous provider guide, section 1 is empty by design. The provider *list* is confirmed by the spec's authoritative website fact; each provider's individual marketing description and external URLs are third-party/portal-specific and are category 3.

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| (none) | — | no previous OCC provider guide exists; old overview only linked to the website for the provider list |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Providers are third-party operators offering managed connectivity in OVHcloud PoPs; alternative to Direct | 9 | spec authoritative fact (Provider = managed L3 connectivity); ovhcloud.com Provider page |
| OVHcloud Connect Provider bandwidth ranges 50 Mbps up to 50 Gbps | 27 | spec authoritative fact (website): Provider 50 Mbps–50 Gbps |
| Supported provider set includes BSO (formerly Intercloud), Console Connect, Digital Realty, Equinix (Fabric), Megaport, Orange Business Services, Risq | 39-132 | spec provider list (website): Digital Realty, Colt, Console Connect, Megaport, Equinix, InterCloud/BSO, Orange Business Services, RISQ |
| Provider workflow: order (service key) → provider provisions → configure BGP/VLAN → traffic flows privately | 136-139 | spec Delivery fact ("Provider = service key emailed") + Provider = L3/BGP model; previous faq service-key flow |
| Note that the provider list may evolve; check the OCC webpage | 35-37 | matches website's dynamic provider list |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| "Colt" is a supported provider (present in spec list but NOT in this guide) — omission | 33-132 | spec's website list includes **Colt**, which does not appear in this guide's provider entries; needs PM/website confirmation of whether Colt should be listed |
| BSO description (financial network, ultra-low latency, capital markets, acquired Intercloud) | 43-45 | third-party marketing copy; no OVHcloud source — verify against bso.co |
| Console Connect description (SDI platform, L2 connections, CloudRouter, portal) | 56-58 | third-party portal specifics — no OVHcloud source |
| Digital Realty ServiceFabric description | 70-72 | third-party marketing — no OVHcloud source |
| Equinix Fabric description (Platform Equinix, SDN interconnection) | 82-84 | third-party marketing — no OVHcloud source |
| Megaport description (NaaS, VXC/MCR/MVE product breakdown) | 96-102 | third-party product specifics — no OVHcloud source |
| Orange Business Services description (MPLS/Internet/cloud, EU/Africa/ME reach) | 114-116 | third-party marketing — no OVHcloud source |
| Risq description (Quebec-based, carrier-grade, dark fibre, Canadian market) | 126-128 | third-party marketing — no OVHcloud source |
| All external provider URLs (bso.co, consoleconnect.com, digitalrealty.com, equinix.com, megaport.com, orange-business.com, risq.quebec, plus doc/API links) | 49-132 | live-URL validity and correct deep-links not confirmable from SOT; run /verify-links |
| "Many providers offer on-demand / dynamic provisioning in minutes" and "many also connect to AWS/Azure/GCP" | 17-18 | provider-portal capabilities — third-party claims, no OVHcloud source |

## Summary
- Category 1: 0 · Category 2: 5 · Category 3: 11
- Notes: New guide, no previous equivalent (section 1 empty as expected). The OCC-side facts (provider concept, Provider bandwidth range, service-key workflow, provider set) are verifiable from the spec's authoritative facts. The bulk of the page is third-party provider marketing descriptions and external URLs that have no OVHcloud source and are category 3 (run /verify-links on the URLs). Flagged discrepancy: the spec's website list includes **Colt**, which is absent from this guide — confirm with PM/website.
