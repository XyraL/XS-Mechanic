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
            XS.el('div', { class: 'cap', text: 'sent in from the bays' }),
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

        return XS.el('div', { class: here ? 'row lit' : 'row' }, [
            XS.el('div', {}, [
                XS.el('div', { class: 't' }, [
                    `${order.customerName || 'Unknown'} · ${order.plate || '——'}`,
                    here ? XS.el('span', { class: 'tag', text: 'CONNECTED' }) : null,
                ]),
                XS.el('div', { class: 'm', text: `${summarise(parts)} · ${XS.ago(order.createdAt)}` }),
                lines(order, parts),
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
                order.status === 'claimed' ? XS.el('button', {
                    class: 'mini', text: 'Finish',
                    onclick: () => XS.post('finishOrder', { id: order.id }),
                }) : null,
            ]),
        ]);
    }

    function summarise(parts) {
        if (!parts.length) return 'nothing listed';

        const seen = [];

        for (const pick of parts) {
            const label = pick.categoryLabel || pick.category;
            if (label && !seen.includes(label)) seen.push(label);
        }

        return `${parts.length} part${parts.length === 1 ? '' : 's'} · ${seen.join(', ')}`;
    }

    // Each line can be taken off. A part the shop cannot get hold of should
    // come off the order rather than sit on it, and the quote follows it down.
    function lines(order, parts) {
        if (!parts.length) return null;

        const open = order.status !== 'done';
        const wrap = XS.el('div', { style: 'margin-top:10px;display:flex;flex-direction:column;gap:5px' });

        for (const [index, pick] of parts.entries()) {
            const stock = XS.stockFor(pick.category);

            wrap.append(XS.el('div', { class: 'ol' }, [
                XS.el('span', { class: 'n' }, [
                    XS.el('span', { class: 'c', text: (pick.categoryLabel || pick.category || '').toUpperCase() }),
                    pick.label,
                    stock && stock.count < 1
                        ? XS.el('span', { class: 'tag warn', text: 'MAKE ONE' })
                        : null,
                ]),
                XS.el('span', { class: 'p', text: XS.money(pick.price) }),
                open ? XS.el('button', {
                    class: 'del', text: '×', title: 'Take this off the order',
                    onclick: () => XS.post('dropOrderLine', { id: order.id, line: index }),
                }) : null,
            ]));
        }

        return wrap;
    }
})();
