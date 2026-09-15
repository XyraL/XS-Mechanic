Tuning = {}

--[[ Custom tuning: the things stock GTA has no mod slot for.

     Every option here changes the vehicle's HANDLING, which is where the risk
     lives. The defaults below are tuned against the vanilla vehicles. An addon
     car with an unbalanced handling file can come out SLOWER after a swap,
     because these values overwrite fields the addon had inflated to compensate
     for something else it got wrong. That is not a bug in the swap — it is the
     handling file. Either fix the vehicle or blacklist it.

     handlingOverwrites = true  replaces the value outright
     handlingOverwrites = false adds to whatever the vehicle already had
     applyOrder                 lower numbers apply first, for overlapping fields
     restricted                 'combustion', 'electric' or nil for anything
     blacklist                  spawn codes that may never take this option ]]

Tuning.Categories = {
    { id = 'engineSwaps', label = 'Engine Swap', slot = 'engine' },
    { id = 'drivetrains', label = 'Drivetrain',  slot = 'drivetrain' },
    { id = 'turbos',      label = 'Turbo',       slot = 'turbo' },
    { id = 'brakes',      label = 'Brake Kit',   slot = 'brakes' },
    { id = 'tyres',       label = 'Tyres',       slot = 'tyres' },
    { id = 'gearboxes',   label = 'Gearbox',     slot = 'gearbox' },
    { id = 'drift',       label = 'Drift Tune',  slot = 'drift' },
}

