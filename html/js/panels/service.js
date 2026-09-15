(function () {
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

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Inspection sheet' }),
            XS.el('div', { class: 'cap', text: `${XS.num(car.odometer)} km on the clock` }),
        ]));

        const rows = XS.el('div', { class: 'rows' });

        for (const part of parts) {
            const tone = part.wear <= 20 ? 't-bad' : part.wear <= 50 ? 't-warn' : '';

            rows.append(XS.el('div', { class: 'row', style: 'grid-template-columns:1fr 200px auto' }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 't', text: part.label }),
                    XS.el('div', {
                        class: 'm',
                        text: `${part.lifespanKm} km life · affects ${part.affects} · ${part.quantity}x ${part.item}`,
                    }),
                ]),
                XS.el('div', {}, [
                    XS.el('div', {
                        style: `font:600 13px/1 var(--mono);text-align:right;margin-bottom:8px;${part.due ? 'color:var(--bad)' : ''}`,
                        text: `${part.wear}%`,
                    }),
                    XS.track(part.wear, tone),
                ]),
                XS.el('div', { class: 'acts' }, [
                    part.due ? XS.el('span', { class: 'st b', text: 'DUE' }) : null,
                    XS.el('button', {
                        class: `mini ${part.due ? 'hot' : ''}`,
                        text: 'Replace',
                        onclick: () => XS.post('replacePart', { part: part.id }),
                    }),
                ]),
            ]));
        }

        grid.append(rows);

        grid.append(XS.el('div', {
            style: 'margin-top:18px;font-size:12px;color:var(--faint);line-height:1.6;max-width:640px',
            text: 'Worn parts make the vehicle drive worse — slower to pull, longer to stop, less grip, slower shifts. Replacing one puts that part back to full.',
        }));

        host.append(grid);
    };
})();
