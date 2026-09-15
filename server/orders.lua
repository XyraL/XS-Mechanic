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

function Orders.Leave(src, data)
    local shop = Store.Get(data.shop)
    if not shop or not shop.enabled then return { ok = false, error = 'That shop is closed.' } end

    local citizenid = Framework.GetCitizenId(src)
    if not citizenid then return { ok = false, error = 'You are not loaded.' } end

    local waiting = MySQL.scalar.await([[
        SELECT COUNT(*) FROM xs_mechanic_orders
        WHERE shop_id = ? AND customer = ? AND status IN ('open', 'claimed')
    ]], { shop.id, citizenid })

    if (tonumber(waiting) or 0) >= 2 then
        return { ok = false, error = 'You already have work waiting here.' }
    end

    -- Two shapes arrive here. A desk order is a list of category names the
    -- customer ticked; a bay order is the actual picks they previewed, already
    -- priced by the server. Both are kept as they came.
    local requested = {}

    for _, entry in ipairs(data.requested or {}) do
        if type(entry) == 'string' and #entry <= 32 then
            requested[#requested + 1] = entry
        elseif type(entry) == 'table' and entry.label then
            requested[#requested + 1] = entry
        end
    end

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

    for _, person in ipairs(Framework.JobPlayers(shop.job)) do
        Framework.Notify(person.source, ('New work order at %s.'):format(shop.name), 'inform')
    end

    TriggerClientEvent('XS-Mechanic:client:refresh', -1)

    return { ok = true }
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
