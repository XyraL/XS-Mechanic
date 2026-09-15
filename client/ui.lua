RegisterNUICallback('ready', function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    XSM.Close()
    cb({ ok = true })
end)

RegisterNUICallback('connect', function(_, cb)
    XSM.Connect()
    cb({ ok = true })
end)

RegisterNUICallback('disconnect', function(_, cb)
    XSM.Disconnect()
    cb({ ok = true })
end)

RegisterNUICallback('settings', function(data, cb)
    XSM.state.settings = XSM.state.settings or {}
    XSM.state.settings[data.key] = data.value

    TriggerServerEvent('XS-Mechanic:server:settings', data.key, data.value)
    Hud.Update()

    cb({ ok = true })
end)

RegisterNUICallback('preview', function(data, cb)
    if not Preview.Show(data) then
        XSM.Toast('Nothing connected.', 'error')
        cb({ ok = false })
        return
    end

    cb({ ok = true })
end)

RegisterNUICallback('respray', function(data, cb)
    Preview.Respray(data)
    cb({ ok = true })
end)

RegisterNUICallback('extra', function(data, cb)
    Preview.Extra(data.id, data.on)
    cb({ ok = true })
end)

RegisterNUICallback('cancelPreview', function(_, cb)
    XSM.StopPreview(true)
    XSM.PushVehicle()
    cb({ ok = true })
end)

RegisterNUICallback('apply', function(_, cb)
    local preview = XSM.preview

    if not preview or not XSM.vehicle then
        cb({ ok = false })
        return
    end

    local result = lib.callback.await('XS-Mechanic:apply', false, {
        shop = XSM.shop and XSM.shop.id,
        mode = XSM.mode,
        netId = VehToNet(XSM.vehicle),
        plate = XSM.catalogue and XSM.catalogue.plate,
        model = XSM.catalogue and XSM.catalogue.model,
        class = XSM.catalogue and XSM.catalogue.class,
        category = preview.category,
        label = preview.label,
        slotId = preview.slotId,
        index = preview.index,
        price = preview.price,
    })

    if not result or not result.ok then
        XSM.Toast(result and result.error or 'That did not go through.', 'error')
        cb({ ok = false })
        return
    end

    Preview.Commit()
    XSM.PushVehicle()
    XSM.Refresh()
    XSM.Toast(result.message or 'Fitted.', 'good')

    cb({ ok = true })
end)

RegisterNUICallback('repair', function(data, cb)
    XSM.Close()

    if data.how == 'kit' then
        Repair.UseKit(data.item)
    elseif XSM.shop then
        Repair.AtBay(XSM.shop, nil)
    end

    cb({ ok = true })
end)

RegisterNUICallback('openWash', function(_, cb)
    XSM.Close()
    Repair.Wash()
    cb({ ok = true })
end)

local function serverCall(name)
    return function(data, cb)
        local result = lib.callback.await(('XS-Mechanic:%s'):format(name), false, data or {})

        if result and result.message then
            XSM.Toast(result.message, result.ok and 'good' or 'error')
        elseif result and not result.ok and result.error then
            XSM.Toast(result.error, 'error')
        end

        XSM.Refresh()
        cb(result or { ok = false })
    end
end

RegisterNUICallback('sendInvoice', serverCall('sendInvoice'))
RegisterNUICallback('saveInvoice', serverCall('saveInvoice'))
RegisterNUICallback('resendInvoice', serverCall('resendInvoice'))
RegisterNUICallback('dropLine', serverCall('dropLine'))

RegisterNUICallback('buyPart', serverCall('buyPart'))
RegisterNUICallback('claimOrder', serverCall('claimOrder'))
RegisterNUICallback('finishOrder', serverCall('finishOrder'))
RegisterNUICallback('shopMoney', serverCall('shopMoney'))
RegisterNUICallback('setGrade', serverCall('setGrade'))

