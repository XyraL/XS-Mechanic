Team = {}

function Team.IsBoss(src, shop)
    if not shop or shop.kind ~= 'owned' then return false end
    return Framework.IsBoss(src, shop.job, shop.bossGrade)
end

-- Who gets to decide what the shop charges. The boss always does; below that
-- it is a grade the shop sets for itself, so a senior mechanic can price a job
-- without being handed the money and the staff list as well.
function Team.CanPrice(src, shop)
    if not shop or shop.kind ~= 'owned' then return false end
    if Team.IsBoss(src, shop) then return true end

    local job, _, grade = Framework.GetJob(src)
    if job ~= shop.job then return false end

    return (tonumber(grade) or 0) >= (tonumber(shop.priceGrade) or Config.Jobs.priceGrade)
end

function Team.Staff(shop)
    if not shop or shop.job == '' then return {} end
    return Framework.JobPlayers(shop.job)
end

function Team.OnDuty(shop)
    local count = 0

    for _, person in ipairs(Team.Staff(shop)) do
        if person.onDuty or not Config.Jobs.requireDuty then count = count + 1 end
    end

    return count
end

local function guard(src, shopId)
    local shop = Store.Get(shopId)
    if not shop then return nil, 'That shop is gone.' end

    if not Config.Jobs.manageFromTablet then
        return nil, 'Staff are managed through your boss menu on this server.'
    end

    if not Team.IsBoss(src, shop) then return nil, 'Only the boss can do that.' end

    return shop, nil
end

function Team.Hire(src, targetSrc, shopId)
    local shop, err = guard(src, shopId)
    if not shop then return { ok = false, error = err } end

    targetSrc = tonumber(targetSrc)
    if not targetSrc or targetSrc == src then return { ok = false, error = 'Nobody close enough.' } end

    local mechanic = GetPlayerPed(src)
    local target = GetPlayerPed(targetSrc)

    if not target or target == 0 then return { ok = false, error = 'They are not here.' } end

    -- Proximity is checked on the server as well as the client, or a spoofed
    -- id hires anyone on the map.
    if #(GetEntityCoords(mechanic) - GetEntityCoords(target)) > 6.0 then
        return { ok = false, error = 'Stand next to them.' }
    end

    local existing = Framework.GetJob(targetSrc)
    if existing == shop.job then return { ok = false, error = 'They already work here.' } end

    if not Framework.SetJob(targetSrc, shop.job, 0) then
        return { ok = false, error = 'Your framework refused that.' }
    end

    Framework.Notify(targetSrc, ('You now work at %s.'):format(shop.name), 'success')

    Discord.Send('admin', 'Hired',
        ('**%s** hired **%s** at %s'):format(Framework.GetName(src), Framework.GetName(targetSrc), shop.name),
        Discord.Colour.good)

    return { ok = true, message = ('Hired %s.'):format(Framework.GetName(targetSrc)) }
end

local function findByCitizenId(citizenid)
    for _, playerId in ipairs(GetPlayers()) do
        playerId = tonumber(playerId)
        if Framework.GetCitizenId(playerId) == citizenid then return playerId end
    end
    return nil
end

function Team.Fire(src, citizenid, shopId)
    local shop, err = guard(src, shopId)
    if not shop then return { ok = false, error = err } end

    if citizenid == Framework.GetCitizenId(src) then
        return { ok = false, error = 'You cannot fire yourself.' }
    end

    local targetSrc = findByCitizenId(citizenid)
    if not targetSrc then return { ok = false, error = 'They need to be online.' } end

    local name = Framework.GetName(targetSrc)

    if not Framework.SetJob(targetSrc, 'unemployed', 0) then
        return { ok = false, error = 'Your framework refused that.' }
    end

    Framework.Notify(targetSrc, ('You no longer work at %s.'):format(shop.name), 'error')

    Discord.Send('admin', 'Fired',
        ('**%s** fired **%s** from %s'):format(Framework.GetName(src), name, shop.name),
        Discord.Colour.bad)

    return { ok = true, message = ('Fired %s.'):format(name) }
end

function Team.SetGrade(src, citizenid, grade, shopId)
    local shop, err = guard(src, shopId)
    if not shop then return { ok = false, error = err } end

    local targetSrc = findByCitizenId(citizenid)
    if not targetSrc then return { ok = false, error = 'They need to be online.' } end

    grade = math.max(0, math.floor(tonumber(grade) or 0))

    -- A boss cannot promote anyone above their own grade, themselves included.
    local _, _, own = Framework.GetJob(src)
    if grade > own then return { ok = false, error = 'You cannot promote above your own grade.' } end

    if not Framework.SetJob(targetSrc, shop.job, grade) then
        return { ok = false, error = 'Your framework refused that.' }
    end

    Framework.Notify(targetSrc, ('Your grade at %s changed.'):format(shop.name), 'inform')

    return { ok = true, message = 'Grade set.' }
end

function Team.Money(src, shopId, kind, amount)
    local shop = Store.Get(shopId)
    if not shop then return { ok = false, error = 'That shop is gone.' } end
    if not Team.IsBoss(src, shop) then return { ok = false, error = 'Only the boss can do that.' } end

    if not Banking.LedgerOnly() then
        return { ok = false, error = 'Use your banking resource for that.' }
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return { ok = false, error = 'Enter an amount.' } end

    local name = Framework.GetName(src)

    if kind == 'withdraw' then
        if not Banking.Remove(shop, amount, 'Withdrawn by the boss', name, 'withdraw') then
            return { ok = false, error = 'The shop does not have that.' }
        end

        Framework.AddMoney(src, 'bank', amount, 'Mechanic shop withdrawal')
        return { ok = true, message = ('Withdrew %s.'):format(Util.Money(amount)) }
    end

    if Framework.GetMoney(src, 'bank') < amount then
        return { ok = false, error = 'You do not have that.' }
    end

    Framework.RemoveMoney(src, 'bank', amount, 'Mechanic shop deposit')
    Banking.Add(shop, amount, 'Deposited by the boss', name, 'deposit')

    return { ok = true, message = ('Deposited %s.'):format(Util.Money(amount)) }
end
