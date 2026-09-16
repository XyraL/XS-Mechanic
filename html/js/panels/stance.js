(function () {
    // Stance is visual work, so it gets the sheet over the car rather than a
    // page in the tablet: move a slider and watch the car drop.
    const WHEELS = [
        { id: 'fl', label: 'Front left', axle: 'front' },
        { id: 'fr', label: 'Front right', axle: 'front' },
        { id: 'rl', label: 'Rear left', axle: 'rear' },
        { id: 'rr', label: 'Rear right', axle: 'rear' },
    ];

    XS.panels.stance = function (host) {
        XS.clear(host);

        const car = XS.state.vehicle;
        const grid = XS.el('section', { class: 'grid' });

        if (!car) {
            grid.append(XS.empty('Nothing connected', 'Connect a vehicle first.'));
            host.append(grid);
            return;
        }

        const limits = XS.state.stanceLimits || { height: 0.3, camber: 0.35, track: 0.25 };

        XS.state.stanceDraft = XS.state.stanceDraft || clone(car.stance) || blank();
        const draft = XS.state.stanceDraft;

        const on = touched(draft);

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Stance' }),
            XS.el('div', { class: 'cap', text: 'live on the vehicle' }),
        ]));

        const push = () => {
            XS.post('previewStance', { stance: draft });
            XS.rerender('stance');
        };

        // Off is the factory setup, and turning it off puts the car back rather
        // than leaving it where the sliders happened to be.
        grid.append(XS.el('label', { class: 'toggle' }, [
            XS.el('input', {
                type: 'checkbox', checked: on,
                onchange: (ev) => {
                    if (ev.target.checked) {
                        draft.height = -0.06;
                    } else {
                        XS.state.stanceDraft = blank();
                    }

                    XS.post('previewStance', { stance: XS.state.stanceDraft });
                    XS.rerender('stance');
                },
            }),
            XS.el('span', { class: 'sw' }),
            XS.el('span', { class: 'lb', text: 'Enable stancing' }),
            XS.el('span', { class: 'pr', text: XS.money((XS.state.prices || {}).stance || 0) }),
        ]));

        grid.append(XS.el('label', { class: 'toggle' }, [
            XS.el('input', {
                type: 'checkbox', checked: XS.state.stanceEach === true,
                onchange: (ev) => { XS.state.stanceEach = ev.target.checked; XS.rerender('stance'); },
            }),
            XS.el('span', { class: 'sw' }),
            XS.el('span', { class: 'lb', text: 'Adjust wheels individually' }),
        ]));

        grid.append(XS.el('div', { class: 'gh', style: 'margin-top:18px' }, [
            XS.el('h2', { text: 'Suspension height' }),
        ]));

        grid.append(slider(null, draft.height, -limits.height, limits.height, (v) => {
            draft.height = v;
            push();
        }));

        if (XS.state.stanceEach) {
            for (const wheel of WHEELS) {
                draft[wheel.id] = draft[wheel.id] || { camber: 0, track: 0 };

                grid.append(XS.el('div', { class: 'gh', style: 'margin-top:18px' }, [
                    XS.el('h2', { text: wheel.label }),
                ]));

                grid.append(slider('Camber', draft[wheel.id].camber, -limits.camber, limits.camber, (v) => {
                    draft[wheel.id].camber = v;
                    push();
                }));

                grid.append(slider('Track', draft[wheel.id].track, -limits.track, limits.track, (v) => {
                    draft[wheel.id].track = v;
                    push();
                }));
            }
        } else {
            // Per axle, which is how anybody actually thinks about it.
            for (const [key, label] of [['camber', 'Camber'], ['track', 'Track width']]) {
                grid.append(XS.el('div', { class: 'gh', style: 'margin-top:18px' }, [
                    XS.el('h2', { text: label }),
                ]));

                for (const axle of ['front', 'rear']) {
                    const wheels = WHEELS.filter((w) => w.axle === axle);
                    const limit = key === 'camber' ? limits.camber : limits.track;

                    for (const wheel of wheels) draft[wheel.id] = draft[wheel.id] || { camber: 0, track: 0 };

                    grid.append(slider(axle === 'front' ? 'Front' : 'Rear',
                        draft[wheels[0].id][key], -limit, limit, (v) => {
                            for (const wheel of wheels) draft[wheel.id][key] = v;
                            push();
                        }));
                }
            }
        }

        grid.append(XS.el('div', { style: 'display:flex;gap:9px;margin-top:22px' }, [
            XS.el('button', {
                class: 'mini hot', text: 'Save stance',
                onclick: () => XS.post('saveStance', { stance: draft }),
            }),
            // Resetting has to be saved as well as shown, or the old stance
            // comes straight back the next time the car spawns.
            XS.el('button', {
                class: 'mini', text: 'Back to factory',
                onclick: () => {
                    XS.state.stanceDraft = blank();
                    XS.post('previewStance', { stance: XS.state.stanceDraft });
                    XS.post('saveStance', { stance: XS.state.stanceDraft });
                    XS.rerender('stance');
                },
            }),
        ]));

        host.append(grid);
    };

    function slider(label, value, min, max, onInput) {
        const readout = XS.el('span', {
            class: 'rd',
            text: `${Math.round((Number(value) / max) * 100)}%`,
        });

        return XS.el('div', { class: 'field slide' }, [
            XS.el('label', {}, [label || '', readout]),
            XS.el('input', {
                type: 'range',
                min: String(min), max: String(max), step: '0.01',
                value: String(value),
                oninput: (ev) => {
                    const next = Number(ev.target.value);
                    readout.textContent = `${Math.round((next / max) * 100)}%`;
                    onInput(next);
                },
            }),
        ]);
    }

    function touched(stance) {
        if (!stance) return false;
        if (stance.height) return true;

        return WHEELS.some((w) => stance[w.id] && (stance[w.id].camber || stance[w.id].track));
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
