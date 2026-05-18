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
    console.log("Loading phone state: ", phoneData);

    // Set Battery
    document.getElementById('battery-indicator').innerText = phoneData.battery + '%';

    // Show privacy button for Star brand
    if (phoneData.brand === 'star') {
        document.getElementById('btn-privacy').classList.remove('hidden');
    } else {
        document.getElementById('btn-privacy').classList.add('hidden');
    }

    // Apply Damage Overlay
    if (phoneData.screenCracked) {
        document.getElementById('damage-overlay').classList.remove('hidden');
    } else {
        document.getElementById('damage-overlay').classList.add('hidden');
    }
}

// Close phone using escape key
document.addEventListener('keyup', function(e) {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/closePhone`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(() => {
            document.getElementById('app-root').style.display = 'none';
        });
    }
});

// Privacy Toggle Callback
document.getElementById('btn-privacy').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/togglePrivacyMode`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});
