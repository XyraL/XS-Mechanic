DB = { ready = false }

--[[ The schema provisions itself on start, so importing the sql file is
     optional. Every statement is CREATE TABLE IF NOT EXISTS, so an existing
     install is left alone, and columns added after a release are applied
     separately below — IF NOT EXISTS on the table does nothing for a table
     that already exists with fewer columns. ]]

local TABLES = {
    [[
        CREATE TABLE IF NOT EXISTS `xs_mechanic_shops` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(64) NOT NULL,
            `kind` VARCHAR(16) NOT NULL DEFAULT 'owned',
            `job` VARCHAR(64) NOT NULL DEFAULT '',
            `boss_grade` INT NOT NULL DEFAULT 3,
            `accent` VARCHAR(16) NOT NULL DEFAULT 'blue',
            `enabled` TINYINT(1) NOT NULL DEFAULT 1,
            `data` LONGTEXT NULL,
            `created_by` VARCHAR(64) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `job` (`job`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
        CREATE TABLE IF NOT EXISTS `xs_mechanic_vehicles` (
            `plate` VARCHAR(12) NOT NULL,
            `model` VARCHAR(64) NOT NULL DEFAULT '',
            `odometer` DOUBLE NOT NULL DEFAULT 0,
            `service` LONGTEXT NULL,
            `performance` LONGTEXT NULL,
            `stance` LONGTEXT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    -- `items` and not `lines`: LINES is reserved in MariaDB and belongs to
    -- LOAD DATA, so an unquoted SELECT naming it dies pointing at the NEXT
    -- column, which sends you looking in entirely the wrong place.
    [[
        CREATE TABLE IF NOT EXISTS `xs_mechanic_invoices` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `shop_id` INT UNSIGNED NOT NULL,
            `mechanic` VARCHAR(64) NOT NULL DEFAULT '',
            `mechanic_name` VARCHAR(96) NOT NULL DEFAULT '',
            `customer` VARCHAR(64) NOT NULL DEFAULT '',
            `customer_name` VARCHAR(96) NOT NULL DEFAULT '',
            `plate` VARCHAR(12) NOT NULL DEFAULT '',
            `items` LONGTEXT NULL,
            `total` INT NOT NULL DEFAULT 0,
            `status` VARCHAR(16) NOT NULL DEFAULT 'draft',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `paid_at` TIMESTAMP NULL,
            PRIMARY KEY (`id`),
            KEY `shop_id` (`shop_id`),
            KEY `customer` (`customer`),
            KEY `status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
        CREATE TABLE IF NOT EXISTS `xs_mechanic_orders` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `shop_id` INT UNSIGNED NOT NULL,
            `customer` VARCHAR(64) NOT NULL DEFAULT '',
            `customer_name` VARCHAR(96) NOT NULL DEFAULT '',
            `plate` VARCHAR(12) NOT NULL DEFAULT '',
            `model` VARCHAR(64) NOT NULL DEFAULT '',
            `requested` LONGTEXT NULL,
            `notes` TEXT NULL,
            `status` VARCHAR(16) NOT NULL DEFAULT 'open',
            `quote` INT NOT NULL DEFAULT 0,
            `claimed_by` VARCHAR(64) NULL,
            `claimed_name` VARCHAR(96) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `shop_id` (`shop_id`),
            KEY `status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    -- Only used when no banking resource was found. A shop with real society
    -- banking never writes a row here.
    [[
        CREATE TABLE IF NOT EXISTS `xs_mechanic_ledger` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `shop_id` INT UNSIGNED NOT NULL,
            `amount` INT NOT NULL DEFAULT 0,
            `kind` VARCHAR(24) NOT NULL DEFAULT 'other',
            `note` VARCHAR(160) NOT NULL DEFAULT '',
            `by_name` VARCHAR(96) NOT NULL DEFAULT '',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `shop_id` (`shop_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
        CREATE TABLE IF NOT EXISTS `xs_mechanic_players` (
            `citizenid` VARCHAR(64) NOT NULL,
            `settings` LONGTEXT NULL,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
}

local function hasColumn(table_, column)
    local row = MySQL.single.await([[
        SELECT COLUMN_NAME FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { table_, column })

    return row ~= nil
end

-- Columns added after the first release go here, not into the CREATE above.
local COLUMNS = {
    -- { 'xs_mechanic_shops', 'example', 'ALTER TABLE `xs_mechanic_shops` ADD COLUMN `example` INT NOT NULL DEFAULT 0' },
}

function DB.Ensure()
    if DB.ready then return true end

    for _, statement in ipairs(TABLES) do
        local ok, err = pcall(function() MySQL.query.await(statement) end)

        if not ok then
            print(('^1[XS-Mechanic]^0 could not create a table: %s'):format(err))
            return false
        end
    end

    for _, entry in ipairs(COLUMNS) do
        local table_, column, statement = entry[1], entry[2], entry[3]

        if not hasColumn(table_, column) then
            local ok, err = pcall(function() MySQL.query.await(statement) end)
            if ok then
                print(('^2[XS-Mechanic]^0 added %s.%s'):format(table_, column))
            else
                print(('^1[XS-Mechanic]^0 could not add %s.%s: %s'):format(table_, column, err))
            end
        end
    end

    DB.ready = true
    return true
end
