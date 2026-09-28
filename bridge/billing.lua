Billing = { name = nil }

if not IsDuplicityVersion() then return end

--[[ Handing a bill to a customer.

     Most servers already run something that does invoices — for the whole city,
     with its own history, chasing and fines. This resource is not trying to be
     that. It keeps a mechanic's own book so a shop works out of the box, and
     gets out of the way the moment a real one is running.

     Nothing here replaces the internal invoice. The row in xs_mechanic_invoices
     is written either way, because the shop's own screens read it and a boss
     wants to see what the shop billed regardless of who collected it. The
     bridge decides who chases the customer for the money. ]]

local function detect()
    local forced = Config.Bridges.billing

    if forced ~= 'auto' then return forced ~= 'none' and forced or nil end

    if GetResourceState('okokBilling') == 'started' then return 'okokBilling' end
    if GetResourceState('esx_billing') == 'started' then return 'esx_billing' end
    if GetResourceState('qb-phone') == 'started' then return 'qb-phone' end

    return nil
end

Billing.name = detect()

-- True when nothing else is collecting, so the resource's own invoice screen is
-- the only way the customer ever sees this.
function Billing.Internal()
    return Billing.name == nil and (Config.Invoices.provider or {}).event == nil
end

--[[ Send the bill.

     Returns true when something else took it on. False means nobody did, which
     is not a failure — the internal invoice is already written and the customer
     will see it on their own screen.

     Every call is wrapped: these are other people's resources, their exports
     change between forks and versions, and a billing script throwing must not
     take the fit or the order down with it. ]]
function Billing.Send(src, customerSrc, amount, label, meta)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 or not customerSrc then return false end

    meta = meta or {}
    label = tostring(label or 'Mechanic work')

    -- An owner's own hook wins over anything detected. One event, everything
    -- needed to raise a bill, so a server can point this at whatever it runs
    -- without this file having to know the resource exists.
    local provider = Config.Invoices.provider or {}

    if provider.event and provider.event ~= '' then
        local ok = pcall(function()
            TriggerEvent(provider.event, {
                society = meta.society,
                shop = meta.shopName,
                mechanic = src,
                customer = customerSrc,
                amount = amount,
                label = label,
                plate = meta.plate,
                invoiceId = meta.invoiceId,
            })
        end)

        if ok then return true end
    end

    -- okokBilling has no export for this. The call here used to be
    -- exports['okokBilling']:CreateInvoice, which does not exist, inside a
    -- pcall — so every bill quietly stayed internal. Its documented way in is
    -- okokBilling:CreateCustomInvoice, raised from the client of the player
    -- writing the invoice, so the mechanic's own client raises it.
    if Billing.name == 'okokBilling' then
        if not customerSrc or not GetPlayerName(customerSrc) then return false end

        TriggerClientEvent('XS-Mechanic:client:okokInvoice', src, {
            target = customerSrc,
            price = amount,
            reason = label,
            from = meta.shopName or 'Mechanic',
            society = meta.society,
            societyName = meta.shopName,
        })
        return true
    end

    if Billing.name == 'esx_billing' then
        local ok = pcall(function()
            TriggerEvent('esx_billing:sendBill',
                src, meta.society or 'society_mechanic', label, amount)
        end)
        if ok then return true end
    end

    if Billing.name == 'qb-phone' then
        local ok = pcall(function()
            TriggerEvent('qb-phone:server:sendNewMail', {
                source = customerSrc,
                subject = label,
                sender = meta.shopName or 'Mechanic',
                message = ('Amount due: %s'):format(Util.Money(amount)),
            })
        end)
        if ok then return true end
    end

    return false
end
