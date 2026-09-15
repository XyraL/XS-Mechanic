Repair = {}

local function animate(seconds, label, atEngine)
    local ped = cache.ped
    local vehicle = XSM.vehicle

    if atEngine and vehicle and DoesEntityExist(vehicle) then
        SetVehicleDoorOpen(vehicle, 4, false, false)
    end

    lib.requestAnimDict('mini@repair', 3000)
    TaskPlayAnim(ped, 'mini@repair', 'fixing_a_ped', 8.0, -8.0, -1, 1, 0.0, false, false, false)

    local ok = lib.progressCircle({
        duration = seconds * 1000,
        label = label,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })

    ClearPedTasks(ped)

    if atEngine and vehicle and DoesEntityExist(vehicle) then
        SetVehicleDoorShut(vehicle, 4, false)
    end

    return ok
end

function Repair.AtBay(shop, point)
    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords, 8.0, true)

    if not vehicle or vehicle == 0 then
        XSM.Notify('Drive a vehicle onto the bay first.', 'error')
        return
    end

    local engine = GetVehicleEngineHealth(vehicle)
    local body = GetVehicleBodyHealth(vehicle)

    if engine >= 995.0 and body >= 995.0 then
        XSM.Notify('Nothing wrong with it.', 'inform')
        return
    end

    local model = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) or '')

    local quote = lib.callback.await('XS-Mechanic:repairQuote', false, {
        shop = shop.id, model = model, class = GetVehicleClass(vehicle),
    })

    if not quote or not quote.ok then
        XSM.Notify(quote and quote.error or 'That cannot be repaired here.', 'error')
        return
    end

    local confirm = lib.alertDialog({
        header = 'Repair',
        content = ('Full repair on this vehicle costs **%s**.'):format(Util.Money(quote.price)),
        centered = true,
        cancel = true,
    })

    if confirm ~= 'confirm' then return end

    if not animate(Config.Repair.bay.seconds, 'Repairing', true) then return end

    local done = lib.callback.await('XS-Mechanic:repair', false, {
        shop = shop.id, how = 'bay', netId = VehToNet(vehicle), price = quote.price,
    })

    if not done or not done.ok then
        XSM.Notify(done and done.error or 'That did not go through.', 'error')
        return
    end

    Repair.Apply(vehicle, 100, 100)
    XSM.Notify('Repaired.', 'success')
end

function Repair.Apply(vehicle, enginePct, bodyPct)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local engine = math.min(1000.0, GetVehicleEngineHealth(vehicle) + (enginePct / 100 * 1000))
    local body = math.min(1000.0, GetVehicleBodyHealth(vehicle) + (bodyPct / 100 * 1000))

    SetVehicleEngineHealth(vehicle, engine)
    SetVehicleBodyHealth(vehicle, body)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)

    if engine >= 999.0 and body >= 999.0 then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
    end

    SetVehicleEngineOn(vehicle, true, true, false)
end

-- Kits are used on whatever vehicle you are stood at, with no shop involved.
function Repair.UseKit(item)
    local kit = Config.Repair.kits[item]
    if not kit then return end

    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords, 5.0, true)

    if not vehicle or vehicle == 0 then
        XSM.Notify('Stand next to a vehicle.', 'error')
        return
    end

    if GetVehicleEngineHealth(vehicle) >= 995.0 and GetVehicleBodyHealth(vehicle) >= 995.0 then
        XSM.Notify('Nothing wrong with it.', 'inform')
        return
    end

    if kit.atEngine then
        local bonnet = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'bonnet'))

        if bonnet and #(coords - bonnet) > 2.4 then
            XSM.Notify('Get to the front of the vehicle.', 'error')
            return
        end
    end

    local allowed = lib.callback.await('XS-Mechanic:kitCheck', false, {
        item = item, netId = VehToNet(vehicle),
    })

    if not allowed or not allowed.ok then
        XSM.Notify(allowed and allowed.error or 'You cannot use that here.', 'error')
        return
    end

    if not animate(kit.seconds, kit.label, kit.atEngine) then return end

    local done = lib.callback.await('XS-Mechanic:repair', false, {
        how = 'kit', item = item, netId = VehToNet(vehicle),
    })

    if not done or not done.ok then
        XSM.Notify(done and done.error or 'That did not go through.', 'error')
        return
    end

    Repair.Apply(vehicle, kit.engine, kit.body)
    XSM.Notify(('Used the %s.'):format(kit.label), 'success')
end

function Repair.Wash()
    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords, 6.0, true)

    if not vehicle or vehicle == 0 then
        XSM.Notify('Stand next to a vehicle.', 'error')
        return
    end

    if GetVehicleDirtLevel(vehicle) < 1.0 then
        XSM.Notify('It is already clean.', 'inform')
        return
    end

    if not animate(Config.Repair.wash.seconds, 'Washing', false) then return end

    SetVehicleDirtLevel(vehicle, 0.0)
    XSM.Notify('Washed.', 'success')
end

RegisterNetEvent('XS-Mechanic:client:useKit', function(item)
    Repair.UseKit(item)
end)
