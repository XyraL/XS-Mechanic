Store = { shops = {} }

local function decodeShop(row)
    if not row then return nil end

    local data = Util.Decode(row.data, {}) or {}

    return {
        id = row.id,
        name = row.name,
        kind = row.kind,
        job = row.job or '',
        bossGrade = row.boss_grade or Config.Jobs.defaultBossGrade,
        accent = row.accent or 'blue',
        -- TINYINT(1) comes back as a boolean from oxmysql, never as 1.
        enabled = Util.Truthy(row.enabled),
        createdBy = row.created_by,
        points = data.points or {},
        pricing = data.pricing or {},
        categories = data.categories or {},
        parts = data.parts or {},
        commission = data.commission or Config.Invoices.defaultCommission,
        selfServiceWhenEmpty = data.selfServiceWhenEmpty ~= false,
        blip = data.blip or { enabled = true, sprite = 446, colour = 47, scale = 0.7 },
        bounds = data.bounds,
    }
end

local function encodeShop(shop)
    return json.encode({
        points = shop.points or {},
        pricing = shop.pricing or {},
        categories = shop.categories or {},
        parts = shop.parts or {},
        commission = shop.commission,
        selfServiceWhenEmpty = shop.selfServiceWhenEmpty,
        blip = shop.blip,
        bounds = shop.bounds,
    })
end

function Store.Load()
    local rows = MySQL.query.await('SELECT * FROM xs_mechanic_shops') or {}

    Store.shops = {}
    for _, row in ipairs(rows) do
        local shop = decodeShop(row)
        if shop then Store.shops[shop.id] = shop end
    end

    return Store.shops
end

function Store.All()
    local out = {}
    for _, shop in pairs(Store.shops) do out[#out + 1] = shop end
    table.sort(out, function(a, b) return (a.name or '') < (b.name or '') end)
    return out
end

-- What clients are allowed to know: where the points are and what each one
-- does. Pricing and the parts list stay server side until something asks.
function Store.Public()
    local out = {}

    for _, shop in pairs(Store.shops) do
        if shop.enabled then
            out[#out + 1] = Util.Plain({
                id = shop.id,
                name = shop.name,
                kind = shop.kind,
                job = shop.job,
                accent = shop.accent,
                points = shop.points,
                blip = shop.blip,
                bounds = shop.bounds,
                categories = shop.categories,
                selfServiceWhenEmpty = shop.selfServiceWhenEmpty,
            })
        end
    end

    return out
end

function Store.Get(id)
    return Store.shops[tonumber(id) or 0]
end

function Store.ByJob(jobName)
    if not jobName or jobName == '' then return nil end

    for _, shop in pairs(Store.shops) do
        if shop.job == jobName and shop.enabled then return shop end
    end

    return nil
end

function Store.Create(shop, createdBy)
    -- MySQL.prepare returns nil for the new row id, which then blows up as a
    -- nil table index somewhere unrelated. insert is the one that answers.
    local id = MySQL.insert.await([[
        INSERT INTO xs_mechanic_shops (name, kind, job, boss_grade, accent, enabled, data, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        shop.name, shop.kind, shop.job or '', shop.bossGrade or Config.Jobs.defaultBossGrade,
        shop.accent or 'blue', shop.enabled == false and 0 or 1, encodeShop(shop), createdBy,
    })

    if not id then return nil end

    shop.id = id
    Store.shops[id] = shop
    return id
end

function Store.Update(id, shop)
    id = tonumber(id)
    if not id or not Store.shops[id] then return false end

    MySQL.update.await([[
        UPDATE xs_mechanic_shops
        SET name = ?, kind = ?, job = ?, boss_grade = ?, accent = ?, enabled = ?, data = ?
        WHERE id = ?
    ]], {
        shop.name, shop.kind, shop.job or '', shop.bossGrade or Config.Jobs.defaultBossGrade,
        shop.accent or 'blue', shop.enabled == false and 0 or 1, encodeShop(shop), id,
    })

    shop.id = id
    Store.shops[id] = shop
    return true
end

function Store.Delete(id)
    id = tonumber(id)
    if not id or not Store.shops[id] then return false end

    MySQL.query.await('DELETE FROM xs_mechanic_shops WHERE id = ?', { id })
    Store.shops[id] = nil
    return true
end

function Store.SetEnabled(id, enabled)
    id = tonumber(id)
    local shop = Store.shops[id]
    if not shop then return false end

    shop.enabled = enabled and true or false
    MySQL.update.await('UPDATE xs_mechanic_shops SET enabled = ? WHERE id = ?', { enabled and 1 or 0, id })
    return true
end

-- Every point in every shop, flattened, so a client can ask "what am I stood
-- in?" without walking the whole tree.
function Store.PointsOfKind(kind)
    local out = {}

    for _, shop in pairs(Store.shops) do
        if shop.enabled then
            for _, point in ipairs(shop.points or {}) do
                if point.kind == kind then
                    out[#out + 1] = { shop = shop, point = point }
                end
            end
        end
    end

    return out
end

function Store.Broadcast()
    TriggerClientEvent('XS-Mechanic:client:shops', -1, Store.Public())
end
