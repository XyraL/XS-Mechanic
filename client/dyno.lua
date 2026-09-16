Dyno = { running = false }

--[[ A run holds the car still, sweeps it through the rev range and reads the
     result off the handling values and what is fitted.

     The numbers are plausible rather than physical. GTA has no engine model to
     interrogate, so horsepower is derived from drive force, mass and gearing,
     which means two cars that feel different read differently and the same car
     reads the same twice. That is what a dyno is for here. ]]

local SAMPLES = 30

local function estimate(vehicle)
    local model = GetEntityModel(vehicle)

    local force = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce') or 0.3
    local topSpeed = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel') or 150.0
    local mass = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fMass') or 1500.0
    local gears = GetVehicleHandlingInt(vehicle, 'CHandlingData', 'nInitialDriveGears') or 5

    -- Tuned so a stock Sultan lands near 300 and a stock Adder near 700.
    local hp = force * mass * 0.92 + topSpeed * 1.35
    local torque = hp * (0.72 + (gears / 40))

    return {
        hp = math.floor(hp),
        torque = math.floor(torque),
        mass = math.floor(mass),
        gears = gears,
        topSpeed = math.floor(topSpeed * 1.32),
    }
end

local function curve(peak)
    local points = {}

    for i = 1, SAMPLES do
        local x = i / SAMPLES

        -- Rises quickly, peaks around three quarters of the range, tails off.
        local shape = math.sin(x * 2.4) * (1.0 - (x * 0.22))
        points[#points + 1] = math.max(0, math.floor(peak * shape))
    end

    return points
end

function Dyno.Run()
    if Dyno.running then return end

    local vehicle = XSM.vehicle

    if not vehicle or not DoesEntityExist(vehicle) then
        XSM.Toast('Nothing connected.', 'error')
        return
    end

    local allowed = lib.callback.await('XS-Mechanic:dynoCheck', false, {
        shop = XSM.shop and XSM.shop.id,
        netId = VehToNet(vehicle),
    })

    if not allowed or not allowed.ok then
        XSM.Toast(allowed and allowed.error or 'Not on a dyno bay.', 'error')
        return
    end

    Dyno.running = true
    XSM.Send('dyno', { state = 'running', points = {}, peak = 0 })

    local stats = estimate(vehicle)
    local points = curve(stats.hp)
    local torqueCurve = curve(stats.torque)

    FreezeEntityPosition(vehicle, true)
    SetVehicleEngineOn(vehicle, true, true, false)

    local shown = {}

    for i = 1, SAMPLES do
        if not Dyno.running then break end

        -- A run holds this handle for thirty seconds. Plenty of time for the
        -- car to be stored, deleted or streamed out, after which every native
        -- below throws "Tried to access invalid entity" once per sample.
        if not DoesEntityExist(vehicle) then
            Dyno.running = false
            XSM.Send('dyno', { state = 'idle', points = {}, peak = 0 })
            XSM.Toast('The vehicle left the bay.', 'error')
            return
        end

        shown[#shown + 1] = { hp = points[i], torque = torqueCurve[i], rpm = math.floor(1000 + (i / SAMPLES) * 7000) }

        SetVehicleCurrentRpm(vehicle, 0.2 + (i / SAMPLES) * 0.8)

        XSM.Send('dyno', {
            state = 'running',
            points = shown,
            peak = stats.hp,
            progress = math.floor((i / SAMPLES) * 100),
        })

        Wait((Config.Dyno.seconds * 1000) / SAMPLES)
    end

    if DoesEntityExist(vehicle) then
        SetVehicleCurrentRpm(vehicle, 0.2)
        FreezeEntityPosition(vehicle, false)
    end

    Dyno.running = false

    if #shown == 0 then return end

    local result = {
        state = 'done',
        points = shown,
        peak = stats.hp,
        stats = stats,
        plate = XSM.catalogue and XSM.catalogue.plate,
        name = XSM.catalogue and XSM.catalogue.name,
    }

    XSM.Send('dyno', result)
    XSM.lastDyno = result
end

function Dyno.Stop()
    Dyno.running = false
end

-- Sharing puts the sheet in front of whoever is stood nearby, which is how a
-- mechanic shows a customer what they just paid for.
function Dyno.Share()
    if not XSM.lastDyno then
        XSM.Toast('Run one first.', 'error')
        return
    end

    TriggerServerEvent('XS-Mechanic:server:shareDyno', {
        plate = XSM.lastDyno.plate,
        name = XSM.lastDyno.name,
        stats = XSM.lastDyno.stats,
    })
end

RegisterNetEvent('XS-Mechanic:client:dynoSheet', function(sheet)
    lib.alertDialog({
        header = ('Dyno · %s'):format(sheet.name or 'Vehicle'),
        content = ([[
**%d hp**  ·  **%d lb-ft**

Plate %s
Top speed around %d mph
%d gears, %d kg
        ]]):format(
            sheet.stats.hp, sheet.stats.torque,
            sheet.plate or '——', sheet.stats.topSpeed,
            sheet.stats.gears, sheet.stats.mass),
        centered = true,
    })
end)
