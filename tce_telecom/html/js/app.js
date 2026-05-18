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
        container.classList.remove('os-itones');
        container.classList.add('os-star');
        document.getElementById('btn-privacy').classList.remove('hidden');
    } else {
        container.classList.remove('os-star');
        container.classList.add('os-itones');
        document.getElementById('btn-privacy').classList.add('hidden');
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
    document.getElementById('app-container').classList.add('hidden');
}

// App Click Handlers
document.querySelectorAll('.app-icon').forEach(icon => {
    icon.addEventListener('click', (e) => {
        let appName = e.currentTarget.getAttribute('data-app');
        if(!appName) return;

        document.getElementById('app-title').innerText = appName.charAt(0).toUpperCase() + appName.slice(1);
        document.getElementById('app-container').classList.remove('hidden');
    });
});

// Home Button
document.getElementById('btn-home').addEventListener('click', () => {
    document.getElementById('app-container').classList.add('hidden');
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
