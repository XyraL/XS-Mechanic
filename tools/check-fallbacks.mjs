// The stub-and-warn list in client/fallbacks.lua only covers globals somebody
// remembered to add to it. This inverts that: find every top-level global the
// client files define, and assert each one is either CORE (the resource cannot
// run without it) or covered by an optional(...) stub.
//
// Adding a module then forces the decision instead of leaving a hole to find
// in game.
import { readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifest = readFileSync(path.join(ROOT, 'fxmanifest.lua'), 'utf8');

// Globals the resource genuinely cannot run without, so stubbing them would
// hide a fatal problem rather than soften it.
const CORE = new Set(['Config', 'Util', 'Mods', 'Framework', 'Inventory', 'Target', 'XSM']);

function block(name) {
    const found = manifest.match(new RegExp(`${name}\\s*\\{([\\s\\S]*?)\\n\\}`, 'm'));
    if (!found) return [];

    return [...found[1].matchAll(/['"]([^'"]+)['"]/g)]
        .map((m) => m[1])
        .filter((entry) => !entry.startsWith('@') && entry.endsWith('.lua'));
}

const clientFiles = [...block('shared_scripts'), ...block('client_scripts')];
const fallbacksPath = path.join(ROOT, 'client/fallbacks.lua');

if (!existsSync(fallbacksPath)) {
    console.log('check-fallbacks FAILED');
    console.log('  client/fallbacks.lua is missing');
    process.exit(1);
}

const fallbacks = readFileSync(fallbacksPath, 'utf8');
const stubbed = new Set(
    [...fallbacks.matchAll(/optional\(\s*['"]([^'"]+)['"]/g)].map((m) => m[1]),
);

const defined = new Map();

for (const file of clientFiles) {
    if (file.endsWith('fallbacks.lua')) continue;

    const full = path.join(ROOT, file);
    if (!existsSync(full)) continue;

    const src = readFileSync(full, 'utf8');

    // A top-level assignment with no `local` in front of it.
    for (const m of src.matchAll(/^([A-Z][A-Za-z0-9_]*)\s*=\s*\{/gm)) {
        if (!defined.has(m[1])) defined.set(m[1], file);
    }
}

const problems = [];

for (const [name, file] of defined) {
    if (CORE.has(name) || stubbed.has(name)) continue;
    problems.push(`global '${name}' (${file}) is neither CORE nor stubbed in client/fallbacks.lua`);
}

for (const name of stubbed) {
    if (!defined.has(name)) {
        problems.push(`fallbacks stubs '${name}' but nothing defines it any more`);
    }
}

if (problems.length) {
    console.log('check-fallbacks FAILED');
    for (const problem of problems) console.log(`  ${problem}`);
    process.exit(1);
}

console.log(`check-fallbacks ok — ${defined.size} globals, ${stubbed.size} stubbed`);
