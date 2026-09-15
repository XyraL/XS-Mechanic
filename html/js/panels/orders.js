(function () {
    XS.panels.orders = function (host) {
        XS.clear(host);

        const filter = XS.state.orderFilter || 'open';
        const all = XS.state.orders || [];

        const counts = {
            open: all.filter((o) => o.status === 'open').length,
            claimed: all.filter((o) => o.status === 'claimed').length,
            done: all.filter((o) => o.status === 'done').length,
        };

        const tree = XS.el('aside', { class: 'tree' }, [XS.el('div', { class: 'grp', text: 'Work orders' })]);

        for (const [id, label] of [['open', 'Waiting'], ['claimed', 'In progress'], ['done', 'Finished'], ['all', 'Everything']]) {
            tree.append(XS.el('button', {
                class: `tn ${filter === id ? 'on' : ''}`,
                onclick: () => { XS.state.orderFilter = id; XS.panels.orders(host); },
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
        const shown = all.filter((o) => filter === 'all' || o.status === filter);

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Work orders' }),
            XS.el('div', { class: 'cap', text: 'left at the desk by customers' }),
        ]));

        if (!shown.length) {
            grid.append(XS.empty('Nothing waiting',
                'Customers leave a job here when nobody is around to ask. Claim one and it is yours.'));
            host.append(grid);
            return;
        }

        const rows = XS.el('div', { class: 'rows' });

        for (const order of shown) {
            const tone = order.status === 'done' ? 'f' : order.status === 'claimed' ? 'p' : 'w';

            rows.append(XS.el('div', { class: 'row' }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 't', text: `${order.customerName || 'Unknown'} · ${order.plate || '——'}` }),
                    XS.el('div', { class: 'm', text: summarise(order.requested) + ' · ' + XS.ago(order.createdAt) }),
                    picks(order.requested),
                    order.notes ? XS.el('div', { style: 'font-size:12px;color:var(--dim);margin-top:8px;line-height:1.5', text: order.notes }) : null,
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
            ]));
        }

        grid.append(rows);
        host.append(grid);
    };

    // An order arrives one of two ways: a list of categories ticked at the
    // desk, or the actual parts a customer picked and looked at in a bay.
    function summarise(requested) {
        const list = requested || [];
        if (!list.length) return 'nothing listed';

        if (typeof list[0] === 'string') return list.join(', ');

        const seen = [];
        for (const pick of list) {
            const label = pick.categoryLabel || pick.category;
            if (label && !seen.includes(label)) seen.push(label);
        }

        return `${list.length} part${list.length === 1 ? '' : 's'} · ${seen.join(', ')}`;
    }

    // Only a bay order has parts to show; a desk order has nothing to list.
    function picks(requested) {
        const list = (requested || []).filter((entry) => typeof entry === 'object' && entry.label);
        if (!list.length) return null;

        const wrap = XS.el('div', { style: 'margin-top:10px;display:flex;flex-direction:column;gap:5px' });

        for (const pick of list) {
            wrap.append(XS.el('div', {
                style: 'display:flex;justify-content:space-between;gap:12px;font-size:12px;padding:5px 9px;background:var(--sunk);border:1px solid var(--line);border-radius:6px',
            }, [
                XS.el('span', {}, [
                    XS.el('span', { style: 'color:var(--faint);font:10px/1 var(--mono);letter-spacing:.08em;margin-right:8px', text: (pick.categoryLabel || pick.category || '').toUpperCase() }),
                    pick.label,
                ]),
                XS.el('span', { style: 'font:600 12px/1 var(--mono);color:var(--accent2)', text: XS.money(pick.price) }),
            ]));
        }

        return wrap;
    }
})();
