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
                onclick: () => { XS.state.tuneCategory = category.id; XS.panels.performance(host); },
            }, [
                XS.el('span', { class: 'n', text: category.label }),
                XS.el('span', {
                    class: `b ${category.current ? 'good' : ''}`,
                    text: category.current ? 'ON' : String(category.options.length),
                }),
            ]));
        }

        tree.append(XS.el('div', { class: 'grp', text: 'Setup' }));
        tree.append(XS.el('button', {
            class: `tn ${chosen === 'stance' ? 'on' : ''}`,
            onclick: () => { XS.state.tuneCategory = 'stance'; XS.panels.performance(host); },
        }, [XS.el('span', { class: 'n', text: 'Stance' })]));

        host.append(tree);

        const grid = XS.el('section', { class: 'grid' });

        if (!car) {
            grid.append(XS.empty('Nothing connected', 'Connect a vehicle first.'));
            host.append(grid);
            return;
        }

        if (XS.state.tuneCategory === 'stance') {
            renderStance(grid, car);
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
            const stock = XS.stockFor('performance');
            const dry = category.requiresItem && !!stock && stock.count < 1;

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
                    else XS.post('fitTuning', { category: category.id, option: option.id });
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
                        text: category.requiresItem ? '1 part' : XS.money(option.price),
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

    const WHEELS = [
        { id: 'fl', label: 'Front left' },
        { id: 'fr', label: 'Front right' },
        { id: 'rl', label: 'Rear left' },
        { id: 'rr', label: 'Rear right' },
    ];

    function renderStance(grid, car) {
        const limits = XS.state.stanceLimits || { height: 0.3, camber: 0.35, track: 0.25 };

        XS.state.stanceDraft = XS.state.stanceDraft || clone(car.stance) || blank();
        const draft = XS.state.stanceDraft;

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Stance' }),
            XS.el('div', { class: 'cap', text: 'live on the vehicle' }),
        ]));

        const push = () => {
            XS.post('previewStance', { stance: draft });
            XS.panels.performance(document.querySelector('[data-panel="performance"]'));
        };

        grid.append(slider('Ride height', draft.height, -limits.height, limits.height, (v) => {
            draft.height = v;
            push();
        }));

        for (const wheel of WHEELS) {
            draft[wheel.id] = draft[wheel.id] || { camber: 0, track: 0 };

            grid.append(XS.el('div', { class: 'gh', style: 'margin-top:20px' }, [
                XS.el('h2', { text: wheel.label }),
                XS.el('div', {
                    class: 'cap',
                    text: `camber ${draft[wheel.id].camber.toFixed(2)} · track ${draft[wheel.id].track.toFixed(2)}`,
                }),
            ]));

            grid.append(XS.el('div', { class: 'split' }, [
                slider('Camber', draft[wheel.id].camber, -limits.camber, limits.camber, (v) => {
                    draft[wheel.id].camber = v;
                    push();
                }),
                slider('Track', draft[wheel.id].track, -limits.track, limits.track, (v) => {
                    draft[wheel.id].track = v;
                    push();
                }),
            ]));
        }

        grid.append(XS.el('div', { style: 'display:flex;gap:9px;margin-top:22px' }, [
            XS.el('button', {
                class: 'mini hot', text: 'Save stance',
                onclick: () => { XS.post('saveStance', { stance: draft }); },
            }),
            XS.el('button', {
                class: 'mini', text: 'Reset',
                onclick: () => {
                    XS.state.stanceDraft = blank();
                    XS.post('previewStance', { stance: XS.state.stanceDraft });
                    XS.panels.performance(document.querySelector('[data-panel="performance"]'));
                },
            }),
        ]));
    }

    function slider(label, value, min, max, onInput) {
        const readout = XS.el('span', {
            style: 'font:600 12px/1 var(--mono);color:var(--accent2)',
            text: Number(value).toFixed(2),
        });

        return XS.el('div', { class: 'field' }, [
            XS.el('label', { style: 'display:flex;justify-content:space-between;align-items:center' }, [
                label, readout,
            ]),
            XS.el('input', {
                type: 'range',
                min: String(min), max: String(max), step: '0.01',
                value: String(value),
                style: 'width:100%;accent-color:var(--accent)',
                oninput: (ev) => {
                    const next = Number(ev.target.value);
                    readout.textContent = next.toFixed(2);
                    onInput(next);
                },
            }),
        ]);
    }

    function blank() {
        const out = { height: 0 };
        for (const wheel of WHEELS) out[wheel.id] = { camber: 0, track: 0 };
        return out;
    }

    function clone(stance) {
        if (!stance) return null;

        const out = { height: Number(stance.height) || 0 };

        for (const wheel of WHEELS) {
            const entry = stance[wheel.id] || {};
            out[wheel.id] = { camber: Number(entry.camber) || 0, track: Number(entry.track) || 0 };
        }

        return out;
    }
})();
