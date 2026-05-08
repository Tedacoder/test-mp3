-- Add these to your ox_inventory data/items.lua
return {
    ['plastic_grocery_bag'] = {
        label = 'Plastic Grocery Bag',
        weight = 100,
        description = 'A thin bag for your groceries. Use to unpack.',
        consume = 0,
        client = {
            export = 'ultimate_grocer.useBag'
        }
    },
    ['custom_chips'] = {
        label = 'Zapp’s Voodoo Chips',
        weight = 200,
        description = 'A Philly favorite. Salty, spicy, and crunchy.',
    },
    ['bzzz_apple'] = {
        label = 'Fresh Gala Apple',
        weight = 150,
        description = 'A crisp, healthy snack from the produce aisle.',
    },
    ['cuban_soda'] = {
        label = 'Premium Craft Soda',
        weight = 300,
        description = 'Glass bottle soda. Refreshing and cold.',
    },
    ['pata_hoagie'] = {
        label = 'Deluxe Italian Hoagie',
        weight = 600,
        description = 'A massive sub with all the fixings.',
    }
}
