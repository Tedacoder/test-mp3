Config = {}

-- General Settings
Config.AllowNPCSales = true

-- Whitelisted Vehicles
Config.Whitelist = {
    model = {
        'fdtruck',
        'fdtruck2',
        'fdtruckw',
        'taco',
        'ramentruck'
    }
}

-- Wholesale Depot (Docks)
Config.WholesaleDepot = {
    coords = vector3(100.0, -3000.0, 6.0),
    heading = 90.0,
    items = {
        { item = 'raw_steak', price = 10 },
        { item = 'onions', price = 5 },
        { item = 'amoroso_roll', price = 5 },
        { item = 'cheez_whiz', price = 8 },
        { item = 'ground_beef', price = 10 },
        { item = 'potato', price = 3 },
        { item = 'bread', price = 5 },
        { item = 'coldcuts', price = 8 },
        { item = 'soda_syrup', price = 4 },
        { item = 'liquor_supply', price = 20 }
    }
}

-- City Hall License Desk
Config.CityHall = {
    coords = vector3(240.0, -400.0, 39.0),
    heading = 120.0
}

-- Liquor License Settings
Config.LiquorLicense = {
    cost = 100,
    expiryDays = 7, -- Real-world days
}

-- Menu & Crafting Recipes
Config.Menu = {
    ['fries'] = {
        label = 'French Fries',
        item = 'french_fries',
        time = 5000,
        ingredients = {
            { item = 'potato', count = 1 }
        },
        anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b', flag = 49 },
        prop = { model = 'prop_fish_slice_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
    },
    ['chips'] = {
        label = 'Potato Chips',
        item = 'potato_chips',
        time = 5000,
        ingredients = {
            { item = 'potato', count = 1 }
        },
        anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b', flag = 49 },
        prop = { model = 'prop_fish_slice_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
    },
    ['hamburger'] = {
        label = 'Hamburger',
        item = 'hamburger',
        time = 8000,
        ingredients = {
            { item = 'ground_beef', count = 1 },
            { item = 'bread', count = 1 }
        },
        anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b', flag = 49 },
        prop = { model = 'prop_fish_slice_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
    },
    ['cheeseburger'] = {
        label = 'Cheeseburger',
        item = 'cheeseburger',
        time = 8000,
        ingredients = {
            { item = 'ground_beef', count = 1 },
            { item = 'bread', count = 1 },
            { item = 'cheez_whiz', count = 1 }
        },
        anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b', flag = 49 },
        prop = { model = 'prop_fish_slice_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
    },
    ['coldcut_sandwich'] = {
        label = 'Cold Cut Sandwich',
        item = 'coldcut_sandwich',
        time = 4000,
        ingredients = {
            { item = 'bread', count = 1 },
            { item = 'coldcuts', count = 1 }
        },
        anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b', flag = 49 },
        prop = { model = 'prop_fish_slice_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
    },
    ['soft_drink'] = {
        label = 'Soft Drink',
        item = 'soft_drink',
        time = 3000,
        ingredients = {
            { item = 'soda_syrup', count = 1 }
        },
        anim = { dict = 'missfam4', clip = 'base', flag = 49 },
        prop = { model = 'prop_cs_paper_cup', bone = 36029, pos = vec3(0.05, 0.04, 0.02), rot = vec3(-99.0, 0.0, 0.0) }
    },
    ['alcoholic_drink'] = {
        label = 'Alcoholic Drink',
        item = 'alcoholic_drink',
        time = 3000,
        requiresLicense = true,
        ingredients = {
            { item = 'liquor_supply', count = 1 }
        },
        anim = { dict = 'missfam4', clip = 'base', flag = 49 },
        prop = { model = 'prop_cs_paper_cup', bone = 36029, pos = vec3(0.05, 0.04, 0.02), rot = vec3(-99.0, 0.0, 0.0) }
    }
}

-- Multi-Step Recipes
Config.MultiStepRecipes = {
    ['philly_cheesesteak'] = {
        label = 'Philly Cheesesteak',
        steps = {
            {
                id = 'chop_steak',
                label = 'Chop Steak',
                time = 5000,
                ingredients = { { item = 'raw_steak', count = 1 } },
                output = 'chopped_steak',
                anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b', flag = 49 },
                prop = { model = 'prop_fish_slice_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
            },
            {
                id = 'grill_steak',
                label = 'Grill Steak & Onions',
                time = 8000,
                ingredients = { { item = 'chopped_steak', count = 1 }, { item = 'onions', count = 1 } },
                output = 'grilled_steak_onions',
                anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b', flag = 49 },
                prop = { model = 'prop_fish_slice_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
            },
            {
                id = 'assemble_philly',
                label = 'Assemble Philly',
                time = 4000,
                ingredients = { { item = 'grilled_steak_onions', count = 1 }, { item = 'amoroso_roll', count = 1 }, { item = 'cheez_whiz', count = 1 } },
                output = 'philly_cheesesteak',
                anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b', flag = 49 },
                prop = { model = 'prop_fish_slice_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
            }
        }
    },
    ['chop_cheese'] = {
        label = 'Chop Cheese',
        steps = {
            {
                id = 'chop_meat',
                label = 'Chop Ground Beef',
                time = 5000,
                ingredients = { { item = 'ground_beef', count = 1 } },
                output = 'chopped_beef',
                anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b', flag = 49 },
                prop = { model = 'prop_fish_slice_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
            },
            {
                id = 'grill_beef_cheese',
                label = 'Grill Beef & Cheese',
                time = 8000,
                ingredients = { { item = 'chopped_beef', count = 1 }, { item = 'cheez_whiz', count = 1 } },
                output = 'grilled_beef_cheese',
                anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b', flag = 49 },
                prop = { model = 'prop_fish_slice_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
            },
            {
                id = 'assemble_chop_cheese',
                label = 'Assemble Chop Cheese',
                time = 4000,
                ingredients = { { item = 'grilled_beef_cheese', count = 1 }, { item = 'amoroso_roll', count = 1 } },
                output = 'chop_cheese',
                anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b', flag = 49 },
                prop = { model = 'prop_fish_slice_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
            }
        }
    }
}
