XSM = {
    open = false,
    mode = 'tablet',
    panel = 'vehicle',
    shops = {},
    shop = nil,
    vehicle = nil,
    catalogue = nil,
    state = {},
    preview = nil,
}

function XSM.Notify(message, kind)
    Framework.Notify(message, kind)
end

function XSM.Send(action, payload)
    payload = payload or {}
    payload.action = action
    SendNUIMessage(Util.Plain(payload))
end

function XSM.Toast(message, kind)
    XSM.Send('toast', { message = message, kind = kind })
end

function XSM.Close()
    if not XSM.open then return end

    XSM.open = false
    SetNuiFocus(false, false)
    XSM.Send('close')
    XSM.StopPreview(true)
    Anim.Stop()
    Showcase.Stop()
    Craft.Close()
end

-- mode is 'tablet', 'desk', 'bay', 'bench' or 'builder'.
function XSM.Open(mode, shopId)
    if XSM.open then return end

    local payload = lib.callback.await('XS-Mechanic:bootstrap', false, { mode = mode, shop = shopId })

    if not payload or not payload.ok then
        XSM.Notify(payload and payload.error or 'You cannot use that here.', 'error')
        return
    end

    XSM.mode = mode
    XSM.shop = payload.state and payload.state.shop or nil
    XSM.state = payload.state or {}
    XSM.open = true

    SetNuiFocus(true, true)
    XSM.Send('open', { mode = mode, state = payload.state })

    if mode == 'tablet' then Anim.Start() end
    if XSM.vehicle then Showcase.Start(XSM.vehicle) end

    if XSM.vehicle then XSM.PushVehicle() end
end

function XSM.Show(panel)
    if not XSM.open then return end
    XSM.Send('open', { mode = XSM.mode, state = XSM.state, panel = panel })
end

--[[ Stepping the panel aside to do something in the world.

     Not the same as closing it. Closing puts the vehicle back and lets go of
     the connection, which is exactly wrong halfway through fitting the part
     somebody is standing there paying for. ]]
function XSM.Hide()
    if not XSM.open then return end

    XSM.Send('close')
    SetNuiFocus(false, false)
    Anim.Stop()
    Showcase.Stop()
end

function XSM.Unhide(panel)
    if not XSM.open then return end

    SetNuiFocus(true, true)
    XSM.Send('open', { mode = XSM.mode, state = XSM.state, panel = panel })

    if XSM.mode == 'tablet' then Anim.Start() end
    if XSM.vehicle then Showcase.Start(XSM.vehicle) end
end

function XSM.Refresh()
    if not XSM.open then return end

    local payload = lib.callback.await('XS-Mechanic:state', false, { mode = XSM.mode, shop = XSM.shop and XSM.shop.id })
    if not payload then return end

    XSM.state = payload
    XSM.Send('state', { state = payload })
end

local function className(class)
    local names = {
        [0] = 'Compact', 'Sedan', 'SUV', 'Coupe', 'Muscle', 'Sports Classic', 'Sports',
        'Super', 'Motorcycle', 'Off-road', 'Industrial', 'Utility', 'Van', 'Cycle',
        'Boat', 'Helicopter', 'Plane', 'Service', 'Emergency', 'Military', 'Commercial',
    }
    return names[class] or 'Vehicle'
end

-- The handling natives take the ENTITY, not the model name.
local function driveOf(vehicle)
    local bias = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveBiasFront')
    if not bias then return nil end
    if bias >= 0.99 then return 'FWD' end
    if bias <= 0.01 then return 'RWD' end
    return 'AWD'
end

