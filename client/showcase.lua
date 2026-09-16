Showcase = { active = false }

--[[ The live vehicle preview.

     The panel does not draw a picture of the car. It leaves a transparent
     rectangle, and because NUI is an overlay the game shows through it — so a
     scripted camera pointed at the real vehicle puts the real vehicle there,
     with whatever paint and parts are on it right now.

     The page measures where that rectangle actually is and posts it, because
     the panel scales with the screen and a hardcoded rect would only be right
     on one resolution.

     Framing: aiming the camera AT the car puts the car in the middle of the
     screen. To move it into a window that is off to one side, the aim point is
     pushed sideways instead — aim to the right of the car and the car sits to
     the left. That is sign-safe, which rotating the camera is not. ]]

local cam = nil
local target = nil
local rect = nil
local orbit = 0.0

local PITCH = -11.0
local DISTANCE = 5.4
local FOV = 45.0

local function drop()
    if cam then
        RenderScriptCams(false, false, 0, true, true)
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        cam = nil
    end

    Showcase.active = false
end

local function frame()
    if not cam or not target or not DoesEntityExist(target) then return end

    local centre = GetEntityCoords(target)
    local heading = GetEntityHeading(target) + 220.0 + orbit
    local rad = math.rad(heading)

    local pos = vector3(
        centre.x + math.sin(rad) * -DISTANCE,
        centre.y + math.cos(rad) * -DISTANCE,
        centre.z + 1.05)

    SetCamCoord(cam, pos.x, pos.y, pos.z)

    local aim = centre

    if rect then
        local width, height = GetActiveScreenResolution()
        local aspect = (width or 1920) / math.max(height or 1080, 1)

        -- Half the view's width and height at the car's distance.
        local halfV = DISTANCE * math.tan(math.rad(FOV) / 2)
        local halfH = halfV * aspect

        -- How far the window's centre sits from the middle of the screen,
        -- in half-screens. Pushing the aim point the other way brings the car
        -- into the window.
        local dx = (0.5 - rect.x) * 2.0
        local dy = (rect.y - 0.5) * 2.0

        local forward = centre - pos
        local flat = vector3(forward.x, forward.y, 0.0)

        if #flat > 0.0 then
            flat = flat / #flat

            -- X is east and Y is north, so the right of a forward (fx, fy) is
            -- (fy, -fx).
            local right = vector3(flat.y, -flat.x, 0.0)

            aim = centre + (right * (dx * halfH)) + vector3(0.0, 0.0, dy * halfV)
        end
    end

    PointCamAtCoord(cam, aim.x, aim.y, aim.z)
    SetCamFov(cam, FOV)
end

function Showcase.Start(vehicle)
    if not Config.Tablet.livePreview then return end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    target = vehicle

    if not cam then
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

    if XSM.vehicle and DoesEntityExist(XSM.vehicle) then
        Showcase.Start(XSM.vehicle)
    end
end

function Showcase.Spin(amount)
    orbit = (orbit + amount) % 360
    frame()
end

-- The car can move, and the panel can be dragged around by a resize, so the
-- framing is refreshed on a slow tick rather than only when something asks.
CreateThread(function()
    while true do
        Wait(200)

        if Showcase.active then
            if not target or not DoesEntityExist(target) then
                Showcase.Stop()
            else
                frame()
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    drop()
end)
