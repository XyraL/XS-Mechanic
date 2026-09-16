Pricing = {}

local valueCache = {}

-- The framework's shared vehicle list first, then a per-class default, then the
-- flat fallback. Addon vehicles are usually missing from the shared list, which
-- is the whole reason classDefaults exists.
function Pricing.VehicleValue(model, class)
    model = string.lower(model or '')

    if valueCache[model] then return valueCache[model] end

    local price = Framework.VehiclePrice(model)

    if not price or price <= 0 then
        price = Config.Pricing.classDefaults[class] or Config.Pricing.fallback
    end

    valueCache[model] = price
    return price
end

--[[ A shop's override for one category.

     It is a table — price, percent, enabled — and a plain number is accepted
     as well because that is what an earlier version of the price editor wrote
     into the shop's saved data. Those rows are in people's databases; reading
     them as a table is `attempt to index a number value` on the next tablet
     that opens, and every shop that has ever had a price changed is broken
     until it is read back the way it was written. ]]
local function categoryConfig(shop, category)
    local override = shop and shop.pricing and shop.pricing[category]
    local base = Config.Pricing.categories[category]

    if not base then return nil end

    if type(override) == 'number' then
        override = { price = override }
    elseif type(override) ~= 'table' then
        override = nil
    end

    return {
        price = override and override.price or base.price,
        percent = override and override.percent or base.percent,
        enabled = not override or override.enabled ~= false,
    }
end

-- level is the mod index; 0 or nil means there is no ladder to climb.
function Pricing.For(shop, category, model, class, level)
    local entry = categoryConfig(shop, category)
    if not entry or not entry.enabled then return nil end

    local mode = Config.Pricing.mode
    local total = 0

    if mode == 'percent' or mode == 'both' then
        total = Pricing.VehicleValue(model, class) * (entry.percent or 0)
    end

    if mode == 'fixed' or mode == 'both' then
        total = total + (entry.price or 0)
    end

    local step = tonumber(level) or 0
    if step > 0 then
        total = total + (total * (Config.Pricing.levelMultiplier or 0) * step)
    end

    return math.floor(total + 0.5)
end

function Pricing.CategoryEnabled(shop, category)
    if shop and shop.categories and shop.categories[category] == false then return false end

    local entry = categoryConfig(shop, category)
    return entry ~= nil and entry.enabled
end

-- The whole price list for one vehicle at one shop, so the panel can show every
-- number without a round trip per button.
function Pricing.Sheet(shop, model, class)
    local out = {}

    for _, category in ipairs(Mods.Categories) do
        if Pricing.CategoryEnabled(shop, category.id) then
            out[category.id] = Pricing.For(shop, category.id, model, class, 0)
        end
    end

    return out
end

function Pricing.ClearCache()
    valueCache = {}
end
