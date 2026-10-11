CarCam = { active = false }

-- A camera that circles the car while parts are picked. It only ever moves
-- when the player drags, scrolls or picks a view: never on its own.

local FOV = 45.0

-- Degrees around the car from the nose towards the driver's side, and up.
local VIEWS = {
    front = { yaw = 0.0, pitch = 8.0 },
    side = { pitch = 6.0 },
    rear = { yaw = 180.0, pitch = 10.0 },
    top = { pitch = 62.0, zoom = 1.15 },
}

local cam, vehicle, running
local centre, reach, height
local near, far, framed = 3.0, 12.0, 6.0
local yaw, pitch, dist = 0.0, 12.0, 6.0
local goalYaw, goalPitch, goalDist = 0.0, 12.0, 6.0
local edge, aspect = 0.0, 16 / 9

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function ease(from, to, rate, dt)
    return from + (to - from) * math.min(1.0, rate * dt)
end

local function measure(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))

    centre = vector3((min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2)
    reach = math.sqrt(((max.x - min.x) / 2) ^ 2 + ((max.y - min.y) / 2) ^ 2)
    height = (max.z - min.z) / 2
end

-- Far enough back that the whole car fits beside the panel, not under it.
local function fit()
    local tall = math.tan(math.rad(FOV / 2))
    local wide = tall * aspect

    local across = reach / (math.max(0.3, 1.0 - edge) * 0.82 * wide)
    local up = (height + reach * 0.25) / (0.78 * tall)

    return math.max(across, up, near)
end

-- Where the player is looking from now, so the camera starts there.
local function yawFromView()
    local from = GetFinalRenderedCamCoord()
    local at = GetOffsetFromEntityGivenWorldCoords(vehicle, from.x, from.y, from.z) - centre

    if at.x * at.x + at.y * at.y < 0.01 then return 35.0 end

    return math.deg(math.atan(-at.x, at.y))
end

local function place()
    local flat = math.cos(math.rad(pitch)) * dist

    local target = GetOffsetFromEntityInWorldCoords(vehicle, centre.x, centre.y, centre.z)
    local want = GetOffsetFromEntityInWorldCoords(vehicle,
        centre.x - math.sin(math.rad(yaw)) * flat,
        centre.y + math.cos(math.rad(yaw)) * flat,
        centre.z + math.sin(math.rad(pitch)) * dist)

    -- A wall between the car and the camera pulls the camera in front of it.
    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        target.x, target.y, target.z, want.x, want.y, want.z, 1, vehicle, 7)
    local _, hit, at = GetShapeTestResult(ray)

    local pos = want
    local length = #(want - target)

    if (hit == true or hit == 1) and length > 0.01 then
        pos = target + (want - target) * math.max(0.0, (#(at - target) - 0.3) / length)
    end

    -- Aimed a little to the left of the car, so it sits in the open part of
    -- the screen rather than behind the panel.
    local look = target - pos
    local across = #look

    if across > 0.01 then
        local right = vector3(look.y, -look.x, 0.0)
        local size = #right

        if size > 0.001 then
            target = target - right / size * (across * edge * math.tan(math.rad(FOV / 2)) * aspect)
        end
    end

    SetCamCoord(cam, pos.x, pos.y, pos.z)
    PointCamAtCoord(cam, target.x, target.y, target.z)

    if #(pos - GetEntityCoords(cache.ped)) < 1.3 then
        SetEntityLocallyInvisible(cache.ped)
    end
end

local function loop()
    local token = {}
    running = token

    CreateThread(function()
        while running == token do
            if not vehicle or not DoesEntityExist(vehicle) then
                CarCam.Stop()
                break
            end

            local dt = GetFrameTime()

            yaw = ease(yaw, goalYaw, 10.0, dt)
            pitch = ease(pitch, goalPitch, 10.0, dt)
            dist = ease(dist, goalDist, 8.0, dt)

            place()
            Wait(0)
        end
    end)
end

function CarCam.Start(entity, view)
    if Config.Tuning.camera == false then return false end
    if not entity or not DoesEntityExist(entity) then return false end

    view = view or {}
    edge = clamp(tonumber(view.edge) or 0.0, 0.0, 0.6)
    aspect = clamp(tonumber(view.aspect) or (16 / 9), 1.0, 4.0)

    if CarCam.active and entity == vehicle then return true end

    vehicle = entity
    measure(entity)

    near = reach + 0.5
    framed = fit()
    far = math.max(framed * 2.2, reach * 3.0 + 6.0)

    yaw, pitch, dist = yawFromView(), 12.0, framed
    goalYaw, goalPitch, goalDist = yaw, pitch, dist

    if not cam then
        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamFov(cam, FOV)
    end

    place()
    SetCamActive(cam, true)

    if not CarCam.active then
        RenderScriptCams(true, true, 600, true, true)
    end

    CarCam.active = true
    loop()

    return true
end

function CarCam.Orbit(dx, dy)
    if not CarCam.active then return end

    goalYaw = goalYaw - (tonumber(dx) or 0) * 0.3
    goalPitch = clamp(goalPitch + (tonumber(dy) or 0) * 0.2, -4.0, 70.0)
end

function CarCam.Zoom(step)
    if not CarCam.active then return end

    goalDist = clamp(goalDist * (1.0 + 0.12 * clamp(tonumber(step) or 0, -3, 3)), near, far)
end

function CarCam.View(name)
    local view = VIEWS[name]
    if not CarCam.active or not view then return end

    local base = view.yaw

    -- Whichever side the camera is already nearer.
    if name == 'side' then
        base = goalYaw % 360.0 > 180.0 and 270.0 or 90.0
    end

    if base then
        goalYaw = base + 360.0 * math.floor((goalYaw - base) / 360.0 + 0.5)
    end

    goalPitch = view.pitch
    goalDist = clamp(framed * (view.zoom or 1.0), near, far)
end

function CarCam.Stop()
    running = nil
    vehicle = nil

    if not cam then
        CarCam.active = false
        return
    end

    RenderScriptCams(false, true, 500, true, true)
    SetCamActive(cam, false)
    DestroyCam(cam, true)

    cam = nil
    CarCam.active = false
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() or not cam then return end

    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(cam, true)
    cam = nil
end)
