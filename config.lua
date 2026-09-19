Config = {}

-- Force a bridge instead of auto-detecting. 'auto' is almost always right.
Config.Bridges = {
    framework = 'auto',   -- auto | qbox | qbcore
    inventory = 'auto',   -- auto | ox_inventory | qb-inventory | qs-inventory | codem-inventory | core_inventory | ps-inventory
    target    = 'auto',   -- auto | ox_target | qb-target | builtin
    banking   = 'auto',   -- auto | qb-banking | Renewed-Banking | okokBanking | qbx | none
    phone     = 'auto',   -- auto | lb-phone | qs-smartphone | XS-Phone | qb-phone | none
}

-- No coordinates live in this file. Every shop, bay, parts counter and
-- storage point is placed in-game with /mechanic and stored in the database.
-- This file is the rules those places play by.
--
-- The resource ships empty. Nothing works until you build a shop.

Config.Debug = false

-- ── Who can build ────────────────────────────────────────────────────────────
-- Any one of these passing is enough.
Config.Admin = {
    acePermission = 'xs.mechanic',
    groups        = { 'admin', 'god' },
    licenses      = {},
}

Config.Builder = {
    command = 'mechanic',

    -- Metres. How far from yourself you can place a point.
    placementRange = 60.0,

    -- Snap a placed point down to ground height. Off is right almost always:
    -- the placement ray already lands on the surface you are looking at, and
    -- ground height ignores interior floors, so snapping inside a workshop
    -- drops the point through the floor. G toggles it while placing.
    snapToGround = false,

    -- Nudge step in metres when adjusting a placed point with the arrow keys.
    nudgeStep = 0.05,

    -- Placement camera speed in metres per second, at normal / shift / alt.
    cameraSpeed = { normal = 8.0, fast = 24.0, slow = 0.8 },

    limits = {
        bays    = 8,
        shops   = 4,
        storage = 4,
        benches = 2,
        duty    = 2,
        dynos   = 2,
    },
}

-- ── Ownership ────────────────────────────────────────────────────────────────
-- A shop is owned by a JOB, not by a player record in this resource. You build
-- the shop over someone's interior, point it at a job, and give them that job.
-- Several shops means several jobs, and each one is sealed off from the others:
-- its own staff, prices, parts list, storage, invoices and money.
--
-- Creating the job itself is your framework's business, not this resource's.
-- The builder warns you when a shop names a job your framework does not have.
Config.Jobs = {
    -- A shop's boss grade is set per shop in the builder. This is only what a
    -- newly created shop starts with.
    defaultBossGrade = 3,

    -- Respect on/off duty. With this off, holding the job is enough.
    requireDuty = false,

    -- Let a boss hire, fire and promote from the tablet's Team app. Turn it off
    -- if you already run a boss menu and want that to be the only way.
    manageFromTablet = true,

    -- Grade needed to change what this shop charges — the category prices, the
    -- performance list and what the parts counter sells. Each shop can raise or
    -- lower it in the builder. 0 lets everybody price work.
    priceGrade = 2,
}

-- ── The tablet ───────────────────────────────────────────────────────────────
-- How a mechanic opens the interface. The item is the default because it keeps
-- the tablet something you can take away; a command suits servers that would
-- rather not manage another item.
Config.Tablet = {
    item = 'mechanic_tablet',

    -- Leave empty for none. Anyone holding a shop's job can use it.
    command = '',

    -- Re-check the item is still on the player every this many seconds while
    -- the tablet is open. 0 checks only when opening.
    checkSeconds = 30,

    -- Metres. How close the tablet has to be to connect to a vehicle.
    connectDistance = 6.0,

    -- Only connect to a vehicle that is inside the shop's boundary, with the
    -- mechanic inside it too. Draw the boundary in the builder.
    --
    -- A shop with no boundary drawn is not restricted, so this changes nothing
    -- until somebody draws one. /mechanicdebug says which shops have one.
    insideShopOnly = true,

    -- Work happens on a bay. Fitting a part, a performance package or a stance
    -- needs the mechanic stood on a tuning bay with the car on it — reading an
    -- invoice or a work order does not. Off lets a mechanic work anywhere
    -- inside the shop.
    insideBayOnly = true,

    -- Hold a tablet prop and stand like you are reading it while the panel is
    -- open. Cosmetic only; the interface works either way.
    animation = true,

    -- Show the REAL vehicle in the panel, live, with its current paint and
    -- parts. The panel leaves a transparent window and a scripted camera puts
    -- the car behind it.
    --
    -- The camera takes over the screen while the tablet is open, the same way
    -- the tuning preview does. Off falls back to a drawn card.
    livePreview = true,
}

