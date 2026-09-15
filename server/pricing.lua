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

local function categoryConfig(shop, category)
    local shopOverride = shop and shop.pricing and shop.pricing[category]
    local base = Config.Pricing.categories[category]

    if not base then return nil end

    return {
        price = shopOverride and shopOverride.price or base.price,
        percent = shopOverride and shopOverride.percent or base.percent,
        enabled = not shopOverride or shopOverride.enabled ~= false,
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
