Preview = {}

--[[ Looking at work before paying for it.

     Everything a preview can touch is recorded off the vehicle before the first
     change, and put back the moment the panel closes. Nothing previewed is ever
     kept: a respray you looked at and walked away from is a respray you did not
     have.

     The record is tied to the ENTITY it came from, not to whatever the tablet
     happens to be pointed at later. Connecting to a second car while the first
     one is mid-preview used to hand the first car's settings to the second. ]]

local snapshot = nil
local camera = nil

-- Degrees around the car from its nose, the same convention the live window
-- uses: 0 the nose, 90 the driver's side, 180 the boot.
local ANGLES = {
    cosmetics   = { pitch = -10.0, yaw = 35.0,  dist = 5.2 },
    wheels      = { pitch = -6.0,  yaw = 68.0,  dist = 3.6 },
    performance = { pitch = -28.0, yaw = 18.0,  dist = 4.4 },
    respray     = { pitch = -8.0,  yaw = 90.0,  dist = 6.4 },
    lights      = { pitch = -8.0,  yaw = 0.0,   dist = 4.6 },
    interior    = { pitch = -20.0, yaw = 105.0, dist = 2.6 },
    livery      = { pitch = -10.0, yaw = 90.0,  dist = 6.0 },
    plate       = { pitch = -10.0, yaw = 180.0, dist = 3.2 },
    extras      = { pitch = -10.0, yaw = 35.0,  dist = 5.6 },
}

-- Changing anything on a vehicle somebody else owns does nothing at all, and
-- says nothing about it either.
local function control(vehicle)
    if NetworkHasControlOfEntity(vehicle) then return true end

    NetworkRequestControlOfEntity(vehicle)

    for _ = 1, 20 do
        if NetworkHasControlOfEntity(vehicle) then return true end
        Wait(25)
        NetworkRequestControlOfEntity(vehicle)
    end

    return NetworkHasControlOfEntity(vehicle)
end

Preview.Control = control

local function readExtras(vehicle)
    local out = {}

    for id = 0, 20 do
        if DoesExtraExist(vehicle, id) then
            out[id] = IsVehicleExtraTurnedOn(vehicle, id)
        end
    end

    return out
end

-- Cosmetic only. Body and engine health are deliberately left out: a mechanic
-- can repair a car mid-preview, and putting back what the car looked like must
-- never put back what it was worth fixing.
local function read(vehicle)
    SetVehicleModKit(vehicle, 0)

    local mods = {}
    for _, entry in ipairs(Mods.Slots) do
        mods[entry.slot] = GetVehicleMod(vehicle, entry.slot)
    end

    local toggles = {}
    for _, slot in ipairs({ 17, 18, 19, 20, 21, 22 }) do
        toggles[slot] = IsToggleModOn(vehicle, slot)
    end

    local primary, secondary = GetVehicleColours(vehicle)
    local pearl, wheelColour = GetVehicleExtraColours(vehicle)

    local customPrimary, customSecondary

    if GetIsVehiclePrimaryColourCustom(vehicle) then
        local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
        customPrimary = { r, g, b }
    end

    if GetIsVehicleSecondaryColourCustom(vehicle) then
        local r, g, b = GetVehicleCustomSecondaryColour(vehicle)
        customSecondary = { r, g, b }
    end

    local neon = {}
    for index = 0, 3 do
        neon[index] = IsVehicleNeonLightEnabled(vehicle, index)
    end

    local nr, ng, nb = GetVehicleNeonLightsColour(vehicle)
    local sr, sg, sb = GetVehicleTyreSmokeColor(vehicle)

    return {
        mods = mods,
        toggles = toggles,
        wheelType = GetVehicleWheelType(vehicle),
        wheelVariation = GetVehicleModVariation(vehicle, 23),
        primary = primary, secondary = secondary,
        pearl = pearl, wheelColour = wheelColour,
        customPrimary = customPrimary,
        customSecondary = customSecondary,
        livery = GetVehicleLivery(vehicle),
        plate = GetVehicleNumberPlateTextIndex(vehicle),
        tint = GetVehicleWindowTint(vehicle),
        xenon = GetVehicleXenonLightsColour(vehicle),
        neon = neon,
        neonColour = { nr, ng, nb },
        smoke = { sr, sg, sb },
        extras = readExtras(vehicle),
        chameleon = Catalogue.SupportsChameleon() and GetVehicleModColor_1(vehicle) or nil,
        stance = Stance.Read(vehicle),
    }
end

local function restore(vehicle, was)
    SetVehicleModKit(vehicle, 0)

    SetVehicleWheelType(vehicle, was.wheelType)

    for slot, index in pairs(was.mods) do
        if index == -1 then
            RemoveVehicleMod(vehicle, slot)
        else
            SetVehicleMod(vehicle, slot, index, slot == 23 and was.wheelVariation or false)
        end
    end

    for slot, on in pairs(was.toggles or {}) do
        ToggleVehicleMod(vehicle, slot, on)
    end

    -- A custom colour outranks the indexed one, so putting the indexed colour
    -- back over a custom respray changes nothing at all until it is cleared.
    -- This is what made a free paint job stick.
    if was.customPrimary then
        SetVehicleCustomPrimaryColour(vehicle, was.customPrimary[1], was.customPrimary[2], was.customPrimary[3])
    else
        ClearVehicleCustomPrimaryColour(vehicle)
    end

    if was.customSecondary then
        SetVehicleCustomSecondaryColour(vehicle, was.customSecondary[1], was.customSecondary[2], was.customSecondary[3])
    else
        ClearVehicleCustomSecondaryColour(vehicle)
    end

    SetVehicleColours(vehicle, was.primary, was.secondary)
    SetVehicleExtraColours(vehicle, was.pearl, was.wheelColour)
    SetVehicleLivery(vehicle, was.livery)
    SetVehicleNumberPlateTextIndex(vehicle, was.plate)
    SetVehicleWindowTint(vehicle, was.tint)

    if was.xenon then SetVehicleXenonLightsColour(vehicle, was.xenon) end

    for index, on in pairs(was.neon or {}) do
        SetVehicleNeonLightEnabled(vehicle, index, on)
    end

    if was.neonColour then
        SetVehicleNeonLightsColour(vehicle, was.neonColour[1], was.neonColour[2], was.neonColour[3])
    end

    if was.smoke then
        SetVehicleTyreSmokeColor(vehicle, was.smoke[1], was.smoke[2], was.smoke[3])
    end

    for id, on in pairs(was.extras or {}) do
        SetVehicleExtra(vehicle, id, on and 0 or 1)
    end

    if was.chameleon then SetVehicleModColor_1(vehicle, was.chameleon, 0, 0) end

    Stance.Restore(vehicle, was.stance)
end

local function remember(vehicle)
    if snapshot and snapshot.entity == vehicle then return end

    -- A different car. Put the last one back before letting go of it.
    if snapshot then Preview.Restore() end

    snapshot = { entity = vehicle, was = read(vehicle) }
end

function Preview.Snapshot(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    remember(vehicle)
end

-- Puts the recorded vehicle back, whatever the tablet is pointed at now.
function Preview.Restore()
    local held = snapshot
    snapshot = nil

    if not held then return end
    if not held.entity or not DoesEntityExist(held.entity) then return end

    restore(held.entity, held.was)
end

-- The same, but the record is KEPT. A customer building up a list of parts
-- takes one back off it, and everything else has to go on again from a clean
-- car — which needs the record to still be there afterwards.
function Preview.Revert()
    if not snapshot then return end
    if not snapshot.entity or not DoesEntityExist(snapshot.entity) then return end

    restore(snapshot.entity, snapshot.was)
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

    -- Around the car from its nose. (-sin, cos) is a rotation; (sin, -cos) —
    -- what this used to be — is a reflection, so the angle it produced moved
    -- with the car's world heading and the same view framed a different part
    -- of the car depending on which way it was parked. Same bug the live
    -- window had; fixing one without the other leaves the two disagreeing.
    local rad = math.rad(GetEntityHeading(vehicle) + angle.yaw)

    -- tan, not sin: the height that makes a camera look DOWN at angle p from
    -- horizontal distance d is d * tan(p). sin quietly under-raises it, and the
    -- steeper the view the further off it gets.
    local lift = angle.dist * math.tan(math.rad(math.min(70.0, -angle.pitch)))

    SetCamCoord(camera,
        coords.x + (-math.sin(rad) * angle.dist),
        coords.y + (math.cos(rad) * angle.dist),
        coords.z + lift + 0.55)

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

-- The live window already shows the car from a camera of its own. A second one
-- swinging round on every click would fight it.
local function framing(vehicle, category)
    if Showcase.active then return end

    -- The preview camera exists to show somebody the part they are looking at
    -- in the panel. Fitting a part off a work order goes through the same
    -- code with the panel shut, and swinging a camera onto the car then —
    -- with no UI on screen to explain it — is just the view being taken away.
    if not XSM.open then return end

    startCam(vehicle, category)
end

-- Applies a change for looking at only. Nothing is paid for and nothing is
-- saved until the panel says apply.
function Preview.Show(data)
    local vehicle = XSM.vehicle
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    if not control(vehicle) then return false end

    remember(vehicle)
    SetVehicleModKit(vehicle, 0)

    local slot = tonumber(data.slot)
    local index = tonumber(data.index)

    if data.slotId == 'wheels' then
        SetVehicleWheelType(vehicle, tonumber(data.wheelType) or snapshot.was.wheelType)
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
    framing(vehicle, data.category)

    return true
end

function Preview.Respray(data)
    local vehicle = XSM.vehicle
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    if not control(vehicle) then return false end

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
    elseif data.part == 'pearl' or data.part == 'wheel' then
        -- Pearl and wheel colour are the extra pair rather than the main one,
        -- and they read from the same palette: a pearl is one of these
        -- colours laid over whatever the body is.
        local pearl, wheelColour = GetVehicleExtraColours(vehicle)

        if data.part == 'pearl' then
            SetVehicleExtraColours(vehicle, tonumber(data.index) or pearl, wheelColour)
        else
            SetVehicleExtraColours(vehicle, pearl, tonumber(data.index) or wheelColour)
        end
    elseif data.part == 'secondary' then
        ClearVehicleCustomSecondaryColour(vehicle)
        SetVehicleColours(vehicle, primary, tonumber(data.index) or secondary)
    else
        ClearVehicleCustomPrimaryColour(vehicle)
        SetVehicleColours(vehicle, tonumber(data.index) or primary, secondary)
    end

    XSM.preview = { category = 'respray', slotId = 'respray', label = 'Respray', price = data.price }
    framing(vehicle, 'respray')

    return true
end

function Preview.Extra(id, on)
    local vehicle = XSM.vehicle
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    if not control(vehicle) then return false end

    remember(vehicle)
    SetVehicleExtra(vehicle, tonumber(id) or 0, on and 0 or 1)

    return true
end

-- Puts the vehicle back the way it was found. `full` also drops the camera,
-- which is what closing the panel wants.
function XSM.StopPreview(full)
    Preview.Restore()
    XSM.preview = nil

    if full then Preview.StopCam() end
end

-- One part of the list is paid for and fitted. What is on the car now becomes
-- the new "as it arrived", so the rest of the list can still be taken back off
-- without taking the fitted one with it.
function Preview.Accept()
    if not snapshot then return end

    local entity = snapshot.entity

    if not entity or not DoesEntityExist(entity) then
        snapshot = nil
        return
    end

    snapshot = { entity = entity, was = read(entity) }
end

-- Called once the server has taken the money: what is on the car right now
-- becomes the truth, so there is nothing to put back.
function Preview.Commit()
    snapshot = nil
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

-- Last resort. A resource restart mid-preview must not leave somebody with a
-- respray they never paid for.
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Preview.Restore()
end)
