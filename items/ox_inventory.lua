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

-- Phase 2: servicing parts, custom tuning parts, and the two pocket items.

['engine_oil'] = {
    label = 'Engine Oil',
    weight = 1200,
    stack = true,
    close = true,
    description = 'Five litres and a funnel.',
},

['air_filter'] = {
    label = 'Air Filter',
    weight = 400,
    stack = true,
    close = true,
    description = 'Cheap, and nobody changes it often enough.',
},

['spark_plugs'] = {
    label = 'Spark Plugs',
    weight = 200,
    stack = true,
    close = true,
    description = 'Sold in fours for a reason.',
},

['clutch'] = {
    label = 'Clutch',
    weight = 6000,
    stack = true,
    close = true,
    description = 'A long afternoon.',
},

['brake_pads'] = {
    label = 'Brake Pads',
    weight = 1500,
    stack = true,
    close = true,
    description = 'The bit that wears out first.',
},

['tyres'] = {
    label = 'Tyres',
    weight = 7000,
    stack = true,
    close = true,
    description = 'Rubber, round, four of them.',
},

['suspension_kit'] = {
    label = 'Suspension Kit',
    weight = 8000,
    stack = true,
    close = true,
    description = 'Springs, dampers and top mounts.',
},

['ev_battery'] = {
    label = 'EV Battery',
    weight = 12000,
    stack = true,
    close = true,
    description = 'Heavy, expensive, and not to be dropped.',
},

['ev_coolant'] = {
    label = 'EV Coolant',
    weight = 1000,
    stack = true,
    close = true,
    description = 'Keeps the pack from cooking itself.',
},

['i4_engine'] = {
    label = 'I4 Engine',
    weight = 40000,
    stack = true,
    close = true,
    description = 'Small and revvy.',
},

['v6_engine'] = {
    label = 'V6 Engine',
    weight = 55000,
    stack = true,
    close = true,
    description = 'The sensible one.',
},

['v8_engine'] = {
    label = 'V8 Engine',
    weight = 70000,
    stack = true,
    close = true,
    description = 'Torque everywhere.',
},

['v12_engine'] = {
    label = 'V12 Engine',
    weight = 85000,
    stack = true,
    close = true,
    description = 'Not for a hatchback.',
},

['electric_motor'] = {
    label = 'Electric Motor',
    weight = 60000,
    stack = true,
    close = true,
    description = 'Instant, and quiet about it.',
},

['turbo_kit'] = {
    label = 'Turbo Kit',
    weight = 9000,
    stack = true,
    close = true,
    description = 'Snail, pipework, wastegate.',
},

['drivetrain_kit'] = {
    label = 'Drivetrain Kit',
    weight = 15000,
    stack = true,
    close = true,
    description = 'Changes which wheels do the work.',
},

['gearbox_kit'] = {
    label = 'Gearbox',
    weight = 25000,
    stack = true,
    close = true,
    description = 'Ratios you actually chose.',
},

['brake_kit'] = {
    label = 'Brake Kit',
    weight = 6000,
    stack = true,
    close = true,
    description = 'Discs, calipers, braided lines.',
},

['drift_kit'] = {
    label = 'Drift Kit',
    weight = 7000,
    stack = true,
    close = true,
    description = 'Loose on purpose.',
},

['nitrous'] = {
    label = 'Nitrous Bottle',
    weight = 5000,
    stack = true,
    close = true,
    description = 'Arms the bottle. Hold the boost key once it is armed.',
    client = { export = 'XS-Mechanic.use_nitrous' },
},

['lighting_remote'] = {
    label = 'Lighting Remote',
    weight = 300,
    stack = false,
    close = true,
    description = 'Xenons and underglow, with the effects that make a meet worth turning up to.',
    client = { export = 'XS-Mechanic.use_lighting_remote' },
},
