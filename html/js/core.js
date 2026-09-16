const XS = {
    resource: typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'XS-Mechanic',
    state: {},
    mode: 'tablet',
    panel: 'home',
    panels: {},
};

XS.post = async function (endpoint, payload) {
    try {
        const res = await fetch(`https://${XS.resource}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(payload || {}),
        });
        return await res.json();
    } catch (err) {
        return null;
    }
};

XS.el = function (tag, attrs, children) {
    const node = document.createElement(tag);

    for (const [key, value] of Object.entries(attrs || {})) {
        if (value === null || value === undefined || value === false) continue;

        if (key === 'class') node.className = value;
        else if (key === 'text') node.textContent = value;
        else if (key === 'html') node.innerHTML = value;
        else if (key.startsWith('on')) node.addEventListener(key.slice(2).toLowerCase(), value);
        else if (value === true) node.setAttribute(key, '');
        else node.setAttribute(key, value);
    }

    for (const child of [].concat(children || [])) {
        if (child === null || child === undefined || child === false) continue;
        node.append(child.nodeType ? child : document.createTextNode(String(child)));
    }

    return node;
};

XS.esc = function (value) {
    return String(value ?? '').replace(/[&<>"']/g, (ch) => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
    }[ch]));
};

XS.money = function (value) {
    const n = Math.round(Number(value) || 0);
    return (n < 0 ? '-$' : '$') + Math.abs(n).toLocaleString('en-US');
};

XS.num = function (value, digits) {
    return (Number(value) || 0).toLocaleString('en-US', {
        minimumFractionDigits: digits || 0,
        maximumFractionDigits: digits || 0,
    });
};

XS.ago = function (stamp) {
    if (!stamp) return '—';

    // The server sends os.time(), which is seconds. A millisecond stamp is
    // also just a number, so the magnitude decides rather than the type —
    // otherwise a stray ms value multiplies into the future and every row
    // reads "just now".
    const then = typeof stamp === 'number'
        ? (stamp > 1e11 ? stamp : stamp * 1000)
        : Date.parse(stamp);

    if (Number.isNaN(then)) return '—';

    const secs = Math.max(0, Math.floor((Date.now() - then) / 1000));
    if (secs < 60) return 'just now';
    if (secs < 3600) return `${Math.floor(secs / 60)}m ago`;
    if (secs < 86400) return `${Math.floor(secs / 3600)}h ago`;
    return `${Math.floor(secs / 86400)}d ago`;
};

// The open order against a plate. A mechanic who has just connected to a car
// wants to know this before anything else on the screen.
XS.orderFor = function (plate) {
    if (!plate) return null;

    const want = String(plate).trim().toUpperCase();

    return (XS.state.orders || []).find((order) =>
        (order.status === 'open' || order.status === 'claimed')
        && String(order.plate || '').trim().toUpperCase() === want) || null;
};

// What the shop has on the shelf for a kind of work. null means stock is
// switched off, and everything is fittable.
XS.stockFor = function (category) {
    const stock = XS.state.stock;
    if (!stock || !stock.items) return null;

    const item = (stock.categories || {})[category];
    if (!item) return null;

    return {
        item,
        label: (stock.labels || {})[item] || item,
        count: stock.items[item] || 0,
    };
};

XS.clear = function (node) {
    while (node.firstChild) node.removeChild(node.firstChild);
    return node;
};

XS.toast = function (message, kind) {
    const host = document.getElementById('toasts');
    const node = XS.el('div', { class: `toast ${kind || ''}`, text: message });

    host.append(node);

    setTimeout(() => {
        node.style.transition = 'opacity .2s, transform .2s';
        node.style.opacity = '0';
        node.style.transform = 'translateX(16px)';
        setTimeout(() => node.remove(), 220);
    }, 3200);
};

XS.modal = function ({ title, note, body, confirm, danger, onConfirm }) {
    const host = document.getElementById('modal');
    XS.clear(host);
    host.hidden = false;

    const close = () => { host.hidden = true; XS.clear(host); };

    const sheet = XS.el('div', { class: 'sheet' }, [
        XS.el('div', { class: 'mh' }, [
            XS.el('div', { class: 't', text: title || '' }),
            note ? XS.el('div', { class: 's', text: note }) : null,
        ]),
        XS.el('div', { class: 'mb' }, body || null),
        XS.el('div', { class: 'mf' }, [
            XS.el('button', { class: 'mini', text: 'Cancel', onclick: close }),
            confirm === false ? null : XS.el('button', {
                class: `mini ${danger ? 'danger' : 'hot'}`,
                text: confirm || 'Confirm',
                onclick: async () => {
                    const keep = onConfirm ? await onConfirm() : false;
                    if (keep !== true) close();
                },
            }),
        ]),
    ]);

    host.append(sheet);
    host.onclick = (ev) => { if (ev.target === host) close(); };

    return { close };
};

// One dialog for every price a shop sets. What happens on save is left to the
// caller, so the endpoint each one posts to is written where you can find it.
XS.askPrice = function ({ title, note, price, label, naming }, done) {
    const priceInput = XS.el('input', {
        type: 'number', min: '0', value: String(Math.round(Number(price) || 0)),
        style: 'width:100%',
    });

    const nameInput = naming ? XS.el('input', {
        type: 'text', value: label || '', maxlength: '48', style: 'width:100%',
    }) : null;

    XS.modal({
        title,
        note,
        confirm: 'Set it',
        body: XS.el('div', { style: 'display:flex;flex-direction:column;gap:14px' }, [
            nameInput ? XS.el('div', { class: 'field' }, [
                XS.el('label', { text: 'What it is called' }),
                nameInput,
            ]) : null,
            XS.el('div', { class: 'field' }, [
                XS.el('label', { text: 'Price' }),
                priceInput,
                XS.el('div', { class: 'hint', text: 'What the customer is charged. Zero makes it free.' }),
            ]),
        ]),
        onConfirm: () => done({
            price: Math.max(0, Math.round(Number(priceInput.value) || 0)),
            label: nameInput ? nameInput.value.trim() : undefined,
        }),
    });
};

XS.closeModal = function () {
    const host = document.getElementById('modal');
    host.hidden = true;
    XS.clear(host);
};

// A bar with a track, used by the strip and anywhere a percentage is shown.
XS.track = function (percent, tone) {
    return XS.el('div', { class: `trk ${tone || ''}` }, [
        XS.el('i', { style: `width:${Math.max(0, Math.min(100, Number(percent) || 0))}%` }),
    ]);
};

XS.cell = function (label, value, unit, percent, tone, cellTone) {
    return XS.el('div', { class: `cell ${cellTone || ''}` }, [
        XS.el('div', { class: 'k', text: label }),
        XS.el('div', { class: 'v' }, [
            String(value),
            unit ? XS.el('span', { class: 'u', text: unit }) : null,
        ]),
        percent === null || percent === undefined ? null : XS.track(percent, tone),
    ]);
};

XS.empty = function (title, note) {
    return XS.el('div', { class: 'empty' }, [
        XS.el('div', { class: 't', text: title }),
        note ? XS.el('div', { class: 's', text: note }) : null,
    ]);
};

// A top-level const lives in the global lexical scope, which every other
// script in the page can read by name but nothing can reach as a property.
// The browser preview and the website demo both drive the panel from outside,
// so it is published deliberately.
window.XS = XS;
