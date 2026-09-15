Preview = {}

local original = nil
local camera = nil

local ANGLES = {
    cosmetics   = { pitch = -8.0,  yaw = 215.0, dist = 5.2 },
    wheels      = { pitch = -14.0, yaw = 270.0, dist = 3.6 },
    performance = { pitch = -6.0,  yaw = 180.0, dist = 5.6 },
    respray     = { pitch = -10.0, yaw = 230.0, dist = 6.4 },
    lights      = { pitch = -6.0,  yaw = 190.0, dist = 4.6 },
    interior    = { pitch = -18.0, yaw = 300.0, dist = 2.6 },
    livery      = { pitch = -22.0, yaw = 250.0, dist = 6.0 },
    plate       = { pitch = -12.0, yaw = 0.0,   dist = 3.2 },
    extras      = { pitch = -8.0,  yaw = 215.0, dist = 5.6 },
}

-- Everything that can be put back is recorded before the first change, so
-- walking away leaves the car exactly as it arrived.
local function remember(vehicle)
    if original then return end

    SetVehicleModKit(vehicle, 0)

    local mods = {}
    for _, entry in ipairs(Mods.Slots) do
        mods[entry.slot] = GetVehicleMod(vehicle, entry.slot)
    end

    local primary, secondary = GetVehicleColours(vehicle)
    local pearl, wheelColour = GetVehicleExtraColours(vehicle)

    original = {
        mods = mods,
        wheelType = GetVehicleWheelType(vehicle),
        wheelVariation = GetVehicleModVariation(vehicle, 23),
        primary = primary, secondary = secondary,
        pearl = pearl, wheelColour = wheelColour,
        livery = GetVehicleLivery(vehicle),
        plate = GetVehicleNumberPlateTextIndex(vehicle),
        tint = GetVehicleWindowTint(vehicle),
        xenon = GetVehicleXenonLightsColour and GetVehicleXenonLightsColour(vehicle) or -1,
    }
end

function Preview.Snapshot(vehicle)
    remember(vehicle)
end

local function startCam(vehicle, category)
    if not Config.Tuning.preview then return end

    local angle = ANGLES[category] or ANGLES.cosmetics

    if not camera then
        camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(camera, true)
        RenderScriptCams(true, true, 500, true, true)
    end

    local coords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle) + angle.yaw
    local rad = math.rad(heading)

    SetCamCoord(camera,
        coords.x + math.sin(rad) * -angle.dist,
        coords.y + math.cos(rad) * -angle.dist,
        coords.z + 0.85)

    PointCamAtEntity(camera, vehicle, 0.0, 0.0, 0.0, true)
    SetCamFov(camera, 52.0)
end

function Preview.StopCam()
    if not camera then return end

    RenderScriptCams(false, true, 500, true, true)
    SetCamActive(camera, false)
    DestroyCam(camera, true)
    camera = nil
end

-- Applies a change for looking at only. Nothing is paid for and nothing is
-- saved until the panel says apply.
function Preview.Show(data)
    local vehicle = XSM.vehicle
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    remember(vehicle)
    SetVehicleModKit(vehicle, 0)

    local slot = tonumber(data.slot)
    local index = tonumber(data.index)

    if data.slotId == 'wheels' then
        SetVehicleWheelType(vehicle, tonumber(data.wheelType) or original.wheelType)
        SetVehicleMod(vehicle, 23, index, GetVehicleModVariation(vehicle, 23))
        if GetVehicleClass(vehicle) == 8 then SetVehicleMod(vehicle, 24, index, false) end
    elseif data.slotId == 'plate' then
        SetVehicleNumberPlateTextIndex(vehicle, index)
    elseif data.legacy then
        SetVehicleLivery(vehicle, index)
    elseif slot then
        if index == -1 then
            RemoveVehicleMod(vehicle, slot)
        else
            SetVehicleMod(vehicle, slot, index, false)
        end
    end

    XSM.preview = data
    startCam(vehicle, data.category)

    return true
end

function Preview.Respray(data)
    local vehicle = XSM.vehicle
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    remember(vehicle)

    local primary, secondary = GetVehicleColours(vehicle)

    if data.custom then
        local hex = tostring(data.hex or ''):gsub('#', '')
        local r = tonumber(hex:sub(1, 2), 16) or 0
        local g = tonumber(hex:sub(3, 4), 16) or 0
        local b = tonumber(hex:sub(5, 6), 16) or 0

        if data.custom == 'primary' then
            SetVehicleCustomPrimaryColour(vehicle, r, g, b)
        else
            SetVehicleCustomSecondaryColour(vehicle, r, g, b)
        end
    elseif data.part == 'primary' then
        SetVehicleColours(vehicle, tonumber(data.index) or primary, secondary)
    else
        SetVehicleColours(vehicle, primary, tonumber(data.index) or secondary)
    end

    XSM.preview = { category = 'respray', slotId = 'respray', label = 'Respray', price = data.price }
    startCam(vehicle, 'respray')

    return true
end

function Preview.Extra(id, on)
    local vehicle = XSM.vehicle
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    remember(vehicle)
    SetVehicleExtra(vehicle, tonumber(id) or 0, on and 0 or 1)

    return true
end

-- Puts the vehicle back the way it was found. `full` also drops the camera,
-- which is what closing the panel wants.
function XSM.StopPreview(full)
    local vehicle = XSM.vehicle

    if original and vehicle and DoesEntityExist(vehicle) and Config.Tuning.restoreOnCancel then
        SetVehicleModKit(vehicle, 0)

        SetVehicleWheelType(vehicle, original.wheelType)

        for slot, index in pairs(original.mods) do
            if index == -1 then
                RemoveVehicleMod(vehicle, slot)
            else
                SetVehicleMod(vehicle, slot, index, slot == 23 and original.wheelVariation or false)
            end
        end

        SetVehicleColours(vehicle, original.primary, original.secondary)
        SetVehicleExtraColours(vehicle, original.pearl, original.wheelColour)
        SetVehicleLivery(vehicle, original.livery)
        SetVehicleNumberPlateTextIndex(vehicle, original.plate)
        SetVehicleWindowTint(vehicle, original.tint)
    end

    original = nil
    XSM.preview = nil

    if full then Preview.StopCam() end
end

-- Called once the server has taken the money: what is on the car right now
-- becomes the truth, so there is nothing to put back.
function Preview.Commit()
    original = nil
    XSM.preview = nil
    Preview.StopCam()

    local vehicle = XSM.vehicle
    if vehicle and DoesEntityExist(vehicle) then
        TriggerServerEvent('XS-Mechanic:server:saveMods', VehToNet(vehicle))
    end
end

-- Only the client that owns the entity can read the fitted mods back off it,
-- so the server asks rather than trying to look itself. The answer goes into
-- the framework's own player_vehicles.mods column, which every QB/QBox garage
-- already re-applies on spawn — there is nothing further to integrate.
RegisterNetEvent('XS-Mechanic:client:readMods', function(netId)
    if not NetworkDoesNetworkIdExist(netId) then return end

    local vehicle = NetToVeh(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local plate = Util.Trim(GetVehicleNumberPlateText(vehicle) or '')
    if plate == '' then return end

    local props
    local ok = pcall(function() props = lib.getVehicleProperties(vehicle) end)
    if not ok or not props then return end

    TriggerServerEvent('XS-Mechanic:server:storeMods', plate, props)
end)
