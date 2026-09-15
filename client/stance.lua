Stance = {}

--[[ Suspension height, camber and track width, per wheel.

     The natives are per-wheel bone offsets, so this is drawn on the client and
     carried in the profile like everything else. It is deliberately clamped:
     the limits below are the difference between a stanced car and a car whose
     wheels are somewhere near the next postcode. ]]

local LIMITS = {
    height = { -0.30, 0.30 },
    camber = { -0.35, 0.35 },
    track  = { -0.25, 0.25 },
}

local WHEELS = { 'fl', 'fr', 'rl', 'rr' }

local INDEX = { fl = 0, fr = 1, rl = 2, rr = 3 }

local function clamp(value, key)
    local limit = LIMITS[key]
    return math.max(limit[1], math.min(limit[2], tonumber(value) or 0.0))
end

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

function Stance.Apply(vehicle, stance)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    stance = Stance.Normalise(stance)

    if not stance then
        -- Nothing fitted. Put the ride height back and leave the wheels alone.
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionRaise',
            GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionRaise'))
        return
    end

    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionRaise', stance.height)

    for _, wheel in ipairs(WHEELS) do
        local entry = stance[wheel]
        local index = INDEX[wheel]

        -- Not every build exposes these, and a missing native must not take
        -- the whole profile application down with it.
        pcall(function()
            SetVehicleWheelXOffset(vehicle, index, entry.track)
            SetVehicleWheelYRotation(vehicle, index, entry.camber)
        end)
    end
end

-- Used by the live editor: applies without writing anything, so backing out
-- leaves the car as it was.
function Stance.Preview(vehicle, stance)
    Stance.Apply(vehicle, stance)
end

function Stance.Read(vehicle)
    if not vehicle or vehicle == 0 then return Stance.Empty() end

    local out = { height = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionRaise') or 0.0 }

    for _, wheel in ipairs(WHEELS) do
        local index = INDEX[wheel]
        local camber, track = 0.0, 0.0

        pcall(function()
            track = GetVehicleWheelXOffset(vehicle, index) or 0.0
            camber = GetVehicleWheelYRotation(vehicle, index) or 0.0
        end)

        out[wheel] = { camber = camber, track = track }
    end

    return out
end

Stance.Wheels = WHEELS
Stance.Limits = LIMITS
