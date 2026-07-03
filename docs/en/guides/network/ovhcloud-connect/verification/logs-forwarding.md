{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — logs-forwarding.mdx

- **Previous-doc source:** ovhcloud-connect-old/logs-to-customers.mdx
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| Four log kinds: service, service_configuration, bgp, interface | 37-42 | previous logs-to-customers L35-40 (verbatim) |
| service = lifecycle events (suspended, delivered) | 39 | previous logs-to-customers L37 |
| service_configuration = config events incl. add/delete DC/POP configs | 40 | previous logs-to-customers L38 |
| bgp = BGP session status | 41 | previous logs-to-customers L39 |
| interface = optic-fibre interface events incl. in/out light | 42 | previous logs-to-customers L40 |
| Log content fields: kind, message, neighbor, service_uuid, timestamp (ms resolution) | 46-52 | previous logs-to-customers L44-50 (verbatim table) |
| Glossary: LDP, Data Stream, Logs forwarding, Subscription definitions | 17-20 | previous logs-to-customers L17-20 (verbatim) |
| `POST /dbaas/logs/{serviceName}/output/graylog/stream` | 62 | previous logs-to-customers L62 (dbaas node = 404 in cache; sourced from prev doc) |
| `GET /dbaas/logs/{serviceName}/output/graylog/stream` | 68 | previous logs-to-customers L69 |
| `GET /dbaas/logs/{serviceName}/output/graylog/stream/{streamId}` | 72 | previous logs-to-customers L74 |
| `POST /ovhCloudConnect/{serviceName}/log/subscription` (+ payload kind/streamId) | 78,100 | api.json (endpoint exists); previous logs-to-customers L81 |
| `GET /ovhCloudConnect` | 85 | api.json (endpoint exists); previous L89 |
| `GET /ovhCloudConnect/{serviceName}/log/kind` | 96 | api.json (endpoint exists); previous L101 |
| `GET /dbaas/logs/{serviceName}/operation/{operationId}` | 118 | previous logs-to-customers L125 (dbaas 404 in cache → prev doc source) |
| `GET /ovhCloudConnect/{serviceName}/log/subscription` | 122 | api.json (endpoint exists); previous L130 |
| `GET /ovhCloudConnect/{serviceName}/log/subscription/{subscriptionId}` | 126 | api.json (endpoint exists); previous L135 |
| `DELETE /ovhCloudConnect/{serviceName}/log/subscription/{subscriptionId}` | 170 | api.json (endpoint exists); previous L180 |
| Response shape: operationId + serviceName; subscription object (createdAt, kind, resource, streamId, subscriptionId, updatedAt) | 110-142 | previous logs-to-customers L116-152 (verbatim) |
| Forwarding activation free; LDP billed per standard price plan | 56 | previous logs-to-customers L54 |
| Graylog usage: retrieve logs-xxxx username/password, open Graylog web-UI (e.g. gra1.logs.ovh.com), search | 149-152 | previous logs-to-customers L159-162 (verbatim) |
| Cancelling subscription stops forwarding; stored logs immutable/not deleted | 164-166 | previous logs-to-customers L174-176 |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| CP nav: Bare Metal Cloud → Network → OVHcloud Connect | 29 | manager-beta cache path; consistent across new OCC guides |
| Requirement: LDP account + OCC account in the same OVHcloud account | 27 | previous logs-to-customers L27 (present — actually category-1 carryover, still verifiable) |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| _(none)_ | — | All substantive claims trace to the previous logs-to-customers guide or api.json |

## Summary
- Category 1: 21 · Category 2: 2 · Category 3: 0
- Notes: Near-verbatim, clean carryover from logs-to-customers. All `/ovhCloudConnect/.../log/*` endpoints confirmed in api.json; the `/dbaas/logs/.../graylog/stream` and `/operation/{operationId}` endpoints could not be re-fetched (dbaas node = HTTP 404 in the cache snapshot) but are present verbatim in the authoritative previous guide, so they are classified category 1. No category-3 items.
