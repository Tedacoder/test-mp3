Config = {}

Config.TargetDistance = 1.5

-- Model Sets group multiple prop models into a single category for easy mapping
Config.ModelSets = {
    Produce = {
        'bzzz_food_banana_prop',
        'bzzz_food_apple_prop',
        'bzzz_food_orange_prop',
    },
    Drinks = {
        'cuban_soda_bottle',
        'cuban_water_bottle',
    },
    Snacks = {
        'custom_chips_voodoo',
        'pata_snack_chips',
    },
    Deli = {
        'pata_hoagie_prop',
    }
}

-- Map explicit props or ModelSets (by name) to specific inventory items
Config.Products = {
    -- Use specific model names
    ['bzzz_food_banana_prop'] = { item = 'bzzz_banana', price = 100, stock = 50 },
    ['bzzz_food_apple_prop'] = { item = 'bzzz_apple', price = 150, stock = 50 },
    ['cuban_soda_bottle'] = { item = 'cuban_soda', price = 300, stock = 50 },
    ['custom_chips_voodoo'] = { item = 'custom_chips', price = 200, stock = 50 },
    ['pata_hoagie_prop'] = { item = 'pata_hoagie', price = 600, stock = 20 },

    -- Or use ModelSets by their category name (the script will map all models in the set)
    -- ['Produce'] = { item = 'random_produce', price = 100, stock = 50 },
}

-- If a shelf doesn't have a specific prop assigned, allow a 'General Shelf' mode
Config.GeneralShelves = {
    'prop_shelf_01',
    'prop_shelf_02',
    'prop_food_shelf_01',
}

-- Cart spawns where players can grab a cart
Config.CartSpawns = {
    vec3(25.0, -1345.0, 29.5), -- Example coords
}

-- Register coordinates where players pay and get their bag
Config.Registers = {
    vec3(26.0, -1346.0, 29.5), -- Example coords
}

-- Create a reverse lookup for ModelSets to easily check if a prop belongs to a set
Config.ReverseModelSets = {}
for setName, models in pairs(Config.ModelSets) do
    for _, model in ipairs(models) do
        Config.ReverseModelSets[model] = setName
    end
end
