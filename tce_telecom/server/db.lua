-- server/db.lua
-- Initialize the Database schema

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `telecom_devices` (
            `imei` VARCHAR(50) PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `brand` VARCHAR(20) NOT NULL, -- 'itones', 'star', 'landline'
            `phone_number` VARCHAR(20) NOT NULL,
            `insurance_active` BOOLEAN DEFAULT 0,
            `insurance_due_date` DATETIME DEFAULT NULL,
            `is_unlisted` BOOLEAN DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS `telecom_contacts` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `imei` VARCHAR(50) NOT NULL,
            `name` VARCHAR(50) NOT NULL,
            `number` VARCHAR(20) NOT NULL,
            FOREIGN KEY (`imei`) REFERENCES `telecom_devices`(`imei`) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS `telecom_messages` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `sender_number` VARCHAR(20) NOT NULL,
            `receiver_number` VARCHAR(20) NOT NULL,
            `content` TEXT NOT NULL,
            `timestamp` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `is_read` BOOLEAN DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS `telecom_social_accounts` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `platform` VARCHAR(20) NOT NULL, -- 'facespace', 'instaglam', 'chirp'
            `citizenid` VARCHAR(50) NOT NULL,
            `username` VARCHAR(50) NOT NULL UNIQUE,
            `display_name` VARCHAR(50) NOT NULL,
            `avatar_url` VARCHAR(255) DEFAULT NULL
        );

        CREATE TABLE IF NOT EXISTS `telecom_social_posts` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `account_id` INT NOT NULL,
            `content` TEXT NOT NULL,
            `image_url` VARCHAR(255) DEFAULT NULL,
            `timestamp` DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (`account_id`) REFERENCES `telecom_social_accounts`(`id`) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS `telecom_landlines` (
            `property_id` VARCHAR(100) PRIMARY KEY,
            `number` VARCHAR(20) NOT NULL,
            `installed_by` VARCHAR(50) NOT NULL,
            `node_coords` LONGTEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS `telecom_infrastructure` (
            `pole_id` INT AUTO_INCREMENT PRIMARY KEY,
            `coords` LONGTEXT NOT NULL,
            `is_broken` BOOLEAN DEFAULT 0,
            `radius` INT DEFAULT 150
        );
    ]])
    print("^2[TCE Telecom]^7 Database schemas validated.")
end)
