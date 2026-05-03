let currentRole = 'owner';
let resourceName = 'pos_system';

// Initialization
document.addEventListener('DOMContentLoaded', () => {
    // Listen for NUI Messages from Lua
    window.addEventListener('message', function(event) {
        let data = event.data;
        if (data.type === "ui") {
            if (data.status) {
                document.body.style.display = "flex";
                if (data.storeName) {
                    document.getElementById('store-title').innerText = data.storeName + " POS";
                    document.getElementById('store-welcome').innerText = "Welcome to " + data.storeName + "!";
                }
            } else {
                document.body.style.display = "none";
            }
        } else if (data.type === "updateState") {
            renderOwnerInventory(data.inventory);
            renderWorkerGrid(data.inventory);
            renderTicket(data.ticket, data.inventory);
            updateCustomerView(data.ticket, data.inventory);
        } else if (data.type === "checkoutResponse") {
            alert(data.message);
        }
    });

    // Close with Escape key
    document.onkeyup = function (data) {
        if (data.which == 27) { // Escape key
            fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
        }
    };

    document.getElementById('add-inventory-form').addEventListener('submit', (e) => {
        e.preventDefault();
        const name = document.getElementById('item-name').value;
        const price = document.getElementById('item-price').value;

        fetch(`https://${GetParentResourceName()}/addInventory`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ name: name, price: parseFloat(price) })
        });

        document.getElementById('item-name').value = '';
        document.getElementById('item-price').value = '';
    });
});

// UI View Switching
function switchRole(role) {
    currentRole = role;

    // Update Buttons
    document.querySelectorAll('.role-selector button').forEach(btn => btn.classList.remove('active'));
    document.getElementById(`btn-${role}`).classList.add('active');

    // Update Views
    document.querySelectorAll('.view-section').forEach(view => view.classList.remove('active'));
    document.getElementById(`view-${role}`).classList.add('active');

    // Role specific UI adjustments
    const workerCheckoutBtn = document.getElementById('btn-worker-checkout');
    if (role === 'worker') {
        workerCheckoutBtn.style.display = 'flex';
    } else {
        workerCheckoutBtn.style.display = 'none';
    }
}

// API Interactions
function addToTicket(name) {
    fetch(`https://${GetParentResourceName()}/addToTicket`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ name: name })
    });
}

function checkout(method = 'cash') {
    fetch(`https://${GetParentResourceName()}/checkout`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ payment_method: method })
    });
}

// Rendering Logic
function renderOwnerInventory(inventory) {
    const list = document.getElementById('owner-inventory-list');
    list.innerHTML = '';

    if (!inventory || Object.keys(inventory).length === 0) {
        list.innerHTML = '<p class="empty-msg">No items in inventory.</p>';
        return;
    }

    for (const [name, price] of Object.entries(inventory)) {
        const itemDiv = document.createElement('div');
        itemDiv.className = 'inventory-item';
        itemDiv.innerHTML = `
            <span>${name}</span>
            <span class="product-price">$${price.toFixed(2)}</span>
        `;
        list.appendChild(itemDiv);
    }
}

function renderWorkerGrid(inventory) {
    const grid = document.getElementById('worker-product-grid');
    grid.innerHTML = '';

    if (!inventory || Object.keys(inventory).length === 0) {
        grid.innerHTML = '<p class="empty-msg" style="grid-column: 1/-1;">No items available. Owner must add items first.</p>';
        return;
    }

    for (const [name, price] of Object.entries(inventory)) {
        const card = document.createElement('div');
        card.className = 'product-card';
        card.onclick = () => addToTicket(name);
        card.innerHTML = `
            <div class="product-name">${name}</div>
            <div class="product-price">$${price.toFixed(2)}</div>
        `;
        grid.appendChild(card);
    }
}

function renderTicket(ticket, inventory) {
    const container = document.getElementById('ticket-items');
    const totalDisplay = document.getElementById('ticket-total');

    container.innerHTML = '';

    if (!ticket || ticket.length === 0) {
        container.innerHTML = '<p class="empty-msg">Ticket is empty.</p>';
        totalDisplay.textContent = '$0.00';
        return;
    }

    let total = 0;
    ticket.forEach(item => {
        const price = inventory[item] || 0;
        total += price;
        const div = document.createElement('div');
        div.className = 'ticket-item';
        div.innerHTML = `
            <span>${item}</span>
            <span>$${price.toFixed(2)}</span>
        `;
        container.appendChild(div);
    });

    totalDisplay.textContent = `$${total.toFixed(2)}`;
}

function updateCustomerView(ticket, inventory) {
    const paymentSection = document.getElementById('payment-section');
    const totalDisplay = document.getElementById('customer-total-display');
    const msg = document.querySelector('.customer-msg');

    if (ticket && ticket.length > 0) {
        paymentSection.style.display = 'block';
        let total = 0;
        ticket.forEach(item => { total += (inventory[item] || 0); });
        totalDisplay.textContent = `$${total.toFixed(2)}`;
        msg.textContent = 'Please review your items. Ready to pay?';
    } else {
        paymentSection.style.display = 'none';
        msg.textContent = 'Please review your items on the ticket screen.';
    }
}
