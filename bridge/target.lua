Target = { name = nil }

if IsDuplicityVersion() then return end

local function detect()
    local forced = Config.Bridges.target
    if forced ~= 'auto' then return forced ~= 'none' and forced or nil end

    if GetResourceState('ox_target') == 'started' then return 'ox_target' end
    if GetResourceState('qb-target') == 'started' then return 'qb-target' end

    return 'builtin'
end

Target.name = detect()

local zones = {}

-- Labels have to be static. A target resource caches the option list when the
-- zone is made, so anything that reads state at draw time ("Work on the Elegy")
-- shows whatever was true when the zone was registered and never updates.
function Target.AddSphere(id, coords, radius, options)
    if Target.name == 'ox_target' then
        local built = {}

        for _, option in ipairs(options) do
            built[#built + 1] = {
                name = ('%s:%s'):format(id, option.id),
                label = option.label,
                icon = option.icon,
                distance = option.distance or 2.0,
                canInteract = option.canInteract,
                onSelect = option.action,
            }
        end

        zones[id] = exports.ox_target:addSphereZone({
            coords = vec3(coords.x, coords.y, coords.z),
            radius = radius,
            debug = Config.Debug,
            options = built,
        })
        return
    end

    if Target.name == 'qb-target' then
        local built = {}

        for _, option in ipairs(options) do
            built[#built + 1] = {
                label = option.label,
                icon = option.icon,
                action = option.action,
                canInteract = option.canInteract,
            }
        end

        exports['qb-target']:AddCircleZone(id, vec3(coords.x, coords.y, coords.z), radius, {
            name = id, debugPoly = Config.Debug, useZ = true,
        }, { options = built, distance = 2.5 })

        zones[id] = id
        return
    end

    -- No target resource: the marker-and-key path in client/zones.lua covers
    -- it. Nothing to register.
    zones[id] = { fallback = true, coords = coords, radius = radius, options = options }
end

function Target.AddEntity(id, entity, options)
    if not entity or entity == 0 then return end

    if Target.name == 'ox_target' then
        local built = {}

        for _, option in ipairs(options) do
            built[#built + 1] = {
                name = ('%s:%s'):format(id, option.id),
                label = option.label,
                icon = option.icon,
                distance = option.distance or 2.0,
                canInteract = option.canInteract,
                onSelect = option.action,
            }
        end

        exports.ox_target:addLocalEntity(entity, built)
        zones[id] = { entity = entity }
        return
    end

    if Target.name == 'qb-target' then
        local built = {}

        for _, option in ipairs(options) do
            built[#built + 1] = {
                label = option.label, icon = option.icon,
                action = option.action, canInteract = option.canInteract,
            }
        end

        exports['qb-target']:AddTargetEntity(entity, { options = built, distance = 2.5 })
        zones[id] = { entity = entity }
        return
    end

    zones[id] = { fallback = true, entity = entity, options = options }
end

function Target.Remove(id)
    local zone = zones[id]
    if not zone then return end

    if Target.name == 'ox_target' then
        if type(zone) == 'table' and zone.entity then
            exports.ox_target:removeLocalEntity(zone.entity)
        elseif type(zone) ~= 'table' then
            exports.ox_target:removeZone(zone)
        end
    elseif Target.name == 'qb-target' then
        if type(zone) == 'table' and zone.entity then
            exports['qb-target']:RemoveTargetEntity(zone.entity)
        else
            exports['qb-target']:RemoveZone(id)
        end
    end

    zones[id] = nil
end

function Target.Fallbacks()
    local out = {}
    for id, zone in pairs(zones) do
        if type(zone) == 'table' and zone.fallback then out[id] = zone end
    end
    return out
end

function Target.Clear()
    for id in pairs(zones) do Target.Remove(id) end
    zones = {}
end
