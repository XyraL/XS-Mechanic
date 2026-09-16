local function shopFor(src, shopId)
    if shopId then
        local shop = Store.Get(shopId)
        if shop then return shop end
    end

    local job = Framework.GetJob(src)
    return Store.ByJob(job)
end

-- A bay is open to anyone at a self-service shop, and at an owned shop only
-- while none of its staff are working — which is the same rule the target
-- options use client side.
local function selfServiceAllowed(shop)
    if not shop or not shop.enabled then return false end
    if shop.kind ~= 'owned' then return true end
    if shop.selfServiceWhenEmpty == false then return false end

    return Team.OnDuty(shop) == 0
end

local function settings(src)
    local citizenid = Framework.GetCitizenId(src)
    if not citizenid then return {} end

    local row = MySQL.single.await('SELECT settings FROM xs_mechanic_players WHERE citizenid = ?', { citizenid })
    return Util.Decode(row and row.settings, {}) or {}
end

local function colourTable()
    -- The game's colour list is fixed, so it is built once and reused. Only the
    -- ones a mechanic would actually reach for are offered by name; custom RGB
    -- covers everything else.
    return {
        { id = 0, label = 'Black', hex = '#0d0d0d' }, { id = 1, label = 'Graphite', hex = '#1c1c1e' },
        { id = 2, label = 'Anthracite', hex = '#26282b' }, { id = 3, label = 'Steel', hex = '#3d4249' },
        { id = 4, label = 'Silver', hex = '#9ba1a8' }, { id = 5, label = 'Bluish Silver', hex = '#aab6c4' },
        { id = 9, label = 'Gunmetal', hex = '#40474d' }, { id = 11, label = 'Black Steel', hex = '#232c35' },
        { id = 27, label = 'Red', hex = '#c00e1a' }, { id = 28, label = 'Torino Red', hex = '#da1918' },
        { id = 29, label = 'Formula Red', hex = '#b6111b' }, { id = 34, label = 'Sunrise Orange', hex = '#d44f2a' },
        { id = 36, label = 'Orange', hex = '#f78616' }, { id = 38, label = 'Gold', hex = '#c2a661' },
        { id = 42, label = 'Bright Green', hex = '#31a02c' }, { id = 49, label = 'Dark Green', hex = '#132428' },
        { id = 53, label = 'Lime', hex = '#aad13a' }, { id = 55, label = 'Midnight Blue', hex = '#222e46' },
        { id = 64, label = 'Navy', hex = '#1f2852' }, { id = 70, label = 'Ultra Blue', hex = '#224faa' },
        { id = 73, label = 'Racing Blue', hex = '#2c5f9a' }, { id = 77, label = 'Bright Blue', hex = '#2354a1' },
        { id = 88, label = 'Yellow', hex = '#f1d80a' }, { id = 89, label = 'Race Yellow', hex = '#fcf04c' },
        { id = 96, label = 'Brown', hex = '#3b2e2a' }, { id = 106, label = 'Beige', hex = '#a8a086' },
        { id = 111, label = 'White', hex = '#ffffff' }, { id = 112, label = 'Frost White', hex = '#eaeaea' },
        { id = 117, label = 'Brushed Steel', hex = '#6f7f85' }, { id = 120, label = 'Pure Gold', hex = '#b3a04a' },
        { id = 132, label = 'Chameleon', hex = '#7c5cd6' },
    }
end

