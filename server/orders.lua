Orders = {}

--[[ A work order is the job, and it is the only thing that changes a vehicle.

     Nothing in the tablet touches the car. Picking parts previews them and
     builds a list; the list is written down as an order and billed. The car
     changes later, when a mechanic stands at it with the part in their pockets
     and uses it — and what goes on is read off the order, which is why every
     line has to carry enough to be replayed days after it was written. A
     respray line with no colour on it is not a job anybody can do. ]]

-- Old rows were written before lines had ids. Numbering them on the way out
-- means an order booked last week still works rather than being skipped.
local function relabel(lines)
    for index, line in ipairs(lines) do
        if type(line) == 'table' and not line.lid then line.lid = index end
    end

    return lines
end

local function decode(row)
    return {
        id = row.id,
        shopId = row.shop_id,
        customer = row.customer,
        customerName = row.customer_name,
        plate = row.plate,
        model = row.model,
        requested = relabel(Util.Decode(row.requested, {}) or {}),
        notes = row.notes,
        status = row.status,
        quote = row.quote,
        claimedBy = row.claimed_by,
        claimedName = row.claimed_name,
        createdAt = row.created_at_unix,
    }
end

local function save(id, lines)
    local quote = 0
    for _, line in ipairs(lines) do quote = quote + (tonumber(line.price) or 0) end

    MySQL.update.await('UPDATE xs_mechanic_orders SET requested = ?, quote = ? WHERE id = ?',
        { json.encode(lines), quote, id })

    return quote
end

--[[ What one pick costs.

     nil means this shop does not sell it and the line is dropped. A handling
     package is priced per option and the shop can rename and reprice it, so it
     cannot go through Pricing.For — there is no `tuning` band to read and
     asking for one returns nil, which is how every package booked at a flat
     performance price instead of its own. ]]
local function priceOf(shop, pick, model, class)
    if pick.tuning then
        if not Config.CustomTuning.enabled then return nil end

        local option = Tuning.Get(pick.tuning.category, pick.tuning.option)
        if not option then return nil end

        -- Taking one back off is labour, not a part. Nobody is billed for it.
        if pick.tuning.remove then return 0 end

        local _, price = CustomTuning.Priced(shop, pick.tuning.category, option)
        return math.max(0, math.floor(tonumber(price) or 0))
    end

    local category = tostring(pick.category or '')
    if not Pricing.CategoryEnabled(shop, category) then return nil end

    return Pricing.For(shop, category, model, class, pick.index) or 0
end

-- Everything a pick carries. Widened deliberately: the old version rebuilt a
-- pick down to eight fields, so a booked respray lost its colour and a booked
-- extra lost whether it was going on or coming off.
local function lineFrom(pick, lid, price)
    local category = tostring(pick.category or '')

    local line = {
        lid = lid,
        category = category,
        categoryLabel = Mods.CategoryLabel[category] or category,
        label = tostring(pick.label or 'Part'):sub(1, 64),
        price = price,
        fitted = false,

        slotId = tostring(pick.slotId or ''),
        slot = tonumber(pick.slot),
        index = tonumber(pick.index),
        wheelType = tonumber(pick.wheelType),
        legacy = pick.legacy == true or nil,
        plain = pick.plain == true or nil,
    }

    if pick.paint then
        line.paint = true
        line.part = tostring(pick.part or 'primary')
        line.custom = pick.custom and tostring(pick.custom) or nil
        line.hex = pick.hex and tostring(pick.hex):sub(1, 7) or nil
    end

    if pick.extra ~= nil then
        line.extra = tonumber(pick.extra)
        line.on = pick.on == true
    end

    if type(pick.tuning) == 'table' then
        line.tuning = {
            category = tostring(pick.tuning.category or ''),
            option = tostring(pick.tuning.option or ''),
            remove = pick.tuning.remove == true or nil,
        }
    end

    return line
end

--[[ The part a line needs, or nil when there is nothing to fit.

     nil is not a failure. Switching an extra off, taking a package back off
     and every line on a server that does not run on parts all have no item
     behind them, and those are done from the order screen instead. Everything
     that does have an item is done by using it at the car. Nothing is both. ]]
