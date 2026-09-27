(function () {
    const RESOURCE = 'XS-Mechanic';

    /*  In game this file loads and must do nothing, and the decision is made
        the safe way round: it runs on the hosts that serve the demo and
        nowhere else. An unrecognised host is treated as the game.

        It used to be the other way round — bail if GetParentResourceName
        exists, or if the hostname equals the resource name — and both missed.
        FiveM serves NUI from cfx-nui-xs-mechanic, which never equalled
        'xs-mechanic', and the native is not there yet when the first script
        tag runs. So neither guard fired, the fetch override below swallowed
        every NUI callback, and ROUTES.ready posted an 'open' as the page
        loaded: the tablet came up on spawn, on duty, with a demo shop and
        somebody else's name on it.  */
    const DEMO_HOSTS = /^(localhost|127\.0\.0\.1|\[::1\]|(.+\.)?xyralscripts\.dev|(.+\.)?workers\.dev)$/i;

    if (typeof GetParentResourceName === 'function') return;
    if (!DEMO_HOSTS.test(location.hostname)) return;

    window.GetParentResourceName = () => RESOURCE;

    const NOW = Math.floor(Date.now() / 1000);

    // Trimmed from shared/paint.lua — the same families and indices the
    // game uses, a slice of each so the file stays readable.
    const PAINT = [
            {
                    "id": "metallic",
                    "label": "Metallic",
                    "colours": [
                            {
                                    "id": 0,
                                    "label": "Black",
                                    "hex": "#0d1116"
                            },
                            {
                                    "id": 1,
                                    "label": "Graphite Black",
                                    "hex": "#1c1d21"
                            },
                            {
                                    "id": 2,
                                    "label": "Black Steel",
                                    "hex": "#32383d"
                            },
                            {
                                    "id": 3,
                                    "label": "Dark Silver",
                                    "hex": "#454b4f"
                            },
                            {
                                    "id": 4,
                                    "label": "Silver",
                                    "hex": "#999da0"
                            },
                            {
                                    "id": 5,
                                    "label": "Blue Silver",
                                    "hex": "#c2c4c6"
                            },
                            {
                                    "id": 6,
                                    "label": "Steel Gray",
                                    "hex": "#979a97"
                            },
                            {
                                    "id": 7,
                                    "label": "Shadow Silver",
                                    "hex": "#637380"
                            },
                            {
                                    "id": 8,
                                    "label": "Stone Silver",
                                    "hex": "#63625c"
                            },
                            {
                                    "id": 9,
                                    "label": "Midnight Silver",
                                    "hex": "#3c3f47"
                            },
                            {
                                    "id": 10,
                                    "label": "Gun Metal",
                                    "hex": "#444e54"
                            },
                            {
                                    "id": 11,
                                    "label": "Anthracite Grey",
                                    "hex": "#1d2129"
                            },
                            {
                                    "id": 27,
                                    "label": "Red",
                                    "hex": "#c00e1a"
                            },
                            {
                                    "id": 28,
                                    "label": "Torino Red",
                                    "hex": "#da1918"
                            },
                            {
                                    "id": 29,
                                    "label": "Formula Red",
                                    "hex": "#b6111b"
                            },
                            {
                                    "id": 30,
                                    "label": "Blaze Red",
                                    "hex": "#a51e23"
                            },
                            {
                                    "id": 31,
                                    "label": "Graceful Red",
                                    "hex": "#7b1a22"
                            },
                            {
                                    "id": 32,
                                    "label": "Garnet Red",
                                    "hex": "#8e1b1f"
                            }
                    ]
            },
            {
                    "id": "matte",
                    "label": "Matte",
                    "colours": [
                            {
                                    "id": 12,
                                    "label": "Black",
                                    "hex": "#13181f"
                            },
                            {
                                    "id": 13,
                                    "label": "Gray",
                                    "hex": "#26282a"
                            },
                            {
                                    "id": 14,
                                    "label": "Light Grey",
                                    "hex": "#515554"
                            },
                            {
                                    "id": 39,
                                    "label": "Red",
                                    "hex": "#cf1f21"
                            },
                            {
                                    "id": 40,
                                    "label": "Dark Red",
                                    "hex": "#732021"
                            },
                            {
                                    "id": 41,
                                    "label": "Orange",
                                    "hex": "#f27d20"
                            },
                            {
                                    "id": 42,
                                    "label": "Yellow",
                                    "hex": "#ffc91f"
                            },
                            {
                                    "id": 55,
                                    "label": "Lime Green",
                                    "hex": "#66b81f"
                            },
                            {
                                    "id": 82,
                                    "label": "Dark Blue",
                                    "hex": "#1f2852"
                            },
                            {
                                    "id": 83,
                                    "label": "Blue",
                                    "hex": "#253aa7"
                            },
                            {
                                    "id": 84,
                                    "label": "Midnight Blue",
                                    "hex": "#1c3551"
                            },
                            {
                                    "id": 128,
                                    "label": "Green",
                                    "hex": "#4e6443"
                            },
                            {
                                    "id": 129,
                                    "label": "Brown",
                                    "hex": "#bcac8f"
                            },
                            {
                                    "id": 131,
                                    "label": "White",
                                    "hex": "#fcf9f1"
                            },
                            {
                                    "id": 133,
                                    "label": "Olive Army Green",
                                    "hex": "#81844c"
                            },
                            {
                                    "id": 148,
                                    "label": "Purple",
                                    "hex": "#6b1f7b"
                            },
                            {
                                    "id": 149,
                                    "label": "Dark Purple",
                                    "hex": "#1e1d22"
                            },
                            {
                                    "id": 151,
                                    "label": "Forest Green",
                                    "hex": "#2d362a"
                            }
                    ]
            },
            {
                    "id": "metals",
                    "label": "Metals & Chrome",
                    "colours": [
                            {
                                    "id": 117,
                                    "label": "Brushed Steel",
                                    "hex": "#6a747c",
                                    "shaded": true
                            },
                            {
                                    "id": 118,
                                    "label": "Brushed Black Steel",
                                    "hex": "#354158",
                                    "shaded": true
                            },
                            {
                                    "id": 119,
                                    "label": "Brushed Aluminium",
                                    "hex": "#9ba0a8",
                                    "shaded": true
                            },
                            {
                                    "id": 120,
                                    "label": "Chrome",
                                    "hex": "#5870a1",
                                    "shaded": true
                            },
                            {
                                    "id": 158,
                                    "label": "Pure Gold",
                                    "hex": "#c9a227",
                                    "shaded": true
                            },
                            {
                                    "id": 159,
                                    "label": "Brushed Gold",
                                    "hex": "#a08a55",
                                    "shaded": true
                            }
                    ]
            },
            {
                    "id": "utility",
                    "label": "Utility",
                    "colours": [
                            {
                                    "id": 15,
                                    "label": "Black",
                                    "hex": "#151921"
                            },
                            {
                                    "id": 16,
                                    "label": "Black Poly",
                                    "hex": "#1e2429"
                            },
                            {
                                    "id": 17,
                                    "label": "Dark Silver",
                                    "hex": "#333a3c"
                            },
                            {
                                    "id": 18,
                                    "label": "Silver",
                                    "hex": "#8c9095"
                            },
                            {
                                    "id": 19,
                                    "label": "Gun Metal",
                                    "hex": "#39434d"
                            },
                            {
                                    "id": 20,
                                    "label": "Shadow Silver",
                                    "hex": "#506272"
                            },
                            {
                                    "id": 43,
                                    "label": "Red",
                                    "hex": "#9c1016"
                            },
                            {
                                    "id": 44,
                                    "label": "Bright Red",
                                    "hex": "#de0f18"
                            },
                            {
                                    "id": 56,
                                    "label": "Dark Green",
                                    "hex": "#22383e"
                            },
                            {
                                    "id": 57,
                                    "label": "Green",
                                    "hex": "#1d5a3f"
                            },
                            {
                                    "id": 75,
                                    "label": "Dark Blue",
                                    "hex": "#112552"
                            },
                            {
                                    "id": 76,
                                    "label": "Midnight Blue",
                                    "hex": "#1b203e"
                            },
                            {
                                    "id": 77,
                                    "label": "Blue",
                                    "hex": "#275190"
                            },
                            {
                                    "id": 78,
                                    "label": "Sea Foam Blue",
                                    "hex": "#608592"
                            },
                            {
                                    "id": 79,
                                    "label": "Lightning Blue",
                                    "hex": "#2446a8"
                            },
                            {
                                    "id": 80,
                                    "label": "Maui Blue Poly",
                                    "hex": "#4271e1"
                            },
                            {
                                    "id": 81,
                                    "label": "Bright Blue",
                                    "hex": "#3b39e0"
                            },
                            {
                                    "id": 108,
                                    "label": "Brown",
                                    "hex": "#3a2a1b"
                            }
                    ]
            },
            {
                    "id": "worn",
                    "label": "Worn",
                    "colours": [
                            {
                                    "id": 21,
                                    "label": "Black",
                                    "hex": "#1e232f"
                            },
                            {
                                    "id": 22,
                                    "label": "Graphite",
                                    "hex": "#363a3f"
                            },
                            {
                                    "id": 23,
                                    "label": "Silver Grey",
                                    "hex": "#a0a199"
                            },
                            {
                                    "id": 24,
                                    "label": "Silver",
                                    "hex": "#d3d3d3"
                            },
                            {
                                    "id": 25,
                                    "label": "Blue Silver",
                                    "hex": "#b7bfca"
                            },
                            {
                                    "id": 26,
                                    "label": "Shadow Silver",
                                    "hex": "#778794"
                            },
                            {
                                    "id": 46,
                                    "label": "Red",
                                    "hex": "#a94744"
                            },
                            {
                                    "id": 47,
                                    "label": "Golden Red",
                                    "hex": "#b16c51"
                            },
                            {
                                    "id": 48,
                                    "label": "Dark Red",
                                    "hex": "#371c25"
                            },
                            {
                                    "id": 58,
                                    "label": "Dark Green",
                                    "hex": "#2d423f"
                            },
                            {
                                    "id": 59,
                                    "label": "Green",
                                    "hex": "#45594b"
                            },
                            {
                                    "id": 60,
                                    "label": "Sea Wash",
                                    "hex": "#65867f"
                            },
                            {
                                    "id": 85,
                                    "label": "Dark Blue",
                                    "hex": "#4c5f81"
                            },
                            {
                                    "id": 86,
                                    "label": "Blue",
                                    "hex": "#58688e"
                            },
                            {
                                    "id": 87,
                                    "label": "Light Blue",
                                    "hex": "#74b5d8"
                            },
                            {
                                    "id": 113,
                                    "label": "Honey Beige",
                                    "hex": "#b0ab94"
                            },
                            {
                                    "id": 114,
                                    "label": "Brown",
                                    "hex": "#453831"
                            },
                            {
                                    "id": 115,
                                    "label": "Dark Brown",
                                    "hex": "#2a282b"
                            }
                    ]
            }
    ];

    function slot(id, label, category, current, names) {
        return {
            id, slot: 1, label, category, current,
            options: [{ index: -1, label: `Stock ${label}` }]
                .concat(names.map((n, i) => ({ index: i, label: n }))),
        };
    }


    const SERVICE_PARTS = [
        { id: 'engine_oil', label: 'Engine Oil', wear: 12, due: true, item: 'engine_oil', quantity: 1, lifespanKm: 400, affects: 'accel' },
        { id: 'air_filter', label: 'Air Filter', wear: 41, due: false, item: 'air_filter', quantity: 1, lifespanKm: 650, affects: 'topSpeed' },
        { id: 'spark_plugs', label: 'Spark Plugs', wear: 18, due: true, item: 'spark_plugs', quantity: 4, lifespanKm: 800, affects: 'accel' },
        { id: 'clutch', label: 'Clutch', wear: 74, due: false, item: 'clutch', quantity: 1, lifespanKm: 1200, affects: 'gearTime' },
        { id: 'brake_pads', label: 'Brake Pads', wear: 9, due: true, item: 'brake_pads', quantity: 2, lifespanKm: 700, affects: 'brake' },
        { id: 'tyres', label: 'Tyres', wear: 55, due: false, item: 'tyres', quantity: 4, lifespanKm: 900, affects: 'traction' },
        { id: 'suspension', label: 'Suspension', wear: 88, due: false, item: 'suspension_kit', quantity: 1, lifespanKm: 1600, affects: 'suspension' },
    ];

    // Matches CustomTuning.Sheet()
    const TUNING_SHEET = [
        { id: 'engineSwaps', label: 'Engine Swap', requiresItem: true, current: 'v8', options: [
            { id: 'i4', name: 'I4 Turbo 2.0', info: 'Small and revvy. Best on something light.', item: 'i4_engine', price: 18000, fitted: false },
            { id: 'v6', name: 'V6 3.5', info: 'The sensible one.', item: 'v6_engine', price: 26000, fitted: false },
            { id: 'v8', name: 'V8 6.2', info: 'Torque everywhere. Heavy over the front axle.', item: 'v8_engine', price: 42000, fitted: true },
            { id: 'v12', name: 'V12 6.5', info: 'Do not put this in a hatchback and complain.', item: 'v12_engine', price: 78000, fitted: false },
        ] },
        { id: 'drivetrains', label: 'Drivetrain', requiresItem: true, current: null, options: [
            { id: 'fwd', name: 'Front Wheel Drive', item: 'drivetrain_kit', price: 14000, fitted: false },
            { id: 'rwd', name: 'Rear Wheel Drive', item: 'drivetrain_kit', price: 14000, fitted: false },
            { id: 'awd', name: 'All Wheel Drive', info: 'Traction everywhere, a little more weight.', item: 'drivetrain_kit', price: 22000, fitted: false },
        ] },
        { id: 'turbos', label: 'Turbo', requiresItem: true, current: 'stage1', options: [
            { id: 'stage1', name: 'Stage 1 Turbo', item: 'turbo_kit', price: 20000, fitted: true },
            { id: 'stage2', name: 'Stage 2 Turbo', info: 'More boost, more heat. Service it more often.', item: 'turbo_kit', price: 38000, fitted: false },
        ] },
        { id: 'brakes', label: 'Brake Kit', requiresItem: true, current: null, options: [
            { id: 'street', name: 'Street Brakes', item: 'brake_kit', price: 9000, fitted: false },
            { id: 'track', name: 'Track Brakes', item: 'brake_kit', price: 24000, fitted: false },
        ] },
        { id: 'tyres', label: 'Tyres', requiresItem: true, current: 'sport', options: [
            { id: 'sport', name: 'Sport Tyres', item: 'tyre_kit', price: 8000, fitted: true },
            { id: 'semislick', name: 'Semi Slicks', info: 'Grippy when warm, awful in the wet.', item: 'tyre_kit', price: 19000, fitted: false },
        ] },
        { id: 'gearboxes', label: 'Gearbox', requiresItem: true, current: null, options: [
            { id: 'close', name: 'Close Ratio', item: 'gearbox_kit', price: 22000, fitted: false },
            { id: 'sequential', name: 'Sequential', info: 'Shifts fast enough to notice.', item: 'gearbox_kit', price: 46000, fitted: false },
        ] },
        { id: 'drift', label: 'Drift Tune', requiresItem: true, current: null, options: [
            { id: 'drift', name: 'Drift Setup', info: 'Loose on purpose. Not faster.', item: 'drift_kit', price: 26000, fitted: false },
        ] },
    ];

    const CATALOGUE = {
        model: 'elegy2',
        name: 'Elegy Retro Custom',
        class: 4,
        className: 'Sports',
        drive: 'RWD',
        plate: '46VSN720',
        electric: false,
        slots: [
            slot('frontBumper', 'Front Bumper', 'cosmetics', 1,
                ['Street Splitter', 'Carbon Lip', 'Vented Race', 'Wide Arch Front', 'Chin Spoiler', 'Track Diffuser']),
            slot('hood', 'Hood', 'cosmetics', -1,
                ['Vented Carbon', 'Cowl Induction', 'Race Pins', 'Clear Panel']),
            slot('exhaust', 'Exhaust', 'cosmetics', 2,
                ['Twin Tip', 'Centre Exit', 'Quad Titanium', 'Side Pipes']),
            slot('spoiler', 'Spoiler', 'cosmetics', -1,
                ['Lip Spoiler', 'Ducktail', 'GT Wing', 'Swan Neck']),
            slot('sideSkirt', 'Side Skirt', 'cosmetics', 0,
                ['Street Skirts', 'Carbon Skirts', 'Wide Arch Sides']),
            slot('rollCage', 'Roll Cage', 'cosmetics', -1, ['Half Cage', 'Full Cage']),
            slot('engine', 'Engine', 'performance', 2, ['Level 1', 'Level 2', 'Level 3', 'Level 4']),
            slot('brakes', 'Brakes', 'performance', 1, ['Level 1', 'Level 2', 'Level 3']),
            slot('transmission', 'Transmission', 'performance', -1, ['Level 1', 'Level 2', 'Level 3']),
            slot('suspension', 'Suspension', 'performance', 2, ['Level 1', 'Level 2', 'Level 3', 'Level 4']),
            slot('turbo', 'Turbo', 'performance', -1, ['Fitted']),
            slot('xenon', 'Headlights', 'lights', 0, ['Xenon']),
            slot('seats', 'Seats', 'interior', -1, ['Bucket Seats', 'Race Harness', 'Leather']),
            slot('steeringWheel', 'Steering Wheel', 'interior', 1, ['Sport', 'Dished', 'Suede', 'Wood']),
            slot('dashboard', 'Dashboard', 'interior', -1, ['Carbon Trim', 'Alcantara']),
        ],
        wheels: {
            id: 'wheels', label: 'Wheels', category: 'wheels',
            currentType: 5, current: 3, customTyres: true,
            types: [
                { type: 5, label: 'Tuner', options: [
                    { index: 0, label: 'Cosmo' }, { index: 1, label: 'Dash VIP' }, { index: 2, label: 'Fujiwara' },
                    { index: 3, label: 'Endo v1' }, { index: 4, label: 'Wangan Master' }, { index: 5, label: 'Rollas' },
                ] },
                { type: 7, label: 'High End', options: [
                    { index: 0, label: 'Shadow' }, { index: 1, label: 'Cougar' }, { index: 2, label: 'Deep Five' },
                    { index: 3, label: 'Lozspeed Mk V' },
                ] },
                { type: 1, label: 'Muscle', options: [
                    { index: 0, label: 'Classic Five' }, { index: 1, label: 'Dukes' }, { index: 2, label: 'Mecha' },
                ] },
            ],
        },
        liveries: null,
        plates: {
            id: 'plate', label: 'Plate', category: 'plate', current: 0,
            options: [
                { index: 0, label: 'Blue on White 1' }, { index: 1, label: 'Yellow on Black' },
                { index: 2, label: 'Yellow on Blue' }, { index: 3, label: 'Blue on White 2' },
                { index: 4, label: 'Blue on White 3' }, { index: 5, label: 'North Yankton' },
            ],
        },
        extras: [{ id: 1, on: true }, { id: 2, on: false }],
        neon: { sides: [], colour: { r: 0, g: 140, b: 255 } },
        paint: {
            primary: 0, secondary: 2, pearlescent: 111, wheelColour: 0,
            customPrimary: null, customSecondary: null,
            dashboard: 0, interior: 0, windowTint: 1, chameleon: null,
        },
        supportsChameleon: true,
        health: { engine: 924, body: 781, petrolTank: 1000, dirt: 4.2 },
    };

    const STATE = {
        name: 'Vincent Valentine',
        onDuty: true,
        isBoss: true,
        manageJobs: true,
        ledgerOnly: true,
        pricingMode: 'fixed',
        levelMultiplier: 0.1,
        commission: 10,
        unpaid: 2,
        openOrders: 3,
        staffOnline: 2,
        takesOrders: true,
        basket: [
            { lid: 1, category: 'cosmetics', categoryLabel: 'Cosmetics', label: 'Carbon Lip — Front Bumper', price: 2150, fitted: false, needs: 'body_part', needsLabel: 'Body Part' },
            { lid: 2, category: 'wheels', categoryLabel: 'Wheels', label: 'Endo v1', price: 750, fitted: false, needs: 'wheel_set', needsLabel: 'Wheel Set' },
            { lid: 3, category: 'performance', categoryLabel: 'Performance', label: 'Level 3 — Engine', price: 3250, fitted: true, billed: 88 },
        ],
        serviceEnabled: true,
        tuningEnabled: true,
        dynoEnabled: true,
        stanceLimits: { height: 0.30, camber: 0.35, track: 0.25 },
        settings: { accent: 'blue', hud: true, sounds: true, autoDraft: true },
        paint: PAINT,

        shop: { id: 1, name: 'Hayes Autoworks', kind: 'owned', job: 'mechanic' },

        categories: {},

        prices: {
            cosmetics: 500, wheels: 750, performance: 2500, respray: 400,
            lights: 350, interior: 400, livery: 600, extras: 250, plate: 200, repair: 1200,
        },

        summary: {
            today: 18400, jobs: 6, unpaid: 2, unpaidTotal: 9250,
            orders: 3, onDuty: 2, staff: 5, funds: 84200, earned: 1840,
        },

        staff: [
            { citizenid: 'XYR00001', name: 'Vincent Valentine', grade: 4, gradeLabel: 'Owner', onDuty: true },
            { citizenid: 'XYR00002', name: 'Marcus Webb', grade: 2, gradeLabel: 'Mechanic', onDuty: true },
            { citizenid: 'XYR00003', name: 'Dana Oyelaran', grade: 2, gradeLabel: 'Mechanic', onDuty: false },
            { citizenid: 'XYR00004', name: 'Theo Brandt', grade: 1, gradeLabel: 'Apprentice', onDuty: false },
            { citizenid: 'XYR00005', name: 'Priya Raman', grade: 3, gradeLabel: 'Foreman', onDuty: false },
        ],

        grades: [
            { level: 0, label: 'Trainee' }, { level: 1, label: 'Apprentice' },
            { level: 2, label: 'Mechanic' }, { level: 3, label: 'Foreman' }, { level: 4, label: 'Owner' },
        ],

        ledger: [
            { amount: 4300, kind: 'invoice', note: 'Invoice #1281 paid', byName: 'Marcus Webb', createdAt: NOW - 60 * 14 },
            { amount: -1200, kind: 'parts', note: 'Parts counter — 4x Tyre Kit', byName: 'Vincent Valentine', createdAt: NOW - 60 * 52 },
            { amount: 7800, kind: 'invoice', note: 'Invoice #1279 paid', byName: 'Vincent Valentine', createdAt: NOW - 60 * 130 },
            { amount: -2500, kind: 'withdraw', note: 'Withdrawn by the boss', byName: 'Vincent Valentine', createdAt: NOW - 60 * 320 },
        ],

        orders: [
            { id: 412, status: 'open', customerName: 'Ellis Ward', plate: '46VSN720',
              quote: 6150, createdAt: NOW - 60 * 9,
              requested: [
                  { lid: 4, category: 'cosmetics', categoryLabel: 'Cosmetics', label: 'Carbon Lip — Front Bumper', price: 2150, fitted: false, needs: 'body_part', needsLabel: 'Body Part' },
                  { lid: 5, category: 'cosmetics', categoryLabel: 'Cosmetics', label: 'GT Wing — Spoiler', price: 2750, fitted: false, needs: 'body_part', needsLabel: 'Body Part' },
                  { lid: 6, category: 'wheels', categoryLabel: 'Wheels', label: 'Endo v1', price: 1250, fitted: true, billed: 88, needs: 'wheel_set', needsLabel: 'Wheel Set' },
              ],
              notes: 'Wants the front end done. Not fussed on colour.' },
            { id: 411, status: 'open', customerName: 'Rosa Delgado', plate: 'KTM 8841',
              quote: 1250, createdAt: NOW - 60 * 34,
              requested: [
                  { lid: 7, category: 'wheels', categoryLabel: 'Wheels', label: 'Dash VIP', price: 1250, fitted: false, needs: 'wheel_set', needsLabel: 'Wheel Set' },
              ],
              notes: 'Bent rim on the nearside front.' },
            { id: 410, status: 'claimed', customerName: 'Aaron Pike', plate: 'LSV 2210',
              quote: 1000, createdAt: NOW - 60 * 72,
              requested: [
                  { lid: 8, category: 'respray', categoryLabel: 'Respray', label: 'Respray — Racing Blue', price: 400, fitted: false, needs: 'paint_can', needsLabel: 'Paint Can' },
                  { lid: 9, category: 'livery', categoryLabel: 'Livery', label: 'Stripes', price: 600, fitted: true, billed: 88, needs: 'vinyl_wrap', needsLabel: 'Vinyl Wrap' },
              ],
              notes: '' },
            { id: 409, status: 'done', customerName: 'Nina Brackley', plate: 'ZZR 0098',
              quote: 400, createdAt: NOW - 60 * 210,
              requested: [
                  { lid: 10, category: 'interior', categoryLabel: 'Interior', label: 'Carbon Dash', price: 400, fitted: false, needs: 'interior_part', needsLabel: 'Interior Part' },
              ],
              notes: 'Overdue on everything.' },
        ],

        canPrice: true,
        hasArea: true,

        stock: {
            shelf: true,
            categories: {
                cosmetics: 'body_part', wheels: 'wheel_set', respray: 'paint_can',
                livery: 'vinyl_wrap', lights: 'light_kit', interior: 'interior_part',
                extras: 'body_part', plate: 'plate_blank', performance: 'performance_part',
            },
            slots: {
                engine: 'engine_parts', brakes: 'brake_parts',
                transmission: 'transmission_parts', suspension: 'suspension_parts',
                turbo: 'turbo_kit',
            },
            labels: {
                body_part: 'Body Part', wheel_set: 'Wheel Set', paint_can: 'Paint Can',
                vinyl_wrap: 'Vinyl Wrap', light_kit: 'Light Kit', interior_part: 'Interior Part',
                plate_blank: 'Plate Blank', performance_part: 'Performance Part',
                engine_parts: 'Engine Parts', brake_parts: 'Brake Parts',
                transmission_parts: 'Transmission Parts', suspension_parts: 'Suspension Parts',
                turbo_kit: 'Turbo Kit',
            },
            items: {
                body_part: 6, wheel_set: 0, paint_can: 3, vinyl_wrap: 1,
                light_kit: 2, interior_part: 0, plate_blank: 4, performance_part: 2,
                engine_parts: 1, brake_parts: 0, transmission_parts: 3, suspension_parts: 4,
                turbo_kit: 2,
            },
        },



        crafting: [
            { item: 'body_part', label: 'Body Part', group: 'Parts', category: 'cosmetics', onShelf: 6, canMake: true,
              needs: [
                  { key: 'scrap', item: 'metalscrap', label: 'Scrap', need: 6, have: 22 },
                  { key: 'steel', item: 'steel', label: 'Steel', need: 4, have: 9 },
              ] },
            { item: 'wheel_set', label: 'Wheel Set', group: 'Parts', category: 'wheels', onShelf: 0, canMake: false,
              needs: [
                  { key: 'rubber', item: 'rubber', label: 'Rubber', need: 6, have: 1 },
                  { key: 'steel', item: 'steel', label: 'Steel', need: 5, have: 9 },
              ] },
            { item: 'paint_can', label: 'Paint Can', group: 'Parts', category: 'respray', onShelf: 3, canMake: true,
              needs: [
                  { key: 'scrap', item: 'metalscrap', label: 'Scrap', need: 3, have: 22 },
              ] },
            { item: 'light_kit', label: 'Light Kit', group: 'Parts', category: 'lights', onShelf: 2, canMake: false,
              needs: [
                  { key: 'glass', item: 'glass', label: 'Glass', need: 4, have: 2 },
                  { key: 'scrap', item: 'metalscrap', label: 'Scrap', need: 3, have: 22 },
              ] },
            { item: 'engine_parts', label: 'Engine Parts', group: 'Upgrades', onShelf: 1, canMake: true,
              needs: [
                  { key: 'steel', item: 'steel', label: 'Steel', need: 7, have: 9 },
                  { key: 'scrap', item: 'metalscrap', label: 'Scrap', need: 5, have: 22 },
              ] },
            { item: 'brake_parts', label: 'Brake Parts', group: 'Upgrades', onShelf: 0, canMake: true,
              needs: [
                  { key: 'steel', item: 'steel', label: 'Steel', need: 5, have: 9 },
                  { key: 'scrap', item: 'metalscrap', label: 'Scrap', need: 3, have: 22 },
              ] },
            { item: 'suspension_parts', label: 'Suspension Parts', group: 'Upgrades', onShelf: 4, canMake: false,
              needs: [
                  { key: 'steel', item: 'steel', label: 'Steel', need: 6, have: 9 },
                  { key: 'rubber', item: 'rubber', label: 'Rubber', need: 3, have: 1 },
              ] },
            { item: 'v8_engine', label: 'V8 6.2', group: 'Engines', onShelf: 0, canMake: false,
              needs: [
                  { key: 'steel', item: 'steel', label: 'Steel', need: 20, have: 9 },
                  { key: 'scrap', item: 'metalscrap', label: 'Scrap', need: 15, have: 22 },
                  { key: 'rubber', item: 'rubber', label: 'Rubber', need: 4, have: 1 },
              ] },
            { item: 'i4_engine', label: 'I4 Turbo 2.0', group: 'Engines', onShelf: 1, canMake: false,
              needs: [
                  { key: 'steel', item: 'steel', label: 'Steel', need: 10, have: 9 },
                  { key: 'scrap', item: 'metalscrap', label: 'Scrap', need: 8, have: 22 },
                  { key: 'rubber', item: 'rubber', label: 'Rubber', need: 2, have: 1 },
              ] },
            { item: 'turbo_kit', label: 'Turbo Kit', group: 'Drivetrain', onShelf: 2, canMake: true,
              needs: [
                  { key: 'steel', item: 'steel', label: 'Steel', need: 9, have: 9 },
                  { key: 'scrap', item: 'metalscrap', label: 'Scrap', need: 6, have: 22 },
              ] },
            { item: 'gearbox_kit', label: 'Gearbox Kit', group: 'Drivetrain', onShelf: 0, canMake: false,
              needs: [
                  { key: 'steel', item: 'steel', label: 'Steel', need: 12, have: 9 },
                  { key: 'scrap', item: 'metalscrap', label: 'Scrap', need: 8, have: 22 },
                  { key: 'rubber', item: 'rubber', label: 'Rubber', need: 2, have: 1 },
              ] },
            { item: 'repair_kit', label: 'Repair Kit', group: 'Supplies', onShelf: 5, canMake: true,
              needs: [
                  { key: 'scrap', item: 'metalscrap', label: 'Scrap', need: 5, have: 22 },
                  { key: 'steel', item: 'steel', label: 'Steel', need: 3, have: 9 },
                  { key: 'rubber', item: 'rubber', label: 'Rubber', need: 1, have: 1 },
              ] },
        ],

        invoices: [
            { id: 1284, status: 'draft', customerName: 'Ellis Ward', plate: '46VSN720', total: 11850,
              mechanicName: 'Vincent Valentine', createdAt: NOW - 60 * 4, items: [
                { label: 'Carbon Lip', category: 'Cosmetics · Front Bumper', amount: 2150 },
                { label: 'Quad Titanium', category: 'Cosmetics · Exhaust', amount: 1800 },
                { label: 'Engine Level 3', category: 'Performance', amount: 6500 },
                { label: 'Brake Pads', category: 'Service · Replaced', amount: 900 },
                { label: 'Labour', note: 'Added by mechanic', amount: 500 },
              ] },
            { id: 1283, status: 'sent', customerName: 'Rosa Delgado', plate: 'KTM 8841', total: 5400,
              mechanicName: 'Marcus Webb', createdAt: NOW - 60 * 41, items: [
                { label: 'Full repair', category: 'Repair', amount: 1200 },
                { label: 'Endo v1', category: 'Wheels', amount: 4200 },
              ] },
            { id: 1282, status: 'sent', customerName: 'Aaron Pike', plate: 'LSV 2210', total: 3850,
              mechanicName: 'Vincent Valentine', createdAt: NOW - 60 * 95, items: [
                { label: 'Respray — Racing Blue', category: 'Respray', amount: 400 },
                { label: 'Suspension Level 3', category: 'Performance', amount: 3450 },
              ] },
            { id: 1281, status: 'paid', customerName: 'Nina Brackley', plate: 'ZZR 0098', total: 4300,
              mechanicName: 'Marcus Webb', createdAt: NOW - 60 * 190, items: [
                { label: 'Engine Level 2', category: 'Performance', amount: 4300 },
              ] },
        ],

        invoice: {
            id: 1284, total: 11850, items: [
                { label: 'Carbon Lip', category: 'Cosmetics · Front Bumper', amount: 2150 },
                { label: 'Quad Titanium', category: 'Cosmetics · Exhaust', amount: 1800 },
                { label: 'Engine Level 3', category: 'Performance', amount: 6500 },
                { label: 'Brake Pads', category: 'Service · Replaced', amount: 900 },
                { label: 'Labour', note: 'Added by mechanic', amount: 500 },
            ],
        },

        vehicle: {
            plate: '46VSN720', model: 'elegy2', name: 'Elegy Retro Custom',
            className: 'Sports', drive: 'RWD', electric: false,
            owner: 'Ellis Ward', odometer: 4812, output: 412, outputPercent: 71,
            health: { engine: 924, body: 781, petrolTank: 1000, dirt: 4.2 },
            service: { due: 3, parts: SERVICE_PARTS },
            tuning: TUNING_SHEET,
            performance: { engineSwaps: 'v8', turbos: 'stage1', tyres: 'sport' },
            stance: { height: -0.06, fl: { camber: -0.12, track: 0.04 }, fr: { camber: -0.12, track: 0.04 },
                      rl: { camber: -0.18, track: 0.06 }, rr: { camber: -0.18, track: 0.06 } },
        },

        catalogue: CATALOGUE,

        shops: [
            { id: 1, name: 'Hayes Autoworks', kind: 'owned', job: 'mechanic', enabled: true },
            { id: 2, name: 'Paleto Auto Repair', kind: 'owned', job: 'paletomech', enabled: true },
            { id: 3, name: 'Sandy Shores Bay', kind: 'self', job: '', enabled: false },
        ],
    };

    const DYNO = {
        state: 'done',
        peak: 486,
        plate: '46VSN720',
        name: 'Elegy Retro Custom',
        points: [{ hp: 39, torque: 31, rpm: 1233 }, { hp: 76, torque: 62, rpm: 1467 }, { hp: 113, torque: 91, rpm: 1700 }, { hp: 148, torque: 120, rpm: 1933 }, { hp: 182, torque: 147, rpm: 2167 }, { hp: 215, torque: 173, rpm: 2400 }, { hp: 245, torque: 198, rpm: 2633 }, { hp: 273, torque: 220, rpm: 2867 }, { hp: 299, torque: 241, rpm: 3100 }, { hp: 323, torque: 261, rpm: 3333 }, { hp: 344, torque: 278, rpm: 3567 }, { hp: 363, torque: 293, rpm: 3800 }, { hp: 379, torque: 306, rpm: 4033 }, { hp: 393, torque: 317, rpm: 4267 }, { hp: 403, torque: 325, rpm: 4500 }, { hp: 411, torque: 331, rpm: 4733 }, { hp: 416, torque: 336, rpm: 4967 }, { hp: 418, torque: 337, rpm: 5200 }, { hp: 418, torque: 337, rpm: 5433 }, { hp: 415, torque: 334, rpm: 5667 }, { hp: 409, torque: 330, rpm: 5900 }, { hp: 400, torque: 323, rpm: 6133 }, { hp: 389, torque: 314, rpm: 6367 }, { hp: 376, torque: 304, rpm: 6600 }, { hp: 361, torque: 291, rpm: 6833 }, { hp: 343, torque: 277, rpm: 7067 }, { hp: 324, torque: 261, rpm: 7300 }, { hp: 303, torque: 244, rpm: 7533 }, { hp: 280, torque: 226, rpm: 7767 }, { hp: 256, torque: 207, rpm: 8000 }],
        stats: { hp: 486, torque: 392, mass: 1450, gears: 6, topSpeed: 189 },
    };

    const HUD = {
        shop: 'Hayes Autoworks',
        plate: '46VSN720',
        rows: [
            { k: 'Vehicle', v: 'Elegy Retro' },
            { k: 'Engine', v: '92%', percent: 92 },
            { k: 'Body', v: '78%', percent: 78, track: 't-warn' },
            { k: 'Service', v: '3 DUE', tone: 'bad' },
            { k: 'Draft', v: '$11,850' },
        ],
    };

    const ROUTES = {
        ready: () => {
            setTimeout(() => {
                window.postMessage({ action: 'open', mode: 'tablet', state: STATE }, '*');
                window.postMessage({ action: 'hud', hud: HUD }, '*');
                window.postMessage({ action: 'dyno', ...DYNO }, '*');
            }, 60);
            return {};
        },
        close: () => ({}),
        settings: () => ({}),
        preview: () => ({}),
        cancelPreview: () => { STATE.previewing = null; return {}; },
        apply: () => ({}),
    };

    const realFetch = window.fetch.bind(window);

    window.fetch = function (target, options) {
        const url = String(target || '');

        if (!url.toLowerCase().includes(`${RESOURCE.toLowerCase()}/`)) {
            return realFetch(target, options);
        }

        const endpoint = url.split('/').pop();
        const handler = ROUTES[endpoint];
        const payload = handler ? handler(JSON.parse(options?.body || '{}')) : {};

        return Promise.resolve(new Response(JSON.stringify(payload ?? {}), {
            headers: { 'Content-Type': 'application/json' },
        }));
    };

    document.body.classList.add('standalone');
})();
