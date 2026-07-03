{/* Internal verification report — not a published guide. Do not add to the sidebar / build. */}

# Verification — overview.mdx

- **Previous-doc source:** ovhcloud-connect-old/overview.mdx
- **Sources checked:** previous docs, SOT cache (api / manager-beta / terraform / docs), OCC contract, ovhcloud.com
- **Method:** /fact-check SOT-veracity + previous-doc comparison

This file is an `pageType: overview` landing page (frontmatter only, no body prose). The substantive "claims" are the essential-guide link targets and the go-further links.

## 1. Already present in the previous docs & verifiable
| Claim | Line | Evidence |
|---|---|---|
| Overview page structure (essentials + goFurther + support CTA) | 1-33 | previous overview.mdx has the identical layout, same 5 essential entries, same goFurther/CTA blocks |
| Roadmap/changelog link `ovhcloud.com/en/roadmap-changelog/` | 24 | identical to previous overview line 23 |
| Discord link `discord.gg/ovhcloud` | 26 | identical to previous overview line 25 |
| Support link `help.ovhcloud.com` | 32 | identical to previous overview line 32 |

## 2. New (not in the previous docs) but verifiable
| Claim | Line | Evidence |
|---|---|---|
| Essential guide slugs renamed to new set (occ-direct-control-panel-setup, occ-provider-control-panel-setup, monitor, logs-forwarding, faq) | 9-16 | all five target `.mdx` files exist in the new ovhcloud-connect/ folder; verifiable against the repo tree |
| Community link uses alias `/links/community` | 22 | new-docs links-alias convention (replaces old bare community.ovhcloud.com URL) |

## 3. New & not verifiable without testing
| Claim | Line | Why unverifiable / test needed |
|---|---|---|
| (none) | — | landing page contains no factual/procedural claims requiring live validation |

## Summary
- Category 1: 4 · Category 2: 2 · Category 3: 0
- Notes: Clean carryover. Same overview layout as the previous doc; the only real changes are the retargeted essential-guide slugs (all confirmed to exist) and the `/links/community` alias swap. No unverifiable claims.
