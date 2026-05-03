CREATE TABLE IF NOT EXISTS `vehicle_inspections` (
    `plate` varchar(50) NOT NULL,
    `status` varchar(20) DEFAULT 'None',
    `expiry` int(11) DEFAULT NULL,
    `failed_date` int(11) DEFAULT NULL,
    `failed_parts` longtext DEFAULT '[]',
    `last_shop` varchar(50) DEFAULT NULL,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
