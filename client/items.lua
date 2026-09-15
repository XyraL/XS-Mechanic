--[[ ox_inventory's `client = { export = ... }` is called on the CLIENT.

     These were registered server side at first, which fails at load with
     "No such export" — ox validates the export exists while it is reading its
     item list, so the error arrives before anyone has used anything.

     qb-style inventories go the other way: the server registers a useable item
     and triggers a client event. That path lives in server/commands.lua, and
     both of them end up in the same function here. ]]

if Config.Tablet.item ~= '' then
    exports('openTablet', function()
        XSM.Open('tablet')
    end)
end

for item, kit in pairs(Config.Repair.kits) do
    if kit then
        exports(('use_%s'):format(item), function()
            Repair.UseKit(item)
        end)
    end
end

if Config.Nitrous.enabled and Config.Nitrous.item ~= '' then
    exports('use_nitrous', function()
        Nitrous.Toggle()
    end)
end

if Config.Lighting.enabled and Config.Lighting.item ~= '' then
    exports('use_lighting_remote', function()
        Lighting.Open()
    end)
end
