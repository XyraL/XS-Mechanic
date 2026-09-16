(function () {
    // How many of each part to make. Kept out of XS.state so a refresh from
    // the server does not reset what somebody was in the middle of typing.
    const amounts = {};

    XS.panels.craft = function (host) {
        XS.clear(host);

        const recipes = XS.state.crafting || [];
        const grid = XS.el('section', { class: 'grid' });

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Bench' }),
            XS.el('div', { class: 'cap', text: 'material from your pockets, part onto the shelf' }),
        ]));

        if (!recipes.length) {
            grid.append(XS.empty('Nothing to make here', 'No recipes are set up on this server.'));
            host.append(grid);
            return;
        }

        const cards = XS.el('div', { class: 'recipes' });

        for (const recipe of recipes) cards.append(card(recipe));

        grid.append(cards);
        host.append(grid);
    };

    function card(recipe) {
        const amount = amounts[recipe.item] || 1;
        const enough = recipe.needs.every((need) => need.have >= need.need * amount);

        const node = XS.el('div', { class: `rc ${enough ? '' : 'short'}` });

        node.append(XS.el('div', { class: 'rh' }, [
            XS.el('div', {}, [
                XS.el('div', { class: 'nm', text: recipe.label }),
                XS.el('div', { class: 'ct', text: recipe.category ? `for ${recipe.category}` : 'supplies' }),
            ]),
            XS.el('div', { class: 'shelf' }, [
                XS.el('span', { class: 'n', text: XS.num(recipe.onShelf) }),
                XS.el('span', { class: 'k', text: 'on the shelf' }),
            ]),
        ]));

        const needs = XS.el('div', { class: 'needs' });

        for (const need of recipe.needs) {
            const want = need.need * amount;
            const ok = need.have >= want;

            needs.append(XS.el('div', { class: `nd ${ok ? '' : 'no'}` }, [
                XS.el('span', { class: 'l', text: need.label }),
                XS.el('span', { class: 'v', text: `${XS.num(need.have)} / ${XS.num(want)}` }),
                XS.track(Math.min(100, want > 0 ? (need.have / want) * 100 : 100), ok ? 't-cool' : 't-bad'),
            ]));
        }

        node.append(needs);

        node.append(XS.el('div', { class: 'ra' }, [
            XS.el('div', { class: 'qty' }, [
                XS.el('button', {
                    text: '−', title: 'Fewer',
                    onclick: () => step(recipe.item, -1),
                }),
                XS.el('span', { text: String(amount) }),
                XS.el('button', {
                    text: '+', title: 'More',
                    onclick: () => step(recipe.item, 1),
                }),
            ]),
            XS.el('button', {
                class: 'go',
                text: enough ? `Make ${amount > 1 ? `${amount} ` : ''}${recipe.label}` : 'Not enough material',
                disabled: !enough,
                onclick: () => XS.post('craft', { item: recipe.item, amount }),
            }),
        ]));

        return node;
    }

    function step(item, by) {
        amounts[item] = Math.max(1, Math.min(10, (amounts[item] || 1) + by));
        XS.panels.craft(document.querySelector('[data-panel="craft"]'));
    }
})();
