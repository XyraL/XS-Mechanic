(function () {
    XS.panels.invoices = function (host) {
        XS.clear(host);

        const filter = XS.state.invoiceFilter || 'unpaid';
        const all = XS.state.invoices || [];

        const counts = {
            unpaid: all.filter((i) => i.status === 'sent').length,
            paid: all.filter((i) => i.status === 'paid').length,
            draft: all.filter((i) => i.status === 'draft').length,
        };

        const tree = XS.el('aside', { class: 'tree' }, [XS.el('div', { class: 'grp', text: 'Invoices' })]);

        for (const [id, label] of [['unpaid', 'Unpaid'], ['paid', 'Paid'], ['draft', 'Saved'], ['all', 'Everything']]) {
            tree.append(XS.el('button', {
                class: `tn ${filter === id ? 'on' : ''}`,
                onclick: () => { XS.state.invoiceFilter = id; XS.rerender('invoices'); },
            }, [
                XS.el('span', { class: 'n', text: label }),
                XS.el('span', {
                    class: `b ${id === 'unpaid' && counts.unpaid ? 'warn' : ''}`,
                    text: String(id === 'all' ? all.length : counts[id] || 0),
                }),
            ]));
        }

        host.append(tree);

        const grid = XS.el('section', { class: 'grid' });
        const shown = all.filter((i) => filter === 'all'
            || (filter === 'unpaid' && i.status === 'sent')
            || (filter === 'paid' && i.status === 'paid')
            || (filter === 'draft' && i.status === 'draft'));

        grid.append(XS.el('div', { class: 'gh' }, [
            XS.el('h2', { text: 'Invoices' }),
            XS.el('div', { class: 'cap', text: `${shown.length} shown · shared across the shop` }),
        ]));

        if (!shown.length) {
            grid.append(XS.empty('Nothing here',
                filter === 'unpaid' ? 'Every invoice has been settled.' : 'Nothing sent yet. Bill a work order and it lands here.'));
            host.append(grid);
            return;
        }

        const rows = XS.el('div', { class: 'rows' });

        for (const invoice of shown) {
            const tone = invoice.status === 'paid' ? 'f' : invoice.status === 'sent' ? 'w' : '';

            rows.append(XS.el('button', {
                class: 'row',
                onclick: () => showInvoice(invoice),
            }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 't', text: invoice.customerName || 'Unknown customer' }),
                    XS.el('div', {
                        class: 'm',
                        text: `#${invoice.id}${invoice.orderId ? ` · Order #${invoice.orderId}` : ''} · ${invoice.plate || '——'} · ${(invoice.items || []).length} line${(invoice.items || []).length === 1 ? '' : 's'} · ${XS.ago(invoice.createdAt)}`,
                    }),
                ]),
                XS.el('div', { class: 'acts' }, [
                    XS.el('span', { class: 'a', text: XS.money(invoice.total) }),
                    XS.el('span', { class: `st ${tone}`, text: invoice.status.toUpperCase() }),
                ]),
            ]));
        }

        grid.append(rows);
        host.append(grid);
    };

    function showInvoice(invoice) {
        const body = XS.el('div');

        for (const item of invoice.items || []) {
            body.append(XS.el('div', { class: 'ln', style: 'grid-template-columns:1fr auto;padding-left:0;padding-right:0' }, [
                XS.el('div', {}, [
                    XS.el('div', { class: 'd', text: item.label }),
                    XS.el('div', { class: 'm', text: item.note || item.category || '' }),
                ]),
                XS.el('div', { class: 'a', text: XS.money(item.amount) }),
            ]));
        }

        body.append(XS.el('div', { class: 'tr big', style: 'margin-top:16px' }, [
            XS.el('span', { text: 'TOTAL' }),
            XS.el('span', { text: XS.money(invoice.total) }),
        ]));

        XS.modal({
            title: `Invoice #${invoice.id}`,
            note: `${invoice.customerName || 'Unknown'} · ${invoice.plate || '——'} · written by ${invoice.mechanicName || 'a mechanic'}`,
            body,
            confirm: invoice.status === 'paid' ? false : 'Resend to customer',
            onConfirm: () => { XS.bill('resendInvoice', { id: invoice.id }); },
        });
    }
})();