local function stateFor(src, mode, shopId)
    local shop = shopFor(src, shopId)
    local job, onDuty = Framework.GetJob(src)

    local state = {
        name = Framework.GetName(src),
        onDuty = onDuty,
        settings = settings(src),
        colours = colourTable(),
        levelMultiplier = Config.Pricing.levelMultiplier,
        pricingMode = Config.Pricing.mode,
        partsPaidBy = Config.Parts.paidBy,
        serviceEnabled = Config.Service.enabled,
        livePreview = Config.Tablet.livePreview,
        tuningEnabled = Config.CustomTuning.enabled,
        dynoEnabled = Config.Dyno.enabled,
        stanceLimits = { height = 0.30, camber = 0.35, track = 0.25 },
        manageJobs = Config.Jobs.manageFromTablet,
        ledgerOnly = Banking.LedgerOnly(),
        kits = {},
        shops = {},
        invoice = Invoices.Draft(src),
    }

    for item, kit in pairs(Config.Repair.kits) do
        if kit then
            state.kits[#state.kits + 1] = {
                item = item, label = kit.label,
                engine = kit.engine, body = kit.body,
                held = Inventory.Count(src, item),
            }
        end
    end

    table.sort(state.kits, function(a, b) return a.label < b.label end)

    if mode == 'builder' then
        for _, entry in ipairs(Store.All()) do
            state.shops[#state.shops + 1] = {
                id = entry.id, name = entry.name, kind = entry.kind,
                job = entry.job, enabled = entry.enabled,
            }
        end

        return state
    end

    if not shop then return state end

    state.shop = { id = shop.id, name = shop.name, kind = shop.kind, job = shop.job }
    state.commission = shop.commission
    state.categories = shop.categories
    state.isBoss = Team.IsBoss(src, shop)
    state.grades = Framework.JobGrades(shop.job)
    state.staff = Team.Staff(shop)
    state.prices = Pricing.Sheet(shop, nil, nil)

    local counts = Invoices.Counts(shop.id)

    state.unpaid = counts.unpaid
    state.openOrders = Orders.OpenCount(shop.id)
    state.invoices = Invoices.ForShop(shop.id)
    state.orders = Orders.ForShop(shop.id)

    state.summary = {
        today = Banking.TakenToday(shop),
        jobs = counts.jobs,
        unpaid = counts.unpaid,
        unpaidTotal = counts.unpaidTotal,
        orders = state.openOrders,
        onDuty = Team.OnDuty(shop),
        staff = #state.staff,
        funds = Banking.Balance(shop),
        earned = 0,
    }

    -- The bay only offers "pay and fit now" where self service is genuinely
    -- allowed; otherwise the customer's only route is an order to the shop.
    state.selfService = selfServiceAllowed(shop)
    state.staffOnline = Team.OnDuty(shop)
    state.takesOrders = shop.kind == 'owned' and Team.OnDuty(shop) > 0

    state.ledger = Banking.Recent(shop, 25)
    state.counters = {}

    for _, point in ipairs(shop.points or {}) do
        if point.kind == 'counter' then
            state.counters[#state.counters + 1] = {
                id = point.id,
                label = point.label or 'Parts counter',
                near = true,
                items = #(shop.parts or {}) > 0 and shop.parts or Config.Parts,
            }
        end
    end

    return state
end

lib.callback.register('XS-Mechanic:bootstrap', function(src, data)
    local mode = data and data.mode or 'tablet'

    if mode == 'builder' then
        if not Framework.IsAdmin(src) then return { ok = false, error = 'You are not allowed to do that.' } end
        return { ok = true, state = Util.Plain(stateFor(src, mode)) }
    end

    if mode == 'tablet' or mode == 'desk' then
        if Config.Tablet.item ~= '' and not Inventory.Has(src, Config.Tablet.item, 1) then
            return { ok = false, error = 'You need a mechanic tablet.' }
        end

        local shop = shopFor(src, data and data.shop)
        if not shop then return { ok = false, error = 'You do not work at a shop.' } end

        local job = Framework.GetJob(src)
        if shop.kind == 'owned' and job ~= shop.job then
            return { ok = false, error = 'Not your shop.' }
        end
    end

    return { ok = true, state = Util.Plain(stateFor(src, mode, data and data.shop)) }
end)

lib.callback.register('XS-Mechanic:state', function(src, data)
    return Util.Plain(stateFor(src, data and data.mode or 'tablet', data and data.shop))
end)

lib.callback.register('XS-Mechanic:shops', function()
    return Store.Public()
end)

lib.callback.register('XS-Mechanic:vehicle', function(src, data)
    return Util.Plain(Vehicles.Summary(data and data.plate, data and data.model))
end)

lib.callback.register('XS-Mechanic:jobExists', function(_, data)
    return Framework.JobExists(data and data.job)
end)

lib.callback.register('XS-Mechanic:shop', function(src, data)
    if not Framework.IsAdmin(src) then return { ok = false, error = 'You are not allowed to do that.' } end

    local shop = Store.Get(data and data.id)
    if not shop then return { ok = false, error = 'That shop is gone.' } end

    return { ok = true, shop = Util.Plain(shop) }
end)

