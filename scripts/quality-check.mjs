import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const failures = [];

function fail(message) {
  failures.push(message);
}

function trackedFiles(pattern) {
  const args = ['ls-files'];
  if (pattern) args.push(pattern);
  return execFileSync('git', args, { cwd: root, encoding: 'utf8' })
    .split('\n').filter(Boolean);
}

function parseJson(path) {
  try {
    return JSON.parse(readFileSync(resolve(root, path), 'utf8'));
  } catch (error) {
    fail(`${path}: invalid JSON (${error.message})`);
    return undefined;
  }
}

for (const path of trackedFiles('*.json')) parseJson(path);

const localePaths = [
  'AppScope/resources/base/element/string.json',
  'AppScope/resources/en_US/element/string.json',
  'AppScope/resources/zh_CN/element/string.json'
];
const localeKeys = localePaths.map((path) => {
  const document = parseJson(path);
  const keys = (document?.string ?? []).map((entry) => entry.name);
  if (new Set(keys).size !== keys.length) fail(`${path}: duplicate string resource name`);
  return new Set(keys);
});

if (localeKeys.length === 3) {
  const reference = [...localeKeys[0]].sort().join('\n');
  localeKeys.slice(1).forEach((keys, index) => {
    if ([...keys].sort().join('\n') !== reference) {
      fail(`${localePaths[index + 1]}: resource keys differ from the base locale`);
    }
  });
}

const sensitivePatterns = [
  /-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----/,
  /["'](?:storePassword|keyPassword)["']\s*:/,
  /\/Users\/[^/\s]+\/\.ohos\//,
  /ghp_[A-Za-z0-9]{30,}/,
  /github_pat_[A-Za-z0-9_]{30,}/
];

for (const path of trackedFiles()) {
  let content;
  try {
    content = readFileSync(resolve(root, path), 'utf8');
  } catch {
    continue;
  }
  if (sensitivePatterns.some((pattern) => pattern.test(content))) {
    fail(`${path}: possible credential or private signing path`);
  }
}

for (const readme of ['README.md', 'README.zh-CN.md']) {
  const content = readFileSync(resolve(root, readme), 'utf8');
  const links = content.matchAll(/\]\((?!https?:\/\/|mailto:|#)([^)#]+)(?:#[^)]*)?\)/g);
  for (const match of links) {
    const target = resolve(root, dirname(readme), decodeURIComponent(match[1]));
    if (!existsSync(target)) fail(`${readme}: missing local link target ${match[1]}`);
  }
}

const requiredFiles = [
  'LICENSE', 'CHANGELOG.md', 'CONTRIBUTING.md', 'CLA.md', 'CODE_OF_CONDUCT.md',
  'SECURITY.md', 'build-profile.example.json5', '.github/CODEOWNERS'
];
requiredFiles.forEach((path) => {
  if (!existsSync(resolve(root, path))) fail(`missing required file: ${path}`);
});

if (failures.length > 0) {
  console.error('Repository quality check failed:');
  failures.forEach((failure) => console.error(`- ${failure}`));
  process.exit(1);
}

console.log('Repository quality check passed.');