-- ── The office laptop ────────────────────────────────────────────────────────
-- A prop you place in the shop. The tablet is carried to a car; the laptop
-- stays on the desk and runs the business — billing, work orders, the parts
-- list, staff and the money. Employees only.
--
-- Place one with the shop builder. A shop with no laptop simply does its
-- billing from the tablet instead.
Config.Desk = {
    -- Any prop model. These two are the usual laptops; the second is open.
    prop = 'prop_laptop_lester2',

    -- Spawn the prop at all. Off means the point still works, there is just
    -- nothing to look at — useful when the MLO already has a laptop modelled.
    spawnProp = true,

    -- Metres. How close you have to be to use it.
    useDistance = 1.6,
}

-- ── Pricing ──────────────────────────────────────────────────────────────────
-- Three modes:
--   fixed    the category price, whatever the vehicle is worth
--   percent  a share of the vehicle's value
--   both     the share, plus the fixed price on top
--
-- Each shop can override the numbers in the builder. This is the default a new
-- shop starts with, and the mode applies to every shop on the server.
Config.Pricing = {
    mode = 'fixed',

    -- Added to the price for each mod level above the first. 0.1 means a level
    -- 4 part costs 30% more than a level 1 part. Plates, tints and horns ignore
    -- it — they have no natural ordering.
    levelMultiplier = 0.1,

    -- price is used by 'fixed' and 'both'. percent is a share of the vehicle's
    -- value, so 0.01 is 1%.
    categories = {
        cosmetics   = { price = 500,  percent = 0.01 },
        wheels      = { price = 750,  percent = 0.01 },
        performance = { price = 2500, percent = 0.02 },
        respray     = { price = 400,  percent = 0.005 },
        lights      = { price = 350,  percent = 0.005 },
        interior    = { price = 400,  percent = 0.005 },
        livery      = { price = 600,  percent = 0.01 },
        extras      = { price = 250,  percent = 0.005 },
        plate       = { price = 200,  percent = 0.002 },
        stance      = { price = 900,  percent = 0.01 },
        repair      = { price = 1200, percent = 0.02 },
    },

    -- Where a vehicle's value comes from, in order. The framework's shared
    -- vehicle list is checked first, then the class default, then the fallback.
    -- Addon vehicles missing from the shared list are why classDefaults exists.
    classDefaults = {
        [0] = 25000,   [1] = 35000,   [2] = 45000,   [3] = 30000,
        [4] = 65000,   [5] = 95000,   [6] = 120000,  [7] = 250000,
        [8] = 20000,   [9] = 55000,   [12] = 40000,  [13] = 1500,
        [14] = 180000, [15] = 400000, [16] = 850000, [17] = 60000,
        [18] = 90000,  [19] = 250000, [20] = 70000,
    },

    fallback = 50000,
}

