Showcase = { active = false }

--[[ The live vehicle preview.

     The panel does not draw a picture of the car. It leaves a transparent
     rectangle, and because NUI is an overlay the game shows through it — so a
     scripted camera pointed at the real vehicle puts the real vehicle there,
     with whatever paint and parts are on it right now.

     The page measures where that rectangle actually is and posts it, because
     the panel scales with the screen and a hardcoded rect would only be right
     on one resolution.

     Three things are worked out from that rectangle rather than guessed:

     WHERE THE CAMERA STANDS. `alpha` is degrees around the car measured from
     its nose, and it has to mean the same thing whatever direction the car is
     parked in. In GTA V an entity at heading h has forward (-sin h, cos h), so
     a camera on the line at angle alpha from the nose is at

         forward(h + alpha) = (-sin(h + alpha), cos(h + alpha))

     because the signed angle between forward(A) and forward(B) is always
     A - B. The heading cancels algebraically rather than by luck.

     alpha = 0 stands off the nose, 90 off the driver's side, 180 off the boot,
     270 off the passenger side. Increasing alpha walks anticlockwise seen from
     above, the same sense as heading, which is why it adds.

     FRAMING. Aiming the camera AT the car puts the car in the middle of the
     SCREEN. To move it into a window off to one side the aim point is pushed
     sideways instead — aim to the right of the car and the car sits to the
     left. That is sign-safe, which rotating the camera is not.

     SIZE. The window is a fraction of the screen, so a camera framed for the
     whole screen shows a close-up of one wing through it. The distance comes
     from how much of the screen the window covers and how big this particular
     vehicle is. Get that wrong and the framing maths is still perfect — it
     just frames a door handle. ]]

local cam = nil
local target = nil
local rect = nil
local spin = 0.0

local FOV = 50.0

--[[ Where the camera stands to look at each part of the car.

     `alpha` is the angle around the car from its nose as above, `pitch` is how
     far down it looks, `zoom` scales the distance the window asked for, `lift`
     moves the aim point up or down the car's height and `along` moves it fore
     or aft as a fraction of the car's half length.

     `along` is what makes a tight shot useful: an engine bay framed on the
     car's centre is a shot of the roof. ]]
local VIEWS = {
    full      = { alpha = 35.0,  pitch = -12.0, zoom = 1.00, lift = 0.00, along = 0.00 },
    front     = { alpha = 0.0,   pitch = -8.0,  zoom = 0.78, lift = -0.10, along = 0.70 },
    rear      = { alpha = 180.0, pitch = -8.0,  zoom = 0.78, lift = -0.05, along = -0.70 },
    side      = { alpha = 90.0,  pitch = -4.0,  zoom = 0.95, lift = 0.00, along = 0.00 },
    wheel     = { alpha = 68.0,  pitch = -5.0,  zoom = 0.42, lift = -0.55, along = 0.55 },
    roof      = { alpha = 35.0,  pitch = -52.0, zoom = 0.85, lift = 0.40, along = 0.00 },
    interior  = { alpha = 105.0, pitch = -20.0, zoom = 0.40, lift = 0.35, along = 0.10 },
    engineBay = { alpha = 18.0,  pitch = -34.0, zoom = 0.50, lift = 0.30, along = 0.65 },
    plate     = { alpha = 180.0, pitch = -10.0, zoom = 0.34, lift = -0.20, along = -0.85 },
}

-- Where each slot lives on the car. Anything not named here gets the whole car.
local SLOT_VIEW = {
    frontBumper = 'front', grille = 'front', xenon = 'front', lights = 'front',
    hood = 'engineBay', engine = 'engineBay', engineBlock = 'engineBay',
    airFilter = 'engineBay', turbo = 'engineBay', struts = 'engineBay', tank = 'engineBay',

    rearBumper = 'rear', spoiler = 'rear', exhaust = 'rear', trunk = 'rear',
    plateHolder = 'plate', plate = 'plate',

    sideSkirt = 'side', fender = 'side', rightFender = 'side', archCover = 'side',
    windows = 'side', aerials = 'side', livery = 'side', respray = 'side',
    cosmetics = 'full', extras = 'full',

    brakes = 'wheel', suspension = 'wheel', wheels = 'wheel',
    frontWheels = 'wheel', backWheels = 'wheel', tyreSmoke = 'wheel',
    hydraulics = 'wheel', stance = 'side',

    roof = 'roof', rollCage = 'roof',

    dashboard = 'interior', dial = 'interior', doorSpeaker = 'interior',
    seats = 'interior', steeringWheel = 'interior', shifter = 'interior',
    plaques = 'interior', speakers = 'interior', trimDesign = 'interior',
    ornaments = 'interior', trim = 'interior', horn = 'interior',
    interior = 'interior',
}

local KEYS = { 'alpha', 'pitch', 'zoom', 'lift', 'along' }

local view = VIEWS.full
local shown = { alpha = 35.0, pitch = -12.0, zoom = 1.0, lift = 0.0, along = 0.0 }
local moving = false

-- How much of the window the car should fill across its longest axis.
local FILL = 0.85

-- The camera cannot always stand where the maths wants it — a lock-up is four
-- metres deep. Below this it widens the lens instead of backing further off.
local MIN_DISTANCE = 2.6
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

-- Half the vehicle across its widest horizontal diagonal, half its height, and
-- half its length. The diagonal because the camera looks at a corner of it,
-- never square on.
local function spanOf(vehicle)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))

    local size = max - min
    local flat = math.sqrt((size.x * size.x) + (size.y * size.y)) * 0.5

    return math.max(flat, 1.2), math.max(size.z * 0.5, 0.6), math.max(size.y * 0.5, 1.4)
