-- Paste these into qb-core/shared/items.lua.
-- Item images go in your inventory's images folder, named to match.

['mechanic_tablet'] = {
    name = 'mechanic_tablet', label = 'Mechanic Tablet', weight = 800,
    type = 'item', image = 'mechanic_tablet.png', unique = true, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Plugs into a vehicle and tells you everything it can take.',
},

['repair_kit'] = {
    name = 'repair_kit', label = 'Repair Kit', weight = 3000,
    type = 'item', image = 'repair_kit.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Enough to put an engine back together properly.',
},

['advanced_repair_kit'] = {
    name = 'advanced_repair_kit', label = 'Advanced Repair Kit', weight = 4000,
    type = 'item', image = 'advanced_repair_kit.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'The same job, done faster.',
},

['duct_tape'] = {
    name = 'duct_tape', label = 'Duct Tape', weight = 200,
    type = 'item', image = 'duct_tape.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Gets you moving. Does not get you fixed.',
},

['cleaning_kit'] = {
    name = 'cleaning_kit', label = 'Cleaning Kit', weight = 1000,
    type = 'item', image = 'cleaning_kit.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'Bucket, sponge, and some pride.',
},

['tyre_kit'] = {
    name = 'tyre_kit', label = 'Tyre Kit', weight = 5000,
    type = 'item', image = 'tyre_kit.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'A set of tyres and the tools to fit them.',
},

['performance_part'] = {
    name = 'performance_part', label = 'Performance Part', weight = 2500,
    type = 'item', image = 'performance_part.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'Whatever the tuning menu asked for.',
},
