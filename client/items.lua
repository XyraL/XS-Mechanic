--[[ ox_inventory resolves `client = { export = ... }` on the CLIENT.

     From its modules/items/shared.lua: the client branch does
     `data.export = useExport(strsplit('.', clientData.export))`, and that
     closure calls `exports[resource][name]` when the item is used. So a
     missing export is not a startup error — it throws the first time somebody
     uses the item.

     Registered on both sides anyway. The server copy costs nothing, covers any
     inventory that asks the other way round, and means the answer never
     depends on which side a third-party resource decided to look. Both ends
     land in the same client function.

     qb-style inventories go through server CreateUseableItem instead; that
     path is in server/commands.lua.

     Every exports() call below is written out in full rather than wrapped in a
     helper, so the name stays greppable — tools/check-items.mjs reads these. ]]

local registered = {}

if Config.Tablet.item ~= '' then
    exports('openTablet', function()
        XSM.Open('tablet')
    end)

    registered[#registered + 1] = 'openTablet'
end

for item, kit in pairs(Config.Repair.kits) do
    if kit then
        exports(('use_%s'):format(item), function()
            Repair.UseKit(item)
        end)

        registered[#registered + 1] = ('use_%s'):format(item)
    end
end

if Config.Nitrous.enabled and Config.Nitrous.item ~= '' then
    exports('use_nitrous', function()
        Nitrous.Toggle()
    end)

    registered[#registered + 1] = 'use_nitrous'
end

if Config.Lighting.enabled and Config.Lighting.item ~= '' then
    exports('use_lighting_remote', function()
        Lighting.Open()
    end)

    registered[#registered + 1] = 'use_lighting_remote'
end

-- One line on join, so "No such export" can be told apart from "this file
-- never reached the server" without guessing. If you do not see this, the
-- folder you uploaded is missing client/items.lua.
CreateThread(function()
    Wait(3000)
    print(('^2[XS-Mechanic]^0 %d item export(s) registered: %s')
        :format(#registered, table.concat(registered, ', ')))
end)
