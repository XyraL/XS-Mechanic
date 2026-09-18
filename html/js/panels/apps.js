(function () {
    // The tablet's home screen. A wall of text tabs is a menu; a wall of apps
    // is a tablet, and the shop's people pick this thing up twenty times a
    // shift. The nav bar is still there for moving between screens once you
    // are inside one.
    const GLYPH = {
        vehicle: '<path d="M5 16h14M6.5 16l1.2-5.1A2 2 0 0 1 9.6 9.3h4.8a2 2 0 0 1 1.9 1.6L17.5 16M7 16v2M17 16v2"/><circle cx="8.4" cy="16" r="1.3"/><circle cx="15.6" cy="16" r="1.3"/>',
        tuning: '<path d="M14.7 6.3a4 4 0 0 0 5.3 5.3l-8 8a2.1 2.1 0 0 1-3-3z"/><path d="M6.5 17.5h.01"/>',
        repairs: '<path d="M9 5.5 5.5 9 4 7.5a4 4 0 0 0 5.4 5.4l6 6a2 2 0 0 0 2.8-2.8l-6-6A4 4 0 0 0 6.8 4.7z"/>',
        service: '<path d="M12 4v4M12 16v4M4 12h4M16 12h4"/><circle cx="12" cy="12" r="3.2"/>',
        performance: '<path d="M12 19a7 7 0 1 1 7-7"/><path d="M12 12l4-3"/>',
        dyno: '<path d="M4 18a8 8 0 0 1 16 0"/><path d="M12 18l3.5-5"/>',
        orders: '<rect x="5" y="4" width="14" height="16" rx="2"/><path d="M9 9h6M9 13h6M9 17h3"/>',
        invoices: '<path d="M6 3h12v18l-3-2-3 2-3-2-3 2z"/><path d="M9.5 8h5M9.5 12h5"/>',
        home: '<path d="M4 11 12 4l8 7"/><path d="M6.5 10v9h11v-9"/>',
        team: '<circle cx="9" cy="9" r="3"/><path d="M3.5 19a5.5 5.5 0 0 1 11 0"/><path d="M16 7.2a3 3 0 0 1 0 5.6M17.5 19a5.5 5.5 0 0 0-2-4.2"/>',
        settings: '<circle cx="12" cy="12" r="2.8"/><path d="M12 3.5v2M12 18.5v2M3.5 12h2M18.5 12h2M6 6l1.4 1.4M16.6 16.6 18 18M18 6l-1.4 1.4M7.4 16.6 6 18"/>',
        craft: '<path d="M4 20 14 10"/><path d="M13 5.5 18.5 11 21 8.5 15.5 3z"/><path d="M11 12l1.5 1.5"/>',
    };

    const TONE = {
        vehicle: 'blue', tuning: 'violet', repairs: 'amber', service: 'orange',
        performance: 'pink', dyno: 'pink', orders: 'green', invoices: 'blue',
        home: 'brown', team: 'brown', settings: 'grey', craft: 'amber',
    };

    XS.panels.apps = function (host) {
        XS.clear(host);

        const grid = XS.el('section', { class: 'grid' });
        const apps = XS.apps().filter((tab) => tab.id !== 'apps');

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: XS.state.shop?.name || 'Mechanic' }),
        ]));

        const wall = XS.el('div', { class: 'apps' });

        for (const tab of apps) {
            const count = tab.badge ? tab.badge() : 0;

            wall.append(XS.el('button', {
                class: 'app', 'data-tone': TONE[tab.id] || 'grey',
                onclick: () => XS.show(tab.id),
            }, [
                XS.el('span', {
                    class: 'ic',
                    html: `<svg viewBox="0 0 24 24">${GLYPH[tab.id] || GLYPH.settings}</svg>`,
                }),
                count ? XS.el('span', { class: 'bdg', text: String(count) }) : null,
                XS.el('span', { class: 'lb', text: tab.label }),
            ]));
        }

        grid.append(wall);
        host.append(grid);
    };
})();
