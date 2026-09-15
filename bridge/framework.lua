-- Patching the registrar rather than each call site gives every NUI callback in
-- the resource two guarantees, including any added later:
--
-- 1. Each handler runs in its own thread. FiveM will not dispatch the next NUI
--    callback while the current one is still yielding, and most handlers here
--    yield on a server round-trip.
-- 2. A nil payload is sent as `false`. cb(nil) sends no response body at all,
--    leaving the page's fetch pending forever. Several callbacks return nil
--    legitimately, and every consumer tests for truthiness, so `false` reads
--    the same to the page and actually resolves.
if not IsDuplicityVersion() and type(RegisterNUICallback) == 'function' then
    local _registerNUI = RegisterNUICallback

    RegisterNUICallback = function(name, handler)
        return _registerNUI(name, function(data, cb)
            CreateThread(function()
                handler(data, function(payload, ...)
                    if payload == nil then payload = false end
                    cb(payload, ...)
                end)
            end)
        end)
    end
end

Framework = { name = nil, core = nil }

local function detect()
    local forced = Config.Bridges.framework
    if forced == 'qbox' or forced == 'qbcore' then return forced end
    if GetResourceState('qbx_core') == 'started' then return 'qbox' end
    if GetResourceState('qb-core') == 'started' then return 'qbcore' end
    return nil
end

Framework.name = detect()

if Framework.name == 'qbcore' then
    Framework.core = exports['qb-core']:GetCoreObject()
elseif not Framework.name then
    print('^1[XS-Mechanic]^0 No supported framework found. Start qbx_core or qb-core before XS-Mechanic.')
end

