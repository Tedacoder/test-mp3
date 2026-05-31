with open('adv_vehicles/server/dealership.lua', 'r') as file:
    lines = file.readlines()

with open('adv_vehicles/server/dealership.lua', 'w') as file:
    for line in lines:
        if "if not isFinanced and not Framework.RemoveMoney(src, 'bank', finalPrice, 'vehicle-purchase') then return false, 'Not enough money (including 8% tax).' end" in line:
            # We already charged the base price above (or we need to fix it entirely, let's fix entirely)
            pass
        elif "if not Framework.RemoveMoney(src, 'bank', price, \"vehicle-purchase\") then" in line:
            file.write("        -- Removed to handle full price with tax below\n")
        elif "return false, \"Not enough money.\"" in line:
            pass
        elif "    local tax = math.floor(price * 0.08)" in line:
            file.write("    -- We re-verify total final price and charge once here\n")
            file.write("    local tax = math.floor(price * 0.08)\n")
            file.write("    local finalPrice = price + tax\n")
            file.write("    if not isFinanced and not Framework.RemoveMoney(src, 'bank', finalPrice, 'vehicle-purchase') then\n")
            file.write("        return false, 'Not enough money (including 8% tax).'\n")
            file.write("    end\n")
        else:
            file.write(line)
