// NUI Message Listener
window.addEventListener('message', (event) => {
    let data = event.data;

    switch(data.action) {
        case 'openPhone':
            document.getElementById('app-root').style.display = 'block';
            setupPhoneState(data.data);
            break;
        case 'closePhone':
            document.getElementById('app-root').style.display = 'none';
            break;
    }
});

function setupPhoneState(phoneData) {
    const container = document.getElementById('phone-container');

    // Set Brand Styling (Swap CSS Classes)
    if (phoneData.brand === 'star') {
        container.classList.remove('itone');
        container.classList.add('star');
        document.getElementById('hardware-notch-itone').classList.add('hidden');
        document.getElementById('hardware-notch-star').classList.remove('hidden');
        document.getElementById('widget-row-itone').classList.add('hidden');
        document.getElementById('widget-row-star').classList.remove('hidden');
        document.getElementById('btn-privacy').classList.remove('hidden');
        document.getElementById('app-badge').innerText = "★";
    } else {
        container.classList.remove('star');
        container.classList.add('itone');
        document.getElementById('hardware-notch-star').classList.add('hidden');
        document.getElementById('hardware-notch-itone').classList.remove('hidden');
        document.getElementById('widget-row-star').classList.add('hidden');
        document.getElementById('widget-row-itone').classList.remove('hidden');
        document.getElementById('btn-privacy').classList.add('hidden');
        document.getElementById('app-badge').innerText = "◎";
    }

    // Set Battery
    document.getElementById('battery-indicator').innerText = phoneData.battery + '%';

    // Apply Damage Overlay
    if (phoneData.screenCracked) {
        document.getElementById('damage-overlay').classList.remove('hidden');
    } else {
        document.getElementById('damage-overlay').classList.add('hidden');
    }

    // Ensure we start on home screen
    document.getElementById('app-container').classList.remove('active');
}

// App Views Generators
function renderBankApp(data) {
    let balance = data ? data.balance : 12450.50;
    let name = data ? data.accountName : "John Doe";
    let html = `
        <div style="text-align:center; margin-bottom: 15px;">
            <h4 style="color:var(--text-sub); margin-bottom: 5px;">Total Balance</h4>
            <h1 style="color:#4ade80; font-size: 32px;">$${balance.toLocaleString('en-US', {minimumFractionDigits: 2})}</h1>
            <p style="font-size: 11px; margin-top:5px;">Welcome, ${name}</p>
        </div>
        <h4 style="border-bottom: 1px solid #333; padding-bottom: 5px;">Recent Transactions</h4>
        <div style="overflow-y:auto; flex-grow:1;">
    `;

    let txs = data ? data.transactions : [
        {type: 'in', amount: 1500, label: 'Paycheck', date: '2023-10-24'},
        {type: 'out', amount: 50, label: '24/7 Store', date: '2023-10-23'},
        {type: 'out', amount: 200, label: 'TCE Telecom Bill', date: '2023-10-23'}
    ];

    txs.forEach(tx => {
        let color = tx.type === 'in' ? '#4ade80' : '#f87171';
        let prefix = tx.type === 'in' ? '+' : '-';
        html += `
            <div style="display:flex; justify-content:space-between; padding: 10px 0; border-bottom: 1px solid rgba(255,255,255,0.05);">
                <div>
                    <div style="color:var(--text-main); font-size:13px;">${tx.label}</div>
                    <div style="color:var(--text-sub); font-size:10px;">${tx.date}</div>
                </div>
                <div style="color:${color}; font-weight:bold; font-size:13px;">${prefix}$${tx.amount.toFixed(2)}</div>
            </div>
        `;
    });
    html += `</div>`;
    return html;
}

function renderContactsApp(data) {
    let html = `
        <h4 style="border-bottom: 1px solid #333; padding-bottom: 5px; margin-bottom: 10px;">Directory</h4>
        <div style="overflow-y:auto; flex-grow:1; display:flex; flex-direction:column; gap:8px;">
    `;

    let contacts = data ? data : [
        {name: "Alice Smith", number: "555-0192"},
        {name: "Bob Jones", number: "555-3841"},
        {name: "Mechanic", number: "555-8899"}
    ];

    contacts.forEach(c => {
        html += `
            <div style="display:flex; align-items:center; gap: 10px; background: rgba(255,255,255,0.05); padding: 10px; border-radius: 12px;">
                <div style="width:35px; height:35px; border-radius:50%; background: #333; display:flex; align-items:center; justify-content:center; font-weight:bold;">${c.name.charAt(0)}</div>
                <div>
                    <div style="color:var(--text-main); font-size:14px; font-weight:500;">${c.name}</div>
                    <div style="color:var(--text-sub); font-size:11px;">${c.number}</div>
                </div>
                <button style="margin-left:auto; background:#22c55e; border:none; border-radius:50%; width:30px; height:30px; color:white; cursor:pointer;"><i class="fa-solid fa-phone"></i></button>
            </div>
        `;
    });
    html += `</div>
        <button style="margin-top:10px; padding:10px; border-radius:10px; background:#007AFF; color:white; border:none; width:100%; cursor:pointer;">+ Add Contact</button>
    `;
    return html;
}

// App Click Handlers
document.querySelectorAll('.app-icon, .dock-icon').forEach(icon => {
    icon.addEventListener('click', (e) => {
        let appName = e.currentTarget.getAttribute('data-app');
        if(!appName) return;

        document.getElementById('app-title').innerText = appName.charAt(0).toUpperCase() + appName.slice(1);
        let appBody = document.getElementById('app-view-body');

        // Render specific apps
        if (appName === 'bank') {
            appBody.innerHTML = renderBankApp(null); // passing null uses dummy data for preview

            // In FiveM:
            if (window.invokeNative) {
                fetch(`https://${GetParentResourceName()}/getBankData`, { method: 'POST', body: JSON.stringify({}) })
                .then(res => res.json()).then(data => { appBody.innerHTML = renderBankApp(data); });
            }
        } else if (appName === 'phone' || appName === 'contacts') {
            document.getElementById('app-title').innerText = "Contacts";
            appBody.innerHTML = renderContactsApp(null);

            // In FiveM:
            if (window.invokeNative) {
                fetch(`https://${GetParentResourceName()}/getContacts`, { method: 'POST', body: JSON.stringify({}) })
                .then(res => res.json()).then(data => { appBody.innerHTML = renderContactsApp(data); });
            }
        } else {
            appBody.innerHTML = `<h3>Under Construction</h3><p>The ${appName} module is not fully integrated yet.</p>`;
        }

        document.getElementById('app-container').classList.add('active');
    });
});

// App Back/Close Buttons
document.getElementById('btn-home').addEventListener('click', () => {
    document.getElementById('app-container').classList.remove('active');
});

// Close phone using escape key
document.addEventListener('keyup', function(e) {
    if (e.key === 'Escape') {
        // Dummy fetch for browser testing, will fail in browser but work in FiveM
        if (window.invokeNative) {
            fetch(`https://${GetParentResourceName()}/closePhone`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            }).then(() => {
                document.getElementById('app-root').style.display = 'none';
            });
        } else {
            document.getElementById('app-root').style.display = 'none';
        }
    }
});
