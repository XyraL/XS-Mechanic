Showcase = { active = false }

--[[ The live vehicle preview.

     The panel does not draw a picture of the car. It leaves a transparent
     rectangle, and because NUI is an overlay the game shows through it — so a
     scripted camera pointed at the real vehicle puts the real vehicle there,
     with whatever paint and parts are on it right now.

     The page measures where that rectangle actually is and posts it, because
     the panel scales with the screen and a hardcoded rect would only be right
     on one resolution.

     Two things have to be worked out from that rectangle, not guessed:

     Framing. Aiming the camera AT the car puts the car in the middle of the
     SCREEN. To move it into a window off to one side the aim point is pushed
     sideways instead — aim to the right of the car and the car sits to the
     left. That is sign-safe, which rotating the camera is not.

     Size. The window is a small fraction of the screen, so a camera framed for
     the whole screen shows a close-up of one wing through it. The distance has
     to be worked out from how much of the screen the window actually covers
     and how big this particular vehicle is. Get that wrong and the framing
     maths is still perfect — it just frames a door handle. ]]

local cam = nil
local target = nil
local rect = nil
local orbit = 0.0

local PITCH = -11.0
local FOV = 50.0

--[[ Where the camera stands to look at each part of the car.

     `orbit` is degrees around the car from the resting three-quarter view,
     `pitch` is how far down it looks, `zoom` scales the distance the window
     asked for, and `lift` moves the aim point up or down the car's height.

     The window shows one part of a car at a time, so it goes and looks at that
     part: click a spoiler and it walks round the back. ]]
local VIEWS = {
    full      = { orbit = 0.0,    pitch = -11.0, zoom = 1.0,  lift = 0.0 },
    front     = { orbit = -40.0,  pitch = -9.0,  zoom = 0.82, lift = 0.0 },
    rear      = { orbit = 140.0,  pitch = -9.0,  zoom = 0.82, lift = 0.0 },
    side      = { orbit = -130.0, pitch = -6.0,  zoom = 0.92, lift = 0.0 },
    wheel     = { orbit = -118.0, pitch = -8.0,  zoom = 0.44, lift = -0.55 },
    roof      = { orbit = -25.0,  pitch = -34.0, zoom = 0.86, lift = 0.35 },
    interior  = { orbit = -152.0, pitch = -22.0, zoom = 0.40, lift = 0.30 },
    engineBay = { orbit = -30.0,  pitch = -30.0, zoom = 0.52, lift = 0.30 },
    plate     = { orbit = 160.0,  pitch = -12.0, zoom = 0.38, lift = -0.25 },
}

-- Where each slot lives on the car. Anything not named here gets the whole car.
local SLOT_VIEW = {
    frontBumper = 'front', grille = 'front', hood = 'engineBay', xenon = 'front',
    engine = 'engineBay', engineBlock = 'engineBay', airFilter = 'engineBay',
    turbo = 'engineBay', struts = 'engineBay', tank = 'engineBay',

    rearBumper = 'rear', spoiler = 'rear', exhaust = 'rear', trunk = 'rear',
    plateHolder = 'plate', plate = 'plate',

    sideSkirt = 'side', fender = 'side', rightFender = 'side', archCover = 'side',
    windows = 'side', aerials = 'side', livery = 'side', respray = 'side',
    brakes = 'wheel', suspension = 'wheel', wheels = 'wheel',
    frontWheels = 'wheel', backWheels = 'wheel', tyreSmoke = 'wheel',
    hydraulics = 'wheel', stance = 'side',

    roof = 'roof', rollCage = 'roof',

    dashboard = 'interior', dial = 'interior', doorSpeaker = 'interior',
    seats = 'interior', steeringWheel = 'interior', shifter = 'interior',
    plaques = 'interior', speakers = 'interior', trimDesign = 'interior',
    ornaments = 'interior', trim = 'interior', horn = 'interior',
}

local view = VIEWS.full
local shown = { orbit = 0.0, pitch = PITCH, zoom = 1.0, lift = 0.0 }
local moving = false

-- How much of the window the car should fill across its longest axis.
local FILL = 0.85

-- The camera cannot always stand where the maths wants it — a lock-up is four
-- metres deep. Below this it widens the lens instead of backing further off.
local MIN_DISTANCE = 3.2
local MAX_DISTANCE = 26.0
local MAX_FOV = 92.0

local function drop()
    if cam then
        RenderScriptCams(false, false, 0, true, true)
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        cam = nil
    end

    Showcase.active = false
end

-- Half the vehicle across its widest horizontal diagonal, and half its height.
-- The diagonal because the camera looks at a corner of it, never square on.
local function spanOf(vehicle)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))

    local size = max - min
    local flat = math.sqrt((size.x * size.x) + (size.y * size.y)) * 0.5

    return math.max(flat, 1.2), math.max(size.z * 0.5, 0.6)
end

-- Somewhere the camera can actually stand. A wall between it and the car is
-- worse than a car that is slightly too big for the window.
local function reachable(centre, direction, want)
    local from = centre + vector3(0.0, 0.0, 1.0)
    local to = from + (direction * want)

    local ray = StartShapeTestCapsule(from.x, from.y, from.z, to.x, to.y, to.z,
        0.4, 1 + 16, 0, 4)

    local _, hit, coords = GetShapeTestResult(ray)

    if hit ~= 1 then return want end

    local reached = #(vector3(coords.x, coords.y, coords.z) - from) - 0.6

    return math.max(MIN_DISTANCE, math.min(want, reached))
end