RegisterNUICallback('hire', function(_, cb)
    local target = Team.NearestPlayer()

    if not target then
        XSM.Toast('Nobody close enough.', 'error')
        cb({ ok = false })
        return
    end

    local result = lib.callback.await('XS-Mechanic:hire', false, { target = target })

    if result and result.message then XSM.Toast(result.message, result.ok and 'good' or 'error') end

    XSM.Refresh()
    cb(result or { ok = false })
end)

RegisterNUICallback('fire', serverCall('fire'))

RegisterNUICallback('newShop', function(_, cb)
    Builder.New()
    cb({ ok = true })
end)

RegisterNUICallback('editShop', function(data, cb)
    Builder.Edit(data.id)
    cb({ ok = true })
end)

RegisterNUICallback('draftSet', function(data, cb)
    Builder.Set(data.key, data.value)
    cb({ ok = true })
end)

RegisterNUICallback('placePoint', function(data, cb)
    cb({ ok = true })
    Builder.Place(data.kind)
end)

RegisterNUICallback('movePoint', function(data, cb)
    cb({ ok = true })
    Builder.Move(data.id)
end)

RegisterNUICallback('dropPoint', function(data, cb)
    Builder.Drop(data.id)
    cb({ ok = true })
end)

RegisterNUICallback('saveShop', function(_, cb)
    Builder.Save()
    cb({ ok = true })
end)

RegisterNUICallback('toggleShop', function(_, cb)
    Builder.Toggle()
    cb({ ok = true })
end)

RegisterNUICallback('deleteShop', function(_, cb)
    Builder.Delete()
    cb({ ok = true })
end)

RegisterNUICallback('discardDraft', function(_, cb)
    Builder.Discard()
    cb({ ok = true })
end)

RegisterNUICallback('replacePart', function(data, cb)
    cb({ ok = true })
    ServiceUI.Replace(data.part)
end)

RegisterNUICallback('fitTuning', function(data, cb)
    local result = lib.callback.await('XS-Mechanic:fitTuning', false, {
        shop = XSM.shop and XSM.shop.id,
        plate = XSM.catalogue and XSM.catalogue.plate,
        model = XSM.catalogue and XSM.catalogue.model,
        category = data.category,
        option = data.option,
    })

    if result and result.message then XSM.Toast(result.message, result.ok and 'good' or 'error')
    elseif result and result.error then XSM.Toast(result.error, 'error') end

    XSM.PushVehicle()
    XSM.Refresh()
    cb(result or { ok = false })
end)

RegisterNUICallback('removeTuning', function(data, cb)
    local result = lib.callback.await('XS-Mechanic:removeTuning', false, {
        shop = XSM.shop and XSM.shop.id,
        plate = XSM.catalogue and XSM.catalogue.plate,
        category = data.category,
    })

    if result and result.message then XSM.Toast(result.message, result.ok and 'good' or 'error') end

    XSM.PushVehicle()
    XSM.Refresh()
    cb(result or { ok = false })
end)

RegisterNUICallback('previewStance', function(data, cb)
    if XSM.vehicle and DoesEntityExist(XSM.vehicle) then
        Stance.Preview(XSM.vehicle, data.stance)
    end

    cb({ ok = true })
end)

RegisterNUICallback('saveStance', function(data, cb)
    local result = lib.callback.await('XS-Mechanic:saveStance', false, {
        shop = XSM.shop and XSM.shop.id,
        plate = XSM.catalogue and XSM.catalogue.plate,
        model = XSM.catalogue and XSM.catalogue.model,
        class = XSM.catalogue and XSM.catalogue.class,
        stance = data.stance,
    })

    if result and result.message then XSM.Toast(result.message, result.ok and 'good' or 'error')
    elseif result and result.error then XSM.Toast(result.error, 'error') end

    XSM.Refresh()
    cb(result or { ok = false })
end)

RegisterNUICallback('runDyno', function(_, cb)
    cb({ ok = true })
    Dyno.Run()
end)