Tuning.Options = {
    engineSwaps = {
        {
            id = 'i4',
            name = 'I4 Turbo 2.0',
            info = 'Small and revvy. Best on something light.',
            item = 'i4_engine',
            price = 18000,
            audio = 'FUTO',
            restricted = 'combustion',
            applyOrder = 1,
            handlingOverwrites = true,
            handling = {
                fInitialDriveForce = 0.33,
                fDriveInertia = 1.25,
                fInitialDriveMaxFlatVel = 155.0,
                fClutchChangeRateScaleUpShift = 3.2,
                fClutchChangeRateScaleDownShift = 3.2,
            },
        },
        {
            id = 'v6',
            name = 'V6 3.5',
            info = 'The sensible one.',
            item = 'v6_engine',
            price = 26000,
            audio = 'SULTAN',
            restricted = 'combustion',
            applyOrder = 1,
            handlingOverwrites = true,
            handling = {
                fInitialDriveForce = 0.37,
                fDriveInertia = 1.15,
                fInitialDriveMaxFlatVel = 168.0,
                fClutchChangeRateScaleUpShift = 2.8,
                fClutchChangeRateScaleDownShift = 2.8,
            },
        },
        {
            id = 'v8',
            name = 'V8 6.2',
            info = 'Torque everywhere. Heavy over the front axle.',
            item = 'v8_engine',
            price = 42000,
            audio = 'DOMINATOR',
            restricted = 'combustion',
            applyOrder = 1,
            handlingOverwrites = true,
            handling = {
                fInitialDriveForce = 0.42,
                fDriveInertia = 1.05,
                fInitialDriveMaxFlatVel = 182.0,
                fClutchChangeRateScaleUpShift = 2.4,
                fClutchChangeRateScaleDownShift = 2.4,
            },
        },
        {
            id = 'v12',
            name = 'V12 6.5',
            info = 'Do not put this in a hatchback and complain.',
            item = 'v12_engine',
            price = 78000,
            audio = 'ADDER',
            restricted = 'combustion',
            applyOrder = 1,
            handlingOverwrites = true,
            handling = {
                fInitialDriveForce = 0.48,
                fDriveInertia = 0.95,
                fInitialDriveMaxFlatVel = 205.0,
                fClutchChangeRateScaleUpShift = 2.1,
                fClutchChangeRateScaleDownShift = 2.1,
            },
        },
        {
            id = 'ev',
            name = 'Electric Motor',
            info = 'Instant torque, no gears to speak of.',
            item = 'electric_motor',
            price = 65000,
            audio = 'VOLTIC',
            restricted = 'electric',
            applyOrder = 1,
            handlingOverwrites = true,
            handling = {
                fInitialDriveForce = 0.46,
                fDriveInertia = 1.6,
                fInitialDriveMaxFlatVel = 190.0,
            },
        },
    },

    drivetrains = {
        {
            id = 'fwd', name = 'Front Wheel Drive', item = 'drivetrain_kit', price = 14000,
            applyOrder = 2, handlingOverwrites = true,
            handling = { fDriveBiasFront = 1.0 },
        },
        {
            id = 'rwd', name = 'Rear Wheel Drive', item = 'drivetrain_kit', price = 14000,
            applyOrder = 2, handlingOverwrites = true,
            handling = { fDriveBiasFront = 0.0 },
        },
        {
            id = 'awd', name = 'All Wheel Drive', item = 'drivetrain_kit', price = 22000,
            info = 'Traction everywhere, a little more weight.',
            applyOrder = 2, handlingOverwrites = true,
            handling = { fDriveBiasFront = 0.5 },
        },
    },

    turbos = {
        {
            id = 'stage1', name = 'Stage 1 Turbo', item = 'turbo_kit', price = 20000,
            applyOrder = 3, handlingOverwrites = false,
            handling = { fInitialDriveForce = 0.04, fInitialDriveMaxFlatVel = 8.0 },
        },
        {
            id = 'stage2', name = 'Stage 2 Turbo', item = 'turbo_kit', price = 38000,
            info = 'More boost, more heat. Service it more often.',
            applyOrder = 3, handlingOverwrites = false,
            handling = { fInitialDriveForce = 0.08, fInitialDriveMaxFlatVel = 15.0 },
        },
    },

    brakes = {
        {
            id = 'street', name = 'Street Brakes', item = 'brake_kit', price = 9000,
            applyOrder = 4, handlingOverwrites = false,
            handling = { fBrakeForce = 0.15 },
        },
        {
            id = 'track', name = 'Track Brakes', item = 'brake_kit', price = 24000,
            applyOrder = 4, handlingOverwrites = false,
            handling = { fBrakeForce = 0.35, fBrakeBiasFront = 0.02 },
        },
    },

    tyres = {
        {
            id = 'sport', name = 'Sport Tyres', item = 'tyre_kit', price = 8000,
            applyOrder = 5, handlingOverwrites = false,
            handling = { fTractionCurveMax = 0.15, fTractionCurveMin = 0.12 },
        },
        {
            id = 'semislick', name = 'Semi Slicks', item = 'tyre_kit', price = 19000,
            info = 'Grippy when warm, awful in the wet.',
            applyOrder = 5, handlingOverwrites = false,
            handling = { fTractionCurveMax = 0.30, fTractionCurveMin = 0.24, fTractionLossMult = -0.05 },
        },
    },

    gearboxes = {
        {
            id = 'close', name = 'Close Ratio', item = 'gearbox_kit', price = 22000,
            applyOrder = 6, handlingOverwrites = false,
            handling = { fClutchChangeRateScaleUpShift = 1.2, fClutchChangeRateScaleDownShift = 1.2 },
        },
        {
            id = 'sequential', name = 'Sequential', item = 'gearbox_kit', price = 46000,
            info = 'Shifts fast enough to notice.',
            applyOrder = 6, handlingOverwrites = false,
            handling = { fClutchChangeRateScaleUpShift = 2.5, fClutchChangeRateScaleDownShift = 2.5 },
            gears = 6,
        },
    },

    drift = {
        {
            id = 'drift', name = 'Drift Setup', item = 'drift_kit', price = 26000,
            info = 'Loose on purpose. Not faster.',
            applyOrder = 7, handlingOverwrites = false,
            handling = {
                fTractionCurveMax = -0.25,
                fTractionCurveMin = -0.35,
                fTractionCurveLateral = -2.0,
                fDriveBiasFront = 0.0,
            },
        },
    },
}

Tuning.ById = {}

for category, options in pairs(Tuning.Options) do
    for _, option in ipairs(options) do
        option.category = category
        Tuning.ById[('%s:%s'):format(category, option.id)] = option
    end
end

function Tuning.Get(category, id)
    return Tuning.ById[('%s:%s'):format(category, id)]
end

function Tuning.Allowed(option, model, electric)
    if not option then return false end

    if option.restricted == 'electric' and not electric then return false end
    if option.restricted == 'combustion' and electric then return false end

    for _, blocked in ipairs(option.blacklist or {}) do
        if string.lower(blocked) == string.lower(model or '') then return false end
    end

    return true
end

-- Everything fitted, sorted so overlapping handling fields land in a
-- predictable order rather than whichever way pairs() happened to walk.
function Tuning.Ordered(fitted)
    local out = {}

    for category, id in pairs(fitted or {}) do
        local option = Tuning.Get(category, id)
        if option then out[#out + 1] = option end
    end

    table.sort(out, function(a, b)
        return (a.applyOrder or 50) < (b.applyOrder or 50)
    end)

    return out
end
