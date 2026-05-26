/* eslint-disable no-console */
// One-shot audit: which guide files on disk are not reachable via the sidebar?
// Parser-aware, all 7 locales, accounts for supplements + FR-only patterns.
import * as fs from 'node:fs';
import * as path from 'node:path';
import { parseIndexMd } from '../config/sidebar/parser';
import {
  getHeaderItems,
  securitySidebar,
} from '../config/sidebar/supplements';

const LOCALES = ['en', 'fr', 'de', 'es', 'it', 'pl', 'pt'] as const;
const FR_ONLY = /^web-cloud\/(phone-and-fax|internet\/(internet-access|overthebox))\//;

function collectLinks(items: unknown[], out: Set<string>): void {
  for (const it of items as Array<{
    link?: string;
    items?: unknown[];
  }>) {
    if (typeof it?.link === 'string' && it.link.startsWith('/guides/')) {
      out.add(it.link.replace(/^\/guides\//, ''));
    }
    if (Array.isArray(it?.items)) collectLinks(it.items, out);
  }
}

const supplementSlugs = new Set<string>();
function harvestSupplement(it: unknown): void {
  if (it && typeof it === 'object') {
    const o = it as { link?: string; items?: unknown[] };
    if (typeof o.link === 'string' && o.link.startsWith('/guides/')) {
      supplementSlugs.add(o.link.replace(/^\/guides\//, ''));
    }
    if (Array.isArray(o.items)) o.items.forEach(harvestSupplement);
  }
}
harvestSupplement(securitySidebar);
LOCALES.forEach((l) => getHeaderItems(l).forEach(harvestSupplement));

let totalProblems = 0;
for (const locale of LOCALES) {
  const result = parseIndexMd('config/sidebar/index.md', 'docs', locale);
  const reachable = new Set<string>();
  collectLinks(result.universes, reachable);
  for (const s of supplementSlugs) reachable.add(s);

  const root = path.join('docs', locale, 'guides');
  const onDisk = new Set<string>();
  const walk = (dir: string) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) walk(full);
      else if (e.isFile() && (e.name.endsWith('.mdx') || e.name.endsWith('.md'))) {
        const rel = full.replace(`${root}/`, '').replace(/\.(mdx|md)$/, '');
        onDisk.add(rel);
      }
    }
  };
  walk(root);

  const orphans = [...onDisk].filter((s) => !reachable.has(s)).sort();
  const trueOrphans = orphans.filter((s) => {
    const base = path.basename(s);
    if (base.startsWith('_')) return false;
    if (s === 'e-learning' || s === 'migration') return false;
    if (locale !== 'fr' && FR_ONLY.test(s)) return false;
    return true;
  });

  console.log(
    `[${locale}] disk=${onDisk.size}, reachable=${reachable.size}, raw orphans=${orphans.length}, true orphans=${trueOrphans.length}`,
  );
  for (const o of trueOrphans) {
    console.log('  -', o);
    totalProblems++;
  }
}
console.log(`\nTOTAL TRUE ORPHANS: ${totalProblems}`);
process.exit(totalProblems === 0 ? 0 : 1);