end

-- Somewhere the camera can actually stand. A wall between it and the car is
-- worse than a car that is slightly too big for the window.
local function reachable(from, direction, want)
    local to = from + (direction * want)

    local ray = StartShapeTestCapsule(from.x, from.y, from.z, to.x, to.y, to.z,
        0.4, 1 + 16, 0, 4)

    local _, hit, coords = GetShapeTestResult(ray)

    if hit ~= 1 then return want end

    local reached = #(vector3(coords.x, coords.y, coords.z) - from) - 0.5

    return math.max(MIN_DISTANCE, math.min(want, reached))
end

-- Walks the camera towards the view it has been asked for rather than cutting
-- to it. Returns true while there is still ground to cover.
local function ease()
    local done = true

    for _, key in ipairs(KEYS) do
        local from = shown[key]
        local to = view[key]
        local gap = to - from

        -- The long way round the car is never the nicer way to watch.
        if key == 'alpha' then
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
    local heading = GetEntityHeading(target)

    local spanH, spanV, spanL = spanOf(target)

    -- The point on the car this shot is about, which is not always its middle.
    local nose = vector3(-math.sin(math.rad(heading)), math.cos(math.rad(heading)), 0.0)
    local look = centre + (nose * (spanL * shown.along)) + vector3(0.0, 0.0, spanV * shown.lift)

    local width, height = GetActiveScreenResolution()
    local aspect = (width or 1920) / math.max(height or 1080, 1)

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

    -- Around the car from its nose, independent of where the car is pointing.
    local around = math.rad(heading + shown.alpha + spin)
    local flat = vector3(-math.sin(around), math.cos(around), 0.0)

    local distance = reachable(look + vector3(0.0, 0.0, 0.4), flat, want)

    -- Whatever room there turned out to be, the lens opens up until the car
    -- fits the window at that distance.
    local needH = (spanH * shown.zoom) / math.max(distance * windowW * FILL * aspect, 0.01)
    local needV = (spanV * shown.zoom) / math.max(distance * windowH * FILL, 0.01)

    local fov = math.deg(math.atan(math.max(needH, needV))) * 2
    fov = math.max(FOV, math.min(MAX_FOV, fov))

    local pos = vector3(
        look.x + flat.x * distance,
        look.y + flat.y * distance,
        look.z + (distance * -math.sin(math.rad(shown.pitch))) + 0.30)

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
        print(('^3[XS-Mechanic]^0 showcase: window %.2f x %.2f · alpha %.0f · %.1fm · fov %.0f')
            :format(windowW, windowH, shown.alpha, distance, fov))
    end
end

function Showcase.Start(vehicle)
    if not Config.Tablet.livePreview then return end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    target = vehicle

    if not cam then
        -- A fresh camera starts where it is meant to be rather than easing in
        -- from wherever the last car left it.
        for _, key in ipairs(KEYS) do shown[key] = view[key] end

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
    spin = 0.0
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
    spin = (spin + (tonumber(amount) or 0)) % 360
    moving = true
    frame()
end

-- How far the car has been turned by hand, so a double click can put it back.
function Showcase.Spun()
    return spin
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
