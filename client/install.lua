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
-- How far you are from the car's body, not from its middle. Measured from the
-- centre, standing at a bumper or a wheel on anything longer than a hatchback
-- read as not being at the car at all.
local REACH = 2.0

local function fromBody(vehicle, coords)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    local at = GetOffsetFromEntityGivenWorldCoords(vehicle, coords.x, coords.y, coords.z)

    local dx = math.max(min.x - at.x, 0.0, at.x - max.x)
    local dy = math.max(min.y - at.y, 0.0, at.y - max.y)

    return math.sqrt(dx * dx + dy * dy)
end

local function carInFront()
    -- Sat in it is not stood at it. Nothing about fitting a part works from
    -- the driver's seat, and the animation plays into the roof.
    if IsPedInAnyVehicle(cache.ped, false) then
        return nil, 'Get out of the car first.'
    end

    local coords = GetEntityCoords(cache.ped)

    -- The car the tablet is plugged into wins whenever you are at it.
    if XSM.vehicle and DoesEntityExist(XSM.vehicle) and fromBody(XSM.vehicle, coords) <= REACH then
        return XSM.vehicle
    end

    local vehicle, nearest

    for _, entity in ipairs(GetGamePool('CVehicle')) do
        if #(coords - GetEntityCoords(entity)) < 12.0 then
            local gap = fromBody(entity, coords)

            if gap <= REACH and (not nearest or gap < nearest) then
                vehicle, nearest = entity, gap
            end
        end
    end

    if not vehicle then return nil end

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

        -- No order for this plate is not a refusal any more: the part asks
        -- what it should go on. A real error — another shop's order, not a
        -- mechanic — still stops here, because those are answers, not silence.
        if not found or not found.ok then
            if found and found.noOrder then
                Install.Free(vehicle, item)
            else
                XSM.Notify(found and found.error or 'Nothing written down for that car.', 'error')
            end
            return
        end

        local lines = found.lines or {}

        if #lines == 0 then
            Install.Free(vehicle, item)
            return
        end

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

--[[ Fitting with nothing written down.

     A work order is how a shop bills a customer, and plenty of work never gets
     billed: a mechanic doing their own car, or one the boss waved through. Used
     with no order against the plate, a part asks what it should go on instead
     of refusing.

     What it offers is read off the car, the same as the tuning screen, and
     narrowed to the slots this particular part is the part for — an interior
     part offers interior slots and nothing else. ]]
--[[ Custom tuning packages that this part is the part for.

     A brake kit is not a mod slot — there is no GTA slot for it — so searching
     the catalogue for it finds nothing and the part looks unusable. These live
     in Tuning.Options with an item name of their own, which is what makes
     'brake_kit' and 'drift_kit' different from 'brake_parts'. ]]
local function packagesForItem(item)
    if not item or not Config.CustomTuning.enabled then return {} end

    local out = {}

    for _, category in ipairs(Tuning.Categories or {}) do
        local choices = {}

        for _, option in ipairs((Tuning.Options or {})[category.id] or {}) do
            if option.item == item then
                choices[#choices + 1] = {
                    index = option.id,
                    label = option.name,
                    tuning = { category = category.id, option = option.id },
                }
            end
        end

        if #choices > 0 then
            out[#out + 1] = {
                slot = { id = category.id, label = category.label, category = 'performance', package = true },
                choices = choices,
            }
        end
    end

    return out
end

-- Servicing parts replace a worn part rather than fitting a new option, so
-- they have one choice each and go down the servicing road.
local function serviceForItem(item)
    if not item or Config.Service.enabled == false then return nil end

    for _, part in ipairs(Service.Parts or {}) do
        if part.item == item then return part end
    end

    return nil
end