-- ── Tuning ───────────────────────────────────────────────────────────────────
-- Nothing here lists what a vehicle can have fitted. That is read off the
-- vehicle itself when the panel opens, so an addon car with its own body kit
-- offers its own body kit under its own names with no config entry.
--
-- These settings only take things AWAY.
Config.Tuning = {
    -- Hide these everywhere. Use the ids from shared/mods.lua, for example
    -- 'armour', 'hydraulics', 'turbo'.
    blockedSlots = {},

    -- Hide slots for particular models. Spawn code, lowercase.
    --   ['police'] = { 'spoiler', 'livery' },
    blockedByModel = {},

    -- Vehicles no mechanic may touch at all. Spawn codes, lowercase.
    blockedModels = { 'police', 'police2', 'police3', 'ambulance', 'firetruk' },

    -- Vehicles this resource should treat as electric. It detects the stock
    -- ones; list any addon EVs here.
    electricModels = { 'dilettante', 'dilettante2', 'khamelion', 'voltic', 'voltic2',
        'cyclone', 'tezeract', 'neon', 'raiden', 'imorgon', 'omnisegt', 'powersurge', 'virtue' },

    -- Let a customer look at a modification before paying for it.
    --
    -- Nothing previewed is ever kept. The vehicle is recorded before the first
    -- change and put back the moment the panel closes, so looking at a respray
    -- is not a way to get one.
    preview = true,

    -- Seconds to fit one thing, by category. Fitting is not instant: the
    -- mechanic works on the car and the panel steps aside while they do.
    -- 0 anywhere makes that category instant again.
    seconds = {
        cosmetics = 10, wheels = 12, respray = 14, livery = 8,
        lights = 6, interior = 6, extras = 5, plate = 4,
        performance = 12, default = 8,
    },
}

-- ── Paint ────────────────────────────────────────────────────────────────────
-- The colours themselves are in shared/paint.lua, grouped the way the game
-- groups them: Metallic, Matte, Metals & Chrome, Utility and Worn. This is
-- where you change what a shop is allowed to sell.
Config.Paint = {
    -- Colour indices to take off the list entirely.
    hidden = {},

    -- Colours that are in the table but off by default because selling them
    -- causes arguments. Right now that is only the police fleet blue.
    allowRestricted = false,

    -- Colours to ADD. This is for paint your server streams itself: an add-on
    -- paint pack, or the chameleon paints on a build that has them.
    --
    -- Nothing is shipped here on purpose. Chameleon indices depend on the
    -- server build and on carcols_gen9.meta being streamed — they start at 161
    -- on some builds and higher on others — so guessing them here would paint
    -- cars the wrong colour rather than fail. Find yours and list them.
    --
    -- `family` slots a colour into one of the groups above, or invents a new
    -- group of its own. Leave it out and it lands under extraLabel.
    extra = {
        -- { id = 161, label = 'Monochrome',  hex = '#8f97a8', family = 'chameleon' },
        -- { id = 162, label = 'Night & Day', hex = '#3b5ba8', family = 'chameleon' },
    },

    extraLabel = 'Add-ons',
}

-- ── Servicing ────────────────────────────────────────────────────────────────
-- Parts wear as a vehicle gains mileage, and worn parts make it drive worse
-- until a mechanic replaces them. What each part is, how long it lasts and what
-- it costs the car is in shared/service.lua — that file is the one to edit.
--
-- Wear is worked out on the server from reported distance. Changing a lifespan
-- does not reset anything already worn; the new rate applies from then on.
Config.Service = {
    enabled = true,

    -- Percentage at or below which a part is flagged as due. Higher flags it
    -- sooner. It only decides when the warning appears — it does not change
    -- how fast the part wears or how much it costs the car.
    threshold = 20,

    -- Seconds to replace one part.
    replaceSeconds = 10,

    -- Vehicles that never wear. Spawn codes, lowercase.
    blocked = { 'police', 'police2', 'police3', 'ambulance', 'firetruk' },

    -- Charge the customer for labour on top of the parts. 0 is parts only.
    labour = 250,
}

-- ── Custom tuning ────────────────────────────────────────────────────────────
-- Engine swaps, drivetrains, turbos, brakes, tyres, gearboxes and drift setups.
-- The options themselves live in shared/tuning.lua.
--
-- These change the vehicle's HANDLING. The shipped values are tuned against
-- vanilla vehicles; an addon car with an unbalanced handling file can come out
-- slower after a swap. That is the handling file, not the swap.
Config.CustomTuning = {
    enabled = true,

    -- Take the item rather than the money. Per shop this is set in the builder;
    -- this is what a new shop starts with.
    requiresItem = true,

    -- Seconds to fit one. An engine swap is deliberately slower than a set of
    -- tyres.
    seconds = { engineSwaps = 25, drivetrains = 18, gearboxes = 18, default = 10 },
}