function XSM.PushVehicle()
    if not XSM.vehicle or not DoesEntityExist(XSM.vehicle) then
        XSM.Send('vehicle', { vehicle = false, catalogue = false })
        return
    end

    local catalogue = Catalogue.Build(XSM.vehicle)
    if not catalogue then return end

    XSM.catalogue = catalogue

    local profile = lib.callback.await('XS-Mechanic:vehicle', false, {
        plate = catalogue.plate,
        model = catalogue.model,
    }) or {}

    local vehicle = {
        plate = catalogue.plate,
        model = catalogue.model,
        name = catalogue.name,
        class = catalogue.class,
        className = className(catalogue.class),
        drive = driveOf(XSM.vehicle),
        electric = catalogue.electric,
        owner = profile.owner,
        odometer = profile.odometer or 0,
        output = profile.output,
        outputPercent = profile.outputPercent,
        health = catalogue.health,
        service = profile.service or { due = 0 },
        tuning = profile.tuning or {},
        stance = profile.stance,
        performance = profile.performance or {},
    }

    XSM.Send('vehicle', { vehicle = vehicle, catalogue = catalogue })

    Hud.Update()
end

-- The full shop, with its boundary and points on it, rather than the trimmed
-- copy the panel is given.
function XSM.ShopById(id)
    if not id then return nil end

    for _, shop in ipairs(XSM.shops or {}) do
        if shop.id == id then return shop end
    end

    return nil
end

function XSM.Connect()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, Config.Tablet.connectDistance, true)

    if not vehicle or vehicle == 0 then
        XSM.Toast('No vehicle close enough.', 'error')
        return false
    end

    local model = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) or '')

    for _, blocked in ipairs(Config.Tuning.blockedModels or {}) do
        if string.lower(blocked) == model then
            XSM.Toast('That vehicle cannot be worked on.', 'error')
            return false
        end
    end

    -- A tablet in your pocket is not a workshop. With a boundary drawn, both
    -- the mechanic and the car have to be inside it.
    if Config.Tablet.insideShopOnly then
        local shop = XSM.ShopById(XSM.shop and XSM.shop.id)

        if shop and Util.HasArea(shop.area) then
            if not Util.InsideArea(coords, shop.area) then
                XSM.Toast(('You have to be at %s to work on anything.'):format(shop.name), 'error')
                return false
            end

            if not Util.InsideArea(GetEntityCoords(vehicle), shop.area) then
                XSM.Toast('That vehicle is not in the shop. Bring it in.', 'error')
                return false
            end
        end
    end

    XSM.StopPreview(false)
    XSM.vehicle = vehicle
    XSM.PushVehicle()
    if XSM.open then Showcase.Start(vehicle) end
    XSM.Toast('Connected to ' .. (XSM.catalogue and XSM.catalogue.name or 'the vehicle') .. '.', 'good')
    return true
end

function XSM.Disconnect()
    Showcase.Stop()
    XSM.StopPreview(true)
    XSM.vehicle = nil
    XSM.catalogue = nil
    XSM.Send('vehicle', { vehicle = false, catalogue = false })
    Hud.Update()
end

RegisterNetEvent('XS-Mechanic:client:shops', function(shops)
    XSM.shops = shops or {}
    Zones.Rebuild()
end)

RegisterNetEvent('XS-Mechanic:client:toast', function(message, kind)
    if XSM.open then XSM.Toast(message, kind) else XSM.Notify(message, kind) end
end)

RegisterNetEvent('XS-Mechanic:client:refresh', function()
    if XSM.open then XSM.Refresh() end
end)

RegisterNetEvent('XS-Mechanic:client:openTablet', function()
    XSM.Open('tablet')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    XSM.StopPreview(true)
end)

CreateThread(function()
    while not Framework.name do Wait(500) end
    Wait(1200)

    local shops = lib.callback.await('XS-Mechanic:shops', false)
    XSM.shops = shops or {}
    Zones.Rebuild()
end)

RegisterNetEvent('XS-Mechanic:client:builder', function()
    XSM.Open('builder')
end)

-- The tablet is an item, so losing it while the panel is open should close the
-- panel. Config.Tablet.checkSeconds = 0 checks only on opening.
CreateThread(function()
    while true do
        local gap = Config.Tablet.checkSeconds or 0
        Wait(gap > 0 and gap * 1000 or 5000)

        if gap > 0 and XSM.open and XSM.mode ~= 'builder' and Config.Tablet.item ~= '' then
            local holding = lib.callback.await('XS-Mechanic:holdingTablet', false)

            if holding == false then
                XSM.Notify('You no longer have the tablet.', 'error')
                XSM.Close()
            end
        end
    end
end)
