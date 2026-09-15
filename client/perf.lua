Perf = {}

--[[ Everything that is not a stock mod slot lands here: the custom tuning
     packages and the wear multipliers from servicing.

     Handling is client side, so every client applies the same package to every
     car it can see. The profile arrives on an `xsmech` state bag set by the
     server, which means it works with any garage, any spawner and any admin
     tool without a hook into any of them.

     Base values are captured per ENTITY the first time we touch it and every
     recompute starts from those, so applying twice never compounds. ]]

local bases = {}
local applied = {}

local FIELDS = {
    accel = 'fInitialDriveForce',
    topSpeed = 'fInitialDriveMaxFlatVel',
    brake = 'fBrakeForce',
    traction = 'fTractionCurveMax',
    gearTime = 'fClutchChangeRateScaleUpShift',
    suspension = 'fSuspensionForce',
}

local function baseOf(vehicle, field)
    local key = ('%s:%s'):format(vehicle, field)

    if bases[key] == nil then
        bases[key] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', field)
    end

    return bases[key]
end

local function collectFields(options)
    local fields = {}

    for _, option in ipairs(options) do
        for field in pairs(option.handling or {}) do fields[field] = true end
    end

    for _, field in pairs(FIELDS) do fields[field] = true end

    return fields
end

function Perf.Apply(vehicle, profile)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    profile = profile or {}

    local fitted = profile.performance or {}
    local wear = profile.service or {}
    local electric = Catalogue.IsElectric(vehicle)

    local options = Tuning.Ordered(fitted)
    local fields = collectFields(options)

    -- Start every field from the vehicle's own base so nothing compounds.
    local values = {}
    for field in pairs(fields) do
        values[field] = baseOf(vehicle, field)
    end

    for _, option in ipairs(options) do
        for field, amount in pairs(option.handling or {}) do
            if option.handlingOverwrites then
                values[field] = amount
            else
                values[field] = (values[field] or 0.0) + amount
            end
        end
    end

    -- Wear is applied last and always multiplies, so a worn car is worse than
    -- the same car fresh whatever is bolted to it.
    if Config.Service.enabled then
        for effect, field in pairs(FIELDS) do
            local multiplier = Service.Multiplier(wear, electric, effect)

            if multiplier < 1.0 and values[field] then
                values[field] = values[field] * multiplier
            end
        end
    end

    for field, value in pairs(values) do
        if type(value) == 'number' then
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, value + 0.0)
        end
    end

    for _, option in ipairs(options) do
        if option.gears then
            SetVehicleHandlingInt(vehicle, 'CHandlingData', 'nInitialDriveGears', option.gears)
        end

        if option.audio and option.audio ~= '' then
            ForceVehicleEngineAudio(vehicle, option.audio)
        end
    end

    if Config.Tuning.nos and fitted.nos then
        applied[vehicle] = applied[vehicle] or {}
        applied[vehicle].nos = true
    end

    applied[vehicle] = applied[vehicle] or {}
    applied[vehicle].profile = profile

    Stance.Apply(vehicle, profile.stance)
end

function Perf.Profile(vehicle)
    return applied[vehicle] and applied[vehicle].profile or nil
end

function Perf.Forget(vehicle)
    applied[vehicle] = nil

    for key in pairs(bases) do
        if key:sub(1, #tostring(vehicle) + 1) == tostring(vehicle) .. ':' then
            bases[key] = nil
        end
    end
end

AddStateBagChangeHandler('xsmech', nil, function(bagName, _, value)
    -- gsub returns the string AND the number of replacements, and passing that
    -- straight into tonumber makes the count its BASE — which is 1, and out of
    -- range. The parentheses throw the second value away.
    local netId = tonumber((bagName:gsub('entity:', '')))
    if not netId then return end

    CreateThread(function()
        -- lib.waitFor ERRORS on timeout when given a message, it does not
        -- return nil. A state bag for a vehicle this client cannot see is
        -- normal and must not spam the console, so the timeout is swallowed.
        local ok, vehicle = pcall(lib.waitFor, function()
            local entity = NetworkGetEntityFromNetworkId(netId)
            if entity and entity ~= 0 and DoesEntityExist(entity) then return entity end
        end, 'no entity for the state bag', 5000)

        if not ok or not vehicle then return end

        Perf.Apply(vehicle, value)
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    bases = {}
    applied = {}
end)
