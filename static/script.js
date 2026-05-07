// Initialization
document.addEventListener('DOMContentLoaded', () => {
    refreshInventory();
    refreshTicket();

    document.getElementById('add-inventory-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const name = document.getElementById('item-name').value;
        const price = document.getElementById('item-price').value;

        const response = await fetch('/api/inventory', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, price })
        });

        if (response.ok) {
            document.getElementById('item-name').value = '';
            document.getElementById('item-price').value = '';
            refreshInventory();
        } else {
            alert('Failed to add item.');
        }
    });
});

// UI View Switching
function switchRole(role) {
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

    refreshInventory();
    refreshTicket();
}

// API Interactions
async function refreshInventory() {
    const response = await fetch('/api/inventory');
    const data = await response.json();

    renderOwnerInventory(data);
    renderWorkerGrid(data);
}

async function refreshTicket() {
    const response = await fetch('/api/ticket');
    const data = await response.json();

    renderTicket(data);
    updateCustomerView(data);
}

async function addToTicket(name) {
    await fetch('/api/ticket', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name })
    });
    refreshTicket();
}

async function checkout(method = 'cash') {
    const response = await fetch('/api/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ payment_method: method })
    });
    if (response.ok) {
        const data = await response.json();
        alert(data.message);
        refreshTicket();
    }
}

// Rendering Logic
function renderOwnerInventory(inventory) {
    const list = document.getElementById('owner-inventory-list');
    list.innerHTML = '';

    if (Object.keys(inventory).length === 0) {
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

    if (Object.keys(inventory).length === 0) {
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

function renderTicket(ticketData) {
    const container = document.getElementById('ticket-items');
    const totalDisplay = document.getElementById('ticket-total');

    container.innerHTML = '';

    if (ticketData.items.length === 0) {
        container.innerHTML = '<p class="empty-msg">Ticket is empty.</p>';
        totalDisplay.textContent = '$0.00';
        return;
    }

    ticketData.items.forEach(item => {
        const div = document.createElement('div');
        div.className = 'ticket-item';
        div.innerHTML = `
            <span>${item.name}</span>
            <span>$${item.price.toFixed(2)}</span>
        `;
        container.appendChild(div);
    });

    totalDisplay.textContent = `$${ticketData.total.toFixed(2)}`;
}

function updateCustomerView(ticketData) {
    const paymentSection = document.getElementById('payment-section');
    const totalDisplay = document.getElementById('customer-total-display');
    const msg = document.querySelector('.customer-msg');

    if (ticketData.items.length > 0) {
        paymentSection.style.display = 'block';
        totalDisplay.textContent = `$${ticketData.total.toFixed(2)}`;
        msg.textContent = 'Please review your items. Ready to pay?';
    } else {
        paymentSection.style.display = 'none';
        msg.textContent = 'Please review your items on the ticket screen.';
    }
}