if IsDuplicityVersion() then
    function Framework.GetPlayer(src)
        if Framework.name == 'qbox' then return exports.qbx_core:GetPlayer(src) end
        if Framework.name == 'qbcore' then return Framework.core.Functions.GetPlayer(src) end
        return nil
    end

    function Framework.GetCitizenId(src)
        local player = Framework.GetPlayer(src)
        return player and player.PlayerData and player.PlayerData.citizenid or nil
    end

    function Framework.GetJob(src)
        local player = Framework.GetPlayer(src)
        local job = player and player.PlayerData and player.PlayerData.job
        if not job then return nil, false, 0 end
        return job.name, job.onduty and true or false, (job.grade and (job.grade.level or job.grade)) or 0
    end

    function Framework.IsBoss(src, jobName, bossGrade)
        local name, _, grade = Framework.GetJob(src)
        if name ~= jobName then return false end

        local player = Framework.GetPlayer(src)
        local job = player and player.PlayerData and player.PlayerData.job
        if job and job.isboss then return true end

        return grade >= (bossGrade or 99)
    end

    function Framework.GetName(src)
        local player = Framework.GetPlayer(src)
        local info = player and player.PlayerData and player.PlayerData.charinfo
        if not info then return GetPlayerName(src) or 'Unknown' end
        return ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
    end

    function Framework.GetNameByCitizenId(citizenid)
        local row = MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ?', { citizenid })
        if not row or not row.charinfo then return citizenid end

        local info = Util.Decode(row.charinfo)
        if not info then return citizenid end

        return ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
    end

    function Framework.AddMoney(src, account, amount, reason)
        local player = Framework.GetPlayer(src)
        if not player then return false end
        return player.Functions.AddMoney(account or 'cash', math.floor(amount), reason or 'XS-Mechanic')
    end

    function Framework.RemoveMoney(src, account, amount, reason)
        local player = Framework.GetPlayer(src)
        if not player then return false end
        return player.Functions.RemoveMoney(account or 'cash', math.floor(amount), reason or 'XS-Mechanic')
    end

    function Framework.GetMoney(src, account)
        local player = Framework.GetPlayer(src)
        local money = player and player.PlayerData and player.PlayerData.money
        return money and money[account or 'cash'] or 0
    end

    -- Everyone currently holding a job, on duty or not. The Team app and the
    -- "is anyone working?" self-service fallback both read this.
    function Framework.JobPlayers(jobName)
        local out = {}
        local players = Framework.name == 'qbox'
            and exports.qbx_core:GetQBPlayers()
            or (Framework.core and Framework.core.Functions.GetQBPlayers()) or {}

        for _, player in pairs(players) do
            local data = player.PlayerData
            local job = data and data.job

            if job and job.name == jobName then
                out[#out + 1] = {
                    source = data.source,
                    citizenid = data.citizenid,
                    name = ('%s %s'):format(data.charinfo and data.charinfo.firstname or '',
                        data.charinfo and data.charinfo.lastname or ''):gsub('^%s+', ''):gsub('%s+$', ''),
                    grade = (job.grade and (job.grade.level or job.grade)) or 0,
                    gradeLabel = job.grade and job.grade.name or '',
                    onDuty = job.onduty and true or false,
                }
            end
        end

        return out
    end

    function Framework.JobExists(jobName)
        if not jobName or jobName == '' then return false end

        local ok, found = pcall(function()
            if Framework.name == 'qbox' then
                return exports.qbx_core:GetJob(jobName) ~= nil
            end
            return Framework.core and Framework.core.Shared and Framework.core.Shared.Jobs
                and Framework.core.Shared.Jobs[jobName] ~= nil
        end)

        return ok and found == true
    end

    function Framework.JobGrades(jobName)
        local out = {}

        pcall(function()
            local job = Framework.name == 'qbox'
                and exports.qbx_core:GetJob(jobName)
                or (Framework.core and Framework.core.Shared and Framework.core.Shared.Jobs
                    and Framework.core.Shared.Jobs[jobName])

            for level, grade in pairs(job and job.grades or {}) do
                out[#out + 1] = {
                    level = tonumber(level) or 0,
                    label = type(grade) == 'table' and (grade.name or grade.label) or tostring(grade),
                }
            end
        end)

        table.sort(out, function(a, b) return a.level < b.level end)
        return out
    end

    function Framework.SetJob(src, jobName, grade)
        local ok = pcall(function()
            if Framework.name == 'qbox' then
                exports.qbx_core:SetPlayerPrimaryJob(src, jobName, tonumber(grade) or 0)
                return
            end

            local player = Framework.GetPlayer(src)
            if player then player.Functions.SetJob(jobName, tonumber(grade) or 0) end
        end)

        return ok
    end

    function Framework.IsAdmin(src)
        local admin = Config.Admin

        if admin.acePermission and admin.acePermission ~= '' then
            if IsPlayerAceAllowed(src, admin.acePermission) then return true end
        end

        for _, group in ipairs(admin.groups or {}) do
            if Framework.name == 'qbox' then
                if exports.qbx_core:HasPermission(src, group) then return true end
            elseif Framework.core and Framework.core.Functions.HasPermission(src, group) then
                return true
            end
        end

        if #(admin.licenses or {}) > 0 then
            for _, identifier in ipairs(GetPlayerIdentifiers(src) or {}) do
                local license = identifier:match('^license2?:(.+)$')
                if license then
                    for _, allowed in ipairs(admin.licenses) do
                        if license == allowed then return true end
                    end
                end
            end
        end

        return false
    end

    -- What the framework thinks a vehicle is worth. Used by percentage pricing,
    -- and it is the reason Config.Pricing.classDefaults exists — an addon car
    -- missing from the shared list has no price here.
    function Framework.VehiclePrice(model)
        model = string.lower(model or '')
        if model == '' then return nil end

        local price

        pcall(function()
            if Framework.name == 'qbox' then
                local list = exports.qbx_core:GetVehiclesByName() or {}
                local entry = list[model]
                price = entry and (entry.price or entry.cost)
                return
            end

            local shared = Framework.core and Framework.core.Shared and Framework.core.Shared.Vehicles
            local entry = shared and shared[model]
            price = entry and (entry.price or entry.cost)
        end)

        return tonumber(price)
    end

    function Framework.Notify(src, message, kind)
        if Config.Notify.style == 'framework' then
            if Framework.name == 'qbox' then
                exports.qbx_core:Notify(src, message, kind or 'inform')
            elseif Framework.core then
                TriggerClientEvent('QBCore:Notify', src, message, kind == 'error' and 'error' or 'success')
            end
            return
        end

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Mechanic',
            description = message,
            type = kind or 'inform',
            position = Config.Notify.position,
        })
    end
else
    function Framework.GetPlayerData()
        if Framework.name == 'qbox' then return exports.qbx_core:GetPlayerData() end
        if Framework.name == 'qbcore' then return Framework.core.Functions.GetPlayerData() end
        return nil
    end

    function Framework.GetJob()
        local data = Framework.GetPlayerData()
        local job = data and data.job
        if not job then return nil, false, 0 end
        return job.name, job.onduty and true or false, (job.grade and (job.grade.level or job.grade)) or 0
    end

    function Framework.GetCitizenId()
        local data = Framework.GetPlayerData()
        return data and data.citizenid or nil
    end

    function Framework.Notify(message, kind)
        if Config.Notify.style == 'framework' then
            if Framework.name == 'qbox' then
                exports.qbx_core:Notify(message, kind or 'inform')
                return
            end
            TriggerEvent('QBCore:Notify', message, kind == 'error' and 'error' or 'success')
            return
        end

        lib.notify({
            title = 'Mechanic',
            description = message,
            type = kind or 'inform',
            position = Config.Notify.position,
        })
    end
end
