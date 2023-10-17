import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

const SRC_DIR = new URL('../src/components', import.meta.url).pathname;
const SRC_FILENAME = 'usage.gts';
const DEST_FILE = new URL('../src/usage.ts', import.meta.url).pathname;
const PREFIX = `
// This file is auto-generated by 'pnpm rebuild:usage'
/* eslint-disable simple-import-sort/imports */
`;

let componentsToInclude = walk(SRC_DIR)
  .flat(Number.POSITIVE_INFINITY)
  .filter((filename) => path.parse(filename).base == SRC_FILENAME)
  .map((filename) => {
    let usageKlassName = filename
      .replace(SRC_DIR, '')
      .replace('.gts', '')
      .split('/')
      .filter(Boolean)
      .map((s) => toPascalCase(s))
      .join('');
    return {
      name: usageKlassName,
      componentName: usageKlassName.replace(/Usage$/, ''),
      sourceFile: filename,
    };
  });
componentsToInclude.sort((a, b) => a.sourceFile.localeCompare(b.sourceFile));

let indexContents = PREFIX + '\n';
indexContents += componentsToInclude
  .map(
    (c) =>
      `import ${c.name} from './components${c.sourceFile.replace(
        SRC_DIR,
        '',
      )}';`,
  )
  .join('\n');
indexContents += '\n\n';
let componentPairs = componentsToInclude.map(
  (c) => `['${c.componentName}', ${c.name}]`,
);
indexContents += `export const ALL_USAGE_COMPONENTS = [\n  ${componentPairs.join(
  ',\n  ',
)}\n];\n`;
// indexContents += `export {\n  ${componentNameArray.join(',\n  ')}\n};\n`;
fs.writeFileSync(DEST_FILE, indexContents);

execSync(`prettier -w ${DEST_FILE}`);

function walk(dirPath) {
  let entries = fs.readdirSync(dirPath, { withFileTypes: true });
  return entries.map((entry) => {
    const childPath = path.join(dirPath, entry.name);
    return entry.isDirectory() ? walk(childPath) : childPath;
  });
}

function toPascalCase(text) {
  return text.replace(/(^\w|-\w)/g, clearAndUpper);
}

function clearAndUpper(text) {
  return text.replace(/-/, '').toUpperCase();
}
