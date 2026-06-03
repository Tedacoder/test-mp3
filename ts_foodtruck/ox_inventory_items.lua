-- Copy these into your ox_inventory/data/items.lua
return {
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
}