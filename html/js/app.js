(function () {
    const root = document.getElementById('root');
    const nav = document.querySelector('[data-nav]');
    const led = document.querySelector('[data-led]');

    const TABS = {
        tablet: [
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
        ],
        builder: [
            { id: 'builder', label: 'Shops' },
            { id: 'settings', label: 'Settings' },
        ],
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

    XS.show = function (id) {
        XS.panel = id;

        for (const panel of document.querySelectorAll('.panel')) {
            panel.classList.toggle('on', panel.dataset.panel === id);
        }

        renderNav();

        const render = XS.panels[id];
        if (render) render(document.querySelector(`[data-panel="${id}"]`));

        // The pane can change shape between panels, so the camera is told
        // again rather than assuming the window has not moved.
        requestAnimationFrame(XS.subject.reportViewport);
    };

    XS.redraw = function () {
        document.querySelector('[data-shop-name]').textContent =
            XS.state.shop?.name || (XS.mode === 'builder' ? 'Builder' : 'No shop');

        document.querySelector('[data-who]').textContent = XS.state.name || '—';
        document.querySelector('[data-duty]').className = XS.state.onDuty === false ? 'off' : '';

        if (led) led.className = XS.state.vehicle ? 'led' : 'led off';

        document.body.setAttribute('data-accent', XS.state.settings?.accent || 'blue');

        XS.subject.redraw();
        renderNav();

        const render = XS.panels[XS.panel];
        if (render) render(document.querySelector(`[data-panel="${XS.panel}"]`));
    };

    XS.open = function (payload) {
        Object.assign(XS.state, payload?.state || {});
        XS.mode = payload?.mode || 'tablet';

        const first = (TABS[XS.mode] || []).find((t) => !t.when || t.when());
        XS.panel = payload?.panel || (first ? first.id : 'vehicle');

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
        XS.post('carView', { active: false });
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
