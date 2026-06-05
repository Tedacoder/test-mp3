const escapeHtml = (unsafe) => {
    if (!unsafe) return "";
    return String(unsafe)
         .replace(/&/g, "&amp;")
         .replace(/</g, "&lt;")
         .replace(/>/g, "&gt;")
         .replace(/"/g, "&quot;")
         .replace(/'/g, "&#039;");
}

let currentSelectedPlayer = null;

// Universal Global Handler listening to NUI Visibility Commands from client.lua
window.addEventListener('message', function(event) {
    let item = event.data;
    if (item.action === "openPanel") {
        document.getElementById('admin-root').style.display = "flex";
        document.body.style.display = "block";
        refreshPlayers();
        fetchCooldowns();
    } else if (item.action === "closePanel") {
        document.getElementById('admin-root').style.display = "none";
        document.body.style.display = "none";
    }

    if (item.type === "updatePlayerList") {
        renderPlayerList(item.players);
        document.getElementById('vitalsCount').textContent = item.players.length;
    }

    if (item.type === "updatePlayerPreview" && item.info) {
        document.getElementById('inspectorName').textContent = item.info.name;
        document.getElementById('inspectorId').textContent = `[ID: ${item.info.id}]`;
        document.getElementById('inspectorJob').textContent = `Job: ${item.info.job || 'Unknown'} | Cash: $${item.info.cash || 0} | Bank: $${item.info.bank || 0}`;
        if (item.info.avatarUrl) {
            document.getElementById('inspectorAvatar').src = item.info.avatarUrl;
        }
    }

    if (item.type === "updateInventory") {
        renderInventoryGrid(item.items);
    }

    if (item.type === "toast" || item.action === "notify") {
        showToast(item.message || item.text || "Notification");
    }

    if (item.type === "updateLogsFeed") {
        renderLogs(item.lines);
    }

    if (item.type === "updateAuditTrail") {
        renderDetailedLogs(item.trail);
    }

    if (item.type === "updateAdminChat" && item.messages) {
        const chatBox = document.getElementById("adminChatMessages");
        if (chatBox) {
            chatBox.innerHTML = item.messages.map(msg =>
                `<div class="mb-2"><span class="text-purple-400 font-bold">${msg.sender}</span> <span class="text-xs text-gray-500">[${msg.time}]</span>: <span class="text-gray-300">${msg.text}</span></div>`
            ).join('');
            chatBox.scrollTop = chatBox.scrollHeight;
        }
    }

    if (item.type === "updateAnnouncements" && item.announcements) {
        const box = document.getElementById("announcementHistory");
        if (box) {
            box.innerHTML = item.announcements.map(a =>
                `<div class="mb-2 p-2 bg-white/5 rounded"><span class="text-yellow-400 font-bold">${a.admin}</span> <span class="text-xs text-gray-500">[${a.time}]</span>: <span class="text-gray-300">${a.message}</span></div>`
            ).join('');
            box.scrollTop = box.scrollHeight;
        }
    }

    if (item.type === "showAnnouncement" && item.message) {
        const banner = document.createElement("div");
        banner.style.position = "fixed";
        banner.style.top = "20px";
        banner.style.left = "50%";
        banner.style.transform = "translateX(-50%)";
        banner.style.backgroundColor = "rgba(0, 0, 0, 0.85)";
        banner.style.border = "2px solid #f1c40f";
        banner.style.boxShadow = "0 0 20px rgba(241, 196, 15, 0.5)";
        banner.style.borderRadius = "10px";
        banner.style.padding = "20px 40px";
        banner.style.zIndex = "9999";
        banner.style.pointerEvents = "none";
        banner.style.textAlign = "center";
        banner.style.transition = "opacity 0.5s ease-in-out";
        banner.style.opacity = "0";

        banner.innerHTML = `
            <div style="color: #f1c40f; font-size: 1.5rem; font-weight: bold; text-transform: uppercase; margin-bottom: 5px;">Server Announcement</div>
            <div style="color: white; font-size: 1.2rem;">${escapeHtml(item.message)}</div>
        `;

        document.body.appendChild(banner);

        // Play alert sound
        const audio = new Audio("https://cdn.pixabay.com/download/audio/2021/08/04/audio_0625c1539c.mp3?filename=message-incoming-132126.mp3");
        audio.volume = 0.5;
        audio.play().catch(e => console.log("Audio play failed:", e));

        // Fade in
        setTimeout(() => banner.style.opacity = "1", 10);

        // Flash effect for 10 seconds
        let isFlashing = true;
        const flashInterval = setInterval(() => {
            if (isFlashing) {
                banner.style.boxShadow = banner.style.boxShadow.includes("0px") ? "0 0 30px rgba(241, 196, 15, 0.9)" : "0 0 10px rgba(241, 196, 15, 0.3)";
            }
        }, 500);

        // Fade out and remove after 10 seconds
        setTimeout(() => {
            isFlashing = false;
            banner.style.opacity = "0";
            setTimeout(() => banner.remove(), 500);
            clearInterval(flashInterval);
        }, 10000);
    }

    if (item.type === "updateReports" && item.reports) {
        const list = document.getElementById("reportsList");
        if (list) {
            list.innerHTML = item.reports.map(r => `
                <div class="p-3 bg-white/5 border border-white/10 rounded flex justify-between items-center">
                    <div>
                        <div class="font-bold text-yellow-400">#${escapeHtml(r.id)} - ${escapeHtml(r.playerName)}</div>
                        <div class="text-xs text-gray-300 mt-1">${escapeHtml(r.reason)}</div>
                        <div class="text-[10px] text-gray-500 mt-1">Status: ${escapeHtml(r.status)} | Claimed By: ${escapeHtml(r.claimedBy) || 'None'} | ${escapeHtml(r.time)}</div>
                    </div>
                    <div class="flex gap-2">
                        ${r.status === 'open' ? `<button onclick="claimReport(${r.id})" class="px-3 py-1 bg-blue-600 hover:bg-blue-500 rounded text-xs">Claim</button>` : ''}
                        ${r.status !== 'closed' ? `<button onclick="closeReport(${r.id})" class="px-3 py-1 bg-red-600 hover:bg-red-500 rounded text-xs">Close</button>` : ''}
                        <button onclick="messageReport(${r.id})" class="px-3 py-1 bg-green-600 hover:bg-green-500 rounded text-xs">Message</button>
                    </div>
                </div>
            `).join('');
        }
    }

    if (item.type === "updateCheatAlerts" && item.alerts) {
        const list = document.getElementById("cheatAlertsList");
        if (list) {
            list.innerHTML = item.alerts.map(a => `
                <div class="p-3 bg-red-500/10 border border-red-500/30 rounded">
                    <div class="font-bold text-red-400">${escapeHtml(a.name)} (ID: ${escapeHtml(a.id)})</div>
                    <div class="text-xs text-gray-300 mt-1">${escapeHtml(a.reason)}</div>
                    <div class="text-[10px] text-gray-500 mt-1">${escapeHtml(a.time)}</div>
                </div>
            `).join('');
        }
    }

    if (item.type === "updateGarage" && item.vehicles) {
        renderGarageList(item.vehicles, item.targetId);
    }

    if (item.type === "updateWhitelistItems" && item.whitelist) {
        renderWhitelist(item.whitelist);
    }

    if (item.type === "updatePermissions" && item.permissions) {
        renderPermissions(item.permissions);
    }

    if (item.type === "updateCooldownsUI" && item.cooldowns) {
        renderCooldowns(item.cooldowns);
    }

    if (item.type === "updateCoords" || item.type === "updateEntityInfo") {
         // Implement Dev tools rendering if UI exists
    }
});

function claimReport(id) {
    fetch(`https://${GetParentResourceName()}/claimReport`, { method: "POST", body: JSON.stringify({ reportId: id }) });
}

function closeReport(id) {
    fetch(`https://${GetParentResourceName()}/resolveReport`, { method: "POST", body: JSON.stringify({ reportId: id }) });
}

async function messageReport(id) {
    const message = await _showPromptModal("Enter message to player:");
    if (message) {
        fetch(`https://${GetParentResourceName()}/sendReportMessage`, { method: "POST", body: JSON.stringify({ reportId: id, message }) });
    }
}

function fetchWhitelistItems() {
    const id = document.getElementById("whitelistPlayerId").value;
    if (!id) return showToast("Enter Player ID");
    fetch(`https://${GetParentResourceName()}/admin:getWhitelistItems`, { method: "POST", body: JSON.stringify({ targetId: id }) });
}

function renderWhitelist(wl) {
    const types = ['clothing', 'tattoo', 'skin'];
    types.forEach(type => {
        const el = document.getElementById(`whitelist${type.charAt(0).toUpperCase() + type.slice(1)}`);
        if (el) {
            el.innerHTML = (wl[type] || []).map(item => `
                <div class="flex justify-between items-center p-1 bg-black/50 border border-white/5 rounded">
                    <span class="text-xs text-gray-300">${item}</span>
                    <button onclick="removeWhitelistItem('${type}', '${item}')" class="text-red-500 hover:text-red-400"><i class="fas fa-times"></i></button>
                </div>
            `).join('');
        }
    });
}

function addWhitelistItem() {
    const targetId = document.getElementById("whitelistPlayerId").value;
    const itemType = document.getElementById("whitelistType").value;
    const itemId = document.getElementById("whitelistItemName").value;
    if (!targetId || !itemId) return showToast("Missing fields");
    fetch(`https://${GetParentResourceName()}/admin:addWhitelistItem`, { method: "POST", body: JSON.stringify({ targetId, itemType, itemId }) });
    setTimeout(fetchWhitelistItems, 500);
}

function removeWhitelistItem(itemType, itemId) {
    const targetId = document.getElementById("whitelistPlayerId").value;
    if (!targetId) return;
    fetch(`https://${GetParentResourceName()}/admin:removeWhitelistItem`, { method: "POST", body: JSON.stringify({ targetId, itemType, itemId }) });
    setTimeout(fetchWhitelistItems, 500);
}

const availablePerms = [
    "viewPlayers", "viewInventory", "removeItems", "giveItems", "manageVehicles",
    "warnPlayers", "kickPlayers", "banPlayers", "healPlayers", "killPlayers",
    "teleportPlayers", "spectatePlayers", "giveMoney", "giveClothing", "manageJobs",
    "viewReports", "messagePlayers", "viewCheatAlerts", "freezePlayers", "viewAdminChat", "manageWhitelist"
];

function fetchPermissions() {
    const id = document.getElementById("permPlayerId").value;
    if (!id) return showToast("Enter Player ID");
    // Trigger updatePermissions event by requesting it from server (add corresponding lua if missing, assuming standard flow)
    // As a fallback, we just send a mock update via a new callback or assume the server sends it on request.
    // For now, we will create the checkboxes assuming we receive them.
    fetch(`https://${GetParentResourceName()}/getPermissions`, { method: "POST", body: JSON.stringify({ targetId: id }) });
}

function renderPermissions(perms) {
    const list = document.getElementById("permissionsList");
    if (list) {
        list.innerHTML = availablePerms.map(p => `
            <div class="flex items-center gap-2 p-2 bg-white/5 border border-white/10 rounded">
                <input type="checkbox" id="perm_${p}" onchange="updatePermission('${p}', this.checked)" ${perms[p] ? 'checked' : ''} class="w-4 h-4 rounded bg-black/50 border border-white/20 accent-purple-500">
                <label for="perm_${p}" class="text-xs text-gray-300">${p}</label>
            </div>
        `).join('');
    }
}

function updatePermission(permKey, value) {
    const targetId = document.getElementById("permPlayerId").value;
    if (!targetId) return;
    fetch(`https://${GetParentResourceName()}/updatePermission`, { method: "POST", body: JSON.stringify({ targetId, permKey, value }) });
}

const actionCooldownsList = ["removeItem", "addItem", "addVehicle", "removeVehicle", "kick", "ban", "warn", "heal", "kill", "bring", "teleportTo", "giveMoney", "setJob", "removeJob"];

function fetchCooldowns() {
    fetch(`https://${GetParentResourceName()}/admin:getCooldowns`, { method: "POST", body: JSON.stringify({}) });
}

function renderCooldowns(cds) {
    const list = document.getElementById("cooldownsList");
    if (list) {
        list.innerHTML = actionCooldownsList.map(a => `
            <div class="flex flex-col gap-1 p-2 bg-white/5 border border-white/10 rounded">
                <div class="flex justify-between items-center text-xs text-gray-300">
                    <label>${a}</label>
                    <span id="cd_val_${a}" class="font-bold text-green-400">${cds[a] || 0}s</span>
                </div>
                <input type="range" id="cd_${a}" class="cd-slider w-full accent-green-500" min="0" max="60" value="${cds[a] || 0}" oninput="document.getElementById('cd_val_${a}').textContent = this.value + 's'">
            </div>
        `).join('');
    }
}

function saveCooldowns() {
    let payload = {};
    actionCooldownsList.forEach(a => {
        const slider = document.getElementById(`cd_${a}`);
        if (slider) payload[a] = parseInt(slider.value);
    });
    fetch(`https://${GetParentResourceName()}/admin:updateCooldowns`, { method: "POST", body: JSON.stringify({ cooldowns: payload }) });
    showToast("Cooldowns updated!");
}

function closeMenu() {
    fetch(`https://${GetParentResourceName()}/closeMenu`, { method: "POST", body: JSON.stringify({}) });
}

document.addEventListener('keydown', function(event) {
    if (event.key === "Escape") {
        const promptModal = document.getElementById("promptModal");
        if (promptModal && !promptModal.classList.contains("hidden")) {
            document.getElementById("promptCancel").click();
            return;
        }
        if (document.getElementById('admin-root').style.display === "flex" || document.getElementById('admin-root').style.display === "block" || document.getElementById('admin-root').style.display === "") {
            closeMenu();
        }
    }
});

function refreshPlayers() {
    fetch(`https://${GetParentResourceName()}/getActivePlayers`, { method: "POST", body: JSON.stringify({}) });
}

function renderPlayerList(players) {
    const list = document.getElementById("dynamicPlayerList");
    const bulkList = document.getElementById("bulkPlayerList");
    let html = "";
    let bulkHtml = "";
    players.forEach(p => {
        html += `
        <div onclick="selectPlayer(${p.id})" class="p-4 rounded-xl border border-white/5 bg-white/[0.02] hover:bg-white/[0.04] flex justify-between items-center cursor-pointer transition-all">
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg bg-zinc-800 flex items-center justify-center font-mono font-bold text-gray-300">[${p.id}]</div>
                <div>
                    <h3 class="font-bold text-gray-300 tracking-wide">${p.name}</h3>
                </div>
            </div>
        </div>`;

        bulkHtml += `
        <div class="flex items-center gap-2 p-1">
            <input type="checkbox" id="bulk_${p.id}" value="${p.id}" class="bulk-player-cb w-3 h-3 rounded bg-black/50 border border-white/20 accent-red-500">
            <label for="bulk_${p.id}" class="text-[10px] text-gray-300 cursor-pointer">[${p.id}] ${p.name}</label>
        </div>`;
    });
    list.innerHTML = html;
    if (bulkList) bulkList.innerHTML = bulkHtml;
}

function toggleBulkSelectAll(checked) {
    document.querySelectorAll(".bulk-player-cb").forEach(cb => cb.checked = checked);
}

async function executeBulkAction(action) {
    const targets = Array.from(document.querySelectorAll(".bulk-player-cb:checked")).map(cb => parseInt(cb.value));
    if (targets.length === 0) return showToast("No players selected.");

    let payload = { action, targets };

    if (action === "kick") {
        const reason = await _showPromptModal("Enter bulk kick reason:");
        if (!reason) return;
        payload.reason = reason;
    } else if (action === "ban") {
        const reason = await _showPromptModal("Enter bulk ban reason:");
        if (!reason) return;
        const durationStr = await _showPromptModal("Enter duration in seconds (0 for perm):", "0");
        payload.reason = reason;
        payload.duration = parseInt(durationStr) || 0;
    } else if (action === "giveItem") {
        const item = await _showPromptModal("Enter item name:");
        if (!item) return;
        const amountStr = await _showPromptModal("Enter amount:", "1");
        payload.item = item;
        payload.amount = parseInt(amountStr) || 1;
    }

    fetch(`https://${GetParentResourceName()}/bulkAction`, { method: "POST", body: JSON.stringify(payload) });
    showToast(`Executed bulk ${action} on ${targets.length} players.`);
}

function selectPlayer(id) {
    currentSelectedPlayer = id;
    fetch(`https://${GetParentResourceName()}/getPlayerInfo`, { method: "POST", body: JSON.stringify({ targetId: id }) });
    fetch(`https://${GetParentResourceName()}/getInventory`, { method: "POST", body: JSON.stringify({ targetId: id }) });
    fetch(`https://${GetParentResourceName()}/getPlayerVehicles`, { method: "POST", body: JSON.stringify({ targetId: id }) });
}

function renderInventoryGrid(items) {
    const grid = document.getElementById("dynamicInventoryGrid");
    if (!items) {
        grid.innerHTML = `<div class="col-span-5 text-center text-gray-500 text-xs py-4">No items</div>`;
        return;
    }

    const slotsMap = {};
    for (const key in items) {
        if (items[key]) {
            slotsMap[items[key].slot] = items[key];
        }
    }

    let html = "";
    for (let i = 1; i <= 50; i++) {
        const item = slotsMap[i];
        if (item) {
            const imgPath = `nui://ox_inventory/web/images/${item.name}.png`;
            html += `
            <div class="aspect-square rounded-lg border border-white/5 bg-white/[0.02] hover:border-purple-500/30 relative flex items-center justify-center transition-all cursor-grab active:cursor-grabbing group"
                 oncontextmenu="removeInvItem(event, ${currentSelectedPlayer}, '${item.name}', ${item.count || item.amount}, ${i}, this.getAttribute('data-meta'), this)"
                 data-meta='${JSON.stringify(item.metadata || {}).replace(/'/g, "&apos;")}'>
                <div class="absolute top-1 left-1.5 text-[9px] font-mono text-gray-500">${i}</div>
                <img src="${imgPath}" class="w-2/3 h-2/3 object-contain opacity-80 group-hover:scale-110 transition-transform" onerror="this.style.display='none'" />
                <div class="absolute bottom-1 right-1.5 text-[10px] font-mono text-gray-400 font-black">${item.count || item.amount}x</div>
            </div>`;
        } else {
            html += `<div class="aspect-square rounded-lg border border-white/[0.02] bg-white/[0.01]"></div>`;
        }
    }
    grid.innerHTML = html;
}

function removeInvItem(event, targetId, itemName, count, slot, metaStr, element) {
    event.preventDefault();
    fetch(`https://${GetParentResourceName()}/removeItem`, {
        method: "POST",
        body: JSON.stringify({ targetId, item: itemName, amount: count, silent: true, slot, metadata: JSON.parse(metaStr) })
    }).then(() => {
        element.style.pointerEvents = "none";
        element.style.opacity = "0.2";
        showToast(`Removed ${count}x ${itemName} from slot ${slot}`);
    });
}

function renderLogs(lines) {
    const box = document.getElementById("dynamicLogs");
    if (!lines || !box) return;
    box.innerHTML = lines.map(l => `<div class="mb-1.5">${escapeHtml(l)}</div>`).join('');
    box.scrollTop = box.scrollHeight;
}

function renderDetailedLogs(trail) {
    const list = document.getElementById("fullLogsList");
    if (!list) return;
    if (!trail || trail.length === 0) {
        list.innerHTML = `<div class="text-gray-500 text-center py-10 text-xl font-bold bg-black/40 rounded-xl border border-white/5">No detailed logs found.</div>`;
        return;
    }

    list.innerHTML = trail.reverse().map(t => `
        <div class="mb-3 p-4 bg-black/40 border border-white/5 rounded-xl hover:border-[var(--menu-accent)] transition-all flex flex-col gap-2">
            <div class="flex justify-between items-center border-b border-white/5 pb-2">
                <span class="text-sm font-mono text-gray-500">${escapeHtml(t.time)}</span>
                <span class="px-2 py-1 rounded bg-[var(--menu-accent)] text-black text-xs font-bold uppercase tracking-wider">${escapeHtml(t.action)}</span>
            </div>
            <div class="flex gap-4 items-center">
                <div class="flex flex-col">
                    <span class="text-xs text-gray-500 uppercase tracking-wider">Admin</span>
                    <span class="font-bold text-white">${escapeHtml(t.admin)}</span>
                </div>
                <i class="fas fa-arrow-right text-[var(--menu-accent)] opacity-50"></i>
                <div class="flex flex-col">
                    <span class="text-xs text-gray-500 uppercase tracking-wider">Target</span>
                    <span class="font-bold text-white">${escapeHtml(t.target)}</span>
                </div>
            </div>
            <div class="mt-2 text-gray-400 bg-white/5 p-2 rounded text-sm font-mono break-all">
                ${escapeHtml(t.details)}
            </div>
        </div>
    `).join('');
}

function renderGarageList(vehicles, targetId) {
    const list = document.getElementById("garageList");
    const inspectorList = document.getElementById("inspectorGarageList");

    if (!vehicles || vehicles.length === 0) {
        const emptyMsg = `<div class="p-4 text-center text-gray-500 font-bold bg-black/40 rounded-xl border border-white/5">No vehicles found.</div>`;
        if (list) list.innerHTML = emptyMsg;
        if (inspectorList) inspectorList.innerHTML = emptyMsg;
        return;
    }

    const html = vehicles.map(v => `
        <div class="p-3 rounded-lg border border-white/5 bg-black/40 flex justify-between items-center hover:border-purple-500/20 transition-all mb-2">
            <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded bg-white/5 flex items-center justify-center text-zinc-400">
                    <i class="fas fa-car text-sm"></i>
                </div>
                <div>
                    <h4 class="text-xs font-bold text-gray-200">${escapeHtml(v.label) || escapeHtml(v.model) || 'Unknown Model'}</h4>
                    <p class="text-[10px] font-mono text-zinc-500">Plate: [ ${escapeHtml(v.plate)} ]</p>
                </div>
            </div>

            <div class="flex flex-col items-end gap-1">
                <span class="text-[9px] px-1.5 py-0.5 rounded font-bold ${v.status === 'Stored' ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : 'bg-rose-500/10 text-rose-400 border-rose-500/20'} border">
                    ${escapeHtml(v.status)}
                </span>
                <span class="text-[9px] font-mono text-zinc-600"><i class="fas fa-gas-pump mr-1"></i>${escapeHtml(v.fuel)}%</span>
            </div>
        </div>
    `).join('');

    if (list) list.innerHTML = html;
    if (inspectorList) inspectorList.innerHTML = html;
}

function removeVehicle(targetId, plate) {
    fetch(`https://${GetParentResourceName()}/removeVehicle`, { method: "POST", body: JSON.stringify({ targetId, plate }) });
    setTimeout(fetchGarage, 500); // refresh list
}

function showToast(msg) {
    const t = document.getElementById("toast");
    t.textContent = msg;
    t.classList.remove("translate-x-[150%]", "opacity-0");
    setTimeout(() => {
        t.classList.add("translate-x-[150%]", "opacity-0");
    }, 3000);
}

// Action Button Hooks
document.getElementById('btnHeal').addEventListener('click', () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    fetch(`https://${GetParentResourceName()}/healPlayer`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer }) });
});

