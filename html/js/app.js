(function () {
    const root = document.getElementById('root');
    const led = document.querySelector('[data-led]');

    const TABS = {
        // The tablet is the mechanic's. Running the shop — the books, the
        // staff, the prices — is the laptop's job and lives on the desk.
        //
        // `at` names a kind of point the app only makes sense on. A shop that
        // has not placed one of those is not held to it, or a shop with no
        // dyno would be a shop where the Dyno app can never be opened.
        tablet: [
            { id: 'apps', label: 'Home' },
            { id: 'vehicle', label: 'Vehicle' },
            { id: 'tuning', label: 'Tuning', at: 'tuning', group: 'vehicle' },
            { id: 'repairs', label: 'Repairs' },
            { id: 'service', label: 'Service', when: () => XS.state.serviceEnabled !== false, badge: () => XS.state.vehicle?.service?.due },
            { id: 'performance', label: 'Performance', at: 'tuning', when: () => XS.state.tuningEnabled !== false, group: 'vehicle' },
            { id: 'stance', label: 'Stance', at: 'tuning', when: () => XS.state.tuningEnabled !== false, group: 'vehicle' },
            { id: 'dyno', label: 'Dyno', at: 'dyno', when: () => XS.state.dynoEnabled !== false, group: 'vehicle' },
            { id: 'orders', label: 'Orders', badge: () => XS.state.openOrders },
            { id: 'invoices', label: 'Invoices', badge: () => XS.state.unpaid, when: () => XS.state.invoicesEnabled !== false },
            { id: 'settings', label: 'Settings' },
        ],
        desk: [
            { id: 'apps', label: 'Home' },
            { id: 'invoices', label: 'Invoices', badge: () => XS.state.unpaid, when: () => XS.state.invoicesEnabled !== false },
            { id: 'home', label: 'Shop' },
            { id: 'team', label: 'Team', boss: true },
            { id: 'settings', label: 'Settings' },
        ],
        bay: [
            { id: 'tuning', label: 'Tuning' },
            { id: 'repairs', label: 'Repairs' },
        ],
        bench: [
            { id: 'craft', label: 'Bench' },
        ],
        builder: [
            { id: 'builder', label: 'Shops' },
            { id: 'settings', label: 'Settings' },
        ],
    };

    // The tabs this player can actually reach, in this mode, right now. The nav
    // bar and the home screen both need the same list.
    // The screens that live behind one app rather than beside it. Still real
    // panels, still reachable — they just do not get their own icon.
    XS.appsIn = function (group) {
        return XS.apps(true).filter((tab) => tab.group === group);
    };

    XS.apps = function (withGrouped) {
        const near = XS.state.near || {};

        return (TABS[XS.mode] || []).filter((tab) => {
            if (!withGrouped && tab.group) return false;
            if (tab.boss && !XS.state.isBoss) return false;
            if (tab.when && !tab.when()) return false;

            // near[kind] is false only when the shop HAS that kind of point
            // and you are not stood on one. Undefined means there is nothing
            // to stand on, so the app is not hidden.
            if (tab.at && near[tab.at] === false) return false;

            return true;
        });
    };

    //[[ No tabs.
    //
    //   A tablet does not have a row of tabs across the top — it has a home
    //   screen of apps, and a way back to it. The bar carries the name of
    //   whatever app you are in and a chevron home; the dock along the bottom
    //   does the rest. ]]
    function renderNav() {
        const home = XS.panel === 'apps';
        const tab = (TABS[XS.mode] || []).find((t) => t.id === XS.panel);

        const back = document.querySelector('[data-back]');
        const title = document.querySelector('[data-title]');

        const owner = (TABS[XS.mode] || []).find((t) => t.id === XS.panel)?.group;

        if (back) {
            back.hidden = home || !XS.apps().some((t) => t.id === 'apps');
            back.dataset.to = owner || 'apps';
        }
        if (title) title.textContent = home || !tab ? 'Mechanic' : tab.label;

        // What the tablet is plugged into, the way the reference says it.
        const link = document.querySelector('[data-link]');

        if (link) {
            const plate = XS.state.vehicle?.plate;

            link.hidden = !plate;
            link.textContent = plate ? `Connected to ${plate}` : '';
        }

        const duty = document.querySelector('[data-dock-duty]');

        if (duty) {
            const on = XS.state.onDuty !== false;

            duty.textContent = on ? 'On duty' : 'Off duty';
            duty.className = `dk state ${on ? 'on' : ''}`;
        }

        const drop = document.querySelector('[data-dock-drop]');
        if (drop) drop.hidden = !XS.state.vehicle || XS.mode !== 'tablet';

        const dock = document.querySelector('[data-dock]');
        if (dock) dock.hidden = !XS.apps().some((t) => t.id === 'apps');
    }

    //[[ Which shell the screen is wearing.
    //
    //   Tuning is not a page with a picture of a car on it — the car IS the
    //   screen and the panel is a sheet over it. Everything else is a tablet,
    //   a laptop or the bench. ]]
    const SHEET = new Set(['tuning', 'stance']);

    function layout() {
        if (SHEET.has(XS.panel)) return 'sheet';
        if (XS.mode === 'desk') return 'laptop';
        if (XS.mode === 'bench') return 'bench';
        return 'tablet';
    }

    function dress() {
        const shell = layout();

        document.body.dataset.layout = shell;

        // Which screen is up, so the stylesheet can size the device to it. The
        // home screen is two short rows of apps and does not need the glass an
        // eight column parts list does.
        //
        // Deliberately NOT data-panel: the panel sections are [data-panel], and
        // putting the same attribute on body makes body the first match for
        // querySelector('[data-panel="apps"]') — which then clears the whole
        // shell and renders the screen into it.
        document.body.dataset.screen = XS.panel || '';

        const device = document.querySelector('.device');
        if (device) device.dataset.device = shell === 'sheet' ? 'tablet' : shell;

    }

    XS.show = function (id) {
        XS.panel = id;
        dress();

        // Lua needs to know which screen is up: when it steps the panel aside
        // to fit a part, it has to put the same one back.
        XS.post('panel', { id });

        for (const panel of document.querySelectorAll('.panel')) {
            panel.classList.toggle('on', panel.dataset.panel === id);
        }

        renderNav();

        // The column belongs to the screen, not to the session: the home
        // screen has no car beside it and every other screen does, so leaving
        // home has to put it back.
        XS.subject.redraw();

        XS.rerender(id);

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

        // An app you have walked away from cannot stay on screen — the bay
        // apps go when you leave the bay, and standing on a dead panel is
        // worse than being put back on the home screen.
        if (!XS.apps().some((tab) => tab.id === XS.panel)) {
            if (XS.apps().some((tab) => tab.id === 'apps')) { XS.show('apps'); return; }
        }

        XS.rerender(XS.panel);
    };

    XS.open = function (payload) {
        Object.assign(XS.state, payload?.state || {});
        XS.mode = payload?.mode || 'tablet';

        const first = (TABS[XS.mode] || []).find((t) => !t.when || t.when());
        XS.panel = payload?.panel || (first ? first.id : 'vehicle');

        dress();

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

    for (const [selector, go] of [
        // Back to whatever owns this screen. Out of Tuning that is Vehicle, not
        // all the way home — renderNav sets data-to each time it draws.
        ['[data-back]', (e) => XS.show(e.currentTarget?.dataset.to || 'apps')],
        ['[data-dock-home]', () => XS.show('apps')],
        ['[data-dock-close]', () => XS.close()],
        ['[data-dock-drop]', () => XS.post('disconnect')],
    ]) {
        const button = document.querySelector(selector);
        if (button) button.addEventListener('click', go);
    }


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

    // What the page can see about where it is running. The one question worth
    // asking first when the interface misbehaves is whether it knows it is in
    // game at all, and it is the one thing nobody can check from the console.
    XS.post('ready', {
        host: location.hostname,
        native: typeof GetParentResourceName === 'function',
        mock: document.body.classList.contains('standalone'),
    }).then((reply) => {
        if (!reply || !reply.debug) return;

        // Who opened the panel, and what the shell is doing when nobody has.
        // Both answers live in the page and nowhere a console can reach.
        const open = XS.open;

        XS.open = function (payload) {
            XS.post('diag', {
                what: 'open called',
                detail: `mode ${payload?.mode || '?'}, panel ${payload?.panel || '?'}, `
                    + `keys ${Object.keys(payload?.state || {}).length} — `
                    + String(new Error().stack || '').split('\n').slice(1, 4).join(' | '),
            });

            return open.apply(this, arguments);
        };

        setTimeout(() => {
            const sheets = [...document.styleSheets];
            let rootRule = null;

            for (const sheet of sheets) {
                let rules;
                try { rules = sheet.cssRules; } catch { continue; }
                for (const rule of rules) if (rule.selectorText === '#root') rootRule = rule.style.opacity;
            }

            XS.post('diag', {
                what: 'shell after 2s',
                detail: `class "${root.className || 'none'}", opacity ${getComputedStyle(root).opacity}, `
                    + `sheets ${sheets.length}, #root rule opacity ${rootRule === null ? 'NOT FOUND' : rootRule}`,
            });
        }, 2000);
    });
})();
