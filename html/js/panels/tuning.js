(function () {
    // Tuning is the cosmetic screen. Engine, brakes, transmission and
    // suspension are mechanical, they change nothing you can look at, and they
    // live on the Performance screen next to the packages that do the same job.
    const MECHANICAL = new Set(['performance']);

    // The four respray channels, as [what Lua calls it, the label, where the
    // current value sits on the paint object]. Three columns because two of
    // them disagree: the part id is 'pearl' and 'wheel', but the values come
    // back as 'pearlescent' and 'wheelColour'.
    const CHANNELS = [
        ['primary',   'Primary',   'primary'],
        ['secondary', 'Secondary', 'secondary'],
        ['pearl',     'Pearl',     'pearlescent'],
        ['wheel',     'Wheels',    'wheelColour'],
    ];

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

        const group = groups.find((g) => g.id === XS.state.tuneGroup);

        // The window goes and looks at whatever is on screen. A slot is more
        // specific than a category, so a spoiler sends the camera round the
        // back rather than to "cosmetics" in general.
        XS.subject.look(XS.state.tuneSlot || group?.id || 'full');

        host.append(renderTree(groups));
        host.append(renderGrid(group, prices));
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

            if (MECHANICAL.has(id)) continue;

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
                onclick: () => { XS.state.tuneGroup = group.id; XS.state.tuneSlot = null; XS.rerender('tuning'); },
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

        for (const slot of group.slots) {
            const stock = XS.stockFor(group.id, slot.id);
            const dry = !!stock && stock.count < 1;

            grid.append(XS.el('div', { class: 'gh' }, [
                XS.el('h2', { text: `${group.label} · ${slot.label}` }),
                XS.el('div', { class: 'cap' }, [
                    `${slot.options.length} read from model`,
                    stockNote(stock),
                ]),
                pricer(group),
            ]));

            const cards = XS.el('div', { class: 'cards' });

            for (const option of slot.options) {
                const fitted = slot.current === option.index;
                const price = option.index === -1 ? null : priceFor(prices, group.id, option.index);

                cards.append(XS.el('button', {
                    class: `c ${XS.isPreviewing(slot.id, option.index) ? 'on' : ''} ${dry && option.index !== -1 ? 'dry' : ''}`,
                    onmouseenter: () => XS.subject.look(slot.id),
                    onclick: () => choose(slot, option, group.id, price),
                }, [
                    XS.el('div', { class: 'idx', text: option.index === -1 ? 'STOCK' : `IDX ${String(option.index).padStart(2, '0')}` }),
                    XS.el('div', { class: 'nm', text: option.label }),
                    XS.el('div', { class: 'fr' }, [
                        XS.el('span', { class: 'pr', text: price === null ? '—' : XS.money(price) }),
                        XS.el('span', {
                            class: `st ${fitted ? 'f' : XS.isPreviewing(slot.id, option.index) ? 'p' : ''}`,
                            text: fitted ? 'FITTED' : XS.isPreviewing(slot.id, option.index) ? 'PICKED' : 'STOCK',
                        }),
                    ]),
                ]));
            }

            grid.append(cards);
        }

        return grid;
    }

    // What is on the shelf for this kind of work. Nothing is hidden when the
    // shop is out: a customer can still ask for it, and somebody goes and
    // makes one at the bench.
    function stockNote(stock) {
        if (!stock) return null;

        // The count trails the label rather than leading it, because the labels
        // are a mix of singular, plural and mass nouns — Body Part, Brake Pads,
        // Glass — so "6 Body Part in stock" is wrong and no pluralising rule
        // gets all three right.
        return XS.el('span', {
            class: 'stk',
            text: stock.count > 0
                ? ` · ${stock.label} ×${XS.num(stock.count)} in stock`
                : ` · no ${stock.label} — has to be made`,
        });
    }

    // Prices are the shop's business, not the job in front of you. They are
    // set on the laptop at the desk.
    function pricer() {
        return null;
    }

    function renderRespray(grid, group, prices) {
        const on = group.paint || {};
        const price = prices.respray || 0;
        const families = XS.state.paint || [];

        if (!CHANNELS.some((c) => c[0] === XS.state.paintChannel)) XS.state.paintChannel = 'primary';

        if (!families.some((f) => f.id === XS.state.paintFamily)) {
            XS.state.paintFamily = families.length ? families[0].id : null;
        }

        const channel = CHANNELS.find((c) => c[0] === XS.state.paintChannel);

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Respray' }),
            XS.el('div', { class: 'cap' }, [XS.money(price), stockNote(XS.stockFor('respray'))]),
            pricer(group),
        ]));

        const parts = XS.el('div', { class: 'chips' });

        for (const [id, label] of CHANNELS) {
            parts.append(XS.el('button', {
                class: `tn ${XS.state.paintChannel === id ? 'on' : ''}`,
                onclick: () => { XS.state.paintChannel = id; XS.rerender('tuning'); },
            }, [XS.el('span', { class: 'n', text: label })]));
        }

        grid.append(parts);

        if (!families.length) {
            grid.append(XS.empty('No palette loaded', 'The colour table did not reach the panel.'));
            return grid;
        }

        const finishes = XS.el('div', { class: 'chips' });

        for (const family of families) {
            finishes.append(XS.el('button', {
                class: `tn ${XS.state.paintFamily === family.id ? 'on' : ''}`,
                onclick: () => { XS.state.paintFamily = family.id; XS.rerender('tuning'); },
            }, [
                XS.el('span', { class: 'n', text: family.label }),
                XS.el('span', { class: 'b', text: String(family.colours.length) }),
            ]));
        }

        grid.append(finishes);

        const family = families.find((f) => f.id === XS.state.paintFamily);

        grid.append(swatchGrid(channel, family, on[channel[2]]));

        // Only the body takes a colour off the picker. Pearl and wheel colour
        // are indices into the table and have no custom form.
        if (channel[0] === 'primary' || channel[0] === 'secondary') {
            grid.append(XS.el('div', { class: 'gh' }, [
                XS.el('h2', { text: `${channel[1]} · Custom` }),
                XS.el('div', { class: 'cap', text: 'any colour, no finish' }),
            ]));

            const held = on[`custom${channel[1]}`];

            const input = XS.el('input', {
                type: 'color',
                value: hexOf(held) || '#1e2530',
                style: 'width:100%;height:44px;padding:2px;background:var(--sunk);border:1px solid var(--line2);border-radius:7px;cursor:pointer',
                onchange: (ev) => choosePaint({
                    part: channel[0],
                    custom: channel[0],
                    hex: ev.target.value,
                    label: `Custom ${channel[1].toLowerCase()}`,
                }),
            });

            grid.append(XS.el('div', { class: 'cards' }, [
                XS.el('div', { class: 'c' }, [
                    XS.el('div', { class: 'idx', text: channel[1].toUpperCase() }),
                    XS.el('div', { class: 'nm', text: 'Mixed to order' }),
                    input,
                ]),
            ]));
        }

        return grid;
    }

    function swatchGrid(channel, family, current) {
        const wrap = XS.el('div', { class: 'swatches' });

        for (const colour of (family && family.colours) || []) {
            wrap.append(XS.el('button', {
                class: `sw ${current === colour.id ? 'on' : ''} ${colour.shaded ? 'shaded' : ''}`,
                style: `background-color:${colour.hex}`,
                title: `${colour.label} · ${family.label}`,
                onclick: () => choosePaint({
                    part: channel[0],
                    index: colour.id,
                    label: `${channel[1]} — ${colour.label}`,
                }),
            }, [
                XS.el('span', { class: 'lbl', text: colour.label }),
            ]));
        }

        return wrap;
    }

    function renderWheels(grid, group, prices) {
        const wheels = group.wheels;
        const price = prices.wheels || 0;

        if (!XS.state.wheelType && XS.state.wheelType !== 0) XS.state.wheelType = wheels.currentType;

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Wheels · Type' }),
            XS.el('div', { class: 'cap' }, [`${wheels.types.length} fitted to model`, stockNote(XS.stockFor('wheels'))]),
            pricer(group),
        ]));

        const types = XS.el('div', { class: 'cards' });

        for (const type of wheels.types) {
            types.append(XS.el('button', {
                class: `c ${XS.state.wheelType === type.type ? 'on' : ''}`,
                onclick: () => { XS.state.wheelType = type.type; XS.rerender('tuning'); },
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
                onmouseenter: () => XS.subject.look('wheels'),
                onclick: () => choose(
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
            XS.el('div', { class: 'cap' }, [`${group.extras.length} on this model`, stockNote(XS.stockFor('extras'))]),
            pricer(group),
        ]));

        const cards = XS.el('div', { class: 'cards' });

        for (const extra of group.extras) {
            cards.append(XS.el('button', {
                class: `c ${extra.on ? 'on' : ''}`,
                onclick: () => toggleExtra(extra),
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

    // Picked, whoever is doing the picking. A mechanic builds the same kind of
    // list a customer does; the difference is what happens at the end of it.
    XS.isPreviewing = function (slotId, index) {
        return (XS.state.basket || []).some((p) => p.slotId === slotId && p.index === index);
    };

    function payload(slot, option, category, price) {
        return {
            slot: slot.slot,
            slotId: slot.id,
            index: option.index,
            label: option.label,
            category,
            price,
            wheelType: slot.wheelType,
            legacy: slot.legacy || false,
        };
    }

    // Clicking a part puts it on the car AND on the list, and leaves it there.
    // One per slot: a second front bumper replaces the first, a rear bumper
    // does not.
    function choose(slot, option, category, price) {
        XS.state.tuneSlot = slot.id;
        XS.post('pickPart', payload(slot, option, category, price));
    }

    function choosePaint(data) {
        XS.state.tuneSlot = 'respray';

        XS.post('pickPart', Object.assign({
            paint: true, slotId: 'respray', category: 'respray',
        }, data));
    }

    function toggleExtra(extra) {
        XS.post('pickPart', {
            extra: extra.id, on: !extra.on, category: 'extras',
            slotId: `extra_${extra.id}`, label: `Extra ${extra.id}`,
        });
    }

    // A customer in a bay is building an ORDER, not paying a bill. Clicking a
    // part puts it on the car and on this list at the same time and leaves it
    // there, so what they are looking at is what they are about to ask for,
    // and the total adds up as they go.
    function renderBasket() {
        const side = XS.el('aside', { class: 'side' });
        const basket = XS.state.basket || [];
        const total = basket.reduce((sum, item) => sum + (item.price || 0), 0);

        side.append(XS.el('div', { class: 'sh' }, [
            XS.el('span', { class: 't', text: 'What you want doing' }),
            basket.length
                ? XS.el('button', {
                    class: 'sub', style: 'padding:4px 9px;font-size:11px',
                    text: 'Clear',
                    onclick: () => XS.post('clearPicks'),
                })
                : XS.el('span', { class: 'n', text: 'NOTHING YET' }),
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
                text: 'Nothing goes on the car until the shop fits it.',
            }),

            // One button, one answer. Nothing here does work to a car — it
            // asks the shop to.
            XS.el('button', {
                class: 'go',
                text: XS.state.takesOrders ? 'Send it to the shop' : 'Nobody is in',
                disabled: !basket.length || !XS.state.takesOrders,
                onclick: () => XS.post('submitOrder'),
            }),

            !XS.state.takesOrders
                ? XS.el('div', {
                    style: 'font-size:11px;color:var(--faint);line-height:1.5;margin-top:10px;text-align:center',
                    text: 'Nobody is working right now. Come back when somebody is in.',
                })
                : null,
        ]));

        return side;
    }

    function renderDraft() {
        if (XS.mode === 'bay') return renderBasket();
        if ((XS.state.basket || []).length) return XS.renderQueue();

        const side = XS.el('aside', { class: 'side' });
        const draft = XS.state.invoice || { items: [], total: 0 };

        side.append(XS.el('div', { class: 'sh' }, [
            XS.el('span', { class: 't', text: 'Invoice draft' }),
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

            XS.el('button', {
                class: 'go',
                text: 'Send to customer',
                disabled: !(draft.items || []).length,
                onclick: () => XS.bill('sendInvoice'),
            }),

            XS.el('button', {
                class: 'sub', text: 'Save for later',
                disabled: !(draft.items || []).length,
                onclick: () => XS.post('saveInvoice'),
            }),
        ]));

        return side;
    }

    // What the mechanic has picked but not fitted yet. Clicking parts builds a
    // list the same way a customer's does — a front bumper and a rear bumper
    // are two things to fit, not one choice between them — and fitting runs
    // through the lot, one job at a time, adding a line each.
    XS.renderQueue = function () {
        const side = XS.el('aside', { class: 'side' });
        const queue = XS.state.basket || [];
        const total = queue.reduce((sum, item) => sum + (item.price || 0), 0);

        side.append(XS.el('div', { class: 'sh' }, [
            XS.el('span', { class: 't', text: 'To fit' }),
            XS.el('button', {
                class: 'sub', style: 'padding:4px 9px;font-size:11px',
                text: 'Clear',
                onclick: () => XS.post('clearPicks'),
            }),
        ]));

        const lines = XS.el('div', { class: 'lines' });

        for (const [i, item] of queue.entries()) {
            const stock = XS.stockFor(item.category, item.slotId);
            const short = !!stock && stock.count < 1;

            lines.append(XS.el('div', { class: 'ln' }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 'd' }, [
                        item.label,
                        short ? XS.el('span', { class: 'tag warn', text: 'NONE LEFT' }) : null,
                    ]),
                    XS.el('div', { class: 'm', text: item.categoryLabel || item.category }),
                ]),
                XS.el('div', { class: 'a', text: XS.money(item.price) }),
                XS.el('button', {
                    class: 'del', text: '×', title: 'Take it off',
                    onclick: () => XS.post('dropPick', { index: i }),
                }),
            ]));
        }

        side.append(lines);

        side.append(XS.el('div', { class: 'tot' }, [
            XS.el('div', { class: 'tr big' }, [
                XS.el('span', { text: 'PARTS' }),
                XS.el('span', { text: XS.money(total) }),
            ]),

            // Parts go on a work order and nowhere else. Billing used to be a
            // second button here, which meant a car could be charged for before
            // anybody had written down what it was having done — and left two
            // places to bill from that had to agree. The order is the one
            // record now: fit off it, bill off it, finish it.
            XS.el('button', {
                class: 'go',
                text: 'Put it on a work order',
                onclick: () => XS.post('bookAll'),
            }),

            XS.el('div', {
                style: 'font-size:11px;color:var(--faint);line-height:1.5;margin-top:10px;text-align:center',
                text: 'Nothing goes on the car from here. It goes on the order — fit the parts at the car, then bill it from Orders.',
            }),
        ]));

        return side;
    };
})();
