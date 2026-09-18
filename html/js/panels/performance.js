(function () {
    XS.panels.performance = function (host) {
        XS.clear(host);

        const car = XS.state.vehicle;
        const sheet = car?.tuning || [];

        const chosen = XS.state.tuneCategory
            && sheet.some((c) => c.id === XS.state.tuneCategory)
            ? XS.state.tuneCategory
            : (sheet[0] && sheet[0].id);

        const slots = (XS.state.catalogue?.slots || []).filter((s) => s.category === 'performance');

        const tree = XS.el('aside', { class: 'tree' });

        // The levels the model itself carries, first — they are the everyday
        // job, and the packages below them are the special order.
        if (slots.length) {
            tree.append(XS.el('div', { class: 'grp', text: 'Upgrades' }));

            for (const slot of slots) {
                tree.append(XS.el('button', {
                    class: `tn ${XS.state.tuneCategory === slot.id ? 'on' : ''}`,
                    onclick: () => { XS.state.tuneCategory = slot.id; XS.rerender('performance'); },
                }, [
                    XS.el('span', { class: 'n', text: slot.label }),
                    XS.el('span', {
                        class: `b ${slot.current !== -1 ? 'good' : ''}`,
                        text: slot.current !== -1 ? `L${slot.current + 1}` : String(slot.options.length),
                    }),
                ]));
            }
        }

        if (sheet.length) tree.append(XS.el('div', { class: 'grp', text: 'Packages' }));

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

        // A modkit slot rather than a package.
        const slot = slots.find((s) => s.id === XS.state.tuneCategory);

        if (slot) {
            renderSlot(grid, slot);
            host.append(grid);
            host.append(queue());
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
        host.append(queue());
    };

    // Picking a level puts it on the same list everything else goes on, so one
    // Fit all does the lot and writes one invoice.
    function renderSlot(grid, slot) {
        const stock = XS.stockFor('performance', slot.id);
        const prices = XS.state.prices || {};

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: slot.label }),
            XS.el('div', { class: 'cap' }, [
                `${slot.options.length} read from model`,
                stock
                    ? XS.el('span', {
                        class: 'stk',
                        text: stock.count > 0
                            ? ` · ${XS.num(stock.count)} ${stock.label} in stock`
                            : ` · no ${stock.label} — one has to be made`,
                    })
                    : null,
            ]),
        ]));

        const dry = !!stock && stock.count < 1;
        const cards = XS.el('div', { class: 'cards' });

        for (const option of slot.options) {
            const fitted = slot.current === option.index;
            const picked = (XS.state.basket || []).some((p) => p.slotId === slot.id && p.index === option.index);
            const price = option.index === -1 ? null : (prices.performance || 0);

            cards.append(XS.el('button', {
                class: `c ${picked ? 'on' : ''} ${dry && option.index !== -1 ? 'dry' : ''}`,
                onclick: () => XS.post('pickPart', {
                    slot: slot.slot,
                    slotId: slot.id,
                    index: option.index,
                    label: `${option.label} — ${slot.label}`,
                    category: 'performance',
                }),
            }, [
                XS.el('div', { class: 'idx', text: option.index === -1 ? 'STOCK' : `LEVEL ${option.index + 1}` }),
                XS.el('div', { class: 'nm', text: option.label }),
                XS.el('div', { class: 'fr' }, [
                    XS.el('span', { class: 'pr', text: price === null ? '—' : XS.money(price) }),
                    XS.el('span', {
                        class: `st ${fitted ? 'f' : picked ? 'p' : ''}`,
                        text: fitted ? 'FITTED' : picked ? 'PICKED' : 'STOCK',
                    }),
                ]),
            ]));
        }

        grid.append(cards);
    }

    function queue() {
        if (!(XS.state.basket || []).length || !XS.renderQueue) return null;
        return XS.renderQueue();
    }
})();
