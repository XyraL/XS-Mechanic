(function () {
    XS.panels.team = function (host) {
        XS.clear(host);

        const tab = XS.state.teamTab || 'staff';
        const staff = XS.state.staff || [];

        const tree = XS.el('aside', { class: 'tree' }, [XS.el('div', { class: 'grp', text: 'Shop' })]);

        for (const [id, label, count] of [
            ['staff', 'Staff', staff.length],
            ['money', 'Money', null],
            ['prices', 'Prices', null],
        ]) {
            tree.append(XS.el('button', {
                class: `tn ${tab === id ? 'on' : ''}`,
                onclick: () => { XS.state.teamTab = id; XS.rerender('team'); },
            }, [
                XS.el('span', { class: 'n', text: label }),
                count === null ? null : XS.el('span', { class: 'b', text: String(count) }),
            ]));
        }

        host.append(tree);

        const grid = XS.el('section', { class: 'grid' });

        if (tab === 'staff') renderStaff(grid, staff);
        else if (tab === 'money') renderMoney(grid);
        else renderPrices(grid);

        host.append(grid);
    };

    function renderStaff(grid, staff) {
        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Staff' }),
            XS.el('div', { class: 'cap', text: XS.state.manageJobs ? 'hired through the framework' : 'read only' }),
        ]));

        if (XS.state.manageJobs) {
            grid.append(XS.el('div', { style: 'margin-bottom:14px' }, [
                XS.el('button', { class: 'mini hot', text: 'Hire nearest player', onclick: hire }),
            ]));
        }

        const rows = XS.el('div', { class: 'rows' });

        for (const person of staff) {
            rows.append(XS.el('div', { class: 'row' }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 't', text: person.name }),
                    XS.el('div', { class: 'm', text: `${person.gradeLabel || `Grade ${person.grade}`} · ${person.onDuty ? 'on duty' : 'off duty'}` }),
                ]),
                XS.el('div', { class: 'acts' }, [
                    XS.el('span', { class: `st ${person.onDuty ? 'f' : ''}`, text: person.onDuty ? 'ON' : 'OFF' }),
                    XS.state.manageJobs ? XS.el('button', {
                        class: 'mini', text: 'Grade',
                        onclick: () => changeGrade(person),
                    }) : null,
                    XS.state.manageJobs ? XS.el('button', {
                        class: 'mini danger', text: 'Fire',
                        onclick: () => XS.modal({
                            title: `Fire ${person.name}?`,
                            note: 'They lose the job immediately. This goes through your framework, so any boss menu will agree.',
                            confirm: 'Fire', danger: true,
                            onConfirm: () => XS.post('fire', { citizenid: person.citizenid }),
                        }),
                    }) : null,
                ]),
            ]));
        }

        if (!staff.length) {
            rows.append(XS.empty('Nobody on the books', 'Hire someone standing next to you to get started.'));
        }

        grid.append(rows);
    }

    function hire() {
        XS.modal({
            title: 'Hire nearest player',
            note: 'They are given this shop\'s job at the lowest grade. Stand next to them first.',
            confirm: 'Hire',
            onConfirm: () => XS.post('hire'),
        });
    }

    function changeGrade(person) {
        let grade = person.grade;

        const select = XS.el('select', { onchange: (ev) => { grade = Number(ev.target.value); } });

        for (const option of XS.state.grades || []) {
            select.append(XS.el('option', {
                value: String(option.level),
                selected: option.level === person.grade,
                text: `${option.level} — ${option.label}`,
            }));
        }

        XS.modal({
            title: `${person.name}'s grade`,
            note: 'Grades come from your framework. The boss grade for this shop is set in the builder.',
            body: XS.el('div', { class: 'field' }, [XS.el('label', { text: 'Grade' }), select]),
            confirm: 'Save',
            onConfirm: () => XS.post('setGrade', { citizenid: person.citizenid, grade }),
        });
    }

    function renderMoney(grid) {
        const s = XS.state.summary || {};

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Shop funds' }),
            XS.el('div', { class: 'cap', text: XS.state.ledgerOnly ? 'kept by this resource' : 'your banking resource' }),
        ]));

        grid.append(XS.el('div', { class: 'cards' }, [
            XS.el('div', { class: 'c' }, [
                XS.el('div', { class: 'idx', text: 'BALANCE' }),
                XS.el('div', { class: 'nm', style: 'font:650 24px/1 var(--mono)', text: XS.money(s.funds || 0) }),
            ]),
            XS.el('div', { class: 'c' }, [
                XS.el('div', { class: 'idx', text: 'TAKEN TODAY' }),
                XS.el('div', { class: 'nm', style: 'font:650 24px/1 var(--mono)', text: XS.money(s.today || 0) }),
            ]),
        ]));

        if (XS.state.ledgerOnly) {
            grid.append(XS.el('div', { style: 'margin:16px 0' }, [
                XS.el('button', { class: 'mini hot', text: 'Withdraw', onclick: () => move('withdraw') }),
                ' ',
                XS.el('button', { class: 'mini', text: 'Deposit', onclick: () => move('deposit') }),
            ]));
        }

        grid.append(XS.el('div', { class: 'gh', style: 'margin-top:22px' }, [
            XS.el('h2', { text: 'Recent movements' }),
            XS.el('div', { class: 'cap', text: `${(XS.state.ledger || []).length} entries` }),
        ]));

        const rows = XS.el('div', { class: 'rows' });

        for (const entry of XS.state.ledger || []) {
            rows.append(XS.el('div', { class: 'row' }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 't', text: entry.note || entry.kind }),
                    XS.el('div', { class: 'm', text: `${entry.byName || 'system'} · ${XS.ago(entry.createdAt)}` }),
                ]),
                XS.el('span', {
                    class: 'a',
                    style: `color:${entry.amount < 0 ? 'var(--bad)' : 'var(--good)'}`,
                    text: XS.money(entry.amount),
                }),
            ]));
        }

        if (!(XS.state.ledger || []).length) {
            rows.append(XS.empty('Nothing yet', 'Money moves here as invoices are paid and parts are bought.'));
        }

        grid.append(rows);
    }

    function move(kind) {
        let amount = 0;

        XS.modal({
            title: kind === 'withdraw' ? 'Withdraw from the shop' : 'Deposit into the shop',
            body: XS.el('div', { class: 'field' }, [
                XS.el('label', { text: 'Amount' }),
                XS.el('input', { type: 'number', value: '0', min: '0', oninput: (ev) => { amount = Number(ev.target.value) || 0; } }),
            ]),
            confirm: kind === 'withdraw' ? 'Withdraw' : 'Deposit',
            onConfirm: () => XS.post('shopMoney', { kind, amount }),
        });
    }

    function renderPrices(grid) {
        const canPrice = XS.state.canPrice;

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'What this shop charges' }),
            XS.el('div', { class: 'cap', text: `mode: ${XS.state.pricingMode || 'fixed'}` }),
        ]));

        const rows = XS.el('div', { class: 'rows' });

        for (const [id, price] of Object.entries(XS.state.prices || {})) {
            const label = id.charAt(0).toUpperCase() + id.slice(1);

            rows.append(XS.el('div', { class: 'row' }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 't', text: label }),
                    XS.el('div', { class: 'm', text: 'base price before the level multiplier' }),
                ]),
                XS.el('span', { class: 'a', text: XS.money(price) }),
                canPrice ? XS.el('button', {
                    class: 'mini', text: 'Change',
                    onclick: () => XS.askPrice({
                        title: `${label} price`,
                        note: 'Everything in this category at this shop. Zero makes it free.',
                        price,
                    }, ({ price: set }) => XS.post('setCategoryPrice', { category: id, price: set })),
                }) : null,
            ]));
        }

        grid.append(rows);

        // The handling packages are priced one at a time rather than by
        // category — a V8 and a set of tyres are both "tuning" and nobody
        // charges the same for them.
        for (const category of XS.state.tuningPrices || []) {
            grid.append(XS.el('div', { class: 'gh', style: 'margin-top:22px' }, [
                XS.el('h2', { text: category.label }),
                XS.el('div', { class: 'cap', text: `${category.options.length} packages` }),
            ]));

            const list = XS.el('div', { class: 'rows' });

            for (const option of category.options) {
                list.append(XS.el('div', { class: 'row' }, [
                    XS.el('div', {}, [
                        XS.el('div', { class: 't' }, [
                            option.name,
                            option.priced ? XS.el('span', { class: 'tag', text: 'RENAMED' }) : null,
                        ]),
                        XS.el('div', { class: 'm', text: option.priced ? `shipped as ${option.stock}` : 'shipped price' }),
                    ]),
                    XS.el('span', { class: 'a', text: XS.money(option.price) }),
                    canPrice ? XS.el('button', {
                        class: 'mini', text: 'Change',
                        onclick: () => XS.askPrice({
                            title: option.name,
                            note: 'What this package is called and what it costs here. Everybody at this shop sees the change.',
                            price: option.price,
                            label: option.name,
                            naming: true,
                        }, ({ price, label }) => XS.post('setTuningPrice', {
                            category: category.id, option: option.id, price, label,
                        })),
                    }) : null,
                ]));
            }

            grid.append(list);
        }

        grid.append(XS.el('div', { style: 'margin-top:16px;font-size:12px;color:var(--faint);line-height:1.6' },
            canPrice
                ? 'Changing one here changes it for everybody at this shop. The tablet only quotes off these — it cannot set them.'
                : 'Your rank cannot change prices. Ask a boss.'));
    }
})();
