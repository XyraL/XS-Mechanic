Stance = {}

--[[ Suspension height, camber and track width, per wheel.

     Everything here is a DIFFERENCE from how the vehicle left the factory, not
     an absolute. The stock values are read off the entity once, before anything
     touches it, and kept — so a stance of nothing puts the car back exactly,
     and applying the same stance twice does not stack.

     Reading the current value instead is what broke cars: once a vehicle is
     lowered, the "stock" ride height you read back IS the lowered one, so there
     is nothing left to put back and every reset lowers it again. ]]

local LIMITS = {
    height = { -0.30, 0.30 },
    camber = { -0.35, 0.35 },
    track  = { -0.25, 0.25 },
}

local WHEELS = { 'fl', 'fr', 'rl', 'rr' }

local INDEX = { fl = 0, fr = 1, rl = 2, rr = 3 }

-- Entity handles get recycled, so the model is kept with the reading and a
-- mismatch means this handle is a different car now.
local stock = {}

local function clamp(value, key)
    local limit = LIMITS[key]
    return math.max(limit[1], math.min(limit[2], tonumber(value) or 0.0))
end

local function readWheels(vehicle)
    local out = {}

    for _, wheel in ipairs(WHEELS) do
        local index = INDEX[wheel]
        local track, camber = 0.0, 0.0

        -- Not every build exposes these, and a missing native must not take
        -- the whole profile application down with it.
        pcall(function()
            track = GetVehicleWheelXOffset(vehicle, index) or 0.0
            camber = GetVehicleWheelYRotation(vehicle, index) or 0.0
        end)

        out[wheel] = { track = track, camber = camber }
    end

    return out
end

-- How the car left the factory. Taken once, before this resource changes
-- anything on it.
local function factory(vehicle)
    local model = GetEntityModel(vehicle)
    local held = stock[vehicle]

    if held and held.model == model then return held end

    held = {
        model = model,
        raise = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionRaise') or 0.0,
        wheels = readWheels(vehicle),
    }

    stock[vehicle] = held

    return held
end

Stance.Factory = factory

function Stance.Empty()
    local out = { height = 0.0 }

    for _, wheel in ipairs(WHEELS) do
        out[wheel] = { camber = 0.0, track = 0.0 }
    end

    return out
end

function Stance.Normalise(stance)
    if type(stance) ~= 'table' then return nil end

    local out = { height = clamp(stance.height, 'height') }
    local touched = out.height ~= 0.0

    for _, wheel in ipairs(WHEELS) do
        local entry = stance[wheel] or {}

        out[wheel] = {
            camber = clamp(entry.camber, 'camber'),
            track = clamp(entry.track, 'track'),
        }

        if out[wheel].camber ~= 0.0 or out[wheel].track ~= 0.0 then touched = true end
    end

    if not touched then return nil end

    return out
end

-- Puts the car back on its factory suspension. This is what "no stance" means,
-- and it has to be a real instruction rather than a decision to leave things
-- alone.
function Stance.Reset(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local was = factory(vehicle)

    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionRaise', was.raise)

    for _, wheel in ipairs(WHEELS) do
        local entry = was.wheels[wheel]
        local index = INDEX[wheel]

        if entry then
            pcall(function()
                SetVehicleWheelXOffset(vehicle, index, entry.track)
                SetVehicleWheelYRotation(vehicle, index, entry.camber)
            end)
        end
    end
end

function Stance.Apply(vehicle, stance)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    -- Read the factory setup BEFORE changing anything, even when what is being
    -- applied is nothing.
    local was = factory(vehicle)

    stance = Stance.Normalise(stance)

    if not stance then
        Stance.Reset(vehicle)
        return
    end

    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionRaise', was.raise + stance.height)

    for _, wheel in ipairs(WHEELS) do
        local entry = stance[wheel]
        local index = INDEX[wheel]
        local from = was.wheels[wheel] or { track = 0.0, camber = 0.0 }

        pcall(function()
            SetVehicleWheelXOffset(vehicle, index, from.track + entry.track)
            SetVehicleWheelYRotation(vehicle, index, from.camber + entry.camber)
        end)
    end
end

-- Used by the live editor: applies without writing anything, so backing out
-- leaves the car as it was.
function Stance.Preview(vehicle, stance)
    Stance.Apply(vehicle, stance)
end

-- What the preview snapshot puts back. Stance.Apply cannot do it: a stance of
-- nothing normalises to nil, and the caller means "what it had", which is not
-- always the factory setup.
function Stance.Restore(vehicle, stance)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    if type(stance) ~= 'table' then
        Stance.Reset(vehicle)
        return
    end

    Stance.Apply(vehicle, stance)
end

-- The fitted stance, as a difference from factory, which is the same shape the
-- profile stores and the editor edits.
function Stance.Read(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return Stance.Empty() end

    local was = factory(vehicle)
    local now = readWheels(vehicle)

    local out = {
        height = (GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionRaise') or 0.0) - was.raise,
    }

    for _, wheel in ipairs(WHEELS) do
        out[wheel] = {
            track = now[wheel].track - was.wheels[wheel].track,
            camber = now[wheel].camber - was.wheels[wheel].camber,
        }
    end

    return out
end

function Stance.Forget(vehicle)
    stock[vehicle] = nil
end

-- Handles are recycled. Anything that no longer exists is dropped rather than
-- kept as a reading for whatever takes the number next.
CreateThread(function()
    while true do
        Wait(60000)

        for entity in pairs(stock) do
            if not DoesEntityExist(entity) then stock[entity] = nil end
        end
    end
end)

Stance.Wheels = WHEELS
Stance.Limits = LIMITS
