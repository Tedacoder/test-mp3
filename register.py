import sys

def shop_owner_menu(inventory):
    while True:
        print("\n--- Shop Owner Menu ---")
        print("1. Add item")
        print("2. View inventory")
        print("3. Return to Main Menu")
        choice = input("Select an option: ")

        if choice == '1':
            item_name = input("Enter item name: ").strip()
            if not item_name:
                print("Item name cannot be empty.")
                continue
            try:
                item_price = float(input("Enter item price: "))
                if item_price < 0:
                    print("Price cannot be negative.")
                    continue
                inventory[item_name] = item_price
                print(f"Item '{item_name}' added with price ${item_price:.2f}.")
            except ValueError:
                print("Invalid price format. Please enter a number.")
        elif choice == '2':
            print("\n--- Current Inventory ---")
            if not inventory:
                print("Inventory is empty.")
            else:
                for item, price in inventory.items():
                    print(f"- {item}: ${price:.2f}")
        elif choice == '3':
            break
        else:
            print("Invalid option.")

def worker_menu(inventory, current_ticket):
    while True:
        print("\n--- Worker Menu ---")
        print("1. Add item to ticket")
        print("2. View current ticket")
        print("3. Return to Main Menu")
        choice = input("Select an option: ")

        if choice == '1':
            print("\n--- Available Inventory ---")
            if not inventory:
                print("Inventory is empty. Add items first.")
                continue
            for item, price in inventory.items():
                print(f"- {item}: ${price:.2f}")

            item_name = input("\nEnter item name to add (or leave blank to cancel): ").strip()
            if not item_name:
                continue

            if item_name in inventory:
                current_ticket.append(item_name)
                print(f"Added '{item_name}' to ticket.")
            else:
                print("Item not found in inventory.")
        elif choice == '2':
            print("\n--- Current Ticket ---")
            if not current_ticket:
                print("Ticket is empty.")
            else:
                total = 0
                for item in current_ticket:
                    price = inventory[item]
                    print(f"- {item}: ${price:.2f}")
                    total += price
                print(f"Current Total: ${total:.2f}")
        elif choice == '3':
            break
        else:
            print("Invalid option.")

def customer_menu(inventory, current_ticket):
    print("\n--- Customer View ---")
    if not current_ticket:
        print("Your ticket is currently empty.")
        return

    print("Items Purchased:")
    total = 0
    for item in current_ticket:
        price = inventory[item]
        print(f"- {item}: ${price:.2f}")
        total += price
    print("-" * 20)
    print(f"Total to pay: ${total:.2f}")

    action = input("\nWould you like to pay now? (y/n): ").strip().lower()
    if action == 'y':
        print("Payment accepted. Thank you for your business!")
        current_ticket.clear()
    else:
        print("Payment pending. Please see a worker.")

def main():
    inventory = {}
    current_ticket = []

    print("Welcome to the Cash Register System!")
    while True:
        print("\n=== Main Menu ===")
        print("1. Shop Owner (Manage Inventory)")
        print("2. Worker (Manage Ticket)")
        print("3. Customer (View & Pay)")
        print("4. Exit")

        choice = input("Select your role: ").strip()

        if choice == '1':
            shop_owner_menu(inventory)
        elif choice == '2':
            worker_menu(inventory, current_ticket)
        elif choice == '3':
            customer_menu(inventory, current_ticket)
        elif choice == '4':
            print("Shutting down register. Goodbye!")
            break
        else:
            print("Invalid selection. Please try again.")

if __name__ == "__main__":
    main()
