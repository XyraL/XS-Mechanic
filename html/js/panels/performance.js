(function () {
    XS.panels.performance = function (host) {
        XS.clear(host);

        const car = XS.state.vehicle;
        const sheet = car?.tuning || [];

        const chosen = XS.state.tuneCategory
            && sheet.some((c) => c.id === XS.state.tuneCategory)
            ? XS.state.tuneCategory
            : (sheet[0] && sheet[0].id);

        const tree = XS.el('aside', { class: 'tree' }, [XS.el('div', { class: 'grp', text: 'Custom tuning' })]);

        for (const category of sheet) {
            tree.append(XS.el('button', {
                class: `tn ${chosen === category.id ? 'on' : ''}`,
                onclick: () => { XS.state.tuneCategory = category.id; XS.rerender('performance'); },
            }, [
                XS.el('span', { class: 'n', text: category.label }),
                XS.el('span', {
                    class: `b ${category.current ? 'good' : ''}`,
                    text: category.current ? 'ON' : String(category.options.length),
                }),
            ]));
        }

        host.append(tree);

        const grid = XS.el('section', { class: 'grid' });

        if (!car) {
            grid.append(XS.empty('Nothing connected', 'Connect a vehicle first.'));
            host.append(grid);
            return;
        }

        const category = sheet.find((c) => c.id === chosen);

        if (!category) {
            grid.append(XS.empty('Nothing available',
                'Custom tuning is switched off, or nothing in the list fits this vehicle.'));
            host.append(grid);
            return;
        }

        const held = XS.stockFor('performance');

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: category.label }),
            XS.el('div', { class: 'cap' }, [
                category.requiresItem ? 'the shop supplies the part' : 'paid from shop funds',
                category.requiresItem && held
                    ? XS.el('span', {
                        class: 'stk',
                        text: held.count > 0
                            ? ` · ${XS.num(held.count)} ${held.label} in stock`
                            : ` · no ${held.label} — one has to be made`,
                    })
                    : null,
                XS.state.canPrice
                    ? XS.el('span', { class: 'stk', text: ' · right click to price' })
                    : null,
            ]),
        ]));

        const cards = XS.el('div', { class: 'cards' });

        for (const option of category.options) {
            // Each package has its own part. Greying the whole list out
            // against one generic item hid every engine a shop actually had.
            const held = XS.heldOf(option.item);
            const dry = category.requiresItem && held !== null && held < 1;

            cards.append(XS.el('button', {
                class: `c ${option.fitted ? 'on' : ''} ${dry ? 'dry' : ''}`,
                oncontextmenu: (ev) => {
                    ev.preventDefault();
                    if (!XS.state.canPrice) return;

                    // Right click is the price. The left one fits the part,
                    // which is what you are here to do nine times in ten.
                    XS.askPrice({
                        title: option.name,
                        note: 'What this package is called and what it costs this shop. Everybody at this shop sees the change.',
                        price: option.price,
                        label: option.name,
                        naming: true,
                    }, ({ price, label }) => XS.post('setTuningPrice', {
                        category: category.id, option: option.id, price, label,
                    }));
                },
                onclick: () => {
                    if (option.fitted) XS.post('removeTuning', { category: category.id });
                    else XS.post('fitTuning', { category: category.id, option: option.id, item: option.item });
                },
            }, [
                XS.el('div', { class: 'idx' }, [
                    category.requiresItem ? option.item.toUpperCase() : 'PACKAGE',
                    option.priced ? XS.el('span', { class: 'stk', text: ' · SHOP PRICE' }) : null,
                ]),
                XS.el('div', { class: 'nm', text: option.name }),
                option.info
                    ? XS.el('div', {
                        style: 'font-size:11px;color:var(--faint);line-height:1.45;margin:-6px 0 12px',
                        text: option.info,
                    })
                    : null,
                XS.el('div', { class: 'fr' }, [
                    XS.el('span', {
                        class: 'pr',
                        text: category.requiresItem
                            ? (held === null ? '1 part' : `${XS.num(held)} on the shelf`)
                            : XS.money(option.price),
                    }),
                    XS.el('span', {
                        class: `st ${option.fitted ? 'f' : ''}`,
                        text: option.fitted ? 'FITTED' : 'AVAILABLE',
                    }),
                ]),
            ]));
        }

        grid.append(cards);

        grid.append(XS.el('div', {
            style: 'margin-top:18px;font-size:12px;color:var(--faint);line-height:1.6;max-width:640px',
            text: 'These change the vehicle’s handling. The shipped values are tuned against stock cars — an addon with an unbalanced handling file can come out slower, which is the handling file rather than the swap.',
        }));

        host.append(grid);
    };

})();
