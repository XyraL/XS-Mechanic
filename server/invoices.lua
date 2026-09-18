Invoices = {}

-- One open draft per mechanic. It is built as they work and only becomes a row
-- when it is sent or saved.
local drafts = {}

local function decode(row)
    return {
        id = row.id,
        shopId = row.shop_id,
        mechanic = row.mechanic,
        mechanicName = row.mechanic_name,
        customer = row.customer,
        customerName = row.customer_name,
        plate = row.plate,
        items = Util.Decode(row.items, {}) or {},
        total = row.total,
        status = row.status,
        createdAt = row.created_at_unix,
        paidAt = row.paid_at_unix,
    }
end

function Invoices.Draft(src)
    drafts[src] = drafts[src] or { items = {}, total = 0 }
    return drafts[src]
end

function Invoices.Clear(src)
    drafts[src] = nil
end

local function retotal(draft)
    local total = 0
    for _, item in ipairs(draft.items) do total = total + (item.amount or 0) end
    draft.total = total
end

--[[ Whether work done on the spot lands on the running bill by itself.

     Only repairs, servicing and stance come through here now. Parts are fitted
     off a work order and billed from the order, which is its own path and is
     never silent — somebody pressed a button that said what it would do. ]]
local function autoDraft(src)
    if not Config.Invoices.autoDraft then return false end

    local citizenid = Framework.GetCitizenId(src)
    if not citizenid then return true end

    local row = MySQL.single.await('SELECT settings FROM xs_mechanic_players WHERE citizenid = ?', { citizenid })
    local settings = Util.Decode(row and row.settings, {}) or {}

    return settings.autoDraft ~= false
end

function Invoices.AddLine(src, label, amount, category, note)
    local draft = Invoices.Draft(src)

    if not autoDraft(src) then return draft end

    draft.items[#draft.items + 1] = {
        label = label,
        amount = math.floor(tonumber(amount) or 0),
        category = category,
        note = note,
    }

    retotal(draft)
    return draft
end

function Invoices.DropLine(src, index)
    local draft = Invoices.Draft(src)
    index = tonumber(index)

    if not index or not draft.items[index + 1] then return draft end

    table.remove(draft.items, index + 1)
    retotal(draft)
    return draft
end