lib.callback.register('XS-Mechanic:saveShop', function(src, data)
    if not Framework.IsAdmin(src) then return { ok = false, error = 'You are not allowed to do that.' } end

    local draft = data and data.shop
    if not draft then return { ok = false, error = 'Nothing to save.' } end

    draft.name = Util.Trim(tostring(draft.name or '')):sub(1, 64)
    if draft.name == '' then return { ok = false, error = 'Give it a name.' } end

    draft.job = Util.Trim(tostring(draft.job or '')):sub(1, 64)
    draft.kind = draft.kind == 'self' and 'self' or 'owned'

    if draft.kind == 'owned' and draft.job == '' then
        return { ok = false, error = 'An owned shop needs a job name.' }
    end

    local id = draft.id

    if id then
        if not Store.Update(id, draft) then return { ok = false, error = 'That shop is gone.' } end
    else
        id = Store.Create(draft, Framework.GetCitizenId(src))
        if not id then return { ok = false, error = 'Could not write that shop.' } end
    end

    Store.Broadcast()

    Discord.Send('admin', draft.id and 'Shop edited' or 'Shop created',
        ('**%s** %s **%s** (job `%s`)'):format(
            Framework.GetName(src), draft.id and 'edited' or 'created', draft.name,
            draft.job ~= '' and draft.job or 'self service'),
        Discord.Colour.info)

    return { ok = true, id = id }
end)

lib.callback.register('XS-Mechanic:toggleShop', function(src, data)
    if not Framework.IsAdmin(src) then return { ok = false } end

    local shop = Store.Get(data and data.id)
    if not shop then return { ok = false } end

    Store.SetEnabled(shop.id, not shop.enabled)
    Store.Broadcast()

    return { ok = true, enabled = shop.enabled }
end)

lib.callback.register('XS-Mechanic:deleteShop', function(src, data)
    if not Framework.IsAdmin(src) then return { ok = false, error = 'You are not allowed to do that.' } end

    local shop = Store.Get(data and data.id)
    if not shop then return { ok = false, error = 'That shop is gone.' } end

    local name = shop.name
    Store.Delete(shop.id)
    Store.Broadcast()

    Discord.Send('admin', 'Shop deleted',
        ('**%s** deleted **%s**'):format(Framework.GetName(src), name), Discord.Colour.bad)

    return { ok = true }
end)

-- Fitting something. The price is worked out here, never taken from the panel.
lib.callback.register('XS-Mechanic:apply', function(src, data)
    local shop = shopFor(src, data and data.shop)
    if not shop then return { ok = false, error = 'No shop.' } end

    local category = tostring(data.category or '')
    if not Pricing.CategoryEnabled(shop, category) then
        return { ok = false, error = 'This shop does not do that.' }
    end

    local price = Pricing.For(shop, category, data.model, data.class, data.index) or 0
    local label = tostring(data.label or 'Part'):sub(1, 64)

    if data.mode == 'bay' then
        local account = Config.SelfService.account

        if Framework.GetMoney(src, account) < price then
            return { ok = false, error = ('You need %s.'):format(Util.Money(price)) }
        end

        Framework.RemoveMoney(src, account, price, 'Mechanic')
        Banking.Add(shop, price, ('Self service — %s'):format(label), Framework.GetName(src), 'selfservice')

        Discord.Send('tuning', 'Self service',
            ('**%s** fitted %s at %s for %s'):format(Framework.GetName(src), label, shop.name, Util.Money(price)),
            Discord.Colour.info)

        return { ok = true, message = ('Fitted for %s.'):format(Util.Money(price)) }
    end

    local job = Framework.GetJob(src)
    if shop.kind == 'owned' and job ~= shop.job then
        return { ok = false, error = 'Not your shop.' }
    end

    if settings(src).autoDraft ~= false and Config.Invoices.autoDraft then
        Invoices.AddLine(src, label, price, Mods.CategoryLabel[category] or category)
    end

    Discord.Send('tuning', 'Work applied',
        ('**%s** fitted %s to `%s` at %s'):format(
            Framework.GetName(src), label, data.plate or '??', shop.name),
        Discord.Colour.info)

    return { ok = true, message = 'Fitted and added to the invoice.' }
end)

