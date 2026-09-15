RegisterCommand(Config.Builder.command, function(source)
    if source == 0 then
        print('^1[XS-Mechanic]^0 That one is for players.')
        return
    end

    if not Framework.IsAdmin(source) then
        Framework.Notify(source, 'You are not allowed to do that.', 'error')
        return
    end

    TriggerClientEvent('XS-Mechanic:client:builder', source)
end, false)

if Config.Tablet.command ~= '' then
    RegisterCommand(Config.Tablet.command, function(source)
        if source == 0 then return end

        TriggerClientEvent('XS-Mechanic:client:openTablet', source)
    end, false)
end

-- Rows written back while a TINYINT(1) read bug was live genuinely become 0 in
-- the table, so fixing the read is not enough on its own.
RegisterCommand('mechanicshops', function(source, args)
    if source ~= 0 and not Framework.IsAdmin(source) then return end

    local function say(message)
        if source == 0 then print(message) else Framework.Notify(source, message, 'inform') end
    end

    if args[1] == 'on' then
        for _, shop in ipairs(Store.All()) do
            Store.SetEnabled(shop.id, true)
        end

        Store.Broadcast()
        say('Every shop switched on.')
        return
    end

    local all = Store.All()

    if #all == 0 then
        say('No shops. Run /' .. Config.Builder.command .. ' and build one.')
        return
    end

    for _, shop in ipairs(all) do
        say(('#%d %s — %s, job %s, %d points, %s'):format(
            shop.id, shop.name, shop.kind,
            shop.job ~= '' and shop.job or 'none',
            #(shop.points or {}),
            shop.enabled and 'on' or 'OFF'))
    end
end, false)

if Config.Tablet.item ~= '' then
    -- ox_inventory ignores CreateUseableItem entirely; it only calls an export
    -- named in its own data/items.lua. items/ox_inventory.lua is the paste-in
    -- block for that, and this export is what it points at.
    exports('openTablet', function(event, item, inventory)
        if event ~= 'usingItem' then return end
        TriggerClientEvent('XS-Mechanic:client:openTablet', inventory.id)
    end)

    if Inventory.name ~= 'ox_inventory' then
        CreateThread(function()
            Wait(2000)

            local core = Framework.core

            if Framework.name == 'qbox' then
                exports.qbx_core:CreateUseableItem(Config.Tablet.item, function(src)
                    TriggerClientEvent('XS-Mechanic:client:openTablet', src)
                end)
            elseif core then
                core.Functions.CreateUseableItem(Config.Tablet.item, function(src)
                    TriggerClientEvent('XS-Mechanic:client:openTablet', src)
                end)
            end
        end)
    end
end

for item, kit in pairs(Config.Repair.kits) do
    if kit then
        exports(('use_%s'):format(item), function(event, _, inventory)
            if event ~= 'usingItem' then return end
            TriggerClientEvent('XS-Mechanic:client:useKit', inventory.id, item)
        end)
    end
end

if Inventory.name ~= 'ox_inventory' then
    CreateThread(function()
        Wait(2000)

        for item, kit in pairs(Config.Repair.kits) do
            if kit then
                local handler = function(src)
                    TriggerClientEvent('XS-Mechanic:client:useKit', src, item)
                end

                if Framework.name == 'qbox' then
                    exports.qbx_core:CreateUseableItem(item, handler)
                elseif Framework.core then
                    Framework.core.Functions.CreateUseableItem(item, handler)
                end
            end
        end
    end)
end
