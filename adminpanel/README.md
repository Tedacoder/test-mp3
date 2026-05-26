# 🛡 N2‑DEEP RP Admin Panel — README (ox_inventory Version)

## Features

- Modern sidebar UI with icons and tabs for all admin functions
- Inventory management: view, add, remove items (silent actions for gods)
- Garage: view/add/remove vehicles
- Player actions: warn, kick, ban, heal, kill, teleport, spectate, freeze
- Management: give money, give clothing, set/remove jobs
- Permissions: granular per-admin permissions, god mode, live DB persistence
- Reports: view/respond, goto/bring/close, reply in report chat
- Cheat alerts: live anti-cheat flags, quick actions
- Admin chat: private staff chat window
- Logs: searchable, exportable, with audit trail for sensitive actions
- Player info panel: shows ping, job, grade, cash, bank, location
- Bulk actions: kick, ban, give items to multiple players
- Cooldown adjustment: gods can set action cooldowns live
- Server announcements: send messages to all players, announcement history
- Responsive design: works on desktop, tablet, mobile
- **Whitelist system:** restricts specific clothes, skins, tattoos, and hair to assigned players only; only non-whitelisted clothing is auto-removed, all other items are permitted unless whitelisted

## Requirements
- QBCore Framework (or Qbox fork with QBCore compatibility)
- oxmysql (latest version)
- ox_inventory (latest version)
- A working FiveM server environment

## Installation
1. Place the `admin_panel` folder into your server’s resources directory.
2. Add the following to your `server.cfg`:
   ```
   ensure adminpanel
   ```
3. Run the SQL below in your database:
   ```sql
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
   ```
4. Add your gods’ Steam hexes to `Config.Gods` in `config.lua`.
5. Restart your server.

## Configuration
- `config.lua` contains:
  - `Config.PanelTitle` — the title displayed on the UI sidebar.
  - `Config.Gods` — Steam hexes with full god access.
  - `Config.AdminPermissions` — default permissions for specific admins.
  - `Config.Cooldowns` — per‑action cooldowns in seconds.
  - `Config.VehiclePresets` — optional vehicle mod presets.

## Usage
- **Open Panel:** Press F2 (default) or type `/admin`.
- **Tabs:**
  - Inventory — View, add, remove items via ox_inventory exports
  - Garage — View/add/remove vehicles from DB
  - Player Actions — Warn, kick, ban, heal, kill, teleport, spectate, freeze
  - Management — Give money, give clothing (/pedmenu <cid>), set/remove jobs
  - Permissions — Gods can grant/revoke powers; changes persist in DB
  - Reports — View/respond to player reports
  - Cheat Alerts — Live anti‑cheat flags with quick actions
  - Admin Chat — Private staff chat
  - Logs — View recent admin actions
  - Announcements — Send server-wide messages
  - Whitelist — Assign/remove whitelisted clothes, skins, tattoos, hair for players

## Commands and Keybinds
Here are the commands you can use in-game to interact with the admin panel system:

- `/admin` or `/toggleadmin` : Opens the admin panel UI.
- `F2` (Default Keybind) : Toggles the admin panel UI open and closed.
- `/adminfix` : Emergency escape command to release NUI focus if the UI gets stuck.
- `/checksteam` : Prints your Steam ID to the chat and console to help with setting up permissions.
- `/stopspec` : Stops spectating a player and returns your camera to normal.
- `F3` (Default Keybind) : Keybind for `/stopspec` to quickly stop spectating.

## Whitelist System
- Gods/admins can assign specific clothes, skins, tattoos, and hair to players.
- Only clothing is auto-removed if not whitelisted; all other items are permitted unless whitelisted for a player.
- Whitelist management UI in the admin panel (tab: Whitelist)
- All whitelist changes are logged; only auto-removed clothing is logged for enforcement.

## Permissions System
- Gods: Full access + can edit other admins’ permissions.
- Admins: Only see and use actions they have permission for.
- Permissions are stored in `admin_permissions` table and loaded on resource start.

## Logging
- All actions are logged to `logs/admin_log.txt`.
- Optional Discord webhook logging via `Config.AdminLogWebhook`.

## Quick Test Checklist (ox_inventory)
- Open panel with F2 or /admin.
- Select a player → Inventory grid populates from ox_inventory.
- Add/remove item → Changes reflect in player’s inventory.
- Silent remove (god only) → No player notification, but logs entry created.
- Garage tab → Add/remove vehicle from DB.
- Player Actions → Test warn, kick, ban, heal, kill, teleport, spectate, freeze.
- Management → Give money, clothing, set/remove job.
- Permissions → Toggle for another admin, restart, confirm persistence.
- Reports → Submit /report test, claim, chat, close.
- Cheat Alerts → Trigger test flag, handle via quick actions.
- Admin Chat → Send/receive messages instantly.
- Logs → Confirm recent actions recorded.
- Whitelist tab → Assign/remove clothes, skins, tattoos, hair; test enforcement (only clothing auto-removed).