lib.callback.register('XS-Mechanic:repairQuote', function(src, data)
    local shop = Store.Get(data and data.shop)
    if not shop then return { ok = false, error = 'No shop.' } end

    if not Pricing.CategoryEnabled(shop, 'repair') then
        return { ok = false, error = 'This shop does not do repairs.' }
    end

    return { ok = true, price = Pricing.For(shop, 'repair', data.model, data.class, 0) or 0 }
end)

lib.callback.register('XS-Mechanic:kitCheck', function(src, data)
    local item = tostring(data and data.item or '')
    local kit = Config.Repair.kits[item]

    if not kit then return { ok = false, error = 'Unknown item.' } end
    if not Inventory.Has(src, item, 1) then return { ok = false, error = 'You do not have one.' } end

    return { ok = true }
end)

lib.callback.register('XS-Mechanic:repair', function(src, data)
    if data.how == 'kit' then
        local item = tostring(data.item or '')
        local kit = Config.Repair.kits[item]

        if not kit then return { ok = false, error = 'Unknown item.' } end
        if not Inventory.Remove(src, item, 1) then return { ok = false, error = 'You do not have one.' } end

        return { ok = true }
    end

    local shop = Store.Get(data and data.shop)
    if not shop then return { ok = false, error = 'No shop.' } end

    local price = math.floor(tonumber(data.price) or 0)
    local job = Framework.GetJob(src)
    local isStaff = shop.kind == 'owned' and job == shop.job

    if isStaff then
        Invoices.AddLine(src, 'Full repair', price, 'Repair')
        return { ok = true }
    end

    local account = Config.SelfService.account

    if Framework.GetMoney(src, account) < price then
        return { ok = false, error = ('You need %s.'):format(Util.Money(price)) }
    end

    Framework.RemoveMoney(src, account, price, 'Mechanic repair')
    Banking.Add(shop, price, 'Repair', Framework.GetName(src), 'repair')

    return { ok = true }
end)

lib.callback.register('XS-Mechanic:sendInvoice', function(src, data)
    local shop = shopFor(src, data and data.shop)
    if not shop then return { ok = false, error = 'No shop.' } end

    return Invoices.Send(src, shop, data and data.plate, false)
end)

lib.callback.register('XS-Mechanic:saveInvoice', function(src, data)
    local shop = shopFor(src, data and data.shop)
    if not shop then return { ok = false, error = 'No shop.' } end

    return Invoices.Send(src, shop, data and data.plate, true)
end)

lib.callback.register('XS-Mechanic:resendInvoice', function(src, data)
    return Invoices.Resend(src, data and data.id)
end)

lib.callback.register('XS-Mechanic:dropLine', function(src, data)
    Invoices.DropLine(src, data and data.index)
    return { ok = true }
end)



lib.callback.register('XS-Mechanic:myInvoices', function(src)
    local citizenid = Framework.GetCitizenId(src)
    if not citizenid then return { invoices = {} } end

    return { invoices = Util.Plain(Invoices.ForCustomer(citizenid)) }
end)

lib.callback.register('XS-Mechanic:buyPart', function(src, data)
    local shop = shopFor(src)
    if not shop then return { ok = false, error = 'No shop.' } end

    local job = Framework.GetJob(src)
    if shop.kind == 'owned' and job ~= shop.job then return { ok = false, error = 'Not your shop.' } end

    local list = #(shop.parts or {}) > 0 and shop.parts or Config.Parts
    local wanted = tostring(data and data.item or '')
    local amount = math.max(1, math.min(50, math.floor(tonumber(data and data.amount) or 1)))

    local part
    for _, entry in ipairs(list) do
        if entry.item == wanted then part = entry break end
    end

    if not part then return { ok = false, error = 'That is not stocked here.' } end

    local cost = part.price * amount

    if Config.Parts.paidBy == 'society' then
        if not Banking.Remove(shop, cost, ('Parts — %dx %s'):format(amount, part.label), Framework.GetName(src), 'parts') then
            return { ok = false, error = 'The shop cannot cover that.' }
        end
    else
        if Framework.GetMoney(src, 'bank') < cost then
            return { ok = false, error = ('You need %s.'):format(Util.Money(cost)) }
        end

        Framework.RemoveMoney(src, 'bank', cost, 'Mechanic parts')
    end

    if not Inventory.Add(src, part.item, amount) then
        if Config.Parts.paidBy == 'society' then
            Banking.Add(shop, cost, 'Parts refunded', Framework.GetName(src), 'refund')
        else
            Framework.AddMoney(src, 'bank', cost, 'Mechanic parts refund')
        end

        return { ok = false, error = 'No room for that.' }
    end

    return { ok = true, message = ('Bought %dx %s.'):format(amount, part.label) }
end)

