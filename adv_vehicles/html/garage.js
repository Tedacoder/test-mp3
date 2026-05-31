window.addEventListener('message', (event) => {
    if (event.data.action === "openGarage") {
        document.getElementById('garage-container').style.display = 'flex';
        document.getElementById('garage-name').innerText = event.data.garage;
        renderVehicles(event.data.vehicles);
    }
});

function closeUI() {
    document.getElementById('garage-container').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/closeGarage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function renderVehicles(vehicles) {
    const list = document.getElementById('vehicle-list');
    list.innerHTML = '';

    vehicles.forEach(veh => {
        const div = document.createElement('div');
        div.className = 'vehicle-card';

        let stateText = veh.state === 1 ? "In Garage" : (veh.state === 2 ? "Impounded" : "Street");
        let btnHtml = '';

        if (veh.state === 1) {
            btnHtml = `<button class="btn" onclick="spawnVehicle('${veh.plate}', '${veh.vehicle}')">Spawn</button>`;
        } else if (veh.state === 0) {
            btnHtml = `<button class="btn" disabled>On Street</button>`;
        } else if (veh.state === 2) {
            btnHtml = `<button class="btn" onclick="recoverImpound('${veh.plate}')">Recover ($500)</button>`;
        }

        div.innerHTML = `
            <div class="vehicle-info">
                <strong>Name: ${veh.alias ? veh.alias.toUpperCase() : veh.vehicle.toUpperCase()}</strong>
                <p>Plate: ${veh.plate}</p>
                <p>Fuel: ${veh.fuel.toFixed(1)}% | Engine: ${(veh.engine_health/10).toFixed(1)}%</p>
                <p>Status: ${stateText}</p>
            </div>
            <div class="vehicle-actions" style="display:flex; flex-direction:column; gap:5px;">
                ${btnHtml}
                <button class="btn" style="background:#28a745" onclick="duplicateKey('${veh.plate}')">Duplicate Key</button>
                <button class="btn" style="background:#17a2b8" onclick="renameVehicle('${veh.plate}')">Rename</button>
            </div>
        `;
        list.appendChild(div);
    });
}

function spawnVehicle(plate, vehicle) {
    document.getElementById('garage-container').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/spawnVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plate, vehicle })
    });
}

function recoverImpound(plate) {
    document.getElementById('garage-container').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/recoverImpound`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plate })
    });
}

function duplicateKey(plate) {
    document.getElementById('garage-container').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/duplicateKeyNui`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plate })
    });
}

document.addEventListener('keydown', (e) => {
    if (e.key === "Escape") closeUI();
});

function renameVehicle(plate) {
    document.getElementById('garage-container').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/renameVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plate })
    });
}
