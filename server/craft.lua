Craft = {}

--[[ The bench.

     Raw material comes out of the mechanic's own pockets and the finished part
     goes onto the shop's shelf, so crafting is how a shop restocks itself
     rather than a second way to print items.

     Everything is checked again here. The panel's counts are what the mechanic
     had a moment ago, not what the server is going to act on. ]]

local function recipeFor(item)
    return Parts.RecipeFor(tostring(item or ''))
end

-- What the mechanic is holding of each material, against what a recipe wants.
function Craft.Sheet(src, shop)
    local out = {}

    local held = {}

    for _, material in pairs(Config.Crafting.materials) do
        if held[material.item] == nil then
            held[material.item] = Inventory.Count(src, material.item)
        end
    end

    for _, recipe in ipairs(Config.Crafting.recipes) do
        local needs = {}
        local canMake = true

        for _, material in ipairs(Parts.Materials(recipe)) do
            local have = held[material.item] or 0

            needs[#needs + 1] = {
                key = material.key,
                item = material.item,
                label = material.label,
                need = material.need,
                have = have,
            }

            if have < material.need then canMake = false end
        end

        out[#out + 1] = {
            item = recipe.item,
            label = recipe.label,
            category = recipe.category,
            needs = needs,
            canMake = canMake,
            onShelf = Stock.Count(shop, recipe.item, src),
        }
    end

    return out
end

function Craft.Make(src, shop, item, amount)
    if not Config.Crafting.enabled then
        return { ok = false, error = 'Nothing is made here.' }
    end

    local recipe = recipeFor(item)
    if not recipe then return { ok = false, error = 'The bench does not make that.' } end

    amount = math.floor(tonumber(amount) or 1)
    if amount < 1 or amount > 10 then
        return { ok = false, error = 'One to ten at a time.' }
    end

    local materials = Parts.Materials(recipe)

    for _, material in ipairs(materials) do
        if Inventory.Count(src, material.item) < material.need * amount then
            return { ok = false, error = ('Not enough %s.'):format(string.lower(material.label)) }
        end
    end

    -- Taken one at a time so a failure halfway through can be handed back
    -- rather than leaving the mechanic short.
    local taken = {}

    for _, material in ipairs(materials) do
        if Inventory.Remove(src, material.item, material.need * amount) then
            taken[#taken + 1] = { item = material.item, count = material.need * amount }
        else
            for _, back in ipairs(taken) do
                Inventory.Add(src, back.item, back.count)
            end

            return { ok = false, error = ('Could not take the %s.'):format(string.lower(material.label)) }
        end
    end

    if not Stock.Put(shop, recipe.item, amount, src) then
        for _, back in ipairs(taken) do
            Inventory.Add(src, back.item, back.count)
        end

        return { ok = false, error = 'Nowhere to put it. Clear some room.' }
    end

    Discord.Send('tuning', 'Parts made',
        ('**%s** made %dx %s at %s'):format(Framework.GetName(src), amount, recipe.label, shop.name),
        Discord.Colour.info)

    local shelf = Stock.StashOf(shop)

    return {
        ok = true,
        message = shelf
            and ('Made %dx %s. On the shelf.'):format(amount, recipe.label)
            or ('Made %dx %s.'):format(amount, recipe.label),
    }
end
