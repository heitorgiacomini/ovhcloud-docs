{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — automation.mdx

- **Previous-doc source:** ovhcloud-connect-old/api.mdx
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| `GET /ovhCloudConnect/{serviceName}/config/pop` (list PoP configs) | 23 | previous api.mdx (config/pop calls); api.json confirms |
| `POST /ovhCloudConnect/{serviceName}/config/pop` (create PoP config) | 24 | previous api.mdx L73,83; api.json confirms |
| OCC solution can be configured via API; credentials via createToken | 12,29 | previous api.mdx L12, L24 |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| `GET /ovhCloudConnect` (list all services) | 21 | api.json — endpoint exists |
| `GET /ovhCloudConnect/{serviceName}` (service details) | 22 | api.json — endpoint exists |
| `GET /ovhCloudConnect/{serviceName}/serviceInfos` (metadata/billing) | 25 | api.json — endpoint exists |
| API console URL section=/ovhCloudConnect branch=v1 | 15 | api.json namespace ovhCloudConnect v1 |
| createToken URL eu.api.ovh.com/createToken | 29 | standard OVHcloud API credential flow |
| Official SDKs: python-ovh, node-ovh, go-ovh, php-ovh, csharp-ovh | 31-35 | ovhcloud.com/github public SDK repos (all exist) |
| Python `ovh.Client(endpoint='ovh-eu')` + `client.get('/ovhCloudConnect')` | 40-49 | python-ovh usage; endpoint exists |
| API request signing headers X-Ovh-Application / X-Ovh-Consumer / X-Ovh-Timestamp / X-Ovh-Signature | 65-68 | OVHcloud API signing scheme (documented standard) |
| Terraform resource `ovh_vrack_ovhcloudconnect` with args `service_name`, `ovh_cloud_connect` | 103-106 | terraform.json — resource exists; both args required (verbatim match) |
| Terraform provider source `ovh/ovh`, registry + GitHub links | 80-81,88 | terraform.json / public registry |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| "No dedicated OVHcloud CLI binary for OVHcloud Connect" | 58 | Absence claim; cannot confirm a negative from cache — needs PM confirmation (though consistent with no CLI in SOT) |

## Summary
- Category 1: 3 · Category 2: 10 · Category 3: 1
- Notes: Every OCC API endpoint cited (`/ovhCloudConnect`, `/{serviceName}`, `/config/pop`, `/serviceInfos`) is confirmed in api.json. The Terraform resource and its two required arguments match terraform.json exactly. The guide is deliberately conservative ("check the Registry for exact names"), so factual risk is minimal; the only category-3 item is the negative CLI-existence claim.
