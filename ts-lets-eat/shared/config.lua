Config = {}

-- Framework Settings
Config.Framework = 'qbox' -- 'qbox', 'qbcore', 'esx', or 'none' for standalone
Config.Inventory = 'ox' -- 'ox', 'qb', 'qs', or 'custom'

-- Target System (optional but useful for interactions)
Config.Target = 'ox_target' -- 'ox_target', 'qb-target'

-- UI Settings
Config.UseOxLibMenus = true
Config.UseOxLibProgressBar = true

-- Business / Location Settings
Config.BusinessSourcing = {
    enabled = true,
    accountType = 'bank', -- or 'cash'
    wholesaleMarkup = 0.5, -- 50% of the item cost
    locations = {
        vec3(120.3, -3005.1, 5.8) -- Example delivery warehouse
    },
    pedModel = `s_m_m_trucker_01`,
    allowedJobs = {
        ['burgershot'] = true,
        ['catcafe'] = true,
        ['pizza'] = true
    }
}

-- Degradation / Spoilage Rates (in hours)
-- Lower number means it spoils faster
Config.Spoilage = {
    enabled = true,
    rates = {
        raw_meat = 24,
        raw_seafood = 12,
        cooked_meal = 72,
        dessert = 120,
        drinks = 240
    }
}

-- Buff Settings
Config.Buffs = {
    enabled = true,
    duration = 30000, -- 30 seconds
    categories = {
        ['Soul Food'] = {
            type = 'regen',
            healthMultiplier = 1.2,
            staminaMultiplier = 1.5,
            label = 'Health & Stamina Regen'
        },
        ['Seafood'] = {
            type = 'stress',
            stressRelief = 25,
            label = 'Stress Reduction'
        },
        ['BBQ'] = {
            type = 'satiation',
            hungerMultiplier = 2.0,
            thirstMultiplier = 1.5,
            label = 'Long-lasting Fullness'
        },
        ['Chinese'] = {
            type = 'speed',
            speedMultiplier = 1.1,
            label = 'Movement Speed Buff'
        },
        ['Drinks'] = {
            type = 'thirst',
            thirstMultiplier = 2.0,
            label = 'Hydration'
        },
        ['Dessert'] = {
            type = 'armor',
            armorAdd = 10,
            label = 'Minor Armor Boost'
        }
    }
}

-- Prop Interactions (Kitchen Props)
Config.KitchenProps = {
    [`prop_cooker_03`] = { type = 'stove' },
    [`prop_micro_01`] = { type = 'microwave' },
    [`prop_micro_02`] = { type = 'microwave' },
    [`prop_micro_03`] = { type = 'microwave' },
    [`prop_bbq_1`] = { type = 'grill' },
    [`prop_bbq_2`] = { type = 'grill' },
    [`prop_bbq_3`] = { type = 'grill' },
    [`prop_bbq_4`] = { type = 'grill' },
    [`prop_bbq_5`] = { type = 'grill' }
}

-- Refrigerator Props
Config.RefrigeratorProps = {
    [`prop_fridge_01`] = true,
    [`prop_fridge_03`] = true
}

-- Restaurant Locations & Storefronts
Config.Restaurants = {
    ['burgershot'] = {
        label = 'Burger Shot',
        job = 'burgershot',
        -- Storefront NPC where players can buy items if no workers are around
        storefront = {
            enabled = true,
            pedModel = `s_m_y_chef_01`,
            coords = vec4(-1193.38, -892.29, 13.99, 304.5), -- x, y, z, heading
            items = {
                { name = 'bologna_sandwich', price = 15 },
                { name = 'water', price = 5 }
            }
        },
        -- Custom cooking stations (zones) if native props aren't placed well
        cookingStations = {
            { coords = vec3(-1201.78, -897.41, 13.99), radius = 1.0 }
        }
    }
}

-- Dynamic Prop Spawning
Config.CookingProps = {
    ['frying_pan'] = { hash = `prop_pot_05`, offset = vec3(0.0, 0.0, 1.0), rot = vec3(0.0, 0.0, 0.0) },
    ['pot'] = { hash = `prop_pot_03`, offset = vec3(0.0, 0.0, 1.0), rot = vec3(0.0, 0.0, 0.0) },
    ['cutting_board'] = { hash = `prop_food_cb`, offset = vec3(0.0, 0.0, 1.0), rot = vec3(0.0, 0.0, 0.0) }
}

-- Visual & Audio Effects
Config.Effects = {
    enabled = true,
    particle = {
        dict = 'core',
        name = 'ent_amb_steam',
        scale = 0.5,
        offset = vec3(0.0, 0.0, 0.2)
    },
    audio = {
        soundName = 'PAN_SIZZLE',
        soundDict = 'DLC_Biker_Meth_Lab_Sounds'
    }
}

-- Animations
Config.Animations = {
    ['cutting'] = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        anim = 'cop_b_idle',
        flags = 49,
        time = 5000
    },
    ['stirring'] = {
        dict = 'amb@prop_human_bbq@male@base',
        anim = 'base',
        flags = 49,
        time = 5000
    },
    ['grilling'] = {
        dict = 'amb@prop_human_bbq@male@base',
        anim = 'base',
        flags = 49,
        time = 5000
    }
}

