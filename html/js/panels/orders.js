(function () {
    XS.panels.orders = function (host) {
        XS.clear(host);

        const filter = XS.state.orderFilter || 'open';
        const all = XS.state.orders || [];
        const connected = XS.state.vehicle?.plate || null;

        const counts = {
            open: all.filter((o) => o.status === 'open').length,
            claimed: all.filter((o) => o.status === 'claimed').length,
            done: all.filter((o) => o.status === 'done').length,
        };

        const tree = XS.el('aside', { class: 'tree' }, [XS.el('div', { class: 'grp', text: 'Work orders' })]);

        for (const [id, label] of [['open', 'Waiting'], ['claimed', 'In progress'], ['done', 'Finished'], ['all', 'Everything']]) {
            tree.append(XS.el('button', {
                class: `tn ${filter === id ? 'on' : ''}`,
                onclick: () => { XS.state.orderFilter = id; XS.rerender('orders'); },
            }, [
                XS.el('span', { class: 'n', text: label }),
                XS.el('span', {
                    class: `b ${id === 'open' && counts.open ? 'warn' : ''}`,
                    text: String(id === 'all' ? all.length : counts[id] || 0),
                }),
            ]));
        }

        host.append(tree);

        const grid = XS.el('section', { class: 'grid' });

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Work orders' }),
            XS.el('div', { class: 'cap', text: 'what the shop owes, and what is left to fit' }),
        ]));

        // The car in front of you comes first, whatever the filter says. That
        // is the whole point of carrying the tablet to the car.
        const shown = all
            .filter((o) => filter === 'all' || o.status === filter)
            .sort((a, b) => Number(isHere(b, connected)) - Number(isHere(a, connected)));

        if (!shown.length) {
            grid.append(XS.empty('Nothing waiting',
                'A customer picks what they want in a bay and sends it over. It lands here, and on the car when you connect to it.'));
            host.append(grid);
            return;
        }

        const rows = XS.el('div', { class: 'rows' });

        for (const order of shown) rows.append(row(order, connected));

        grid.append(rows);
        host.append(grid);
    };

    function isHere(order, plate) {
        if (!plate || !order.plate) return false;
        return String(order.plate).trim().toUpperCase() === String(plate).trim().toUpperCase();
    }

    function row(order, connected) {
        const here = isHere(order, connected);
        const tone = order.status === 'done' ? 'f' : order.status === 'claimed' ? 'p' : 'w';
        const parts = (order.requested || []).filter((entry) => entry && typeof entry === 'object');

        const total = parts.length;
        const done = parts.filter((p) => p.fitted).length;
        const owed = parts.some((p) => !p.billed);

        return XS.el('div', { class: here ? 'row lit' : 'row' }, [
            XS.el('div', {}, [
                XS.el('div', { class: 't' }, [
                    `${order.customerName || 'Unknown'} · ${order.plate || '——'}`,
                    here ? XS.el('span', { class: 'tag', text: 'CONNECTED' }) : null,
                    owed ? XS.el('span', { class: 'tag warn', text: 'UNBILLED' }) : null,
                ]),
                XS.el('div', { class: 'm', text: `${summarise(parts, done)} · ${XS.ago(order.createdAt)}` }),
                total ? XS.track(Math.round((done / total) * 100), done === total ? 'good' : '') : null,
                lines(order, parts, here),
                order.notes ? XS.el('div', {
                    style: 'font-size:12px;color:var(--dim);margin-top:8px;line-height:1.5',
                    text: order.notes,
                }) : null,
            ]),
            XS.el('div', { class: 'acts' }, [
                order.quote ? XS.el('span', { class: 'a', text: XS.money(order.quote) }) : null,
                XS.el('span', { class: `st ${tone}`, text: order.status.toUpperCase() }),
                order.status === 'open' ? XS.el('button', {
                    class: 'mini hot', text: 'Claim',
                    onclick: () => XS.post('claimOrder', { id: order.id }),
                }) : null,
                // Booked without billing, or added to since the last bill.
                owed && order.status !== 'done' ? XS.el('button', {
                    class: 'mini', text: 'Bill it',
                    onclick: () => XS.post('billOrder', { id: order.id }),
                }) : null,
                order.status === 'claimed' ? XS.el('button', {
                    class: 'mini', text: 'Finish',
                    onclick: () => XS.post('finishOrder', { id: order.id }),
                }) : null,
            ]),
        ]);
    }

    function summarise(parts, done) {
        if (!parts.length) return 'nothing listed';

        const seen = [];

        for (const pick of parts) {
            const label = pick.categoryLabel || pick.category;
            if (label && !seen.includes(label)) seen.push(label);
        }

        return `${done} of ${parts.length} fitted · ${seen.join(', ')}`;
    }

    // What the mechanic reads before walking to the bench. Each line says what
    // it is waiting on: a part to be made, a part on the shelf to go and get,
    // or nothing at all — those last ones have no part behind them and are the
    // only work this screen does itself.
    function lines(order, parts, here) {
        if (!parts.length) return null;

        const open = order.status !== 'done';
        const wrap = XS.el('div', { style: 'margin-top:10px;display:flex;flex-direction:column;gap:5px' });

        // Finished work drops to the bottom; what is left to do stays in view.
        const sorted = [...parts].sort((a, b) => Number(!!a.fitted) - Number(!!b.fitted));

        for (const pick of sorted) {
            const held = pick.needs ? XS.heldOf(pick.needs) : null;
            const short = !pick.fitted && pick.needs && held !== null && held < 1;

            wrap.append(XS.el('div', {
                class: 'ol',
                style: pick.fitted ? 'opacity:.55' : null,
            }, [
                XS.el('span', { class: 'n' }, [
                    XS.el('span', { class: 'c', text: (pick.categoryLabel || pick.category || '').toUpperCase() }),
                    pick.label,
                    pick.fitted ? XS.el('span', { class: 'tag', text: 'FITTED' }) : null,
                    short ? XS.el('span', { class: 'tag warn', text: 'MAKE ONE' }) : null,
                    !pick.fitted && pick.needs && !short
                        ? XS.el('span', { class: 'tag', text: (pick.needsLabel || pick.needs).toUpperCase() })
                        : null,
                ]),
                XS.el('span', { class: 'p', text: XS.money(pick.price) }),

                // No part to use, so there is nothing to hand the mechanic —
                // this is the one thing the tablet still does to a car.
                !pick.fitted && !pick.needs && here && open ? XS.el('button', {
                    class: 'mini', text: 'Do it',
                    onclick: () => XS.post('fitByHand'),
                }) : null,

                open && !pick.fitted ? XS.el('button', {
                    class: 'del', text: '×', title: 'Take this off the order',
                    onclick: () => XS.post('dropOrderLine', { id: order.id, line: pick.lid }),
                }) : null,
            ]));
        }

        return wrap;
    }
})();
