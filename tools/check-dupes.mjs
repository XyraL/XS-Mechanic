// No function defined twice on the same side.
//
// 1.0.5 added Framework.JobGrades for the boss check without noticing the file
// already had one — the grade list the Team app shows. Lua runs top to bottom,
// so the old one quietly replaced the new one, the boss check compared a table
// with a number, and every employee who was not flagged boss lost the tablet.
// Every other checker passed.
//
// Sides come from fxmanifest.lua first, then from the top-level
// IsDuplicityVersion() blocks the bridge files use to split themselves. A
// function on the shared side clashes with either.
import { readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function walk(dir, out = []) {
    for (const name of readdirSync(dir)) {
        if (name === 'node_modules' || name === 'tools' || name.startsWith('.')) continue;
        const full = path.join(dir, name);
        if (statSync(full).isDirectory()) walk(full, out);
        else if (name.endsWith('.lua') && name !== 'fxmanifest.lua') out.push(full);
    }
    return out;
}

// Which sides the manifest loads each file on.
const manifest = readFileSync(path.join(ROOT, 'fxmanifest.lua'), 'utf8');
const loaded = {};

for (const [block, side] of [['client_scripts', 'client'], ['server_scripts', 'server'], ['shared_scripts', 'shared']]) {
    const m = manifest.match(new RegExp(`${block}\\s*\\{([\\s\\S]*?)\\}`));
    if (!m) continue;

    for (const file of m[1].match(/'([^']+\.lua)'/g) || []) {
        const rel = file.slice(1, -1);
        (loaded[rel] ||= new Set()).add(side);
    }
}

function sidesOf(rel) {
    const set = loaded[rel];
    if (!set) return null;
    if (set.has('shared') || (set.has('client') && set.has('server'))) return 'shared';
    return set.has('server') ? 'server' : 'client';
}

const seen = new Map();
const problems = [];
let defs = 0;

for (const file of walk(ROOT)) {
    const rel = path.relative(ROOT, file).split(path.sep).join('/');
    const base = sidesOf(rel);
    if (!base) continue;

    let side = base;
    let block = null;

    readFileSync(file, 'utf8').split(/\r?\n/).forEach((line, i) => {
        if (/^if IsDuplicityVersion\(\) then return end/.test(line)) side = 'client';
        else if (/^if not IsDuplicityVersion\(\) then return end/.test(line)) side = 'server';
        else if (/^if IsDuplicityVersion\(\) then\s*$/.test(line)) block = 'server';
        else if (/^if not IsDuplicityVersion\(\)/.test(line)) block = 'client';
        else if (/^else\s*$/.test(line) && block) block = block === 'server' ? 'client' : 'server';
        else if (/^end\s*$/.test(line)) block = null;

        const m = line.match(/^\s*function\s+([A-Za-z_][\w]*(?:[.:][A-Za-z_]\w*)+)\s*\(/);
        if (!m) return;

        defs += 1;

        const name = m[1].replace(':', '.');
        const at = block || side;
        const list = seen.get(name) || [];

        for (const other of list) {
            if (other.side === at || other.side === 'shared' || at === 'shared') {
                problems.push(`${name} is defined twice on the ${at === 'shared' ? other.side : at} side — ${other.where} and ${rel}:${i + 1}`);
            }
        }

        list.push({ side: at, where: `${rel}:${i + 1}` });
        seen.set(name, list);
    });
}

if (problems.length) {
    console.error(`check-dupes — ${problems.length} function(s) defined twice\n`);
    for (const p of problems) console.error(`  ${p}`);
    process.exit(1);
}

console.log(`check-dupes ok — ${defs} function definitions, none defined twice on one side`);