function Orders.ItemFor(shop, line)
    if type(line) ~= 'table' then return nil end

    if line.tuning then
        if line.tuning.remove then return nil end
        if shop and shop.tuningItems == false then return nil end
        if not Config.CustomTuning.requiresItem then return nil end

        local option = Tuning.Get(line.tuning.category, line.tuning.option)
        if not option or not option.item or option.item == '' then return nil end

        return option.item
    end

    -- Not the shop's shelf: Config.Stock.require is the server deciding
    -- whether parts exist at all. Stock.Enabled also asks whether this shop
    -- has somewhere to keep them, and a shop with no stockroom still has a
    -- mechanic with a bumper in their pockets.
    if Config.Stock.require ~= true then return nil end

    if line.plain then return nil end
    if line.extra ~= nil and not line.on then return nil end

    local item = Parts.ItemFor(line.category, line.slotId)
    if not item or item == '' then return nil end

    return item
end

function Orders.Counts(order)
    local total, done = 0, 0

    for _, line in ipairs(order.requested or {}) do
        if type(line) == 'table' then
            total = total + 1
            if line.fitted then done = done + 1 end
        end
    end

    return total, done
end

--[[ What the tablet is shown.

     Every order still open, however old, plus a short tail of finished ones.
     The old version took the newest forty of everything, so a busy shop lost
     its open orders off the bottom while a mechanic stood at the car holding
     the part for one of them. ]]
