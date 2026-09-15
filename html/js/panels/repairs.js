(function () {
    XS.panels.repairs = function (host) {
        XS.clear(host);

        const car = XS.state.vehicle;

        host.append(XS.el('aside', { class: 'tree' }, [
            XS.el('div', { class: 'grp', text: 'Work' }),
            XS.el('button', { class: 'tn on' }, [XS.el('span', { class: 'n', text: 'Repairs' })]),
            XS.el('button', { class: 'tn', onclick: () => XS.post('openWash') }, [
                XS.el('span', { class: 'n', text: 'Wash' }),
            ]),
        ]));

        const grid = XS.el('section', { class: 'grid' });

        if (!car) {
            grid.append(XS.empty('Nothing connected', 'Connect a vehicle before repairing it.'));
            host.append(grid);
            return;
        }

        const engine = Math.round((car.health?.engine || 0) / 10);
        const body = Math.round((car.health?.body || 0) / 10);
        const price = (XS.state.prices || {}).repair || 0;
        const clean = engine >= 99 && body >= 99;

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Condition' }),
            XS.el('div', { class: 'cap', text: clean ? 'nothing to do' : 'repairable' }),
        ]));

        const cards = XS.el('div', { class: 'cards' });

        cards.append(XS.el('div', { class: 'c' }, [
            XS.el('div', { class: 'idx', text: 'ENGINE' }),
            XS.el('div', { class: 'nm', style: 'font:650 21px/1 var(--mono);margin-bottom:11px', text: `${engine}%` }),
            XS.track(engine, engine < 40 ? 't-bad' : engine < 70 ? 't-warn' : ''),
        ]));

        cards.append(XS.el('div', { class: 'c' }, [
            XS.el('div', { class: 'idx', text: 'BODY' }),
            XS.el('div', { class: 'nm', style: 'font:650 21px/1 var(--mono);margin-bottom:11px', text: `${body}%` }),
            XS.track(body, body < 40 ? 't-bad' : body < 70 ? 't-warn' : ''),
        ]));

        grid.append(cards);

        grid.append(XS.el('div', { class: 'gh', style: 'margin-top:22px' }, [
            XS.el('h2', { text: 'How to fix it' }),
            XS.el('div', { class: 'cap', text: XS.mode === 'bay' ? 'you pay' : 'billed to the customer' }),
        ]));

        const options = XS.el('div', { class: 'cards' });

        options.append(XS.el('button', {
            class: 'c', disabled: clean,
            onclick: () => XS.post('repair', { how: 'bay' }),
        }, [
            XS.el('div', { class: 'idx', text: 'BAY' }),
            XS.el('div', { class: 'nm', text: 'Full repair' }),
            XS.el('div', { class: 'fr' }, [
                XS.el('span', { class: 'pr', text: XS.money(price) }),
                XS.el('span', { class: 'st', text: 'ENGINE + BODY' }),
            ]),
        ]));

        for (const kit of XS.state.kits || []) {
            options.append(XS.el('button', {
                class: 'c', disabled: clean || !kit.held,
                onclick: () => XS.post('repair', { how: 'kit', item: kit.item }),
            }, [
                XS.el('div', { class: 'idx', text: 'ITEM' }),
                XS.el('div', { class: 'nm', text: kit.label }),
                XS.el('div', { class: 'fr' }, [
                    XS.el('span', { class: 'pr', text: kit.held ? `${kit.held} held` : 'none held' }),
                    XS.el('span', { class: `st ${kit.held ? 'f' : ''}`, text: `+${kit.engine}% ENG` }),
                ]),
            ]));
        }

        grid.append(options);
        host.append(grid);
    };
})();
