#!/usr/bin/env node
/**
 * Extend slug-mapping.json with synthetic entries for fresh guides that
 * have no corresponding legacy `base/pages/**` entry.
 *
 * The mapping is used by analyze-slug-seo.ts and rename-slugs.ts.
 * Without these synthetic entries, fresh-only guides are invisible to the
 * SEO pipeline (recent commits explicitly note "skipped collisions with
 * existing fresh guides" — collision detection but no renaming).
 *
 * For a fresh entry, fullSlug = newSlug = current filename basename.
 * Legacy entries are left untouched.
 */
import fs from 'node:fs';
import path from 'node:path';
import { globSync } from 'glob';

const ROOT_DIR = path.resolve(import.meta.dirname, '..');
const DOCS_EN = path.join(ROOT_DIR, 'docs', 'en');
const MAPPING_PATH = path.join(ROOT_DIR, 'scripts', 'slug-mapping.json');

interface MappingEntry {
  fullSlug: string;
  newSlug: string;
  basePath: string;
  exists: boolean;
}

const mapping: Record<string, MappingEntry> = JSON.parse(
  fs.readFileSync(MAPPING_PATH, 'utf-8'),
);

const beforeCount = Object.keys(mapping).length;

const mdxFiles = globSync('guides/**/*.mdx', { cwd: DOCS_EN, nodir: true });

let added = 0;
for (const rel of mdxFiles) {
  const key = rel; // e.g. "guides/public-cloud/databases/foo.mdx"
  if (mapping[key]) continue;

  const slug = path.basename(rel, '.mdx');
  // basePath mirrors legacy convention: underscores in directory segments
  const dirSegments = path.dirname(rel).split('/').slice(1); // drop leading "guides"
  const basePath = [...dirSegments.map((s) => s.replace(/-/g, '_')), slug].join(
    '/',
  );

  mapping[key] = {
    fullSlug: slug,
    newSlug: slug,
    basePath,
    exists: true,
  };
  added++;
}

fs.writeFileSync(MAPPING_PATH, `${JSON.stringify(mapping, null, 2)}\n`);

console.log(
  `Extended slug-mapping.json: ${beforeCount} → ${beforeCount + added} entries (${added} fresh guides added)`,
);