-- ── Dyno ─────────────────────────────────────────────────────────────────────
-- Place a dyno bay in the builder. Numbers come from the vehicle's handling and
-- what is fitted, so they are consistent rather than physical.
Config.Dyno = {
    enabled = true,
    seconds = 30,
}

-- ── Nitrous ──────────────────────────────────────────────────────────────────
-- An item, and a package the mechanic fits. Both are needed.
Config.Nitrous = {
    enabled = true,
    item = 'nitrous',

    -- Which key holds the boost. 21 is left shift.
    control = 21,

    push = 14.0,
    drainPerSecond = 22.0,
    refillPerSecond = 4.0,
}

-- ── Lighting remote ──────────────────────────────────────────────────────────
-- An item that controls the xenons and underglow, with effects.
Config.Lighting = {
    enabled = true,
    item = 'lighting_remote',
}

-- ── Repairs ──────────────────────────────────────────────────────────────────
Config.Repair = {
    -- A full repair at a bay. Price comes from Config.Pricing.
    bay = { enabled = true, seconds = 12 },

    -- Items anyone can carry. Set an item to false to remove that route.
    kits = {
        repair_kit = {
            label = 'Repair Kit',
            engine = 100, body = 100,
            seconds = 20,
            -- Needs the bonnet open and the player stood at the front.
            atEngine = true,
        },
        advanced_repair_kit = {
            label = 'Advanced Repair Kit',
            engine = 100, body = 100,
            seconds = 12,
            atEngine = true,
        },
        duct_tape = {
            label = 'Duct Tape',
            -- Enough to get moving again, not enough to skip the mechanic.
            engine = 35, body = 20,
            seconds = 8,
            atEngine = false,
            -- Cannot be used again until the vehicle has been properly fixed.
            onceUntilRepaired = true,
        },
    },

    -- Washing. Free at a bay unless you price it.
    wash = { enabled = true, seconds = 6, item = 'cleaning_kit', price = 150 },
}

-- ── Stock ────────────────────────────────────────────────────────────────────
-- A shop can only fit what it has on the shelf. The shelf is the shop's own
-- storage point, so a mechanic stocks it the same way they stock anything else:
-- put parts in, or make them at the bench, and the tablet reads what is there.
--
-- Off, every option is fittable and nothing is ever consumed — which is how
-- this resource behaved before, if that is what you want.
--
-- A shop with no storage point reads the mechanic's own pockets instead, so a
-- one-room self service shop still works without building a stockroom.
Config.Stock = {
    require = true,

    -- Which item each kind of work uses up. One per category; set any of them
    -- to '' and that category stops needing anything.
    categoryItems = {
        cosmetics   = 'body_part',
        wheels      = 'wheel_set',
        respray     = 'paint_can',
        livery      = 'vinyl_wrap',
        lights      = 'light_kit',
        interior    = 'interior_part',
        extras      = 'body_part',
        plate       = 'plate_blank',
        performance = 'performance_part',
    },

    -- And where a single slot deserves its own part rather than the category's.
    -- An engine upgrade is not a brake upgrade, so the shop stocks them apart
    -- and the bench makes them apart. Anything not listed falls back to the
    -- category above.
    slotItems = {
        engine       = 'engine_parts',
        brakes       = 'brake_parts',
        transmission = 'transmission_parts',
        suspension   = 'suspension_parts',
        turbo        = 'turbo_kit',
    },
}

