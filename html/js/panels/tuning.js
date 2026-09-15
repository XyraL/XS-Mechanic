(function () {
    // Categories with nothing visual to show a customer.
    const NO_PREVIEW = new Set(['performance']);

    XS.panels.tuning = function (host) {
        XS.clear(host);

        const car = XS.state.vehicle;
        const cat = XS.state.catalogue;

        if (!car || !cat) {
            host.className = 'panel on';
            host.append(XS.el('div', { class: 'grid' }, [
                XS.empty('Nothing connected',
                    XS.mode === 'bay'
                        ? 'Drive a vehicle into the bay and the options it can take will be read off it.'
                        : 'Connect a vehicle first. Everything on this page comes off the car itself.'),
            ]));
            return;
        }

        const prices = XS.state.prices || {};
        const groups = buildGroups(cat);

        if (!XS.state.tuneGroup || !groups.some((g) => g.id === XS.state.tuneGroup)) {
            XS.state.tuneGroup = groups.length ? groups[0].id : null;
        }

        host.append(renderTree(groups));
        host.append(renderGrid(groups.find((g) => g.id === XS.state.tuneGroup), prices));
        host.append(renderDraft());
    };

    // The catalogue arrives as a flat list of slots the model actually carries.
    // Grouping happens here so the tree and the grid agree without the server
    // having to care how the panel is laid out.
    function buildGroups(cat) {
        const enabled = XS.state.categories || {};
        const out = [];
        const bucket = {};

        for (const slot of cat.slots || []) {
            if (enabled[slot.category] === false) continue;
            (bucket[slot.category] ||= []).push(slot);
        }

        const ORDER = [
            ['cosmetics', 'Cosmetics', 'Bodywork'],
            ['wheels', 'Wheels', 'Bodywork'],
            ['respray', 'Respray', 'Bodywork'],
            ['livery', 'Livery', 'Bodywork'],
            ['performance', 'Performance', 'Mechanical'],
            ['lights', 'Lights', 'Detail'],
            ['interior', 'Interior', 'Detail'],
            ['extras', 'Extras', 'Detail'],
            ['plate', 'Plates', 'Detail'],
        ];

        for (const [id, label, section] of ORDER) {
            if (enabled[id] === false) continue;

            if (id === 'wheels') {
                if (!cat.wheels) continue;
                out.push({ id, label, section, wheels: cat.wheels, count: cat.wheels.types.length });
                continue;
            }

            if (id === 'respray') {
                out.push({ id, label, section, paint: cat.paint, count: null });
                continue;
            }

            if (id === 'livery') {
                const legacy = cat.liveries;
                const slots = bucket.livery || [];
                if (!legacy && !slots.length) continue;
                out.push({ id, label, section, slots: legacy ? [legacy] : slots, count: (legacy?.options || slots[0]?.options || []).length });
                continue;
            }

            if (id === 'extras') {
                if (!cat.extras?.length) continue;
                out.push({ id, label, section, extras: cat.extras, count: cat.extras.length });
                continue;
            }

            if (id === 'plate') {
                if (!cat.plates) continue;
                out.push({ id, label, section, slots: [cat.plates], count: cat.plates.options.length });
                continue;
            }

            const slots = bucket[id];
            if (!slots?.length) continue;
            out.push({ id, label, section, slots, count: slots.length });
        }

        return out;
    }

    function renderTree(groups) {
        const tree = XS.el('aside', { class: 'tree' });
        let section = null;

        for (const group of groups) {
            if (group.section !== section) {
                section = group.section;
                tree.append(XS.el('div', { class: 'grp', text: section }));
            }

            tree.append(XS.el('button', {
                class: `tn ${XS.state.tuneGroup === group.id ? 'on' : ''}`,
                onclick: () => { XS.state.tuneGroup = group.id; XS.panels.tuning(document.querySelector('[data-panel="tuning"]')); },
            }, [
                XS.el('span', { class: 'n', text: group.label }),
                XS.el('span', { class: 'b', text: group.count === null ? 'RGB' : String(group.count) }),
            ]));
        }

        if (!groups.length) {
            tree.append(XS.el('div', { class: 'grp', text: 'Nothing available' }));
        }

        return tree;
    }

    function renderGrid(group, prices) {
        const grid = XS.el('section', { class: 'grid' });

        if (!group) {
            grid.append(XS.empty('Nothing to fit',
                'This model carries no parts in the categories this shop offers.'));
            return grid;
        }

        if (group.id === 'respray') return renderRespray(grid, group, prices);
        if (group.id === 'wheels') return renderWheels(grid, group, prices);
        if (group.id === 'extras') return renderExtras(grid, group, prices);

        // Performance changes nothing you can look at, and a customer already
        // knows what a bigger engine does. In a bay it goes straight onto the
        // order rather than pretending there is something to preview.
        const blind = XS.mode === 'bay' && NO_PREVIEW.has(group.id);

        for (const slot of group.slots) {
            grid.append(XS.el('div', { class: 'gh' }, [
                XS.el('h2', { text: `${group.label} · ${slot.label}` }),
                XS.el('div', {
                    class: 'cap',
                    text: blind ? 'nothing to see · goes straight on the order' : `${slot.options.length} read from model`,
                }),
            ]));

            const cards = XS.el('div', { class: 'cards' });

            for (const option of slot.options) {
                const fitted = slot.current === option.index;
                const price = option.index === -1 ? null : priceFor(prices, group.id, option.index);

                cards.append(XS.el('button', {
                    class: `c ${XS.isPreviewing(slot.id, option.index) ? 'on' : ''}`,
                    disabled: blind && option.index === -1,
                    onclick: () => {
                        if (blind) {
                            XS.post('addPick', {
                                category: group.id,
                                slotId: slot.id,
                                slot: slot.slot,
                                index: option.index,
                                label: `${option.label} — ${slot.label}`,
                            });
                            return;
                        }

                        XS.preview(slot, option, group.id, price);
                    },
                }, [
                    XS.el('div', { class: 'idx', text: option.index === -1 ? 'STOCK' : `IDX ${String(option.index).padStart(2, '0')}` }),
                    XS.el('div', { class: 'nm', text: option.label }),
                    XS.el('div', { class: 'fr' }, [
                        XS.el('span', { class: 'pr', text: price === null ? '—' : XS.money(price) }),
                        XS.el('span', {
                            class: `st ${fitted ? 'f' : XS.isPreviewing(slot.id, option.index) ? 'p' : ''}`,
                            text: fitted ? 'FITTED' : XS.isPreviewing(slot.id, option.index) ? 'PREVIEW' : 'STOCK',
                        }),
                    ]),
                ]));
            }

            grid.append(cards);
        }

        return grid;
    }

    function renderRespray(grid, group, prices) {
        const paint = group.paint || {};
        const price = prices.respray || 0;

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Respray · Primary' }),
            XS.el('div', { class: 'cap', text: XS.money(price) }),
        ]));

        grid.append(swatchGrid('primary', paint.primary));

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Respray · Secondary' }),
            XS.el('div', { class: 'cap', text: 'matched to primary by default' }),
        ]));

        grid.append(swatchGrid('secondary', paint.secondary));

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Respray · Custom' }),
            XS.el('div', { class: 'cap', text: 'any colour' }),
        ]));

        const custom = XS.el('div', { class: 'cards' });

        for (const part of ['primary', 'secondary']) {
            const input = XS.el('input', {
                type: 'color',
                value: hexOf(paint[`custom${part[0].toUpperCase()}${part.slice(1)}`]) || '#1e2530',
                style: 'width:100%;height:38px;padding:2px;background:var(--sunk);border:1px solid var(--line2);border-radius:7px;cursor:pointer',
                onchange: (ev) => XS.post('respray', { custom: part, hex: ev.target.value }),
            });

            custom.append(XS.el('div', { class: 'c' }, [
                XS.el('div', { class: 'idx', text: part.toUpperCase() }),
                XS.el('div', { class: 'nm', text: `Custom ${part}` }),
                input,
            ]));
        }

        grid.append(custom);

        return grid;
    }

    function swatchGrid(part, current) {
        const wrap = XS.el('div', { class: 'swatches' });

        for (const colour of XS.state.colours || []) {
            wrap.append(XS.el('button', {
                class: `sw ${current === colour.id ? 'on' : ''}`,
                style: `background:${colour.hex}`,
                title: colour.label,
                onclick: () => XS.post('respray', { part, index: colour.id }),
            }, [
                XS.el('span', { class: 'lbl', text: colour.label }),
            ]));
        }

        if (!(XS.state.colours || []).length) {
            wrap.append(XS.empty('No palette loaded', 'The colour table did not reach the panel.'));
        }

        return wrap;
    }

    function renderWheels(grid, group, prices) {
        const wheels = group.wheels;
        const price = prices.wheels || 0;

        if (!XS.state.wheelType && XS.state.wheelType !== 0) XS.state.wheelType = wheels.currentType;

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Wheels · Type' }),
            XS.el('div', { class: 'cap', text: `${wheels.types.length} fitted to model` }),
        ]));

        const types = XS.el('div', { class: 'cards' });

        for (const type of wheels.types) {
            types.append(XS.el('button', {
                class: `c ${XS.state.wheelType === type.type ? 'on' : ''}`,
                onclick: () => { XS.state.wheelType = type.type; XS.panels.tuning(document.querySelector('[data-panel="tuning"]')); },
            }, [
                XS.el('div', { class: 'idx', text: `TYPE ${String(type.type).padStart(2, '0')}` }),
                XS.el('div', { class: 'nm', text: type.label }),
                XS.el('div', { class: 'fr' }, [
                    XS.el('span', { class: 'pr', text: `${type.options.length} designs` }),
                    XS.el('span', { class: `st ${wheels.currentType === type.type ? 'f' : ''}`, text: wheels.currentType === type.type ? 'FITTED' : '' }),
                ]),
            ]));
        }

        grid.append(types);

        const chosen = wheels.types.find((t) => t.type === XS.state.wheelType);
        if (!chosen) return grid;

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: `Wheels · ${chosen.label}` }),
            XS.el('div', { class: 'cap', text: `${chosen.options.length} designs` }),
        ]));

        const cards = XS.el('div', { class: 'cards' });

        for (const option of chosen.options) {
            const fitted = wheels.currentType === chosen.type && wheels.current === option.index;

            cards.append(XS.el('button', {
                class: `c ${XS.isPreviewing('wheels', option.index) ? 'on' : ''}`,
                onclick: () => XS.preview(
                    { id: 'wheels', slot: 23, label: 'Wheels', wheelType: chosen.type },
                    option, 'wheels', price,
                ),
            }, [
                XS.el('div', { class: 'idx', text: `IDX ${String(option.index).padStart(2, '0')}` }),
                XS.el('div', { class: 'nm', text: option.label }),
                XS.el('div', { class: 'fr' }, [
                    XS.el('span', { class: 'pr', text: XS.money(price) }),
                    XS.el('span', { class: `st ${fitted ? 'f' : ''}`, text: fitted ? 'FITTED' : 'STOCK' }),
                ]),
            ]));
        }

        grid.append(cards);
        return grid;
    }

    function renderExtras(grid, group, prices) {
        const price = prices.extras || 0;

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Extras' }),
            XS.el('div', { class: 'cap', text: `${group.extras.length} on this model` }),
        ]));

        const cards = XS.el('div', { class: 'cards' });

        for (const extra of group.extras) {
            cards.append(XS.el('button', {
                class: `c ${extra.on ? 'on' : ''}`,
                onclick: () => XS.post('extra', { id: extra.id, on: !extra.on }),
            }, [
                XS.el('div', { class: 'idx', text: `EXTRA ${String(extra.id).padStart(2, '0')}` }),
                XS.el('div', { class: 'nm', text: `Extra ${extra.id}` }),
                XS.el('div', { class: 'fr' }, [
                    XS.el('span', { class: 'pr', text: XS.money(price) }),
                    XS.el('span', { class: `st ${extra.on ? 'f' : ''}`, text: extra.on ? 'ON' : 'OFF' }),
                ]),
            ]));
        }

        grid.append(cards);
        return grid;
    }

    function priceFor(prices, category, index) {
        const base = prices[category];
        if (base === null || base === undefined) return null;

        const step = Math.max(0, Number(index) || 0);
        const mult = XS.state.levelMultiplier || 0;

        return Math.round(base + base * mult * step);
    }

    function hexOf(rgb) {
        if (!rgb) return null;
        const to = (v) => Math.max(0, Math.min(255, Number(v) || 0)).toString(16).padStart(2, '0');
        return `#${to(rgb.r)}${to(rgb.g)}${to(rgb.b)}`;
    }

    XS.isPreviewing = function (slotId, index) {
        const p = XS.state.previewing;
        return !!p && p.slot === slotId && p.index === index;
    };

    XS.preview = function (slot, option, category, price) {
        XS.state.previewing = { slot: slot.id, index: option.index, label: option.label, category, price };

        XS.post('preview', {
            slot: slot.slot,
            slotId: slot.id,
            index: option.index,
            label: option.label,
            category,
            price,
            wheelType: slot.wheelType,
            legacy: slot.legacy || false,
        });

        XS.panels.tuning(document.querySelector('[data-panel="tuning"]'));
    };

    // A customer in a bay is building an ORDER, not paying a bill. They pick,
    // they see it on the car, and the shop gets the list. Paying on the spot is
    // still offered, but only where self service is actually allowed.
    function renderBasket() {
        const side = XS.el('aside', { class: 'side' });
        const basket = XS.state.basket || [];
        const preview = XS.state.previewing;
        const total = basket.reduce((sum, item) => sum + (item.price || 0), 0);

        side.append(XS.el('div', { class: 'sh' }, [
            XS.el('span', { class: 't', text: 'What you want doing' }),
            XS.el('span', { class: 'n', text: `${basket.length} ITEM${basket.length === 1 ? '' : 'S'}` }),
        ]));

        const lines = XS.el('div', { class: 'lines' });

        for (const [i, item] of basket.entries()) {
            lines.append(XS.el('div', { class: 'ln' }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 'd', text: item.label }),
                    XS.el('div', { class: 'm', text: item.categoryLabel || item.category }),
                ]),
                XS.el('div', { class: 'a', text: XS.money(item.price) }),
                XS.el('button', {
                    class: 'del', text: '×', title: 'Remove',
                    onclick: () => XS.post('dropPick', { index: i }),
                }),
            ]));
        }

        if (!basket.length) {
            lines.append(XS.el('div', { style: 'padding:26px 16px;text-align:center;color:var(--faint);font-size:12px;line-height:1.6' },
                'Pick something and it lands here. Nothing is bought until you say so.'));
        }

        side.append(lines);

        side.append(XS.el('div', { class: 'tot' }, [
            XS.el('div', { class: 'tr big' }, [
                XS.el('span', { text: 'ESTIMATE' }),
                XS.el('span', { text: XS.money(total) }),
            ]),

            XS.el('div', {
                style: 'font-size:11px;color:var(--faint);line-height:1.5;margin:-4px 0 12px',
                text: 'The shop can change any of these prices before you pay.',
            }),

            preview
                ? XS.el('button', {
                    class: 'go', text: 'Add to the order',
                    onclick: () => XS.post('addPick'),
                })
                : XS.state.takesOrders
                    ? XS.el('button', {
                        class: 'go', text: 'Send it to the shop',
                        disabled: !basket.length,
                        onclick: () => XS.post('submitOrder'),
                    })
                    : XS.el('button', {
                        class: 'go', text: XS.state.selfService ? 'Pay and fit it yourself' : 'Nobody is in',
                        disabled: !basket.length || !XS.state.selfService,
                        onclick: () => XS.post('checkout'),
                    }),

            // No second pay button: with staff in you send an order, and with
            // the shop empty the primary button already is the pay one.
            preview
                ? XS.el('button', { class: 'sub', text: 'Not that one', onclick: () => XS.post('cancelPreview') })
                : null,

            !preview && !XS.state.takesOrders && !XS.state.selfService
                ? XS.el('div', {
                    style: 'font-size:11px;color:var(--faint);line-height:1.5;margin-top:10px;text-align:center',
                    text: 'Nobody is working and this shop does not allow self service. Come back later.',
                })
                : null,
        ]));

        return side;
    }

    function renderDraft() {
        if (XS.mode === 'bay') return renderBasket();

        const side = XS.el('aside', { class: 'side' });
        const draft = XS.state.invoice || { items: [], total: 0 };
        const preview = XS.state.previewing;

        side.append(XS.el('div', { class: 'sh' }, [
            XS.el('span', { class: 't', text: XS.mode === 'bay' ? 'Your basket' : 'Invoice draft' }),
            XS.el('span', { class: 'n', text: draft.id ? `#${draft.id}` : 'NEW' }),
        ]));

        const lines = XS.el('div', { class: 'lines' });

        for (const [i, item] of (draft.items || []).entries()) {
            lines.append(XS.el('div', { class: 'ln' }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 'd', text: item.label }),
                    XS.el('div', { class: 'm', text: item.note || item.category || '' }),
                ]),
                XS.el('div', { class: 'a', text: XS.money(item.amount) }),
                XS.el('button', { class: 'del', text: '×', title: 'Remove', onclick: () => XS.post('dropLine', { index: i }) }),
            ]));
        }

        if (!(draft.items || []).length) {
            lines.append(XS.el('div', { style: 'padding:26px 16px;text-align:center;color:var(--faint);font-size:12px;line-height:1.6' },
                XS.mode === 'bay' ? 'Pick a part and it lands here.' : 'Fit something and it is added here automatically.'));
        }

        side.append(lines);

        const commission = Math.round((draft.total || 0) * ((XS.state.commission || 0) / 100));

        side.append(XS.el('div', { class: 'tot' }, [
            XS.el('div', { class: 'tr' }, [XS.el('span', { text: 'PARTS' }), XS.el('span', { text: XS.money(draft.total) })]),
            XS.mode === 'tablet' && XS.state.commission
                ? XS.el('div', { class: 'tr' }, [
                    XS.el('span', { text: `COMMISSION ${XS.state.commission}%` }),
                    XS.el('span', { text: XS.money(commission) }),
                ])
                : null,
            XS.el('div', { class: 'tr big' }, [XS.el('span', { text: 'TOTAL' }), XS.el('span', { text: XS.money(draft.total) })]),

            preview
                ? XS.el('button', {
                    class: 'go',
                    text: XS.mode === 'bay' ? `Fit for ${XS.money(preview.price || 0)}` : 'Fit and add to invoice',
                    onclick: () => XS.post('apply'),
                })
                : XS.el('button', {
                    class: 'go',
                    text: XS.mode === 'bay' ? 'Pay and finish' : 'Send to customer',
                    disabled: !(draft.items || []).length,
                    // Spelled out rather than picked with a ternary so every
                    // endpoint the page uses stays greppable.
                    onclick: () => {
                        if (XS.mode === 'bay') XS.post('checkout');
                        else XS.post('sendInvoice');
                    },
                }),

            preview
                ? XS.el('button', { class: 'sub', text: 'Discard preview', onclick: () => XS.post('cancelPreview') })
                : XS.mode === 'tablet'
                    ? XS.el('button', { class: 'sub', text: 'Save for later', disabled: !(draft.items || []).length, onclick: () => XS.post('saveInvoice') })
                    : null,
        ]));

        return side;
    }
})();
