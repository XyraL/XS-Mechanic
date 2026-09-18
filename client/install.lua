Install = {}

--[[ Fitting a part by using it.

     The tablet writes the job down and bills for it. This is where a car
     actually changes: a mechanic stands at it with a part in their pockets and
     uses the part. What goes on is read off the work order for that plate, so
     a paint can knows which colour it is and a body part knows which bumper.

     Nothing here decides anything on its own. The server picks the line, takes
     the part and ticks it off; this end finds the car, plays the animation and
     sets the mod. ]]

local busy = false

-- The car being worked on. Whatever the tablet is connected to if you are
-- stood at it, otherwise whatever you are stood at — using a part IS the act
-- of connecting to a car, and asking somebody to open the tablet first to tell
-- it something it can see for itself is a step for nothing.
local function carInFront()
    -- Sat in it is not stood at it. Nothing about fitting a part works from
    -- the driver's seat, and the animation plays into the roof.
    if IsPedInAnyVehicle(cache.ped, false) then
        return nil, 'Get out of the car first.'
    end

    local coords = GetEntityCoords(cache.ped)

    if XSM.vehicle and DoesEntityExist(XSM.vehicle)
        and #(coords - GetEntityCoords(XSM.vehicle)) <= 5.0 then
        return XSM.vehicle
    end

    local vehicle = lib.getClosestVehicle(coords, 3.0, true)
    if not vehicle or vehicle == 0 then return nil end

    if XSM.vehicle ~= vehicle then
        XSM.StopPreview(false)
        XSM.vehicle = vehicle
        XSM.catalogue = Catalogue.Build(vehicle)
    end

    return vehicle
end

local function apply(vehicle, line)
    SetVehicleModKit(vehicle, 0)

    if line.paint then return Preview.Respray(line) end
    if line.extra ~= nil then return Preview.Extra(line.extra, line.on) end

    -- A handling package is fitted on the server. There is no mod slot to set
    -- and nothing to look at.
    if line.tuning then return true end

    return Preview.Show(line)
end

-- One line, start to finish.
local function fit(vehicle, line, item)
    -- Asked before the animation, because the usual reason a fit does nothing
    -- is the owner sitting in the car, and finding that out after eight
    -- seconds of welding costs the part.
    if not Preview.Control(vehicle) then
        XSM.Notify('Cannot get hold of that car.', 'error')
        return false
    end

    -- An engine swap takes longer than a set of tyres, and the two lists of
    -- timings are kept apart because a package is not a mod slot.
    local seconds = line.tuning
        and (Config.CustomTuning.seconds[line.tuning.category] or Config.CustomTuning.seconds.default or 10)
        or (Config.Tuning.seconds[line.category] or Config.Tuning.seconds.default or 0)

    if seconds > 0 and not Anim.Work(seconds, ('Fitting %s'):format(line.label or 'it')) then
        return false
    end

    if not apply(vehicle, line) then
        XSM.Notify('That did not go on.', 'error')
        return false
    end

    local result = lib.callback.await('XS-Mechanic:fitLine', false, {
        orderId = line.orderId,
        lid = line.lid,
        netId = VehToNet(vehicle),
        plate = XSM.catalogue and XSM.catalogue.plate,
        item = item,
    })

    if not result or not result.ok then
        -- The part never left your pockets, so the car does not keep the work.
        Preview.Revert()
        XSM.PushVehicle()
        XSM.Notify(result and result.error or 'That did not go through.', 'error')
        return false
    end

    -- Paid for and on. It is part of the car now, not something to put back.
    Preview.Commit()
    XSM.PushVehicle()
    XSM.Notify(result.message, 'success')

    if XSM.open then XSM.Refresh() end

    return true
end

function Install.Use(item)
    if busy then return end

    -- Picks sitting on the car are a preview, and fitting underneath one puts
    -- the preview's version of the part on instead of the order's.
    if #(XSM.basket or {}) > 0 then
        XSM.Notify('Finish what you are picking first.', 'error')
        return
    end

    local vehicle, why = carInFront()

    if not vehicle then
        XSM.Notify(why or 'Stand at the car you are working on.', 'error')
        return
    end

    busy = true

    local ok, err = pcall(function()
        local plate = Util.Trim(GetVehicleNumberPlateText(vehicle) or '')
        local model = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) or '')

        local found = lib.callback.await('XS-Mechanic:orderLines', false, {
            plate = plate, model = model, item = item,
        })

        if not found or not found.ok then
            XSM.Notify(found and found.error or 'Nothing written down for that car.', 'error')
            return
        end

        local lines = found.lines or {}

        if #lines == 1 then
            fit(vehicle, lines[1], item)
            return
        end

        Install.Pick(vehicle, lines, item, found.orders or 1)
    end)

    busy = false

    if not ok then print(('^1[XS-Mechanic]^0 install failed: %s'):format(err)) end
end

-- More than one line wants this part. A body kit is eight body parts, so this
-- is the everyday case rather than the odd one, which is why fitting the lot
-- is here and not something you do eight times.
function Install.Pick(vehicle, lines, item, orders)
    local options = {}

    for _, line in ipairs(lines) do
        options[#options + 1] = {
            title = line.label,
            description = ('%s · %s%s'):format(
                line.categoryLabel or line.category,
                Util.Money(line.price or 0),
                orders > 1 and (' · Order #%d'):format(line.orderId) or ''),
            icon = 'wrench',
            onSelect = function() fit(vehicle, line, item) end,
        }
    end

    options[#options + 1] = {
        title = ('Fit the lot (%d)'):format(#lines),
        description = ('Uses %d.'):format(#lines),
        icon = 'layer-group',
        onSelect = function()
            for _, line in ipairs(lines) do
                if not fit(vehicle, line, item) then break end
            end
        end,
    }

    lib.registerContext({
        id = 'xsmech_fit',
        title = Util.Trim(GetVehicleNumberPlateText(vehicle) or 'Vehicle'),
        options = options,
    })

    lib.showContext('xsmech_fit')
end

-- The lines with no part behind them: an extra being switched off, a package
-- coming back off, and everything on a server that does not run on parts.
-- There is nothing to use, so they are done from the order itself.
function Install.ByHand()
    if busy then return end

    local vehicle, why = carInFront()

    if not vehicle then
        XSM.Notify(why or 'Stand at the car you are working on.', 'error')
        return
    end

    busy = true

    local ok = pcall(function()
        local found = lib.callback.await('XS-Mechanic:orderLines', false, {
            plate = Util.Trim(GetVehicleNumberPlateText(vehicle) or ''),
            model = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) or ''),
        })

        if not found or not found.ok then
            XSM.Notify(found and found.error or 'Nothing to do by hand.', 'error')
            return
        end

        local lines = found.lines or {}

        if #lines == 1 then
            fit(vehicle, lines[1], nil)
            return
        end

        Install.Pick(vehicle, lines, nil, found.orders or 1)
    end)

    busy = false

    if not ok then XSM.Notify('That did not go through.', 'error') end
end

RegisterNetEvent('XS-Mechanic:client:useItem', function(item)
    Install.Use(item)
end)
