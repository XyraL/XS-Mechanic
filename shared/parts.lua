Parts = {}

--[[ What a piece of work uses up, and what the bench can make.

     The tables themselves live in config.lua so a server owner can point them
     at the item names they already use. This file is only the lookups, shared
     so the panel and the server agree on what is short. ]]

-- A slot with a part of its own wins over its category's: an engine upgrade
-- and a brake upgrade are both "performance", and a shop stocks them apart.
function Parts.ItemFor(category, slotId)
    local slot = slotId and Config.Stock.slotItems[slotId]
    if slot and slot ~= '' then return slot end

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

--[[ Every item that fits something to a car.

     One list, because the exports, both item files, the useable-item loop and
     the checker all have to agree on it — and because a server owner who
     renames a part in config expects it to carry on working without editing
     five other places. ]]
function Parts.Installable()
    local seen, out = {}, {}

    local function add(item)
        if not item or item == '' or seen[item] then return end

        seen[item] = true
        out[#out + 1] = item
    end

    for _, item in pairs(Config.Stock.categoryItems) do add(item) end
    for _, item in pairs(Config.Stock.slotItems) do add(item) end

    for _, options in pairs(Tuning.Options) do
        for _, option in ipairs(options) do add(option.item) end
    end

    table.sort(out)

    return out
end
