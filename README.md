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

The **laptop** is a prop you place in the shop. It runs the business: invoices,
work orders, the parts counter, staff and the money. No car needed.

**Ownership is the job.** You build a shop over someone's interior, point it at
a job, and give them that job. That is the whole ownership model — there is
nothing to buy and nothing to transfer. Several shops means several jobs, and
each one is sealed off: its own staff, prices, parts, storage, invoices and
money.

**The builder.** `/mechanic` opens a free camera. Fly to the interior you
actually own, drop the tuning bays, the parts counter, the storage, the laptop
and the customer desk where they really are, and save. No restart, no config
editing, no coordinates to copy.

**Pricing.** Fixed, a share of the vehicle's value, or both. Per category, and
each shop can override the numbers. Higher mod levels cost more through one
multiplier rather than a price per part.

**Invoices.** The invoice builds itself as the mechanic works — every part
fitted adds a line at the shop's price. Edit it, send it, save it for later,
send it again. The customer gets a prompt and a phone notification, and
`/invoices` holds anything unpaid. A share goes to the mechanic who wrote it.

**Work orders.** A customer with nobody to talk to leaves the job at the desk —
what they want looking at, and a note. It turns up on the laptop for whoever is
next on.

**Self service.** A shop can be open to anyone, or an owned shop can fall back
to self service while none of its staff are online. Self service pays from the
customer's own account and writes no invoice.

**Repairs.** At a bay priced off the vehicle, or from a kit anyone can carry.
Duct tape gets you moving again without getting you fixed.

## Requirements

- `ox_lib`
- `oxmysql`
- QBox (`qbx_core`) or QBCore (`qb-core`)

Everything else is optional and detected automatically: inventory, target,
vehicle keys, banking and phone. Set any of them by hand in `Config.Bridges` if
the detection guesses wrong.

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

28 items. Copy the whole block for your inventory:

| Inventory | Paste `items/…` | Into |
|---|---|---|
| ox_inventory | `ox_inventory.lua` | `ox_inventory/data/items.lua` |
| qb-inventory, ps-inventory, qs-inventory, others | `qb_core.lua` | `qb-core/shared/items.lua` |

Paste the entries **inside** the existing table, before its closing `}`.

**ox_inventory: the `client = { export = ... }` lines are not optional.** ox
ignores `CreateUseableItem` entirely and only calls an export named in its own
item definition, so without those lines the tablet, the repair kits, the duct
tape, the nitrous and the lighting remote do nothing at all when used —
silently, with no error. Six items carry one:

```
mechanic_tablet   repair_kit   advanced_repair_kit
duct_tape         nitrous      lighting_remote
```

No item images ship with this. The qb block names a `.png` per item; drop your
own into your inventory's images folder, or the slots show blank.

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

The console prints what it detected on start — framework, inventory, banking —
so if a bridge guessed wrong, that line is where it shows.

## Commands

| Command | Who | What |
|---|---|---|
| `/mechanic` | Admin | The shop builder |
| `/invoices` | Anyone | Your unpaid invoices |
| `/mechanicshops` | Admin | List every shop; `on` switches them all back on |

## License

Free to use on any server you own or operate, including commercial. Modify it
for your own server. No redistribution and no resale. See [LICENSE](LICENSE).
