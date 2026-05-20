/**
 * Worker thread: pre-processes HTML files in a single locale directory.
 * Boosts h1 weight for Pagefind and cleans header-anchor "#" symbols.
 *
 * Input (workerData):  { dir: string }
 * Output (message):    number (count of modified files)
 */
import { parentPort, workerData } from 'node:worker_threads';
import * as fs from 'node:fs';
import * as path from 'node:path';

const SKIP_DIRS = new Set(['pagefind', 'public', 'images', 'static']);

function preProcessHtmlForSearch(dir: string): number {
  let processed = 0;
  if (!fs.existsSync(dir)) return processed;

  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (!SKIP_DIRS.has(entry.name)) {
        processed += preProcessHtmlForSearch(fullPath);
      }
    } else if (entry.name.endsWith('.html')) {
      let html = fs.readFileSync(fullPath, 'utf-8');
      let changed = false;

      // Boost h1 weight so exact title matches rank first
      if (!html.includes('data-pagefind-weight')) {
        html = html.replace(
          /<h1([^>]*)>/gi,
          '<h1$1 data-pagefind-weight="10">',
        );
        changed = true;
      }

      // Clear header-anchor text so "#" doesn't appear in sub-result titles
      const cleaned = html.replace(
        /(<a\s[^>]*class="[^"]*header-anchor[^"]*"[^>]*>)\s*#\s*(<\/a>)/gi,
        '$1 $2',
      );
      if (cleaned !== html) {
        html = cleaned;
        changed = true;
      }

      if (changed) {
        fs.writeFileSync(fullPath, html);
        processed++;
      }
    }
  }
  return processed;
}

const { dir } = workerData as { dir: string };
const count = preProcessHtmlForSearch(dir);
parentPort?.postMessage(count);
