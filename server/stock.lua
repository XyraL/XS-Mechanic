Stock = {}

--[[ What a shop actually has on the shelf.

     The shelf is the shop's own storage point — the same stash employees open
     from the target — so stocking up is putting parts in it, and the tablet
     reads what is there rather than offering everything regardless.

     No storage point, or an inventory whose stashes cannot be read without
     somebody opening one, means no shelf and therefore no stock rules. The
     bench still works either way; it just takes from and gives to whoever is
     stood at it. ]]

function Stock.StashOf(shop)
    if not Inventory.StashReady() then return nil end

    for _, point in ipairs(shop and shop.points or {}) do
        if point.kind == 'storage' then
            return ('xsmech_%s_%s'):format(shop.id, point.id)
        end
    end

    return nil
end

--[[ A shop only runs on stock if it has somewhere to keep it.

     Falling back to the mechanic's pockets looked like a sensible degradation
     and was the opposite: a shop with no storage point read every part as zero
     and could not fit anything at all, which is every shop on the day it is
     built. A shelf is what makes stock mean something, so no shelf means no
     stock rules — place a storage point and the shop starts keeping stock. ]]
function Stock.Enabled(shop)
    if Config.Stock.require ~= true then return false end

    return Stock.StashOf(shop) ~= nil
end

function Stock.Count(shop, item, src)
    if not item or item == '' then return 0 end

    local stash = Stock.StashOf(shop)
    if stash then return Inventory.StashCount(stash, item) end

    return Inventory.Count(src, item)
end

function Stock.Take(shop, item, amount, src)
    if not item or item == '' then return true end

    amount = amount or 1

    local stash = Stock.StashOf(shop)
    if stash then return Inventory.StashRemove(stash, item, amount) end

    return Inventory.Remove(src, item, amount)
end

--[[ A made part goes on the shelf. With nowhere to put it, the mechanic keeps
     hold of it, which is also where the shop then reads it from.

     The count is read back rather than trusting what the add returned. A stash
     that is full, or that the inventory decided not to write, reports success
     in some forks and then simply does not have the item — and the mechanic is
     left with the material gone and nothing to show for it. ]]
function Stock.Put(shop, item, amount, src)
    amount = amount or 1

    local stash = Stock.StashOf(shop)

    if stash then
        local before = Inventory.StashCount(stash, item)

        Inventory.StashAdd(stash, item, amount)

        if Inventory.StashCount(stash, item) >= before + amount then return true, 'shelf' end
    end

    if Inventory.Add(src, item, amount) then return true, 'pocket' end

    return false
end

-- What the item each category uses is called, and how many of it there are.
-- The panel greys out what is short rather than hiding it: a customer can still
-- ask for a part the shop has not got, and somebody goes and makes one.
function Stock.Sheet(shop, src)
    if not Stock.Enabled(shop) then return nil end

    local categories = {}
    local slots = {}
    local items = {}
    local labels = {}

    local function take(item)
        if items[item] ~= nil then return end

        items[item] = Stock.Count(shop, item, src)
        labels[item] = Parts.Label(item)
    end

    for category, item in pairs(Config.Stock.categoryItems) do
        if item and item ~= '' then
            categories[category] = item
            take(item)
        end
    end

    for slot, item in pairs(Config.Stock.slotItems) do
        if item and item ~= '' then
            slots[slot] = item
            take(item)
        end
    end

    -- Every custom tuning package supplies its own part — a V8 is not a
    -- "performance part". The panel greys out what the shop has run out of, so
    -- it needs the count of the thing actually taken off the shelf, not the
    -- count of the category's generic stand-in.
    for _, category in ipairs(Tuning.Categories) do
        for _, option in ipairs(Tuning.Options[category.id] or {}) do
            if option.item and option.item ~= '' then take(option.item) end
        end
    end

    return {
        categories = categories,
        slots = slots,
        items = items,
        labels = labels,
        shelf = Stock.StashOf(shop) ~= nil,
    }
end

