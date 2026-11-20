Banking = { name = nil }

if not IsDuplicityVersion() then return end

--[[ No Qbox fallback. qbx_management exports the boss menu and nothing to
     do with money — Qbox keeps society money in Renewed-Banking — so a Qbox
     server without a banking resource used to pick an API that was not
     there. Every call failed inside a pcall: the balance read 0 so the shop
     could never spend, and deposits went nowhere. With nothing to bank with,
     the shop keeps its own ledger, which is what that case is for. ]]
local SUPPORTED = { 'Renewed-Banking', 'okokBanking', 'qb-banking', 'qb-management' }

local function setting()
    return Config.Bridges and Config.Bridges.banking or 'auto'
end

function Banking.Detect()
    local forced = setting()
    if forced == 'none' then
        Banking.name = nil
    elseif forced ~= 'auto' and forced ~= 'qbx' then
        Banking.name = forced
    else
        Banking.name = nil
        for _, resource in ipairs(SUPPORTED) do
            if GetResourceState(resource) == 'started' then Banking.name = resource break end
        end
    end
    return Banking.name
end

function Banking.Ready()
    if not Banking.name then Banking.Detect() end
    return Banking.name ~= nil
end

Banking.Detect()

AddEventHandler('onResourceStart', function(resource)
    if Banking.name then return end
    for _, name in ipairs(SUPPORTED) do
        if name == resource then
            Banking.Detect()
            if Banking.name then print(('^2[XS-Mechanic]^0 banking found: %s.'):format(Banking.name)) end
            return
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == Banking.name and setting() ~= Banking.name then Banking.name = nil end
end)

-- With no banking resource the shop keeps its own ledger in
-- xs_mechanic_ledger and the boss moves money from the tablet. The panel is
-- told which of the two it is looking at so it can show the right controls.
function Banking.LedgerOnly()
    return not Banking.Ready()
end

local function account(shop)
    return shop.job ~= '' and shop.job or ('xsmech_' .. shop.id)
end

--[[ Renewed-Banking and qb-banking make an account for every framework job
     when they start, and for nothing else. A shop with no job banks as
     xsmech_<id>, and a job added later has no account either — and both
     refuse a deposit to an account they do not have by RETURNING false, not
     by throwing. The pcall around them never noticed, so the money from a
     paid invoice went nowhere. ]]
local function ensureAccount(shop, name)
    if Banking.name == 'Renewed-Banking' then
        if exports['Renewed-Banking']:getAccountMoney(name) == false then
            exports['Renewed-Banking']:CreateJobAccount({ name = name, label = (shop.name and shop.name ~= '') and shop.name or name }, 0)
        end
    elseif Banking.name == 'qb-banking' then
        if not exports['qb-banking']:GetAccount(name) then
            exports['qb-banking']:CreateJobAccount(name, 0)
        end
    end
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
        end
    end)

    return math.floor(tonumber(balance) or 0)
end

-- What the banking resource itself said, rather than only whether the call
-- threw. Renewed-Banking and qb-banking answer false for a refusal; okokBanking
-- and the old qb-management document no return value, so for those getting
-- through without an error is the only answer there is.
local function moved(ok, result)
    if not ok then return false end
    if Banking.name == 'Renewed-Banking' or Banking.name == 'qb-banking' then
        return result ~= false and result ~= nil
    end
    return true
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
    local ok = moved(pcall(function()
        ensureAccount(shop, name)

        if Banking.name == 'Renewed-Banking' then
            return exports['Renewed-Banking']:addAccountMoney(name, amount)
        elseif Banking.name == 'okokBanking' then
            return exports.okokBanking:AddMoney(name, amount)
        elseif Banking.name == 'qb-banking' then
            return exports['qb-banking']:AddMoney(name, amount, note)
        elseif Banking.name == 'qb-management' then
            return exports['qb-management']:AddMoney(name, amount)
        end
    end))

    -- Written as income only when the money actually landed. It used to be
    -- written either way, so the shop's history showed deposits the bank had
    -- turned down.
    if not ok then
        print(('^1[XS-Mechanic]^0 %s refused %s into account "%s" (%s).'):format(
            Banking.name, Util.Money(amount), name, note or kind or 'deposit'))
        return false
    end

    ledger(shop, amount, kind or 'income', note, byName)
    return true
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
    local ok = moved(pcall(function()
        if Banking.name == 'Renewed-Banking' then
            return exports['Renewed-Banking']:removeAccountMoney(name, amount)
        elseif Banking.name == 'okokBanking' then
            return exports.okokBanking:RemoveMoney(name, amount)
        elseif Banking.name == 'qb-banking' then
            return exports['qb-banking']:RemoveMoney(name, amount, note)
        elseif Banking.name == 'qb-management' then
            return exports['qb-management']:RemoveMoney(name, amount)
        end
    end))

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