document.getElementById('btnSpectate').addEventListener('click', () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    fetch(`https://${GetParentResourceName()}/spectatePlayer`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer }) });
    closeMenu();
    closeMenu();
});

document.getElementById('btnFreeze').addEventListener('click', () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    fetch(`https://${GetParentResourceName()}/freezePlayer`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer }) });
});

document.getElementById('btnBan').addEventListener('click', async () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    const reason = await _showPromptModal("Enter ban reason:");
    if (!reason) return;
    const durationStr = await _showPromptModal("Enter ban duration in seconds (0 for perm):", "0");
    const duration = parseInt(durationStr) || 0;
    fetch(`https://${GetParentResourceName()}/banPlayer`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer, reason, duration }) });
});


document.getElementById('btnKick').addEventListener('click', async () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    const reason = await _showPromptModal("Enter kick reason:");
    if (!reason) return;
    fetch(`https://${GetParentResourceName()}/kickPlayer`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer, reason }) });
});

document.getElementById('btnWarn').addEventListener('click', async () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    const reason = await _showPromptModal("Enter warning reason:");
    if (!reason) return;
    fetch(`https://${GetParentResourceName()}/warnPlayer`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer, reason }) });
});

document.getElementById('btnGiveMoney').addEventListener('click', async () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    const account = await _showPromptModal("Account type (cash or bank):", "cash");
    if (!account) return;
    const amountStr = await _showPromptModal("Amount to give:", "1000");
    const amount = parseInt(amountStr) || 0;
    fetch(`https://${GetParentResourceName()}/giveMoney`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer, account, amount }) });
});

