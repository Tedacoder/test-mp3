CREATE TABLE IF NOT EXISTS `player_vehicles` (
  `plate` varchar(15) NOT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`plate`)
);

ALTER TABLE `player_vehicles`
ADD COLUMN IF NOT EXISTS `foodtruck` tinyint(1) NOT NULL DEFAULT 0;
