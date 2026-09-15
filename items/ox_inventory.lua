-- Paste these into ox_inventory/data/items.lua.
--
-- ox_inventory ignores CreateUseableItem entirely — it only calls an export
-- named in its own item definition. Without the `client = { export = ... }`
-- lines below, using the tablet or a repair kit does nothing at all, silently,
-- and it looks like the script is broken.

['mechanic_tablet'] = {
    label = 'Mechanic Tablet',
    weight = 800,
    stack = false,
    close = true,
    description = 'Plugs into a vehicle and tells you everything it can take.',
    client = { export = 'XS-Mechanic.openTablet' },
},

['repair_kit'] = {
    label = 'Repair Kit',
    weight = 3000,
    stack = true,
    close = true,
    description = 'Enough to put an engine back together properly.',
    client = { export = 'XS-Mechanic.use_repair_kit' },
},

['advanced_repair_kit'] = {
    label = 'Advanced Repair Kit',
    weight = 4000,
    stack = true,
    close = true,
    description = 'The same job, done faster.',
    client = { export = 'XS-Mechanic.use_advanced_repair_kit' },
},

['duct_tape'] = {
    label = 'Duct Tape',
    weight = 200,
    stack = true,
    close = true,
    description = 'Gets you moving. Does not get you fixed.',
    client = { export = 'XS-Mechanic.use_duct_tape' },
},

['cleaning_kit'] = {
    label = 'Cleaning Kit',
    weight = 1000,
    stack = true,
    close = true,
    description = 'Bucket, sponge, and some pride.',
},

['tyre_kit'] = {
    label = 'Tyre Kit',
    weight = 5000,
    stack = true,
    close = true,
    description = 'A set of tyres and the tools to fit them.',
},

['performance_part'] = {
    label = 'Performance Part',
    weight = 2500,
    stack = true,
    close = true,
    description = 'Whatever the tuning menu asked for.',
},