document.getElementById('btnGiveClothing').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/triggerPedMenu`, { method: "POST", body: JSON.stringify({}) });
    closeMenu();
});

document.getElementById('btnAddVehicle').addEventListener('click', async () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    const model = await _showPromptModal("Vehicle Model (e.g. adder):");
    if (!model) return;
    const garage = await _showPromptModal("Garage ID:", "pillboxgarage");
    if (!garage) return;
    fetch(`https://${GetParentResourceName()}/addVehicle`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer, vehicleModel: model, plate: "", garage, preset: "" }) });
    closeMenu();
});

document.getElementById('btnSetJob').addEventListener('click', async () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    const job = await _showPromptModal("Job name:");
    if (!job) return;
    const gradeStr = await _showPromptModal("Job grade (number):", "0");
    const grade = parseInt(gradeStr) || 0;
    fetch(`https://${GetParentResourceName()}/setJob`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer, job, grade }) });
});


document.getElementById('btnKill').addEventListener('click', () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    fetch(`https://${GetParentResourceName()}/killPlayer`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer }) });
});

document.getElementById('btnBring').addEventListener('click', () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    fetch(`https://${GetParentResourceName()}/bringPlayer`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer }) });
});

document.getElementById('btnGoTo').addEventListener('click', () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    fetch(`https://${GetParentResourceName()}/gotoPlayer`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer }) });
});

