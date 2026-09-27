// The left pane. Whatever the tablet is pointed at lives here and stays there
// while you move between panels — the car for a mechanic, the shop list for
// the builder.
XS.subject = (function () {
    const host = document.querySelector('[data-subject]');
    const split = document.querySelector('[data-split]');

    // Where the live-camera window sits on screen, as fractions of the
    // viewport. Lua needs this to frame the real vehicle inside it, and it has
    // to be measured rather than assumed — the panel scales with the screen.

    // Which part of the car the window should be looking at. The panel sets it
    // when the category or the slot changes and the camera walks round to it.
    // Hovering a part used to swing a camera to that corner of the car. It is
    // kept as a no-op because the tuning panel calls it on every hover, and a
    // missing function there would take the row render down with it.
    function look() {}

    function car(vehicle) {
        // No picture of the car. There is one three feet in front of you, and a
        // window cut through the panel to show it again cost a camera, a hole
        // punched through every layer of the shell, and a viewport measured on
        // every redraw — to tell you what you could already see.
        const hero = XS.el('div', { class: 'hero bare' });

        hero.append(XS.el('div', { class: 'meta' }, [
            XS.el('span', { class: 'plate', text: vehicle.plate || '——' }),
            XS.el('h1', { text: vehicle.name || vehicle.model || 'Vehicle' }),
            XS.el('div', {
                class: 'sub',
                text: [vehicle.className, vehicle.drive, vehicle.electric ? 'Electric' : 'Petrol']
                    .filter(Boolean).join(' · '),
            }),
        ]));

        host.append(hero);

        // Walk up to a car, connect, and the first thing you see is whether
        // somebody has already asked for something to be done to it.
        const order = XS.mode === 'tablet' ? XS.orderFor(vehicle.plate) : null;

        if (order) {
            const parts = (order.requested || []).filter((p) => p && typeof p === 'object');

            host.append(XS.el('button', {
                class: `callout ${order.status === 'claimed' ? 'on' : ''}`,
                onclick: () => XS.show('orders'),
            }, [
                XS.el('div', { class: 'k', text: order.status === 'claimed' ? 'Order in progress' : 'Open work order' }),
                XS.el('div', { class: 'v', text: `${parts.length || 'No'} part${parts.length === 1 ? '' : 's'} · ${XS.money(order.quote)}` }),
                XS.el('div', { class: 'm', text: `${order.customerName || 'a customer'} · ${XS.ago(order.createdAt)}` }),
            ]));
        }

        const engine = Math.round((vehicle.health?.engine || 0) / 10);
        const body = Math.round((vehicle.health?.body || 0) / 10);
        const due = vehicle.service?.due || 0;

        host.append(stat('Engine', `${engine}%`, engine, engine < 40 ? 't-bad' : engine < 70 ? 't-warn' : ''));
        host.append(stat('Body', `${body}%`, body, body < 40 ? 't-bad' : body < 70 ? 't-warn' : ''));

        if (XS.state.serviceEnabled !== false) {
            host.append(stat('Service', due > 0 ? `${due} due` : 'OK', due > 0 ? 18 : 100, due > 0 ? 't-bad' : ''));
        }

        host.append(stat('Odometer', XS.num(vehicle.odometer) + ' km', 48, 't-none'));

        if (vehicle.output) {
            host.append(stat('Output', `${XS.num(vehicle.output)} hp`, vehicle.outputPercent || 0, 't-cool'));
        }

        const fitted = (XS.state.catalogue?.slots || []).filter((s) => s.current !== -1);

        if (fitted.length) {
            host.append(XS.el('h3', { text: `Already fitted · ${fitted.length}` }));

            for (const slot of fitted.slice(0, 8)) {
                const option = (slot.options || []).find((o) => o.index === slot.current);

                host.append(XS.el('div', { class: 'fit' }, [
                    XS.el('span', { text: option?.label || `Index ${slot.current}` }),
                    XS.el('span', { class: 'm', text: slot.label }),
                ]));
            }
        }

        if (XS.mode === 'tablet') {
            host.append(XS.el('button', {
                class: 'sub', style: 'width:100%;margin-top:14px',
                text: 'Disconnect',
                onclick: () => XS.post('disconnect'),
            }));
        }
    }

    function stat(label, value, percent, tone) {
        return XS.el('div', { class: `stat ${tone || ''}` }, [
            XS.el('div', {}, [
                XS.el('div', { class: 'k', text: label }),
                XS.track(percent, tone),
            ]),
            XS.el('div', { class: 'n', text: value }),
        ]);
    }

    function shops() {
        const list = XS.state.shops || [];

        host.append(XS.el('h3', { style: 'margin-top:0', text: `Shops · ${list.length}` }));

        for (const shop of list) {
            host.append(XS.el('button', {
                class: `shopcard ${XS.state.draft && XS.state.draft.id === shop.id ? 'on' : ''}`,
                onclick: () => XS.post('editShop', { id: shop.id }),
            }, [
                XS.el('div', { class: 'nm' }, [
                    shop.name,
                    XS.el('span', { class: `st ${shop.enabled ? 'f' : 'w'}`, text: shop.enabled ? 'ON' : 'OFF' }),
                ]),
                XS.el('div', {
                    class: 'm',
                    text: `${shop.job || 'self service'} · ${shop.kind}`,
                }),
            ]));
        }

        host.append(XS.el('button', {
            class: 'shopcard new', text: '+ Build a shop',
            onclick: () => XS.post('newShop'),
        }));
    }

    function empty(title, note) {
        host.append(XS.el('div', { class: 'nocar' }, [
            XS.el('b', { text: title }),
            note,
        ]));
    }

    function redraw() {
        XS.clear(host);

        if (XS.mode === 'builder') {
            split.className = 'split';
            shops();
            return;
        }

        // The home screen, the laptop and the bench are not pointed at a car,
        // so they get the whole width rather than an empty column. A wall of
        // apps next to a column of car stats is two ideas fighting.
        //
        // Work orders are the shop's book, not one car's page. It lists jobs
        // across several plates, so a render of whichever one happens to be
        // connected is answering a question the screen is not asking.
        if (XS.panel === 'apps' || XS.panel === 'orders'
            || XS.mode === 'desk' || XS.mode === 'bench') {
            split.className = 'split wide';
            return;
        }

        split.className = 'split';

        if (!XS.state.vehicle) {
            empty('Nothing connected', XS.mode === 'bay'
                ? 'Drive a vehicle onto the bay.'
                : 'Stand next to a vehicle and connect to it.');

            if (XS.mode === 'tablet') {
                host.append(XS.el('button', {
                    class: 'go', style: 'width:100%;margin-top:14px',
                    text: 'Connect nearest vehicle',
                    onclick: () => XS.post('connect'),
                }));
            }

            return;
        }

        car(XS.state.vehicle);

    }

    return { redraw, look };
})();