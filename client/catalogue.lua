Catalogue = {}

--[[ Everything in the tuning panel is read off the vehicle in front of you.

     A resource cannot open vehicles.meta or carcols.meta at runtime, but the
     game has already parsed both and will answer questions about them. Asking
     the model what it carries is what makes an addon car with its own bodykit
     list its own bodykit, under the names its .gxt2 gives them, without anyone
     writing a config entry for it. A slot the model has nothing in returns a
     count of zero and never reaches the panel. ]]

local function labelFor(vehicle, slot, index, fallback)
    local label = GetModTextLabel(vehicle, slot, index)
    if not label then return fallback end

    local text = GetLabelText(label)
    if not text or text == '' or text == 'NULL' then return fallback end

    return text
end

local function modelName(vehicle)
    local display = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local text = display and GetLabelText(display)
    if text and text ~= '' and text ~= 'NULL' then return text end
    return display or 'Vehicle'
end

local function stockLabel(entry)
    if entry.levels then return 'Stock' end
    if entry.category == 'wheels' then return 'Stock Wheels' end
    return 'Stock ' .. entry.label
end

-- One mod slot, as the model actually defines it.
local function readSlot(vehicle, entry, spawnCode)
    if Mods.SlotBlocked(entry.slot, spawnCode) then return nil end

    local count = GetNumVehicleMods(vehicle, entry.slot)
    if count <= 0 then return nil end

    local current = GetVehicleMod(vehicle, entry.slot)
    local options = { { index = -1, label = stockLabel(entry) } }

    for index = 0, count - 1 do
        options[#options + 1] = {
            index = index,
            -- A performance slot has no name of its own in the game files, so
            -- it is numbered. Everything else gets whatever the model calls it.
            label = entry.levels
                and ('Level %d'):format(index + 1)
                or labelFor(vehicle, entry.slot, index, ('%s %d'):format(entry.label, index + 1)),
        }
    end

    return {
        id = entry.id,
        slot = entry.slot,
        label = entry.label,
        category = entry.category,
        current = current,
        options = options,
    }
end

