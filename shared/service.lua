Service = {}

--[[ Parts wear as the vehicle gains mileage, and worn parts make it drive
     worse until a mechanic replaces them.

     lifespanKm  distance for that part to go 100% -> 0%
     item        what a mechanic consumes to replace it
     affects     which handling field the wear degrades
     strength    how much of that field is lost at 0% (0.3 = 30% worse)
     restricted  'combustion', 'electric' or nil

     Wear is stored per plate, so it survives a restart and follows the car
     through any garage. Replacing a part puts it back to 100%. ]]

Service.Parts = {
    {
        id = 'engine_oil', label = 'Engine Oil',
        lifespanKm = 400, item = 'engine_oil', quantity = 1,
        restricted = 'combustion',
        affects = 'accel', strength = 0.22,
    },
    {
        id = 'air_filter', label = 'Air Filter',
        lifespanKm = 650, item = 'air_filter', quantity = 1,
        restricted = 'combustion',
        affects = 'topSpeed', strength = 0.14,
    },
    {
        id = 'spark_plugs', label = 'Spark Plugs',
        lifespanKm = 800, item = 'spark_plugs', quantity = 4,
        restricted = 'combustion',
        affects = 'accel', strength = 0.18,
    },
    {
        id = 'clutch', label = 'Clutch',
        lifespanKm = 1200, item = 'clutch', quantity = 1,
        restricted = 'combustion',
        affects = 'gearTime', strength = 0.35,
    },
    {
        id = 'brake_pads', label = 'Brake Pads',
        lifespanKm = 700, item = 'brake_pads', quantity = 2,
        affects = 'brake', strength = 0.30,
    },
    {
        id = 'tyres', label = 'Tyres',
        lifespanKm = 900, item = 'tyres', quantity = 4,
        affects = 'traction', strength = 0.25,
    },
    {
        id = 'suspension', label = 'Suspension',
        lifespanKm = 1600, item = 'suspension_kit', quantity = 1,
        affects = 'suspension', strength = 0.20,
    },
    {
        id = 'ev_battery', label = 'EV Battery',
        lifespanKm = 2000, item = 'ev_battery', quantity = 1,
        restricted = 'electric',
        affects = 'accel', strength = 0.25,
    },
    {
        id = 'ev_coolant', label = 'EV Coolant',
        lifespanKm = 900, item = 'ev_coolant', quantity = 1,
        restricted = 'electric',
        affects = 'topSpeed', strength = 0.16,
    },
}

Service.ById = {}

for _, part in ipairs(Service.Parts) do
    Service.ById[part.id] = part
end

function Service.For(electric)
    local out = {}

    for _, part in ipairs(Service.Parts) do
        if part.restricted == nil
            or (part.restricted == 'electric' and electric)
            or (part.restricted == 'combustion' and not electric)
        then
            out[#out + 1] = part
        end
    end

    return out
end

-- A wear table that has never been written reads as full, so an old vehicle
-- that predates servicing does not arrive with everything at zero.
function Service.Wear(stored, part)
    local value = stored and stored[part.id]
    if type(value) ~= 'number' then return 100 end
    return math.max(0, math.min(100, value))
end

function Service.Due(stored, electric, threshold)
    threshold = threshold or 20
    local due = {}

    for _, part in ipairs(Service.For(electric)) do
        if Service.Wear(stored, part) <= threshold then
            due[#due + 1] = part.id
        end
    end

    return due
end

-- 1.0 is a healthy part. At zero wear the field is down by `strength`.
function Service.Multiplier(stored, electric, field)
    local multiplier = 1.0

    for _, part in ipairs(Service.For(electric)) do
        if part.affects == field then
            local wear = Service.Wear(stored, part) / 100
            multiplier = multiplier * (1.0 - (1.0 - wear) * (part.strength or 0))
        end
    end

    return multiplier
end

function Service.Advance(stored, electric, km)
    stored = stored or {}

    for _, part in ipairs(Service.For(electric)) do
        local wear = Service.Wear(stored, part)
        local lost = (km / (part.lifespanKm or 500)) * 100
        stored[part.id] = math.max(0, wear - lost)
    end

    return stored
end
