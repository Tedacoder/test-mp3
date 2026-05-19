# Tha Crack Era (TCE) Telecom

TCE Telecom is a highly advanced, dual-OS smartphone NUI and infrastructure system built for modern FiveM roleplay servers.

## 🌟 Features
* **Dual-OS NUI**: Seamlessly swaps between the **iTone** (dynamic island, rounded) and **Star** (punch hole, sharp) phone shells dynamically based on item metadata.
* **Star-DeX Desktop Mode**: The NUI transforms into a fully functional landscape desktop OS when triggered.
* **SoundStream**: Streams live 30-second music previews directly from the public iTunes API using an integrated HTML5 audio player.
* **LinkPlayer**: Allows players to paste and stream direct `.mp3`/`.ogg` audio files.
* **Flappy Bird**: A fully playable, canvas-based arcade game built right into the phone.
* **Hardware Damage Mechanics**: Integrated tick loops to detect high-speed crashes (Cracked Screen UI) and underwater submersion (FRIED DEVICE blackout screen).
* **Destructible Telecom Grid**: Players can destroy utility poles. The server calculates the radius and broadcasts a "Blackout Zone" to clients, dropping their 5G UI signal to "SOS".
* **Functional App UI Suite**: Fully styled UI views for Contacts, FaceSpace, City Job Center, Banking, and a Retail Store.
* **Agnostic Architecture**: Fully decoupled utilizing a Bridge pattern for Frameworks (`qbx`, `qb`, `esx`) and Inventories (`qs`, `ox`, `qb`).

---

## ⚙️ Installation

1. **Download & Extract**: Drop the `tce_telecom` folder into your server's `resources` directory.
2. **Dependencies**:
   Ensure you have the following core resources started *before* `tce_telecom`:
   - `ox_lib`
   - `oxmysql`
   - Your chosen framework (`qbx_core` is provided by default in the bridge)
   - Your chosen inventory (`qs-inventory` bridge is provided by default)
3. **Database**:
   The script utilizes `MySQL.ready` to automatically generate the required database tables on its first startup. You do not need to manually import an SQL file! The following tables will be generated:
   - `telecom_devices`
   - `telecom_contacts`
   - `telecom_messages`
   - `telecom_social_accounts`
   - `telecom_social_posts`
   - `telecom_landlines`
   - `telecom_infrastructure`
4. **Configuration**:
   Open `config.lua` and adjust the framework and inventory settings to match your server environment.
   ```lua
   Config.Framework = 'qbx' -- Ensure your chosen bridge exists in bridge/framework/
   Config.Inventory = 'qs'  -- Ensure your chosen bridge exists in bridge/inventory/
   ```
5. **Server Cfg**: Add `ensure tce_telecom` to your `server.cfg`.

---

## 🛠️ Testing & Next Steps
This resource provides the **foundational architecture, UI loops, and database logic**. Because every RP server uses uniquely named items and varied webhook setups, you will need to finalize the specific logic hooks for your server:

1. **Give Items**: Give yourself the `phone_star` or `phone_itones` items. Using the item triggers the NUI popup.
2. **Camera Webhooks**: In `client/camera.lua`, the `capturePhoto` event currently prints to the console. You must uncomment and configure the `screenshot-basic` code block with your Discord webhook to actually save the photos.
3. **Social Media Accounts**: Currently, FaceSpace requires a player to have an entry in `telecom_social_accounts`. You will need to implement your preferred logic (e.g. at the DMV or on character creation) to insert their `citizenid` into this table so they can post.
4. **Item Metadata**: `server/hardware.lua` successfully detects damage events, but you must insert the specific export for your inventory (e.g., `exports.ox_inventory:SetMetadata()`) to permanently save the `water_damaged = true` state to the physical item.

Enjoy the script!
