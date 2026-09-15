XS.hud = (function () {
    const node = document.getElementById('hud');
    const shopEl = node.querySelector('[data-hud-shop]');
    const plateEl = node.querySelector('[data-hud-plate]');
    const bodyEl = node.querySelector('[data-hud-body]');

    let data = null;

    function redraw() {
        const settings = XS.state.settings || {};

        if (!data || settings.hud === false) {
            node.hidden = true;
            return;
        }

        node.hidden = false;
        node.className = settings.hudRight ? 'right' : '';

        shopEl.textContent = data.shop || 'Mechanic';
        plateEl.textContent = data.plate || '';

        XS.clear(bodyEl);

        for (const row of data.rows || []) {
            bodyEl.append(XS.el('div', { class: 'hr' }, [
                XS.el('span', { class: 'k', text: row.k }),
                XS.el('span', {
                    class: 'v',
                    style: row.tone ? `color:var(--${row.tone})` : '',
                    text: row.v,
                }),
            ]));

            if (row.percent !== undefined && row.percent !== null) {
                bodyEl.append(XS.track(row.percent, row.track || ''));
            }
        }
    }

    return {
        set(next) { data = next; redraw(); },
        redraw,
    };
})();
