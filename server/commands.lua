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
    -- ox_inventory's client.export path lives in client/items.lua; it has to
    -- be registered on the client or ox cannot find it.
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

-- qb-style inventories use the framework registrar instead.
if Inventory.name ~= 'ox_inventory' then
    CreateThread(function()
        Wait(2000)

        local pocket = {
            [Config.Nitrous.item] = 'XS-Mechanic:client:useNitrous',
            [Config.Lighting.item] = 'XS-Mechanic:client:useLighting',
        }

        for item, event in pairs(pocket) do
            if item and item ~= '' then
                local handler = function(src) TriggerClientEvent(event, src) end

                if Framework.name == 'qbox' then
                    exports.qbx_core:CreateUseableItem(item, handler)
                elseif Framework.core then
                    Framework.core.Functions.CreateUseableItem(item, handler)
                end
            end
        end
    end)
end

-- Everything the resource decided at startup, in one place. First thing to run
-- when something is not behaving: it says what was detected, what is switched
-- on, and what is missing, so nobody has to guess which layer is at fault.
RegisterCommand('mechanicdebug', function(source)
    if source ~= 0 and not Framework.IsAdmin(source) then return end

    local out = {}

    local function line(text)
        out[#out + 1] = text
    end

    line(('XS-Mechanic %s'):format(GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '?'))
    line(('  framework   %s'):format(Framework.name or 'NONE — nothing will work'))
    line(('  inventory   %s'):format(Inventory.name or 'none detected'))
    line(('  banking     %s'):format(Banking.name or 'own ledger'))
    line(('  phone       %s'):format(Phone.name or 'none detected'))
    line(('  database    %s'):format(DB.ready and 'ready' or 'NOT READY — nothing will save'))

    local shops = Store.All()
    line(('  shops       %d'):format(#shops))

    for _, shop in ipairs(shops) do
        local points = {}

        for _, point in ipairs(shop.points or {}) do
            points[point.kind] = (points[point.kind] or 0) + 1
        end

        local parts = {}
        for kind, count in pairs(points) do parts[#parts + 1] = ('%s x%d'):format(kind, count) end
        table.sort(parts)

        line(('    #%d %s — %s, job %s, %s'):format(
            shop.id, shop.name, shop.kind,
            shop.job ~= '' and shop.job or 'none',
            shop.enabled and 'ON' or 'OFF'))

        line(('       points: %s'):format(#parts > 0 and table.concat(parts, ', ') or 'NONE — this shop does nothing'))

        if Util.HasArea(shop.area) then
            line(('       boundary: %d corners, z %.1f to %.1f'):format(
                #shop.area.points, shop.area.minZ or 0.0, shop.area.maxZ or 0.0))
        elseif Config.Tablet.insideShopOnly then
            line('       boundary: NONE — this shop can be used from anywhere on the map')
        end

        if Config.Parts.requireStock then
            local shelf = Stock.StashOf(shop)
            local short = {}

            for category, item in pairs(Config.Parts.categoryItems) do
                if item ~= '' and Stock.Count(shop, item, 0) < 1 then
                    short[#short + 1] = category
                end
            end

            table.sort(short)

            line(('       stock: %s%s'):format(
                shelf and 'read from the storage point' or 'no storage point — reads the mechanic',
                #short > 0 and (', out of: ' .. table.concat(short, ', ')) or ', everything in'))
        end

        if shop.kind == 'owned' then
            if shop.job == '' then
                line('       WARNING: owned shop with no job')
            elseif not Framework.JobExists(shop.job) then
                line(('       WARNING: your framework has no job called "%s"'):format(shop.job))
            else
                line(('       staff online: %d'):format(Team.OnDuty(shop)))
            end
        end
    end

    line('  switched on:')
    line(('    servicing %s · custom tuning %s · dyno %s'):format(
        Config.Service.enabled and 'yes' or 'no',
        Config.CustomTuning.enabled and 'yes' or 'no',
        Config.Dyno.enabled and 'yes' or 'no'))
    line(('    invoices %s · live car preview %s · tablet anim %s'):format(
        Config.Invoices.enabled and 'yes' or 'no',
        Config.Tablet.livePreview and 'yes' or 'no',
        Config.Tablet.animation and 'yes' or 'no'))
    line(('    crafting %s · stock %s · shop boundaries %s'):format(
        Config.Crafting.enabled and 'yes' or 'no',
        Config.Parts.requireStock and 'yes' or 'no',
        Config.Tablet.insideShopOnly and 'enforced' or 'off'))

    -- Stock read off a shelf needs an inventory that can be asked about one.
    -- Without that every shop silently falls back to the mechanic's pockets.
    if Config.Parts.requireStock and not Inventory.StashReady() then
        line(('    NOTE: %s cannot be read without somebody opening it, so stock comes'):format(Inventory.name or 'your inventory'))
        line('          off the mechanic instead of the shop shelf. ox_inventory can.')
    end

    line(('  tablet item %s'):format(Config.Tablet.item ~= '' and Config.Tablet.item or 'none (command only)'))

    if Config.Tablet.item ~= '' and Inventory.name == 'ox_inventory' then
        line('    ox_inventory: the item needs client = { export = \'XS-Mechanic.openTablet\' }')
    end

    for _, text in ipairs(out) do
        if source == 0 then print(text) else TriggerClientEvent('chat:addMessage', source, { args = { '', text } }) end
    end
end, false)
