(function () {
    // How many of each part to make. Kept out of XS.state so a refresh from
    // the server does not reset what somebody was in the middle of setting.
    const amounts = {};

    XS.panels.craft = function (host) {
        XS.clear(host);

        const recipes = XS.state.crafting || [];

        if (!recipes.length) {
            const empty = XS.el('section', { class: 'grid' });
            empty.append(XS.empty('Nothing to make here', 'No recipes are set up on this server.'));
            host.append(empty);
            return;
        }

        // Twenty-odd recipes is a wall of cards. They come grouped so the bench
        // reads as a workshop rather than a list.
        const groups = [];

        for (const recipe of recipes) {
            const name = recipe.group || 'Parts';
            let group = groups.find((g) => g.name === name);

            if (!group) { group = { name, recipes: [] }; groups.push(group); }

            group.recipes.push(recipe);
        }

        if (!groups.some((g) => g.name === XS.state.craftGroup)) {
            XS.state.craftGroup = groups[0].name;
        }

        const tree = XS.el('aside', { class: 'tree' }, [XS.el('div', { class: 'grp', text: 'Bench' })]);

        for (const group of groups) {
            const ready = group.recipes.filter((r) => r.canMake).length;

            tree.append(XS.el('button', {
                class: `tn ${XS.state.craftGroup === group.name ? 'on' : ''}`,
                onclick: () => { XS.state.craftGroup = group.name; XS.panels.craft(host); },
            }, [
                XS.el('span', { class: 'n', text: group.name }),
                XS.el('span', { class: `b ${ready ? 'good' : ''}`, text: `${ready}/${group.recipes.length}` }),
            ]));
        }

        host.append(tree);

        const shown = groups.find((g) => g.name === XS.state.craftGroup);
        const grid = XS.el('section', { class: 'grid' });

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: shown.name }),
            XS.el('div', {
                class: 'cap',
                text: XS.state.stock?.shelf ? 'material off the shelf, part back on it' : 'material out of your pockets',
            }),
        ]));

        grid.append(materials(recipes));

        const cards = XS.el('div', { class: 'recipes' });

        for (const recipe of shown.recipes) cards.append(card(recipe));

        grid.append(cards);
        host.append(grid);
    };

    // What raw material the shop has, across the top. It is the first thing
    // anyone walking up to the bench wants to know.
    function materials(recipes) {
        const held = new Map();

        for (const recipe of recipes) {
            for (const need of recipe.needs) {
                if (!held.has(need.key)) held.set(need.key, { label: need.label, have: need.have });
            }
        }

        const bar = XS.el('div', { class: 'stockbar' });

        for (const [key, entry] of held) {
            bar.append(XS.el('div', { class: `mat ${entry.have ? '' : 'out'}`, 'data-mat': key }, [
                XS.el('span', { class: 'dot' }),
                XS.el('div', {}, [
                    XS.el('div', { class: 'k', text: entry.label }),
                    XS.el('div', { class: 'n', text: XS.num(entry.have) }),
                ]),
            ]));
        }

        return bar;
    }

    function card(recipe) {
        const amount = amounts[recipe.item] || 1;
        const enough = recipe.needs.every((need) => need.have >= need.need * amount);

        const node = XS.el('div', { class: `rc ${enough ? '' : 'short'}` });

        node.append(XS.el('div', { class: 'rh' }, [
            XS.el('div', {}, [
                XS.el('div', { class: 'nm', text: recipe.label }),
                XS.el('div', { class: 'ct', text: recipe.category ? `used for ${recipe.category}` : 'supplies' }),
            ]),
            XS.el('div', { class: `shelf ${recipe.onShelf ? '' : 'none'}` }, [
                XS.el('span', { class: 'n', text: XS.num(recipe.onShelf) }),
                XS.el('span', { class: 'k', text: 'in stock' }),
            ]),
        ]));

        const needs = XS.el('div', { class: 'needs' });

        for (const need of recipe.needs) {
            const want = need.need * amount;
            const ok = need.have >= want;

            needs.append(XS.el('div', { class: `nd ${ok ? '' : 'no'}` }, [
                XS.el('span', { class: 'l', text: need.label }),
                XS.el('span', { class: 'v', text: `${XS.num(need.have)} / ${XS.num(want)}` }),
                XS.track(want > 0 ? Math.min(100, (need.have / want) * 100) : 100, ok ? '' : 't-bad'),
            ]));
        }

        node.append(needs);

        node.append(XS.el('div', { class: 'ra' }, [
            XS.el('div', { class: 'qty' }, [
                XS.el('button', { text: '−', title: 'Fewer', onclick: () => step(recipe.item, -1) }),
                XS.el('span', { text: String(amount) }),
                XS.el('button', { text: '+', title: 'More', onclick: () => step(recipe.item, 1) }),
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
