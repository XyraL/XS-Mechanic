Stock = {}

--[[ What a shop actually has on the shelf.

     The shelf is the shop's own storage point — the same stash employees open
     from the target — so stocking up is putting parts in it, and the tablet
     reads what is there rather than offering everything regardless.

     Two things make a shop fall back to the mechanic's own pockets: no storage
     point placed, or an inventory that cannot be read without somebody opening
     it. Either way the work still needs the part to exist somewhere, which is
     the point of the setting. ]]

function Stock.Enabled()
    return Config.Stock.require == true
end

function Stock.StashOf(shop)
    if not Inventory.StashReady() then return nil end

    for _, point in ipairs(shop and shop.points or {}) do
        if point.kind == 'storage' then
            return ('xsmech_%s_%s'):format(shop.id, point.id)
        end
    end

    return nil
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
    if not Stock.Enabled() then return nil end

    local categories = {}
    local items = {}
    local labels = {}

    for category, item in pairs(Config.Stock.categoryItems) do
        if item and item ~= '' then
            categories[category] = item

            if items[item] == nil then
                items[item] = Stock.Count(shop, item, src)
                labels[item] = Parts.Label(item)
            end
        end
    end

    return {
        categories = categories,
        items = items,
        labels = labels,
        shelf = Stock.StashOf(shop) ~= nil,
    }
end

function Stock.Missing(shop, category, src)
    if not Stock.Enabled() then return nil end

    local item = Parts.ItemFor(category)
    if not item then return nil end

    if Stock.Count(shop, item, src) > 0 then return nil end

    return item
end
