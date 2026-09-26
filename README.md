<h1 align="center">XS-Mechanic</h1>

<p align="center">Mechanic shops for <strong>QBox</strong> and <strong>QBCore</strong>.</p>

<p align="center">
  <a href="https://github.com/XyraL/XS-Mechanic/releases"><img src="https://img.shields.io/github/v/release/XyraL/XS-Mechanic?style=flat-square&color=55e2ad&label=release" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/framework-QBox%20%7C%20QBCore-55dcff?style=flat-square" alt="framework">
  <img src="https://img.shields.io/badge/status-beta-f5a524?style=flat-square" alt="status: beta">
  <img src="https://img.shields.io/badge/price-free-30d158?style=flat-square" alt="price">
  <a href="https://discord.gg/XRURAw4TM2"><img src="https://img.shields.io/badge/support-discord-5865F2?style=flat-square" alt="support"></a>
</p>

<p align="center">
  <a href="https://github.com/XyraL/XS-Mechanic/releases">Releases</a> &nbsp;·&nbsp;
  <a href="https://discord.gg/XRURAw4TM2">Support</a>
</p>

---

> **Beta.** Still being worked on, so expect rough edges. If you hit one, tell
> me on [Discord](https://discord.gg/XRURAw4TM2) and I will get it sorted.

The tuning menu is built from the car in front of you.

Nothing lists what a vehicle can have fitted. The script asks the model, so an
addon car with its own body kit offers its own body kit, under the names its
own files give them. A slot the model has nothing in never appears.

It ships **empty**. No coordinates from someone else's map, no shops of mine to
delete. Every shop on your server is one you built.

## What it is

**Two things you carry, and they do different jobs.**

The **tablet** is an item. It is the tool a mechanic takes to a car — plug into
whatever is in front of you, read what is fitted, change it, repair it, bill it.

Its home screen is Vehicle, Repairs, Service, Orders, Invoices and Settings.
Tuning, Performance, Stance and Dyno all live inside **Vehicle**, because they
are four answers to the same question — what is bolted to this car — and four
icons for one job is three too many.

The **laptop** is a prop you place in the shop. It runs the business: invoices,
work orders, staff and the money. No car needed.

**Ownership is the job.** You build a shop over someone's interior, point it at
a job, and give them that job. That is the whole ownership model — there is
nothing to buy and nothing to transfer. Several shops means several jobs, and
each one is sealed off: its own staff, prices, parts, storage, invoices and
money.

**The builder.** `/mechanic` opens a free camera. Fly to the interior you
actually own, drop the tuning bays, the storage, the laptop and the crafting
bench where they really are, and save. No restart, no config
editing, no coordinates to copy.

**The boundary.** Draw the walls of the shop in the builder and that is what "at
the shop" means: a mechanic can only connect to a vehicle inside it, and has to
be inside it themselves. Without one a tablet works anywhere on the map, so draw
one. Checked on the server, not just in the panel.

**Pricing.** Fixed, a share of the vehicle's value, or both. Per category, and
each shop can override the numbers. Higher mod levels cost more through one
multiplier rather than a price per part.

**Invoices.** The invoice builds itself as the mechanic works — every part
fitted adds a line at the shop's price. Edit it, send it, save it for later,
send it again. The customer gets a prompt and a phone notification, and
`/invoices` holds anything unpaid. A share goes to the mechanic who wrote it.

Billing asks who is paying and offers three answers: whoever the car is
registered to — listed first, and billable even when they are not on — anyone
standing close enough, or a server ID typed in by hand.

If you already run an invoice resource, point this at it and it hands the bill
over instead of collecting itself. `Config.Bridges.billing` finds okokBilling,
esx_billing or qb-phone on its own, and `Config.Invoices.provider.event` takes
anything else — one server event, called with the society, shop, mechanic,
customer, amount, label, plate and invoice id. The row is still written to
`xs_mechanic_invoices` either way, because the shop's own screens and the boss's
books read it. This only decides who chases the customer.

**Parts are never billed from the tuning screen.** They go on a work order, and
the order is what gets billed, once, from the Orders app — so a car is never
charged for work nobody wrote down.

**Work orders.** A customer drives into a bay, picks what they want and looks at
it on their own car, and sends the lot over with a note and an estimate. It
lands on the tablet of whoever is working, and the mechanic who walks up to that
car and connects to it sees the order on the screen. Lines can be taken off —
a part the shop cannot get hold of comes off the order and off the quote.

Performance is not on the customer's screen. There is nothing to look at, so
they ask the mechanic, who fits it and bills for it.

**Stock.** A shop can only fit what it has. Each kind of work uses up a part,
the parts live in the shop's storage, and the tablet greys out what has run out
instead of offering it anyway. A customer can still order something the shop has
not got — somebody just has to go and make one.

A shop with no storage point placed does not run on stock at all, so nothing is
rationed until there is a shelf to ration it from.

A part counts whether it is on the shelf or in the mechanic's own pockets, and
the shelf is always spent first, so a mechanic who brought their own parts does
not quietly lose them to the shop. `Config.Stock.useFrom` turns either half off.

The shelf is 500 slots and four tonnes by default — a workshop is a stockroom,
not a glovebox, and a bench that makes ten at a time fills a small one in an
afternoon. `Config.Stock.storage` is the dial.

**Fitting with nothing written down.** Use a part at a car and it looks for a
work order first. If there is no order, or no line on it wants what you are
holding, it asks what the part should go on instead of refusing — narrowed to
the slots that particular part is the part for, read off the car itself. Same
rules as any other work: mechanic, at the shop, out of the car, on a bay.

**Work happens on a bay.** Fitting anything needs the mechanic stood on a tuning
bay with the car on it. Reading an invoice or a work order does not.

**The bench.** Place one in the builder and the shop makes its own parts out of
scrap, steel, rubber and glass. Everything it fits, it can build: body panels,
wheels, paint and lights, the engine and brake and suspension upgrades, and
every engine swap, turbo, gearbox and brake kit as its own job. The material
comes off the shelf and the finished part goes back onto it, so a shop that
keeps its storage stocked keeps itself supplied. No minigame — pick the part,
and if the material is there, it gets made.

**Who sets the prices.** A grade you pick per shop can change what the shop
charges: what each category costs, and what a performance package costs and is
called. Below that grade you can do the work and write the invoice,
you just cannot decide what any of it is worth.

**Self service.** A shop can be open to anyone, or an owned shop can fall back
to self service while none of its staff are online. Self service pays from the
customer's own account and writes no invoice.

**Repairs.** The job, not a menu option: a customer sees exactly what is wrong
with their car and puts a repair on the same order, and the shop does the work.
Kits anyone can carry are still there for the roadside — duct tape gets you
moving again without getting you fixed.

## Requirements

- `ox_lib`
- `oxmysql`
- QBox (`qbx_core`) or QBCore (`qb-core`)

Everything else is optional and detected automatically: inventory, target,
banking and phone. Set any of them by hand in `Config.Bridges` if the detection
guesses wrong.

## Setup

### 1. Install it

Drop the folder into your resources, then in `server.cfg`, after `ox_lib` and
`oxmysql`:

```cfg
ensure XS-Mechanic
```

The database sets itself up on first start. `sql/xs_mechanic.sql` is there if
you would rather import it by hand.

### 2. Add the items

39 items. Copy the block for your inventory and paste it **inside** the
existing table, before its closing `}`.

The crafting bench also needs raw material, and that is **not** in the blocks
below — it uses what your server already has. Out of the box it looks for
`metalscrap`, `steel`, `rubber` and `glass`, which is what QBCore ships with. Point `Config.Crafting.materials` at your own names if they differ.

<details>
<summary><strong>ox_inventory</strong> — paste into <code>ox_inventory/data/items.lua</code></summary>

```lua
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
    client = { export = 'XS-Mechanic.fit_tyre_kit' },
},

['performance_part'] = {
    label = 'Performance Part',
    weight = 2500,
    stack = true,
    close = true,
    description = 'Whatever the tuning menu asked for.',
    client = { export = 'XS-Mechanic.fit_performance_part' },
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
    client = { export = 'XS-Mechanic.fit_i4_engine' },
},

['v6_engine'] = {
    label = 'V6 Engine',
    weight = 55000,
    stack = true,
    close = true,
    description = 'The sensible one.',
    client = { export = 'XS-Mechanic.fit_v6_engine' },
},

['v8_engine'] = {
    label = 'V8 Engine',
    weight = 70000,
    stack = true,
    close = true,
    description = 'Torque everywhere.',
    client = { export = 'XS-Mechanic.fit_v8_engine' },
},

['v12_engine'] = {
    label = 'V12 Engine',
    weight = 85000,
    stack = true,
    close = true,
    description = 'Not for a hatchback.',
    client = { export = 'XS-Mechanic.fit_v12_engine' },
},

['electric_motor'] = {
    label = 'Electric Motor',
    weight = 60000,
    stack = true,
    close = true,
    description = 'Instant, and quiet about it.',
    client = { export = 'XS-Mechanic.fit_electric_motor' },
},

['turbo_kit'] = {
    label = 'Turbo Kit',
    weight = 9000,
    stack = true,
    close = true,
    description = 'Snail, pipework, wastegate.',
    client = { export = 'XS-Mechanic.fit_turbo_kit' },
},

['drivetrain_kit'] = {
    label = 'Drivetrain Kit',
    weight = 15000,
    stack = true,
    close = true,
    description = 'Changes which wheels do the work.',
    client = { export = 'XS-Mechanic.fit_drivetrain_kit' },
},

['gearbox_kit'] = {
    label = 'Gearbox',
    weight = 25000,
    stack = true,
    close = true,
    description = 'Ratios you actually chose.',
    client = { export = 'XS-Mechanic.fit_gearbox_kit' },
},

['brake_kit'] = {
    label = 'Brake Kit',
    weight = 6000,
    stack = true,
    close = true,
    description = 'Discs, calipers, braided lines.',
    client = { export = 'XS-Mechanic.fit_brake_kit' },
},

['drift_kit'] = {
    label = 'Drift Kit',
    weight = 7000,
    stack = true,
    close = true,
    description = 'Loose on purpose.',
    client = { export = 'XS-Mechanic.fit_drift_kit' },
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

-- Parts the bench makes, and the work each one is used up by. A shop that
-- runs out of body panels cannot fit one until somebody makes another.

['body_part'] = {
    label = 'Body Part',
    weight = 2500,
    stack = true,
    close = false,
    description = 'A panel, a bumper, a skirt. Whatever the car is missing.',
    client = { export = 'XS-Mechanic.fit_body_part' },
},

['wheel_set'] = {
    label = 'Wheel Set',
    weight = 6000,
    stack = true,
    close = false,
    description = 'Four of them, boxed.',
    client = { export = 'XS-Mechanic.fit_wheel_set' },
},

['paint_can'] = {
    label = 'Paint Can',
    weight = 1200,
    stack = true,
    close = false,
    description = 'Mixed to whatever the customer picks.',
    client = { export = 'XS-Mechanic.fit_paint_can' },
},

['vinyl_wrap'] = {
    label = 'Vinyl Wrap',
    weight = 900,
    stack = true,
    close = false,
    description = 'A roll of it. Bubbles are the fitter, not the vinyl.',
    client = { export = 'XS-Mechanic.fit_vinyl_wrap' },
},

['light_kit'] = {
    label = 'Light Kit',
    weight = 1100,
    stack = true,
    close = false,
    description = 'Housings, bulbs and the loom to run them.',
    client = { export = 'XS-Mechanic.fit_light_kit' },
},

['interior_part'] = {
    label = 'Interior Part',
    weight = 1400,
    stack = true,
    close = false,
    description = 'Trim, dials, a wheel. The bits you actually touch.',
    client = { export = 'XS-Mechanic.fit_interior_part' },
},

['plate_blank'] = {
    label = 'Plate Blank',
    weight = 300,
    stack = true,
    close = false,
    description = 'Pressed, unprinted, entirely legal until it is not.',
    client = { export = 'XS-Mechanic.fit_plate_blank' },
},

-- The modkit upgrades. Engine, brakes and transmission all take the generic
-- performance part; these two are the ones a shop stocks apart.

['armour_plate'] = {
    label = 'Armour Plate',
    weight = 9000,
    stack = true,
    close = false,
    description = 'Ballistic plate, cut to the shell and heavy with it.',
    client = { export = 'XS-Mechanic.fit_armour_plate' },
},

['suspension_parts'] = {
    label = 'Suspension Parts',
    weight = 3600,
    stack = true,
    close = false,
    description = 'Coilovers, bushes and drop links.',
    client = { export = 'XS-Mechanic.fit_suspension_parts' },
},
```

</details>

<details>
<summary><strong>qb-inventory, ps-inventory, qs-inventory and the rest</strong> — paste into <code>qb-core/shared/items.lua</code></summary>

```lua
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
```

</details>

**ox_inventory: the `client = { export = ... }` lines are not optional.** ox
ignores `CreateUseableItem` entirely and only calls an export named in its own
item definition, so without those lines the tablet, the repair kits, the duct
tape, the nitrous and the lighting remote do nothing at all when used —
silently, with no error. Six items carry one:

```
mechanic_tablet   repair_kit   advanced_repair_kit
duct_tape         nitrous      lighting_remote
```

The same blocks live in `items/` in the folder if you would rather open them
there.

**Images.** All 37 ship in `inventory_images/`, named to match the item names
above. Copy them into your inventory's image folder:

| Inventory | Where |
|---|---|
| ox_inventory | `ox_inventory/web/images/` |
| qb-inventory | `qb-inventory/html/images/` |
| ps-inventory | `ps-inventory/html/images/` |
| qs-inventory | `qs-inventory/html/images/` |
| codem-inventory | `codem-inventory/html/itemimages/` |
| core_inventory | `core_inventory/html/img/` |

If yours is not listed, put them wherever its existing item PNGs already live.
Restart the inventory resource afterwards, and hard-refresh the NUI cache if
the old blank slots stick around.

The crafting materials are the exception — `metalscrap`, `steel`, `rubber` and
`glass` are your server's items, so they keep whatever images they already have.

### 3. Give yourself admin

Any **one** of these is enough — it is checked in this order.

An ace in `server.cfg`:

```cfg
add_ace group.admin xs.mechanic allow
```

Or your framework's permission group, if you already use one. `Config.Admin`
accepts `admin` and `god` out of the box:

```lua
Config.Admin = {
    acePermission = 'xs.mechanic',
    groups        = { 'admin', 'god' },
    licenses      = {},
}
```

Or a specific licence, when you want one person and nothing else:

```lua
licenses = { '1a2b3c4d5e6f7890abcdef1234567890abcdef12' },
```

That is the part after `license:` in your identifiers. The server console prints
them when you connect, and txAdmin lists them on the player.

### 4. Make a job for each shop

Ownership **is** the job: you build a shop, point it at a job, and give that job
to whoever owns the interior. So each shop needs a job to exist first, in your
framework, not here.

QBox — `qbx_core/shared/jobs.lua`. QBCore — `qb-core/shared/jobs.lua`:

```lua
mechanic = {
    label = 'Hayes Autoworks',
    defaultDuty = true,
    grades = {
        [0] = { name = 'Trainee' },
        [1] = { name = 'Apprentice' },
        [2] = { name = 'Mechanic' },
        [3] = { name = 'Foreman' },
        [4] = { name = 'Owner', isboss = true },
    },
},
```

The builder warns you if a shop names a job your framework does not have. Grade
3 and up gets the Team app and the shop's money by default — change that per
shop in the builder, or `Config.Jobs.defaultBossGrade` for new ones.

### 5. Build a shop

Restart, run `/mechanic`, and place your points. It needs at least one point
before it will save. Give the job to whoever owns the place and you are done.

**Draw the boundary while you are in there.** Fly round the walls dropping a
corner at each one, press E, and save. Until you do, anyone with the job can
work on a car anywhere on the map. `/mechanicdebug` tells you which shops are
still missing one.

The console prints what it detected on start — framework, inventory, banking —
so if a bridge guessed wrong, that line is where it shows.

## Commands

| Command | Who | What |
|---|---|---|
| `/mechanic` | Admin | The shop builder |
| `/invoices` | Anyone | Your unpaid invoices |
| `/mechanicshops` | Admin | List every shop; `on` switches them all back on |
| `/mechanicdebug` | Admin | What was detected, what is on, what is wrong |

## License

Free to use on any server you own or operate, including commercial. Modify it
for your own server. No redistribution and no resale. See [LICENSE](LICENSE).
