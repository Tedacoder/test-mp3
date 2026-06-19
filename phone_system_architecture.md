# Tha Crack Era - Advanced Telecommunications System Architecture

## 1. Structured Implementation Map

The resource is designed with a strict **Core <-> Bridge <-> Module** architecture to guarantee maximum framework agnosticism.

### Directory Structure
```text
[tce_telecom]/
├── fxmanifest.lua
├── config.lua               # Master configuration (toggles, brands, battery decay rate, etc.)
├── shared/
│   ├── utils.lua            # Shared utilities
│   └── locales.json         # Language strings (using Unicode escapes for emojis e.g., \u26a0\ufe0f)
├── bridge/                  # Agnostic Bridge Layer
│   ├── framework/           # QBCore, qbx_core, ESX, Ox, Standalone
│   ├── inventory/           # ox_inventory, qb-inventory, qs-inventory
│   ├── target/              # ox_target, qb-target, qtarget, textui
│   ├── banking/             # qb-banking, okokBanking, default
│   └── housing/             # vms.lua, qb-houses, etc.
├── server/
│   ├── core.lua             # Bootstrapper & core logic
│   ├── db.lua               # oxmysql wrapper
│   ├── items.lua            # Usable item registrations
│   ├── billing.lua          # Banking/Insurance processing
│   ├── apps/                # Server-side logic for apps (Socials, Music, Banking)
│   └── infrastructure.lua   # Telecom job, Grid state, Landline sync
├── client/
│   ├── core.lua             # NUI initialization, prop management
│   ├── hardware.lua         # Battery, Damage, Water detection, Privacy Display
│   ├── camera.lua           # screenshot-basic hooks, facial expressions
│   ├── target.lua           # Retail, Payphones, Telecom repair nodes
│   └── infrastructure.lua   # Destructible poles, grid knockout zones
└── html/                    # UI Application
    ├── index.html
    ├── style.css
    ├── js/
    │   ├── app.js           # NUI Message routing, React/Vue mounting
    │   └── components/      # Apps, Desktop UI (Star-DeX)
    └── assets/              # Images, sounds, css filters
```

### Module Breakdown

1. **Hardware & Retail**: Managed via `inventory` bridge. Metadata includes `imei`, `color`, `battery`, `screen_condition`, `waterproof`.
2. **Damage & Hazards**: Client tick checks for swimming (`IsPedSwimmingUnderWater`). If damaged, metadata is updated via server callback. NUI sends a glitch overlay message if `screen_condition` < 50.
3. **Star Brand Exclusives**:
    - Sideloading: Handled via NUI file upload / checking inventory for USB item.
    - Privacy Display: Client sets material/rendertarget logic on the attached prop.
    - PowerShare: Target option (no yielding inside `canInteract`).
    - Star-DeX: NUI state swap to desktop layout when near monitor prop.
4. **Camera Mechanics**: Uses `screenshot-basic`. Client invokes `SetFacialIdleAnimOverride` for selfie moods. CSS handles live filters before NUI sends snapshot request.
5. **App Ecosystem**: Light/Dark mode via NUI state. Socials and Job center interact with server db.
6. **Music Ecosystem**:
    - LinkPlayer: NUI Web Audio API.
    - SoundStream: NUI `fetch` to iTunes Search API, playing m4a previews.
7. **Infrastructure & Telecom**:
    - Housing integration via `bridge/housing/vms.lua` to get property coords.
    - Destructible poles: Client tracks entity health of pole hashes. If destroyed, syncs radius to server, which broadcasts blackout to clients in zone.
8. **Directory**: SQL-driven query, cached on server, accessed via NUI (phone) or `target` bridge (payphones).

---

## 2. Bridge Logic Example (Decoupling Framework & Inventory)

This structure ensures the core script never directly calls `QBCore` or `qbx_core`.