-- Recipe / Item Database
Config.Recipes = {
    ['Risotto'] = {
        category = 'Seafood',
        output = 'cooked_risotto',
        portions = {
            ['single'] = { time = 5000, ingredients = { ['raw_risotto'] = 1, ['raw_scallops'] = 1 }, amount = 1 },
            ['family'] = { time = 15000, ingredients = { ['raw_risotto'] = 5, ['raw_scallops'] = 5 }, amount = 10 }
        },
        prop = 'pot',
        anim = 'stirring'
    },
    ['Lasagna'] = {
        category = 'BBQ',
        output = 'cooked_lasagna',
        portions = {
            ['single'] = { time = 6000, ingredients = { ['lasagna_noodles'] = 1, ['raw_meat'] = 1 }, amount = 1 },
            ['family'] = { time = 18000, ingredients = { ['lasagna_noodles'] = 5, ['raw_meat'] = 5 }, amount = 10 }
        },
        prop = 'frying_pan',
        anim = 'stirring'
    },
    ['Oxtail Stew'] = {
        category = 'Soul Food',
        output = 'cooked_oxtail',
        portions = {
            ['single'] = { time = 8000, ingredients = { ['oxtail'] = 1, ['vegetables'] = 1 }, amount = 1 },
            ['family'] = { time = 24000, ingredients = { ['oxtail'] = 5, ['vegetables'] = 5 }, amount = 10 }
        },
        prop = 'pot',
        anim = 'stirring'
    },
    ['Bologna Sandwich'] = {
        category = 'Soul Food',
        output = 'bologna_sandwich',
        portions = {
            ['single'] = { time = 3000, ingredients = { ['bologna'] = 2, ['bread'] = 2 }, amount = 1 },
            ['family'] = { time = 9000, ingredients = { ['bologna'] = 10, ['bread'] = 10 }, amount = 10 }
        },
        prop = 'cutting_board',
        anim = 'cutting'
    },
    ['Steamed Bok Choy'] = {
        category = 'Chinese',
        output = 'steamed_bok_choy',
        portions = {
            ['single'] = { time = 4000, ingredients = { ['bok_choy'] = 1, ['water'] = 1 }, amount = 1 },
            ['family'] = { time = 12000, ingredients = { ['bok_choy'] = 5, ['water'] = 5 }, amount = 10 }
        },
        prop = 'pot',
        anim = 'stirring'
    },
    ['Grilled Red Snapper'] = {
        category = 'Seafood',
        output = 'grilled_red_snapper',
        portions = {
            ['single'] = { time = 7000, ingredients = { ['red_snapper'] = 1, ['seasoning'] = 1 }, amount = 1 },
            ['family'] = { time = 21000, ingredients = { ['red_snapper'] = 5, ['seasoning'] = 5 }, amount = 10 }
        },
        prop = 'frying_pan',
        anim = 'grilling'
    },
    ['Pickled Pig Feet'] = {
        category = 'Soul Food',
        output = 'pickled_pig_feet',
        portions = {
            ['single'] = { time = 6000, ingredients = { ['raw_pig_feet'] = 1, ['vinegar'] = 1 }, amount = 1 },
            ['family'] = { time = 18000, ingredients = { ['raw_pig_feet'] = 5, ['vinegar'] = 5 }, amount = 10 }
        },
        prop = 'pot',
        anim = 'stirring'
    }
}

-- Default Item Definitions (For inventory mapping/creation)
Config.Items = {
    ['raw_risotto'] = { label = 'Raw Risotto', type = 'ingredient', spoil_rate = 'raw_seafood' },
    ['lasagna_noodles'] = { label = 'Lasagna Noodles', type = 'ingredient', spoil_rate = 'raw_meat' },
    ['bologna'] = { label = 'Bologna', type = 'ingredient', spoil_rate = 'raw_meat' },
    ['raw_scallops'] = { label = 'Raw Scallops', type = 'ingredient', spoil_rate = 'raw_seafood' },
    ['raw_pig_feet'] = { label = 'Raw Pig Feet', type = 'ingredient', spoil_rate = 'raw_meat' },
    ['oxtail'] = { label = 'Oxtail', type = 'ingredient', spoil_rate = 'raw_meat' },
    ['bok_choy'] = { label = 'Bok Choy', type = 'ingredient', spoil_rate = 'raw_seafood' }, -- veggies spoil fast
    ['red_snapper'] = { label = 'Red Snapper', type = 'ingredient', spoil_rate = 'raw_seafood' },
    ['raw_meat'] = { label = 'Raw Meat', type = 'ingredient', spoil_rate = 'raw_meat' },
    ['vegetables'] = { label = 'Vegetables', type = 'ingredient', spoil_rate = 'raw_seafood' },
    ['bread'] = { label = 'Bread', type = 'ingredient', spoil_rate = 'cooked_meal' },
    ['water'] = { label = 'Water', type = 'ingredient', spoil_rate = 'drinks', category = 'Drinks', register_usable = false },
    ['seasoning'] = { label = 'Seasoning', type = 'ingredient', spoil_rate = 'dessert' },
    ['vinegar'] = { label = 'Vinegar', type = 'ingredient', spoil_rate = 'drinks' },

    ['cooked_risotto'] = { label = 'Cooked Risotto', type = 'meal', category = 'Seafood', spoil_rate = 'cooked_meal' },
    ['cooked_lasagna'] = { label = 'Cooked Lasagna', type = 'meal', category = 'BBQ', spoil_rate = 'cooked_meal' },
    ['cooked_oxtail'] = { label = 'Oxtail Stew', type = 'meal', category = 'Soul Food', spoil_rate = 'cooked_meal' },
    ['bologna_sandwich'] = { label = 'Bologna Sandwich', type = 'meal', category = 'Soul Food', spoil_rate = 'cooked_meal' },
    ['steamed_bok_choy'] = { label = 'Steamed Bok Choy', type = 'meal', category = 'Chinese', spoil_rate = 'cooked_meal' },
    ['grilled_red_snapper'] = { label = 'Grilled Red Snapper', type = 'meal', category = 'Seafood', spoil_rate = 'cooked_meal' },
    ['pickled_pig_feet'] = { label = 'Pickled Pig Feet', type = 'meal', category = 'Soul Food', spoil_rate = 'cooked_meal' }
}
