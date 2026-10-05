import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const manifest = JSON.parse(readFileSync(join(root, 'manifest.json'), 'utf8'));
const groups = [
  ['mobile-rest', (item) => /^mobile-/.test(item.file) && Number(item.file.slice(7, 9)) >= 10, 6, 430, 930, 390, 844],
  ['curator-all', (item) => /^curator-/.test(item.file), 2, 1500, 970, 1440, 900],
  ['staff-all', (item) => /^staff-/.test(item.file), 2, 1500, 970, 1440, 900],
  ['admin-all', (item) => /^admin-/.test(item.file), 2, 1500, 970, 1440, 900],
];
const esc = (s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
for (const [key, keep, cols, dx, dy, cardW, cardH] of groups) {
  const items = manifest.filter(keep);
  const rows = Math.ceil(items.length / cols);
  const width = cols * dx + 40;
  const height = rows * dy + 90;
  const nodes = items.map((item, index) => {
    const x = 40 + (index % cols) * dx;
    const y = 70 + Math.floor(index / cols) * dy;
    const svg = readFileSync(join(root, item.file), 'utf8');
    const inner = svg.replace(/^<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '');
    return `<text x="${x}" y="${y-16}" fill="#6B2E2E" font-family="Noto Sans" font-size="17" font-weight="700">${esc(item.screen)}</text><g transform="translate(${x} ${y})">${inner}</g>`;
  });
  const result = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}"><rect width="${width}" height="${height}" fill="#E9DFD1"/><text x="40" y="38" fill="#3B302A" font-family="Noto Serif" font-size="28">SMGS · ${esc(key)}</text>${nodes.join('')}</svg>`;
  writeFileSync(join(root, `${key}.svg`), result);
  console.log(key, items.length, result.length, `${cardW}×${cardH}`);
}
