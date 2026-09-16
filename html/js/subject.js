// The left pane. Whatever the tablet is pointed at lives here and stays there
// while you move between panels — the car for a mechanic, the shop list for
// the builder.
XS.subject = (function () {
    const host = document.querySelector('[data-subject]');
    const split = document.querySelector('[data-split]');

    // Where the live-camera window sits on screen, as fractions of the
    // viewport. Lua needs this to frame the real vehicle inside it, and it has
    // to be measured rather than assumed — the panel scales with the screen.
    function reportViewport() {
        const view = host.querySelector('[data-view]');

        if (!view) {
            XS.post('carView', { active: false });
            return;
        }

        const r = view.getBoundingClientRect();

        // A hidden pane reports zeros; sending those would aim the camera at
        // the corner of the screen.
        if (r.width < 10 || r.height < 10) return;

        XS.post('carView', {
            active: true,
            x: (r.left + r.width / 2) / window.innerWidth,
            y: (r.top + r.height / 2) / window.innerHeight,
            w: r.width / window.innerWidth,
            h: r.height / window.innerHeight,
        });
    }

    function car(vehicle) {
        const hero = XS.el('div', { class: 'hero' });

        if (XS.state.livePreview !== false) {
            hero.append(XS.el('div', { class: 'view', 'data-view': true }, [
                XS.el('div', { class: 'hint', text: 'live' }),
            ]));
        } else {
            hero.append(XS.el('div', { class: 'art', html: DRAWING }));
        }

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
            reportViewport();
            return;
        }

        // The laptop and the counter are not pointed at a car, so they get the
        // whole width rather than an empty column.
        if (XS.mode === 'desk' || XS.mode === 'counter') {
            split.className = 'split wide';
            reportViewport();
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

            reportViewport();
            return;
        }

        car(XS.state.vehicle);

        // After layout, so the rect is real.
        requestAnimationFrame(reportViewport);
    }

    const DRAWING = `
<svg viewBox="0 0 640 210" xmlns="http://www.w3.org/2000/svg">
  <defs><linearGradient id="carbody" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#3d566f"/><stop offset="1" stop-color="#16222f"/>
  </linearGradient></defs>
  <path d="M40 158c-6-28 2-45 15-52l80-13c21-25 55-40 105-42 51-2 91 10 122 30l80 15c25 6 38 21 40 44 1 13-4 21-15 23l-36 2c-4-25-21-38-42-38s-38 13-42 38H228c-4-25-21-38-42-38s-38 13-42 38l-86-2c-9 0-14-5-15-13Z" fill="url(#carbody)"/>
  <path d="M160 92c19-21 48-32 84-34 38-2 68 8 93 25l-15 13-147 2-15-6Z" fill="#4a7ba8" opacity=".85"/>
  <circle cx="186" cy="160" r="38" fill="#070c14"/><circle cx="186" cy="160" r="22" fill="#22374d"/>
  <circle cx="186" cy="160" r="9" fill="#2f81f7" fill-opacity=".6"/>
  <circle cx="430" cy="160" r="38" fill="#070c14"/><circle cx="430" cy="160" r="22" fill="#22374d"/>
  <circle cx="430" cy="160" r="9" fill="#2f81f7" fill-opacity=".6"/>
</svg>`;

    window.addEventListener('resize', () => requestAnimationFrame(reportViewport));

    return { redraw, reportViewport };
})();