-- Walks the camera towards the view it has been asked for rather than cutting
-- to it. Returns true while there is still ground to cover.
local function ease()
    local done = true

    for _, key in ipairs({ 'orbit', 'pitch', 'zoom', 'lift' }) do
        local from = shown[key]
        local to = view[key]
        local gap = to - from

        -- The long way round the car is never the nicer way to watch.
        if key == 'orbit' then
            while gap > 180.0 do gap = gap - 360.0 end
            while gap < -180.0 do gap = gap + 360.0 end
        end

        if math.abs(gap) < 0.02 then
            shown[key] = to
        else
            shown[key] = from + gap * 0.16
            done = false
        end
    end

    return not done
end

local function frame()
    if not cam or not target or not DoesEntityExist(target) then return end

    local centre = GetEntityCoords(target)
    local heading = GetEntityHeading(target) + 220.0 + shown.orbit + orbit
    local rad = math.rad(heading)

    local width, height = GetActiveScreenResolution()
    local aspect = (width or 1920) / math.max(height or 1080, 1)

    local spanH, spanV = spanOf(target)

    -- The window, as a fraction of the screen. Nothing measured yet means the
    -- whole screen, which is what the very first frame gets.
    local windowW = rect and rect.w or 1.0
    local windowH = rect and rect.h or 1.0

    -- Distance that makes the car fill the window at the resting lens.
    local restH = math.tan(math.rad(FOV) / 2)
    local restW = restH * aspect

    local want = math.max(
        spanH / math.max(restW * windowW * FILL, 0.01),
        spanV / math.max(restH * windowH * FILL, 0.01))

    want = math.max(MIN_DISTANCE, math.min(MAX_DISTANCE, want * shown.zoom))

    local flat = vector3(math.sin(rad) * -1.0, math.cos(rad) * -1.0, 0.0)
    local distance = reachable(centre, flat, want)

    -- Whatever room there turned out to be, the lens opens up until the car
    -- fits the window at that distance.
    local needH = (spanH * shown.zoom) / math.max(distance * windowW * FILL * aspect, 0.01)
    local needV = (spanV * shown.zoom) / math.max(distance * windowH * FILL, 0.01)

    local fov = math.deg(math.atan(math.max(needH, needV))) * 2
    fov = math.max(FOV, math.min(MAX_FOV, fov))

    local look = centre + vector3(0.0, 0.0, spanV * shown.lift)

    local pos = vector3(
        centre.x + flat.x * distance,
        centre.y + flat.y * distance,
        look.z + (distance * -math.sin(math.rad(shown.pitch))) + 0.35)

    SetCamCoord(cam, pos.x, pos.y, pos.z)

    local aim = look

    if rect then
        -- Half the view's width and height at the car's distance, in the lens
        -- that is actually being used.
        local halfV = distance * math.tan(math.rad(fov) / 2)
        local halfH = halfV * aspect

        -- How far the window's centre sits from the middle of the screen, in
        -- half-screens. Pushing the aim point the other way brings the car
        -- into the window.
        local dx = (0.5 - rect.x) * 2.0
        local dy = (rect.y - 0.5) * 2.0

        local forward = look - pos
        local level = vector3(forward.x, forward.y, 0.0)

        if #level > 0.0 then
            level = level / #level

            -- X is east and Y is north, so the right of a forward (fx, fy) is
            -- (fy, -fx).
            local right = vector3(level.y, -level.x, 0.0)

            aim = look + (right * (dx * halfH)) + vector3(0.0, 0.0, dy * halfV)
        end
    end

    PointCamAtCoord(cam, aim.x, aim.y, aim.z)
    SetCamFov(cam, fov)

    if Config.Debug then
        print(('^3[XS-Mechanic]^0 showcase: window %.2f x %.2f, distance %.1fm, fov %.0f')
            :format(windowW, windowH, distance, fov))
    end
end

function Showcase.Start(vehicle)
    if not Config.Tablet.livePreview then return end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    target = vehicle

    if not cam then
        -- A fresh camera starts where it is meant to be rather than easing in
        -- from wherever the last car left it.
        shown = { orbit = view.orbit, pitch = view.pitch, zoom = view.zoom, lift = view.lift }

        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 400, true, true)
    end

    Showcase.active = true
    frame()
end

function Showcase.Stop()
    target = nil
    rect = nil
    orbit = 0.0
    view = VIEWS.full
    moving = false
    drop()
end

-- Called whenever the page measures its window, which is on open, on every
-- panel change and on resize.
function Showcase.SetRect(data)
    if not data or data.active == false then
        Showcase.Stop()
        return
    end

    rect = { x = data.x or 0.5, y = data.y or 0.5, w = data.w or 0.25, h = data.h or 0.25 }

    Showcase.Focus(data.focus)

    if XSM.vehicle and DoesEntityExist(XSM.vehicle) then
        Showcase.Start(XSM.vehicle)
    end
end

--[[ Look at a part of the car.

     Takes a slot id, a view name, or nothing. Anything it does not recognise
     shows the whole car, which is the right answer for "I do not know". ]]
function Showcase.Focus(what)
    local name = VIEWS[what or ''] and what or SLOT_VIEW[what or '']
    local next_ = VIEWS[name or ''] or VIEWS.full

    if next_ == view then return end

    view = next_
    moving = true
end

function Showcase.Spin(amount)
    orbit = (orbit + amount) % 360
    frame()
end

-- The car can move, and the panel can be dragged around by a resize, so the
-- framing is refreshed on a slow tick rather than only when something asks.
CreateThread(function()
    while true do
        -- Every frame while the camera is walking round the car, and a slow
        -- tick the rest of the time to keep up with a car that moves.
        Wait(moving and 0 or 200)

        if Showcase.active then
            if not target or not DoesEntityExist(target) then
                Showcase.Stop()
            else
                moving = ease()
                frame()
            end
        else
            moving = false
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    drop()
end)
