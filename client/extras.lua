Nitrous = { active = false }
Lighting = {}

--[[ Two items that live in a player's pocket rather than in a shop.

     NOS is a burst of speed with a tank that refills over time. Lighting is a
     remote for the xenons and the underglow, including the effects that make a
     car meet worth turning up to. Both are entirely optional and both are off
     unless the item is configured. ]]

local tank = 100.0
local boosting = false

local function driving()
    local ped = cache.ped
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then return nil end
    return vehicle
end

function Nitrous.Toggle()
    if not Config.Nitrous.enabled then return end

    local vehicle = driving()

    if not vehicle then
        XSM.Notify('Not driving anything.', 'error')
        return
    end

    if not Perf.Profile(vehicle) or not (Perf.Profile(vehicle).performance or {}).nos then
        XSM.Notify('Nothing fitted to this car.', 'error')
        return
    end

    Nitrous.active = not Nitrous.active
    XSM.Notify(Nitrous.active and 'Nitrous armed.' or 'Nitrous off.', 'inform')
end

CreateThread(function()
    while true do
        local wait = 500

        if Nitrous.active and Config.Nitrous.enabled then
            local vehicle = driving()

            if vehicle then
                wait = 0

                local holding = IsControlPressed(0, Config.Nitrous.control)

                if holding and tank > 0 then
                    boosting = true
                    tank = math.max(0, tank - (Config.Nitrous.drainPerSecond * GetFrameTime()))

                    SetVehicleBoostActive(vehicle, true)
                    SetVehicleForwardSpeed(vehicle, GetEntitySpeed(vehicle) + Config.Nitrous.push * GetFrameTime())
                    StartParticleFxNonLoopedOnEntity('veh_backfire', vehicle, 0.0, -2.5, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
                else
                    if boosting then
                        SetVehicleBoostActive(vehicle, false)
                        boosting = false
                    end

                    tank = math.min(100, tank + (Config.Nitrous.refillPerSecond * (GetFrameTime() > 0 and GetFrameTime() or 0.016)))
                end
            else
                Nitrous.active = false
            end
        end

        Wait(wait)
    end
end)

function Nitrous.Level()
    return math.floor(tank)
end

local EFFECTS = { 'off', 'static', 'rainbow', 'flash', 'pulse' }

local effect = 'static'
local colour = { r = 0, g = 140, b = 255 }

function Lighting.Open()
    if not Config.Lighting.enabled then return end

    local vehicle = driving() or lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0, true)

    if not vehicle or vehicle == 0 then
        XSM.Notify('Stand next to a vehicle.', 'error')
        return
    end

    local input = lib.inputDialog('Lighting', {
        { type = 'select', label = 'Effect', default = effect, options = {
            { value = 'off', label = 'Off' },
            { value = 'static', label = 'Solid' },
            { value = 'rainbow', label = 'Rainbow' },
            { value = 'flash', label = 'Flash' },
            { value = 'pulse', label = 'Pulse' },
        } },
        { type = 'color', label = 'Colour', default = ('#%02x%02x%02x'):format(colour.r, colour.g, colour.b) },
        { type = 'checkbox', label = 'Underglow', checked = true },
        { type = 'checkbox', label = 'Xenons', checked = true },
    })

    if not input then return end

    effect = input[1] or 'static'

    local hex = tostring(input[2] or ''):gsub('#', '')
    colour = {
        r = tonumber(hex:sub(1, 2), 16) or 0,
        g = tonumber(hex:sub(3, 4), 16) or 0,
        b = tonumber(hex:sub(5, 6), 16) or 0,
    }

    Lighting.Set(vehicle, effect, colour, input[3], input[4])
end

local running = {}

function Lighting.Set(vehicle, mode, rgb, underglow, xenons)
    if not vehicle or vehicle == 0 then return end

    local netId = VehToNet(vehicle)
    running[netId] = { mode = mode, rgb = rgb, underglow = underglow, xenons = xenons }

    for side = 0, 3 do
        SetVehicleNeonLightEnabled(vehicle, side, mode ~= 'off' and underglow and true or false)
    end

    ToggleVehicleMod(vehicle, 22, mode ~= 'off' and xenons and true or false)

    if mode == 'off' then
        running[netId] = nil
        return
    end

    SetVehicleNeonLightsColour(vehicle, rgb.r, rgb.g, rgb.b)

    if xenons then
        pcall(function() SetVehicleXenonLightsCustomColor(vehicle, rgb.r, rgb.g, rgb.b) end)
    end
end

-- Only the effects that actually change frame to frame need a loop, and the
-- loop stops itself the moment nothing is running.
CreateThread(function()
    local tick = 0

    while true do
        local wait = 400
        local any = false

        for netId, entry in pairs(running) do
            -- Ask whether the id resolves before asking for the entity. NetToVeh
            -- logs a warning for an id this client cannot see, and this loop
            -- runs several times a second — a vehicle that streams out would
            -- otherwise warn forever.
            if not NetworkDoesNetworkIdExist(netId) then
                running[netId] = nil
                goto continue
            end

            local vehicle = NetToVeh(netId)

            if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
                running[netId] = nil
                goto continue
            end

            if entry.mode == 'rainbow' or entry.mode == 'flash' or entry.mode == 'pulse' then
                any = true
                wait = entry.mode == 'flash' and 120 or 40

                local r, g, b = entry.rgb.r, entry.rgb.g, entry.rgb.b

                if entry.mode == 'rainbow' then
                    local hue = (tick % 360) / 360
                    r = math.floor((math.sin(hue * 6.283) * 0.5 + 0.5) * 255)
                    g = math.floor((math.sin(hue * 6.283 + 2.094) * 0.5 + 0.5) * 255)
                    b = math.floor((math.sin(hue * 6.283 + 4.188) * 0.5 + 0.5) * 255)
                elseif entry.mode == 'flash' then
                    local on = (tick % 2) == 0
                    r, g, b = on and r or 0, on and g or 0, on and b or 0
                else
                    local pulse = (math.sin(tick / 8) * 0.4 + 0.6)
                    r, g, b = math.floor(r * pulse), math.floor(g * pulse), math.floor(b * pulse)
                end

                SetVehicleNeonLightsColour(vehicle, r, g, b)
            end

            ::continue::
        end

        tick = tick + 1

        if not any then wait = 500 end
        Wait(wait)
    end
end)

RegisterNetEvent('XS-Mechanic:client:useNitrous', function()
    Nitrous.Toggle()
end)

RegisterNetEvent('XS-Mechanic:client:useLighting', function()
    Lighting.Open()
end)