document.getElementById('btnRemoveJob').addEventListener('click', () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    fetch(`https://${GetParentResourceName()}/removeJob`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer }) });
});

document.getElementById('btnUndo').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/admin:undoLastAction`, { method: "POST", body: JSON.stringify({}) });
});

function showPromptModal(title, defaultValue = "") {
  return new Promise((resolve) => {
    const result = window.prompt(title, defaultValue);
    resolve(result);
  });
}

function _showPromptModal(title, defaultValue = "") {
  return new Promise((resolve) => {
    const modal = document.getElementById("promptModal");
    const titleEl = document.getElementById("promptTitle");
    const inputEl = document.getElementById("promptInput");
    const confirmBtn = document.getElementById("promptConfirm");
    const cancelBtn = document.getElementById("promptCancel");

    titleEl.textContent = title;
    inputEl.value = defaultValue;
    modal.classList.remove("hidden");
    inputEl.focus();

    const cleanup = () => {
      modal.classList.add("hidden");
      confirmBtn.removeEventListener("click", onConfirm);
      cancelBtn.removeEventListener("click", onCancel);
    };

    const onConfirm = () => {
      resolve(inputEl.value);
      cleanup();
    };

    const onCancel = () => {
      resolve(null);
      cleanup();
    };

    confirmBtn.addEventListener("click", onConfirm);
    cancelBtn.addEventListener("click", onCancel);
  });
}

function copyCoordsToClipboard(type) {
    fetch(`https://${GetParentResourceName()}/requestCoordCopy`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ format: type })
    });
}


