Inventory = { name = nil }

local function detect()
    local forced = Config.Bridges.inventory
    if forced ~= 'auto' then return forced ~= 'none' and forced or nil end

    for _, name in ipairs({ 'ox_inventory', 'qs-inventory', 'ps-inventory', 'codem-inventory', 'core_inventory', 'qb-inventory' }) do
        if GetResourceState(name) == 'started' then return name end
    end

    return nil
end

Inventory.name = detect()

if IsDuplicityVersion() then
    function Inventory.Count(src, item)
        if not item or item == '' then return 0 end

        if Inventory.name == 'ox_inventory' then
            return exports.ox_inventory:GetItemCount(src, item) or 0
        end

        if Inventory.name == 'qs-inventory' then
            return exports['qs-inventory']:GetItemTotalAmount(src, item) or 0
        end

        if Inventory.name == 'core_inventory' then
            local found = exports.core_inventory:getItemCount(src, item)
            return tonumber(found) or 0
        end

        local player = Framework.GetPlayer(src)
        if not player then return 0 end

        local found = player.Functions.GetItemByName(item)
        return found and found.amount or 0
    end

    function Inventory.Has(src, item, amount)
        return Inventory.Count(src, item) >= (amount or 1)
    end

    function Inventory.Add(src, item, amount, meta)
        amount = amount or 1

        if Inventory.name == 'ox_inventory' then
            return exports.ox_inventory:AddItem(src, item, amount, meta) and true or false
        end

        if Inventory.name == 'qs-inventory' then
            return exports['qs-inventory']:AddItem(src, item, amount, nil, meta) and true or false
        end

        local player = Framework.GetPlayer(src)
        if not player then return false end

        return player.Functions.AddItem(item, amount, nil, meta) and true or false
    end

    function Inventory.Remove(src, item, amount)
        amount = amount or 1

        if not Inventory.Has(src, item, amount) then return false end

        if Inventory.name == 'ox_inventory' then
            return exports.ox_inventory:RemoveItem(src, item, amount) and true or false
        end

        if Inventory.name == 'qs-inventory' then
            return exports['qs-inventory']:RemoveItem(src, item, amount) and true or false
        end

        local player = Framework.GetPlayer(src)
        if not player then return false end

        return player.Functions.RemoveItem(item, amount) and true or false
    end

    -- ox_inventory will not open a stash it was never told about, and says
    -- nothing at all when asked to. Registering on every use is cheap and
    -- covers a restart having forgotten it.
    function Inventory.RegisterStash(id, label, slots, weight)
        if Inventory.name ~= 'ox_inventory' then return end
        local size = Config.Stock and Config.Stock.storage or {}
        pcall(function()
            exports.ox_inventory:RegisterStash(id, label, slots or size.slots or 500, weight or size.weight or 4000000)
        end)
    end

    --[[ Reading and writing a stash without anybody opening it.

         Only ox_inventory answers this. The others keep stash contents in
         shapes that differ per fork, and guessing wrong would silently eat
         somebody's parts, so the caller is told no and falls back to the
         mechanic's own pockets instead. ]]
    function Inventory.StashReady()
        return Inventory.name == 'ox_inventory'
    end

    function Inventory.StashCount(id, item)
        if not Inventory.StashReady() or not item or item == '' then return 0 end

        Inventory.RegisterStash(id, 'Shop storage')

        local count = 0

        pcall(function()
            count = exports.ox_inventory:GetItem(id, item, nil, true) or 0
        end)

        return tonumber(count) or 0
    end

    function Inventory.StashAdd(id, item, amount)
        if not Inventory.StashReady() then return false end

        Inventory.RegisterStash(id, 'Shop storage')

        local ok, added = pcall(function()
            return exports.ox_inventory:AddItem(id, item, amount or 1)
        end)

        return ok and added and true or false
    end

    function Inventory.StashRemove(id, item, amount)
        if not Inventory.StashReady() then return false end

        amount = amount or 1
        if Inventory.StashCount(id, item) < amount then return false end

        local ok, removed = pcall(function()
            return exports.ox_inventory:RemoveItem(id, item, amount)
        end)

        return ok and removed and true or false
    end
else
    function Inventory.OpenStash(id, label, slots, weight)
        if Inventory.name == 'ox_inventory' then
            -- A stash id goes as a plain string. The { id = ... } form is for
            -- drops and containers, and passing it here silently opens nothing.
            exports.ox_inventory:openInventory('stash', id)
            return
        end

        if Inventory.name == 'qs-inventory' then
            exports['qs-inventory']:RegisterStash(id, slots or 50, weight or 100000)
            return
        end

        if Inventory.name == 'ps-inventory' then
            TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, { maxweight = weight or 100000, slots = slots or 50 })
            TriggerEvent('inventory:client:SetCurrentStash', id)
            return
        end

        TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, { maxweight = weight or 100000, slots = slots or 50 })
        TriggerEvent('inventory:client:SetCurrentStash', id)
    end
end
