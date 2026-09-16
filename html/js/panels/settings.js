(function () {
    XS.panels.settings = function (host) {
        XS.clear(host);

        const grid = XS.el('section', { class: 'grid' });
        const settings = XS.state.settings || {};

        const save = (key, value) => {
            XS.state.settings = { ...settings, [key]: value };
            XS.post('settings', { key, value });
            XS.redraw();
        };

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Screen' }),
            XS.el('div', { class: 'cap', text: 'yours only' }),
        ]));

        const accents = XS.el('div', { class: 'cards' });

        for (const [id, label, hex] of [
            ['blue', 'Blue', '#2f81f7'],
            ['cyan', 'Cyan', '#35d6f0'],
            ['teal', 'Teal', '#2fe0bd'],
            ['violet', 'Violet', '#a98bff'],
            ['amber', 'Amber', '#ffa629'],
            ['green', 'Green', '#4ade80'],
        ]) {
            accents.append(XS.el('button', {
                class: `c ${(settings.accent || 'blue') === id ? 'on' : ''}`,
                onclick: () => save('accent', id),
            }, [
                XS.el('div', { style: `height:26px;border-radius:6px;background:${hex};margin-bottom:11px` }),
                XS.el('div', { class: 'nm', style: 'margin-bottom:0', text: label }),
            ]));
        }

        grid.append(accents);

        grid.append(XS.el('div', { class: 'gh', style: 'margin-top:22px' }, [
            XS.el('h2', { text: 'Behaviour' }),
            XS.el('div', { class: 'cap', text: 'saved to your character' }),
        ]));

        const toggles = XS.el('div', { style: 'max-width:520px' });

        for (const [key, label, note, fallback] of [
            ['hud', 'Show the HUD', 'A small readout at the edge of the screen while you are working on a car.', true],
            ['hudRight', 'HUD on the right', 'Move it to the other side of the screen.', false],
            ['sounds', 'Sounds', 'Clicks and confirmations while using the tablet.', true],
            ['autoDraft', 'Build the invoice as I work', 'Every part fitted is added as a line automatically.', true],
        ]) {
            const current = settings[key] === undefined ? fallback : settings[key];

            toggles.append(XS.el('label', { class: 'check' }, [
                XS.el('input', { type: 'checkbox', checked: current, onchange: (ev) => save(key, ev.target.checked) }),
                XS.el('div', {}, [
                    XS.el('div', { class: 'cl', text: label }),
                    XS.el('div', { class: 'cs', text: note }),
                ]),
            ]));
        }

        grid.append(toggles);
        host.append(grid);
    };
})();
