-- Create dealership stock
CREATE TABLE IF NOT EXISTS `dealership_stock` (
    `plate` VARCHAR(15) NOT NULL,
    `price` INT NOT NULL,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create vehicle keys table
CREATE TABLE IF NOT EXISTS `vehicle_keys` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(15) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `is_primary` TINYINT(1) DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `plate` (`plate`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add required columns to player_vehicles safely (assuming it already exists from qbx_core)
-- We use a stored procedure trick or just raw ALTERS with IF NOT EXISTS logic in MariaDB/MySQL 10.3+
-- Since some MySQL versions do not support ADD COLUMN IF NOT EXISTS easily, we will do it via server lua script or basic ALTER and suppress errors, but basic ALTERs usually work if we do it cleanly.

ALTER TABLE `player_vehicles`
    ADD COLUMN IF NOT EXISTS `vin` VARCHAR(50) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `locked` TINYINT(1) DEFAULT 1,
    ADD COLUMN IF NOT EXISTS `stolen` TINYINT(1) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `impounded` TINYINT(1) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `impound_fee` INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `finance_balance` INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `finance_payment` INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `finance_missed` INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `insurance_tier` VARCHAR(20) DEFAULT 'Basic';
