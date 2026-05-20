/**
 * Compress PNGs and enforce a 0.5 MB size limit on PNGs and JPEGs.
 *
 * PNGs are compressed once; running the script again on an already-compressed
 * file does nothing. JPEGs are never compressed (each pass would lose quality)
 * — only the size limit applies.
 *
 * Usage:
 *   pnpm images:compress <path>...   # compress files in place
 *   pnpm images:check    <path>...   # dry-run, recap of findings
 *
 * <path> can be a file or a directory (walked recursively for .png/.jpg/.jpeg).
 */

import { stat, writeFile } from 'node:fs/promises';
import { extname } from 'node:path';
import { glob } from 'glob';
import sharp from 'sharp';

const MAX_SIZE_BYTES = 512 * 1024; // 0.5 MB
const SUPPORTED_EXTENSIONS = ['.png', '.jpg', '.jpeg'];

type CompressedPng = {
  originalSize: number;
  buffer: Buffer;
};

type CompressedFile = {
  path: string;
  originalSize: number;
  compressedSize: number;
};

function isPngFile(filePath: string): boolean {
  return extname(filePath).toLowerCase() === '.png';
}

async function isPalettePng(filePath: string): Promise<boolean> {
  if (!isPngFile(filePath)) return false;
  return (await sharp(filePath).metadata()).isPalette === true;
}

async function compressPng(filePath: string): Promise<CompressedPng> {
  const originalSize = (await stat(filePath)).size;
  const buffer = await sharp(filePath)
    .png({ quality: 90, compressionLevel: 9 })
    .toBuffer();
  return { originalSize, buffer };
}

function isSupportedImage(filePath: string): boolean {
  return SUPPORTED_EXTENSIONS.includes(extname(filePath).toLowerCase());
}

async function collectImageFiles(paths: string[]): Promise<string[]> {
  const files = await Promise.all(
    paths.map(async (path) => {
      if ((await stat(path)).isDirectory()) {
        // For directories, search recursively for image files inside
        return glob(`**/*{${SUPPORTED_EXTENSIONS.join(',')}}`, {
          cwd: path,
          absolute: true,
          nodir: true,
          nocase: true,
        });
      } else {
        // For files, just include them if supported; the filter at the end removes unsupported ones
        return [path];
      }
    }),
  );
  return files.flat().filter(isSupportedImage);
}

async function runCompress(files: string[]): Promise<void> {
  const compressedFiles: CompressedFile[] = [];

  for (const file of files) {
    if (!isPngFile(file)) continue;
    if (await isPalettePng(file)) continue; // already in compressed form, accept as-is
    const compressionResult = await compressPng(file);
    await writeFile(file, compressionResult.buffer);
    compressedFiles.push({
      path: file,
      originalSize: compressionResult.originalSize,
      compressedSize: compressionResult.buffer.length,
    });
  }

  const saved = compressedFiles.reduce(
    (total, file) => total + file.originalSize - file.compressedSize,
    0,
  );
  const recap = [
    `Compressed ${compressedFiles.length} of ${files.length} image(s), ${formatMb(saved)} saved.`,
    ...compressedFiles.map(
      (file) =>
        `✓ ${file.path}  ${formatMb(file.originalSize)} → ${formatMb(file.compressedSize)}`,
    ),
  ];

  console.log(recap.join('\n'));
}

type Finding = CompressionFinding | ResizeFinding;

type CompressionFinding = {
  kind: 'compress';
  path: string;
  originalSize: number;
  compressedSize: number;
};

type ResizeFinding = {
  kind: 'resize';
  path: string;
  size: number;
};

async function runCheck(files: string[]): Promise<void> {
  const findings: Finding[] = [];

  for (const file of files) {
    // Only truecolor PNGs are evaluated for compressibility. Palette PNGs and
    // JPEGs are accepted as-is and only checked against the size ceiling.
    const isTruecolorPng = isPngFile(file) && !(await isPalettePng(file));

    if (!isTruecolorPng) {
      const originalSize = (await stat(file)).size;
      if (originalSize > MAX_SIZE_BYTES) {
        findings.push({ kind: 'resize', path: file, size: originalSize });
      }
      continue;
    }

    const compressionResult = await compressPng(file);
    const finalSize = compressionResult.buffer.length;

    if (finalSize > MAX_SIZE_BYTES) {
      findings.push({ kind: 'resize', path: file, size: finalSize });
    } else {
      findings.push({
        kind: 'compress',
        path: file,
        originalSize: compressionResult.originalSize,
        compressedSize: compressionResult.buffer.length,
      });
    }
  }

  if (findings.length === 0) {
    console.log(`${files.length} images OK.`);
    return;
  }

  console.error(formatCheckReport(findings, files.length));
  process.exit(1);
}

async function main(): Promise<void> {
  const userArgs = process.argv.slice(2);
  const isCheckMode = userArgs.includes('--check');
  const imagePaths = userArgs.filter((arg) => arg !== '--check');

  if (imagePaths.length === 0) {
    console.error(
      'Missing image paths. Usage: optimize-images [--check] <path>...',
    );
    process.exit(2);
  }

  const imageFiles = await collectImageFiles(imagePaths);
  if (imageFiles.length === 0) {
    console.log('No images to process.');
    return;
  }

  await (isCheckMode ? runCheck(imageFiles) : runCompress(imageFiles));
}

/********************************************************************************
 * Reporting helpers
 *******************************************************************************/
function formatMb(bytes: number): string {
  return `${(bytes / 1024 / 1024).toFixed(2)} MB`;
}

function formatFinding(finding: Finding): string {
  if (finding.kind === 'resize') {
    return (
      `- \`${finding.path}\` is **${formatMb(finding.size)}**, over the ${formatMb(MAX_SIZE_BYTES)} limit.\n` +
      '  → Please crop or resize to smaller size.'
    );
  }

  return (
    `- \`${finding.path}\` is ${formatMb(finding.originalSize)} but compresses to **${formatMb(finding.compressedSize)}**.\n` +
    '  → Please run `pnpm images:compress` and commit the result.'
  );
}

function formatCheckReport(findings: Finding[], checkedCount: number): string {
  const toCompress = findings.filter((f) => f.kind === 'compress').length;
  const toResize = findings.length - toCompress;

  const counts: string[] = [];
  if (toCompress > 0) counts.push(`${toCompress} image(s) to compress`);
  if (toResize > 0) counts.push(`${toResize} image(s) to crop or resize`);

  const summary = `**${counts.join(', ')}** — ${checkedCount} image(s) checked in total.`;

  return [...findings.map(formatFinding), summary].join('\n\n');
}

main();