function Orders.ForShop(shopId)
    local rows = MySQL.query.await([[
        SELECT *, UNIX_TIMESTAMP(created_at) AS created_at_unix
        FROM xs_mechanic_orders
        WHERE shop_id = ? AND status IN ('open', 'claimed')
        ORDER BY id DESC
    ]], { shopId }) or {}

    local done = MySQL.query.await([[
        SELECT *, UNIX_TIMESTAMP(created_at) AS created_at_unix
        FROM xs_mechanic_orders
        WHERE shop_id = ? AND status = 'done'
        ORDER BY id DESC LIMIT 20
    ]], { shopId }) or {}

    local shop = Store.Get(shopId)
    local out = {}

    -- Which part each line is waiting on, worked out here so the screen can
    -- say "make one" against the right thing, and can tell the lines somebody
    -- fits with a part from the ones there is nothing to fit.
    local function annotate(order)
        for _, line in ipairs(order.requested) do
            if type(line) == 'table' then
                local item = Orders.ItemFor(shop, line)

                line.needs = item
                line.needsLabel = item and Parts.Label(item) or nil
            end
        end

        order.total, order.done = Orders.Counts(order)

        return order
    end

    for _, row in ipairs(rows) do out[#out + 1] = annotate(decode(row)) end
    for _, row in ipairs(done) do out[#out + 1] = annotate(decode(row)) end

    return out
end

function Orders.OpenCount(shopId)
    local count = MySQL.scalar.await(
        "SELECT COUNT(*) FROM xs_mechanic_orders WHERE shop_id = ? AND status = 'open'", { shopId })
    return tonumber(count) or 0
end

-- The order already open on this plate at this shop, if there is one. Picking
-- cosmetics, billing, then picking a turbo should add to the job that is
-- already written down rather than starting a second one against the same car.
local function openFor(shopId, plate)
    local row = MySQL.single.await([[
        SELECT *, UNIX_TIMESTAMP(created_at) AS created_at_unix
        FROM xs_mechanic_orders
        WHERE shop_id = ? AND plate = ? AND status IN ('open', 'claimed')
        ORDER BY id ASC LIMIT 1
    ]], { shopId, plate })

    return row and decode(row) or nil
end

local function nextLid(lines)
    local highest = 0

    for _, line in ipairs(lines) do
        local lid = tonumber(line.lid) or 0
        if lid > highest then highest = lid end
    end

    return highest + 1
end

-- Picks in, priced lines out. The price is worked out here and nowhere else —
-- the panel's numbers are what it drew on screen, not what anybody is charged.
local function priceAll(shop, picks, model, class, lines)
    local lid = nextLid(lines or {})
    local priced, total = {}, 0

    for _, pick in ipairs(picks or {}) do
        if type(pick) == 'table' and pick.label then
            local price = priceOf(shop, pick, model, class)

            if price then
                priced[#priced + 1] = lineFrom(pick, lid, price)
                total = total + price
                lid = lid + 1
            end
        end
    end

    return priced, total
end

--[[ A customer's order.

     Drive into a bay, pick what you want, look at it on the car, send the lot.
     It lands on the tablet of whoever is working, and a mechanic who walks up
     to the car and connects to it sees what was asked for. ]]
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

    local plate = Util.Trim(data.plate or ''):sub(1, 12)
    if plate == '' then return { ok = false, error = 'No vehicle.' } end

    local waiting = MySQL.scalar.await([[
        SELECT COUNT(*) FROM xs_mechanic_orders
        WHERE shop_id = ? AND customer = ? AND status IN ('open', 'claimed')
    ]], { shop.id, citizenid })

    if (tonumber(waiting) or 0) >= 2 then
        return { ok = false, error = 'You already have work waiting here.' }
    end

    -- Priced here, not taken from the panel. These lines are about to be
    -- instructions the shop works from and bills for.
    local requested, quote = priceAll(shop, data.requested or data.picks, data.model, data.class, nil)

    if #requested == 0 then return { ok = false, error = 'Nothing on the order.' } end

    local id = MySQL.insert.await([[
        INSERT INTO xs_mechanic_orders (shop_id, customer, customer_name, plate, model, requested, notes, quote)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        shop.id, citizenid, Framework.GetName(src),
        plate,
        tostring(data.model or ''):sub(1, 64),
        json.encode(requested),
        tostring(data.notes or ''):sub(1, 300),
        quote,
    })

    if not id then return { ok = false, error = 'Could not write that down.' } end

    for _, person in ipairs(Framework.JobPlayers(shop.job)) do
        Framework.Notify(person.source,
            ('Work order on the tablet — %s, %d part%s.'):format(
                plate ~= '' and plate or 'a vehicle', #requested, #requested == 1 and '' or 's'),
            'inform')
    end

    TriggerClientEvent('XS-Mechanic:client:refresh', -1)

    return { ok = true }
end

-- Who the job is for. The registered owner first, then whoever is stood in
-- front of the mechanic, because somebody asked for this work.
local function customerFor(src, plate)
    local owner = Vehicles.OwnerOf(plate)

    if owner then
        return owner, Framework.GetNameByCitizenId(owner) or 'Customer'
    end

    local nearest = Invoices.Nearest(src)

    if nearest then
        local citizenid = Framework.GetCitizenId(nearest)
        if citizenid then return citizenid, Framework.GetName(nearest) end
    end

    return '', ''
end

--[[ A work order the SHOP writes.

     Picks go down as a job owed against that car, already claimed by whoever
     wrote it — they are stood at the car, not waiting for somebody to pick it
     up. Adding to a car that already has an order open appends to it, so the
     bumpers and the turbo are one job and one bill. ]]
function Orders.Book(src, data)
    local shop = Store.Get(data.shop)
    if not shop or not shop.enabled then return { ok = false, error = 'That shop is closed.' } end

    local job = Framework.GetJob(src)
    if shop.kind == 'owned' and job ~= shop.job then return { ok = false, error = 'Not your shop.' } end

    local picks = type(data.picks) == 'table' and data.picks or {}
    if #picks == 0 then return { ok = false, error = 'Nothing to write down.' } end

    local plate = Util.Trim(data.plate or ''):sub(1, 12)
    if plate == '' then return { ok = false, error = 'No vehicle.' } end

    local me = Framework.GetCitizenId(src) or ''
    local existing = openFor(shop.id, plate)
    local lines = existing and existing.requested or {}

    local priced, total = priceAll(shop, picks, data.model, data.class, lines)

    if #priced == 0 then return { ok = false, error = 'This shop does not do any of that.' } end

    local id

    if existing then
        for _, line in ipairs(priced) do lines[#lines + 1] = line end

        save(existing.id, lines)
        id = existing.id
    else
        local customer, customerName = customerFor(src, plate)

        id = MySQL.insert.await([[
            INSERT INTO xs_mechanic_orders
                (shop_id, customer, customer_name, plate, model, requested, notes, quote, status, claimed_by, claimed_name)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'claimed', ?, ?)
        ]], {
            shop.id,
            customer,
            customerName,
            plate,
            tostring(data.model or ''):sub(1, 64),
            json.encode(priced),
            tostring(data.notes or 'Waiting on parts.'):sub(1, 300),
            total,
            me,
            Framework.GetName(src),
        })

        lines = priced
    end

    if not id then return { ok = false, error = 'Could not write that down.' } end

    TriggerClientEvent('XS-Mechanic:client:refresh', -1)

    return { ok = true, id = id, count = #priced, total = total, added = priced, appended = existing ~= nil }
end

--[[ Writing it down and billing for it in one press.

     The order is always written. Billing is what the button adds: one invoice
     for every line on that order nobody has been charged for yet, which is the
     lines just added plus anything booked earlier and not billed. ]]
function Orders.Bill(src, data)
    local booked = Orders.Book(src, data)
    if not booked.ok then return booked end

    local billed = Orders.BillRest(src, booked.id)

    if not billed.ok then
        return {
            ok = true,
            id = booked.id,
            count = booked.count,
            message = ('%d written down. %s'):format(booked.count, billed.error or 'Not billed.'),
        }
    end

    return {
        ok = true,
        id = booked.id,
        count = booked.count,
        total = billed.total,
        message = billed.message,
    }
end

-- Every line on an order nobody has been charged for yet, as one invoice.
function Orders.BillRest(src, id)
    local row = MySQL.single.await([[
        SELECT *, UNIX_TIMESTAMP(created_at) AS created_at_unix
        FROM xs_mechanic_orders WHERE id = ?
    ]], { id })

    if not row then return { ok = false, error = 'That order is gone.' } end

    local order = decode(row)
    local shop = Store.Get(order.shopId)
    if not shop then return { ok = false, error = 'That shop is gone.' } end

    local job = Framework.GetJob(src)
    if shop.kind == 'owned' and job ~= shop.job then return { ok = false, error = 'Not your shop.' } end

    local unbilled = {}

    for _, line in ipairs(order.requested) do
        if type(line) == 'table' and not line.billed then unbilled[#unbilled + 1] = line end
    end

    if #unbilled == 0 then return { ok = false, error = 'Everything on that one is already billed.' } end

    local result = Invoices.Bill(src, shop, order, unbilled)
    if not result.ok then return result end

    for _, line in ipairs(unbilled) do line.billed = result.id end

    save(order.id, order.requested)

    TriggerClientEvent('XS-Mechanic:client:refresh', -1)

    return result
end

--[[ Which lines a part in your hands is for.

     Walked oldest order first and in written order inside each, so the answer
     is the same every time. A line whose item is nil is not a candidate for
     any item — those are done from the order screen. ]]
function Orders.Candidates(src, data)
    local shop = Store.ByJob(Framework.GetJob(src))
    if not shop then return { ok = false, error = 'You are not a mechanic.' } end

    local plate = Util.Trim(data.plate or '')
    if plate == '' then return { ok = false, error = 'No vehicle.' } end

    local item = data.item and tostring(data.item) or nil
    local model = tostring(data.model or '')

    local rows = MySQL.query.await([[
        SELECT *, UNIX_TIMESTAMP(created_at) AS created_at_unix
        FROM xs_mechanic_orders
        WHERE shop_id = ? AND plate = ? AND status IN ('open', 'claimed')
        ORDER BY id ASC
    ]], { shop.id, plate }) or {}

    if #rows == 0 then
        local elsewhere = MySQL.scalar.await([[
            SELECT COUNT(*) FROM xs_mechanic_orders
            WHERE plate = ? AND status IN ('open', 'claimed')
        ]], { plate })

        if (tonumber(elsewhere) or 0) > 0 then
            return { ok = false, error = "That is another shop's order." }
        end

        return { ok = false, error = ('Nothing written down for %s.'):format(plate) }
    end

    local out = {}
    local wanted = false

    for _, row in ipairs(rows) do
        local order = decode(row)

        -- A plate can come back on a different car. An order written for one
        -- model is not a licence to rebuild another.
        if order.model == '' or model == '' or order.model == model then
            for _, line in ipairs(order.requested) do
                if type(line) == 'table' then
                    local needs = Orders.ItemFor(shop, line)

                    if needs == item then
                        if line.fitted then
                            wanted = true
                        else
                            out[#out + 1] = {
                                orderId = order.id,
                                lid = line.lid,
                                label = line.label,
                                category = line.category,
                                categoryLabel = line.categoryLabel,
                                price = line.price,
                                tuning = line.tuning,
                            }
                        end
                    end
                end
            end
        end
    end

    if #out == 0 then
        if item then
            local label = string.lower(Parts.Label(item))

            -- Grabbed the wrong thing, and nothing left to do with the right
            -- thing, are different problems with different answers.
            return { ok = false, error = wanted
                and ('Nothing left for a %s.'):format(label)
                or ('Nothing on this order needs a %s.'):format(label) }
        end

        return { ok = false, error = 'Nothing on this order to do by hand.' }
    end

    return { ok = true, lines = out, orders = #rows }
end

--[[ One line, done.

     Everything is checked again here rather than only before the animation:
     the part is taken and the line is ticked in the same call that the client
     reports the work with, so two mechanics on one car cannot both spend a
     part on it. ]]
function Orders.Fit(src, data)
    local shop = Store.ByJob(Framework.GetJob(src))
    if not shop then return { ok = false, error = 'You are not a mechanic.' } end

    local row = MySQL.single.await([[
        SELECT *, UNIX_TIMESTAMP(created_at) AS created_at_unix
        FROM xs_mechanic_orders WHERE id = ?
    ]], { data.orderId })

    if not row then return { ok = false, error = 'That order is gone.' } end

    local order = decode(row)
    if order.shopId ~= shop.id then return { ok = false, error = "That is another shop's order." } end
    if order.status == 'done' then return { ok = false, error = 'That one is finished.' } end

    local lid = tonumber(data.lid)
    local found

    for _, line in ipairs(order.requested) do
        if type(line) == 'table' and line.lid == lid then found = line break end
    end

    if not found then return { ok = false, error = 'That line is gone.' } end
    if found.fitted then return { ok = false, error = 'Somebody already fitted that one.' } end

    local item = Orders.ItemFor(shop, found)

    -- A handling package is the server's job from start to finish; the client
    -- has nothing to set for it.
    if found.tuning then
        local result = found.tuning.remove
            and CustomTuning.Remove(src, { shop = shop.id, plate = order.plate, category = found.tuning.category })
            or CustomTuning.FitOff(src, shop, order, found)

        if not result.ok then return result end
    end

    -- Taken last. A part that could not go on is a part you still have.
    if item and not Inventory.Remove(src, item, 1) then
        return { ok = false, error = ('You do not have a %s.'):format(string.lower(Parts.Label(item))) }
    end

    found.fitted = true
    found.fittedBy = Framework.GetCitizenId(src) or ''
    found.fittedAt = os.time()

    save(order.id, order.requested)

    local total, done = Orders.Counts(order)
    local left = total - done

    if left == 0 then
        MySQL.update.await("UPDATE xs_mechanic_orders SET status = 'done' WHERE id = ?", { order.id })

        for _, playerId in ipairs(GetPlayers()) do
            playerId = tonumber(playerId)

            if Framework.GetCitizenId(playerId) == order.customer then
                Framework.Notify(playerId, ('%s have finished with your vehicle.'):format(shop.name), 'success')
                Phone.Notify(playerId, shop.name, 'Your vehicle is ready.')
                break
            end
        end
    end

    Discord.Send('tuning', 'Work fitted',
        ('**%s** fitted %s to `%s` at %s'):format(
            Framework.GetName(src), found.label, order.plate, shop.name),
        Discord.Colour.info)

    TriggerClientEvent('XS-Mechanic:client:refresh', -1)

    return {
        ok = true,
        left = left,
        done = left == 0,
        message = left == 0
            and ('%s on. Order #%d done.'):format(found.label, order.id)
            or ('%s on. %d left on the order.'):format(found.label, left),
    }
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
function Orders.DropLine(src, id, lid)
    local row, err = claimable(src, id)
    if not row then return { ok = false, error = err } end

    if row.status == 'done' then return { ok = false, error = 'That one is finished.' } end

    local lines = relabel(Util.Decode(row.requested, {}) or {})
    lid = tonumber(lid)

    local index, dropped

    for i, line in ipairs(lines) do
        if type(line) == 'table' and line.lid == lid then index, dropped = i, line break end
    end

    if not dropped then return { ok = false, error = 'That line is already gone.' } end
    if dropped.fitted then return { ok = false, error = 'That one is already on the car.' } end

    table.remove(lines, index)
    save(id, lines)

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

-- Closing an order by hand. It closes itself when the last line goes on, so
-- this is for the one the shop cannot finish.
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
