CREATE TABLE IF NOT EXISTS admin_bans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(64) NOT NULL,
    name VARCHAR(64) NOT NULL,
    reason VARCHAR(255),
    banned_by VARCHAR(64),
    expires INT,
    created_at INT
);

CREATE TABLE IF NOT EXISTS admin_permissions (
    steam_id VARCHAR(32) PRIMARY KEY,
    permissions LONGTEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS admin_whitelist_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_identifier VARCHAR(64) NOT NULL,
    item_type VARCHAR(32) NOT NULL,        -- 'tattoo', 'skin', 'clothing', 'hair'
    item_id VARCHAR(64) NOT NULL,          -- unique item identifier
    granted_by VARCHAR(64) NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
