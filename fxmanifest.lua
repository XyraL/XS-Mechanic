fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'XS-Mechanic'
author 'XyraL'
description 'Mechanic shops for QBox/QBCore. Build them in game, tune off the vehicle itself, bill the customer.'
version '0.2.0'

-- Works on QBox (qbx_core) OR QBCore (qb-core). The bridge auto-detects.
-- Inventory, target, vehicle keys, banking and phone are all auto-detected too
-- and every one of them is optional. See Config.Bridges.
dependencies {
    'ox_lib',
    'oxmysql',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/util.lua',
    'shared/mods.lua',
    'shared/tuning.lua',
    'shared/service.lua',
}

client_scripts {
    'bridge/framework.lua',
    'bridge/inventory.lua',
    'bridge/target.lua',
    'client/main.lua',
    -- After main.lua: these read the state it owns.
    'client/catalogue.lua',
    'client/placement.lua',
    'client/preview.lua',
    'client/stance.lua',
    'client/perf.lua',
    'client/service.lua',
    'client/dyno.lua',
    'client/extras.lua',
    'client/repair.lua',
    'client/orders.lua',
    'client/lift.lua',
    'client/zones.lua',
    'client/builder.lua',
    'client/hud.lua',
    'client/ui.lua',
    -- Last: stubs anything above that failed to load, so one missing file
    -- switches a feature off instead of taking the resource down.
    'client/fallbacks.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/framework.lua',
    'bridge/inventory.lua',
    'bridge/banking.lua',
    'bridge/phone.lua',
    'server/db.lua',
    'server/store.lua',
    'server/discord.lua',
    'server/pricing.lua',
    'server/vehicles.lua',
    'server/service.lua',
    'server/tuning.lua',
    'server/invoices.lua',
    'server/orders.lua',
    'server/team.lua',
    'server/net.lua',
    'server/commands.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/mock.js',
    'html/js/core.js',
    'html/js/app.js',
    'html/js/hud.js',
    'html/js/panels/vehicle.js',
    'html/js/panels/tuning.js',
    'html/js/panels/repairs.js',
    'html/js/panels/invoices.js',
    'html/js/panels/parts.js',
    'html/js/panels/orders.js',
    'html/js/panels/service.js',
    'html/js/panels/performance.js',
    'html/js/panels/dyno.js',
    'html/js/panels/home.js',
    'html/js/panels/team.js',
    'html/js/panels/settings.js',
    'html/js/panels/builder.js',
}
