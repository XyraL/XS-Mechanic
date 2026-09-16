# Changelog

## 0.5.0

Four fixes and the shop actually being a shop.

- **The live car never showed.** The window was transparent, but four layers
  of the tablet were painted behind it, and a transparent box over an opaque
  one is still opaque. The shell, the screen, the column and the card now cut
  a hole through themselves where the window is.
- **No animation when fitting a part.** The tablet pose was being stopped half
  a second late, and the stop cleared every task the mechanic had — including
  the fitting animation that had just started. Cosmetic work takes time now
  too, rather than parts appearing out of nowhere.
- **A preview you walked away from was a free respray.** Custom paint is not
  cleared by putting the old colour back, so it stayed; extras, neon, xenons
  and stance were never put back at all; and connecting to a second car handed
  it the first car's settings. The whole lot is recorded per vehicle now and
  put back when the panel closes, every time.
- **Shops have a boundary.** Draw the walls in the builder and that is what "at
  the shop" means — a mechanic can only work on a vehicle inside it, and has to
  be inside it themselves. Checked on the server. Shops without one carry on as
  before, and `/mechanicdebug` says which those are.
- **Work orders changed shape.** The customer desk is gone. A customer drives
  in, picks what they want, looks at it on their own car and sends it; it lands
  on the tablet, and the mechanic who connects to that car sees it there. Staff
  can take lines off an order, and the quote comes down with them.
- **Stock.** A shop can only fit what it has on the shelf, which is its storage
  point. What has run out is greyed out instead of offered. A customer can
  still order something the shop has not got.
- **A crafting bench.** Make parts out of scrap, metal, rubber, steel and
  glass. Material from your pockets, part onto the shelf, no minigame. The
  camera drops onto the bench and the panel is a sheet of light over it.
- **Prices are staff-editable.** A grade set per shop can change what the
  categories cost, what the counter sells and what a performance package costs
  and is called.
- The dyno needed a dyno bay. It ran from anywhere the tablet opened.
- Performance parts are off the customer's screen. They ask the mechanic.
- Seven new items, and a checker that every item name the resource uses exists
  in both inventory blocks.

## 0.4.1

- Seven config options did nothing at all. Two named bridges that do not
  exist and one duplicated a per-shop setting, so those are gone; the rest
  now work: losing the tablet closes it, invoicing can be switched off,
  management can be kept to the laptop, and fitting a tuning part takes
  time instead of happening instantly.
- `/mechanicdebug` prints what was detected, what is on, and what is wrong
  with each shop.

## 0.4.0

New interface.

- Black and blue, and laid out around the car instead of around a menu.
  The vehicle sits down the left the whole time you are working on it, with
  its condition and everything fitted; the parts get the width; the bill
  runs along the bottom.
- **The car in the panel is the actual car.** The panel leaves a hole and a
  camera puts the real vehicle behind it, with its current paint and parts.
  Turn it off with `Config.Tablet.livePreview` and you get a drawn card.
- Six accent colours, blue out of the box.
- The builder shares the layout: shops down the left, the one you are
  editing on the right.

## 0.3.1

- Orders can only be sent while somebody is actually working. With the shop
  empty a customer either does it themselves or comes back later — no more
  orders piling up with nobody to read them.
- Car lifts are gone. A tuning bay is somewhere you drive into.
- The builder picks a job from a dropdown of the ones your framework has,
  instead of you typing the name and hoping.
- You hold a tablet while the tablet is open. Switch it off with
  `Config.Tablet.animation`.

## 0.3.0

- The tablet crashed the moment it read a vehicle: two natives were spelled
  wrong. Every native the resource calls is now checked against the real
  list, which found a second one nobody had hit yet.
- Customers can use a bay themselves. Pick parts, see them on the car, and
  send the lot to the shop as a work order with an estimate. Performance
  goes straight on the list, since there is nothing to look at.
- The shop sees exactly what was picked, priced, on the order.
- Paying on the spot is still there where self service is allowed.
- The parts counter has its own screen instead of opening the laptop.

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
