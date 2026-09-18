Vehicles = {}

local cache = {}

--[[ Two stores, one rule.

     Anything lib.getVehicleProperties carries — every cosmetic and every stock
     performance mod — belongs to the framework's own player_vehicles.mods
     column, which every QB/QBox garage already re-applies. There is nothing to
     integrate and nothing to fight over.

     Everything that column cannot hold lives here: part wear, odometer, and
     later the performance package and stance. It is keyed by plate and pushed
     to clients as a state bag, so it survives any garage or spawner without a
     hook into either. ]]

local function decode(row)
    return {
        plate = row.plate,
        model = row.model,
        odometer = tonumber(row.odometer) or 0,
        service = Util.Decode(row.service, {}) or {},
        performance = Util.Decode(row.performance, {}) or {},
        stance = Util.Decode(row.stance, {}) or {},
    }
end

local function blank(plate, model)
    return {
        plate = plate,
        model = model or '',
        odometer = 0,
        service = {},
        performance = {},
        stance = {},
    }
end

function Vehicles.Profile(plate, model)
    plate = Util.Trim(plate or '')
    if plate == '' then return nil end

    if cache[plate] then return cache[plate] end

    local row = MySQL.single.await('SELECT * FROM xs_mechanic_vehicles WHERE plate = ?', { plate })
    local profile = row and decode(row) or blank(plate, model)

    cache[plate] = profile
    return profile
end

function Vehicles.Save(profile)
    if not profile or not profile.plate or profile.plate == '' then return end

    MySQL.query.await([[
        INSERT INTO xs_mechanic_vehicles (plate, model, odometer, service, performance, stance)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            model = VALUES(model), odometer = VALUES(odometer),
            service = VALUES(service), performance = VALUES(performance),
            stance = VALUES(stance)
    ]], {
        profile.plate, profile.model or '', profile.odometer or 0,
        json.encode(profile.service or {}),
        json.encode(profile.performance or {}),
        json.encode(profile.stance or {}),
    })

    cache[profile.plate] = profile
end

-- What the client shows on the readout strip.
function Vehicles.Summary(plate, model)
    local profile = Vehicles.Profile(plate, model)
    if not profile then return {} end

    local owner = MySQL.single.await([[
        SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1
    ]], { plate })

    return {
        odometer = math.floor(profile.odometer or 0),
        service = {
            due = Servicing and Servicing.DueCount(profile) or 0,
            parts = Servicing and Servicing.Sheet(profile) or {},
        },
        owner = owner and Framework.GetNameByCitizenId(owner.citizenid) or nil,
        performance = profile.performance,
        stance = profile.stance,
        tuning = CustomTuning and CustomTuning.Sheet(profile, nil) or {},
    }
end

function Vehicles.Push(entity, plate, model)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    local profile = Vehicles.Profile(plate, model)
    if not profile then return end

    Entity(entity).state:set('xsmech', {
        performance = profile.performance,
        stance = profile.stance,
        service = profile.service,
    }, true)
end

-- Every vehicle that comes into existence gets its profile attached, whoever
-- spawned it. No garage hooks, no spawner integration.
AddEventHandler('entityCreated', function(entity)
    if GetEntityType(entity) ~= 2 then return end

    CreateThread(function()
        Wait(250)
        if not DoesEntityExist(entity) then return end

        local plate = Util.Trim(GetVehicleNumberPlateText(entity) or '')
        if plate == '' then return end

        local model = string.lower(GetEntityModel(entity) and '' or '')
        Vehicles.Push(entity, plate, model)
    end)
end)

RegisterNetEvent('XS-Mechanic:server:odometer', function(plate, metres)
    local src = source

    plate = Util.Trim(plate or '')
    metres = tonumber(metres) or 0

    -- A client reporting distance is trusted only within reason: 250m per tick
    -- is the contract, so anything far beyond it is dropped rather than banked.
    if plate == '' or metres <= 0 or metres > 2000 then return end

    local profile = Vehicles.Profile(plate)
    if not profile then return end

    profile.odometer = (profile.odometer or 0) + (metres / 1000)

    -- Wear is derived from the same distance, here, rather than being reported
    -- separately — otherwise the two can drift apart and a client could send
    -- one without the other.
    if Servicing then Servicing.Advance(profile, metres) end

    Vehicles.Save(profile)
end)

function Vehicles.Forget(plate)
    cache[Util.Trim(plate or '')] = nil
end

-- Who the vehicle belongs to, as a citizenid.
--
-- Vehicles.Summary carries an `owner` too, but that one is a display NAME for
-- the readout strip. Orders.Book was reading it off the profile, where it has
-- never existed, so every order the shop wrote down recorded the MECHANIC as
-- the customer — and an invoice against that order billed the mechanic.
function Vehicles.OwnerOf(plate)
    plate = Util.Trim(plate or '')
    if plate == '' then return nil end

    local row = MySQL.single.await('SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    return row and row.citizenid or nil
end