### `bridge/framework/qbx.lua`
```lua
-- Qbox Bridge
if Config.Framework ~= 'qbx' then return end

local qbx = exports.qbx_core

Bridge = Bridge or {}
Bridge.Framework = {
    GetPlayerIdentifier = function(source)
        local player = qbx:GetPlayer(source)
        return player and player.PlayerData.citizenid or nil
    end,

    GetPlayerPhone = function(source)
        local player = qbx:GetPlayer(source)
        return player and player.PlayerData.charinfo.phone or nil
    end,

    RegisterUsableItem = function(itemName, callback)
        -- Qbox specific registration without using .Functions table
        qbx:CreateUseableItem(itemName, function(source, item)
            callback(source, item)
        end)
    end,

    GetSharedItems = function()
        -- Memory: Use GetSharedItems() for qbx_core
        return qbx:GetSharedItems()
    end,

    -- Returns correctly formatted server-side time/date since os.date fails on modern clients
    GetServerTime = function()
        return os.date('%Y-%m-%d %H:%M:%S')
    end
}
```

### `bridge/inventory/qs.lua`
```lua
-- Quasar Inventory Bridge
if Config.Inventory ~= 'qs' then return end

Bridge = Bridge or {}
Bridge.Inventory = {
    GetItemMetadata = function(source, slot)
        local item = exports['qs-inventory']:GetItemBySlot(source, slot)
        return item and item.info or {}
    end,

    RegisterUsableItem = function(itemName, callback)
        -- Memory: Note the spelling "CreateUsableItem" for QS vs "CreateUseableItem" for QB
        exports['qs-inventory']:CreateUsableItem(itemName, function(source, item)
            callback(source, item)
        end)
    end,

    HasItem = function(source, itemName)
        local count = exports['qs-inventory']:GetItemTotalAmount(source, itemName)
        return count > 0
    end
}
```

### Using the Bridge in Server Core
```lua
-- server/items.lua
-- The core script relies solely on the Bridge wrapper.
Bridge.Framework.RegisterUsableItem('phone_star', function(source, item)
    local metadata = item.info or {}

    if metadata.water_damaged then
        TriggerClientEvent('tce_telecom:client:Notify', source, "This phone is fried.", "error")
        return
    end

    TriggerClientEvent('tce_telecom:client:OpenPhone', source, {
        brand = 'star',
        imei = metadata.imei,
        battery = metadata.battery,
        screenCracked = metadata.screen_cracked
    })
end)
```

### Target Note
When implementing ox_target or qb-target, ensure yielding functions are not used inside `canInteract`:
```lua
-- BAD (Causes Native Crashes)
canInteract = function(entity)
    local hasJob = lib.callback.await('tce_telecom:checkJob', false)
    return hasJob
end

-- GOOD (Use built-in properties)
job = "telecom"
```

---

## 3. Database Schema Layout (SQL)

Using `oxmysql` (`'@oxmysql/lib/MySQL.lua'`).

```sql
-- Devices tracking and Insurance
CREATE TABLE IF NOT EXISTS `telecom_devices` (
    `imei` VARCHAR(50) PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `brand` VARCHAR(20) NOT NULL, -- 'itones', 'star', 'landline'
    `phone_number` VARCHAR(20) NOT NULL,
    `insurance_active` BOOLEAN DEFAULT 0,
    `insurance_due_date` DATETIME DEFAULT NULL,
    `is_unlisted` BOOLEAN DEFAULT 0
);

-- Contacts (backed up for insurance)
CREATE TABLE IF NOT EXISTS `telecom_contacts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `imei` VARCHAR(50) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `number` VARCHAR(20) NOT NULL,
    FOREIGN KEY (`imei`) REFERENCES `telecom_devices`(`imei`) ON DELETE CASCADE
);

-- App Data: Messages
CREATE TABLE IF NOT EXISTS `telecom_messages` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `sender_number` VARCHAR(20) NOT NULL,
    `receiver_number` VARCHAR(20) NOT NULL,
    `content` TEXT NOT NULL,
    `timestamp` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `is_read` BOOLEAN DEFAULT 0
);

