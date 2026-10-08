Stations = {}

-- What a service station can be set to do, in the order the builder lists it.
Stations.OFFERS = { 'repair', 'wash', 'paint', 'parts', 'wheels', 'performance', 'stance' }

-- Which offer each kind of pick falls under.
local OFFER_FOR = {
    respray = 'paint',
    wheels = 'wheels',
    performance = 'performance',
    cosmetics = 'parts', lights = 'parts', interior = 'parts',
    livery = 'parts', extras = 'parts', plate = 'parts',
}

function Stations.OfferFor(category)
    return OFFER_FOR[category]
end

-- A station's settings, cleaned on the way into the database.
function Stations.Sanitise(draft)
    local jobs, seen = {}, {}

    for _, job in ipairs(type(draft.stationJobs) == 'table' and draft.stationJobs or {}) do
        job = Util.Trim(tostring(job or '')):sub(1, 64)

        if job ~= '' and not seen[job] and #jobs < 16 then
            seen[job] = true
            jobs[#jobs + 1] = job
        end
    end

    local offers = {}
    local given = type(draft.offers) == 'table' and draft.offers or {}

    for _, key in ipairs(Stations.OFFERS) do
        offers[key] = given[key] ~= false
    end

    draft.stationJobs = jobs
    draft.offers = offers
    draft.job = ''

    return #jobs > 0
end

function Stations.Allowed(src, shop)
    if not shop or shop.kind ~= 'station' or not shop.enabled then return false end

    local job = Framework.GetJob(src)

    for _, allowed in ipairs(shop.stationJobs or {}) do
        if allowed == job then return true end
    end

    return false
end

local function onStation(shop, coords)
    return Store.PointNear(shop, 'station', coords, 2.0) ~= nil
end

-- Everything a station does for free goes through here: the player holds one of
-- its jobs, the station does this kind of work, and the car is on its bay.
function Stations.Check(src, shop, offer, netId)
    if not Stations.Allowed(src, shop) then
        return false, 'This station is not for your job.'
    end

    if offer and not (shop.offers or {})[offer] then
        return false, 'This station does not do that.'
    end

    local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return false, 'No vehicle.'
    end

    if not onStation(shop, GetEntityCoords(vehicle)) then
        return false, 'Drive onto the service bay.'
    end

    return true
end

lib.callback.register('XS-Mechanic:stationCheck', function(src, data)
    data = data or {}

    local shop = Store.Get(data.shop)
    local ok, err = Stations.Check(src, shop, data.offer, data.netId)

    if not ok then return { ok = false, error = err } end

    -- Every pick on the list has to be something this station does.
    for _, pick in ipairs(type(data.picks) == 'table' and data.picks or {}) do
        local offer = Stations.OfferFor(pick and pick.category)

        if not offer or not shop.offers[offer] then
            return { ok = false, error = 'This station does not do that.' }
        end
    end

    return { ok = true }
end)