RegisterNUICallback('stopDyno', function(_, cb)
    Dyno.Stop()
    cb({ ok = true })
end)

RegisterNUICallback('shareDyno', function(_, cb)
    Dyno.Share()
    cb({ ok = true })
end)

-- The bay basket. A customer picks, sees it on the car, and the shop gets the
-- list. Prices shown are the shop's list price; the server prices the order
-- again when it lands, so nothing here is trusted.
XSM.basket = {}

local function pushBasket()
    XSM.Send('state', { state = { basket = XSM.basket } })
end

RegisterNUICallback('addPick', function(data, cb)
    local pick = XSM.preview

    -- A blind category (performance) posts the pick with the payload instead
    -- of previewing it first.
    if data and data.category then
        pick = {
            category = data.category,
            slotId = data.slotId,
            slot = data.slot,
            index = data.index,
            label = data.label,
        }
    end

    if not pick then
        cb({ ok = false })
        return
    end

    local priced = lib.callback.await('XS-Mechanic:pricePick', false, {
        shop = XSM.shop and XSM.shop.id,
        model = XSM.catalogue and XSM.catalogue.model,
        class = XSM.catalogue and XSM.catalogue.class,
        category = pick.category,
        index = pick.index,
    })

    XSM.basket[#XSM.basket + 1] = {
        category = pick.category,
        categoryLabel = priced and priced.label or pick.category,
        slotId = pick.slotId,
        slot = pick.slot,
        index = pick.index,
        label = pick.label,
        wheelType = pick.wheelType,
        legacy = pick.legacy,
        price = priced and priced.price or 0,
    }

    -- The car goes back to how it arrived; the pick lives on the list now.
    XSM.StopPreview(false)
    XSM.PushVehicle()
    pushBasket()

    cb({ ok = true })
end)

RegisterNUICallback('dropPick', function(data, cb)
    local index = tonumber(data and data.index)

    if index and XSM.basket[index + 1] then
        table.remove(XSM.basket, index + 1)
        pushBasket()
    end

    cb({ ok = true })
end)

RegisterNUICallback('submitOrder', function(_, cb)
    if #XSM.basket == 0 then
        cb({ ok = false })
        return
    end

    local notes = lib.inputDialog('Anything to tell them?', {
        { type = 'textarea', label = 'Notes', required = false, max = 300,
          description = 'Optional. Colour preferences, what it is doing, when you need it back.' },
    })

    local result = lib.callback.await('XS-Mechanic:submitOrder', false, {
        shop = XSM.shop and XSM.shop.id,
        plate = XSM.catalogue and XSM.catalogue.plate,
        model = XSM.catalogue and XSM.catalogue.model,
        picks = XSM.basket,
        notes = notes and notes[1] or '',
    })

    if not result or not result.ok then
        XSM.Toast(result and result.error or 'That did not go through.', 'error')
        cb({ ok = false })
        return
    end

    XSM.basket = {}
    pushBasket()
    XSM.Toast(result.message or 'Sent to the shop.', 'good')
    XSM.Close()

    cb({ ok = true })
end)

RegisterNUICallback('checkout', function(_, cb)
    local result = lib.callback.await('XS-Mechanic:checkout', false, {
        shop = XSM.shop and XSM.shop.id,
        plate = XSM.catalogue and XSM.catalogue.plate,
        model = XSM.catalogue and XSM.catalogue.model,
        class = XSM.catalogue and XSM.catalogue.class,
        picks = XSM.basket,
    })

    if not result or not result.ok then
        XSM.Toast(result and result.error or 'That did not go through.', 'error')
        cb({ ok = false })
        return
    end

    -- Paid for, so what is on the car now is the truth.
    for _, pick in ipairs(XSM.basket) do
        Preview.Show(pick)
    end

    Preview.Commit()
    XSM.basket = {}
    pushBasket()
    XSM.PushVehicle()
    XSM.Toast(result.message or 'Done.', 'good')

    cb({ ok = true })
end)