-- Social Media: Accounts
CREATE TABLE IF NOT EXISTS `telecom_social_accounts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `platform` VARCHAR(20) NOT NULL, -- 'facespace', 'instaglam', 'chirp'
    `citizenid` VARCHAR(50) NOT NULL,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `display_name` VARCHAR(50) NOT NULL,
    `avatar_url` VARCHAR(255) DEFAULT NULL
);

-- Social Media: Posts
CREATE TABLE IF NOT EXISTS `telecom_social_posts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `account_id` INT NOT NULL,
    `content` TEXT NOT NULL,
    `image_url` VARCHAR(255) DEFAULT NULL,
    `timestamp` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`account_id`) REFERENCES `telecom_social_accounts`(`id`) ON DELETE CASCADE
);

-- Housing / Landlines Infrastructure
CREATE TABLE IF NOT EXISTS `telecom_landlines` (
    `property_id` VARCHAR(100) PRIMARY KEY, -- Linked to vms.lua property ID
    `number` VARCHAR(20) NOT NULL,
    `installed_by` VARCHAR(50) NOT NULL, -- Telecom worker citizenid
    `node_coords` LONGTEXT NOT NULL -- JSON array of connection points {x,y,z}
);

-- Grid Status
CREATE TABLE IF NOT EXISTS `telecom_infrastructure` (
    `pole_id` INT AUTO_INCREMENT PRIMARY KEY,
    `coords` LONGTEXT NOT NULL, -- {x,y,z}
    `is_broken` BOOLEAN DEFAULT 0,
    `radius` INT DEFAULT 150
);
```

---

## 4. UI Component Architecture

The NUI is built as a single-page application (SPA) using React/Vue or Vanilla JS Web Components, fully encapsulated.

### Component Tree
```text
<RootContainer>
    <!-- Hardware Overlays -->
    <DamageOverlay v-if="screenCracked" intensity="high" />
    <GlareOverlay />

    <!-- Mode Swapping -->
    <StarDexLayout v-if="isDexMode">
        <!-- Desktop layout with window management -->
        <Taskbar />
        <WindowSystem />
    </StarDexLayout>

    <MobileLayout v-else class="theme-dark | theme-light">
        <StatusBar>
            <TimeDisplay /> <!-- Syncs with server time via callback -->
            <NetworkSignal strength="calc()" /> <!-- Reacts to network knockout radius -->
            <BatteryIndicator percent="batteryLife" />
        </StatusBar>

        <Screen>
            <!-- Lock Screen / Home Screen -->
            <HomeScreen v-if="unlocked">
                <AppGrid>
                    <AppIcon name="FaceSpace" />
                    <AppIcon name="InstaGlam" />
                    <AppIcon name="SoundStream" />
                    <!-- Sideloaded Apps for Star -->
                    <AppIcon v-if="brand == 'star'" name="DarkWeb" />
                </AppGrid>
            </HomeScreen>

            <!-- App Containers -->
            <AppContainer v-if="activeApp">
                <!-- Advanced Camera -->
                <CameraApp v-if="activeApp == 'camera'">
                    <LiveFilters />
                    <MoodSelector /> <!-- Triggers SetFacialIdleAnimOverride via NUI callback -->
                    <CaptureButton />
                </CameraApp>

                <!-- Music Players -->
                <SoundStreamApp v-if="activeApp == 'soundstream'">
                    <Searchbar /> <!-- Queries iTunes Search API -->
                    <PlayerControls audioSrc="m4aPreviewUrl" />
                </SoundStreamApp>

                <DirectoryApp v-if="activeApp == 'directory'">
                    <!-- Fetches businesses, emergency, landlines -->
                </DirectoryApp>
            </AppContainer>
        </Screen>

        <PhysicalButtons>
            <PrivacyToggle v-if="brand == 'star'" @click="togglePrivacyMode" />
        </PhysicalButtons>
    </MobileLayout>
</RootContainer>
```

### Future Scalability Hooks
```lua
-- Exports provided for external scripts
exports('RegisterSmartHomeDevice', function(deviceId, data)
    -- Integrates with smart locks, lights, etc.
end)

exports('SendWatchNotification', function(source, title, message)
    -- Push notification to wearable tech items
end)

exports('RegisterCameraStream', function(cameraId, rtspUrl)
    -- Register Dashcam/CCTV streams into the phone's camera app
end)
```
