(function () {
    const root = document.getElementById('root');
    const nav = document.querySelector('[data-nav]');
    const strip = document.querySelector('[data-strip]');
    const led = document.querySelector('[data-led]');

    // Which tabs each mode gets, and how wide the work area is for each panel.
    const TABS = {
        tablet: [
            // Vehicle first: the tablet is carried by a mechanic working on a
            // car, so connecting one is the first thing it should offer.
            { id: 'vehicle', label: 'Vehicle' },
            { id: 'tuning', label: 'Tuning' },
            { id: 'repairs', label: 'Repairs' },
            { id: 'service', label: 'Service', when: () => XS.state.serviceEnabled !== false, badge: () => XS.state.vehicle?.service?.due },
            { id: 'performance', label: 'Performance', when: () => XS.state.tuningEnabled !== false },
            { id: 'dyno', label: 'Dyno', when: () => XS.state.dynoEnabled !== false },
            { id: 'invoices', label: 'Invoices', badge: () => XS.state.unpaid },
            { id: 'parts', label: 'Parts' },
            { id: 'home', label: 'Shop' },
            { id: 'team', label: 'Team', boss: true },
            { id: 'settings', label: 'Settings' },
        ],
        desk: [
            { id: 'invoices', label: 'Invoices', badge: () => XS.state.unpaid },
            { id: 'orders', label: 'Orders', badge: () => XS.state.openOrders },
            { id: 'parts', label: 'Parts' },
            { id: 'home', label: 'Shop' },
            { id: 'team', label: 'Team', boss: true },
            { id: 'settings', label: 'Settings' },
        ],
        counter: [
            { id: 'parts', label: 'Parts' },
        ],
        bay: [
            { id: 'tuning', label: 'Tuning' },
            { id: 'repairs', label: 'Repairs' },
            { id: 'settings', label: 'Settings' },
        ],
        builder: [
            { id: 'builder', label: 'Shops' },
            { id: 'settings', label: 'Settings' },
        ],
    };

    const LAYOUT = {
        home: 'one', vehicle: 'one', tuning: 'three', repairs: 'two',
        invoices: 'two', parts: 'two', team: 'two', settings: 'one', builder: 'two', orders: 'two',
        service: 'two', performance: 'two', dyno: 'one',
    };

    function renderNav() {
        XS.clear(nav);

        for (const tab of TABS[XS.mode] || []) {
            if (tab.boss && !XS.state.isBoss) continue;
            if (tab.when && !tab.when()) continue;

            const count = tab.badge ? tab.badge() : 0;

            nav.append(XS.el('button', {
                class: XS.panel === tab.id ? 'on' : '',
                onclick: () => XS.show(tab.id),
            }, [
                tab.label,
                count ? XS.el('span', { class: 'badge', text: String(count) }) : null,
            ]));
        }
    }

    // The readout strip. With no vehicle connected it collapses to one line
    // that says so, rather than showing a row of dashes.
    function renderStrip() {
        XS.clear(strip);

        const car = XS.state.vehicle;

        // The laptop never leaves the office, so it summarises the shop where
        // the handheld would be showing the car it is plugged into.
        if (XS.mode === 'desk' || XS.mode === 'counter') {
            const s = XS.state.summary || {};

            strip.className = 'strip';
            strip.append(XS.el('div', { class: 'nocar' }, [
                XS.el('b', { text: XS.state.shop?.name || 'Shop' }),
                `${s.unpaid || 0} unpaid · ${s.orders || 0} open orders · ${XS.money(s.funds || 0)} in the account`,
            ]));
            return;
        }

        if (XS.mode === 'builder') {
            strip.className = 'strip';
            strip.append(XS.el('div', { class: 'nocar' }, [
                XS.el('b', { text: `${(XS.state.shops || []).length} shops` }),
                'on this server. Place points with the free camera, then save.',
            ]));
            return;
        }

        if (!car) {
            strip.className = 'strip';
            strip.append(XS.el('div', { class: 'nocar' }, [
                XS.el('b', { text: 'No vehicle connected.' }),
                XS.mode === 'bay'
                    ? 'Drive into the bay to begin.'
                    : 'Stand next to one and press Connect on the Vehicle tab.',
            ]));
            return;
        }

        strip.className = 'strip';

        const service = car.service || {};
        const due = service.due || 0;

        strip.append(XS.el('div', { class: 'cell ident' }, [
            XS.el('span', { class: 'plate', text: car.plate || '——' }),
            XS.el('div', {}, [
                XS.el('div', { class: 'nm', text: car.name || car.model || 'Vehicle' }),
                XS.el('div', {
                    class: 'sub',
                    text: [car.className, car.drive, car.electric ? 'Electric' : 'Petrol']
                        .filter(Boolean).join(' · '),
                }),
            ]),
        ]));

        const engine = Math.round((car.health?.engine || 0) / 10);
        const body = Math.round((car.health?.body || 0) / 10);

        strip.append(XS.cell('Engine', engine, '%', engine,
            engine < 40 ? 't-bad' : engine < 70 ? 't-warn' : '', engine < 40 ? 'danger' : ''));
        strip.append(XS.cell('Body', body, '%', body,
            body < 40 ? 't-bad' : body < 70 ? 't-warn' : '', body < 40 ? 'danger' : ''));
        strip.append(XS.cell('Odometer', XS.num(car.odometer), 'km', null));

        if (XS.state.serviceEnabled !== false) {
            strip.append(XS.cell(
                'Service',
                due > 0 ? `${due} DUE` : 'OK',
                null,
                due > 0 ? 18 : 100,
                due > 0 ? 't-bad' : '',
                due > 0 ? 'alert' : '',
            ));
        }

        if (car.output) {
            strip.append(XS.cell('Output', XS.num(car.output), 'hp', car.outputPercent || 0, 't-cool'));
        }

        if (XS.mode === 'tablet') {
            strip.append(XS.el('div', { class: 'stripact' }, [
                XS.el('button', {
                    class: 'mini hot', text: 'Disconnect',
                    onclick: () => XS.post('disconnect'),
                }),
            ]));
        }
    }

    XS.show = function (id) {
        XS.panel = id;

        for (const panel of document.querySelectorAll('.panel')) {
            panel.classList.toggle('on', panel.dataset.panel === id);
        }

        const work = document.querySelector('[data-work]');
        work.className = `work ${LAYOUT[id] || 'one'}`;

        renderNav();

        const render = XS.panels[id];
        if (render) render(document.querySelector(`[data-panel="${id}"]`));
    };

    XS.redraw = function () {
        document.querySelector('[data-shop-name]').textContent =
            XS.state.shop?.name || (XS.mode === 'builder' ? 'Builder' : 'No shop');

        document.querySelector('[data-who]').textContent =
            XS.state.name || '—';

        document.querySelector('[data-duty]').className =
            XS.state.onDuty === false ? 'off' : '';

        if (led) led.className = XS.state.vehicle ? 'led' : 'led off';

        document.body.setAttribute('data-accent', XS.state.settings?.accent || 'amber');

        renderStrip();
        renderNav();

        const render = XS.panels[XS.panel];
        if (render) render(document.querySelector(`[data-panel="${XS.panel}"]`));
    };

    XS.open = function (payload) {
        Object.assign(XS.state, payload?.state || {});
        XS.mode = payload?.mode || 'tablet';

        const first = (TABS[XS.mode] || [])[0];
        XS.panel = payload?.panel || (first ? first.id : 'home');

        const device = document.querySelector('.device');
        if (device) device.dataset.device = XS.mode === 'desk' ? 'laptop' : 'tablet';

        root.classList.add('open');
        document.body.classList.add('open');
        XS.redraw();
        XS.show(XS.panel);
    };

    XS.close = function () {
        root.classList.remove('open');
        document.body.classList.remove('open');
        XS.closeModal();
        XS.post('close');
    };

    document.querySelector('[data-close]').addEventListener('click', XS.close);

    document.addEventListener('keydown', (ev) => {
        if (ev.key !== 'Escape') return;

        const modal = document.getElementById('modal');
        if (!modal.hidden) { XS.closeModal(); return; }

        if (root.classList.contains('open')) XS.close();
    });

    window.addEventListener('message', (ev) => {
        const data = ev.data || {};

        switch (data.action) {
            case 'open':
                XS.open(data);
                break;

            case 'close':
                root.classList.remove('open');
        document.body.classList.remove('open');
                XS.closeModal();
                break;

            case 'state':
                Object.assign(XS.state, data.state || {});
                if (root.classList.contains('open')) XS.redraw();
                XS.hud.redraw();
                break;

            case 'vehicle':
                XS.state.vehicle = data.vehicle || null;
                XS.state.catalogue = data.catalogue || null;
                if (root.classList.contains('open')) XS.redraw();
                XS.hud.redraw();
                break;

            case 'hud':
                XS.hud.set(data.hud);
                break;

            case 'toast':
                XS.toast(data.message, data.kind);
                break;

            case 'dyno':
                XS.state.dyno = data;
                if (XS.panel === 'dyno') XS.show('dyno');
                break;

            case 'draft':
                XS.state.draft = data.draft || null;
                if (root.classList.contains('open')) XS.redraw();
                break;
        }
    });

    XS.post('ready');
})();
