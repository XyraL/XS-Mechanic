Craft = { at = nil }

--[[ The bench.

     The camera drops to head height over the bench and looks down at it, and
     the panel is drawn as a sheet of light over the top rather than as the
     tablet. Nothing is played for: pick a part, and if the material is in your
     pockets the bench makes it.

     The camera is the reason this is its own mode. Everything else the panel
     does happens wherever the mechanic is stood. ]]

local cam = nil

local HEIGHT = 1.25
local BACK = 0.62
local PITCH = -58.0
local FOV = 48.0

local function drop()
    if not cam then return end

    RenderScriptCams(false, true, 400, true, true)
    SetCamActive(cam, false)
    DestroyCam(cam, true)
    cam = nil
end

local function look(point)
    local coords = vector3(point.coords.x, point.coords.y, point.coords.z)

    -- Behind the mechanic's shoulder rather than square on, so the bench reads
    -- as a surface instead of a flat wall.
    local heading = GetEntityHeading(cache.ped)
    local rad = math.rad(heading)
    local back = vector3(math.sin(rad) * BACK, -math.cos(rad) * BACK, 0.0)

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    SetCamCoord(cam, coords.x + back.x, coords.y + back.y, coords.z + HEIGHT)
    SetCamRot(cam, PITCH, 0.0, heading, 2)
    SetCamFov(cam, FOV)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 400, true, true)
end

function Craft.Open(shop, point)
    if not Config.Crafting.enabled then
        XSM.Notify('Nothing is made here.', 'error')
        return
    end

    Craft.at = { shop = shop.id, point = point.id }

    look(point)
    XSM.Open('bench', shop.id)

    -- Opening can be refused — no job, shop switched off — and the camera must
    -- not be left pointed at a bench nobody is using.
    if not XSM.open then
        Craft.at = nil
        drop()
    end
end

function Craft.Close()
    Craft.at = nil
    drop()
end

RegisterNUICallback('craft', function(data, cb)
    local seconds = Config.Crafting.seconds or 0
    local amount = math.max(1, math.min(10, math.floor(tonumber(data and data.amount) or 1)))

    XSM.Send('close')
    SetNuiFocus(false, false)
    drop()

    if seconds > 0 then
        if not Anim.Work(seconds * amount, 'Making it') then
            -- The panel was stepped aside, not closed: XSM.open is still true,
            -- which is exactly why XSM.Open used to return without doing
            -- anything here. A cancelled craft left the bench shut, focus
            -- gone, and the flag set — so nothing could open it again all
            -- session. Put the same screen back the way the success path does.
            XSM.Unhide('craft')
            cb({ ok = false })
            return
        end
    end

    local result = lib.callback.await('XS-Mechanic:craft', false, {
        shop = Craft.at and Craft.at.shop,
        item = data and data.item,
        amount = amount,
    })

    if result and result.message then XSM.Notify(result.message, 'success')
    elseif result and result.error then XSM.Notify(result.error, 'error') end

    -- Straight back to the bench, because nobody makes one of anything.
    local point = Craft.at

    if point and XSM.open then
        local shop = XSM.ShopById(point.shop)
        local placed

        for _, entry in ipairs(shop and shop.points or {}) do
            if entry.id == point.point then placed = entry break end
        end

        if placed then look(placed) end

        SetNuiFocus(true, true)
        XSM.Send('open', { mode = 'bench', state = XSM.state, panel = 'craft' })
        XSM.Refresh()
    end

    cb(result or { ok = false })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    drop()
end)
