#!/usr/bin/env node
/**
 * Converts legacy GitHub-style callouts (> [!type] blockquotes) and legacy
 * markdown-it "/// details | Title ... ///" collapsibles to Rspress-compatible
 * syntax that the new docs platform actually renders.
 *
 * Callout mapping:
 *   > [!info]    -> :::info
 *   > [!warning] -> :::warning
 *   > [!primary] -> :::info     (legacy "primary" is GitHub-flavored "note")
 *   > [!tip]     -> :::tip
 *   > [!danger]  -> :::danger
 *   > [!success] -> :::tip
 *
 * Collapsible mapping:
 *   /// details | Title          ->  <details>
 *   <body>                           <summary>Title</summary>
 *   ///                              <body>
 *                                    </details>
 *
 * Both patterns preserve any leading indentation (they may live inside <Tab>
 * blocks).
 *
 * Run with: node scripts/migrate/fix-callouts-and-details.mjs [--dry]
 */
import { globSync, readFileSync, writeFileSync } from 'node:fs';

const DRY = process.argv.includes('--dry');

const CALLOUT_MAP = {
  info: 'info',
  warning: 'warning',
  primary: 'info',
  tip: 'tip',
  danger: 'danger',
  success: 'tip',
};

function convertCallouts(lines) {
  const out = [];
  let i = 0;
  let count = 0;
  while (i < lines.length) {
    const line = lines[i];
    const m = line.match(/^(\s*)>\s*\[!([a-z]+)\]\s*$/);
    if (!m || !(m[2] in CALLOUT_MAP)) {
      out.push(line);
      i++;
      continue;
    }
    const indent = m[1];
    const target = CALLOUT_MAP[m[2]];
    // gather subsequent `>` lines as body
    const body = [];
    let j = i + 1;
    while (j < lines.length) {
      const bm = lines[j].match(/^(\s*)>(.*)$/);
      if (!bm) break;
      // body line: strip the "> " prefix
      const stripped = bm[2].replace(/^ ?/, '');
      body.push(`${indent}${stripped}`);
      j++;
    }
    // trim leading/trailing blank body lines (legacy blocks often had `>` blanks)
    while (body.length && /^\s*$/.test(body[0])) body.shift();
    while (body.length && /^\s*$/.test(body[body.length - 1])) body.pop();
    out.push(`${indent}:::${target}`);
    out.push(...body);
    out.push(`${indent}:::`);
    count++;
    i = j;
  }
  return { lines: out, count };
}

function convertDetails(lines) {
  const out = [];
  let i = 0;
  let count = 0;
  while (i < lines.length) {
    const line = lines[i];
    const open = line.match(/^(\s*)\/\/\/\s*details\s*\|\s*(.+?)\s*$/);
    if (!open) {
      out.push(line);
      i++;
      continue;
    }
    const indent = open[1];
    const title = open[2];
    // find the matching closing /// at the same indent
    let j = i + 1;
    while (j < lines.length) {
      const closeRe = new RegExp(`^${indent}///\\s*$`);
      if (closeRe.test(lines[j])) break;
      j++;
    }
    if (j >= lines.length) {
      // no matching close — leave the block as-is to avoid mangling
      out.push(line);
      i++;
      continue;
    }
    const body = lines.slice(i + 1, j);
    // trim leading/trailing blank body lines
    while (body.length && /^\s*$/.test(body[0])) body.shift();
    while (body.length && /^\s*$/.test(body[body.length - 1])) body.pop();
    out.push(`${indent}<details>`);
    out.push(`${indent}<summary>${title}</summary>`);
    out.push('');
    out.push(...body);
    out.push('');
    out.push(`${indent}</details>`);
    count++;
    i = j + 1;
  }
  return { lines: out, count };
}

const files = globSync('docs/**/*.mdx', { nodir: true });
let filesChanged = 0;
let callouts = 0;
let details = 0;

for (const file of files) {
  const src = readFileSync(file, 'utf8');
  const lines = src.split('\n');
  const c = convertCallouts(lines);
  const d = convertDetails(c.lines);
  if (c.count === 0 && d.count === 0) continue;
  filesChanged++;
  callouts += c.count;
  details += d.count;
  if (!DRY) writeFileSync(file, d.lines.join('\n'));
}

console.log(`Files changed: ${filesChanged}`);
console.log(`Callouts converted: ${callouts}`);
console.log(`Details blocks converted: ${details}`);
