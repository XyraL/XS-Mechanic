Zones = {}

local registered = {}
local props = {}
local blips = {}

local KIND_COLOUR = {
    tuning  = { 255, 166, 41 },
    repair  = { 77, 159, 255 },
    counter = { 55, 211, 153 },
    storage = { 169, 139, 255 },
    laptop  = { 255, 196, 107 },
    bench   = { 255, 213, 79 },
    duty    = { 47, 224, 189 },
    dyno    = { 109, 224, 255 },
}

Zones.Colour = KIND_COLOUR

-- Is this spot inside the shop? A shop with no boundary drawn answers yes to
-- everywhere, which is how every shop built before boundaries existed behaves.
function Zones.InShop(shop, coords)
    if not shop then return false end
    if not Util.HasArea(shop.area) then return true end

    return Util.InsideArea(coords, shop.area)
end

function Zones.ShopAt(coords)
    for _, shop in ipairs(XSM.shops or {}) do
        if Util.HasArea(shop.area) and Util.InsideArea(coords, shop.area) then
            return shop
        end
    end

    return nil
end

-- Whether a spot is stood on one of the shop's points of a given kind. The
-- dyno uses it: a dyno run belongs on a dyno bay, not wherever you happen to
-- have parked.
function Zones.OnPoint(shop, kind, coords)
    for _, point in ipairs(shop and shop.points or {}) do
        if point.kind == kind then
            local distance = #(coords - vector3(point.coords.x, point.coords.y, point.coords.z))
            if distance <= (point.radius or 3.0) then return point end
        end
    end

    return nil
end

local function jobMatches(shop)
    if shop.kind ~= 'owned' then return true end

    local job, onDuty = Framework.GetJob()
    if job ~= shop.job then return false end
    if Config.Jobs.requireDuty and not onDuty then return false end

    return true
end

Zones.JobMatches = jobMatches

-- A self-service shop is open to anyone. An owned shop is staff only, unless
-- the owner allowed it to fall back when nobody is working.
local function canUseBay(shop)
    if shop.kind ~= 'owned' then return true end
    if jobMatches(shop) then return true end
    return shop.selfServiceWhenEmpty ~= false and (shop.staffOnline or 0) == 0
end

Zones.CanUseBay = canUseBay

local function clearProps()
    for _, entity in pairs(props) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
    props = {}
end

local function clearBlips()
    for _, blip in pairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    blips = {}
end

local function spawnLaptop(shop, point)
    if not Config.Desk.spawnProp then return end

    local model = joaat(Config.Desk.prop)
    if not IsModelInCdimage(model) then return end

    lib.requestModel(model, 8000)

    local entity = CreateObject(model, point.coords.x, point.coords.y, point.coords.z, false, false, false)
    SetEntityHeading(entity, point.heading or 0.0)
    FreezeEntityPosition(entity, true)
    SetEntityAsMissionEntity(entity, true, true)
    SetModelAsNoLongerNeeded(model)

    props[point.id] = entity

    Target.AddEntity(('xsmech_laptop_%s'):format(point.id), entity, {
        {
            id = 'open',
            label = 'Use the laptop',
            icon = 'fa-solid fa-laptop',
            distance = Config.Desk.useDistance,
            canInteract = function() return jobMatches(shop) end,
            action = function() XSM.Open('desk', shop.id) end,
        },
    })
end

local function optionsFor(shop, point)
    if point.kind == 'tuning' then
        return { {
            id = 'tune',
            label = 'Work on a vehicle',
            icon = 'fa-solid fa-screwdriver-wrench',
            canInteract = function() return canUseBay(shop) end,
            action = function()
                if jobMatches(shop) then XSM.Open('tablet', shop.id) else XSM.Open('bay', shop.id) end
            end,
        } }
    end

    if point.kind == 'repair' then
        return { {
            id = 'repair',
            label = 'Repair a vehicle',
            icon = 'fa-solid fa-wrench',
            canInteract = function() return canUseBay(shop) end,
            action = function() Repair.AtBay(shop, point) end,
        } }
    end

    if point.kind == 'counter' then
        return { {
            id = 'parts',
            label = 'Parts counter',
            icon = 'fa-solid fa-boxes-stacked',
            canInteract = function() return jobMatches(shop) end,
            action = function() XSM.Open('counter', shop.id) end,
        } }
    end

    if point.kind == 'storage' then
        return { {
            id = 'stash',
            label = 'Storage',
            icon = 'fa-solid fa-warehouse',
            canInteract = function() return jobMatches(shop) end,
            action = function()
                Inventory.OpenStash(('xsmech_%s_%s'):format(shop.id, point.id), shop.name .. ' storage', 60, 200000)
            end,
        } }
    end

    if point.kind == 'dyno' then
        return { {
            id = 'dyno',
            label = 'Use the dyno',
            icon = 'fa-solid fa-gauge-high',
            canInteract = function() return jobMatches(shop) end,
            action = function() XSM.Open('tablet', shop.id) end,
        } }
    end

    if point.kind == 'bench' then
        if not Config.Crafting.enabled then return {} end

        return { {
            id = 'craft',
            label = 'Crafting bench',
            icon = 'fa-solid fa-hammer',
            distance = Config.Crafting.useDistance,
            canInteract = function() return jobMatches(shop) end,
            action = function() Craft.Open(shop, point) end,
        } }
    end

    if point.kind == 'duty' then
        return { {
            id = 'duty',
            label = 'Clock on or off',
            icon = 'fa-solid fa-user-clock',
            canInteract = function()
                local job = Framework.GetJob()
                return job == shop.job
            end,
            action = function() TriggerServerEvent('XS-Mechanic:server:duty', shop.id) end,
        } }
    end

    return {}
