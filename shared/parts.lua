Parts = {}

--[[ What a piece of work uses up, and what the bench can make.

     The tables themselves live in config.lua so a server owner can point them
     at the item names they already use. This file is only the lookups, shared
     so the panel and the server agree on what is short. ]]

function Parts.ItemFor(category)
    local item = Config.Stock.categoryItems[category or '']
    if not item or item == '' then return nil end
    return item
end

function Parts.RecipeFor(item)
    for _, recipe in ipairs(Config.Crafting.recipes) do
        if recipe.item == item then return recipe end
    end

    return nil
end

function Parts.RecipeForCategory(category)
    for _, recipe in ipairs(Config.Crafting.recipes) do
        if recipe.category == category then return recipe end
    end

    return nil
end

-- The recipe's needs are written against the raw materials, not against item
-- names, so a server that calls scrap something else changes one line.
function Parts.Materials(recipe)
    local out = {}

    for key, amount in pairs(recipe and recipe.needs or {}) do
        local material = Config.Crafting.materials[key]

        if material then
            out[#out + 1] = {
                key = key,
                item = material.item,
                label = material.label,
                need = amount,
            }
        end
    end

    table.sort(out, function(a, b) return a.key < b.key end)

    return out
end

function Parts.Label(item)
    local recipe = Parts.RecipeFor(item)
    if recipe then return recipe.label end

    return item
end
