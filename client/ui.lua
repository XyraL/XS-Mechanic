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

RegisterNUICallback('lift', function(data, cb)
    XSM.lifted = data.up and true or false
    XSM.Send('state', { state = { lifted = XSM.lifted } })
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
RegisterNUICallback('checkout', serverCall('checkout'))
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