lib.callback.register('XS-Mechanic:leaveOrder', function(src, data)
    return Orders.Leave(src, data or {})
end)

lib.callback.register('XS-Mechanic:claimOrder', function(src, data)
    return Orders.Claim(src, data and data.id)
end)

lib.callback.register('XS-Mechanic:finishOrder', function(src, data)
    return Orders.Finish(src, data and data.id)
end)

lib.callback.register('XS-Mechanic:hire', function(src, data)
    local shop = shopFor(src)
    if not shop then return { ok = false, error = 'No shop.' } end

    return Team.Hire(src, data and data.target, shop.id)
end)

lib.callback.register('XS-Mechanic:fire', function(src, data)
    local shop = shopFor(src)
    if not shop then return { ok = false, error = 'No shop.' } end

    return Team.Fire(src, data and data.citizenid, shop.id)
end)

lib.callback.register('XS-Mechanic:setGrade', function(src, data)
    local shop = shopFor(src)
    if not shop then return { ok = false, error = 'No shop.' } end

    return Team.SetGrade(src, data and data.citizenid, data and data.grade, shop.id)
end)

lib.callback.register('XS-Mechanic:shopMoney', function(src, data)
    local shop = shopFor(src)
    if not shop then return { ok = false, error = 'No shop.' } end

    return Team.Money(src, shop.id, data and data.kind, data and data.amount)
end)

RegisterNetEvent('XS-Mechanic:server:payInvoice', function(id, account)
    Invoices.Pay(source, id, account)
end)

RegisterNetEvent('XS-Mechanic:server:settings', function(key, value)
    local src = source
    local citizenid = Framework.GetCitizenId(src)
    if not citizenid then return end

    local allowed = {
        accent = true, hud = true, hudRight = true, sounds = true, autoDraft = true,
    }

    if not allowed[key] then return end

    local current = settings(src)
    current[key] = value

    MySQL.query.await([[
        INSERT INTO xs_mechanic_players (citizenid, settings) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE settings = VALUES(settings)
    ]], { citizenid, json.encode(current) })
end)

RegisterNetEvent('XS-Mechanic:server:duty', function(shopId)
    local src = source
    local shop = Store.Get(shopId)
    if not shop then return end

    local job = Framework.GetJob(src)
    if job ~= shop.job then return end

    if Framework.name == 'qbox' then
        exports.qbx_core:ToggleDuty(src)
    else
        TriggerClientEvent('QBCore:ToggleDuty', src)
    end
end)

-- The client owns the vehicle entity, so it is the only side that can read the
-- fitted mods back off it. Written to the framework's own column.
RegisterNetEvent('XS-Mechanic:server:saveMods', function(netId)
    local src = source
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    local plate = Util.Trim(GetVehicleNumberPlateText(entity) or '')
    if plate == '' then return end

    local owned = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    if not owned then return end

    TriggerClientEvent('XS-Mechanic:client:readMods', src, netId)
end)

