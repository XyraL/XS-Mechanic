Banking = { name = nil }

if not IsDuplicityVersion() then return end

local function detect()
    local forced = Config.Bridges.banking
    if forced ~= 'auto' then return forced ~= 'none' and forced or nil end

    if GetResourceState('Renewed-Banking') == 'started' then return 'Renewed-Banking' end
    if GetResourceState('okokBanking') == 'started' then return 'okokBanking' end
    if GetResourceState('qb-banking') == 'started' then return 'qb-banking' end
    if GetResourceState('qb-management') == 'started' then return 'qb-management' end
    if Framework.name == 'qbox' then return 'qbx' end

    return nil
end

Banking.name = detect()

-- With no banking resource the shop keeps its own ledger in
-- xs_mechanic_ledger and the boss moves money from the tablet. The panel is
-- told which of the two it is looking at so it can show the right controls.
function Banking.LedgerOnly()
    return Banking.name == nil
end

local function account(shop)
    return shop.job ~= '' and shop.job or ('xsmech_' .. shop.id)
end

function Banking.Balance(shop)
    if Banking.LedgerOnly() then
        local total = MySQL.scalar.await(
            'SELECT COALESCE(SUM(amount), 0) FROM xs_mechanic_ledger WHERE shop_id = ?', { shop.id })
        return math.floor(tonumber(total) or 0)
    end

    local name = account(shop)
    local balance = 0

    pcall(function()
        if Banking.name == 'Renewed-Banking' then
            balance = exports['Renewed-Banking']:getAccountMoney(name) or 0
        elseif Banking.name == 'okokBanking' then
            balance = exports.okokBanking:GetAccount(name) or 0
        elseif Banking.name == 'qb-banking' then
            balance = exports['qb-banking']:GetAccountBalance(name) or 0
        elseif Banking.name == 'qb-management' then
            balance = exports['qb-management']:GetAccount(name) or 0
        elseif Banking.name == 'qbx' then
            balance = exports.qbx_management:GetAccountBalance(name) or 0
        end
    end)

    return math.floor(tonumber(balance) or 0)
end

local function ledger(shop, amount, kind, note, byName)
    MySQL.insert.await([[
        INSERT INTO xs_mechanic_ledger (shop_id, amount, kind, note, by_name)
        VALUES (?, ?, ?, ?, ?)
    ]], { shop.id, math.floor(amount), kind or 'other', note or '', byName or '' })
end

function Banking.Add(shop, amount, note, byName, kind)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end

    if Banking.LedgerOnly() then
        ledger(shop, amount, kind or 'income', note, byName)
        return true
    end

    local name = account(shop)
    local ok = pcall(function()
        if Banking.name == 'Renewed-Banking' then
            exports['Renewed-Banking']:addAccountMoney(name, amount)
        elseif Banking.name == 'okokBanking' then
            exports.okokBanking:AddMoney(name, amount)
        elseif Banking.name == 'qb-banking' then
            exports['qb-banking']:AddMoney(name, amount)
        elseif Banking.name == 'qb-management' then
            exports['qb-management']:AddMoney(name, amount)
        elseif Banking.name == 'qbx' then
            exports.qbx_management:AddMoney(name, amount)
        end
    end)

    -- The ledger doubles as the shop's history even when a banking resource
    -- holds the actual money, so the Team app has something to show.
    ledger(shop, amount, kind or 'income', note, byName)
    return ok
end

function Banking.Remove(shop, amount, note, byName, kind)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end

    if Banking.Balance(shop) < amount then return false end

    if Banking.LedgerOnly() then
        ledger(shop, -amount, kind or 'expense', note, byName)
        return true
    end

    local name = account(shop)
    local ok = pcall(function()
        if Banking.name == 'Renewed-Banking' then
            exports['Renewed-Banking']:removeAccountMoney(name, amount)
        elseif Banking.name == 'okokBanking' then
            exports.okokBanking:RemoveMoney(name, amount)
        elseif Banking.name == 'qb-banking' then
            exports['qb-banking']:RemoveMoney(name, amount)
        elseif Banking.name == 'qb-management' then
            exports['qb-management']:RemoveMoney(name, amount)
        elseif Banking.name == 'qbx' then
            exports.qbx_management:RemoveMoney(name, amount)
        end
    end)

    if not ok then return false end

    ledger(shop, -amount, kind or 'expense', note, byName)
    return true
end

function Banking.Recent(shop, limit)
    local rows = MySQL.query.await([[
        SELECT amount, kind, note, by_name, UNIX_TIMESTAMP(created_at) AS created_at
        FROM xs_mechanic_ledger WHERE shop_id = ?
        ORDER BY id DESC LIMIT ?
    ]], { shop.id, limit or 25 }) or {}

    local out = {}
    for _, row in ipairs(rows) do
        out[#out + 1] = {
            amount = row.amount,
            kind = row.kind,
            note = row.note,
            byName = row.by_name,
            createdAt = row.created_at,
        }
    end

    return out
end

function Banking.TakenToday(shop)
    local total = MySQL.scalar.await([[
        SELECT COALESCE(SUM(amount), 0) FROM xs_mechanic_ledger
        WHERE shop_id = ? AND amount > 0 AND created_at >= CURDATE()
    ]], { shop.id })

    return math.floor(tonumber(total) or 0)
end
