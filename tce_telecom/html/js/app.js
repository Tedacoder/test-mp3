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
        case 'networkState':
            let signalBars = document.querySelector('.signal-bars');
            if (data.hasSignal) {
                signalBars.style.opacity = '1';
                document.getElementById('network-signal').innerHTML = '<i class="fa-solid fa-signal"></i> 5G';
            } else {
                signalBars.style.opacity = '0.3';
                document.getElementById('network-signal').innerHTML = '<i class="fa-solid fa-ban"></i> SOS';
            }
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

function renderCameraApp() {
    return `
        <div style="display:flex; flex-direction:column; height:100%; align-items:center; justify-content:center;">
            <div id="camera-viewfinder" style="width:100%; height:250px; background:#222; border-radius:15px; position:relative; overflow:hidden; display:flex; align-items:center; justify-content:center; margin-bottom:20px;">
                <!-- Transparent center so the GTA game world shows through behind the NUI -->
                <i class="fa-solid fa-expand" style="color:rgba(255,255,255,0.3); font-size:40px;"></i>
                <div id="camera-filter-overlay" style="position:absolute; inset:0; pointer-events:none; filter:none; transition: backdrop-filter 0.3s;"></div>
            </div>

            <div style="display:flex; gap:10px; overflow-x:auto; padding-bottom:15px; width:100%; scroll-snap-type: x mandatory;">
                <button class="filter-btn" data-filter="none" style="padding:5px 10px; border-radius:10px; background:#444; color:white; border:none;">Normal</button>
                <button class="filter-btn" data-filter="grayscale(100%)" style="padding:5px 10px; border-radius:10px; background:#444; color:white; border:none;">B&W</button>
                <button class="filter-btn" data-filter="sepia(80%)" style="padding:5px 10px; border-radius:10px; background:#444; color:white; border:none;">Sepia</button>
                <button class="filter-btn" data-filter="contrast(150%) saturate(120%)" style="padding:5px 10px; border-radius:10px; background:#444; color:white; border:none;">Vivid</button>
            </div>

            <button id="btn-capture-photo" style="width:60px; height:60px; border-radius:50%; background:white; border:4px solid #ccc; cursor:pointer; margin-top:auto; box-shadow: 0 0 15px rgba(255,255,255,0.5);"></button>
        </div>
    `;
}

function setupCameraAppListeners() {
    // Filter selection
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            let filter = e.currentTarget.getAttribute('data-filter');
            // We apply the CSS filter to the NUI body or overlay.
            // In a real implementation, you'd apply this to the game render target.
            document.getElementById('camera-filter-overlay').style.backdropFilter = filter;
        });
    });

    // Capture photo
    document.getElementById('btn-capture-photo').addEventListener('click', () => {
        let filter = document.getElementById('camera-filter-overlay').style.backdropFilter || 'none';

        // Trigger visual flash
        let flash = document.createElement('div');
        flash.style.cssText = "position:absolute; inset:0; background:white; z-index:9999; pointer-events:none; transition:opacity 0.2s;";
        document.body.appendChild(flash);
        setTimeout(() => { flash.style.opacity = '0'; }, 50);
        setTimeout(() => { flash.remove(); }, 250);

        // Send to FiveM client
        if (window.invokeNative) {
            fetch(`https://${GetParentResourceName()}/capturePhoto`, {
                method: 'POST',
                body: JSON.stringify({ filter: filter })
            });
        } else {
            console.log("Photo Captured with filter:", filter);
        }
    });
}

function renderMusicApp() {
    let html = `
        <div style="display:flex; flex-direction:column; height:100%;">
            <h4 style="margin-bottom: 10px; text-align: left;">SoundStream</h4>
            <div style="display:flex; gap:5px; margin-bottom: 15px;">
                <input type="text" id="music-search" placeholder="Search artists, songs..." style="flex-grow:1; padding: 8px 12px; border-radius: 15px; border:none; background:rgba(255,255,255,0.1); color:white; outline:none;">
                <button id="btn-search-music" style="padding: 8px 12px; border-radius: 15px; border:none; background:#ec4899; color:white; cursor:pointer;"><i class="fa-solid fa-magnifying-glass"></i></button>
            </div>

            <div id="music-results" style="overflow-y:auto; flex-grow:1; display:flex; flex-direction:column; gap:10px;">
                <div style="text-align:center; color:var(--text-sub); margin-top:20px;">Search to find music...</div>
            </div>

            <!-- Global Audio Player element that persists while app is open -->
            <audio id="soundstream-player" controls style="width:100%; margin-top:10px; height:40px; display:none;"></audio>
        </div>
    `;
    return html;
}

// Global scope for the audio player so we can stop it if the phone closes
window.currentAudioPlayer = null;

function setupMusicAppListeners() {
    document.getElementById('btn-search-music').addEventListener('click', () => {
        let query = document.getElementById('music-search').value;
        if (!query) return;

        let resultsContainer = document.getElementById('music-results');
        resultsContainer.innerHTML = `<div style="text-align:center;"><i class="fa-solid fa-spinner fa-spin"></i> Searching iTunes...</div>`;

        fetch(`https://itunes.apple.com/search?term=${encodeURIComponent(query)}&limit=10&media=music`)
            .then(res => res.json())
            .then(data => {
                resultsContainer.innerHTML = '';
                if (data.results.length === 0) {
                    resultsContainer.innerHTML = `<div style="text-align:center; color:var(--text-sub);">No results found.</div>`;
                    return;
                }

                data.results.forEach(track => {
                    let trackDiv = document.createElement('div');
                    trackDiv.style.cssText = "display:flex; align-items:center; gap: 10px; background: rgba(255,255,255,0.05); padding: 10px; border-radius: 12px; cursor:pointer;";
                    trackDiv.innerHTML = `
                        <img src="${track.artworkUrl60}" style="width:40px; height:40px; border-radius:8px;">
                        <div style="flex-grow:1; overflow:hidden;">
                            <div style="color:var(--text-main); font-size:13px; font-weight:500; white-space: nowrap; overflow:hidden; text-overflow: ellipsis;">${track.trackName}</div>
                            <div style="color:var(--text-sub); font-size:11px; white-space: nowrap; overflow:hidden; text-overflow: ellipsis;">${track.artistName}</div>
                        </div>
                        <i class="fa-solid fa-circle-play" style="color:#22c55e; font-size:20px;"></i>
                    `;

                    trackDiv.addEventListener('click', () => {
                        let player = document.getElementById('soundstream-player');
                        player.src = track.previewUrl;
                        player.style.display = 'block';
                        player.play();
                        window.currentAudioPlayer = player;
                    });

                    resultsContainer.appendChild(trackDiv);
                });
            })
            .catch(err => {
                resultsContainer.innerHTML = `<div style="text-align:center; color:#f87171;">Error fetching music.</div>`;
            });
    });
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
        } else if (appName === 'music') {
            document.getElementById('app-title').innerText = "Music";
            appBody.innerHTML = renderMusicApp();
            setupMusicAppListeners();
        } else if (appName === 'camera') {
            document.getElementById('app-title').innerText = "Camera";
            appBody.innerHTML = renderCameraApp();
            setupCameraAppListeners();
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
