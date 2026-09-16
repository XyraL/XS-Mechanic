(function () {
    XS.panels.builder = function (host) {
        XS.clear(host);

        const shops = XS.state.shops || [];
        const draft = XS.state.draft;


        const grid = XS.el('section', { class: 'grid' });

        if (!draft) {
            grid.append(XS.empty('Pick a shop, or build one',
                'Nothing ships with this resource. Fly to the interior you want to use, drop the bays and the counters where they actually are, and save.'));
            host.append(grid);
            return;
        }

        renderDraft(grid, draft);
        host.append(grid);
    };

    const POINT_KINDS = [
        { kind: 'tuning', label: 'Tuning bay', note: 'Where a car gets worked on' },
        { kind: 'repair', label: 'Repair bay', note: 'Repairs, priced off the vehicle' },
        { kind: 'counter', label: 'Parts counter', note: 'What this shop sells' },
        { kind: 'storage', label: 'Storage', note: 'A stash for employees' },
        { kind: 'laptop', label: 'Office laptop', note: 'Billing, orders, staff and money' },
        { kind: 'desk', label: 'Customer desk', note: 'Where work orders get left' },
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
                    XS.el('div', { class: 'hint', text: 'This grade and above get the Team app and the shop money.' }),
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

            form.append(XS.el('label', { class: 'check' }, [
                XS.el('input', {
                    type: 'checkbox', checked: draft.selfServiceWhenEmpty !== false,
                    onchange: (ev) => set('selfServiceWhenEmpty', ev.target.checked),
                }),
                XS.el('div', {}, [
                    XS.el('div', { class: 'cl', text: 'Self service when nobody is on' }),
                    XS.el('div', { class: 'cs', text: 'Customers can use the bays themselves while no staff are online.' }),
                ]),
            ]));
        }

        grid.append(form);

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Points' }),
            XS.el('div', { class: 'cap', text: `${(draft.points || []).length} placed` }),
        ]));

        const add = XS.el('div', { class: 'cards', style: 'margin-bottom:16px' });

        for (const kind of POINT_KINDS) {
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
            const meta = POINT_KINDS.find((k) => k.kind === point.kind);

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
