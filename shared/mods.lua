Mods = {}

Mods.Slots = {
    { slot = 0,  id = 'spoiler',       label = 'Spoiler',           category = 'cosmetics' },
    { slot = 1,  id = 'frontBumper',   label = 'Front Bumper',      category = 'cosmetics' },
    { slot = 2,  id = 'rearBumper',    label = 'Rear Bumper',       category = 'cosmetics' },
    { slot = 3,  id = 'sideSkirt',     label = 'Side Skirt',        category = 'cosmetics' },
    { slot = 4,  id = 'exhaust',       label = 'Exhaust',           category = 'cosmetics' },
    { slot = 5,  id = 'rollCage',      label = 'Roll Cage',         category = 'cosmetics' },
    { slot = 6,  id = 'grille',        label = 'Grille',            category = 'cosmetics' },
    { slot = 7,  id = 'hood',          label = 'Hood',              category = 'cosmetics' },
    { slot = 8,  id = 'fender',        label = 'Fender',            category = 'cosmetics' },
    { slot = 9,  id = 'rightFender',   label = 'Right Fender',      category = 'cosmetics' },
    { slot = 10, id = 'roof',          label = 'Roof',              category = 'cosmetics' },

    { slot = 11, id = 'engine',        label = 'Engine',            category = 'performance', levels = true },
    { slot = 12, id = 'brakes',        label = 'Brakes',            category = 'performance', levels = true },
    { slot = 13, id = 'transmission',  label = 'Transmission',      category = 'performance', levels = true },
    { slot = 15, id = 'suspension',    label = 'Suspension',        category = 'performance', levels = true },
    { slot = 16, id = 'armour',        label = 'Armour',            category = 'performance', levels = true },
    { slot = 18, id = 'turbo',         label = 'Turbo',             category = 'performance', toggle = true },

    { slot = 14, id = 'horn',          label = 'Horn',              category = 'extras', flatPrice = true },
    { slot = 20, id = 'tyreSmoke',     label = 'Tyre Smoke',        category = 'extras', toggle = true },
    { slot = 22, id = 'xenon',         label = 'Headlights',        category = 'lights', toggle = true },

    { slot = 23, id = 'frontWheels',   label = 'Wheels',            category = 'wheels' },
    { slot = 24, id = 'backWheels',    label = 'Back Wheels',       category = 'wheels', bikesOnly = true },

    { slot = 25, id = 'plateHolder',   label = 'Plate Holder',      category = 'interior' },
    { slot = 27, id = 'trimDesign',    label = 'Trim Design',       category = 'interior' },
    { slot = 28, id = 'ornaments',     label = 'Ornaments',         category = 'interior' },
    { slot = 29, id = 'dashboard',     label = 'Dashboard',         category = 'interior' },
    { slot = 30, id = 'dial',          label = 'Dials',             category = 'interior' },
    { slot = 31, id = 'doorSpeaker',   label = 'Door Speakers',     category = 'interior' },
    { slot = 32, id = 'seats',         label = 'Seats',             category = 'interior' },
    { slot = 33, id = 'steeringWheel', label = 'Steering Wheel',    category = 'interior' },
    { slot = 34, id = 'shifter',       label = 'Shifter',           category = 'interior' },
    { slot = 35, id = 'plaques',       label = 'Plaques',           category = 'interior' },
    { slot = 36, id = 'speakers',      label = 'Speakers',          category = 'interior' },
    { slot = 37, id = 'trunk',         label = 'Trunk',             category = 'interior' },
    { slot = 38, id = 'hydraulics',    label = 'Hydraulics',        category = 'cosmetics' },
    { slot = 39, id = 'engineBlock',   label = 'Engine Block',      category = 'cosmetics' },
    { slot = 40, id = 'airFilter',     label = 'Air Filter',        category = 'cosmetics' },
    { slot = 41, id = 'struts',        label = 'Struts',            category = 'cosmetics' },
    { slot = 42, id = 'archCover',     label = 'Arch Cover',        category = 'cosmetics' },
    { slot = 43, id = 'aerials',       label = 'Aerials',           category = 'cosmetics' },
    { slot = 44, id = 'trim',          label = 'Trim',              category = 'cosmetics' },
    { slot = 45, id = 'tank',          label = 'Tank',              category = 'cosmetics' },
    { slot = 46, id = 'windows',       label = 'Windows',           category = 'cosmetics' },
    { slot = 48, id = 'livery',        label = 'Livery',            category = 'livery' },
}

