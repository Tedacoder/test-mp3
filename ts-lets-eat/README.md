# TS Let's Eat - Advanced Food Preparation & Cooking System

A highly modular, framework-agnostic FiveM script that brings advanced food preparation, cooking, dynamic storefronts, and realism mechanics to your server.

## Features
- **Multi-Framework & Inventory Support:** Natively supports QBox, QBCore, ESX, ox_inventory, qb-inventory, and qs-inventory.
- **Physical Prop Spawning & Effects:** Visually spawns pots, pans, and cutting boards with GTA native animations, steam particles, and sizzle audio.
- **Dynamic Refrigerator Stashes:** Instantly creates localized stashes for any `ox_target` targeted refrigerator.
- **Scalable Portions:** Players can cook Single servings or Family-style (x10) batches.
- **Spoilage Mechanics:** Built-in degradation system dynamically calculates expiration times based on item metadata.
- **Categorized Buffs:** Meals are categorized (e.g., Soul Food, Seafood, BBQ) to grant specific status buffs (Health/Stamina regen, Stress reduction, Speed multipliers).
- **Dynamic Restaurant Storefronts:** Admins and Restaurant Bosses can visually build and update their storefront menus in-game without editing files. Data is persistently saved to the server via Key-Value Pairs (KVP).
- **Exploit Protected:** Heavy server-side validation against infinite item loops, money injection, and global triggering.

## Dependencies
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target) (or qb-target configured in shared/config.lua)
- A Supported Framework (QBCore, QBox, or ESX)
- A Supported Inventory (ox_inventory, qb-inventory, or qs-inventory)

## Installation
1. Ensure all dependencies are started before this script.
2. Add the items from `shared/config.lua -> Config.Items` to your inventory's items database (e.g., `ox_inventory/data/items.lua` or QBCore's `shared/items.lua`).
3. Add `ensure ts-lets-eat` to your `server.cfg`.

## Usage & Instructions

### 1. Cooking Food
- **Native Props:** Walk up to any stove, microwave, or grill in the GTA world and use your third-eye target (`ox_target`). Select **Cook Food**.
- **Custom Zones:** For custom MLOs, use the invisible sphere zones configured in `Config.Restaurants`.
- **Selecting Recipes:** A menu will appear with available recipes. Select Single or Family style. The script verifies you have the raw ingredients, plays the animation/effects, and rewards the cooked item.

### 2. Using Refrigerators
- Walk up to any refrigerator prop and use your target. It will dynamically generate a stash ID based on your exact coordinates and open the inventory.

### 3. Wholesale Sourcing
- Business owners can visit the delivery warehouse NPC configured in `Config.BusinessSourcing.locations`.
- Use your target and select **Purchase Wholesale Ingredients**.
- **Requirement:** You must have the correct job defined in `Config.BusinessSourcing.allowedJobs`. The cost is deducted directly from your bank or cash account.

### 4. Restaurant Storefronts
- Each restaurant configured in `Config.Restaurants` spawns an NPC storefront.
- **Customers:** Target the NPC to browse and purchase items.
- **Admins & Bosses:** A **Manage Storefront** option will appear on the NPC. Use this menu to dynamically add items, set prices, or remove items. Changes are saved instantly and persist across server restarts.

### 5. Eating Food & Spoilage
- Simply use the meal item from your inventory.
- The script calculates the time passed since the item was created. If it exceeds the spoilage rate (defined in `Config.Spoilage`), the food is wasted.
- If fresh, the appropriate status buff (Speed, Armor, Health/Stamina Regen, Stress Relief, Hunger/Thirst) is automatically applied to your character.

## Configuration Guide
The `shared/config.lua` file is fully commented and highly customizable.
- **`Config.Framework` / `Config.Inventory`**: Change these values to match your server's setup (e.g., `'ox'`, `'qb'`, `'esx'`).
- **`Config.Buffs`**: Adjust the multipliers and types of buffs for each category.
- **`Config.Recipes`**: Add new recipes, define the ingredients required, portion times, and animation styles.
- **`Config.Restaurants`**: Define custom jobs, storefront coordinates, and targetable invisible zones for custom mapping.