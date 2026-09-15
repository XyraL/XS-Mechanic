CreateThread(function()
    if not Framework.name then return end

    if not DB.Ensure() then
        print('^1[XS-Mechanic]^0 The database is not ready. Nothing will save.')
        return
    end

    local shops = Store.Load()
    local count = 0
    for _ in pairs(shops) do count = count + 1 end

    -- Registering every stash on start covers a restart having forgotten them.
    for _, shop in pairs(shops) do
        for _, point in ipairs(shop.points or {}) do
            if point.kind == 'storage' then
                Inventory.RegisterStash(
                    ('xsmech_%s_%s'):format(shop.id, point.id),
                    ('%s storage'):format(shop.name), 60, 200000)
            end
        end
    end

    print(('^2[XS-Mechanic]^0 %d shop(s) loaded. Framework: %s. Inventory: %s. Banking: %s.'):format(
        count,
        Framework.name,
        Inventory.name or 'none',
        Banking.name or 'own ledger'))

    if count == 0 then
        print(('^3[XS-Mechanic]^0 Nothing is built yet. Run /%s in game to make your first shop.'):format(Config.Builder.command))
    end

    Wait(2000)
    Store.Broadcast()
end)

AddEventHandler('playerJoining', function()
    local src = source

    CreateThread(function()
        Wait(4000)
        TriggerClientEvent('XS-Mechanic:client:shops', src, Store.Public())
    end)
end)

if Config.Invoices.expireDays > 0 then
    CreateThread(function()
        while true do
            Wait(60 * 60 * 1000)

            MySQL.query.await([[
                DELETE FROM xs_mechanic_invoices
                WHERE status = 'sent' AND created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
            ]], { Config.Invoices.expireDays })
        end
    end)
end

exports('GetShops', function()
    return Store.All()
end)

exports('GetVehicleProfile', function(plate)
    return Vehicles.Profile(plate)
end)

exports('IsMechanic', function(src)
    local job = Framework.GetJob(src)
    return Store.ByJob(job) ~= nil
end)
