CustomTuning = {}

--[[ Fitting a package. The shop decides whether it costs an item or money, and
     either way the cost falls on the SHOP — the customer pays whatever the
     mechanic puts on the invoice, which is not the same number and is not
     worked out here. That split is deliberate: a shop that fits a £78,000
     engine and bills £20,000 for it has made a bad decision, not hit a bug. ]]

local function electricOf(profile)
    for _, name in ipairs(Config.Tuning.electricModels or {}) do
        if string.lower(name) == string.lower(profile.model or '') then return true end
    end
    return false
end

function CustomTuning.Sheet(profile, shop)
    if not Config.CustomTuning.enabled then return {} end

    local electric = electricOf(profile)
    local fitted = profile.performance or {}
    local out = {}

    for _, category in ipairs(Tuning.Categories) do
        local options = {}

        for _, option in ipairs(Tuning.Options[category.id] or {}) do
            if Tuning.Allowed(option, profile.model, electric) then
                options[#options + 1] = {
                    id = option.id,
                    name = option.name,
                    info = option.info,
                    item = option.item,
                    price = option.price,
                    fitted = fitted[category.id] == option.id,
                }
            end
        end

        if #options > 0 then
            out[#out + 1] = {
                id = category.id,
                label = category.label,
                requiresItem = shop and shop.tuningItems ~= false or Config.CustomTuning.requiresItem,
                current = fitted[category.id],
                options = options,
            }
        end
    end

    return out
end

function CustomTuning.Fit(src, data)
    if not Config.CustomTuning.enabled then
        return { ok = false, error = 'Custom tuning is off on this server.' }
    end

    local shop = Store.Get(data.shop)
    if not shop then return { ok = false, error = 'No shop.' } end

    local job = Framework.GetJob(src)
    if shop.kind == 'owned' and job ~= shop.job then
        return { ok = false, error = 'Not your shop.' }
    end

    local option = Tuning.Get(data.category, data.option)
    if not option then return { ok = false, error = 'Unknown option.' } end

    local plate = Util.Trim(data.plate or '')
    local profile = Vehicles.Profile(plate, data.model)
    if not profile then return { ok = false, error = 'No vehicle.' } end

    if not Tuning.Allowed(option, profile.model, electricOf(profile)) then
        return { ok = false, error = 'That does not go in this vehicle.' }
    end

    local fitted = profile.performance or {}

    if fitted[data.category] == option.id then
        return { ok = false, error = 'Already fitted.' }
    end

    local usesItem = shop.tuningItems ~= false and Config.CustomTuning.requiresItem

    if usesItem then
        if not Inventory.Has(src, option.item, 1) then
            return { ok = false, error = ('The shop needs a %s.'):format(option.name) }
        end

        if not Inventory.Remove(src, option.item, 1) then
            return { ok = false, error = 'Could not take the part.' }
        end
    else
        if not Banking.Remove(shop, option.price, ('Tuning — %s'):format(option.name), Framework.GetName(src), 'tuning') then
            return { ok = false, error = 'The shop cannot cover that.' }
        end
    end

    fitted[data.category] = option.id
    profile.performance = fitted

    Vehicles.Save(profile)

    for _, entity in ipairs(GetAllVehicles and GetAllVehicles() or {}) do
        if Util.Trim(GetVehicleNumberPlateText(entity) or '') == plate then
            Vehicles.Push(entity, plate, profile.model)
            break
        end
    end

    Discord.Send('tuning', 'Custom tuning fitted',
        ('**%s** fitted %s to `%s` at %s'):format(Framework.GetName(src), option.name, plate, shop.name),
        Discord.Colour.info)

    return { ok = true, message = ('%s fitted.'):format(option.name) }
end

function CustomTuning.Remove(src, data)
    local shop = Store.Get(data.shop)
    if not shop then return { ok = false, error = 'No shop.' } end

    local job = Framework.GetJob(src)
    if shop.kind == 'owned' and job ~= shop.job then
        return { ok = false, error = 'Not your shop.' }
    end

    local plate = Util.Trim(data.plate or '')
    local profile = Vehicles.Profile(plate)
    if not profile then return { ok = false, error = 'No vehicle.' } end

    local fitted = profile.performance or {}
    if not fitted[data.category] then return { ok = false, error = 'Nothing fitted.' } end

    fitted[data.category] = nil
    profile.performance = fitted

    Vehicles.Save(profile)

    for _, entity in ipairs(GetAllVehicles and GetAllVehicles() or {}) do
        if Util.Trim(GetVehicleNumberPlateText(entity) or '') == plate then
            Vehicles.Push(entity, plate, profile.model)
            break
        end
    end

    return { ok = true, message = 'Taken off.' }
end

function CustomTuning.SaveStance(src, data)
    local shop = Store.Get(data.shop)
    if not shop then return { ok = false, error = 'No shop.' } end

    if not Pricing.CategoryEnabled(shop, 'stance') then
        return { ok = false, error = 'This shop does not do stance.' }
    end

    local plate = Util.Trim(data.plate or '')
    local profile = Vehicles.Profile(plate, data.model)
    if not profile then return { ok = false, error = 'No vehicle.' } end

    if type(data.stance) ~= 'table' then return { ok = false, error = 'Nothing to save.' } end

    -- Clamped on the server too. The client clamps for feel; this is the one
    -- that stops a crafted payload putting the wheels in the next postcode.
    local stance = {
        height = math.max(-0.30, math.min(0.30, tonumber(data.stance.height) or 0)),
    }

    for _, wheel in ipairs({ 'fl', 'fr', 'rl', 'rr' }) do
        local entry = data.stance[wheel] or {}

        stance[wheel] = {
            camber = math.max(-0.35, math.min(0.35, tonumber(entry.camber) or 0)),
            track = math.max(-0.25, math.min(0.25, tonumber(entry.track) or 0)),
        }
    end

    profile.stance = stance
    Vehicles.Save(profile)

    for _, entity in ipairs(GetAllVehicles and GetAllVehicles() or {}) do
        if Util.Trim(GetVehicleNumberPlateText(entity) or '') == plate then
            Vehicles.Push(entity, plate, profile.model)
            break
        end
    end

    local price = Pricing.For(shop, 'stance', profile.model, data.class, 0) or 0
    Invoices.AddLine(src, 'Stance setup', price, 'Stance')

    return { ok = true, message = 'Stance saved.' }
end
