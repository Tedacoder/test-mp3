CREATE TABLE IF NOT EXISTS `player_vehicles` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) DEFAULT NULL,
    `plate` VARCHAR(15) NOT NULL,
    `vin` VARCHAR(50) DEFAULT NULL,
    `model` VARCHAR(50) NOT NULL,
    `hash` VARCHAR(50) DEFAULT NULL,
    `garage` VARCHAR(50) DEFAULT 'street',
    `state` INT DEFAULT 1,
    `mods` LONGTEXT DEFAULT NULL,
    `damage` LONGTEXT DEFAULT NULL,
    `fuel` FLOAT DEFAULT 100.0,
    `coords` LONGTEXT DEFAULT NULL,
    `heading` FLOAT DEFAULT 0.0,
    `engine_health` FLOAT DEFAULT 1000.0,
    `body_health` FLOAT DEFAULT 1000.0,
    `locked` TINYINT(1) DEFAULT 1,
    `stolen` TINYINT(1) DEFAULT 0,
    `impounded` TINYINT(1) DEFAULT 0,
    `impound_fee` INT DEFAULT 0,
    `finance_balance` INT DEFAULT 0,
    `finance_payment` INT DEFAULT 0,
    `finance_missed` INT DEFAULT 0,
    `insurance_tier` VARCHAR(20) DEFAULT 'Basic',
    PRIMARY KEY (`id`),
    UNIQUE KEY `plate` (`plate`),
    UNIQUE KEY `vin` (`vin`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `vehicle_keys` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(15) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `is_primary` TINYINT(1) DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `plate` (`plate`),
    KEY `citizenid` (`citizenid`),
    FOREIGN KEY (`plate`) REFERENCES `player_vehicles`(`plate`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dealership_stock` (
    `plate` VARCHAR(15) NOT NULL,
    `price` INT NOT NULL,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
