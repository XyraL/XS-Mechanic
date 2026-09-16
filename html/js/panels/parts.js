(function () {
    XS.panels.parts = function (host) {
        XS.clear(host);

        const counters = XS.state.counters || [];
        const chosen = XS.state.counterId || (counters[0] && counters[0].id) || null;

        const tree = XS.el('aside', { class: 'tree' }, [XS.el('div', { class: 'grp', text: 'Counters' })]);

        for (const counter of counters) {
            tree.append(XS.el('button', {
                class: `tn ${chosen === counter.id ? 'on' : ''}`,
                onclick: () => { XS.state.counterId = counter.id; XS.panels.parts(host); },
            }, [
                XS.el('span', { class: 'n', text: counter.label || 'Parts counter' }),
                XS.el('span', { class: 'b', text: String((counter.items || []).length) }),
            ]));
        }

        if (!counters.length) tree.append(XS.el('div', { class: 'grp', text: 'None placed' }));

        host.append(tree);

        const grid = XS.el('section', { class: 'grid' });
        const counter = counters.find((c) => c.id === chosen);

        if (!counter) {
            grid.append(XS.empty('No parts counter',
                'An admin places counters in the shop builder. Without one there is nowhere to buy from.'));
            host.append(grid);
            return;
        }

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: counter.label || 'Parts counter' }),
            XS.el('div', { class: 'cap' }, [
                XS.state.partsPaidBy === 'player' ? 'paid from your own pocket' : 'paid from shop funds',
                XS.state.canPrice ? XS.el('span', { class: 'stk', text: ' · right click to price' }) : null,
            ]),
        ]));

        if (!counter.near) {
            grid.append(XS.el('div', { class: 'empty', style: 'margin-bottom:14px' }, [
                XS.el('div', { class: 't', text: 'You are not at this counter' }),
                XS.el('div', { class: 's', text: 'Walk up to it to buy. You can still see what it stocks from here.' }),
            ]));
        }

        const cards = XS.el('div', { class: 'cards' });

        for (const item of counter.items || []) {
            cards.append(XS.el('button', {
                class: `c ${item.stocked === 0 ? 'dry' : ''}`, disabled: !counter.near,
                oncontextmenu: (ev) => {
                    ev.preventDefault();
                    if (XS.state.canPrice) price(item);
                },
                onclick: () => buy(item),
            }, [
                XS.el('div', { class: 'idx', text: item.item.toUpperCase() }),
                XS.el('div', { class: 'nm', text: item.label }),
                XS.el('div', { class: 'fr' }, [
                    XS.el('span', { class: 'pr', text: XS.money(item.price) }),
                    XS.el('span', {
                        class: 'st',
                        text: item.stocked === undefined ? 'EACH' : `${XS.num(item.stocked)} IN`,
                    }),
                ]),
            ]));
        }

        if (!(counter.items || []).length) {
            cards.append(XS.empty('Nothing stocked', 'The shop owner has not put anything on this counter yet.'));
        }

        grid.append(cards);
        host.append(grid);
    };

    // What the counter charges, and what it calls it. Removing a line takes
    // the part off this shop's list entirely.
    function price(item) {
        XS.askPrice({
            title: item.label,
            note: 'What this shop sells it for. Set it to whatever you like — it is your counter.',
            price: item.price,
            label: item.label,
            naming: true,
        }, ({ price: amount, label }) => XS.post('setPartPrice', {
            item: item.item, price: amount, label,
        }));
    }

    function buy(item) {
        let amount = 1;

        const input = XS.el('input', {
            type: 'number', value: '1', min: '1', max: '50',
            oninput: (ev) => { amount = Math.max(1, Math.min(50, Number(ev.target.value) || 1)); },
        });

        XS.modal({
            title: `Buy ${item.label}`,
            note: `${XS.money(item.price)} each. The price is charged once per item.`,
            body: XS.el('div', { class: 'field' }, [XS.el('label', { text: 'How many' }), input]),
            confirm: 'Buy',
            onConfirm: () => XS.post('buyPart', { item: item.item, amount }),
        });
    }
})();