local function readWheels(vehicle, spawnCode)
    if Mods.SlotBlocked(23, spawnCode) then return nil end

    local original = GetVehicleWheelType(vehicle)
    local currentMod = GetVehicleMod(vehicle, 23)
    local custom = GetVehicleModVariation(vehicle, 23)
    local types = {}

    -- Switching wheel type rewrites the available list, so each one is asked in
    -- turn and the vehicle is put back exactly as it was found.
    for _, kind in ipairs(Mods.WheelTypes) do
        SetVehicleWheelType(vehicle, kind.id)

        local count = GetNumVehicleMods(vehicle, 23)
        if count > 0 then
            local options = {}

            for index = 0, count - 1 do
                options[#options + 1] = {
                    index = index,
                    label = labelFor(vehicle, 23, index, ('%s %d'):format(kind.label, index + 1)),
                }
            end

            types[#types + 1] = { type = kind.id, label = kind.label, options = options }
        end
    end

    SetVehicleWheelType(vehicle, original)
    SetVehicleMod(vehicle, 23, currentMod, custom)

    if #types == 0 then return nil end

    return {
        id = 'wheels',
        label = 'Wheels',
        category = 'wheels',
        currentType = original,
        current = currentMod,
        customTyres = custom,
        types = types,
    }
end

local function readExtras(vehicle)
    local extras = {}

    for id = 0, 20 do
        if DoesExtraExist(vehicle, id) then
            extras[#extras + 1] = { id = id, on = IsVehicleExtraTurnedOn(vehicle, id) == 1 }
        end
    end

    if #extras == 0 then return nil end
    return extras
end

local function readLiveries(vehicle)
    -- A model uses one of two systems and never both. The mod-slot kind is read
    -- by readSlot already, so only the older livery API is handled here.
    local count = GetVehicleLiveryCount(vehicle)
    if count <= 0 then return nil end

    local options = {}
    for index = 0, count - 1 do
        options[#options + 1] = { index = index, label = ('Livery %d'):format(index + 1) }
    end

    return {
        id = 'livery',
        label = 'Livery',
        category = 'livery',
        legacy = true,
        current = GetVehicleLivery(vehicle),
        options = options,
    }
end

local function readPlates(vehicle)
    local count = GetNumberOfVehicleNumberPlates(vehicle)
    if count <= 0 then return nil end

    local labels = {
        [0] = 'Blue on White 1', [1] = 'Yellow on Black', [2] = 'Yellow on Blue',
        [3] = 'Blue on White 2', [4] = 'Blue on White 3', [5] = 'North Yankton',
    }

    local options = {}
    for index = 0, count - 1 do
        options[#options + 1] = { index = index, label = labels[index] or ('Plate %d'):format(index + 1) }
    end

    return {
        id = 'plate',
        label = 'Plate',
        category = 'plate',
        current = GetVehicleNumberPlateTextIndex(vehicle),
        options = options,
    }
end

local function readNeon(vehicle)
    local r, g, b = GetVehicleNeonLightsColour(vehicle)
    local sides = {}

    for _, side in ipairs(Mods.NeonSides) do
        sides[#sides + 1] = { id = side.id, label = side.label, on = IsVehicleNeonLightEnabled(vehicle, side.id) }
    end

    return { sides = sides, colour = { r = r, g = g, b = b } }
end

local function readPaint(vehicle)
    local primary, secondary = GetVehicleColours(vehicle)
    local pearl, wheelColour = GetVehicleExtraColours(vehicle)
    local pr, pg, pb = GetVehicleCustomPrimaryColour(vehicle)
    local sr, sg, sb = GetVehicleCustomSecondaryColour(vehicle)

    return {
        primary = primary,
        secondary = secondary,
        pearlescent = pearl,
        wheelColour = wheelColour,
        customPrimary = IsVehiclePrimaryColourCustom(vehicle) and { r = pr, g = pg, b = pb } or nil,
        customSecondary = IsVehicleSecondaryColourCustom(vehicle) and { r = sr, g = sg, b = sb } or nil,
        dashboard = GetVehicleDashboardColour(vehicle),
        interior = GetVehicleInteriorColour(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        chameleon = Catalogue.SupportsChameleon() and GetVehicleModColour_1(vehicle) or nil,
    }
end

-- Chameleon paints arrived with the Drug Wars update. Asking for them on an
-- older build returns nothing useful, so the whole group is hidden instead.
function Catalogue.SupportsChameleon()
    return GetGameBuildNumber and GetGameBuildNumber() >= 2802
end

function Catalogue.Build(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end

    SetVehicleModKit(vehicle, 0)

    local spawnCode = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) or '')
    local slots = {}

    for _, entry in ipairs(Mods.Slots) do
        -- Wheels are asked for separately because the answer depends on which
        -- wheel type is fitted at the time.
        if entry.slot ~= 23 and entry.slot ~= 24 then
            local read = readSlot(vehicle, entry, spawnCode)
            if read then slots[#slots + 1] = read end
        end
    end

    local class = GetVehicleClass(vehicle)

    return {
        model = spawnCode,
        name = modelName(vehicle),
        class = class,
        plate = Util.Trim(GetVehicleNumberPlateText(vehicle) or ''),
        isBike = class == 8,
        electric = Catalogue.IsElectric(vehicle),
        slots = slots,
        wheels = readWheels(vehicle, spawnCode),
        liveries = readLiveries(vehicle),
        plates = readPlates(vehicle),
        extras = readExtras(vehicle),
        neon = readNeon(vehicle),
        paint = readPaint(vehicle),
        tints = Mods.WindowTints,
        xenonColours = Mods.XenonColours,
        supportsChameleon = Catalogue.SupportsChameleon(),
        health = {
            engine = math.floor(GetVehicleEngineHealth(vehicle)),
            body = math.floor(GetVehicleBodyHealth(vehicle)),
            petrolTank = math.floor(GetVehiclePetrolTankHealth(vehicle)),
            dirt = math.floor(GetVehicleDirtLevel(vehicle) * 100) / 100,
        },
    }
end

-- Electric vehicles cannot take an engine swap or most servicing parts, so the
-- panel needs to know before it offers them.
function Catalogue.IsElectric(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end

    local model = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) or '')

    for _, name in ipairs(Config.Tuning.electricModels or {}) do
        if string.lower(name) == model then return true end
    end

    -- No native answers this directly. An empty petrol tank in the handling
    -- data is the tell across the stock list. Note the handling natives take
    -- the ENTITY, not the model — passing a model name returns nothing useful
    -- and every vehicle reads as electric.
    local tank = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fPetrolTankVolume')
    return type(tank) == 'number' and tank <= 0.0
end
