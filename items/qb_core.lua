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
    type = 'item', image = 'tyre_kit.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'A set of tyres and the tools to fit them.',
},

['performance_part'] = {
    name = 'performance_part', label = 'Performance Part', weight = 2500,
    type = 'item', image = 'performance_part.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Whatever the tuning menu asked for.',
},

-- Phase 2: servicing parts, custom tuning parts, and the two pocket items.

['engine_oil'] = {
    name = 'engine_oil', label = 'Engine Oil', weight = 1200,
    type = 'item', image = 'engine_oil.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'Five litres and a funnel.',
},

['air_filter'] = {
    name = 'air_filter', label = 'Air Filter', weight = 400,
    type = 'item', image = 'air_filter.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'Cheap, and nobody changes it often enough.',
},

['spark_plugs'] = {
    name = 'spark_plugs', label = 'Spark Plugs', weight = 200,
    type = 'item', image = 'spark_plugs.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'Sold in fours for a reason.',
},

['clutch'] = {
    name = 'clutch', label = 'Clutch', weight = 6000,
    type = 'item', image = 'clutch.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'A long afternoon.',
},

['brake_pads'] = {
    name = 'brake_pads', label = 'Brake Pads', weight = 1500,
    type = 'item', image = 'brake_pads.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'The bit that wears out first.',
},

['tyres'] = {
    name = 'tyres', label = 'Tyres', weight = 7000,
    type = 'item', image = 'tyres.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'Rubber, round, four of them.',
},

['suspension_kit'] = {
    name = 'suspension_kit', label = 'Suspension Kit', weight = 8000,
    type = 'item', image = 'suspension_kit.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'Springs, dampers and top mounts.',
},

['ev_battery'] = {
    name = 'ev_battery', label = 'EV Battery', weight = 12000,
    type = 'item', image = 'ev_battery.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'Heavy, expensive, and not to be dropped.',
},

['ev_coolant'] = {
    name = 'ev_coolant', label = 'EV Coolant', weight = 1000,
    type = 'item', image = 'ev_coolant.png', unique = false, useable = false,
    shouldClose = true, combinable = nil,
    description = 'Keeps the pack from cooking itself.',
},

['i4_engine'] = {
    name = 'i4_engine', label = 'I4 Engine', weight = 40000,
    type = 'item', image = 'i4_engine.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Small and revvy.',
},

['v6_engine'] = {
    name = 'v6_engine', label = 'V6 Engine', weight = 55000,
    type = 'item', image = 'v6_engine.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'The sensible one.',
},

['v8_engine'] = {
    name = 'v8_engine', label = 'V8 Engine', weight = 70000,
    type = 'item', image = 'v8_engine.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Torque everywhere.',
},

['v12_engine'] = {
    name = 'v12_engine', label = 'V12 Engine', weight = 85000,
    type = 'item', image = 'v12_engine.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Not for a hatchback.',
},

['electric_motor'] = {
    name = 'electric_motor', label = 'Electric Motor', weight = 60000,
    type = 'item', image = 'electric_motor.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Instant, and quiet about it.',
},

['turbo_kit'] = {
    name = 'turbo_kit', label = 'Turbo Kit', weight = 9000,
    type = 'item', image = 'turbo_kit.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Snail, pipework, wastegate.',
},

['drivetrain_kit'] = {
    name = 'drivetrain_kit', label = 'Drivetrain Kit', weight = 15000,
    type = 'item', image = 'drivetrain_kit.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Changes which wheels do the work.',
},

['gearbox_kit'] = {
    name = 'gearbox_kit', label = 'Gearbox', weight = 25000,
    type = 'item', image = 'gearbox_kit.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Ratios you actually chose.',
},

['brake_kit'] = {
    name = 'brake_kit', label = 'Brake Kit', weight = 6000,
    type = 'item', image = 'brake_kit.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Discs, calipers, braided lines.',
},

['drift_kit'] = {
    name = 'drift_kit', label = 'Drift Kit', weight = 7000,
    type = 'item', image = 'drift_kit.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Loose on purpose.',
},

['nitrous'] = {
    name = 'nitrous', label = 'Nitrous Bottle', weight = 5000,
    type = 'item', image = 'nitrous.png', unique = false, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Arms the bottle. Hold the boost key once it is armed.',
},

['lighting_remote'] = {
    name = 'lighting_remote', label = 'Lighting Remote', weight = 300,
    type = 'item', image = 'lighting_remote.png', unique = true, useable = true,
    shouldClose = true, combinable = nil,
    description = 'Xenons and underglow, with the effects that make a meet worth turning up to.',
},

-- Parts the bench makes, and the work each one is used up by. A shop that
-- runs out of body panels cannot fit one until somebody makes another.

['body_part'] = {
    name = 'body_part', label = 'Body Part', weight = 2500,
    type = 'item', image = 'body_part.png', unique = false, useable = true,
    shouldClose = false, combinable = nil,
    description = 'A panel, a bumper, a skirt. Whatever the car is missing.',
},

['wheel_set'] = {
    name = 'wheel_set', label = 'Wheel Set', weight = 6000,
    type = 'item', image = 'wheel_set.png', unique = false, useable = true,
    shouldClose = false, combinable = nil,
    description = 'Four of them, boxed.',
},

['paint_can'] = {
    name = 'paint_can', label = 'Paint Can', weight = 1200,
    type = 'item', image = 'paint_can.png', unique = false, useable = true,
    shouldClose = false, combinable = nil,
    description = 'Mixed to whatever the customer picks.',
},

['vinyl_wrap'] = {
    name = 'vinyl_wrap', label = 'Vinyl Wrap', weight = 900,
    type = 'item', image = 'vinyl_wrap.png', unique = false, useable = true,
    shouldClose = false, combinable = nil,
    description = 'A roll of it. Bubbles are the fitter, not the vinyl.',
},

['light_kit'] = {
    name = 'light_kit', label = 'Light Kit', weight = 1100,
    type = 'item', image = 'light_kit.png', unique = false, useable = true,
    shouldClose = false, combinable = nil,
    description = 'Housings, bulbs and the loom to run them.',
},

['interior_part'] = {
    name = 'interior_part', label = 'Interior Part', weight = 1400,
    type = 'item', image = 'interior_part.png', unique = false, useable = true,
    shouldClose = false, combinable = nil,
    description = 'Trim, dials, a wheel. The bits you actually touch.',
},

['plate_blank'] = {
    name = 'plate_blank', label = 'Plate Blank', weight = 300,
    type = 'item', image = 'plate_blank.png', unique = false, useable = true,
    shouldClose = false, combinable = nil,
    description = 'Pressed, unprinted, entirely legal until it is not.',
},

-- The modkit upgrades. One part per slot, so a shop stocks engine work and
-- brake work apart and the bench makes them apart.

['armour_plate'] = {
    name = 'armour_plate', label = 'Armour Plate', weight = 9000,
    type = 'item', image = 'armour_plate.png', unique = false, useable = true,
    shouldClose = false, combinable = nil,
    description = 'Ballistic plate, cut to the shell and heavy with it.',
},

['suspension_parts'] = {
    name = 'suspension_parts', label = 'Suspension Parts', weight = 3600,
    type = 'item', image = 'suspension_parts.png', unique = false, useable = true,
    shouldClose = false, combinable = nil,
    description = 'Coilovers, bushes and drop links.',
},
