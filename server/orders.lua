Orders = {}

local function decode(row)
    return {
        id = row.id,
        shopId = row.shop_id,
        customer = row.customer,
        customerName = row.customer_name,
        plate = row.plate,
        model = row.model,
        requested = Util.Decode(row.requested, {}) or {},
        notes = row.notes,
        status = row.status,
        quote = row.quote,
        claimedBy = row.claimed_by,
        claimedName = row.claimed_name,
        createdAt = row.created_at_unix,
    }
end

function Orders.ForShop(shopId)
    local rows = MySQL.query.await([[
        SELECT *, UNIX_TIMESTAMP(created_at) AS created_at_unix
        FROM xs_mechanic_orders WHERE shop_id = ?
        ORDER BY id DESC LIMIT 40
    ]], { shopId }) or {}

    local out = {}
    for _, row in ipairs(rows) do out[#out + 1] = decode(row) end
    return out
end

function Orders.OpenCount(shopId)
    local count = MySQL.scalar.await(
        "SELECT COUNT(*) FROM xs_mechanic_orders WHERE shop_id = ? AND status = 'open'", { shopId })
    return tonumber(count) or 0
end

--[[ A customer's order.

     There is one way in: drive into a bay, pick what you want and look at it on
     the car, send the lot. It lands on the tablet of whoever is working, and a
     mechanic who walks up to the car and connects to it sees what was asked
     for. Nothing is left on a desk for somebody to find.

     Performance is not on the list on purpose. Nobody picks a turbo off a menu
     because it looks nice — they ask the mechanic, and the mechanic fits it
     and bills for it. ]]
function Orders.Create(src, data)
    local shop = Store.Get(data.shop)
    if not shop or not shop.enabled then return { ok = false, error = 'That shop is closed.' } end

    -- An order with nobody to receive it is a queue nobody empties. With the
    -- shop unstaffed a customer's only route is doing it themselves, which is
    -- exactly what the self service fallback is for.
    if shop.kind ~= 'owned' then
        return { ok = false, error = 'This one is self service. Nobody takes orders here.' }
    end

    if Team.OnDuty(shop) == 0 then
        return { ok = false, error = 'Nobody is in. Come back when somebody is working, or do it yourself.' }
    end

    local citizenid = Framework.GetCitizenId(src)
    if not citizenid then return { ok = false, error = 'You are not loaded.' } end

    local waiting = MySQL.scalar.await([[
        SELECT COUNT(*) FROM xs_mechanic_orders
        WHERE shop_id = ? AND customer = ? AND status IN ('open', 'claimed')
    ]], { shop.id, citizenid })

    if (tonumber(waiting) or 0) >= 2 then
        return { ok = false, error = 'You already have work waiting here.' }
    end

    -- The picks the customer previewed, already priced by the server.
    local requested = {}

    for _, entry in ipairs(data.requested or {}) do
        if type(entry) == 'table' and entry.label then
            requested[#requested + 1] = entry
        end
    end

    if #requested == 0 then return { ok = false, error = 'Nothing on the order.' } end

    local id = MySQL.insert.await([[
        INSERT INTO xs_mechanic_orders (shop_id, customer, customer_name, plate, model, requested, notes, quote)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        shop.id, citizenid, Framework.GetName(src),
        Util.Trim(data.plate or ''):sub(1, 12),
        tostring(data.model or ''):sub(1, 64),
        json.encode(requested),
        tostring(data.notes or ''):sub(1, 300),
        math.max(0, math.floor(tonumber(data.quote) or 0)),
    })

    if not id then return { ok = false, error = 'Could not write that down.' } end

    local plate = Util.Trim(data.plate or '')

    for _, person in ipairs(Framework.JobPlayers(shop.job)) do
        Framework.Notify(person.source,
            ('Work order on the tablet — %s, %d part%s.'):format(
                plate ~= '' and plate or 'a vehicle', #requested, #requested == 1 and '' or 's'),
            'inform')
    end

    TriggerClientEvent('XS-Mechanic:client:refresh', -1)

    return { ok = true }
end

--[[ A work order the SHOP writes.

     A mechanic picks five things, the shelf has three of them, and the answer
     is not "no". The three go on, the two that cannot go on become a job the
     shop owes the customer — which is the whole reason work orders exist.

     It goes down already claimed by whoever wrote it. They are stood at the
     car; they are not waiting for somebody else to pick it up. ]]
function Orders.Book(src, data)
    local shop = Store.Get(data.shop)
    if not shop or not shop.enabled then return { ok = false, error = 'That shop is closed.' } end

    local job = Framework.GetJob(src)
    if shop.kind == 'owned' and job ~= shop.job then return { ok = false, error = 'Not your shop.' } end

    local picks = type(data.picks) == 'table' and data.picks or {}
    if #picks == 0 then return { ok = false, error = 'Nothing to book.' } end

    local plate = Util.Trim(data.plate or ''):sub(1, 12)
    if plate == '' then return { ok = false, error = 'No vehicle.' } end

    local priced, total = {}, 0

    for _, pick in ipairs(picks) do
        local category = tostring(pick.category or '')

        if Pricing.CategoryEnabled(shop, category) then
            local price = Pricing.For(shop, category, data.model, data.class, pick.index) or 0

            priced[#priced + 1] = {
                category = category,
                categoryLabel = Mods.CategoryLabel[category] or category,
                slotId = tostring(pick.slotId or ''),
                slot = tonumber(pick.slot),
                index = tonumber(pick.index),
                wheelType = tonumber(pick.wheelType),
                legacy = pick.legacy == true,
                label = tostring(pick.label or 'Part'):sub(1, 64),
                price = price,
            }

            total = total + price
        end
    end

    if #priced == 0 then return { ok = false, error = 'This shop does not do any of that.' } end

    -- The customer is whoever the vehicle belongs to when we know, and the
    -- mechanic when we do not — an order has to belong to somebody.
    local profile = Vehicles.Profile(plate, data.model)
    local customer = profile and profile.owner or nil

    local me = Framework.GetCitizenId(src) or ''

    local id = MySQL.insert.await([[
        INSERT INTO xs_mechanic_orders
            (shop_id, customer, customer_name, plate, model, requested, notes, quote, status, claimed_by, claimed_name)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'claimed', ?, ?)
    ]], {
        shop.id,
        customer or me,
        customer and (Framework.GetNameByCitizenId(customer) or 'Customer') or Framework.GetName(src),
        plate,
        tostring(data.model or ''):sub(1, 64),
        json.encode(priced),
        tostring(data.notes or 'Waiting on parts.'):sub(1, 300),
        total,
        me,
        Framework.GetName(src),
    })

    if not id then return { ok = false, error = 'Could not write that down.' } end

    TriggerClientEvent('XS-Mechanic:client:refresh', -1)

    return { ok = true, count = #priced, total = total }
end

local function claimable(src, id)
    local row = MySQL.single.await('SELECT * FROM xs_mechanic_orders WHERE id = ?', { id })
    if not row then return nil, 'That order is gone.' end

    local shop = Store.Get(row.shop_id)
    if not shop then return nil, 'That shop is gone.' end

    local job = Framework.GetJob(src)
    if job ~= shop.job then return nil, 'Not your shop.' end

    return row, nil
end

function Orders.Claim(src, id)
    local row, err = claimable(src, id)
    if not row then return { ok = false, error = err } end

    if row.status ~= 'open' then return { ok = false, error = 'Somebody already has that one.' } end

    MySQL.update.await([[
        UPDATE xs_mechanic_orders SET status = 'claimed', claimed_by = ?, claimed_name = ? WHERE id = ?
    ]], { Framework.GetCitizenId(src) or '', Framework.GetName(src), id })

    TriggerClientEvent('XS-Mechanic:client:refresh', -1)

    return { ok = true, message = 'Claimed.' }
end

-- Taking a line off an order. A part the shop cannot get hold of should come
-- off the list rather than sit on it forever, and the quote comes down with it
-- so the customer is not still being shown a price for it.
function Orders.DropLine(src, id, line)
    local row, err = claimable(src, id)
    if not row then return { ok = false, error = err } end

    if row.status == 'done' then return { ok = false, error = 'That one is finished.' } end

    local requested = Util.Decode(row.requested, {}) or {}
    local index = math.floor(tonumber(line) or -1) + 1

    if not requested[index] then return { ok = false, error = 'That line is already gone.' } end

    local dropped = requested[index]
    table.remove(requested, index)

    local quote = 0
    for _, entry in ipairs(requested) do
        quote = quote + (tonumber(entry.price) or 0)
    end

    MySQL.update.await('UPDATE xs_mechanic_orders SET requested = ?, quote = ? WHERE id = ?',
        { json.encode(requested), quote, id })

    for _, playerId in ipairs(GetPlayers()) do
        playerId = tonumber(playerId)

        if Framework.GetCitizenId(playerId) == row.customer then
            Framework.Notify(playerId,
                ('The shop took %s off your order.'):format(dropped.label or 'a part'), 'inform')
            break
        end
    end

    TriggerClientEvent('XS-Mechanic:client:refresh', -1)

    return { ok = true, message = ('%s taken off.'):format(dropped.label or 'Line') }
end

function Orders.Finish(src, id)
    local row, err = claimable(src, id)
    if not row then return { ok = false, error = err } end

    if row.status ~= 'claimed' then return { ok = false, error = 'That one is not in progress.' } end

    MySQL.update.await("UPDATE xs_mechanic_orders SET status = 'done' WHERE id = ?", { id })

    for _, playerId in ipairs(GetPlayers()) do
        playerId = tonumber(playerId)

        if Framework.GetCitizenId(playerId) == row.customer then
            local shop = Store.Get(row.shop_id)
            Framework.Notify(playerId, ('%s have finished with your vehicle.'):format(shop and shop.name or 'The mechanic'), 'success')
            Phone.Notify(playerId, shop and shop.name or 'Mechanic', 'Your vehicle is ready.')
            break
        end
    end

    TriggerClientEvent('XS-Mechanic:client:refresh', -1)

    return { ok = true, message = 'Marked finished.' }
end
