Builder = { draft = nil, dirty = false }

--[[ The draft lives here in Lua, not in the panel.

     Points are placed with the free camera, so a copy held by the page goes
     stale the moment anything moves. The panel asks for a change, Lua makes
     it, and Lua pushes the whole draft back. ]]

local LIMITS = {
    tuning = 'bays', repair = 'bays', counter = 'shops',
    storage = 'storage', laptop = 'shops', desk = 'desks', duty = 'duty',
}

local LABELS = {
    tuning = 'Tuning bay', repair = 'Repair bay', counter = 'Parts counter',
    storage = 'Storage', laptop = 'Office laptop', desk = 'Customer desk', duty = 'Duty point',
}

local preview = {}

local function clearPreview()
    for _, blip in ipairs(preview) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    preview = {}
end

local function drawPreview()
    clearPreview()

    for _, point in ipairs(Builder.draft and Builder.draft.points or {}) do
        local blip = AddBlipForCoord(point.coords.x, point.coords.y, point.coords.z)
        SetBlipSprite(blip, 1)
        SetBlipScale(blip, 0.6)
        SetBlipColour(blip, point.kind == 'tuning' and 47 or 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(('[%s] %s'):format(LABELS[point.kind] or point.kind, point.label or ''))
        EndTextCommandSetBlipName(blip)
        preview[#preview + 1] = blip
    end
end

-- The footprint is worked out from what has been placed, so it moves as you
-- build and there is no radius to set too small by hand.
local function bounds(draft)
    local points = draft.points or {}
    if #points == 0 then return nil end

    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

    for _, point in ipairs(points) do
        minX = math.min(minX, point.coords.x)
        minY = math.min(minY, point.coords.y)
        minZ = math.min(minZ, point.coords.z)
        maxX = math.max(maxX, point.coords.x)
        maxY = math.max(maxY, point.coords.y)
        maxZ = math.max(maxZ, point.coords.z)
    end

    local cx, cy, cz = (minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2
    local radius = math.max(12.0, math.max(maxX - minX, maxY - minY) / 2 + 8.0)

    return { x = cx, y = cy, z = cz, radius = radius }
end

local function push()
    if not Builder.draft then
        XSM.Send('draft', { draft = false })
        return
    end

    Builder.draft.bounds = bounds(Builder.draft)

    local jobMissing = false
    if Builder.draft.kind == 'owned' and Builder.draft.job ~= '' then
        jobMissing = not lib.callback.await('XS-Mechanic:jobExists', false, { job = Builder.draft.job })
    end

    local copy = Util.Plain(Builder.draft)
    copy.jobMissing = jobMissing
    copy.dirty = Builder.dirty

    XSM.Send('draft', { draft = copy })
    drawPreview()
end

Builder.Push = push

local function touch()
    Builder.dirty = true
    push()
end

function Builder.New()
    Builder.draft = {
        id = nil,
        name = 'New shop',
        kind = 'owned',
        job = '',
        bossGrade = Config.Jobs.defaultBossGrade,
        commission = Config.Invoices.defaultCommission,
        accent = 'amber',
        enabled = true,
        selfServiceWhenEmpty = true,
        points = {},
        pricing = {},
        categories = {},
        parts = {},
        blip = { enabled = true, sprite = 446, colour = 47, scale = 0.7 },
    }

    Builder.dirty = true
    push()
end

function Builder.Edit(id)
    local shop = lib.callback.await('XS-Mechanic:shop', false, { id = id })

    if not shop or not shop.ok then
        XSM.Toast(shop and shop.error or 'That shop is gone.', 'error')
        return
    end

    Builder.draft = shop.shop
    Builder.dirty = false
    push()
end

function Builder.Set(key, value)
    if not Builder.draft then return end

    if key == 'bossGrade' or key == 'commission' then
        value = math.max(0, math.floor(tonumber(value) or 0))
    end

    Builder.draft[key] = value
    touch()
end

function Builder.Discard()
    Builder.draft = nil
    Builder.dirty = false
    clearPreview()
    push()
end

local function limitFor(kind)
    local key = LIMITS[kind]
    return key and Config.Builder.limits[key] or 8
end

local function countOf(kind)
    local total = 0
    for _, point in ipairs(Builder.draft.points or {}) do
        if point.kind == kind then total = total + 1 end
    end
    return total
end

function Builder.Place(kind)
    if not Builder.draft then return end

    if countOf(kind) >= limitFor(kind) then
        XSM.Toast(('You already have the most %s this shop can take.'):format(LABELS[kind] or kind), 'error')
        return
    end

    -- The panel has to let go of the keyboard while the camera has it.
    SetNuiFocus(false, false)
    XSM.Send('close')

    local result = Placement.Start({
        mode = (kind == 'tuning' or kind == 'repair') and 'zone' or 'point',
        label = LABELS[kind] or kind,
        colour = Zones.Colour[kind],
        radius = (kind == 'tuning' or kind == 'repair') and 5.0 or 1.8,
    })

    SetNuiFocus(true, true)
    XSM.Send('open', { mode = 'builder', state = XSM.state, panel = 'builder' })

    if not result then push() return end

    Builder.draft.points[#Builder.draft.points + 1] = {
        id = Util.Id('p'),
        kind = kind,
        label = LABELS[kind] or kind,
        coords = { x = result.x, y = result.y, z = result.z },
        heading = result.h,
        radius = result.radius,
    }

    touch()
end

function Builder.Move(id)
    if not Builder.draft then return end

    local found
    for _, point in ipairs(Builder.draft.points) do
        if point.id == id then found = point break end
    end

    if not found then return end

    SetNuiFocus(false, false)
    XSM.Send('close')

    local result = Placement.Start({
        mode = (found.kind == 'tuning' or found.kind == 'repair') and 'zone' or 'point',
        label = LABELS[found.kind] or found.kind,
        colour = Zones.Colour[found.kind],
        radius = found.radius or 2.5,
        origin = { x = found.coords.x, y = found.coords.y, z = found.coords.z, h = found.heading },
    })

    SetNuiFocus(true, true)
    XSM.Send('open', { mode = 'builder', state = XSM.state, panel = 'builder' })

    if not result then push() return end

    found.coords = { x = result.x, y = result.y, z = result.z }
    found.heading = result.h
    found.radius = result.radius

    touch()
end

function Builder.Drop(id)
    if not Builder.draft then return end

    for i, point in ipairs(Builder.draft.points) do
        if point.id == id then
            table.remove(Builder.draft.points, i)
            touch()
            return
        end
    end
end

function Builder.Save()
    if not Builder.draft then return end

    if Builder.draft.kind == 'owned' and Builder.draft.job == '' then
        XSM.Toast('An owned shop needs a job name.', 'error')
        return
    end

    if #(Builder.draft.points or {}) == 0 then
        XSM.Toast('Place at least one point before saving.', 'error')
        return
    end

    Builder.draft.bounds = bounds(Builder.draft)

    local result = lib.callback.await('XS-Mechanic:saveShop', false, { shop = Builder.draft })

    if not result or not result.ok then
        XSM.Toast(result and result.error or 'Could not save that.', 'error')
        return
    end

    Builder.draft.id = result.id
    Builder.dirty = false

    XSM.Toast('Saved.', 'good')
    XSM.Refresh()
    push()
end

function Builder.Toggle()
    if not Builder.draft or not Builder.draft.id then
        XSM.Toast('Save the shop first.', 'error')
        return
    end

    local result = lib.callback.await('XS-Mechanic:toggleShop', false, { id = Builder.draft.id })
    if not result or not result.ok then return end

    Builder.draft.enabled = result.enabled
    XSM.Toast(result.enabled and 'Switched on.' or 'Switched off.', 'good')
    XSM.Refresh()
    push()
end

function Builder.Delete()
    if not Builder.draft or not Builder.draft.id then return end

    local result = lib.callback.await('XS-Mechanic:deleteShop', false, { id = Builder.draft.id })
    if not result or not result.ok then
        XSM.Toast(result and result.error or 'Could not delete that.', 'error')
        return
    end

    Builder.draft = nil
    clearPreview()
    XSM.Toast('Deleted.', 'good')
    XSM.Refresh()
    push()
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearPreview()
end)
