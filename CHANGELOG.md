# Changelog

## 0.2.5

- `Tried to access invalid entity`. The lift and the dyno held onto a
  vehicle across the whole animation — thirty seconds, for a dyno run — and
  kept using it after the car was stored, deleted or driven out of range.
  Both re-check now, and the lighting remote checks after its dialog.

## 0.2.4

- The mechanic tablet item still would not open. The export is registered on
  both sides now, so it does not matter which one your inventory asks.
- The client prints how many item exports it registered a few seconds after
  you join. If you do not see that line, the folder on your server is
  missing `client/items.lua`.

## 0.2.3

- Placing anything in the builder threw `attempt to index a nil value
  (global os)`. The client has no `os` library; point ids were asking it
  for the time.

## 0.2.2

Console spam.

- Every parked car you could not see was logging
  `GetNetworkObject: no object by ID n`, over and over. The state bag
  handler now asks the quiet native instead, and the lighting loop checks
  the id resolves before using it.

## 0.2.1

First in-game pass. Three fixes.

- Vehicles threw `bad argument #2 to tonumber` the moment one spawned.
- ox_inventory would not start: the tablet and kit items pointed at exports
  that were registered on the server instead of the client.
- A vehicle you could not see logged an error instead of being ignored.

## 0.2.0

Servicing, custom tuning, stance, lifts and the dyno.

- Parts wear as a vehicle gains mileage. Nine of them, each with its own
  lifespan and its own effect on how the car drives. Replace them from the
  tablet with the right part in hand.
- Odometer built in. No second resource.
- Engine swaps with their own sound, plus drivetrains, turbos, brake kits,
  tyres, gearboxes and a drift setup. Item or shop money, per shop.
- Stance: ride height, and camber and track per wheel, live on the vehicle.
- Car lifts that actually raise the car on them. Job locked.
- Dyno bay with a real sweep, an HP and torque graph, and a sheet you can
  show the customer.
- Nitrous and a lighting remote as pocket items.
- Twenty one new items across both inventory blocks.

## 0.1.0

First build.

- In-game shop builder on a free camera. Tuning bays, repair bays, parts
  counters, storage, the office laptop, a customer desk and duty points.
- Tuning read off the vehicle itself, so addon cars list their own parts.
- Cosmetics, wheels, performance, respray with RGB, lights, interior, liveries,
  extras and plates.
- Mechanic tablet as an item, for working on a connected car.
- Office laptop as a prop, for invoices, work orders, parts, staff and money.
- Invoices that build themselves as you work, with commission.
- Work orders left at the desk.
- Repairs at a bay, from a kit, or with duct tape.
- Self service shops, and owned shops that fall back to self service when
  nobody is on.
- Three pricing modes, per category, overridable per shop.
- Discord webhooks for tuning, money, admin and servicing.
