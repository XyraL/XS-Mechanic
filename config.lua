Config = {}

-- Force a bridge instead of auto-detecting. 'auto' is almost always right.
Config.Bridges = {
    framework = 'auto',   -- auto | qbox | qbcore
    inventory = 'auto',   -- auto | ox_inventory | qb-inventory | qs-inventory | codem-inventory | core_inventory | ps-inventory
    target    = 'auto',   -- auto | ox_target | qb-target | builtin
    keys      = 'auto',   -- auto | qbx | qb-vehiclekeys | qs-vehiclekeys | custom | none
    banking   = 'auto',   -- auto | qb-banking | Renewed-Banking | okokBanking | qbx | none
    phone     = 'auto',   -- auto | lb-phone | qs-smartphone | XS-Phone | qb-phone | none
    fuel      = 'auto',   -- auto | LegacyFuel | ox_fuel | cdn-fuel | ps-fuel | none
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
        desks   = 2,
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

    -- Let the boss manage staff and money from the laptop only, never from the
    -- tablet. Off lets both do it.
    managementHereOnly = false,
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
    preview = true,

    -- Put the vehicle back exactly as it was if the customer walks away
    -- mid-preview. Turning this off is not advised.
    restoreOnCancel = true,
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

-- ── Parts counters ───────────────────────────────────────────────────────────
-- What each shop sells is set per shop in the builder. This is the list the
-- builder offers when you place a counter, so you are not typing item names.
Config.Parts = {
    { item = 'repair_kit',          label = 'Repair Kit',          price = 850 },
    { item = 'advanced_repair_kit', label = 'Advanced Repair Kit', price = 2200 },
    { item = 'duct_tape',           label = 'Duct Tape',           price = 120 },
    { item = 'cleaning_kit',        label = 'Cleaning Kit',        price = 300 },
    { item = 'tyre_kit',            label = 'Tyre Kit',            price = 1400 },
    { item = 'performance_part',    label = 'Performance Part',    price = 3500 },
}

-- Whether buying from a counter takes the shop's money or the employee's own.
Config.Parts.paidBy = 'society'   -- society | player

-- ── Invoices ─────────────────────────────────────────────────────────────────
Config.Invoices = {
    enabled = true,

    -- An invoice is drafted as the mechanic works, one line per thing applied,
    -- priced from the shop. The mechanic can edit every line before sending.
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

-- ── Self-service ─────────────────────────────────────────────────────────────
Config.SelfService = {
    -- A self-service shop pays from the customer's own account. Which one.
    account = 'bank',   -- bank | cash

    -- Let an owned shop fall back to self-service when none of its staff are
    -- online. Each shop can switch this off in the builder.
    whenShopEmpty = true,
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
