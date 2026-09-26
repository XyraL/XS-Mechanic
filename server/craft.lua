Craft = {}

--[[ The bench.

     Material comes off the shop's shelf and the finished part goes back onto
     it, so the bench is how a shop turns a pile of scrap into the parts it
     fits. A shop with nowhere to keep anything uses the mechanic's pockets for
     both ends, which is the rule the rest of stock follows.

     Everything is checked again here. The panel's counts are what the shelf
     held a moment ago, not what the server is going to act on. ]]

local function recipeFor(item)
    return Parts.RecipeFor(tostring(item or ''))
end

-- What the shop has of each material, against what a recipe wants.
function Craft.Sheet(src, shop)
    local out = {}
    local held = {}

    for _, material in pairs(Config.Crafting.materials) do
        if held[material.item] == nil then
            held[material.item] = Stock.Count(shop, material.item, src)
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
            group = recipe.group or 'Parts',
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
        if Stock.Count(shop, material.item, src) < material.need * amount then
            return { ok = false, error = ('Not enough %s.'):format(string.lower(material.label)) }
        end
    end

    -- Taken one material at a time so a failure halfway through can be handed
    -- back rather than leaving the shop short.
    local taken = {}

    local function handBack()
        for _, back in ipairs(taken) do
            Stock.Put(shop, back.item, back.count, src)
        end
    end

    for _, material in ipairs(materials) do
        local count = material.need * amount

        if Stock.Take(shop, material.item, count, src) then
            taken[#taken + 1] = { item = material.item, count = count }
        else
            handBack()
            return { ok = false, error = ('Could not take the %s.'):format(string.lower(material.label)) }
        end
    end

    local made, where = Stock.Put(shop, recipe.item, amount, src)

    if not made then
        handBack()
        return { ok = false, error = 'Nowhere to put it. Clear some room on the shelf.' }
    end

    Discord.Send('tuning', 'Parts made',
        ('**%s** made %dx %s at %s'):format(Framework.GetName(src), amount, recipe.label, shop.name),
        Discord.Colour.info)

    -- The panel reads its stock numbers once, when it opens. Without this the
    -- part is on the shelf and every screen still says the shop has none of it,
    -- so Fit stays greyed out on a part somebody just made.
    TriggerClientEvent('XS-Mechanic:client:refresh', -1)

    return {
        ok = true,
        message = where == 'shelf'
            and ('Made %dx %s. On the shelf.'):format(amount, recipe.label)
            or ('Made %dx %s. In your pockets.'):format(amount, recipe.label),
    }
end
