# Changelog

## 0.7.0

The tablet stops being the thing that changes the car.

- **Work is quoted in the tablet and done at the car.** Picking parts previews
  them and builds a list; the list becomes a work order and a bill. Nothing is
  fitted from a menu any more. A mechanic makes the part, carries it to the
  car, and uses it — and what goes on is read off that car's work order, so a
  paint can knows which colour and a body part knows which bumper. All 23 part
  items are useable on both inventories.
- **Bill the customer** replaces Fit all on the queue, with Put it on a work
  order underneath it. Both write the same order; billing sends one invoice for
  everything on it nobody has been charged for yet. Adding to a car that
  already has an order open appends to it, so the bumpers and the turbo are one
  job and one bill.
- **Performance goes through the same basket.** Engine swaps, turbos, brakes,
  gearboxes and the rest are picked, quoted, written down and billed exactly
  like a bumper, and fitted by using the part. They used to fit and charge the
  shop the moment you clicked them.
- **Every shop-written order recorded the MECHANIC as the customer.** It read
  an `owner` field off the vehicle profile that has never existed there — only
  the readout strip has one, and that is a display name rather than an id. With
  billing hanging off the order, that would have billed the mechanic every
  time.
- **A booked respray lost its colour.** Orders rebuilt each pick down to eight
  fields and dropped the rest, so a respray, an extra and a package all arrived
  as a line nobody could act on. Both order paths now carry the whole pick.
- **The paint palette is the real one.** 159 colours in five finishes —
  Metallic, Matte, Metals & Chrome, Utility and Worn — plus pearl and wheel
  colour off the same table, and `Config.Paint` for hiding colours or adding
  your own. The old hand-written list of 31 had 14 wrong entries: "Pure Gold"
  was index 120, which is Chrome, and "Bright Green" was 42, which is Matte
  Yellow. Finishes come from the game's own shader id rather than the name, so
  Util Garnet Red sits with the metallics because that is what it renders as.
- **The custom colour picker threw instead of picking.** A local named `paint`
  shadowed the function called `paint`.
- **A shop with forty finished jobs lost its open orders off the tablet** while
  a mechanic stood at the car holding the part for one of them.
- Picks no longer follow you from one car to the next.
- With a few things on the list, the sheet had squeezed the parts above it down
  to 130 pixels — not enough for one row of swatches.
- `tools/check-items.mjs` now expands the parts loop as well as the kit loop.

## 0.6.2

- **Tuning threw, and the throw looked like three separate bugs.** The queue
  moved to `XS.renderQueue` so Performance could use it too, and one call site
  in Tuning was left behind. The error took the whole bill out with it: no
  total, no Fit all, no work-order button, and the panel bailed before it could
  put the list back where you were reading it — so every click also jumped you
  to the top. One name, three symptoms.
- **The list keeps its place even when a panel breaks.** Scroll is restored in
  a `finally` now. A render that throws is a bug to fix, not a reason to also
  lose where the reader was.
- **Put it on a work order** sits under Fit all on the Tuning queue. Same
  basket, same total — the parts you cannot fit today get written down against
  that car instead.
- **Writing an order failed with a SQL error.** `Framework.GetName` ended in
  `:gsub()`, which hands back the string AND the replacement count. Passed last
  to an INSERT it became two parameters and oxmysql refused the query — "expected
  10 parameters, but received 11", pointing at the query instead of at the name.
  A pair of brackets fixes it. `tools/check-returns.mjs` now scans every `return`
  in the resource for the same mistake.
- **The Price button stopped falling off the sheet.** Header rows wrap at 360px.

## 0.6.1

- **The tablet is a tablet.** No row of tabs across the top — a home screen of
  apps, a chevron back to it, and a dock along the bottom with Home, your duty
  state, Disconnect and Close. The bar says what the tablet is plugged into.
  The home screen gets the whole width; an empty car column was sitting on top
  of the apps and pushing them a third of the way down the screen.
- **Ride height did nothing.** It was written to `fSuspensionRaise`, which is
  HANDLING data — shared per model. It lowered every car of that model on the
  server and lowered none of them on screen until something made the vehicle
  re-read its handling. `SetVehicleSuspensionHeight` is the per-entity native
  and it takes effect immediately.
- **Performance is off the Tuning screen.** Engine, brakes, transmission,
  suspension and turbo levels live on the Performance app next to the packages
  that do the same job. Tuning is cosmetic.
- **Fitting no longer refuses over an empty shelf.** What the shop can fit, it
  fits; what it cannot becomes a work order against that car, already claimed
  by the mechanic who wrote it. Make the parts, come back, finish it.

## 0.6.0

The camera, and the shape of the thing.

- **The preview camera was flipped, and in two places.** It placed itself with
  `(-sin t, -cos t)`, which negates both components — a reflection, not a
  rotation. The angle it produced worked out to `-40 - orbit - 2h`: it moved
  with the car's world HEADING, so the same button framed a different part of
  the car depending on which way the car was parked. Spoiler to the front,
  front bumper to the rear. The live window and the tuning preview both had it.
  A camera at angle α from the nose is at `forward(h + α)` and the heading
  cancels. Views also aim fore and aft now, so an engine-bay shot frames the
  engine bay rather than the middle of the roof.
