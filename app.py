from flask import Flask, render_template, request, jsonify
import config

app = Flask(__name__)

# In-memory storage for simplicity
inventory = {}
current_ticket = []

@app.route('/')
def index():
    return render_template('index.html', store_name=config.STORE_NAME)

@app.route('/api/inventory', methods=['GET'])
def get_inventory():
    return jsonify(inventory)

@app.route('/api/inventory', methods=['POST'])
def add_to_inventory():
    data = request.json
    name = data.get('name')
    price = data.get('price')
    if not name or price is None:
        return jsonify({'error': 'Missing name or price'}), 400
    try:
        price = float(price)
        if price < 0:
            return jsonify({'error': 'Price cannot be negative'}), 400
        inventory[name] = price
        return jsonify({'message': f'Item {name} added', 'inventory': inventory})
    except ValueError:
        return jsonify({'error': 'Invalid price format'}), 400

@app.route('/api/ticket', methods=['GET'])
def get_ticket():
    total = 0
    ticket_details = []
    for item in current_ticket:
        if item in inventory:
            price = inventory[item]
            total += price
            ticket_details.append({'name': item, 'price': price})
    return jsonify({'items': ticket_details, 'total': total})

@app.route('/api/ticket', methods=['POST'])
def add_to_ticket():
    data = request.json
    name = data.get('name')
    if name not in inventory:
        return jsonify({'error': 'Item not found in inventory'}), 404
    current_ticket.append(name)
    return get_ticket()

@app.route('/api/checkout', methods=['POST'])
def checkout():
    global current_ticket
    data = request.json or {}
    payment_method = data.get('payment_method', 'cash')

    total = sum(inventory[item] for item in current_ticket if item in inventory)
    current_ticket = []

    if payment_method == 'bank':
        msg = f'Checkout successful. ${total:.2f} deducted directly from customer bank.'
    else:
        msg = f'Checkout successful. ${total:.2f} paid in cash.'

    return jsonify({'message': msg, 'paid': total, 'method': payment_method})

if __name__ == '__main__':
    app.run(debug=True, port=5000)
