# Redirections

Two nginx map files that route legacy URLs to the new `docs.ovhcloud.com`.

## Files

### Source (inputs)

- `legacy-urls.csv` — authoritative ServiceNow export: `seo_url ; country_code ; markdown_path`
  (28 483 rows). Maps each `help.ovhcloud.com/csm/{slug}` to the source
  `base/pages/...` file and locale.
- `prod-redirections_docs.map` — historical `docs.ovh.com` → CSM redirects
  (21 209 rows).
- `prod-redirections.map` — historical CSM-internal renames (6 582 rows). Used
  only as enrichment data: rename source slugs whose CSV-resolved target is a
  home fallback get upgraded to the rename target's specific page.

### Generated (outputs)

Run `node scripts/build-redirections-step1.mjs && node scripts/build-redirections-step2.mjs && node scripts/build-redirections-step3.mjs && node scripts/build-redirections-validate.mjs`
to regenerate.

| File | Applied on host | Entries | Role |
|---|---|---|---|
| `legacy-to-new.map` | `help.ovhcloud.com` | 28 035 | CSM URL → docs.ovhcloud.com page (or locale home if unmigrated). Rename data from prod-redirections.map is merged in. |
| `legacy-docs-to-new.map` | `docs.ovh.com` | 21 141 | Legacy docs URL → docs.ovhcloud.com page (or locale home if unmigrated). |

All redirects are **single-hop** and **HTTP 301**.

## Coverage

```
legacy-to-new.map         28 035 entries   87.6%  → specific page
                                            3 478  → locale home (page not yet migrated)

legacy-docs-to-new.map    21 141 entries   71.4%  → specific page
                                            6 036  → locale home
```

## Source pattern format

Sources are regex `~^…$` matching the URL path (no query string).

For `legacy-to-new.map`, the nginx map directive **must use `$uri`** (not
`$request_uri`) so that CSM URLs with any query string — `?id=KBxxxx`,
`?utm_source=email`, etc. — all match a single source pattern.

For `legacy-docs-to-new.map`, either `$uri` or `$request_uri` works in
practice because docs.ovh.com URLs rarely carry a query string. Sources
tolerate an optional trailing slash (`/path/?$`) so both `/fr/foo` and
`/fr/foo/` match.

## Locale fallback

Country codes in `legacy-urls.csv` map to our 7 locales:

| CSV `country_code` | new docs locale |
|---|---|
| `fr`, `fr-ca` | `fr` |
| `de` | `de` |
| `es`, `es-es`, `es-us` | `es` |
| `it` | `it` |
| `pl` | `pl` |
| `pt` | `pt` |
| `en`, `en-gb`, `en-ie`, `en-in`, `en-au`, `en-sg`, `en-ca`, `asia`, `us` | `en` |

Per-redirect fallback: if the target `.mdx` exists in the requested locale,
the redirect uses it. Otherwise it serves EN. If neither exists, the redirect
points to the locale home `/{locale}/`.

## Anti-rebound guarantee

Built into the pipeline: a destination URL never appears as a source on the
**same host**. Validated by `scripts/build-redirections-validate.mjs` which
groups maps by host (`help.ovhcloud.com` vs `docs.ovh.com`) and checks that
no destination URL is itself a source served by the same nginx instance.

`docs.ovhcloud.com` destinations are terminal — no maps applied there.

## Nginx wiring

The map definitions live in `redirections-map.conf`:

```nginx
map_hash_bucket_size 1024;
map_hash_max_size 2048;

map $uri $redirections {
  include /etc/nginx/conf.d/legacy-to-new.map;
}

map $request_uri $redirections_docs {
  include /etc/nginx/conf.d/legacy-docs-to-new.map;
}
```

The `if ($variable) { return 301 $variable; }` plumbing that consumes these
variables lives in the existing `server { }` config alongside other host
rules (managed separately by infra).

## Regeneration

```bash
node scripts/build-redirections-step1.mjs    # build CSM-slug → new-docs map from CSV
node scripts/build-redirections-step2.mjs    # build docs.ovh.com → new docs map
node scripts/build-redirections-step3.mjs    # generate the 2 nginx files
node scripts/build-redirections-validate.mjs # validate: 0 dead, 0 chains
```
