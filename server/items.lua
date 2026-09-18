--[[ The server half of the item exports.

     ox_inventory calls `client.export` on the client, and client/items.lua is
     what answers that. These exist so the answer does not depend on which side
     a third-party inventory decided to look — an inventory that resolves the
     export server side finds one here, and it ends in the same client
     function.

     Each one is handed the inventory it came from, so the event reaches the
     player who used the item and nobody else.

     Written out in full rather than through a helper so the export names stay
     greppable; tools/check-items.mjs reads them. ]]

local function target(inventory)
    if type(inventory) == 'table' then return inventory.id end
    return tonumber(inventory)
end

if Config.Tablet.item ~= '' then
    exports('openTablet', function(_, _, inventory)
        local src = target(inventory)
        if not src then return end

        TriggerClientEvent('XS-Mechanic:client:openTablet', src)
    end)
end

for item, kit in pairs(Config.Repair.kits) do
    if kit then
        exports(('use_%s'):format(item), function(_, _, inventory)
            local src = target(inventory)
            if not src then return end

            TriggerClientEvent('XS-Mechanic:client:useKit', src, item)
        end)
    end
end

for _, item in ipairs(Parts.Installable()) do
    exports(('fit_%s'):format(item), function(_, _, inventory)
        local src = target(inventory)
        if not src then return end

        TriggerClientEvent('XS-Mechanic:client:useItem', src, item)
    end)
end

if Config.Nitrous.enabled and Config.Nitrous.item ~= '' then
    exports('use_nitrous', function(_, _, inventory)
        local src = target(inventory)
        if not src then return end

        TriggerClientEvent('XS-Mechanic:client:useNitrous', src)
    end)
end

if Config.Lighting.enabled and Config.Lighting.item ~= '' then
    exports('use_lighting_remote', function(_, _, inventory)
        local src = target(inventory)
        if not src then return end

        TriggerClientEvent('XS-Mechanic:client:useLighting', src)
    end)
end
