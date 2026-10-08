(function () {
    XS.panels.repairs = function (host) {
        XS.clear(host);

        const car = XS.state.vehicle;
        const staff = XS.mode !== 'bay';

        // A service station: free, and only what it was set up to do.
        const station = XS.mode === 'station';
        const offers = XS.state.offers || {};
        const canRepair = !station || offers.repair;
        const canWash = !station || offers.wash;

        host.append(XS.el('aside', { class: 'tree' }, [
            XS.el('div', { class: 'grp', text: 'Work' }),
            XS.el('button', { class: 'tn on' }, [XS.el('span', { class: 'n', text: 'Repairs' })]),
            staff && canWash
                ? XS.el('button', { class: 'tn', onclick: () => XS.post('openWash') }, [
                    XS.el('span', { class: 'n', text: 'Wash' }),
                ])
                : null,
        ]));

        const grid = XS.el('section', { class: 'grid' });

        if (!car) {
            grid.append(XS.empty('Nothing connected', XS.mode === 'bay'
                ? 'Drive a vehicle into the bay.'
                : 'Connect a vehicle before repairing it.'));
            host.append(grid);
            return;
        }

        const engine = Math.round((car.health?.engine || 0) / 10);
        const body = Math.round((car.health?.body || 0) / 10);
        const price = (XS.state.prices || {}).repair || 0;
        const clean = engine >= 99 && body >= 99;

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Damage' }),
            XS.el('div', { class: 'cap', text: clean ? 'nothing wrong with it' : verdict(engine, body) }),
        ]));

        const cards = XS.el('div', { class: 'cards' });

        cards.append(condition('ENGINE', engine, 'Runs badly, overheats, cuts out.'));
        cards.append(condition('BODY', body, 'Panels, glass, lights and the doors.'));

        grid.append(cards);

        // A customer can see what is wrong with their car and ask for it to be
        // sorted. They do not get to fix it themselves — that is the job.
        if (!staff) {
            const asked = (XS.state.basket || []).some((p) => p.slotId === 'repair');

            grid.append(XS.el('div', { class: 'gh', style: 'margin-top:24px' }, [
                XS.el('h2', { text: 'Want it sorted?' }),
                XS.el('div', { class: 'cap', text: 'goes on the same order' }),
            ]));

            grid.append(XS.el('div', { class: `zone ${asked ? 'on' : ''}` }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 't', text: asked ? 'A repair is on your order' : 'Put a repair on the order' }),
                    XS.el('div', {
                        class: 'm',
                        text: clean
                            ? 'There is nothing to put right. Come back when you have hit something.'
                            : 'The shop puts the engine and the bodywork back to how they left the factory.',
                    }),
                ]),
                XS.el('div', { class: 'acts' }, [
                    asked
                        ? XS.el('button', {
                            class: 'mini danger', text: 'Take it off',
                            onclick: () => XS.post('pickPart', { remove: true, slotId: 'repair' }),
                        })
                        : XS.el('button', {
                            class: 'mini hot', text: `Add repair · ${XS.money(price)}`,
                            disabled: clean,
                            onclick: () => XS.post('pickPart', {
                                plain: true, slotId: 'repair', category: 'repair', label: 'Full repair',
                            }),
                        }),
                ]),
            ]));

            host.append(grid);
            return;
        }

        grid.append(XS.el('div', { style: 'display:flex;gap:9px;margin-top:24px' }, [
            canRepair ? XS.el('button', {
                class: 'mini hot',
                text: clean ? 'Nothing to repair' : station ? 'Repair it' : `Repair it · ${XS.money(price)}`,
                disabled: clean,
                onclick: () => XS.post('repair', { how: 'bay' }),
            }) : null,
            station && canWash ? XS.el('button', {
                class: 'mini', text: 'Wash it',
                onclick: () => XS.post('openWash'),
            }) : null,
        ]));

        host.append(grid);
    };

    function verdict(engine, body) {
        const worst = Math.min(engine, body);
        if (worst < 25) return 'in a state';
        if (worst < 55) return 'needs work';
        if (worst < 90) return 'a few marks';
        return 'nearly right';
    }

    function condition(label, percent, note) {
        const tone = percent < 40 ? 't-bad' : percent < 70 ? 't-warn' : '';

        return XS.el('div', { class: 'c' }, [
            XS.el('div', { class: 'idx', text: label }),
            XS.el('div', { class: 'nm', style: 'font:650 21px/1 var(--mono);margin-bottom:11px', text: `${percent}%` }),
            XS.track(percent, tone),
            XS.el('div', {
                style: 'font-size:11px;color:var(--faint);line-height:1.45;margin-top:11px',
                text: note,
            }),
        ]);
    }
})();