- **Tuning is not a window any more.** The car is the whole screen and the
  panel is a sheet pinned to the top left. No hole, no cutout — the same
  framing maths puts the car in the middle of everything the sheet is not
  standing on. Drag the car to turn it, double click to put it back. Stance is
  its own sheet: toggles, sliders, the car dropping as you move them.
- **The tablet has a home screen** — an app grid instead of a row of text tabs.
- **Servicing is a car with leader lines** out to what is worn, not a table.
- **Servicing was also impossible.** All nine service parts were consumable and
  obtainable nowhere: the bench had never been given a recipe for them, and the
  parts counter that used to sell them is gone. `check-craftable` reported a
  clean run because it had never been pointed at the file they live in.
- **A shop with a V8 on the shelf was refused the engine swap.** The panel and
  the client check asked about a generic "performance part" while the server
  took the package's own item off the shelf. Each package now reads its own
  part, and the count is on the card.
- **Clicking a part no longer jumps the list to the top.**
- Nitrous fed an unsigned speed into a signed one, so boosting while reversing
  turned the car round and shoved it forwards.
- The at-the-engine check measured the distance to the world origin on any
  vehicle with no bonnet bone, so it could never pass.
- Camera height used `sin` where the angle needs `tan`, so steep views never
  looked down as far as they claimed.

## 0.5.3

- **The tablet died on opening.** The price editor wrote a category's price as
  a plain number and the pricing code reads it as a table, so every shop that
  had ever had a price changed threw `attempt to index a number value` and the
  panel refused to open. Written as a table now, read tolerantly either way,
  and normalised on save so the rows already in the database fix themselves.
- **Nothing could be fitted.** Stock fell back to the mechanic's pockets when a
  shop had no storage point — which reads as zero of everything, on every shop,
  from the day it is built. A shop only runs on stock if it has a shelf to run
  it from. Place a storage point and it starts counting.
- **The live window follows what you are looking at.** Hover a spoiler and the
  camera walks round the back; a wheel and it drops to the arch; a dash and it
  looks in through the window. It eases round rather than cutting, and the
  window says which view it is showing.
- **Work happens on a bay.** Fitting a part, a performance package or a stance
  needs the mechanic stood on a tuning bay with the car on it. Reading an
  invoice or a work order does not. `Config.Tablet.insideBayOnly`.
- **Customers stop seeing the staff room.** Storage, the laptop, the bench, the
  dyno and the duty point are not registered at all for anyone who does not
  work there, rather than registered and then refused.

## 0.5.2

- **A customer driving into a bay was told to drive into a bay.** Nothing ever
  connected the car — the bay opened the panel and waited to be told which
  vehicle it was about. Whatever is sat on the bay is connected before the
  panel opens now, measured from the bay rather than from wherever the customer
  walked to. The dyno does the same and opens straight onto the dyno screen.
- **A mechanic can pick more than one thing.** Clicking a front bumper and then
  a rear bumper used to be a choice between them. Both sides of the counter now
  build a list the same way: click parts, they go on the car and stay there,
  and the list adds up. **Fit all** works through it one job at a time, each
  with its own animation and its own invoice line, and says how far it got if
  something stops it.
- **The tablet pose is stopped harder.** It is played as a secondary task, and
  a secondary task does not always come off with `StopAnimTask` alone, so it is
  cleared as well and asked again for two seconds afterwards.
- **The bench makes real parts.** Every engine swap, turbo, gearbox, brake kit,
  drivetrain, drift setup and tyre kit is its own build, and the four modkit
  upgrades — engine, brakes, transmission, suspension — are separate parts a
  shop stocks apart rather than one generic performance part. Twenty-one
  recipes, grouped into Parts, Upgrades, Engines, Drivetrain and Supplies.

## 0.5.1

- **Stancing broke cars and would not reset.** Ride height was read back off
  the car it had just changed, so once a vehicle was lowered the "stock" height
  was the lowered one and there was nothing left to put back. Factory values
  are taken once now, per vehicle, and everything is a difference from them —
  so Back to factory is a real instruction and applying a stance twice does not
  stack. Resetting saves as well as shows.
- **The live car was framed for the whole screen** and then shown through a
  window a sixth of it wide, which is why you got a close-up of one wing. The
  distance is worked out from how much of the screen the window covers and how
  big the vehicle actually is, and in a lock-up where the camera cannot back
  off far enough, the lens widens instead. The window is bigger too.
- **The tablet pose kept playing after the tablet closed.** It was stopped only
  if the game said it was playing, and it reports as not playing while it is
  still blending in. Stopped unconditionally now.
- **A part could be fitted with an empty shelf** — the shop said no after the
  mechanic had spent twelve seconds fitting it. The shelf is checked first.
- **Every kind of work has its own animation.** Welding a bumper on is not
  kneeling by a wheel.
- **The bay adds up as you go.** Clicking a part puts it on the car and on the
  order at the same time and leaves it there, so five clicks is five parts you
  can see, priced, with a running total. No add-one-at-a-time step.
- **Repairs are the job.** A customer sees what is wrong with their car and
  puts a repair on the same order; the shop does the work. The list of ways to
  fix it yourself is gone.
- **The parts counter is gone.** A mechanic shop works on cars.
- **The bench works off the shelf** — material out of storage, part back into
  storage, and the count is read back afterwards rather than trusting what the
  inventory said. It also no longer asks for an item called metal, which no
  server has.
- The bench is a solid panel over the workbench instead of a see-through one,
  with the shop's raw material across the top.

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
