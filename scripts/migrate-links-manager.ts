#!/usr/bin/env npx tsx
/**
 * Codemod: replaces [text](/links/manager) with <ManagerLink to="/">text</ManagerLink>.
 * Run with --write to apply, otherwise dry-run.
 */
import * as fs from 'node:fs';
import * as path from 'node:path';

const ROOT = path.resolve(process.cwd(), 'docs');
const WRITE = process.argv.includes('--write');

// Match [text](/links/manager) on a single line
// (newlines excluded to avoid runaway captures across paragraphs/admonitions)
const LINK_RE = /\[([^\]\n]+)\]\(\/links\/manager\)/g;

let filesModified = 0;
let totalReplacements = 0;

function walk(dir: string): void {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isSymbolicLink()) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full);
    } else if (entry.isFile() && full.endsWith('.mdx')) {
      const original = fs.readFileSync(full, 'utf8');
      let count = 0;
      const updated = original.replace(LINK_RE, (_match, text: string) => {
        count++;
        return `<ManagerLink to="/">${text}</ManagerLink>`;
      });
      if (count > 0) {
        filesModified++;
        totalReplacements += count;
        if (WRITE) fs.writeFileSync(full, updated, 'utf8');
      }
    }
  }
}

console.log(`📝 Scanning ${ROOT} for [text](/links/manager) patterns…`);
walk(ROOT);
console.log('─'.repeat(60));
console.log(`Files affected:    ${filesModified}`);
console.log(`Replacements:      ${totalReplacements}`);
if (!WRITE) console.log('\n(dry run — pass --write to apply)');
