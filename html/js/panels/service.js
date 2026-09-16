(function () {
    // A car with leader lines out to what is worn, rather than a table of
    // percentages. A mechanic glances at this and knows which corner of the car
    // to walk to.
    const SILHOUETTE = `
<svg viewBox="0 0 420 150" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
  <path d="M28 112c-5-20 2-32 12-37l56-9c16-19 40-29 76-30 37-1 66 7 89 22l58 11c18 4 28 15 29 32 1 9-3 15-11 16l-26 2c-3-18-15-27-30-27s-27 9-30 27H155c-3-18-15-27-30-27s-27 9-30 27l-62-1c-6 0-10-4-11-9Z"/>
  <path d="M116 66c14-15 35-23 61-25 27-1 49 6 67 18l-11 10-107 1z" opacity=".55"/>
  <circle cx="125" cy="113" r="26" opacity=".8"/><circle cx="125" cy="113" r="13" opacity=".5"/>
  <circle cx="281" cy="113" r="26" opacity=".8"/><circle cx="281" cy="113" r="13" opacity=".5"/>
</svg>`;

    XS.panels.service = function (host) {
        XS.clear(host);

        const car = XS.state.vehicle;
        const parts = car?.service?.parts || [];

        host.append(XS.el('aside', { class: 'tree' }, [
            XS.el('div', { class: 'grp', text: 'Servicing' }),
            XS.el('button', { class: 'tn on' }, [
                XS.el('span', { class: 'n', text: 'Inspection' }),
                XS.el('span', {
                    class: `b ${(car?.service?.due || 0) ? 'warn' : 'good'}`,
                    text: String(car?.service?.due || 0),
                }),
            ]),
        ]));

        const grid = XS.el('section', { class: 'grid' });

        if (!car) {
            grid.append(XS.empty('Nothing connected', 'Connect a vehicle to inspect it.'));
            host.append(grid);
            return;
        }

        if (!parts.length) {
            grid.append(XS.empty('Nothing to service',
                'Either servicing is switched off on this server, or this vehicle is on the blocked list.'));
            host.append(grid);
            return;
        }

        const due = parts.filter((p) => p.due).length;

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Servicing' }),
            XS.el('div', {
                class: 'cap',
                text: due ? `${due} due` : 'nothing due',
            }),
        ]));

        // Split down the middle so the car sits between two columns of cards,
        // the worst ones first on each side.
        const sorted = [...parts].sort((a, b) => a.wear - b.wear);
        const left = [];
        const right = [];

        sorted.forEach((part, index) => (index % 2 ? right : left).push(part));

        grid.append(XS.el('div', { class: 'diagram' }, [
            XS.el('div', { class: 'col left' }, left.map((p) => card(p, 'left'))),

            XS.el('div', { class: 'car' }, [
                XS.el('div', { class: 'art', html: SILHOUETTE }),
                XS.el('div', { class: 'nm', text: car.name || car.model || 'Vehicle' }),
                XS.el('div', { class: 'od', text: `${XS.num(car.odometer)} km` }),
            ]),

            XS.el('div', { class: 'col right' }, right.map((p) => card(p, 'right'))),
        ]));

        grid.append(XS.el('div', {
            style: 'margin-top:20px;font-size:12px;color:var(--faint);line-height:1.6;max-width:640px',
            text: 'Worn parts make the vehicle drive worse — slower to pull, longer to stop, less grip, slower shifts. Replacing one puts that part back to full.',
        }));

        host.append(grid);
    };

    function card(part, side) {
        const tone = part.wear <= 20 ? 't-bad' : part.wear <= 50 ? 't-warn' : '';

        return XS.el('div', { class: `sv ${side} ${part.due ? 'due' : ''}` }, [
            XS.el('div', { class: 'lead' }),
            XS.el('div', { class: 'in' }, [
                XS.el('div', { class: 'hd' }, [
                    XS.el('span', { class: 'k', text: part.label }),
                    XS.el('span', { class: `v ${tone}`, text: `${part.wear}%` }),
                ]),
                XS.track(part.wear, tone),
                XS.el('div', { class: 'ft' }, [
                    XS.el('span', { class: 'm', text: `${part.quantity}x · ${part.affects}` }),
                    XS.el('button', {
                        class: 'wr',
                        title: `Replace ${part.label}`,
                        html: '<svg viewBox="0 0 24 24"><path d="M9 5.5 5.5 9 4 7.5a4 4 0 0 0 5.4 5.4l6 6a2 2 0 0 0 2.8-2.8l-6-6A4 4 0 0 0 6.8 4.7z"/></svg>',
                        onclick: () => XS.post('replacePart', { part: part.id }),
                    }),
                ]),
            ]),
        ]);
    }
})();
