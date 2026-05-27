let currentSelectedPlayer = null;

// Universal Global Handler listening to NUI Visibility Commands from client.lua
window.addEventListener('message', function(event) {
    let item = event.data;
    if (item.action === "openPanel") {
        document.getElementById('admin-root').style.display = "flex";
        document.body.style.display = "block";
        refreshPlayers();
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
});

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
        if (document.getElementById('admin-root').style.display === "flex") {
            closeMenu();
        }
    }
});

function refreshPlayers() {
    fetch(`https://${GetParentResourceName()}/getActivePlayers`, { method: "POST", body: JSON.stringify({}) });
}

function renderPlayerList(players) {
    const list = document.getElementById("dynamicPlayerList");
    let html = "";
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
    });
    list.innerHTML = html;
}

function selectPlayer(id) {
    currentSelectedPlayer = id;
    fetch(`https://${GetParentResourceName()}/getPlayerInfo`, { method: "POST", body: JSON.stringify({ targetId: id }) });
    fetch(`https://${GetParentResourceName()}/getInventory`, { method: "POST", body: JSON.stringify({ targetId: id }) });
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
    if (!lines) return;
    box.innerHTML = lines.map(l => `<div class="mb-1.5">${l}</div>`).join('');
    box.scrollTop = box.scrollHeight;
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
});

document.getElementById('btnFreeze').addEventListener('click', () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    fetch(`https://${GetParentResourceName()}/freezePlayer`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer }) });
});

document.getElementById('btnBan').addEventListener('click', async () => {
    if (!currentSelectedPlayer) return showToast("Select a player first.");
    const reason = await showPromptModal("Enter ban reason:");
    if (!reason) return;
    const durationStr = await showPromptModal("Enter ban duration in seconds (0 for perm):", "0");
    const duration = parseInt(durationStr) || 0;
    fetch(`https://${GetParentResourceName()}/banPlayer`, { method: "POST", body: JSON.stringify({ targetId: currentSelectedPlayer, reason, duration }) });
});

function showPromptModal(title, defaultValue = "") {
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
