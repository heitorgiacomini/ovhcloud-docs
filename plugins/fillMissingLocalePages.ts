/**
 * Rspress plugin: register synthetic routes that serve the English MDX
 * for guides referenced by the sidebar but absent from the current
 * locale.
 *
 * Why: the sidebar (config/sidebar/index.md) is the single source of
 * truth for the navigation in every locale. When a guide listed there
 * is not yet translated to {locale}, docs/{locale}/<slug>.mdx doesn't
 * exist — Rspress dev returns 404 and the per-locale prod build
 * doesn't emit dist/{locale}/<slug>.html. This plugin closes the gap
 * by calling addPages() with { routePath, filepath } pointing at the
 * English source. Rspress compiles that source under the current
 * locale's build context: the URL stays at /{locale}/..., no symlink
 * or stub file is created on disk.
 *
 * Scope: ONLY guides referenced in config/sidebar/index.md. Random
 * deep links to untranslated pages outside the sidebar keep 404'ing —
 * that's the desired behavior (those pages are not part of the public
 * nav).
 *
 * Behavior in dev: addPages is called once per Rspress instance. The
 * dev server serves a single Rspress instance for all locales (see
 * rspress.config.ts), so we register fallback routes for every
 * non-en locale that has at least one missing guide.
 *
 * Behavior in prod: each per-locale build (LOCALE=it rspress build)
 * calls addPages with that locale only.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import type { RspressPlugin } from '@rspress/core';

type Locale = 'fr' | 'en' | 'de' | 'es' | 'it' | 'pl' | 'pt';

interface PluginOptions {
  /** Absolute path to the repo's docs/ directory. */
  docsRoot: string;
  /** Absolute path to config/sidebar/index.md. */
  sidebarIndex: string;
  /**
   * Locales to process. In per-locale prod builds, pass the single
   * build locale. In dev (single multi-locale instance), pass every
   * non-default locale you want to cover.
   */
  locales: Locale[];
  /** Path prefix prepended to routePath. '' for prod (base handles it),
   *  '/{locale}' for dev (Rspress dev exposes other locales under that
   *  prefix; default locale uses '' to stay at root). */
  routePrefixFor: (locale: Locale) => string;
}

const FALLBACK_LOCALE: Locale = 'en';

/**
 * Extract guide slugs from the sidebar index. A guide line looks like:
 *   + [Title](universe/product/slug)
 * Distinguished from product/section lines by: (a) the ref contains '/',
 * and (b) it does not start with 'products/'.
 */
function readGuideRefs(sidebarIndex: string): string[] {
  const md = fs.readFileSync(sidebarIndex, 'utf8');
  const refs: string[] = [];
  for (const line of md.split('\n')) {
    const m = line.match(/\+\s*\[[^\]]*\]\(([^)]+)\)/);
    if (!m) continue;
    const ref = m[1];
    if (!ref.includes('/')) continue;
    if (ref.startsWith('products/')) continue;
    refs.push(ref);
  }
  return refs;
}

export function pluginFillMissingLocalePages(
  opts: PluginOptions,
): RspressPlugin {
  return {
    name: 'fill-missing-locale-pages',
    addPages() {
      const guideRefs = readGuideRefs(opts.sidebarIndex);
      const enDir = path.join(opts.docsRoot, FALLBACK_LOCALE);
      const pages: { routePath: string; filepath: string }[] = [];

      for (const locale of opts.locales) {
        if (locale === FALLBACK_LOCALE) continue;
        const localeDir = path.join(opts.docsRoot, locale);
        const prefix = opts.routePrefixFor(locale);
        let added = 0;

        for (const ref of guideRefs) {
          const rel = `guides/${ref}.mdx`;
          const localFile = path.join(localeDir, rel);
          const enFile = path.join(enDir, rel);
          if (fs.existsSync(localFile)) continue;
          if (!fs.existsSync(enFile)) continue;
          pages.push({
            routePath: `${prefix}/guides/${ref}`,
            filepath: enFile,
          });
          added++;
        }

        if (added > 0) {
          console.log(
            `[fill-missing-locale-pages] ${locale}: ${added} fallback route(s) → docs/en`,
          );
        }
      }

      return pages;
    },
  };
}