function changeMenuTheme(colorRGB, glowRGBA) {
    const root = document.documentElement;
    root.style.setProperty('--menu-accent', colorRGB);
    root.style.setProperty('--menu-accent-glow', glowRGBA);
}

// Default theme selector integration
document.addEventListener("DOMContentLoaded", () => {
    // Add theme options if a selector exists, or just expose it globally
    window.changeMenuTheme = changeMenuTheme;
});


document.addEventListener("DOMContentLoaded", () => {
    const navBtns = document.querySelectorAll(".nav-btn");
    navBtns.forEach(btn => {
        btn.addEventListener("click", (e) => {
            const tabName = btn.getAttribute("data-tab");

            // Hide all views
            document.querySelectorAll(".view-players, .view-garage, .view-chat, .view-reports, .view-whitelist, .view-permissions, .view-logs, .view-settings").forEach(v => {
                v.classList.add("hidden");
            });

            // Deactivate all buttons
            navBtns.forEach(b => {
                b.classList.remove("text-white", "bg-gradient-to-br", "from-purple-600", "to-indigo-600", "shadow-[0_0_15px_rgba(147,51,234,0.3)]");
                b.classList.add("text-gray-400");
                b.style.background = '';
                b.style.boxShadow = '';
            });

            // Activate selected view
            if (tabName === "players") {
                document.querySelectorAll(".view-players").forEach(v => v.classList.remove("hidden"));
            } else {
                const targetView = document.querySelector(".view-" + tabName);
                if (targetView) targetView.classList.remove("hidden");
            }

            // Activate button styling
            btn.classList.remove("text-gray-400");
            btn.classList.add("text-white");
            btn.style.background = `rgba(var(--menu-accent), 0.8)`;
            btn.style.boxShadow = `0 0 15px var(--menu-accent-glow)`;
        });
    });
});

