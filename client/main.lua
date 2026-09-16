XSM = {
    open = false,
    mode = 'tablet',
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
end

-- mode is 'tablet', 'desk', 'bay' or 'builder'.
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
