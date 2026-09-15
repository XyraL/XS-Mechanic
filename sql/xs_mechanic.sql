-- Optional. The resource creates all of this on first start; this file is here
-- for anyone who would rather import it themselves.

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

-- `items` and not `lines`: LINES is reserved in MariaDB.
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

-- Only used when no banking resource was found.
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

CREATE TABLE IF NOT EXISTS `xs_mechanic_players` (
    `citizenid` VARCHAR(64) NOT NULL,
    `settings` LONGTEXT NULL,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
