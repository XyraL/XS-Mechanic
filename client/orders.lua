Orders = {}

Team = {}

-- Hiring needs a person stood in front of you, not a name typed into a box.
function Team.NearestPlayer()
    local me = cache.ped
    local coords = GetEntityCoords(me)
    local best, bestDist

    for _, id in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(id)

        if ped ~= me and DoesEntityExist(ped) then
            local dist = #(coords - GetEntityCoords(ped))

            if dist < 4.0 and (not bestDist or dist < bestDist) then
                best, bestDist = GetPlayerServerId(id), dist
            end
        end
    end

    return best
end

RegisterNetEvent('XS-Mechanic:client:invoice', function(invoice)
    local accept = lib.alertDialog({
        header = ('Invoice from %s'):format(invoice.shopName or 'a mechanic'),
        content = ('**%s**\n\n%s\n\nPay now?'):format(
            Util.Money(invoice.total),
            table.concat(invoice.summary or {}, '\n')),
        centered = true,
        cancel = true,
        labels = { confirm = 'Pay', cancel = 'Later' },
    })

    if accept ~= 'confirm' then
        XSM.Notify('Saved to /invoices.', 'inform')
        return
    end

    TriggerServerEvent('XS-Mechanic:server:payInvoice', invoice.id, 'bank')
end)

RegisterCommand(Config.Invoices.command, function()
    local result = lib.callback.await('XS-Mechanic:myInvoices', false)
    local rows = result and result.invoices or {}

    if #rows == 0 then
        XSM.Notify('Nothing owing.', 'inform')
        return
    end

    local options = {}

    for _, invoice in ipairs(rows) do
        options[#options + 1] = {
            title = ('%s · %s'):format(invoice.shopName or 'Mechanic', Util.Money(invoice.total)),
            description = ('%s · %s'):format(invoice.plate or '', invoice.status == 'paid' and 'Paid' or 'Unpaid'),
            icon = invoice.status == 'paid' and 'check' or 'file-invoice-dollar',
            disabled = invoice.status == 'paid',
            onSelect = function()
                local how = lib.inputDialog('Pay invoice', {
                    { type = 'select', label = 'Pay from', required = true, options = {
                        { value = 'bank', label = 'Bank' },
                        { value = 'cash', label = 'Cash' },
                    } },
                })

                if not how then return end
                TriggerServerEvent('XS-Mechanic:server:payInvoice', invoice.id, how[1])
            end,
        }
    end

    lib.registerContext({ id = 'xsmech_invoices', title = 'Invoices', options = options })
    lib.showContext('xsmech_invoices')
end)
