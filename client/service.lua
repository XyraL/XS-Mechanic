Odometer = {}

--[[ Distance is counted by whoever is driving and reported in batches. The
     server caps what it will accept per report, so a client that lies can
     drift its own odometer a little and no further.

     Wear itself is worked out on the SERVER from the distance, never sent by
     the client — otherwise every car on the map would be one edited resource
     away from a free service. ]]

local last = nil
local banked = 0.0

local REPORT_METRES = 250.0

local function plateOf(vehicle)
    return Util.Trim(GetVehicleNumberPlateText(vehicle) or '')
end

CreateThread(function()
    while true do
        Wait(1000)

        if not Config.Service.enabled then
            last = nil
            goto continue
        end

        do
            local ped = cache.ped
            local vehicle = GetVehiclePedIsIn(ped, false)

            if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
                last = nil
                goto continue
            end

            local coords = GetEntityCoords(vehicle)

            if last then
                local moved = #(coords - last)

                -- A teleport, a garage spawn or a respawn is not mileage.
                if moved < 200.0 then banked = banked + moved end
            end

            last = coords

            if banked >= REPORT_METRES then
                TriggerServerEvent('XS-Mechanic:server:odometer', plateOf(vehicle), banked)
                banked = 0.0
            end
        end

        ::continue::
    end
end)

Odometer.Report = function()
    local ped = cache.ped
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 and banked > 0 then
        TriggerServerEvent('XS-Mechanic:server:odometer', plateOf(vehicle), banked)
        banked = 0.0
    end
end

-- Anything left over is worth sending before the client goes away.
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Odometer.Report()
end)

ServiceUI = {}

function ServiceUI.Replace(partId)
    local vehicle = XSM.vehicle

    if not vehicle or not DoesEntityExist(vehicle) then
        XSM.Toast('Nothing connected.', 'error')
        return
    end

    local part = Service.ById[partId]
    if not part then return end

    local allowed = lib.callback.await('XS-Mechanic:serviceCheck', false, {
        plate = XSM.catalogue and XSM.catalogue.plate,
        part = partId,
    })

    if not allowed or not allowed.ok then
        XSM.Toast(allowed and allowed.error or 'You cannot do that.', 'error')
        return
    end

    XSM.Close()

    lib.requestAnimDict('mini@repair', 3000)
    TaskPlayAnim(cache.ped, 'mini@repair', 'fixing_a_ped', 8.0, -8.0, -1, 1, 0.0, false, false, false)

    local done = lib.progressCircle({
        duration = (Config.Service.replaceSeconds or 10) * 1000,
        label = ('Replacing %s'):format(part.label),
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })

    ClearPedTasks(cache.ped)

    if not done then return end

    local result = lib.callback.await('XS-Mechanic:serviceReplace', false, {
        shop = XSM.shop and XSM.shop.id,
        plate = XSM.catalogue and XSM.catalogue.plate,
        part = partId,
    })

    if not result or not result.ok then
        XSM.Notify(result and result.error or 'That did not go through.', 'error')
        return
    end

    XSM.Notify(('%s replaced.'):format(part.label), 'success')
    XSM.Open('tablet', XSM.shop and XSM.shop.id)
end