local function slotsForItem(item)
    local cat = XSM.catalogue
    if not cat or not item then return {} end

    local out = {}

    for _, slot in ipairs(cat.slots or {}) do
        if Parts.ItemFor(slot.category, slot.id) == item then
            -- Only what is not already on the car. Offering the bumper that is
            -- already fitted is an option that charges a part for nothing.
            local choices = {}

            for _, option in ipairs(slot.options or {}) do
                if option.index ~= slot.current then choices[#choices + 1] = option end
            end

            if #choices > 0 then
                out[#out + 1] = { slot = slot, choices = choices }
            end
        end
    end

    return out
end

-- Fit one option, with no order behind it.
local function fitFree(vehicle, slot, option, item)
    if not Preview.Control(vehicle) then
        XSM.Notify('Cannot get hold of that car.', 'error')
        return false
    end

    -- A package changes how the car drives and has nothing to look at, so it
    -- is timed off the custom tuning list and never touches a mod slot.
    local seconds = slot.package
        and (Config.CustomTuning.seconds[slot.id] or Config.CustomTuning.seconds.default or 10)
        or (Config.Tuning.seconds[slot.category] or Config.Tuning.seconds.default or 0)

    if seconds > 0 and not Anim.Work(seconds, ('Fitting %s'):format(option.label or slot.label)) then
        return false
    end

    -- Nothing to set on the car for a package: the server owns the handling.
    if not slot.package then
        local line = {
            category = slot.category,
            slotId = slot.id,
            slot = slot.slot,
            index = option.index,
            label = option.label,
        }

        if not Preview.Show(line) then
            XSM.Notify('That did not go on.', 'error')
            return false
        end
    end

    local result = lib.callback.await('XS-Mechanic:fitFree', false, {
        netId = VehToNet(vehicle),
        plate = XSM.catalogue and XSM.catalogue.plate,
        -- Sent so the server can refuse a slot this model does not have. It is
        -- checked there against the same blocklist the catalogue was built
        -- from, not taken as permission.
        model = XSM.catalogue and XSM.catalogue.model,
        category = slot.category,
        slotId = slot.id,
        index = option.index,
        tuning = option.tuning,
        item = item,
    })

    if not result or not result.ok then
        if not slot.package then Preview.Revert() end
        XSM.PushVehicle()
        XSM.Notify(result and result.error or 'That did not go through.', 'error')
        return false
    end

    if not slot.package then Preview.Commit() end
    XSM.PushVehicle()
    XSM.Notify(result.message or ('%s fitted.'):format(option.label), 'success')

    return true
end

function Install.Free(vehicle, item)
    -- A servicing part is not a fitting choice: there is one thing it replaces
    -- and the servicing screen already knows how. Hand it straight over.
    local service = serviceForItem(item)

    if service then
        XSM.Notify(('Use the Service screen to replace the %s.'):format(string.lower(service.label or 'part')), 'inform')
        XSM.Open('tablet')
        XSM.Show('service')
        return
    end

    local groups = slotsForItem(item)

    for _, package in ipairs(packagesForItem(item)) do
        groups[#groups + 1] = package
    end

    if #groups == 0 then
        XSM.Notify('Nothing on this car takes that.', 'error')
        return
    end

    --[[ What the car has been booked in for, whatever part it is waiting on.

         Asked without an item so it answers for the whole order, not just this
         part. If a slot is on the order, that slot is spoken for: the customer
         asked for engine level 3 and paid for engine level 3, so level 2 is
         greyed out rather than a free choice a mechanic can make by accident.

         Slots the order says nothing about stay open — the order is a promise
         about what it names, not a ban on everything else. ]]
    local ordered = {}

    local booked = lib.callback.await('XS-Mechanic:orderLines', false, {
        plate = XSM.catalogue and XSM.catalogue.plate,
        model = XSM.catalogue and XSM.catalogue.model,
    })

    for _, line in ipairs(booked and booked.lines or {}) do
        if line.slotId and not line.fitted then
            ordered[line.slotId] = ordered[line.slotId] or {}
            ordered[line.slotId][tostring(line.index)] = line.label or true
        end
    end

    -- One slot takes it, so skip straight to what it could be.
    if #groups == 1 then
        Install.Options(vehicle, groups[1], item, ordered)
        return
    end

    local options = {}

    for _, group in ipairs(groups) do
        local booking = ordered[group.slot.id]

        options[#options + 1] = {
            title = group.slot.label,
            description = booking
                and 'On the work order'
                or ('%d to choose from'):format(#group.choices),
            icon = booking and 'clipboard-check' or 'wrench',
            onSelect = function() Install.Options(vehicle, group, item, ordered) end,
        }
    end

    lib.registerContext({
        id = 'xsmech_free_slots',
        title = 'What is it going on?',
        options = options,
    })

    lib.showContext('xsmech_free_slots')
end

function Install.Options(vehicle, group, item, ordered)
    local booking = (ordered or {})[group.slot.id]
    local options = {}

    for _, choice in ipairs(group.choices) do
        -- With this slot on the work order, only what was ordered can be
        -- fitted. The rest stay on the list, greyed, so it is obvious the
        -- choice was made by the customer and not taken away by the menu.
        local wanted = not booking or booking[tostring(choice.index)] ~= nil

        options[#options + 1] = {
            title = choice.label,
            description = booking
                and (wanted and 'On the work order' or 'Not what was ordered')
                or (choice.index == -1 and 'Back to stock' or nil),
            icon = wanted and 'screwdriver-wrench' or 'ban',
            disabled = not wanted,
            onSelect = wanted and function() fitFree(vehicle, group.slot, choice, item) end or nil,
        }
    end

    lib.registerContext({
        id = 'xsmech_free_options',
        title = group.slot.label,
        menu = #slotsForItem(item) > 1 and 'xsmech_free_slots' or nil,
        options = options,
    })

    lib.showContext('xsmech_free_options')
end

--[[ One named line, fitted from the work order screen.

     Same road as using the part — the server still picks the line, takes the
     part and ticks it off — but it starts from the order rather than from the
     thing in your pockets. Reading the order and then walking away to find the
     part to use it was the long way round when the car is right there. ]]
function Install.Line(orderId, lid)
    if busy then return end

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
        local found = lib.callback.await('XS-Mechanic:orderLines', false, {
            plate = Util.Trim(GetVehicleNumberPlateText(vehicle) or ''),
            model = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) or ''),
        })

        if not found or not found.ok then
            XSM.Notify(found and found.error or 'Nothing written down for that car.', 'error')
            return
        end

        for _, line in ipairs(found.lines or {}) do
            if line.orderId == orderId and line.lid == lid then
                fit(vehicle, line, line.needs)
                return
            end
        end

        -- Reachable honestly: somebody else fitted it, or the part left the
        -- shelf, between the screen being drawn and the button being pressed.
        XSM.Notify('That line is not waiting on anything any more.', 'error')
    end)

    busy = false

    if not ok then print(('^1[XS-Mechanic]^0 fit from order failed: %s'):format(err)) end
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
            byHand = true,
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