function Invoices.ForShop(shopId, limit)
    local rows = MySQL.query.await([[
        SELECT *, UNIX_TIMESTAMP(created_at) AS created_at_unix,
               UNIX_TIMESTAMP(paid_at) AS paid_at_unix
        FROM xs_mechanic_invoices WHERE shop_id = ?
        ORDER BY id DESC LIMIT ?
    ]], { shopId, limit or 40 }) or {}

    local out = {}
    for _, row in ipairs(rows) do out[#out + 1] = decode(row) end
    return out
end

function Invoices.ForCustomer(citizenid)
    local rows = MySQL.query.await([[
        SELECT i.*, UNIX_TIMESTAMP(i.created_at) AS created_at_unix,
               UNIX_TIMESTAMP(i.paid_at) AS paid_at_unix, s.name AS shop_name
        FROM xs_mechanic_invoices i
        LEFT JOIN xs_mechanic_shops s ON s.id = i.shop_id
        WHERE i.customer = ? AND i.status IN ('sent', 'paid')
        ORDER BY i.id DESC LIMIT 30
    ]], { citizenid }) or {}

    local out = {}

    for _, row in ipairs(rows) do
        local invoice = decode(row)
        invoice.shopName = row.shop_name
        out[#out + 1] = invoice
    end

    return out
end

local function summarise(items)
    local lines = {}

    for i, item in ipairs(items) do
        if i > 5 then
            lines[#lines + 1] = ('and %d more'):format(#items - 5)
            break
        end
        lines[#lines + 1] = ('%s — %s'):format(item.label, Util.Money(item.amount))
    end

    return lines
end

-- Nearest customer to the mechanic. An invoice is handed over in person, so
-- there is no player list to pick a stranger out of.
function Invoices.Nearest(src)
    local mechanic = GetPlayerPed(src)
    if not mechanic or mechanic == 0 then return nil end

    local coords = GetEntityCoords(mechanic)
    local best, bestDist

    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)

        if id ~= src then
            local ped = GetPlayerPed(id)

            if ped and ped ~= 0 then
                local dist = #(coords - GetEntityCoords(ped))

                if dist <= Config.Invoices.customerDistance and (not bestDist or dist < bestDist) then
                    best, bestDist = id, dist
                end
            end
        end
    end

    return best
end

function Invoices.Send(src, shop, plate, save)
    local draft = Invoices.Draft(src)

    if #draft.items == 0 then
        return { ok = false, error = 'Nothing on the invoice.' }
    end

    local customerSrc, customerId, customerName

    if not save then
        customerSrc = Invoices.Nearest(src)

        if not customerSrc then
            return { ok = false, error = 'Nobody close enough to hand it to.' }
        end

        customerId = Framework.GetCitizenId(customerSrc)
        customerName = Framework.GetName(customerSrc)

        if not customerId then
            return { ok = false, error = 'That player is not loaded.' }
        end
    end

    local id = MySQL.insert.await([[
        INSERT INTO xs_mechanic_invoices
            (shop_id, mechanic, mechanic_name, customer, customer_name, plate, items, total, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        shop.id,
        Framework.GetCitizenId(src) or '',
        Framework.GetName(src),
        customerId or '',
        customerName or '',
        plate or '',
        json.encode(draft.items),
        draft.total,
        save and 'draft' or 'sent',
    })

    if not id then
        return { ok = false, error = 'Could not write that invoice.' }
    end

    Invoices.Clear(src)

    if save then
        return { ok = true, message = 'Saved for later.' }
    end

    TriggerClientEvent('XS-Mechanic:client:invoice', customerSrc, {
        id = id,
        shopName = shop.name,
        total = draft.total,
        summary = summarise(draft.items),
    })

    Phone.Notify(customerSrc, shop.name, ('Invoice for %s'):format(Util.Money(draft.total)))

    Discord.Send('money', 'Invoice sent',
        ('**%s** billed **%s** %s at %s'):format(
            Framework.GetName(src), customerName, Util.Money(draft.total), shop.name),
        Discord.Colour.info)

    return { ok = true, message = ('Sent to %s.'):format(customerName) }
end

--[[ Billing a work order.

     Nothing to do with the draft. The draft is one running bill per mechanic,
     which is right for a repair or a service done on the spot and wrong for an
     order — an order already knows what is on it and who it is for, and a
     mechanic who writes two orders before sending either should not have them
     bleed into each other.

     The customer is whoever the order is for, online or not, because they
     agreed to the work when they asked for it. Only an order with nobody on it
     falls back to whoever is stood there. ]]
function Invoices.Bill(src, shop, order, lines)
    local items, total = {}, 0

    for _, line in ipairs(lines or {}) do
        local amount = math.max(0, math.floor(tonumber(line.price) or 0))

        items[#items + 1] = {
            label = line.label,
            amount = amount,
            category = line.categoryLabel or line.category,
            note = ('Order #%d'):format(order.id),
        }

        total = total + amount
    end

    if #items == 0 then return { ok = false, error = 'Nothing to bill.' } end

    local customer, customerName = order.customer, order.customerName

    if not customer or customer == '' then
        local nearest = Invoices.Nearest(src)
        if not nearest then return { ok = false, error = 'Nobody close enough to hand it to.' } end

        customer = Framework.GetCitizenId(nearest)
        customerName = Framework.GetName(nearest)

        if not customer then return { ok = false, error = 'That player is not loaded.' } end

        MySQL.update.await('UPDATE xs_mechanic_orders SET customer = ?, customer_name = ? WHERE id = ?',
            { customer, customerName, order.id })

        order.customer, order.customerName = customer, customerName
    end

    local id = MySQL.insert.await([[
        INSERT INTO xs_mechanic_invoices
            (shop_id, mechanic, mechanic_name, customer, customer_name, plate, items, total, status, order_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'sent', ?)
    ]], {
        shop.id,
        Framework.GetCitizenId(src) or '',
        Framework.GetName(src),
        customer,
        customerName or '',
        order.plate or '',
        json.encode(items),
        total,
        order.id,
    })

    if not id then return { ok = false, error = 'Could not write that invoice.' } end

    -- Handed over now if they are here, waiting in /invoices if they are not.
    local customerSrc

    for _, playerId in ipairs(GetPlayers()) do
        playerId = tonumber(playerId)
        if Framework.GetCitizenId(playerId) == customer then customerSrc = playerId break end
    end

    if customerSrc then
        TriggerClientEvent('XS-Mechanic:client:invoice', customerSrc, {
            id = id,
            shopName = shop.name,
            total = total,
            summary = summarise(items),
        })

        Phone.Notify(customerSrc, shop.name, ('Invoice for %s'):format(Util.Money(total)))
    end

    Discord.Send('money', 'Invoice sent',
        ('**%s** billed **%s** %s at %s'):format(
            Framework.GetName(src), customerName, Util.Money(total), shop.name),
        Discord.Colour.info)

    return {
        ok = true,
        id = id,
        total = total,
        message = customerSrc
            and ('Billed %s %s.'):format(customerName, Util.Money(total))
            or ('%s billed to %s. They are not online — it is waiting for them.'):format(Util.Money(total), customerName),
    }
end

function Invoices.Resend(src, id)
    local row = MySQL.single.await([[
        SELECT *, UNIX_TIMESTAMP(created_at) AS created_at_unix,
               UNIX_TIMESTAMP(paid_at) AS paid_at_unix
        FROM xs_mechanic_invoices WHERE id = ?
    ]], { id })

    if not row then return { ok = false, error = 'That invoice is gone.' } end
    if row.status == 'paid' then return { ok = false, error = 'That one is already paid.' } end

    local invoice = decode(row)
    local customerSrc

    for _, playerId in ipairs(GetPlayers()) do
        playerId = tonumber(playerId)
        if Framework.GetCitizenId(playerId) == invoice.customer then customerSrc = playerId break end
    end

    -- A saved draft has no customer on it yet; sending it now picks whoever is
    -- stood in front of the mechanic, the same as a fresh one.
    if invoice.customer == '' or not customerSrc then
        if invoice.customer == '' then
            local nearest = Invoices.Nearest(src)
            if not nearest then return { ok = false, error = 'Nobody close enough to hand it to.' } end

            customerSrc = nearest

            MySQL.update.await([[
                UPDATE xs_mechanic_invoices SET customer = ?, customer_name = ?, status = 'sent' WHERE id = ?
            ]], { Framework.GetCitizenId(customerSrc), Framework.GetName(customerSrc), id })
        else
            return { ok = false, error = 'They are not online.' }
        end
    else
        MySQL.update.await('UPDATE xs_mechanic_invoices SET status = ? WHERE id = ?', { 'sent', id })
    end

    local shop = Store.Get(invoice.shopId)

    TriggerClientEvent('XS-Mechanic:client:invoice', customerSrc, {
        id = id,
        shopName = shop and shop.name or 'Mechanic',
        total = invoice.total,
        summary = summarise(invoice.items),
    })

    return { ok = true, message = 'Sent again.' }
end

function Invoices.Pay(src, id, account)
    local citizenid = Framework.GetCitizenId(src)
    if not citizenid then return end

    local row = MySQL.single.await('SELECT * FROM xs_mechanic_invoices WHERE id = ?', { id })

    if not row or row.customer ~= citizenid then
        Framework.Notify(src, 'That invoice is not yours.', 'error')
        return
    end

    if row.status == 'paid' then
        Framework.Notify(src, 'Already paid.', 'inform')
        return
    end

    account = account == 'cash' and 'cash' or 'bank'

    if Framework.GetMoney(src, account) < row.total then
        Framework.Notify(src, 'You cannot cover that.', 'error')
        return
    end

    if not Framework.RemoveMoney(src, account, row.total, 'Mechanic invoice') then
        Framework.Notify(src, 'Payment failed.', 'error')
        return
    end

    MySQL.update.await('UPDATE xs_mechanic_invoices SET status = ?, paid_at = NOW() WHERE id = ?', { 'paid', id })

    local shop = Store.Get(row.shop_id)
    if not shop then return end

    local commission = math.floor(row.total * ((shop.commission or 0) / 100))
    local toShop = row.total - commission

    Banking.Add(shop, toShop, ('Invoice #%d paid'):format(id), row.mechanic_name, 'invoice')

    if commission > 0 and row.mechanic ~= '' then
        for _, playerId in ipairs(GetPlayers()) do
            playerId = tonumber(playerId)

            if Framework.GetCitizenId(playerId) == row.mechanic then
                Framework.AddMoney(playerId, 'bank', commission, 'Mechanic commission')
                Framework.Notify(playerId, ('Commission: %s'):format(Util.Money(commission)), 'success')
                break
            end
        end
    end

    Framework.Notify(src, ('Paid %s.'):format(Util.Money(row.total)), 'success')

    Discord.Send('money', 'Invoice paid',
        ('**%s** paid %s to %s'):format(Framework.GetName(src), Util.Money(row.total), shop.name),
        Discord.Colour.good)

    TriggerClientEvent('XS-Mechanic:client:refresh', -1)
end

function Invoices.Counts(shopId)
    local row = MySQL.single.await([[
        SELECT
            COUNT(CASE WHEN status = 'sent' THEN 1 END) AS unpaid,
            COALESCE(SUM(CASE WHEN status = 'sent' THEN total END), 0) AS unpaid_total,
            COUNT(CASE WHEN status = 'paid' AND paid_at >= CURDATE() THEN 1 END) AS jobs_today
        FROM xs_mechanic_invoices WHERE shop_id = ?
    ]], { shopId })

    return {
        unpaid = row and row.unpaid or 0,
        unpaidTotal = row and math.floor(row.unpaid_total) or 0,
        jobs = row and row.jobs_today or 0,
    }
end

AddEventHandler('playerDropped', function()
    drafts[source] = nil
end)
