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

-- A shop can rename a package and change what it costs. Anything it has not
-- touched falls through to the shipped name and price, so an untouched shop
-- behaves exactly as before.
function CustomTuning.Priced(shop, category, option)
    local override = shop and shop.tuningPrices and shop.tuningPrices[('%s:%s'):format(category, option.id)]

    if not override then return option.name, option.price, false end

    return override.label or option.name, override.price or option.price, true
end

--[[ Every package and what it costs, with no vehicle involved.

     CustomTuning.Sheet answers "what can go in THIS car", which is the wrong
     question at a desk — an electric motor is not offered against an empty
     profile and would be missing from the price list for good. ]]
function CustomTuning.PriceList(shop)
    if not Config.CustomTuning.enabled then return {} end

    local out = {}

    for _, category in ipairs(Tuning.Categories) do
        local options = {}

        for _, option in ipairs(Tuning.Options[category.id] or {}) do
            local name, price, custom = CustomTuning.Priced(shop, category.id, option)

            options[#options + 1] = {
                id = option.id,
                name = name,
                price = price,
                priced = custom,
                stock = option.name,
            }
        end

        out[#out + 1] = { id = category.id, label = category.label, options = options }
    end

    return out
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
                local name, price, custom = CustomTuning.Priced(shop, category.id, option)

                options[#options + 1] = {
                    id = option.id,
                    name = name,
                    info = option.info,
                    item = option.item,
                    price = price,
                    priced = custom,
                    stock = option.item,
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

--[[ Fitting a package off a work order.

     The same job as CustomTuning.Fit without the paying for it. On an order
     the part has already been made, already been taken off the shelf and is
     already in the mechanic's pockets, and Orders.Fit takes it from there —
     charging the shop again here would take a second one. ]]
function CustomTuning.FitOff(src, shop, order, line)
    if not Config.CustomTuning.enabled then
        return { ok = false, error = 'Custom tuning is off on this server.' }
    end

    local option = Tuning.Get(line.tuning.category, line.tuning.option)
    if not option then return { ok = false, error = 'Unknown option.' } end

    local profile = Vehicles.Profile(order.plate, order.model)
    if not profile then return { ok = false, error = 'No vehicle.' } end

    if not Tuning.Allowed(option, profile.model, electricOf(profile)) then
        return { ok = false, error = 'That does not go in this vehicle.' }
    end

    local fitted = profile.performance or {}

    if fitted[line.tuning.category] == option.id then
        return { ok = false, error = 'Already fitted.' }
    end

    fitted[line.tuning.category] = option.id
    profile.performance = fitted

    Vehicles.Save(profile)

    for _, entity in ipairs(GetAllVehicles and GetAllVehicles() or {}) do
        if Util.Trim(GetVehicleNumberPlateText(entity) or '') == order.plate then
            Vehicles.Push(entity, order.plate, profile.model)
            break
        end
    end

    return { ok = true }
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

    local touched = stance.height ~= 0

    for _, wheel in ipairs({ 'fl', 'fr', 'rl', 'rr' }) do
        local entry = data.stance[wheel] or {}

        stance[wheel] = {
            camber = math.max(-0.35, math.min(0.35, tonumber(entry.camber) or 0)),
            track = math.max(-0.25, math.min(0.25, tonumber(entry.track) or 0)),
        }

        if stance[wheel].camber ~= 0 or stance[wheel].track ~= 0 then touched = true end
    end

    -- All zeros means the car goes back on its factory suspension, so the
    -- profile is cleared rather than storing a stance of nothing — otherwise
    -- there is always something to re-apply and never a way back.
    profile.stance = touched and stance or nil

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
