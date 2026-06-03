# ts_foodtruck

A comprehensive, fully-configurable, and highly immersive FiveM food truck resource. Built tightly around `ox_lib`, `ox_target`, and `ox_inventory`, this script features a dynamic configuration system, multi-step cooking mechanics, dynamic session-based hiring, and a functional management tablet.

## Features

- **Multi-Step Crafting Loops:** Complex recipes like "Philly Cheesesteaks" require multiple physical steps (Chop -> Grill -> Assemble) utilizing `ox_lib:progressBar` and custom animations.
- **Dynamic Session Hiring:** Truck owners can physically look at and target nearby players using `ox_target` to hire them for that vehicle session, granting them stash access.
- **Manual Employee Payouts:** Owners can securely transfer funds to their employees via a physical menu interaction rather than relying on automated payroll.
- **Liquor License System:** Players must purchase an expiring liquor license from City Hall to craft and sell alcoholic beverages.
- **Wholesale Depot:** A configured physical location (Docks) to purchase raw materials and ingredients.
- **NPC Sales:** Toggleable option to sell prepared dishes directly to NPCs on the street.
- **Tablet Fallback Manager:** Built-in dynamic menu capabilities for owners to rename dishes, adjust prices, or hide items from their menu on the fly.
- **Security First:** Strict server-side validation against all transactions and crafting loops to prevent payload manipulation or "free item" exploits.

## Dependencies
- `ox_lib`
- `ox_target`
- `ox_inventory`
- `oxmysql`
- `qb-core` OR `qbx_core` (For Citizen ID verification)

---

## Installation & Setup

1. **Download and Extract:**
   Place the `ts_foodtruck` folder into your resources directory.

2. **Ensure Dependencies:**
   Make sure all dependencies listed above are started in your `server.cfg` *before* `ts_foodtruck`.

3. **Start the Resource:**
   Add `ensure ts_foodtruck` to your `server.cfg`.

4. **Configure the Script:**
   Open `config.lua` to adjust wholesale locations, City Hall coordinates, license costs, and all crafting recipes. You can easily modify the animation dicts, props, and ingredient requirements.

---

## Ox_Inventory Setup (Crucial)

To ensure the food truck operates correctly, you **must** add the following items to your `ox_inventory/data/items.lua` file.

Failure to add these items will result in server-side crafting rejections and missing textures.

```lua
-- Insert into ox_inventory/data/items.lua

    ['raw_steak'] = {
        label = 'Raw Steak',
        weight = 200,
        stack = true,
        close = true,
    },
    ['chopped_steak'] = {
        label = 'Chopped Steak',
        weight = 200,
        stack = true,
        close = true,
    },
    ['onions'] = {
        label = 'Onions',
        weight = 50,
        stack = true,
        close = true,
    },
    ['grilled_steak_onions'] = {
        label = 'Grilled Steak & Onions',
        weight = 250,
        stack = true,
        close = true,
    },
    ['amoroso_roll'] = {
        label = 'Amoroso Roll',
        weight = 100,
        stack = true,
        close = true,
    },
    ['cheez_whiz'] = {
        label = 'Cheez Whiz',
        weight = 150,
        stack = true,
        close = true,
    },
    ['philly_cheesesteak'] = {
        label = 'Philly Cheesesteak',
        weight = 500,
        stack = true,
        close = true,
        consume = 0.5,
        client = {
            status = { hunger = 200000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, 0.02, -0.02), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 2500,
        }
    },
    ['ground_beef'] = {
        label = 'Ground Beef',
        weight = 200,
        stack = true,
        close = true,
    },
    ['chopped_beef'] = {
        label = 'Chopped Beef',
        weight = 200,
        stack = true,
        close = true,
    },
    ['grilled_beef_cheese'] = {
        label = 'Grilled Beef & Cheese',
        weight = 250,
        stack = true,
        close = true,
    },
    ['chop_cheese'] = {
        label = 'Chop Cheese',
        weight = 450,
        stack = true,
        close = true,
        consume = 0.5,
        client = {
            status = { hunger = 200000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, 0.02, -0.02), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 2500,
        }
    },
    ['french_fries'] = {
        label = 'French Fries',
        weight = 150,
        stack = true,
        close = true,
        consume = 0.2,
        client = {
            status = { hunger = 50000 },
            usetime = 2500,
        }
    },
    ['potato_chips'] = {
        label = 'Potato Chips',
        weight = 100,
        stack = true,
        close = true,
        consume = 0.2,
        client = {
            status = { hunger = 50000 },
            usetime = 2500,
        }
    },
    ['hamburger'] = {
        label = 'Hamburger',
        weight = 300,
        stack = true,
        close = true,
        consume = 0.5,
        client = {
            status = { hunger = 100000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, 0.02, -0.02), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 2500,
        }
    },
    ['cheeseburger'] = {
        label = 'Cheeseburger',
        weight = 350,
        stack = true,
        close = true,
        consume = 0.5,
        client = {
            status = { hunger = 150000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, 0.02, -0.02), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 2500,
        }
    },
    ['coldcut_sandwich'] = {
        label = 'Coldcut Sandwich',
        weight = 250,
        stack = true,
        close = true,
        consume = 0.5,
        client = {
            status = { hunger = 100000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            prop = { model = 'prop_cs_burger_01', pos = vec3(0.02, 0.02, -0.02), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 2500,
        }
    },
    ['soft_drink'] = {
        label = 'Soft Drink',
        weight = 250,
        stack = true,
        close = true,
        consume = 0.5,
        client = {
            status = { thirst = 100000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
        }
    },
    ['alcoholic_drink'] = {
        label = 'Alcoholic Drink',
        weight = 250,
        stack = true,
        close = true,
        consume = 0.5,
        client = {
            status = { thirst = 100000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_cs_paper_cup', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
        }
    },
    ['liquor_license'] = {
        label = 'Liquor License',
        weight = 10,
        stack = false,
        close = true,
        description = 'A certified license from City Hall to sell liquor.',
    },
    ['potato'] = {
        label = 'Potato',
        weight = 100,
        stack = true,
        close = true,
    },
    ['bread'] = {
        label = 'Bread',
        weight = 100,
        stack = true,
        close = true,
    },
    ['coldcuts'] = {
        label = 'Cold Cuts',
        weight = 100,
        stack = true,
        close = true,
    },
    ['soda_syrup'] = {
        label = 'Soda Syrup',
        weight = 100,
        stack = true,
        close = true,
    },
    ['liquor_supply'] = {
        label = 'Liquor Supply',
        weight = 500,
        stack = true,
        close = true,
    }
```

### Stash Configuration
Because this script utilizes `ox_inventory:RegisterStash` on the server-side, you **do not** need to manually add stashes into `ox_inventory/data/stashes.lua`. The script dynamically registers the `food_truck_stash_`, `food_truck_safe_`, and `food_truck_counter_` dynamically based on the vehicle's plate.

## How to use

1. Go to the configured Wholesale Depot via `ox_target` to purchase raw ingredients.
2. If you intend to craft and sell Alcoholic Drinks, visit the City Hall via `ox_target` and purchase an expiring Liquor License.
3. Drive your whitelisted Food Truck and ensure a kitchen is installed (via the `install` item logic).
4. As the owner, `ox_target` a nearby player to hire them for your session.
5. `ox_target` your truck to access the Cooking Station. If you have the correct raw ingredients, you can proceed through the multi-step menus.
6. To manage your dynamic menu configurations (prices, titles, disabling), you can trigger the `exports['ts_foodtruck']:openTabletManager()` event via your server's tablet or business logic.
