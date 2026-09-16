// Every part the shop CONSUMES has to be a part the bench can MAKE, or a shop
// runs out of it and there is no way back. The gap is silent: the tablet says
// "none left, make one at the bench" and the bench has never heard of it.
//
// The reverse is checked too — a recipe producing something nothing uses is a
// card taking up space on the bench.
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (file) => readFileSync(path.join(ROOT, file), 'utf8');

const config = read('config.lua');
const tuning = read('shared/tuning.lua');

// Servicing was the list nobody checked. Nine parts a mechanic is asked for
// every time a car comes in, none of them obtainable anywhere in the resource —
// and this checker reported a clean run because it had never been pointed at
// the file they live in. A checker is only as honest as its sources.
const service = read('shared/service.lua');

function block(source, opener, closer) {
    const found = source.match(new RegExp(`${opener}\\s*=\\s*\\{([\\s\\S]*?)\\n${closer}\\}`));
    return found ? found[1] : null;
}

// What the bench makes.
const recipeBlock = block(config, 'recipes', '    ');
if (!recipeBlock) throw new Error('Config.Crafting.recipes not found');

const makes = new Set([...recipeBlock.matchAll(/item\s*=\s*'([^']+)'/g)].map((m) => m[1]));

// What work uses up. Three sources, and every one of them has bitten.
const consumes = new Map();

function consumed(item, from) {
    if (!item || item === '') return;
    if (!consumes.has(item)) consumes.set(item, new Set());
    consumes.get(item).add(from);
}

const categoryBlock = block(config, 'categoryItems', '    ');
if (!categoryBlock) throw new Error('Config.Stock.categoryItems not found');

for (const m of categoryBlock.matchAll(/([a-zA-Z]+)\s*=\s*'([^']*)'/g)) {
    consumed(m[2], `category ${m[1]}`);
}

const slotBlock = block(config, 'slotItems', '    ');
if (!slotBlock) throw new Error('Config.Stock.slotItems not found');

for (const m of slotBlock.matchAll(/([a-zA-Z]+)\s*=\s*'([^']*)'/g)) {
    consumed(m[2], `slot ${m[1]}`);
}

// Every custom tuning package names the item the shop supplies.
for (const m of tuning.matchAll(/id\s*=\s*'([^']+)'[\s\S]{0,400}?item\s*=\s*'([^']+)'/g)) {
    consumed(m[2], `tuning ${m[1]}`);
}

// Every worn part names what replaces it.
for (const m of service.matchAll(/id\s*=\s*'([^']+)'[\s\S]{0,300}?item\s*=\s*'([^']+)'/g)) {
    consumed(m[2], `service ${m[1]}`);
}

const kitBlock = block(config, 'kits', '    ');

if (kitBlock) {
    for (const m of kitBlock.matchAll(/^        ([a-z0-9_]+)\s*=\s*\{/gm)) {
        consumed(m[1], 'repair kit');
    }
}

const missing = [];

for (const [item, from] of consumes) {
    if (!makes.has(item)) missing.push(`  '${item}' is used by ${[...from].join(', ')} but the bench cannot make it`);
}

// Raw material is bought or found, not made, so it is exempt from the reverse
// check along with anything a player is meant to be given.
const NOT_MADE_HERE = new Set(['mechanic_tablet', 'nitrous', 'lighting_remote', 'cleaning_kit']);

const orphans = [];

for (const item of makes) {
    if (consumes.has(item) || NOT_MADE_HERE.has(item)) continue;
    orphans.push(`  '${item}' can be made but nothing ever uses it`);
}

console.log(`check-craftable — ${makes.size} recipes, ${consumes.size} items consumed`);

if (missing.length || orphans.length) {
    if (missing.length) {
        console.log(`\n${missing.length} part(s) a shop can run out of and never get back:`);
        for (const line of missing) console.log(line);
    }

    if (orphans.length) {
        console.log(`\n${orphans.length} recipe(s) nothing uses:`);
        for (const line of orphans) console.log(line);
    }

    process.exit(1);
}

console.log('everything the shop uses, the bench can make');
