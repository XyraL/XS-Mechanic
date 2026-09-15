(function () {
    const RESOURCE = 'XS-Mechanic';

    // In game this file loads but must do nothing. GetParentResourceName is the
    // real signal; the hostname check is a backstop and both sides are folded
    // to lower case, because the browser lowercases the URL host while the
    // native returns the resource's real casing.
    if (typeof GetParentResourceName === 'function') return;
    if (location.hostname.toLowerCase() === RESOURCE.toLowerCase()) return;

    window.GetParentResourceName = () => RESOURCE;

    const NOW = Math.floor(Date.now() / 1000);

    const COLOURS = [
        { id: 0, label: 'Black', hex: '#0d0d0d' }, { id: 1, label: 'Graphite', hex: '#1c1c1e' },
        { id: 2, label: 'Anthracite', hex: '#26282b' }, { id: 3, label: 'Steel', hex: '#3d4249' },
        { id: 4, label: 'Silver', hex: '#9ba1a8' }, { id: 5, label: 'Bluish Silver', hex: '#aab6c4' },
        { id: 27, label: 'Red', hex: '#c00e1a' }, { id: 28, label: 'Torino Red', hex: '#da1918' },
        { id: 36, label: 'Orange', hex: '#f78616' }, { id: 38, label: 'Gold', hex: '#c2a661' },
        { id: 49, label: 'Dark Green', hex: '#132428' }, { id: 53, label: 'Lime', hex: '#aad13a' },
        { id: 64, label: 'Navy', hex: '#222e46' }, { id: 70, label: 'Ultra Blue', hex: '#224faa' },
        { id: 73, label: 'Racing Blue', hex: '#2c5f9a' }, { id: 88, label: 'Yellow', hex: '#f1d80a' },
        { id: 111, label: 'White', hex: '#ffffff' }, { id: 132, label: 'Chameleon', hex: '#7c5cd6' },
    ];

    function slot(id, label, category, current, names) {
        return {
            id, slot: 1, label, category, current,
            options: [{ index: -1, label: `Stock ${label}` }]
                .concat(names.map((n, i) => ({ index: i, label: n }))),
        };
    }

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
        partsPaidBy: 'society',
        pricingMode: 'fixed',
        levelMultiplier: 0.1,
        commission: 10,
        unpaid: 2,
        openOrders: 3,
        serviceEnabled: true,
        canLift: true,
        lifted: false,
        settings: { accent: 'amber', hud: true, sounds: true, autoDraft: true },
        colours: COLOURS,

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

        counters: [
            { id: 'c1', label: 'Front counter', near: true, items: [
                { item: 'repair_kit', label: 'Repair Kit', price: 850 },
                { item: 'advanced_repair_kit', label: 'Advanced Repair Kit', price: 2200 },
                { item: 'duct_tape', label: 'Duct Tape', price: 120 },
                { item: 'tyre_kit', label: 'Tyre Kit', price: 1400 },
                { item: 'performance_part', label: 'Performance Part', price: 3500 },
            ] },
            { id: 'c2', label: 'Back store', near: false, items: [
                { item: 'engine_oil', label: 'Engine Oil', price: 180 },
                { item: 'brake_pads', label: 'Brake Pads', price: 900 },
            ] },
        ],

        kits: [
            { item: 'repair_kit', label: 'Repair Kit', engine: 100, held: 2 },
            { item: 'advanced_repair_kit', label: 'Advanced Repair Kit', engine: 100, held: 0 },
            { item: 'duct_tape', label: 'Duct Tape', engine: 35, held: 5 },
        ],

        orders: [
            { id: 412, status: 'open', customerName: 'Ellis Ward', plate: '46VSN720',
              requested: ['Cosmetics', 'Performance'], quote: 0, createdAt: NOW - 60 * 9,
              notes: 'Wants the front end done and the engine stepped up. Not fussed on colour.' },
            { id: 411, status: 'open', customerName: 'Rosa Delgado', plate: 'KTM 8841',
              requested: ['Wheels'], quote: 0, createdAt: NOW - 60 * 34,
              notes: 'Bent rim on the nearside front.' },
            { id: 410, status: 'claimed', customerName: 'Aaron Pike', plate: 'LSV 2210',
              requested: ['Respray', 'Livery'], quote: 5200, createdAt: NOW - 60 * 72, notes: '' },
            { id: 409, status: 'done', customerName: 'Nina Brackley', plate: 'ZZR 0098',
              requested: ['Service'], quote: 2100, createdAt: NOW - 60 * 210,
              notes: 'Overdue on everything.' },
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
            service: { due: 3 },
        },

        catalogue: CATALOGUE,

        shops: [
            { id: 1, name: 'Hayes Autoworks', kind: 'owned', job: 'mechanic', enabled: true },
            { id: 2, name: 'Paleto Auto Repair', kind: 'owned', job: 'paletomech', enabled: true },
            { id: 3, name: 'Sandy Shores Bay', kind: 'self', job: '', enabled: false },
        ],
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
