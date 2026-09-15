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
                    XS.el('div', {
                        class: 'm',
                        text: `${(order.requested || []).join(', ') || 'no categories'} · ${XS.ago(order.createdAt)}`,
                    }),
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
})();
