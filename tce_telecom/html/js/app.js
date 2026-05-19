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

// App Click Handlers
document.querySelectorAll('.app-icon, .dock-icon').forEach(icon => {
    icon.addEventListener('click', (e) => {
        let appName = e.currentTarget.getAttribute('data-app');
        if(!appName) return;

        document.getElementById('app-title').innerText = appName.charAt(0).toUpperCase() + appName.slice(1);
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