Mods.BySlot = {}
Mods.ById = {}

for _, entry in ipairs(Mods.Slots) do
    Mods.BySlot[entry.slot] = entry
    Mods.ById[entry.id] = entry
end

-- Categories a shop can switch on or off, and a bay can be limited to. Order
-- here is the order they appear in the panel.
Mods.Categories = {
    { id = 'cosmetics',   label = 'Cosmetics' },
    { id = 'wheels',      label = 'Wheels' },
    { id = 'performance', label = 'Performance' },
    { id = 'respray',     label = 'Respray' },
    { id = 'lights',      label = 'Lights' },
    { id = 'interior',    label = 'Interior' },
    { id = 'livery',      label = 'Livery' },
    { id = 'extras',      label = 'Extras' },
    { id = 'plate',       label = 'Plates' },
    { id = 'stance',      label = 'Stance' },
    { id = 'tuning',      label = 'Tuning' },
    { id = 'repair',      label = 'Repair' },
    { id = 'service',     label = 'Service' },
}

Mods.CategoryLabel = {}

for _, entry in ipairs(Mods.Categories) do
    Mods.CategoryLabel[entry.id] = entry.label
end

-- The ten stock wheel types, plus the two that only some models carry. A model
-- is asked which ones it actually has rather than being assumed to have all.
Mods.WheelTypes = {
    { id = 0,  label = 'Sport' },
    { id = 1,  label = 'Muscle' },
    { id = 2,  label = 'Lowrider' },
    { id = 3,  label = 'SUV' },
    { id = 4,  label = 'Offroad' },
    { id = 5,  label = 'Tuner' },
    { id = 6,  label = 'Bike' },
    { id = 7,  label = 'High End' },
    { id = 8,  label = 'Benny\'s Original' },
    { id = 9,  label = 'Benny\'s Bespoke' },
    { id = 10, label = 'Open Wheel' },
    { id = 11, label = 'Street' },
    { id = 12, label = 'Track' },
}

Mods.NeonSides = {
    { id = 0, label = 'Left' },
    { id = 1, label = 'Right' },
    { id = 2, label = 'Front' },
    { id = 3, label = 'Back' },
}

-- Window tints are a fixed game list; unlike a mod slot there is nothing to ask
-- the model for.
Mods.WindowTints = {
    { id = 0, label = 'None' },
    { id = 1, label = 'Pure Black' },
    { id = 2, label = 'Darksmoke' },
    { id = 3, label = 'Lightsmoke' },
    { id = 4, label = 'Limo' },
    { id = 5, label = 'Green' },
}

Mods.XenonColours = {
    { id = -1, label = 'Stock' },       { id = 0,  label = 'White' },
    { id = 1,  label = 'Blue' },        { id = 2,  label = 'Electric Blue' },
    { id = 3,  label = 'Mint Green' },  { id = 4,  label = 'Lime Green' },
    { id = 5,  label = 'Yellow' },      { id = 6,  label = 'Golden Shower' },
    { id = 7,  label = 'Orange' },      { id = 8,  label = 'Red' },
    { id = 9,  label = 'Pony Pink' },   { id = 10, label = 'Hot Pink' },
    { id = 11, label = 'Purple' },      { id = 12, label = 'Blacklight' },
}

function Mods.IsPerformance(slot)
    local entry = Mods.BySlot[slot]
    return entry ~= nil and entry.category == 'performance'
end

function Mods.Category(slot)
    local entry = Mods.BySlot[slot]
    return entry and entry.category or 'cosmetics'
end

-- A slot the owner has switched off in config never reaches the panel, whatever
-- the vehicle carries.
function Mods.SlotBlocked(slot, model)
    local blocked = Config.Tuning and Config.Tuning.blockedSlots
    if blocked then
        for _, id in ipairs(blocked) do
            local entry = Mods.ById[id]
            if (entry and entry.slot == slot) or id == slot then return true end
        end
    end

    local perModel = Config.Tuning and Config.Tuning.blockedByModel
    if perModel and model then
        local list = perModel[string.lower(model)]
        if list then
            for _, id in ipairs(list) do
                local entry = Mods.ById[id]
                if (entry and entry.slot == slot) or id == slot then return true end
            end
        end
    end

    return false
end