-- ── The crafting bench ───────────────────────────────────────────────────────
-- Place one in the builder. Material comes off the shop's own shelf and the
-- finished part goes back onto it, so the bench is how a shop turns a pile of
-- scrap into the parts it fits.
--
-- A shop with no storage point uses the mechanic's pockets for both ends
-- instead, which is the same rule the rest of stock follows.
--
-- The item names below are the ones QBCore ships with. Point them at whatever
-- your server already uses for raw material and nothing else has to change.
Config.Crafting = {
    enabled = true,

    -- Seconds at the bench per part.
    seconds = 8,

    -- Metres. How close the bench has to be to use it.
    useDistance = 1.8,

    materials = {
        scrap  = { item = 'metalscrap', label = 'Scrap' },
        steel  = { item = 'steel',      label = 'Steel' },
        rubber = { item = 'rubber',     label = 'Rubber' },
        glass  = { item = 'glass',      label = 'Glass' },
    },

    -- What the bench can make. `category` ties a part to the work it is used
    -- for, which is what the tablet reads when it says a part is out of stock.
    recipes = {
        { item = 'body_part',       label = 'Body Part',      category = 'cosmetics', group = 'Parts',
          needs = { scrap = 6, steel = 4 } },

        { item = 'wheel_set',       label = 'Wheel Set',      category = 'wheels', group = 'Parts',
          needs = { rubber = 6, steel = 5 } },

        { item = 'paint_can',       label = 'Paint Can',      category = 'respray', group = 'Parts',
          needs = { scrap = 3 } },

        { item = 'vinyl_wrap',      label = 'Vinyl Wrap',     category = 'livery', group = 'Parts',
          needs = { rubber = 3, scrap = 2 } },

        { item = 'light_kit',       label = 'Light Kit',      category = 'lights', group = 'Parts',
          needs = { glass = 4, scrap = 3 } },

        { item = 'interior_part',   label = 'Interior Part',  category = 'interior', group = 'Parts',
          needs = { rubber = 3, scrap = 3, glass = 1 } },

        { item = 'plate_blank',     label = 'Plate Blank',    category = 'plate', group = 'Parts',
          needs = { steel = 2, scrap = 1 } },

        { item = 'performance_part', label = 'Performance Part', category = 'performance', group = 'Upgrades',
          needs = { steel = 8, scrap = 6, rubber = 2 } },

        { item = 'tyre_kit',        label = 'Tyre Kit',       group = 'Supplies',
          needs = { rubber = 8, steel = 2 } },

        { item = 'repair_kit',      label = 'Repair Kit',     group = 'Supplies',
          needs = { scrap = 5, steel = 3, rubber = 1 } },

        { item = 'advanced_repair_kit', label = 'Advanced Repair Kit', group = 'Supplies',
          needs = { scrap = 9, steel = 6, rubber = 2 } },

        { item = 'duct_tape',       label = 'Duct Tape',      group = 'Supplies',
          needs = { rubber = 3, scrap = 1 } },

        { item = 'cleaning_kit',    label = 'Cleaning Kit',   group = 'Supplies',
          needs = { rubber = 2, glass = 1 } },

        -- Servicing consumables. Every one of these is asked for by the
        -- servicing screen, so if the bench cannot make them the whole feature
        -- is a list of things nobody can do anything about.
        { item = 'engine_oil',      label = 'Engine Oil',     group = 'Servicing',
          needs = { scrap = 2 } },

        { item = 'air_filter',      label = 'Air Filter',     group = 'Servicing',
          needs = { scrap = 2, rubber = 1 } },

        { item = 'spark_plugs',     label = 'Spark Plugs',    group = 'Servicing',
          needs = { steel = 2, scrap = 1 } },

        { item = 'clutch',          label = 'Clutch',         group = 'Servicing',
          needs = { steel = 5, scrap = 3 } },

        { item = 'brake_pads',      label = 'Brake Pads',     group = 'Servicing',
          needs = { steel = 3, scrap = 2 } },

        { item = 'tyres',           label = 'Tyres',          group = 'Servicing',
          needs = { rubber = 8, steel = 2 } },

        { item = 'suspension_kit',  label = 'Suspension Kit', group = 'Servicing',
          needs = { steel = 6, rubber = 3 } },

        { item = 'ev_battery',      label = 'EV Battery',     group = 'Servicing',
          needs = { steel = 6, scrap = 5, glass = 2 } },

        { item = 'ev_coolant',      label = 'EV Coolant',     group = 'Servicing',
          needs = { scrap = 2, glass = 1 } },

        -- The modkit upgrades, one part per slot rather than one part for all
        -- of them. Level four costs the same as level one to make; what a
        -- level is worth to the customer is a price, not a recipe.
        { item = 'engine_parts',       label = 'Engine Parts',       group = 'Upgrades',
          needs = { steel = 7, scrap = 5 } },

        { item = 'brake_parts',        label = 'Brake Parts',        group = 'Upgrades',
          needs = { steel = 5, scrap = 3 } },

        { item = 'transmission_parts', label = 'Transmission Parts', group = 'Upgrades',
          needs = { steel = 6, scrap = 4, rubber = 1 } },

        { item = 'suspension_parts',   label = 'Suspension Parts',   group = 'Upgrades',
          needs = { steel = 6, rubber = 3 } },

        -- The engine swaps. Each one is its own build, and a V12 is not a
        -- weekend's work.
        { item = 'i4_engine',       label = 'I4 Turbo 2.0',   group = 'Engines',
          needs = { steel = 10, scrap = 8, rubber = 2 } },

        { item = 'v6_engine',       label = 'V6 3.5',         group = 'Engines',
          needs = { steel = 14, scrap = 11, rubber = 3 } },

        { item = 'v8_engine',       label = 'V8 6.2',         group = 'Engines',
          needs = { steel = 20, scrap = 15, rubber = 4 } },

        { item = 'v12_engine',      label = 'V12 6.5',        group = 'Engines',
          needs = { steel = 30, scrap = 22, rubber = 5 } },

        { item = 'electric_motor',  label = 'Electric Motor', group = 'Engines',
          needs = { steel = 16, scrap = 14, glass = 4, rubber = 3 } },

        -- Everything that bolts to the engine or the floor.
        { item = 'turbo_kit',       label = 'Turbo Kit',      group = 'Drivetrain',
          needs = { steel = 9, scrap = 6 } },

        { item = 'drivetrain_kit',  label = 'Drivetrain Kit', group = 'Drivetrain',
          needs = { steel = 11, scrap = 7, rubber = 2 } },

        { item = 'gearbox_kit',     label = 'Gearbox Kit',    group = 'Drivetrain',
          needs = { steel = 12, scrap = 8, rubber = 2 } },

        { item = 'brake_kit',       label = 'Brake Kit',      group = 'Drivetrain',
          needs = { steel = 8, scrap = 5 } },

        { item = 'drift_kit',       label = 'Drift Kit',      group = 'Drivetrain',
          needs = { steel = 7, rubber = 6, scrap = 4 } },
    },
}

