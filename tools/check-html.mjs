// Every tag in html/index.html has to close where it opened, and the tablet
// has to sit inside the element that hides it.
//
// The car preview came out in 1.0.0 as a two-line deletion that left the
// element's closing tag behind. That </div> closed #root two lines after it
// opened, so the whole tablet became a child of <body> instead: painted from
// resource start, outside the only rule that hides it, unreachable by every
// close path. Fifteen checkers passed on that tree. None of them read the
// markup.
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const FILE = path.resolve(HERE, '..', 'html', 'index.html');

const VOID = new Set(['area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'source', 'track', 'wbr']);

// The stylesheet gates visibility on #root and nothing else. Anything with a
// paint of its own that is not inside it is on screen from the moment the
// page loads.
const GATE = { id: 'root', mustHold: ['device'] };

// Comments and script/style bodies hold plenty that looks like a tag. They
// are blanked rather than removed so line numbers still mean something.
function blank(s) {
    return s.replace(/[^\n]/g, ' ');
}

const raw = readFileSync(FILE, 'utf8');
const src = raw
    .replace(/<!--[\s\S]*?-->/g, blank)
    .replace(/(<script\b[^>]*>)([\s\S]*?)(<\/script>)/gi, (_, open, body, close) => open + blank(body) + close)
    .replace(/(<style\b[^>]*>)([\s\S]*?)(<\/style>)/gi, (_, open, body, close) => open + blank(body) + close);

const stack = [];
const problems = [];
const parents = {};
let elements = 0;
let line = 1;
let at = 0;

for (const m of src.matchAll(/<\/?([a-zA-Z][\w-]*)\b([^>]*)>/g)) {
    line += (src.slice(at, m.index).match(/\n/g) || []).length;
    at = m.index;

    const tag = m[1].toLowerCase();
    const attrs = m[2] || '';
    const closing = m[0][1] === '/';

    if (closing) {
        const top = stack.pop();

        if (!top) {
            problems.push(`line ${line}: </${tag}> with nothing open — a stray closing tag`);
        } else if (top.tag !== tag) {
            problems.push(`line ${line}: </${tag}> closes <${top.tag}${top.id ? '#' + top.id : ''}> opened on line ${top.line}`);
            stack.push(top);
        }

        continue;
    }

    if (VOID.has(tag) || attrs.trim().endsWith('/')) continue;

    const id = (attrs.match(/\bid="([^"]+)"/) || [])[1] || null;
    const classes = ((attrs.match(/\bclass="([^"]+)"/) || [])[1] || '').split(/\s+/).filter(Boolean);

    for (const cls of classes) {
        if (GATE.mustHold.includes(cls)) parents[cls] = stack.map((s) => s.id).filter(Boolean);
    }

    stack.push({ tag, id, line });
    elements += 1;
}

for (const open of stack) {
    problems.push(`line ${open.line}: <${open.tag}${open.id ? '#' + open.id : ''}> is never closed`);
}

for (const cls of GATE.mustHold) {
    if (!(cls in parents)) {
        problems.push(`.${cls} is not in the page at all`);
    } else if (!parents[cls].includes(GATE.id)) {
        problems.push(`.${cls} is not inside #${GATE.id} — it is on screen from the moment the page loads and nothing can hide it`);
    }
}

if (problems.length) {
    console.error(`check-html — ${problems.length} problem(s) in html/index.html\n`);
    for (const p of problems) console.error(`  ${p}`);
    process.exit(1);
}

console.log(`check-html ok — ${elements} elements balanced, ${GATE.mustHold.map((c) => '.' + c).join(', ')} inside #${GATE.id}`);
