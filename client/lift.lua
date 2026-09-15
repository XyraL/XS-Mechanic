Lift = {}

--[[ A working car lift.

     The prop's own platform does not animate, so the vehicle is what moves:
     collision off, lifted over a second, then held. It reads right and it does
     not depend on the prop having bones nobody can rely on.

     Job locked, and a lift only ever holds one car. ]]

local lifts = {}

local HEIGHT = 1.35
local SECONDS = 2.2

local function anchorOf(point)
    return vector3(point.coords.x, point.coords.y, point.coords.z)
end

function Lift.Spawn(shop, point)
    if not Config.Lift.spawnProp then return end

    local model = joaat(Config.Lift.prop)
    if not IsModelInCdimage(model) then return end

    lib.requestModel(model, 8000)

    local coords = anchorOf(point)
    local entity = CreateObject(model, coords.x, coords.y, coords.z - 1.0, false, false, false)

    SetEntityHeading(entity, point.heading or 0.0)
    FreezeEntityPosition(entity, true)
    SetEntityAsMissionEntity(entity, true, true)
    SetModelAsNoLongerNeeded(model)

    lifts[point.id] = { entity = entity, shop = shop, point = point, up = false, vehicle = nil }

    Target.AddEntity(('xsmech_lift_%s'):format(point.id), entity, {
        {
            id = 'toggle',
            label = 'Raise or lower the lift',
            icon = 'fa-solid fa-arrows-up-down',
            distance = 3.0,
            canInteract = function() return Zones.JobMatches(shop) end,
            action = function() Lift.Toggle(point.id) end,
        },
    })
end

local function vehicleOn(point)
    local coords = anchorOf(point)
    local vehicle = lib.getClosestVehicle(coords, Config.Lift.catchRadius, false)

    if not vehicle or vehicle == 0 then return nil end
    if #(GetEntityCoords(vehicle) - coords) > Config.Lift.catchRadius then return nil end

    return vehicle
end

function Lift.Toggle(pointId)
    local lift = lifts[pointId]
    if not lift then return end

    if lift.busy then return end

    if lift.up then
        Lift.Lower(pointId)
        return
    end

    local vehicle = vehicleOn(lift.point)

    if not vehicle then
        XSM.Notify('Drive something onto it first.', 'error')
        return
    end

    Lift.Raise(pointId, vehicle)
end

function Lift.Raise(pointId, vehicle)
    local lift = lifts[pointId]
    if not lift or lift.up then return end

    lift.busy = true
    lift.vehicle = vehicle

    local start = GetEntityCoords(vehicle)
    local target = start.z + HEIGHT

    SetEntityCollision(vehicle, false, false)
    FreezeEntityPosition(vehicle, true)

    local steps = math.floor(SECONDS * 20)

    for i = 1, steps do
        local z = start.z + (HEIGHT * (i / steps))
        SetEntityCoordsNoOffset(vehicle, start.x, start.y, z, false, false, false)
        Wait(50)
    end

    SetEntityCoordsNoOffset(vehicle, start.x, start.y, target, false, false, false)

    lift.up = true
    lift.busy = false

    if XSM.open then
        XSM.lifted = true
        XSM.Send('state', { state = { lifted = true } })
    end
end

function Lift.Lower(pointId)
    local lift = lifts[pointId]
    if not lift or not lift.up then return end

    local vehicle = lift.vehicle

    if not vehicle or not DoesEntityExist(vehicle) then
        lift.up = false
        lift.vehicle = nil
        return
    end

    lift.busy = true

    local start = GetEntityCoords(vehicle)
    local steps = math.floor(SECONDS * 20)

    for i = 1, steps do
        local z = start.z - (HEIGHT * (i / steps))
        SetEntityCoordsNoOffset(vehicle, start.x, start.y, z, false, false, false)
        Wait(50)
    end

    FreezeEntityPosition(vehicle, false)
    SetEntityCollision(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)

    lift.up = false
    lift.vehicle = nil
    lift.busy = false

    if XSM.open then
        XSM.lifted = false
        XSM.Send('state', { state = { lifted = false } })
    end
end

-- A car left in the air when the resource stops would be stuck there.
function Lift.ClearAll()
    for id, lift in pairs(lifts) do
        if lift.up and lift.vehicle and DoesEntityExist(lift.vehicle) then
            FreezeEntityPosition(lift.vehicle, false)
            SetEntityCollision(lift.vehicle, true, true)
            SetVehicleOnGroundProperly(lift.vehicle)
        end

        if lift.entity and DoesEntityExist(lift.entity) then
            DeleteEntity(lift.entity)
        end

        lifts[id] = nil
    end
end

function Lift.NearAny()
    local coords = GetEntityCoords(cache.ped)

    for _, lift in pairs(lifts) do
        if #(coords - anchorOf(lift.point)) < 6.0 then return true end
    end

    return false
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Lift.ClearAll()
end)
