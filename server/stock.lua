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

--[[ A shop with a storage point used to read only the shelf, so a part in the
     mechanic's own pockets was invisible and could not be fitted. Both are
     counted now, and Config.Stock.useFrom decides which of them count. ]]
local function sources(shop)
    local from = Config.Stock and Config.Stock.useFrom or {}
    local useShelf = from.shelf ~= false
    local usePockets = from.pockets ~= false

    local stash = useShelf and Stock.StashOf(shop) or nil

    -- With no storage point there is no shelf to read, so pockets are the
    -- stock whatever the config says — otherwise a one-room shop can fit
    -- nothing at all.
    if not stash then usePockets = true end

    return stash, usePockets
end

function Stock.Count(shop, item, src)
    if not item or item == '' then return 0 end

    local stash, usePockets = sources(shop)

    local total = 0
    if stash then total = total + Inventory.StashCount(stash, item) end
    if usePockets and src then total = total + Inventory.Count(src, item) end

    return total
end

--[[ Spend the shelf first, then the mechanic's own pockets for whatever is
     left. A part someone brought with them is the last resort rather than the
     first, so a shop does not quietly eat a mechanic's stock while its own
     shelf is full.

     If the pockets half fails, whatever came off the shelf goes back: a half
     taken payment leaves the shop short and fits nothing. ]]
function Stock.Take(shop, item, amount, src)
    if not item or item == '' then return true end

    amount = math.max(1, math.floor(tonumber(amount) or 1))

    local stash, usePockets = sources(shop)
    local left = amount

    local fromShelf = 0
    if stash then
        fromShelf = math.min(left, Inventory.StashCount(stash, item))

        if fromShelf > 0 then
            if not Inventory.StashRemove(stash, item, fromShelf) then return false end
            left = left - fromShelf
        end
    end

    if left <= 0 then return true end

    if usePockets and src and Inventory.Remove(src, item, left) then return true end

    if fromShelf > 0 then Inventory.StashAdd(stash, item, fromShelf) end

    return false
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

