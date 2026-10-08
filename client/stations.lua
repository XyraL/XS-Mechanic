Stations = {}

local prompt = false

local function allowed(shop)
    local job = Framework.GetJob()

    for _, name in ipairs(shop.stationJobs or {}) do
        if name == job then return true end
    end

    return false
end

-- The service bay the car is sat on, for a station this player can use.
local function bayUnder(vehicle)
    local coords = GetEntityCoords(vehicle)

    for _, shop in ipairs(XSM.shops or {}) do
        if shop.kind == 'station' and allowed(shop) then
            for _, point in ipairs(shop.points or {}) do
                if point.kind == 'station' then
                    local at = vector3(point.coords.x, point.coords.y, point.coords.z)
                    if #(coords - at) <= (point.radius or 4.0) then return shop, point end
                end
            end
        end
    end

    return nil
end

Stations.BayUnder = bayUnder
Stations.CanUse = allowed

local function hidePrompt()
    if prompt then
        lib.hideTextUI()
        prompt = false
    end
end

function Stations.Open(shop, vehicle)
    XSM.basket = {}
    XSM.PushBasket()
    XSM.StopPreview(false)
    XSM.vehicle = vehicle

    XSM.Open('station', shop.id)
end

local function check(offer, picks)
    local vehicle = XSM.Vehicle()
    if not vehicle then return false, 'No vehicle.' end

    local result = lib.callback.await('XS-Mechanic:stationCheck', false, {
        shop = XSM.shop and XSM.shop.id,
        offer = offer,
        netId = VehToNet(vehicle),
        picks = picks,
    })

    if not result or not result.ok then
        return false, result and result.error or 'That did not go through.'
    end

    return true, vehicle
end

-- Everything picked goes on the car for good. Nothing is charged and nothing
-- goes on a work order — a station is a department setting up its own cars.
function Stations.Apply()
    if #(XSM.basket or {}) == 0 then return end

    local ok, err = check(nil, XSM.basket)

    if not ok then
        XSM.Toast(err, 'error')
        return
    end

    Preview.Commit()
    XSM.basket = {}
    XSM.PushBasket()
    XSM.PushVehicle()
    XSM.Toast('Done. It is on the car.', 'good')
end

local function work(seconds, label)
    return lib.progressCircle({
        duration = math.floor((tonumber(seconds) or 0) * 1000),
        label = label,
        position = 'bottom',
        canCancel = true,
        disable = { car = true, combat = true },
    }) == true
end

function Stations.Repair()
    local ok, vehicle = check('repair')

    if not ok then
        XSM.Toast(vehicle, 'error')
        return
    end

    if GetVehicleEngineHealth(vehicle) >= 995.0 and GetVehicleBodyHealth(vehicle) >= 995.0 then
        XSM.Toast('Nothing wrong with it.', 'inform')
        return
    end

    XSM.Hide()

    if work(Config.Stations.repairSeconds, 'Repairing') then
        Repair.Apply(vehicle, 100, 100)
        XSM.Notify('Repaired.', 'success')
    end

    XSM.Unhide('repairs')
    XSM.PushVehicle()
end

function Stations.Wash()
    local ok, vehicle = check('wash')

    if not ok then
        XSM.Toast(vehicle, 'error')
        return
    end

    if GetVehicleDirtLevel(vehicle) <= 0.1 then
        XSM.Toast('It is already clean.', 'inform')
        return
    end

    XSM.Hide()

    if work(Config.Stations.washSeconds, 'Washing') then
        SetVehicleDirtLevel(vehicle, 0.0)
        XSM.Notify('Washed.', 'success')
    end

    XSM.Unhide('repairs')
end

-- Drive on, press the key, without getting out. Driving off the bay with the
-- panel up closes it, and whatever was picked but not applied comes back off.
CreateThread(function()
    while true do
        local wait = 750
        local ped = cache.ped
        local vehicle = cache.vehicle

        if vehicle and GetPedInVehicleSeat(vehicle, -1) == ped then
            local shop = bayUnder(vehicle)

            if XSM.open and XSM.mode == 'station' then
                hidePrompt()
                if not shop or (XSM.shop and shop.id ~= XSM.shop.id) then XSM.Close() end
            elseif shop and not XSM.open then
                wait = 0

                if not prompt then
                    lib.showTextUI(('[E] Service vehicle — %s'):format(shop.name), { position = 'left-center' })
                    prompt = true
                end

                if IsControlJustPressed(0, 38) then
                    hidePrompt()
                    Stations.Open(shop, vehicle)
                end
            else
                hidePrompt()
            end
        else
            hidePrompt()

            if XSM.open and XSM.mode == 'station' then XSM.Close() end
        end

        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    hidePrompt()
end)
