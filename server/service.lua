Servicing = {}

--[[ Wear is worked out here, from distance the client reported, and never
     taken from the client directly. A part is replaced by consuming its item
     and putting that part back to 100%.

     The odometer handler in server/vehicles.lua calls Advance for every
     kilometre banked, so wear and mileage cannot drift apart. ]]

local function electricOf(profile)
    for _, name in ipairs(Config.Tuning.electricModels or {}) do
        if string.lower(name) == string.lower(profile.model or '') then return true end
    end
    return false
end

function Servicing.Blocked(model)
    model = string.lower(model or '')

    for _, blocked in ipairs(Config.Service.blocked or {}) do
        if string.lower(blocked) == model then return true end
    end

    return false
end

function Servicing.Advance(profile, metres)
    if not Config.Service.enabled then return end
    if Servicing.Blocked(profile.model) then return end

    profile.service = Service.Advance(profile.service, electricOf(profile), metres / 1000)
end

function Servicing.Sheet(profile)
    local electric = electricOf(profile)
    local out = {}

    for _, part in ipairs(Service.For(electric)) do
        local wear = Service.Wear(profile.service, part)

        out[#out + 1] = {
            id = part.id,
            label = part.label,
            wear = math.floor(wear),
            due = wear <= Config.Service.threshold,
            item = part.item,
            quantity = part.quantity,
            lifespanKm = part.lifespanKm,
            affects = part.affects,
        }
    end

    return out
end

function Servicing.DueCount(profile)
    if not Config.Service.enabled then return 0 end
    return #Service.Due(profile.service, electricOf(profile), Config.Service.threshold)
end

function Servicing.Replace(src, plate, partId, shop)
    if not Config.Service.enabled then
        return { ok = false, error = 'Servicing is off on this server.' }
    end

    local part = Service.ById[partId]
    if not part then return { ok = false, error = 'Unknown part.' } end

    local profile = Vehicles.Profile(plate)
    if not profile then return { ok = false, error = 'No vehicle.' } end

    if Servicing.Blocked(profile.model) then
        return { ok = false, error = 'That vehicle is not serviced here.' }
    end

    local quantity = part.quantity or 1

    if not Inventory.Has(src, part.item, quantity) then
        return { ok = false, error = ('You need %dx %s.'):format(quantity, part.label) }
    end

    if not Inventory.Remove(src, part.item, quantity) then
        return { ok = false, error = 'Could not take the parts.' }
    end

    profile.service = profile.service or {}
    profile.service[partId] = 100

    Vehicles.Save(profile)

    -- Push the new wear out so the handling multiplier updates without waiting
    -- for the car to be respawned.
    for _, entity in ipairs(GetAllVehicles and GetAllVehicles() or {}) do
        if Util.Trim(GetVehicleNumberPlateText(entity) or '') == plate then
            Vehicles.Push(entity, plate, profile.model)
            break
        end
    end

    if shop then
        local price = (Config.Service.labour or 0)
        Invoices.AddLine(src, ('%s replaced'):format(part.label), price, 'Service')
    end

    Discord.Send('service', 'Part replaced',
        ('**%s** replaced %s on `%s`'):format(Framework.GetName(src), part.label, plate),
        Discord.Colour.good)

    return { ok = true }
end
