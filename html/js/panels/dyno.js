(function () {
    XS.panels.dyno = function (host) {
        XS.clear(host);

        const car = XS.state.vehicle;
        const run = XS.state.dyno;

        const grid = XS.el('section', { class: 'grid' });

        if (!car) {
            grid.append(XS.empty('Nothing connected', 'Put a vehicle on the dyno bay and connect to it.'));
            host.append(grid);
            return;
        }

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: `Dyno · ${car.name || car.model}` }),
            XS.el('div', {
                class: 'cap',
                text: run?.state === 'running' ? `running · ${run.progress || 0}%` : 'ready',
            }),
        ]));

        grid.append(chart(run));

        if (run?.state === 'done' && run.stats) {
            const stats = run.stats;

            grid.append(XS.el('div', { class: 'gh', style: 'margin-top:20px' }, [
                XS.el('h2', { text: 'Result' }),
                XS.el('div', { class: 'cap', text: 'from the handling and what is fitted' }),
            ]));

            const cards = XS.el('div', { class: 'cards' });

            for (const [label, value, unit] of [
                ['Power', XS.num(stats.hp), 'hp'],
                ['Torque', XS.num(stats.torque), 'lb-ft'],
                ['Top speed', XS.num(stats.topSpeed), 'mph'],
                ['Gears', String(stats.gears), ''],
                ['Weight', XS.num(stats.mass), 'kg'],
            ]) {
                cards.append(XS.el('div', { class: 'c' }, [
                    XS.el('div', { class: 'idx', text: label.toUpperCase() }),
                    XS.el('div', {
                        class: 'nm',
                        style: 'font:650 22px/1 var(--mono);letter-spacing:-.03em;margin-bottom:0',
                    }, [
                        value,
                        unit ? XS.el('span', { style: 'font-size:11px;color:var(--faint);margin-left:4px', text: unit }) : null,
                    ]),
                ]));
            }

            grid.append(cards);
        }

        grid.append(XS.el('div', { style: 'display:flex;gap:9px;margin-top:22px' }, [
            XS.el('button', {
                class: 'mini hot',
                text: run?.state === 'running' ? 'Stop' : 'Run the dyno',
                // Spelled out so both endpoints stay greppable.
                onclick: () => {
                    if (run?.state === 'running') XS.post('stopDyno');
                    else XS.post('runDyno');
                },
            }),
            run?.state === 'done'
                ? XS.el('button', { class: 'mini', text: 'Show the customer', onclick: () => XS.post('shareDyno') })
                : null,
        ]));

        host.append(grid);
    };

    // Hand-drawn SVG rather than a charting library — it is one line on a grid
    // and the resource has no dependencies to spend on it.
    function chart(run) {
        const W = 900;
        const H = 300;
        const PAD = 34;

        const points = run?.points || [];
        const peak = Math.max(run?.peak || 0, ...points.map((p) => p.hp), 1);

        const svg = [`<svg viewBox="0 0 ${W} ${H}" style="width:100%;height:auto;display:block">`];

        svg.push(`<rect x="0" y="0" width="${W}" height="${H}" fill="var(--panel)" rx="10"/>`);

        for (let i = 0; i <= 4; i++) {
            const y = PAD + ((H - PAD * 2) * (i / 4));
            svg.push(`<line x1="${PAD}" y1="${y}" x2="${W - PAD}" y2="${y}" stroke="var(--line)" stroke-width="1"/>`);
            svg.push(`<text x="${PAD - 8}" y="${y + 4}" fill="var(--faint)" font-size="10" font-family="ui-monospace,monospace" text-anchor="end">${Math.round(peak * (1 - i / 4))}</text>`);
        }

        for (let i = 0; i <= 7; i++) {
            const x = PAD + ((W - PAD * 2) * (i / 7));
            svg.push(`<line x1="${x}" y1="${PAD}" x2="${x}" y2="${H - PAD}" stroke="var(--line)" stroke-width="1" opacity="0.5"/>`);
            svg.push(`<text x="${x}" y="${H - PAD + 16}" fill="var(--faint)" font-size="10" font-family="ui-monospace,monospace" text-anchor="middle">${i + 1}k</text>`);
        }

        if (points.length > 1) {
            const coords = points.map((p, i) => {
                const x = PAD + ((W - PAD * 2) * (i / Math.max(points.length - 1, 1)));
                const y = (H - PAD) - ((H - PAD * 2) * (p.hp / peak));
                return `${x.toFixed(1)},${y.toFixed(1)}`;
            });

            const torque = points.map((p, i) => {
                const x = PAD + ((W - PAD * 2) * (i / Math.max(points.length - 1, 1)));
                const y = (H - PAD) - ((H - PAD * 2) * (p.torque / Math.max(peak * 1.3, 1)));
                return `${x.toFixed(1)},${y.toFixed(1)}`;
            });

            svg.push(`<polyline points="${torque.join(' ')}" fill="none" stroke="var(--cool)" stroke-width="2" stroke-opacity="0.65" stroke-linejoin="round"/>`);
            svg.push(`<polyline points="${coords.join(' ')}" fill="none" stroke="var(--accent)" stroke-width="2.5" stroke-linejoin="round"/>`);

            const last = coords[coords.length - 1].split(',');
            svg.push(`<circle cx="${last[0]}" cy="${last[1]}" r="4" fill="var(--accent)"/>`);
        } else {
            svg.push(`<text x="${W / 2}" y="${H / 2}" fill="var(--faint)" font-size="13" text-anchor="middle">Nothing recorded yet</text>`);
        }

        svg.push(`<text x="${W - PAD}" y="${PAD - 12}" fill="var(--accent)" font-size="11" font-family="ui-monospace,monospace" text-anchor="end">HP</text>`);
        svg.push(`<text x="${W - PAD - 34}" y="${PAD - 12}" fill="var(--cool)" font-size="11" font-family="ui-monospace,monospace" text-anchor="end">TORQUE</text>`);
        svg.push('</svg>');

        return XS.el('div', { html: svg.join('') });
    }
})();
