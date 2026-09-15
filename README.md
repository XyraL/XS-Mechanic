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

1. Drop the folder into your resources.
2. `ensure XS-Mechanic` after `ox_lib` and `oxmysql`.
3. Add the items from `items/` to your inventory.
4. Give yourself the `xs.mechanic` ace, or put your admin group in
   `Config.Admin.groups`.
5. Create a job in your framework for each shop you are going to build.
6. Run `/mechanic` in game and build one.

The database sets itself up on first start. `sql/xs_mechanic.sql` is there if
you would rather import it yourself.

**ox_inventory users:** paste the block from `items/ox_inventory.lua`. Those
`client = { export = ... }` lines are not optional — without them the tablet
and the repair kits do nothing at all when used, silently.

## Commands

| Command | Who | What |
|---|---|---|
| `/mechanic` | Admin | The shop builder |
| `/invoices` | Anyone | Your unpaid invoices |
| `/mechanicshops` | Admin | List every shop; `on` switches them all back on |

## License

Free to use on any server you own or operate, including commercial. Modify it
for your own server. No redistribution and no resale. See [LICENSE](LICENSE).
