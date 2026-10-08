(function () {
    XS.panels.builder = function (host) {
        XS.clear(host);

        const shops = XS.state.shops || [];
        const draft = XS.state.draft;


        const grid = XS.el('section', { class: 'grid' });

        if (!draft) {
            grid.append(XS.empty('Pick a shop, or build one',
                'Nothing ships with this resource. Fly to the interior you want to use, drop the bays and the bench where they actually are, and save.'));
            host.append(grid);
            return;
        }

        renderDraft(grid, draft);
        host.append(grid);
    };

    const POINT_KINDS = [
        { kind: 'tuning', label: 'Tuning bay', note: 'Where a car gets worked on' },
        { kind: 'repair', label: 'Repair bay', note: 'Repairs, priced off the vehicle' },
        { kind: 'storage', label: 'Storage', note: 'A stash for employees' },
        { kind: 'laptop', label: 'Office laptop', note: 'Billing, staff and money' },
        { kind: 'bench', label: 'Crafting bench', note: 'Where parts get made' },
        { kind: 'dyno', label: 'Dyno bay', note: 'Where a run is done' },
        { kind: 'duty', label: 'Duty point', note: 'Toggles on and off duty' },
    ];

    function renderDraft(grid, draft) {
        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: draft.id ? draft.name : 'New shop' }),
            XS.el('div', { class: 'cap', text: draft.id ? `#${draft.id}` : 'not saved yet' }),
        ]));

        const set = (key, value) => XS.post('draftSet', { key, value });

        const form = XS.el('div', { style: 'max-width:560px;margin-bottom:22px' });

        form.append(XS.el('div', { class: 'field' }, [
            XS.el('label', { text: 'Shop name' }),
            XS.el('input', { type: 'text', value: draft.name || '', onchange: (ev) => set('name', ev.target.value) }),
        ]));

        form.append(XS.el('div', { class: 'split' }, [
            XS.el('div', { class: 'field' }, [
                XS.el('label', { text: 'Type' }),
                XS.el('select', { onchange: (ev) => set('kind', ev.target.value) }, [
                    XS.el('option', { value: 'owned', selected: draft.kind === 'owned', text: 'Owned — runs off a job' }),
                    XS.el('option', { value: 'self', selected: draft.kind === 'self', text: 'Self service — anyone' }),
                    XS.el('option', { value: 'station', selected: draft.kind === 'station', text: 'Service station — free, for chosen jobs' }),
                ]),
            ]),
            draft.kind === 'owned' ? XS.el('div', { class: 'field' }, [
                XS.el('label', { text: 'Job' }),
                jobPicker(draft, set),
                draft.jobMissing
                    ? XS.el('div', { class: 'hint', style: 'color:var(--warn)', text: 'Your framework does not have a job by that name. Create it first, or the shop will have no staff.' })
                    : XS.el('div', { class: 'hint', text: 'Whoever holds this job works here. Give it to the person who owns the interior.' }),
            ]) : null,
        ]));

        if (draft.kind === 'owned') {
            form.append(XS.el('div', { class: 'split' }, [
                XS.el('div', { class: 'field' }, [
                    XS.el('label', { text: 'Boss grade' }),
                    XS.el('input', {
                        type: 'number', value: String(draft.bossGrade ?? 3), min: '0',
                        onchange: (ev) => set('bossGrade', Number(ev.target.value) || 0),
                    }),
                    XS.el('div', { class: 'hint', text: bossHint(draft) }),
                ]),
                XS.el('div', { class: 'field' }, [
                    XS.el('label', { text: 'Commission %' }),
                    XS.el('input', {
                        type: 'number', value: String(draft.commission ?? 10), min: '0', max: '100',
                        onchange: (ev) => set('commission', Number(ev.target.value) || 0),
                    }),
                    XS.el('div', { class: 'hint', text: 'Share of a paid invoice that goes to the mechanic who wrote it.' }),
                ]),
            ]));

            form.append(XS.el('div', { class: 'field' }, [
                XS.el('label', { text: 'Pricing grade' }),
                XS.el('input', {
                    type: 'number', value: String(draft.priceGrade ?? 2), min: '0',
                    onchange: (ev) => set('priceGrade', Number(ev.target.value) || 0),
                }),
                XS.el('div', { class: 'hint', text: 'This grade and above can change what the shop charges. The boss always can.' }),
            ]));

        }

        if (draft.kind === 'station') form.append(stationFields(draft, set));

        grid.append(form);

        if (draft.kind !== 'station') grid.append(boundary(draft));

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Points' }),
            XS.el('div', { class: 'cap', text: `${(draft.points || []).length} placed` }),
        ]));

        const add = XS.el('div', { class: 'cards', style: 'margin-bottom:16px' });

        for (const kind of draft.kind === 'station' ? [STATION_POINT] : POINT_KINDS) {
            add.append(XS.el('button', {
                class: 'c',
                onclick: () => XS.post('placePoint', { kind: kind.kind }),
            }, [
                XS.el('div', { class: 'idx', text: 'PLACE' }),
                XS.el('div', { class: 'nm', text: kind.label }),
                XS.el('div', { class: 'fr' }, [XS.el('span', { class: 'pr', style: 'font-size:11px', text: kind.note })]),
            ]));
        }

        grid.append(add);

        const list = XS.el('div', { class: 'pointlist' });

        for (const point of draft.points || []) {
            const meta = [...POINT_KINDS, STATION_POINT].find((k) => k.kind === point.kind);

            list.append(XS.el('div', { class: 'point' }, [
                XS.el('span', { class: 'kind' }),
                XS.el('div', {}, [
                    XS.el('div', { class: 't', text: point.label || meta?.label || point.kind }),
                    XS.el('div', {
                        class: 'm',
                        text: `${meta?.label || point.kind} · ${fmt(point.coords)} · r${(point.radius || 3).toFixed(1)}`,
                    }),
                ]),
                XS.el('div', { class: 'acts' }, [
                    XS.el('button', { class: 'mini', text: 'Move', onclick: () => XS.post('movePoint', { id: point.id }) }),
                    XS.el('button', { class: 'mini danger', text: 'Remove', onclick: () => XS.post('dropPoint', { id: point.id }) }),
                ]),
            ]));
        }

        if (!(draft.points || []).length) {
            list.append(XS.empty('Nothing placed yet', 'A shop with no points does nothing. Start with a tuning bay.'));
        }

        grid.append(list);

        grid.append(XS.el('div', { style: 'display:flex;gap:9px;margin-top:22px;position:sticky;bottom:0;padding:14px 0;background:linear-gradient(transparent,var(--bg) 26%)' }, [
            XS.el('button', { class: 'mini hot', text: draft.id ? 'Save changes' : 'Create shop', onclick: () => XS.post('saveShop') }),
            XS.el('button', { class: 'mini', text: draft.enabled === false ? 'Switch on' : 'Switch off', onclick: () => XS.post('toggleShop') }),
            XS.el('button', { class: 'mini', text: 'Discard', onclick: () => XS.post('discardDraft') }),
            draft.id ? XS.el('button', {
                class: 'mini danger', text: 'Delete shop',
                onclick: () => XS.modal({
                    title: `Delete ${draft.name}?`,
                    note: 'Every point, price and setting goes with it. Invoices already written are kept.',
                    confirm: 'Delete', danger: true,
                    onConfirm: () => XS.post('deleteShop'),
                }),
            }) : null,
        ]));
    }

    // Without a boundary the tablet connects to a car anywhere on the map. The
    // shape drawn here is what "at the shop" means, and it is checked on the
    // server as well as in the panel.
    // A service station: who can drive in, and what it does for them.
    const STATION_POINT = { kind: 'station', label: 'Service bay', note: 'Drive in and set the car up' };

    const OFFERS = [
        ['repair', 'Repair'], ['wash', 'Wash'], ['paint', 'Paint'], ['parts', 'Body parts'],
        ['wheels', 'Wheels'], ['performance', 'Performance'], ['stance', 'Stance'],
    ];

    function stationFields(draft, set) {
        const wrap = XS.el('div');
        const jobs = draft.jobs || [];
        const chosen = draft.stationJobs || [];

        const toggle = (name) => set('stationJobs',
            chosen.includes(name) ? chosen.filter((j) => j !== name) : [...chosen, name]);

        const picker = XS.el('div', { class: 'chips' });

        for (const job of jobs) {
            picker.append(XS.el('button', {
                class: `tn ${chosen.includes(job.name) ? 'on' : ''}`,
                onclick: () => toggle(job.name),
            }, [XS.el('span', { class: 'n', text: job.label })]));
        }

        // Saved against a job the framework no longer has: still shown, still removable.
        for (const name of chosen) {
            if (!jobs.some((j) => j.name === name)) {
                picker.append(XS.el('button', { class: 'tn on', onclick: () => toggle(name) }, [
                    XS.el('span', { class: 'n', text: name }),
                ]));
            }
        }

        wrap.append(XS.el('div', { class: 'field' }, [
            XS.el('label', { text: 'Jobs that can use it' }),
            jobs.length
                ? picker
                : XS.el('input', {
                    type: 'text', value: chosen.join(', '), placeholder: 'police, ambulance',
                    onchange: (ev) => set('stationJobs', ev.target.value.split(',').map((j) => j.trim()).filter(Boolean)),
                }),
            XS.el('div', { class: 'hint', text: 'Anyone with one of these jobs can drive onto a service bay and use it.' }),
        ]));

        const offers = draft.offers || {};
        const does = XS.el('div', { class: 'chips' });

        for (const [key, label] of OFFERS) {
            const on = offers[key] !== false;

            does.append(XS.el('button', {
                class: `tn ${on ? 'on' : ''}`,
                onclick: () => set('offers', Object.assign({}, offers, { [key]: !on })),
            }, [XS.el('span', { class: 'n', text: label })]));
        }

        wrap.append(XS.el('div', { class: 'field' }, [
            XS.el('label', { text: 'What it does' }),
            does,
            XS.el('div', { class: 'hint', text: 'Free. Nothing is charged and nothing goes on a work order.' }),
        ]));

        return wrap;
    }

    function boundary(draft) {
        const corners = draft.area?.points || [];
        const wrap = XS.el('div', { style: 'margin-bottom:22px' });

        wrap.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Boundary' }),
            XS.el('div', {
                class: 'cap',
                text: corners.length ? `${corners.length} corners` : 'not drawn',
            }),
        ]));

        wrap.append(XS.el('div', { class: `zone ${corners.length ? 'on' : ''}` }, [
            XS.el('div', {}, [
                XS.el('div', { class: 't', text: corners.length ? 'The shop is fenced off' : 'This shop has no boundary' }),
                XS.el('div', {
                    class: 'm',
                    text: corners.length
                        ? 'Mechanics can only work on a vehicle inside this shape, and they have to be inside it too.'
                        : 'Anyone with the job can connect to a car anywhere on the map. Draw the walls of the workshop and that stops.',
                }),
            ]),
            XS.el('div', { class: 'acts' }, [
                XS.el('button', {
                    class: 'mini hot',
                    text: corners.length ? 'Draw it again' : 'Draw the boundary',
                    onclick: () => XS.post('drawArea'),
                }),
                corners.length ? XS.el('button', {
                    class: 'mini danger', text: 'Clear',
                    onclick: () => XS.post('clearArea'),
                }) : null,
            ]),
        ]));

        return wrap;
    }

    // What the boss grade means for the job picked. Custom jobs often stop short
    // of the default of 3, so the hint says how high this one goes.
    function bossHint(draft) {
        const base = 'This grade and above get the Team app and the shop money.';
        const job = (draft.jobs || []).find((j) => j.name === draft.job);

        if (!job || typeof job.top !== 'number') return base;

        const want = draft.bossGrade ?? 3;

        return want > job.top
            ? `${base} ${job.label} only goes up to grade ${job.top}, so grade ${job.top} counts as boss.`
            : `${base} ${job.label} goes up to grade ${job.top}.`;
    }

    // A dropdown of the framework's real jobs, so nobody has to remember how a
    // job name was spelled. A framework that exposes no list falls back to the
    // text box rather than leaving you with nothing to pick.
    function jobPicker(draft, set) {
        const jobs = draft.jobs || [];

        if (!jobs.length) {
            return XS.el('input', {
                type: 'text', value: draft.job || '',
                placeholder: 'mechanic',
                onchange: (ev) => set('job', ev.target.value.trim()),
            });
        }

        const select = XS.el('select', {
            onchange: (ev) => set('job', ev.target.value),
        });

        select.append(XS.el('option', {
            value: '', selected: !draft.job, text: 'Pick a job…',
        }));

        let known = false;

        for (const job of jobs) {
            if (job.name === draft.job) known = true;

            select.append(XS.el('option', {
                value: job.name,
                selected: job.name === draft.job,
                text: `${job.label} — ${job.name}`,
            }));
        }

        // A shop saved against a job that has since been removed still has to
        // show what it points at, rather than silently reading as unset.
        if (draft.job && !known) {
            select.append(XS.el('option', {
                value: draft.job, selected: true, text: `${draft.job} — missing`,
            }));
        }

        return select;
    }

    function fmt(coords) {
        if (!coords) return '—';
        return `${(coords.x || 0).toFixed(1)}, ${(coords.y || 0).toFixed(1)}, ${(coords.z || 0).toFixed(1)}`;
    }
})();