RegisterNetEvent('XS-Mechanic:server:storeMods', function(plate, props)
    plate = Util.Trim(plate or '')
    if plate == '' or type(props) ~= 'table' then return end

    MySQL.update.await('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(props), plate })
end)

lib.callback.register('XS-Mechanic:serviceCheck', function(src, data)
    if not Config.Service.enabled then
        return { ok = false, error = 'Servicing is off on this server.' }
    end

    local part = Service.ById[data and data.part or '']
    if not part then return { ok = false, error = 'Unknown part.' } end

    local quantity = part.quantity or 1

    if not Inventory.Has(src, part.item, quantity) then
        return { ok = false, error = ('You need %dx %s.'):format(quantity, part.label) }
    end

    return { ok = true }
end)

lib.callback.register('XS-Mechanic:serviceReplace', function(src, data)
    local shop = shopFor(src, data and data.shop)
    return Servicing.Replace(src, Util.Trim(data and data.plate or ''), data and data.part, shop)
end)

lib.callback.register('XS-Mechanic:fitTuning', function(src, data)
    return CustomTuning.Fit(src, data or {})
end)

lib.callback.register('XS-Mechanic:removeTuning', function(src, data)
    return CustomTuning.Remove(src, data or {})
end)

lib.callback.register('XS-Mechanic:saveStance', function(src, data)
    return CustomTuning.SaveStance(src, data or {})
end)

lib.callback.register('XS-Mechanic:dynoCheck', function(src, data)
    if not Config.Dyno.enabled then return { ok = false, error = 'No dyno on this server.' } end

    local shop = shopFor(src, data and data.shop)
    if not shop then return { ok = false, error = 'No shop.' } end

    local job = Framework.GetJob(src)
    if shop.kind == 'owned' and job ~= shop.job then
        return { ok = false, error = 'Not your shop.' }
    end

    return { ok = true }
end)

-- A dyno sheet goes to whoever is stood nearby, which is how a mechanic shows
-- a customer what they just paid for.
RegisterNetEvent('XS-Mechanic:server:shareDyno', function(sheet)
    local src = source

    if type(sheet) ~= 'table' or type(sheet.stats) ~= 'table' then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local coords = GetEntityCoords(ped)

    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        local other = GetPlayerPed(id)

        if other and other ~= 0 and #(coords - GetEntityCoords(other)) <= 12.0 then
            TriggerClientEvent('XS-Mechanic:client:dynoSheet', id, sheet)
        end
    end
end)

lib.callback.register('XS-Mechanic:pricePick', function(src, data)
    local shop = shopFor(src, data and data.shop)
    local category = tostring(data and data.category or '')

    return {
        label = Mods.CategoryLabel[category] or category,
        price = shop and Pricing.For(shop, category, data.model, data.class, data.index) or 0,
    }
end)

-- A customer's order. Every price is worked out again here; the panel's
-- numbers are for the customer to look at, not for the server to trust.
lib.callback.register('XS-Mechanic:submitOrder', function(src, data)
    local shop = Store.Get(data and data.shop)
    if not shop or not shop.enabled then return { ok = false, error = 'That shop is closed.' } end

    local picks = type(data.picks) == 'table' and data.picks or {}
    if #picks == 0 then return { ok = false, error = 'Nothing on the order.' } end
    if #picks > 40 then return { ok = false, error = 'That is too much for one order.' } end

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

    return Orders.Leave(src, {
        shop = shop.id,
        plate = data.plate,
        model = data.model,
        requested = priced,
        notes = data.notes,
        quote = total,
    })
end)

-- Paying on the spot. Only where self service is actually allowed, and the
-- total is worked out here rather than taken from the panel.
lib.callback.register('XS-Mechanic:checkout', function(src, data)
    local shop = Store.Get(data and data.shop)
    if not shop or not shop.enabled then return { ok = false, error = 'That shop is closed.' } end

    if not selfServiceAllowed(shop) then
        return { ok = false, error = 'Somebody is working. Leave it with them.' }
    end

    local picks = type(data.picks) == 'table' and data.picks or {}
    if #picks == 0 then return { ok = false, error = 'Nothing picked.' } end

    local total = 0

    for _, pick in ipairs(picks) do
        local category = tostring(pick.category or '')

        if Pricing.CategoryEnabled(shop, category) then
            total = total + (Pricing.For(shop, category, data.model, data.class, pick.index) or 0)
        end
    end

    local account = Config.SelfService.account

    if Framework.GetMoney(src, account) < total then
        return { ok = false, error = ('You need %s.'):format(Util.Money(total)) }
    end

    Framework.RemoveMoney(src, account, total, 'Mechanic')
    Banking.Add(shop, total, 'Self service', Framework.GetName(src), 'selfservice')

    Discord.Send('tuning', 'Self service',
        ('**%s** fitted %d thing(s) at %s for %s'):format(
            Framework.GetName(src), #picks, shop.name, Util.Money(total)),
        Discord.Colour.info)

    return { ok = true, message = ('Paid %s.'):format(Util.Money(total)) }
end)

lib.callback.register('XS-Mechanic:jobs', function(src)
    if not Framework.IsAdmin(src) then return {} end
    return Framework.JobList()
end)
