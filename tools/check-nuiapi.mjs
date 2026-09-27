// Every XS.* the interface calls has to exist.
//
// check-js parses the scripts, which says they are valid JavaScript and
// nothing about whether XS.subject.hide is a real function. It is not, and has
// not been since the camera window came out — two call sites stayed behind and
// took XS.close() down with them on every close, so Lua was never told the
// panel had gone and the mechanic was left holding a tablet prop.
//
// A browser only finds that at the moment somebody presses the button.
import { readdirSync, readFileSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const { join, relative } = path;

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'html', 'js');

function scripts(dir) {
    const out = [];

    for (const entry of readdirSync(dir)) {
        const path = join(dir, entry);

        if (statSync(path).isDirectory()) out.push(...scripts(path));
        else if (entry.endsWith('.js')) out.push(path);
    }

    return out;
}

// Strings and comments hold plenty that looks like code. Blanking them keeps
// a class name in an HTML template out of the member list.
function stripLiterals(src) {
    return src
        .replace(/\/\*[\s\S]*?\*\//g, ' ')
        .replace(/(^|[^:])\/\/[^\n]*/g, '$1 ')
        .replace(/`(?:\\.|\$\{[^}]*\}|[^`\\])*`/g, '``')
        .replace(/'(?:\\.|[^'\\])*'/g, "''")
        .replace(/"(?:\\.|[^"\\])*"/g, '""');
}

// From the opening brace to the one that closes it.
function block(src, open) {
    let depth = 0;

    for (let i = open; i < src.length; i += 1) {
        if (src[i] === '{') depth += 1;
        else if (src[i] === '}') {
            depth -= 1;
            if (depth === 0) return src.slice(open, i + 1);
        }
    }

    return '';
}

function members(objectLiteral) {
    const inner = objectLiteral.slice(1, -1);
    const found = new Set();

    // Shorthand and key: value alike, at this object's own depth only, so a
    // nested literal does not donate its keys to the parent.
    let depth = 0;

    for (const part of inner.split(/([{}[\]()])|,/)) {
        if (part === '{' || part === '[' || part === '(') { depth += 1; continue; }
        if (part === '}' || part === ']' || part === ')') { depth -= 1; continue; }
        if (depth !== 0 || !part) continue;

        const m = part.trim().match(/^(?:\.\.\.)?([A-Za-z_$][\w$]*)/);
        if (m) found.add(m[1]);
    }

    return found;
}

const files = scripts(ROOT);
const sources = new Map(files.map((f) => [f, stripLiterals(readFileSync(f, 'utf8'))]));

// ── What exists ─────────────────────────────────────────────────────────────
const roots = new Set();
const modules = new Map();

for (const [file, src] of sources) {
    // const XS = { ... } — the root object's own keys.
    const literal = src.match(/const\s+XS\s*=\s*\{/);
    if (literal) for (const key of members(block(src, literal.index + literal[0].length - 1))) roots.add(key);

    for (const m of src.matchAll(/XS\.([A-Za-z_$][\w$]*)\s*=(?!=)/g)) roots.add(m[1]);

    // XS.name = (function () { ... return { a, b }; })();
    for (const m of src.matchAll(/XS\.([A-Za-z_$][\w$]*)\s*=\s*\(function\s*\([^)]*\)\s*\{/g)) {
        const body = block(src, m.index + m[0].length - 1);

        // The IIFE's own return, not one belonging to a function inside it.
        // Taking the last is what the shape of these modules allows: the
        // returned object literal is the final statement.
        const ret = body.lastIndexOf('return {');
        if (ret < 0) continue;

        modules.set(m[1], { file, names: members(block(body, ret + 'return '.length)) });
    }
}

// ── What is called ──────────────────────────────────────────────────────────
const problems = [];

for (const [file, src] of sources) {
    const where = relative(ROOT, file).replace(/\\/g, '/');
    const lines = src.split('\n');

    lines.forEach((line, i) => {
        for (const m of line.matchAll(/\bXS\.([A-Za-z_$][\w$]*)\.([A-Za-z_$][\w$]*)/g)) {
            const [, mod, member] = m;

            const known = modules.get(mod);
            if (!known || known.names.has(member)) continue;

            problems.push(`${where}:${i + 1}  XS.${mod}.${member} — ${mod} exports `
                + `${[...known.names].sort().join(', ') || 'nothing'}`);
        }

        for (const m of line.matchAll(/\bXS\.([A-Za-z_$][\w$]*)/g)) {
            if (!roots.has(m[1])) problems.push(`${where}:${i + 1}  XS.${m[1]} is never assigned`);
        }
    });
}

if (problems.length) {
    console.error(`check-nuiapi — ${problems.length} call(s) to something that does not exist\n`);
    for (const p of problems) console.error(`  ${p}`);
    process.exit(1);
}

const summary = [...modules].map(([name, m]) => `${name} (${m.names.size})`).join(', ');
console.log(`check-nuiapi ok — ${roots.size} XS members, modules: ${summary}`);