end

function Zones.Rebuild()
    Target.Clear()
    clearProps()
    clearBlips()
    registered = {}

    for _, shop in ipairs(XSM.shops or {}) do
        if shop.blip and shop.blip.enabled and shop.bounds then
            local blip = AddBlipForCoord(shop.bounds.x, shop.bounds.y, shop.bounds.z)
            SetBlipSprite(blip, shop.blip.sprite or 446)
            SetBlipColour(blip, shop.blip.colour or 47)
            SetBlipScale(blip, shop.blip.scale or 0.7)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(shop.name)
            EndTextCommandSetBlipName(blip)
            blips[shop.id] = blip
        end

        for _, point in ipairs(shop.points or {}) do
            if point.kind == 'laptop' then
                spawnLaptop(shop, point)
            else
                local options = optionsFor(shop, point)

                if #options > 0 then
                    local id = ('xsmech_%s_%s'):format(shop.id, point.id)

                    Target.AddSphere(id, point.coords, point.radius or 2.5, options)
                    registered[id] = { shop = shop, point = point, options = options }
                end
            end
        end
    end
end

-- Marker-and-key fallback for servers with no target resource. Only the points
-- the target bridge could not take are drawn here.
CreateThread(function()
    while true do
        local wait = 800
        local fallbacks = Target.Fallbacks()

        if next(fallbacks) then
            local coords = GetEntityCoords(cache.ped)
            local nearest, nearestDist

            for id, zone in pairs(fallbacks) do
                if zone.coords then
                    local dist = #(coords - vector3(zone.coords.x, zone.coords.y, zone.coords.z))

                    if dist < 18.0 then
                        wait = 0
                        local entry = registered[id]
                        local colour = entry and KIND_COLOUR[entry.point.kind] or { 255, 166, 41 }

                        DrawMarker(21, zone.coords.x, zone.coords.y, zone.coords.z + 0.9,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.35, 0.35,
                            colour[1], colour[2], colour[3], 140, true, false, 2, false)

                        if dist < (zone.radius or 2.5) and (not nearestDist or dist < nearestDist) then
                            nearest, nearestDist = id, dist
                        end
                    end
                end
            end

            if nearest then
                local entry = registered[nearest]
                local option = entry and entry.options[1]

                if option and (not option.canInteract or option.canInteract()) then
                    lib.showTextUI(('[E] %s'):format(option.label), { position = 'left-center' })

                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        option.action()
                    end
                else
                    lib.hideTextUI()
                end
            else
                lib.hideTextUI()
            end
        end

        Wait(wait)
    end
end)

-- Config.Debug draws every shop's boundary on the ground. Drawing a shape you
-- cannot see is how a boundary ends up two metres short of the door.
CreateThread(function()
    while true do
        local wait = 1000

        if Config.Debug then
            local coords = GetEntityCoords(cache.ped)

            for _, shop in ipairs(XSM.shops or {}) do
                local area = shop.area

                if Util.HasArea(area) then
                    local centre = Util.AreaCentre(area)

                    if centre and #(coords - vector3(centre.x, centre.y, centre.z)) < 120.0 then
                        wait = 0
                        local inside = Util.InsideArea(coords, area)
                        local r, g, b = 47, 224, 189
                        if not inside then r, g, b = 255, 166, 41 end

                        local corners = area.points

                        for index, corner in ipairs(corners) do
                            local next_ = corners[index + 1] or corners[1]

                            DrawLine(corner.x, corner.y, corner.z, next_.x, next_.y, next_.z, r, g, b, 200)
                            DrawLine(corner.x, corner.y, corner.z, corner.x, corner.y, corner.z + 3.0, r, g, b, 120)
                        end
                    end
                end
            end
        end

        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearProps()
    clearBlips()
end)
