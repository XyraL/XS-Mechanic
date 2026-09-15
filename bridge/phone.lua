Phone = { name = nil }

if not IsDuplicityVersion() then return end

local function detect()
    local forced = Config.Bridges.phone
    if forced ~= 'auto' then return forced ~= 'none' and forced or nil end

    for _, name in ipairs({ 'lb-phone', 'qs-smartphone', 'XS-Phone', 'qb-phone', 'gksphone' }) do
        if GetResourceState(name) == 'started' then return name end
    end

    return nil
end

Phone.name = detect()

-- Notifications only. Registering an app is a per-phone affair and several of
-- these have no API for it at all, so an invoice announces itself and the
-- player opens /invoices to deal with it.
function Phone.Notify(src, title, message)
    if not Phone.name then return false end

    local citizenid = Framework.GetCitizenId(src)
    if not citizenid then return false end

    local ok = pcall(function()
        if Phone.name == 'lb-phone' then
            local number = exports['lb-phone']:GetEquippedPhoneNumber(src)
            if not number then return end

            exports['lb-phone']:SendNotification({
                number = number,
                app = 'Messages',
                title = title,
                content = message,
            })
            return
        end

        if Phone.name == 'XS-Phone' then
            exports['XS-Phone']:Notify(src, title, message)
            return
        end

        if Phone.name == 'qs-smartphone' then
            TriggerClientEvent('qs-smartphone:client:notify', src, { title = title, text = message })
            return
        end

        if Phone.name == 'gksphone' then
            TriggerClientEvent('gksphone:notifi', src, { title = title, message = message })
            return
        end

        TriggerClientEvent('qb-phone:client:customNotify', src, { title = title, text = message })
    end)

    return ok
end