function fetchGarage() {
    const idStr = document.getElementById("cidGarage").value;
    const targetId = parseInt(idStr) || currentSelectedPlayer;
    if (!targetId) return showToast("Select a player or enter a valid Server ID");
    fetch(`https://${GetParentResourceName()}/getPlayerVehicles`, { method: "POST", body: JSON.stringify({ targetId: targetId }) });
}

document.getElementById('btnGiveVehicleGarageTab').addEventListener('click', async () => {
    const model = document.getElementById("vehicleModel").value;
    const plate = document.getElementById("vehiclePlate").value;
    const garage = document.getElementById("garageSelect").value;
    const cid = document.getElementById("cidGarage").value;

    if (!model || !cid) return showToast("CID and Model required.");
    fetch(`https://${GetParentResourceName()}/addVehicle`, { method: "POST", body: JSON.stringify({ targetId: cid, vehicleModel: model, plate: plate, garage: garage, preset: "" }) });
    showToast(`Sending vehicle ${model} to garage ${garage}`);
});

function sendAdminChat() {
    const msg = document.getElementById("adminChatInput").value;
    if (!msg) return;
    fetch(`https://${GetParentResourceName()}/sendAdminChat`, { method: "POST", body: JSON.stringify({ message: msg }) });
    document.getElementById("adminChatInput").value = "";
}

function sendAnnouncement() {
    const msg = document.getElementById("announcementInput").value;
    if (!msg) return;
    fetch(`https://${GetParentResourceName()}/sendAnnouncement`, { method: "POST", body: JSON.stringify({ message: msg }) });
    document.getElementById("announcementInput").value = "";
}

// Add Item from Player Inspector (Requested feature restore)
function addInvItem() {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    _showPromptModal("Enter item name to give:").then(item => {
        if (!item) return;
        _showPromptModal("Enter amount:").then(amountStr => {
            const amount = parseInt(amountStr) || 1;
            fetch(`https://${GetParentResourceName()}/addItem`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer, item, amount }) });
        });
    });
}