-- ── Invoices ─────────────────────────────────────────────────────────────────
Config.Invoices = {
    enabled = true,

    -- Repairs, servicing and stance are added to a running draft as they are
    -- done, one line each, priced from the shop. The mechanic can edit every
    -- line before sending it.
    --
    -- Parts are not on this path. They are quoted in the tablet, written down
    -- as a work order and billed from the order, so a customer sees the price
    -- before the work rather than after it.
    autoDraft = true,

    -- Percentage of a paid invoice that goes to the mechanic who sent it. The
    -- rest stays with the shop. 0 turns commission off. A shop can override it.
    defaultCommission = 10,

    -- Days an unpaid invoice stays in the customer's /invoices list. 0 keeps
    -- them forever.
    expireDays = 14,

    -- A customer this far from the mechanic can still be invoiced. Metres.
    customerDistance = 12.0,

    command = 'invoices',
}

-- ── Notifications ────────────────────────────────────────────────────────────
Config.Notify = {
    -- ox_lib notifications, or hand off to the framework's own.
    style = 'ox_lib',   -- ox_lib | framework

    position = 'top-right',
}

-- ── Discord ──────────────────────────────────────────────────────────────────
-- One webhook per category so the people watching each one can have their own
-- channel. Leave a URL blank and that category is silently skipped.
Config.Discord = {
    botName = 'XS-Mechanic',

    tuningWebhook  = '',   -- work applied to vehicles
    moneyWebhook   = '',   -- invoices, parts, society movements
    adminWebhook   = '',   -- shops created, edited, deleted
    serviceWebhook = '',   -- parts replaced, services completed
}
