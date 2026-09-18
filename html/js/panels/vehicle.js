(function () {
    XS.panels.vehicle = function (host) {
        XS.clear(host);

        const grid = XS.el('section', { class: 'grid' });
        const car = XS.state.vehicle;

        if (!car) {
            grid.append(XS.empty('Nothing connected',
                'Stand next to a vehicle and connect it. Everything the tablet does needs a car in front of it.'));

            grid.append(XS.el('div', { style: 'display:grid;place-items:center;margin-top:16px' }, [
                XS.el('button', { class: 'mini hot', text: 'Connect nearest vehicle', onclick: () => XS.post('connect') }),
            ]));

            host.append(grid);
            return;
        }

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Identity' }),
            XS.el('div', { class: 'cap', text: car.model }),
        ]));

        const idCards = XS.el('div', { class: 'cards' });

        for (const pair of [
            ['Plate', car.plate || '——'],
            ['Model', car.name || car.model],
            ['Class', car.className || '—'],
            ['Drivetrain', car.drive || '—'],
            ['Fuel', car.electric ? 'Electric' : 'Petrol'],
            ['Owner', car.owner || 'Unregistered'],
        ]) {
            idCards.append(XS.el('div', { class: 'c' }, [
                XS.el('div', { class: 'idx', text: pair[0].toUpperCase() }),
                XS.el('div', { class: 'nm', text: String(pair[1]) }),
            ]));
        }

        grid.append(idCards);

        grid.append(XS.el('div', { class: 'gh', style: 'margin-top:22px' }, [
            XS.el('h2', { text: 'Condition' }),
            XS.el('div', { class: 'cap', text: 'live from the vehicle' }),
        ]));

        const health = XS.el('div', { class: 'cards' });
        const engine = Math.round((car.health?.engine || 0) / 10);
        const body = Math.round((car.health?.body || 0) / 10);
        const tank = Math.round((car.health?.petrolTank || 0) / 10);
        const dirt = Math.round((car.health?.dirt || 0) / 15 * 100);

        for (const item of [
            { k: 'Engine', v: engine, tone: engine < 40 ? 't-bad' : engine < 70 ? 't-warn' : '' },
            { k: 'Body', v: body, tone: body < 40 ? 't-bad' : body < 70 ? 't-warn' : '' },
            { k: 'Fuel tank', v: tank, tone: tank < 40 ? 't-bad' : '' },
            { k: 'Cleanliness', v: 100 - dirt, tone: dirt > 60 ? 't-warn' : '' },
        ]) {
            health.append(XS.el('div', { class: 'c' }, [
                XS.el('div', { class: 'idx', text: item.k.toUpperCase() }),
                XS.el('div', { class: 'nm', style: 'font:650 21px/1 var(--mono);margin-bottom:11px', text: `${item.v}%` }),
                XS.track(item.v, item.tone),
            ]));
        }

        grid.append(health);

        const fitted = (XS.state.catalogue?.slots || []).filter((s) => s.current !== -1);

        // A handling package is not a mod slot — it changes how the car
        // drives and nothing the catalogue can see. Reading only the slots is
        // why a car with a V8 in it still reported as completely stock.
        const packages = [];

        for (const category of XS.state.vehicle?.tuning || []) {
            const option = (category.options || []).find((o) => o.fitted);
            if (option) packages.push({ category, option });
        }

        const count = fitted.length + packages.length;

        grid.append(XS.el('div', { class: 'gh', style: 'margin-top:22px' }, [
            XS.el('h2', { text: 'Fitted' }),
            XS.el('div', { class: 'cap', text: `${count} non-stock part${count === 1 ? '' : 's'}` }),
        ]));

        if (!count) {
            grid.append(XS.empty('Completely stock', 'Nothing has been changed on this vehicle.'));
        } else {
            const rows = XS.el('div', { class: 'rows' });

            for (const { category, option } of packages) {
                rows.append(XS.el('div', { class: 'row' }, [
                    XS.el('div', {}, [
                        XS.el('div', { class: 't', text: option.name }),
                        XS.el('div', { class: 'm', text: `tuning · ${category.label}` }),
                    ]),
                    XS.el('span', { class: 'st f', text: 'PACKAGE' }),
                ]));
            }

            for (const slot of fitted) {
                const option = (slot.options || []).find((o) => o.index === slot.current);

                rows.append(XS.el('div', { class: 'row' }, [
                    XS.el('div', {}, [
                        XS.el('div', { class: 't', text: option?.label || `Index ${slot.current}` }),
                        XS.el('div', { class: 'm', text: `${slot.category} · ${slot.label}` }),
                    ]),
                    XS.el('span', { class: 'st f', text: `IDX ${slot.current}` }),
                ]));
            }

            grid.append(rows);
        }

        host.append(grid);
    };
})();
