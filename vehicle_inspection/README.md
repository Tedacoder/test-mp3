# Vehicle Inspection System

A comprehensive, framework-agnostic Vehicle Inspection script for FiveM.

## Features
- **Mechanic Workflow**: Mechanics use a diagnostic clipboard via `ox_target` to inspect a vehicle's Brakes, Tires, Lighting, Suspension, Engine, and Fuel Tank.
- **Police MDT Integration**: Police can visually check an inspection sticker via `ox_target` and view detailed failure/expiry reports.
- **Persistence**: All statuses, failure dates, and broken parts are saved persistently via `ox_mysql`.
- **Dynamic Economy**: Configurable fees for initial inspections, discounted re-inspections (within 24hrs), and illegal/fake inspections.
- **Shady Inspections**: Non-mechanics can "forge" an inspection, but police will see a fraudulent warning upon checking the sticker.
- **Dealership Export**: Easily grant new vehicles a clean inspection record upon purchase.
- **Custom Plate Enforcement**: Globally enforce a custom plate style texture across the server.

## Dependencies
- **ox_lib**: Used for progress bars, notifications, menus, and locales.
- **ox_target**: Used for all physical interactions.
- **ox_mysql**: **Absolutely required.** Because this script tracks complex data like JSON arrays of failed parts, timestamps for 48-hour grace periods, and persistent statuses across server restarts, a database wrapper is mandatory. `ox_mysql` is the standard, most performant choice.

## Installation

1. **Add Items to Inventory**:
   You must add the required items to your inventory system. If you are using `ox_inventory`, add the following to `ox_inventory/data/items.lua`:
   ```lua
   ['diagnostic_clipboard'] = {
       label = 'Diagnostic Clipboard',
       weight = 500,
       stack = false,
       close = true,
       description = 'A clipboard used by mechanics to diagnose vehicles.'
   },
   ['inspection_certificate'] = {
       label = 'Inspection Certificate',
       weight = 10,
       stack = false,
       close = true,
       description = 'A legal document verifying a vehicle is roadworthy.'
   }
   ```

2. **Database Setup**:
   Run the included SQL file `sql/install.sql` in your server's database (via HeidiSQL, phpMyAdmin, etc.) to create the `vehicle_inspections` table.

3. **Configure**:
   Open `config.lua` and adjust the jobs, economy fees, health thresholds, and your desired `Config.PlateStyle`.

4. **Start the Script**:
   Add `ensure vehicle_inspection` to your `server.cfg`.

## Operating Instructions

### For Mechanics
1. Have the `diagnostic_clipboard` item in your inventory.
2. Walk up to a vehicle, hold your `ox_target` key (usually `LALT`), and select **"Inspect Vehicle"**.
3. If parts are broken below the configured threshold, the car will **Fail**. The failing parts will be saved to the database.
4. If all parts are healthy, the car will **Pass**, the fee will be deducted, and you will receive an `inspection_certificate` item.

### For Police
1. Walk up to any vehicle, hold your `ox_target` key, and select **"Check Inspection Sticker"**.
2. A notification will show the Expiry Date.
3. If the car has failed, a detailed report will print in the chat/MDT showing the specific failed parts and the date they must be repaired by (Grace Period).
4. If the sticker was forged by a non-mechanic, a warning will appear indicating the document is fraudulent.

### For Developers (Dealership Integration)
When a player buys a brand new car from a dealership, you should give it a clean inspection automatically. Add this export to your dealership script right after the car is purchased and the plate is generated:

```lua
local plate = "ABC 123" -- The new plate
exports.vehicle_inspection:RegisterNewVehicle(plate)
```
