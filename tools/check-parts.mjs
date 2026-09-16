// Every item name the resource USES has to exist in both item blocks, or the
// thing that needs it silently never works: a category whose part is spelled
// wrong can never be fitted, and a recipe whose output is spelled wrong makes
// an item nobody's inventory has heard of.
//
// Raw crafting material is deliberately exempt — scrap and steel come from
// whatever the server already has, and the config points at those names.
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (file) => readFileSync(path.join(ROOT, file), 'utf8');

const config = read('config.lua');
const tuning = read('shared/tuning.lua');

const ox = read('items/ox_inventory.lua');
const qb = read('items/qb_core.lua');

function defined(source) {
    return new Set([...source.matchAll(/^\['([a-z0-9_]+)'\]\s*=/gm)].map((m) => m[1]));
}

const inOx = defined(ox);
const inQb = defined(qb);

// Where each name comes from, so a failure says which line to go and look at.
const wanted = new Map();

function want(item, from) {
    if (!item || item === '' || item === 'nil') return;
    if (!wanted.has(item)) wanted.set(item, new Set());
    wanted.get(item).add(from);
}

// Config.Parts.categoryItems = { cosmetics = 'body_part', ... }
const categoryBlock = config.match(/Config\.Parts\.categoryItems\s*=\s*\{([\s\S]*?)\n\}/);
if (categoryBlock) {
    for (const m of categoryBlock[1].matchAll(/([a-zA-Z]+)\s*=\s*'([^']*)'/g)) {
        want(m[2], `Config.Parts.categoryItems.${m[1]}`);
    }
}

// Config.Crafting.recipes = { { item = 'body_part', ... }, ... }
const recipeBlock = config.match(/recipes\s*=\s*\{([\s\S]*?)\n    \},/);
if (recipeBlock) {
    for (const m of recipeBlock[1].matchAll(/item\s*=\s*'([^']+)'/g)) {
        want(m[1], 'Config.Crafting.recipes');
    }
}

// Config.Parts = { { item = 'repair_kit', ... } } — the counter list.
const countersBlock = config.match(/Config\.Parts\s*=\s*\{([\s\S]*?)\n\}/);
if (countersBlock) {
    for (const m of countersBlock[1].matchAll(/item\s*=\s*'([^']+)'/g)) {
        want(m[1], 'Config.Parts');
    }
}

// Config.Repair.kits = { repair_kit = { ... } }
const kitsBlock = config.match(/kits\s*=\s*\{([\s\S]*?)\n    \},/);
if (kitsBlock) {
    for (const m of kitsBlock[1].matchAll(/^        ([a-z0-9_]+)\s*=\s*\{/gm)) {
        want(m[1], 'Config.Repair.kits');
    }
}

for (const [key, from] of [['Tablet', 'Config.Tablet.item'], ['Nitrous', 'Config.Nitrous.item'], ['Lighting', 'Config.Lighting.item']]) {
    const found = config.match(new RegExp(`Config\\.${key}\\s*=\\s*\\{[\\s\\S]*?item\\s*=\\s*'([^']*)'`));
    if (found) want(found[1], from);
}

// shared/tuning.lua: every package names the item the shop supplies.
for (const m of tuning.matchAll(/item\s*=\s*'([^']+)'/g)) {
    want(m[1], 'shared/tuning.lua');
}

// shared/service.lua: every worn part names what replaces it.
for (const m of read('shared/service.lua').matchAll(/item\s*=\s*'([^']+)'/g)) {
    want(m[1], 'shared/service.lua');
}

// The wash kit, which lives on its own.
const wash = config.match(/wash\s*=\s*\{[^}]*item\s*=\s*'([^']*)'/);
if (wash) want(wash[1], 'Config.Repair.wash.item');

const problems = [];

for (const [item, from] of wanted) {
    const missing = [];
    if (!inOx.has(item)) missing.push('items/ox_inventory.lua');
    if (!inQb.has(item)) missing.push('items/qb_core.lua');

    if (missing.length) {
        problems.push(`  '${item}' (${[...from].join(', ')}) is not in ${missing.join(' or ')}`);
    }
}

// Service parts are named in shared/service.lua and already covered by the
// blocks above only if a config entry points at them, so they are counted
// here for the total rather than checked twice.
console.log(`check-parts — ${wanted.size} item names used, ${inOx.size} defined for ox, ${inQb.size} for qb`);

if (problems.length) {
    console.log(`\n${problems.length} item(s) the resource uses but no inventory has:`);
    for (const line of problems) console.log(line);
    process.exit(1);
}

console.log('every item the resource uses is defined in both item blocks');
