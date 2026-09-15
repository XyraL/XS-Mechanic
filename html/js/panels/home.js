(function () {
    XS.panels.home = function (host) {
        XS.clear(host);

        const grid = XS.el('section', { class: 'grid' });
        const shop = XS.state.shop;

        if (!shop) {
            grid.append(XS.empty('You are not on a shop',
                'This tablet works for whoever holds a mechanic shop\'s job. Ask an admin to set one up.'));
            host.append(grid);
            return;
        }

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: shop.name }),
            XS.el('div', { class: 'cap', text: shop.kind === 'owned' ? 'Owned shop' : 'Self service' }),
        ]));

        const stats = XS.el('div', { class: 'cards' });
        const s = XS.state.summary || {};

        for (const tile of [
            { k: 'Takings today', v: XS.money(s.today || 0), s: `${s.jobs || 0} jobs` },
            { k: 'Unpaid invoices', v: String(s.unpaid || 0), s: XS.money(s.unpaidTotal || 0) },
            { k: 'Open orders', v: String(s.orders || 0), s: 'left at the desk' },
            { k: 'On duty', v: String(s.onDuty || 0), s: `${s.staff || 0} on the books` },
            { k: 'Shop funds', v: XS.money(s.funds || 0), s: XS.state.ledgerOnly ? 'own ledger' : 'society' },
            { k: 'Your commission', v: `${XS.state.commission || 0}%`, s: XS.money(s.earned || 0) + ' earned' },
        ]) {
            stats.append(XS.el('div', { class: 'c' }, [
                XS.el('div', { class: 'idx', text: tile.k.toUpperCase() }),
                XS.el('div', { class: 'nm', style: 'font:650 21px/1 var(--mono);letter-spacing:-.03em;margin-bottom:9px', text: tile.v }),
                XS.el('div', { class: 'fr' }, [XS.el('span', { class: 'pr', style: 'font-size:11px', text: tile.s })]),
            ]));
        }

        grid.append(stats);

        grid.append(XS.el('div', { class: 'gh', style: 'margin-top:22px' }, [
            XS.el('h2', { text: 'On duty now' }),
            XS.el('div', { class: 'cap', text: `${(XS.state.staff || []).filter((p) => p.onDuty).length} working` }),
        ]));

        const rows = XS.el('div', { class: 'rows' });
        const onDuty = (XS.state.staff || []).filter((p) => p.onDuty);

        for (const person of onDuty) {
            rows.append(XS.el('div', { class: 'row' }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 't', text: person.name }),
                    XS.el('div', { class: 'm', text: person.gradeLabel || `Grade ${person.grade}` }),
                ]),
                XS.el('span', { class: 'st f', text: 'ON DUTY' }),
            ]));
        }

        if (!onDuty.length) {
            rows.append(XS.empty('Nobody else is on', 'You are holding the shop on your own right now.'));
        }

        grid.append(rows);
        host.append(grid);
    };
})();
