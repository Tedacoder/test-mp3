with open('adv_vehicles/server/dealership.lua', 'r') as file:
    content = file.read()

# Fix the syntax error injected by the previous sed/python scripts
fixed = content.replace(
"""        -- Removed to handle full price with tax below
        end
    end""",
"""    end"""
).replace(
"""    local tax = math.floor(price * 0.08)
    local finalPrice = price + tax
    if not isFinanced and not Framework.RemoveMoney(src, 'bank', finalPrice, 'vehicle-purchase') then
        return false, 'Not enough money (including 8% tax).'
    end
    local finalPrice = price + tax""",
"""    local tax = math.floor(price * 0.08)
    local finalPrice = price + tax
    if not isFinanced and not Framework.RemoveMoney(src, 'bank', finalPrice, 'vehicle-purchase') then
        return false, 'Not enough money (including 8% tax).'
    end"""
)

with open('adv_vehicles/server/dealership.lua', 'w') as file:
    file.write(fixed)
