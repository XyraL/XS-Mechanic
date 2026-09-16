RegisterNUICallback('ready', function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    XSM.Close()
    cb({ ok = true })
end)

RegisterNUICallback('panel', function(data, cb)
    if data and data.id then XSM.panel = data.id end
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
        -- Either nothing is connected, or the vehicle belongs to a client that
        -- will not hand it over — in which case nothing would have happened at
        -- all, quietly, which is worse than saying so.
        XSM.Toast(XSM.vehicle and 'Cannot get hold of that vehicle.' or 'Nothing connected.', 'error')
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

-- Fitting is not instant. The panel steps aside, the mechanic works on the car
-- for as long as the category is worth, and the part goes on at the end.
RegisterNUICallback('apply', function(_, cb)
    local preview = XSM.preview

    if not preview or not XSM.vehicle then
        cb({ ok = false })
        return
    end

    -- The shelf is checked BEFORE the mechanic spends twelve seconds fitting
    -- something that was never going to go on.
    local stock = XSM.state and XSM.state.stock
    local item = stock and stock.categories and stock.categories[preview.category]

    if item and (stock.items[item] or 0) < 1 then
        XSM.Toast(('No %s on the shelf. Make one at the bench.'):format(
            string.lower(stock.labels[item] or item)), 'error')
        cb({ ok = false })
        return
    end

    local seconds = Config.Tuning.seconds[preview.category] or Config.Tuning.seconds.default or 0
    local panel = XSM.panel or 'tuning'

    if seconds > 0 then
        XSM.Hide()

        local done = Anim.Work(seconds, 'Fitting', preview.category)

        if not done then
            XSM.Unhide(panel)
            XSM.Toast('Left it as it was.', 'error')
            cb({ ok = false })
            return
        end

        XSM.Unhide(panel)
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

-- Staff only. A customer looking at the same screen gets a button that puts a
-- repair on their order instead; kits are used from the inventory, not here.
RegisterNUICallback('repair', function(_, cb)
    XSM.Close()

    if XSM.shop then Repair.AtBay(XSM.shop, nil) end

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

RegisterNUICallback('claimOrder', serverCall('claimOrder'))
RegisterNUICallback('finishOrder', serverCall('finishOrder'))
RegisterNUICallback('dropOrderLine', serverCall('dropOrderLine'))
RegisterNUICallback('setCategoryPrice', serverCall('setCategoryPrice'))
RegisterNUICallback('setTuningPrice', serverCall('setTuningPrice'))
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

RegisterNUICallback('drawArea', function(_, cb)
    cb({ ok = true })
    Builder.Area()
end)

RegisterNUICallback('clearArea', function(_, cb)
    Builder.ClearArea()
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
    -- An engine swap should take longer than a set of tyres, so the panel
    -- steps aside and the mechanic works on the car for a bit.
    local seconds = Config.CustomTuning.seconds[data.category] or Config.CustomTuning.seconds.default or 10

    local stock = XSM.state and XSM.state.stock
    local item = stock and stock.categories and stock.categories.performance

    if item and (stock.items[item] or 0) < 1 then
        XSM.Toast(('No %s on the shelf. Make one at the bench.'):format(
            string.lower(stock.labels[item] or item)), 'error')
        cb({ ok = false })
        return
    end

    if seconds > 0 then
        XSM.Hide()

        if not Anim.Work(seconds, 'Fitting', 'performance') then
            XSM.Unhide('performance')
            cb({ ok = false })
            return
        end
    end

    local result = lib.callback.await('XS-Mechanic:fitTuning', false, {
        shop = XSM.shop and XSM.shop.id,
        plate = XSM.catalogue and XSM.catalogue.plate,
        model = XSM.catalogue and XSM.catalogue.model,
        category = data.category,
        option = data.option,
    })

    if result and result.message then XSM.Notify(result.message, result.ok and 'success' or 'error')
    elseif result and result.error then XSM.Notify(result.error, 'error') end

    XSM.PushVehicle()

    if seconds > 0 then XSM.Unhide('performance') end

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

--[[ Building the list.

     A customer clicks a part and it goes on the car AND onto the list, and it
     stays on the car — so what they are looking at after five clicks is the
     five things they are about to ask for, priced, rather than one part at a
     time and a running total they have to imagine.

     One pick per slot: choosing a second front bumper replaces the first. ]]
local function putOnCar(pick)
    -- A repair is a job, not a part. There is nothing to show on the car, so
    -- there is nothing to put on it.
    if pick.plain then return true end

    if pick.paint then return Preview.Respray(pick) end
    if pick.extra then return Preview.Extra(pick.extra, pick.on) end

    return Preview.Show(pick)
end

local function rebuild()
    -- Back to the car as it arrived, then everything still on the list goes
    -- on again. Taking one part off cannot be done in isolation: putting a
    -- bumper back means knowing what was there, and that is the snapshot.
    Preview.Revert()

    for _, pick in ipairs(XSM.basket) do putOnCar(pick) end

    XSM.preview = nil
    XSM.PushVehicle()
    pushBasket()
end

local function forget(slotId)
    for index, pick in ipairs(XSM.basket) do
        if pick.slotId == slotId then
            table.remove(XSM.basket, index)
            return true
        end
    end

    return false
end

RegisterNUICallback('pickPart', function(data, cb)
    local had = forget(data.slotId)

    if data.remove then
        if had then rebuild() end

        cb({ ok = true })
        return
    end

    -- Putting a slot back to stock is not something to be charged for, so it
    -- takes the pick off the list rather than adding one. Nothing to take off
    -- means the car already looks like that.
    if not data.paint and not data.extra and tonumber(data.index) == -1 then
        if had then rebuild() end

        cb({ ok = true })
        return
    end

    if not putOnCar(data) then
        XSM.Toast(XSM.vehicle and 'Cannot get hold of that vehicle.' or 'Nothing connected.', 'error')
        cb({ ok = false })
        return
    end

    local priced = lib.callback.await('XS-Mechanic:pricePick', false, {
        shop = XSM.shop and XSM.shop.id,
        model = XSM.catalogue and XSM.catalogue.model,
        class = XSM.catalogue and XSM.catalogue.class,
        category = data.category,
        index = data.index,
    })

    XSM.basket[#XSM.basket + 1] = {
        category = data.category,
        categoryLabel = priced and priced.label or data.category,
        slotId = data.slotId,
        slot = data.slot,
        index = data.index,
        label = data.label,
        wheelType = data.wheelType,
        legacy = data.legacy,
        plain = data.plain,
        paint = data.paint,
        part = data.part,
        custom = data.custom,
        hex = data.hex,
        extra = data.extra,
        on = data.on,
        price = priced and priced.price or 0,
    }

    XSM.preview = nil
    XSM.PushVehicle()
    pushBasket()

    cb({ ok = true })
end)

RegisterNUICallback('dropPick', function(data, cb)
    local index = tonumber(data and data.index)

    if index and XSM.basket[index + 1] then
        table.remove(XSM.basket, index + 1)
        rebuild()
    end

    cb({ ok = true })
end)

RegisterNUICallback('clearPicks', function(_, cb)
    XSM.basket = {}
    rebuild()
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

    -- The order is placed, not done. The car goes back to how it arrived until
    -- somebody actually fits any of it.
    XSM.StopPreview(true)
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

    -- Everything picked is already on the car — that is what the customer has
    -- been looking at. Paying for it just makes it the truth.
    Preview.Commit()
    XSM.basket = {}
    pushBasket()
    XSM.PushVehicle()
    XSM.Toast(result.message or 'Done.', 'good')

    cb({ ok = true })
end)

-- The page measures where its transparent window is and posts it; the camera
-- frames the real vehicle into that rectangle.
RegisterNUICallback('carView', function(data, cb)
    Showcase.SetRect(data)
    cb({ ok = true })
end)
