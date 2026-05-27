// Handle opening/closing panel
window.addEventListener('message', (event) => {
  if (event.data.action === 'openPanel') {
    document.querySelector('.admin-container').classList.add('show');
    document.body.style.display = 'block';
    document.body.classList.add('panel-open');

    // Update title
    const titleEl = document.getElementById('sidebarTitle');
    if (titleEl && event.data.title) {
        titleEl.innerHTML = `🛡️ ${event.data.title}`;
    }

    // Auto-refresh player list and jobs when panel opens
    setTimeout(() => {
      refreshPlayers();
      fetch(`https://${GetParentResourceName()}/getJobs`, { method: "POST", body: JSON.stringify({}) });
    }, 100);
  } else if (event.data.action === 'closePanel') {
    document.querySelector('.admin-container').classList.remove('show');
    document.body.classList.remove('panel-open');
  }

  // Admin chat updates
  if (event.data.type === 'updateAdminChat' && event.data.messages) {
    console.log('[Admin Chat] Received messages:', event.data.messages);
    const log = document.getElementById('adminChatMessages');
    if (log) {
      log.innerHTML = '';
      event.data.messages.forEach(msg => {
        const entry = document.createElement('div');
        entry.className = 'chat-message';
        entry.style.marginBottom = '6px';
        entry.innerHTML = `<b style="color:var(--color-primary);">${msg.sender}</b> <span style='color:var(--color-text-dim);font-size:11px;'>[${msg.time}]</span><br><span style="color:var(--color-text);">${msg.text}</span>`;
        log.appendChild(entry);
      });
      log.scrollTop = log.scrollHeight;
      console.log('[Admin Chat] Messages displayed, count:', event.data.messages.length);
    } else {
      console.error('[Admin Chat] Element adminChatMessages not found!');
    }
  }

  // Player info for management tab
  if (event.data.type === 'playerInfo' && event.data.info) {
    console.log('[Management] Received player info:', event.data.info);
    const info = event.data.info;
    const infoPanel = document.getElementById('playerManagementInfo');
    if (infoPanel) {
      infoPanel.style.display = 'block';
      document.getElementById('mgmtPlayerName').textContent = info.name || '-';
      document.getElementById('mgmtPlayerJob').textContent = info.job || '-';
      document.getElementById('mgmtPlayerGrade').textContent = info.grade || '0';
      document.getElementById('mgmtPlayerCash').textContent = info.cash || '0';
      document.getElementById('mgmtPlayerBank').textContent = (info.money - info.cash) || '0';
    }
  }

  // Jobs list for management tab
  if (event.data.type === 'jobsList' && event.data.jobs) {
    console.log('[Management] Received jobs list');
    const jobSelect = document.getElementById('jobSelect');
    const gradeSelect = document.getElementById('jobGradeSelect');
    if (jobSelect) {
      jobSelect.innerHTML = '<option value="">Select Job...</option>';
      Object.keys(event.data.jobs).forEach(jobName => {
        const opt = document.createElement('option');
        opt.value = jobName;
        opt.textContent = event.data.jobs[jobName].label || jobName;
        jobSelect.appendChild(opt);
      });
      // Update grades when job changes
      jobSelect.addEventListener('change', function() {
        const selectedJob = this.value;
        gradeSelect.innerHTML = '';
        if (selectedJob && event.data.jobs[selectedJob] && event.data.jobs[selectedJob].grades) {
          Object.keys(event.data.jobs[selectedJob].grades).forEach(gradeNum => {
            const grade = event.data.jobs[selectedJob].grades[gradeNum];
            const opt = document.createElement('option');
            opt.value = gradeNum;
            opt.textContent = `${grade.name} (Grade ${gradeNum})`;
            gradeSelect.appendChild(opt);
          });
        } else {
          for (let i = 0; i <= 4; i++) {
            const opt = document.createElement('option');
            opt.value = i;
            opt.textContent = `Grade ${i}`;
            gradeSelect.appendChild(opt);
          }
        }
      });
    }
  }
});

// Sidebar tab switching logic
const tabBtns = document.querySelectorAll('.tab-btn');
const tabContents = document.querySelectorAll('.tab-content');

// Switch tab function (can be called programmatically)
function switchTab(tabName) {
  tabBtns.forEach(b => b.classList.remove('active'));
  const targetBtn = document.querySelector(`[data-tab="${tabName}"]`);
  if (targetBtn) targetBtn.classList.add('active');

  tabContents.forEach(c => {
    if (c.id === tabName + 'Tab') {
      c.classList.remove('hidden');
    } else {
      c.classList.add('hidden');
    }
  });
}

tabBtns.forEach(btn => {
  btn.addEventListener('click', () => {
    const tab = btn.getAttribute('data-tab');
    switchTab(tab);
  });
});

// Update dashboard stats
function updateDashboardStats(players, reports, alerts) {
  const playersEl = document.getElementById('onlinePlayersCount');
  const reportsEl = document.getElementById('activeReportsCount');
  const alertsEl = document.getElementById('cheatAlertsCount');

  if (playersEl && players !== undefined) playersEl.textContent = players.length || 0;
  if (reportsEl && reports !== undefined) reportsEl.textContent = reports.filter(r => r.status === 'open').length || 0;
  if (alertsEl && alerts !== undefined) alertsEl.textContent = alerts.length || 0;
}

// Toast notification helper (defined early for use throughout)
window.showToast = function(msg) {
  const toast = document.getElementById("toast");
  if (!toast) return;
  toast.textContent = msg;
  toast.classList.remove("hidden");
  setTimeout(() => toast.classList.add("hidden"), 3000);
}

// Notification sound helper
window.playNotificationSound = function() {
  // Simple beep using Web Audio API (no external resources needed)
  try {
    const audioContext = new (window.AudioContext || window.webkitAudioContext)();
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();

    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);

    oscillator.frequency.value = 800;
    oscillator.type = 'sine';

    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);

    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + 0.5);
  } catch(e) {
    console.log('Audio notification failed:', e);
  }
}

// Export logs function
function exportLogs() {
  let logText = "";
  const logsBox = document.getElementById("adminChatMessages"); // define logsBox
  logsBox.querySelectorAll(".chat-message").forEach(line => {
    logText += line.textContent + "\n";
  });

  const blob = new Blob([logText], { type: "text/plain" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "admin_logs.txt";
  document.body.appendChild(a);
  a.click();
  setTimeout(() => {
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }, 100);
}

            // Cooldown adjustment UI for gods
            let cooldowns = {};
            window.addEventListener("message", (event) => {
                // Real-time notifications: sound for all except announcements
                if (event.data.type === "toast" || event.data.action === "notify" || event.data.action || event.data.type) {
                  showToast(event.data.message || event.data.text || "Notification");
                  // Play sound for all except announcements
                  if (!(event.data.action === "announcement" || event.data.type === "announcement")) {
                    playNotificationSound();
                  }
                }
              if (event.data.type === "updateCooldowns" && event.data.cooldowns) {
                cooldowns = event.data.cooldowns;
                renderCooldownGrid();
              }
            });

            function renderCooldownGrid() {
              const grid = document.getElementById("cooldownGrid");
              if (!grid) return;
              grid.innerHTML = "";
              Object.entries(cooldowns).forEach(([action, value]) => {
                const row = document.createElement("div");
                row.className = "cooldown-row";
                row.innerHTML = `<label>${action}</label> <input type='range' min='0' max='30' value='${value}' id='cd_${action}' /> <span id='cdval_${action}'>${value}s</span>`;
                grid.appendChild(row);
                const slider = row.querySelector(`#cd_${action}`);
                const valSpan = row.querySelector(`#cdval_${action}`);
                slider.addEventListener("input", () => {
                  valSpan.textContent = slider.value + "s";
                });
              });
            }

            document.getElementById("saveCooldownsBtn").addEventListener("click", () => {
              const newCooldowns = {};
              Object.keys(cooldowns).forEach(action => {
                const slider = document.getElementById(`cd_${action}`);
                if (slider) newCooldowns[action] = parseInt(slider.value);
              });
              fetch(`https://${GetParentResourceName()}/admin:updateCooldowns`, {
                method: "POST",
                body: JSON.stringify({ cooldowns: newCooldowns })
              });
            });
          // Role-based UI: hide/disable actions for non-gods
          let userPermissions = {};
          window.addEventListener("message", (event) => {
            if (event.data.type === "refreshPermissions" && event.data.perms) {
              userPermissions = event.data.perms;
              updateRoleBasedUI();
            }
          });

          function updateRoleBasedUI() {
            // Inventory
            document.querySelector("button[onclick='addItem()']").disabled = !userPermissions.giveItems;
            document.querySelector("button[onclick='removeItem(false)']").disabled = !userPermissions.removeItems;
            document.querySelector("button[onclick='removeItem(true)']").disabled = !userPermissions.removeItems;
            // Player Actions
            document.querySelector("button[onclick='warnPlayer()']").disabled = !userPermissions.warnPlayers;
            document.querySelector("button[onclick='kickPlayer()']").disabled = !userPermissions.kickPlayers;
            document.querySelector("button[onclick='banPlayer()']").disabled = !userPermissions.banPlayers;
            document.querySelector("button[onclick='healPlayer()']").disabled = !userPermissions.healPlayers;
            document.querySelector("button[onclick='killPlayer()']").disabled = !userPermissions.killPlayers;
            document.querySelector("button[onclick='bringPlayer()']").disabled = !userPermissions.teleportPlayers;
            document.querySelector("button[onclick='gotoPlayer()']").disabled = !userPermissions.teleportPlayers;
            document.querySelector("button[onclick='spectatePlayer()']").disabled = !userPermissions.spectatePlayers;
            document.querySelector("button[onclick='freezePlayer()']").disabled = !userPermissions.freezePlayers;
            // Management
            document.querySelector("button[onclick='giveMoney()']").disabled = !userPermissions.giveMoney;
            document.querySelector("button[onclick='giveClothing()']").disabled = !userPermissions.giveClothing;
            document.querySelector("button[onclick='setJob()']").disabled = !userPermissions.manageJobs;
            document.querySelector("button[onclick='removeJob()']").disabled = !userPermissions.manageJobs;
            // Permissions tab only for gods
            document.getElementById("permissionsTab").style.display = userPermissions.isGod ? "block" : "none";
          }
        // Undo last action
        window.undoLastAction = function() {
          fetch(`https://${GetParentResourceName()}/admin:undoLastAction`, { method: "POST", body: JSON.stringify({}) });
        }
      // Player search/filter
      const playerSelect = document.getElementById("playerSelectMaster");
      const playerSearch = document.createElement("input");
      playerSearch.type = "text";
      playerSearch.placeholder = "Search players...";
      playerSelect && playerSelect.parentNode.insertBefore(playerSearch, playerSelect);
      let allPlayers = [];

      window.addEventListener("message", (event) => {
        if (event.data.type === "updatePlayerList" && event.data.players) {
          console.log('[Player List] Received players:', event.data.players);
          allPlayers = event.data.players;
          renderPlayerSelect(allPlayers);
          updateDashboardStats(allPlayers, undefined, undefined);
          console.log('[Player List] Rendered count:', allPlayers.length);
        }
      });

      playerSearch.addEventListener("input", () => {
        const term = playerSearch.value.toLowerCase();
        const filtered = allPlayers.filter(p =>
          p.name.toLowerCase().includes(term) || String(p.id).includes(term)
        );
        renderPlayerSelect(filtered);
      });

      function renderPlayerSelect(players) {
        // Render bulk selection list
        const bulkList = document.getElementById("bulkPlayerList");
        if (bulkList) {
          bulkList.innerHTML = "";
          players.forEach(p => {
            const div = document.createElement("div");
            div.innerHTML = `<label><input type="checkbox" class="bulk-cb" value="${p.id}"> ${p.name} [${p.id}]</label>`;
            bulkList.appendChild(div);
          });
        }

        // Update all player dropdowns across all tabs
        const dropdowns = [
          'playerSelectMaster',
          'cidInventoryDropdown',
          'cidGarageDropdown',
          'cidPlayerActionsDropdown',
          'cidManagementDropdown'
        ];

        dropdowns.forEach(id => {
          const select = document.getElementById(id);
          if (select) {
            select.innerHTML = "";
            players.forEach(p => {
              const opt = document.createElement("option");
              opt.value = p.id;
              opt.textContent = `${p.name} [${p.id}]`;
              select.appendChild(opt);
            });
          }
        });

        console.log('[Player List] Populated', dropdowns.length, 'dropdowns with', players.length, 'players');
      }

    // Bulk selection logic
    const bulkSelectAll = document.getElementById("bulkSelectAll");
    if (bulkSelectAll) {
      bulkSelectAll.addEventListener("change", (e) => {
        const checkboxes = document.querySelectorAll(".bulk-cb");
        checkboxes.forEach(cb => cb.checked = e.target.checked);
      });
    }

    function getSelectedBulkPlayers() {
      const selected = [];
      document.querySelectorAll(".bulk-cb:checked").forEach(cb => selected.push(cb.value));
      return selected;
    }

    window.bulkKick = function() {
      const selected = getSelectedBulkPlayers();
      if (selected.length === 0) return showToast("Select at least one player.");
      const reason = document.getElementById("actionReason").value || "Bulk kicked by admin";
      fetch(`https://${GetParentResourceName()}/bulkAction`, {
        method: "POST",
        body: JSON.stringify({ action: "kick", targets: selected, reason })
      });
    }

    window.bulkBan = function() {
      const selected = getSelectedBulkPlayers();
      if (selected.length === 0) return showToast("Select at least one player.");
      const reason = document.getElementById("actionReason").value || "Bulk banned by admin";
      fetch(`https://${GetParentResourceName()}/bulkAction`, {
        method: "POST",
        body: JSON.stringify({ action: "ban", targets: selected, reason, duration: 86400 })
      });
    }

    window.bulkGiveItem = async function() {
      const selected = getSelectedBulkPlayers();
      if (selected.length === 0) return showToast("Select at least one player.");
      const item = await showPromptModal("Enter item name to give to all selected players:");
      if (!item) return;
      const amountStr = await showPromptModal(`Enter amount of ${item} to give:`, "1");
      const amount = parseInt(amountStr);
      if (isNaN(amount) || amount <= 0) return showToast("Invalid amount.");

      fetch(`https://${GetParentResourceName()}/bulkAction`, {
        method: "POST",
        body: JSON.stringify({ action: "giveItem", targets: selected, item, amount })
      });
    }

    // Vehicle search/filter
    const garageList = document.getElementById("garageList");
    const garageSearch = document.createElement("input");
    garageSearch.type = "text";
    garageSearch.placeholder = "Search vehicles...";
    garageList && garageList.parentNode.insertBefore(garageSearch, garageList);
    let allVehicles = [];

    window.addEventListener("message", (event) => {
      if (event.data.type === "updateGarage" && event.data.vehicles) {
        allVehicles = event.data.vehicles;
        renderGarageList(allVehicles);
      }
    });

    garageSearch.addEventListener("input", () => {
      const term = garageSearch.value.toLowerCase();
      const filtered = allVehicles.filter(v =>
        v.vehicle.toLowerCase().includes(term) || v.plate.toLowerCase().includes(term)
      );
      renderGarageList(filtered);
    });

    function renderGarageList(vehicles) {
      if (!garageList) return;
      garageList.innerHTML = "";
      vehicles.forEach(v => {
        const el = document.createElement("li");
        el.className = "garage-item";
        el.innerHTML = `<span>${v.vehicle}</span> <span>[${v.plate}]</span>`;
        garageList.appendChild(el);
      });
    }

    // Logs search/filter
    const logsBox = document.getElementById("logsBox");
    const logsSearch = document.createElement("input");
    logsSearch.type = "text";
    logsSearch.placeholder = "Search logs...";
    logsBox && logsBox.parentNode.insertBefore(logsSearch, logsBox);
    let allLogs = [];

    window.addEventListener("message", (event) => {
      if (event.data.type === "updateLogsFeed" && event.data.lines) {
        allLogs = event.data.lines;
        renderLogsBox(allLogs);
      }
    });

    function renderLogsBox(logs) {
        if(!logsBox) return;
        logsBox.innerHTML = '';
        logs.forEach(l => {
            const p = document.createElement('p');
            p.textContent = l;
            logsBox.appendChild(p);
        })
    }

 function renderInventoryGrid(items) {
  const inventoryGrid = document.getElementById('inventoryGrid');
  if (!inventoryGrid) return;
  inventoryGrid.innerHTML = "";
  items.forEach(item => {
    const el = document.createElement("div");
    el.className = "inventory-item";
    el.innerHTML = `<span>${item.name}</span> <span>x${item.count}</span>`;
    inventoryGrid.appendChild(el);
  });
}

// Add item
function addItem() {
  const item = document.getElementById("itemName").value;
  const amount = parseInt(document.getElementById("itemAmount").value);
  const cidInput = document.getElementById("cidInventory").value;
  const cidDropdown = document.getElementById("cidInventoryDropdown").value;
  const cid = cidDropdown || cidInput;
  if (!item || isNaN(amount) || !cid) return showToast("Please enter item name, amount, and select a player");
  fetch(`https://${GetParentResourceName()}/addItem`, {
    method: "POST",
    body: JSON.stringify({ targetId: cid, item, amount })
  });
}

function removeItem(silent) {
  const item = document.getElementById("itemName").value;
  const amount = parseInt(document.getElementById("itemAmount").value);
  const cidInput = document.getElementById("cidInventory").value;
  const cidDropdown = document.getElementById("cidInventoryDropdown").value;
  const cid = cidDropdown || cidInput;
  if (!item || isNaN(amount) || !cid) return showToast("Please enter item name, amount, and select a player");
  fetch(`https://${GetParentResourceName()}/removeItem`, {
    method: "POST",
    body: JSON.stringify({ targetId: cid, item, amount, silent })
  });
}

// Garage
function addVehicleFromUI() {
  const vehicleModel = document.getElementById("vehicleModel").value;
  const plate = document.getElementById("vehiclePlate").value;
  const garage = document.getElementById("garageSelect").value;
  const preset = document.getElementById("presetSelect").value;
  const cidInput = document.getElementById("cidGarage").value;
  const cidDropdown = document.getElementById("cidGarageDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!vehicleModel || !targetId) return showToast("Please enter vehicle model and select a player");
  fetch(`https://${GetParentResourceName()}/addVehicle`, {
    method: "POST",
    body: JSON.stringify({ targetId, vehicleModel, plate, garage, preset })
  });
}

// Player actions
function warnPlayer() {
  const reason = document.getElementById("actionReason").value;
  const cidInput = document.getElementById("cidPlayerActions").value;
  const cidDropdown = document.getElementById("cidPlayerActionsDropdown").value;
  const targetId = cidDropdown || cidInput;
  console.log('[Player Actions] warnPlayer - targetId:', targetId);
  if (!targetId) {
    showToast("Please select a player from the dropdown or enter a player ID");
    return;
  }
  fetch(`https://${GetParentResourceName()}/warnPlayer`, {
    method: "POST",
    body: JSON.stringify({ targetId, reason })
  });
}

function kickPlayer() {
  const reason = document.getElementById("actionReason").value;
  const cidInput = document.getElementById("cidPlayerActions").value;
  const cidDropdown = document.getElementById("cidPlayerActionsDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!targetId) return showToast("Please select a player");
  fetch(`https://${GetParentResourceName()}/kickPlayer`, {
    method: "POST",
    body: JSON.stringify({ targetId, reason })
  });
}

function banPlayer() {
  const reason = document.getElementById("actionReason").value;
  const cidInput = document.getElementById("cidPlayerActions").value;
  const cidDropdown = document.getElementById("cidPlayerActionsDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!targetId) return showToast("Please select a player");
  const duration = 86400; // 24 hours default
  fetch(`https://${GetParentResourceName()}/banPlayer`, {
    method: "POST",
    body: JSON.stringify({ targetId, reason, duration })
  });
}

function healPlayer() {
  const cidInput = document.getElementById("cidPlayerActions").value;
  const cidDropdown = document.getElementById("cidPlayerActionsDropdown").value;
  const targetId = cidDropdown || cidInput;
  console.log('[Player Actions] healPlayer - targetId:', targetId);
  if (!targetId) {
    showToast("Please select a player from the dropdown or enter a player ID");
    return;
  }
  fetch(`https://${GetParentResourceName()}/healPlayer`, { method: "POST", body: JSON.stringify({ targetId }) });
}

function killPlayer() {
  const cidInput = document.getElementById("cidPlayerActions").value;
  const cidDropdown = document.getElementById("cidPlayerActionsDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!targetId) return showToast("Please select a player");
  fetch(`https://${GetParentResourceName()}/killPlayer`, { method: "POST", body: JSON.stringify({ targetId }) });
}

function bringPlayer() {
  const cidInput = document.getElementById("cidPlayerActions").value;
  const cidDropdown = document.getElementById("cidPlayerActionsDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!targetId) return showToast("Please select a player");
  fetch(`https://${GetParentResourceName()}/bringPlayer`, { method: "POST", body: JSON.stringify({ targetId }) });
}

function gotoPlayer() {
  const cidInput = document.getElementById("cidPlayerActions").value;
  const cidDropdown = document.getElementById("cidPlayerActionsDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!targetId) return showToast("Please select a player");
  fetch(`https://${GetParentResourceName()}/gotoPlayer`, { method: "POST", body: JSON.stringify({ targetId }) });
}

function spectatePlayer() {
  const cidInput = document.getElementById("cidPlayerActions").value;
  const cidDropdown = document.getElementById("cidPlayerActionsDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!targetId) return showToast("Please select a player");
  fetch(`https://${GetParentResourceName()}/spectatePlayer`, { method: "POST", body: JSON.stringify({ targetId }) });
}

function freezePlayer() {
  const cidInput = document.getElementById("cidPlayerActions").value;
  const cidDropdown = document.getElementById("cidPlayerActionsDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!targetId) return showToast("Please select a player");
  fetch(`https://${GetParentResourceName()}/freezePlayer`, { method: "POST", body: JSON.stringify({ targetId }) });
}

// Management
function giveMoney() {
  const account = document.getElementById("moneyType").value;
  const amount = parseInt(document.getElementById("moneyAmount").value);
  const cidInput = document.getElementById("cidManagement").value;
  const cidDropdown = document.getElementById("cidManagementDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (isNaN(amount) || !targetId) return showToast("Please select a player and enter amount");
  fetch(`https://${GetParentResourceName()}/giveMoney`, {
    method: "POST",
    body: JSON.stringify({ targetId, account, amount })
  });
}

function giveClothing() {
  const cidInput = document.getElementById("cidManagement").value;
  const cidDropdown = document.getElementById("cidManagementDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!targetId) return showToast("Please select a player");
  fetch(`https://${GetParentResourceName()}/giveClothing`, { method: "POST", body: JSON.stringify({ targetId }) });
}

function loadPlayerManagementInfo() {
  const cidInput = document.getElementById("cidManagement").value;
  const cidDropdown = document.getElementById("cidManagementDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!targetId) return showToast("Please select a player");
  console.log('[Management] Loading info for player:', targetId);
  fetch(`https://${GetParentResourceName()}/getPlayerInfo`, {
    method: "POST",
    body: JSON.stringify({ targetId })
  });
}

function setJob() {
  const job = document.getElementById("jobSelect").value;
  const grade = document.getElementById("jobGradeSelect").value;
  const cidInput = document.getElementById("cidManagement").value;
  const cidDropdown = document.getElementById("cidManagementDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!targetId || !job) return showToast("Please select a player and job");
  console.log('[Management] Setting job:', job, 'grade:', grade, 'for player:', targetId);
  fetch(`https://${GetParentResourceName()}/setJob`, {
    method: "POST",
    body: JSON.stringify({ targetId, job, grade })
  });
}

function removeJob() {
  const cidInput = document.getElementById("cidManagement").value;
  const cidDropdown = document.getElementById("cidManagementDropdown").value;
  const targetId = cidDropdown || cidInput;
  console.log('[Management] Removing job for player:', targetId);
  if (!targetId) return showToast("Please select a player");
  fetch(`https://${GetParentResourceName()}/removeJob`, { method: "POST", body: JSON.stringify({ targetId }) });
}

// Admin chat send
function sendAdminChat() {
  const input = document.getElementById("adminChatInput");
  const message = input.value.trim();
  console.log('[Admin Chat] Attempting to send message:', message);
  if (!message) {
    console.warn('[Admin Chat] Message is empty, not sending');
    return;
  }
  fetch(`https://${GetParentResourceName()}/sendAdminChat`, {
    method: "POST",
    body: JSON.stringify({ message })
  }).then(() => {
    console.log('[Admin Chat] Message sent successfully');
  }).catch(err => {
    console.error('[Admin Chat] Failed to send message:', err);
  });
  input.value = "";
}

// Announcement send
function sendAnnouncement() {
  const input = document.getElementById("announcementInput");
  const message = input.value.trim();
  if (!message) return;
  fetch(`https://${GetParentResourceName()}/sendAnnouncement`, {
    method: "POST",
    body: JSON.stringify({ message })
  });
  input.value = "";
}

// Refresh players
function refreshPlayers() {
  fetch(`https://${GetParentResourceName()}/getActivePlayers`, { method: "POST", body: JSON.stringify({}) });
}

// DOMContentLoaded
window.addEventListener("DOMContentLoaded", () => {
  // Theme selector
  const themeSelector = document.getElementById("themeSelector");
  if (themeSelector) {
    // Load saved theme
    const savedTheme = localStorage.getItem("adminPanelTheme") || "default";
    themeSelector.value = savedTheme;
    document.body.className = savedTheme !== "default" ? `theme-${savedTheme}` : "";

    themeSelector.addEventListener("change", () => {
      const theme = themeSelector.value;
      localStorage.setItem("adminPanelTheme", theme);
      document.body.className = theme !== "default" ? `theme-${theme}` : "";
    });
  }

  // Close menu function
  window.closeMenu = function() {
    document.querySelector('.admin-container').classList.remove('show');
    document.body.classList.remove('panel-open');
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: "POST",
        body: JSON.stringify({})
    });
  };

  // Escape key listener to close menu
  document.addEventListener('keydown', function(event) {
      if (event.key === "Escape") {
          const promptModal = document.getElementById("promptModal");
          if (promptModal && !promptModal.classList.contains("hidden")) {
              document.getElementById("promptCancel").click();
              return;
          }
          if (document.querySelector('.admin-container').classList.contains('show')) {
              window.closeMenu();
          }
      }
  });

  // Admin chat enter key
  const chatInput = document.getElementById("adminChatInput");
  if (chatInput) {
    chatInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") sendAdminChat();
    });
  }
});

// Whitelist management
const whitelistType = document.getElementById("whitelistType");
const whitelistItemId = document.getElementById("whitelistItemId");
const whitelistItemsList = document.getElementById("whitelistItemsList");
let currentWhitelist = { tattoo: [], skin: [], clothing: [] };
let selectedPlayerId = null;

if (typeof playerSelectMaster !== "undefined" && playerSelectMaster) {
  playerSelectMaster.addEventListener("change", () => {
    selectedPlayerId = playerSelectMaster.value;
    fetch(`https://${GetParentResourceName()}/admin:getWhitelistItems`, {
      method: "POST",
      body: JSON.stringify({ targetId: selectedPlayerId })
    });
  });
}

window.addEventListener("message", (event) => {
  if (event.data.type === "updateWhitelistItems" && event.data.whitelist) {
    currentWhitelist = event.data.whitelist;
    renderWhitelistItems(currentWhitelist);
  }
});

function renderWhitelistItems(list) {
  if (!whitelistItemsList) return;
  whitelistItemsList.innerHTML = "";
  ["tattoo", "skin", "clothing", "hair"].forEach(type => {
    if (list[type] && list[type].length > 0) {
      const section = document.createElement("div");
      section.innerHTML = `<b>${type.charAt(0).toUpperCase() + type.slice(1)}:</b> ` + list[type].join(", ");
      whitelistItemsList.appendChild(section);
    }
  });
}

window.addWhitelistItem = function() {
  if (!selectedPlayerId) return;
  const type = whitelistType.value;
  const itemId = whitelistItemId.value.trim();
  if (!itemId) return;
  fetch(`https://${GetParentResourceName()}/admin:addWhitelistItem`, {
    method: "POST",
    body: JSON.stringify({ targetId: selectedPlayerId, itemType: type, itemId })
  });
  whitelistItemId.value = "";
};

window.removeWhitelistItem = function() {
  if (!selectedPlayerId) return;
  const type = whitelistType.value;
  const itemId = whitelistItemId.value.trim();
  if (!itemId) return;
  fetch(`https://${GetParentResourceName()}/admin:removeWhitelistItem`, {
    method: "POST",
    body: JSON.stringify({ targetId: selectedPlayerId, itemType: type, itemId })
  });
  whitelistItemId.value = "";
};

// Developer Tools Functions
let entityInspectorActive = false;

function refreshCoords() {
  fetch(`https://${GetParentResourceName()}/getCoords`, { method: "POST", body: JSON.stringify({}) });
}

function copyVector3() {
  const vec = document.getElementById("currentVector").value;
  if (vec) {
    navigator.clipboard.writeText(vec);
    showToast("vector3 copied to clipboard!");
  }
}

function copyVector4() {
  const vec = document.getElementById("currentVector").value;
  const heading = document.getElementById("currentHeading").value;
  if (vec && heading) {
    const parts = vec.match(/[-\d.]+/g);
    if (parts && parts.length >= 3) {
      const vec4 = `vector4(${parts[0]}, ${parts[1]}, ${parts[2]}, ${heading})`;
      navigator.clipboard.writeText(vec4);
      showToast("vector4 copied to clipboard!");
    }
  }
}

function copyVectorTable() {
  const vec = document.getElementById("currentVector").value;
  const heading = document.getElementById("currentHeading").value;
  if (vec && heading) {
    const parts = vec.match(/[-\d.]+/g);
    if (parts && parts.length >= 3) {
      const table = `{x = ${parts[0]}, y = ${parts[1]}, z = ${parts[2]}, w = ${heading}}`;
      navigator.clipboard.writeText(table);
      showToast("Table format copied to clipboard!");
    }
  }
}

function copyHeading() {
  const heading = document.getElementById("currentHeading").value;
  if (heading) {
    navigator.clipboard.writeText(heading);
    showToast("Heading copied to clipboard!");
  }
}

function toggleEntityInspector() {
  entityInspectorActive = !entityInspectorActive;
  const btn = document.getElementById("entityInspectorBtn");
  if (entityInspectorActive) {
    btn.textContent = "🛑 Stop Inspector";
    btn.style.background = "var(--color-primary)";
    fetch(`https://${GetParentResourceName()}/toggleEntityInspector`, {
      method: "POST",
      body: JSON.stringify({ active: true })
    });
  } else {
    btn.textContent = "🎯 Start Inspector";
    btn.style.background = "";
    fetch(`https://${GetParentResourceName()}/toggleEntityInspector`, {
      method: "POST",
      body: JSON.stringify({ active: false })
    });
  }
}

function inspectClosestEntity() {
  fetch(`https://${GetParentResourceName()}/inspectClosestEntity`, { method: "POST", body: JSON.stringify({}) });
}

function clearEntityInfo() {
  document.getElementById("entityInfo").innerHTML = '<p style="color:var(--color-text-dim);">Aim at an entity and click to inspect it, or use "Inspect Closest" button.</p>';
}

function detectDecorsOnAimed() {
  fetch(`https://${GetParentResourceName()}/detectDecors`, {
    method: "POST",
    body: JSON.stringify({ target: "aimed" })
  });
}

function detectDecorsOnSelf() {
  fetch(`https://${GetParentResourceName()}/detectDecors`, {
    method: "POST",
    body: JSON.stringify({ target: "self" })
  });
}

function detectDecorsOnVehicle() {
  fetch(`https://${GetParentResourceName()}/detectDecors`, {
    method: "POST",
    body: JSON.stringify({ target: "vehicle" })
  });
}

function toggleNoclip() {
  fetch(`https://${GetParentResourceName()}/toggleNoclip`, { method: "POST", body: JSON.stringify({}) });
}

function toggleGodMode() {
  fetch(`https://${GetParentResourceName()}/toggleGodMode`, { method: "POST", body: JSON.stringify({}) });
}

function toggleInvisible() {
  fetch(`https://${GetParentResourceName()}/toggleInvisible`, { method: "POST", body: JSON.stringify({}) });
}

function fixVehicle() {
  fetch(`https://${GetParentResourceName()}/fixVehicle`, { method: "POST", body: JSON.stringify({}) });
}

function deleteAimedEntity() {
  fetch(`https://${GetParentResourceName()}/deleteAimedEntity`, { method: "POST", body: JSON.stringify({}) });
}

async function spawnVehicleAtCoords() {
  const model = await showPromptModal("Enter vehicle model:");
  if (model) {
    fetch(`https://${GetParentResourceName()}/spawnVehicleAtCoords`, {
      method: "POST",
      body: JSON.stringify({ model })
    });
  }
}

// Listen for dev tools updates
window.addEventListener("message", (event) => {
  if (event.data.type === "updateCoords") {
    document.getElementById("currentVector").value = event.data.vector;
    document.getElementById("currentHeading").value = event.data.heading;
  }

  if (event.data.type === "updateEntityInfo") {
    const info = event.data.info;
    let html = `<div style="color:var(--color-text);">`;
    html += `<div style="color:var(--color-primary);font-weight:bold;margin-bottom:8px;">${info.type}</div>`;
    html += `<div><span style="color:var(--color-text-dim);">Model:</span> ${info.model} (${info.modelHash})</div>`;
    html += `<div><span style="color:var(--color-text-dim);">Entity ID:</span> ${info.entity}</div>`;
    html += `<div><span style="color:var(--color-text-dim);">Network ID:</span> ${info.netId}</div>`;
    html += `<div><span style="color:var(--color-text-dim);">Health:</span> ${info.health}/${info.maxHealth}</div>`;
    html += `<div><span style="color:var(--color-text-dim);">Position:</span> vector3(${info.coords.x}, ${info.coords.y}, ${info.coords.z})</div>`;
    html += `<div><span style="color:var(--color-text-dim);">Heading:</span> ${info.heading}</div>`;
    if (info.speed) html += `<div><span style="color:var(--color-text-dim);">Speed:</span> ${info.speed} mph</div>`;
    if (info.plate) html += `<div><span style="color:var(--color-text-dim);">Plate:</span> ${info.plate}</div>`;
    if (info.isPlayer !== undefined) html += `<div><span style="color:var(--color-text-dim);">Is Player:</span> ${info.isPlayer ? 'Yes' : 'No'}</div>`;
    html += `</div>`;
    document.getElementById("entityInfo").innerHTML = html;
  }

  if (event.data.type === "updateDecorInfo") {
    const decors = event.data.decors;
    let html = `<div style="color:var(--color-text);">`;
    html += `<div style="color:var(--color-primary);font-weight:bold;margin-bottom:8px;">Found ${decors.length} Decor(s)</div>`;
    if (decors.length === 0) {
      html += `<div style="color:var(--color-text-dim);">No decors found on this entity.</div>`;
    } else {
      decors.forEach((decor, i) => {
        html += `<div style="margin-bottom:8px;padding:8px;background:var(--color-sidebar);border-radius:4px;">`;
        html += `<div style="color:var(--color-hover);font-weight:bold;">Decor #${i+1}</div>`;
        html += `<div><span style="color:var(--color-text-dim);">Name:</span> ${decor.name}</div>`;
        html += `<div><span style="color:var(--color-text-dim);">Type:</span> ${decor.type}</div>`;
        html += `<div><span style="color:var(--color-text-dim);">Value:</span> ${decor.value}</div>`;
        html += `</div>`;
      });
    }
    html += `</div>`;
    document.getElementById("decorInfo").innerHTML = html;
  }


  if (event.data.type === "updateInventory") {
    const items = event.data.items;
    let html = `<h3>Inventory for ID: ${event.data.targetId}</h3>`;
    if (!items || Object.keys(items).length === 0) {
      html += `<p>No items found or inventory is empty.</p>`;
    } else {
      html += `<div style="max-height: 200px; overflow-y: auto; background: var(--color-background); padding: 10px; border-radius: 4px;">`;
      for (const key in items) {
        const item = items[key];
        html += `<div style="display:flex;justify-content:space-between;padding:4px 0;border-bottom:1px solid #333;">
          <span>${item.label || item.name}</span>
          <span style="color:var(--color-primary);">x${item.count || item.amount}</span>
        </div>`;
      }
      html += `</div>`;
    }

    // Create or update a modal/div for inventory. For now, we can append it to the Player Actions Info
    const actionsDiv = document.getElementById("playerActionsInfo");
    if (actionsDiv) {
      let invDiv = document.getElementById("playerInventoryView");
      if (!invDiv) {
        invDiv = document.createElement("div");
        invDiv.id = "playerInventoryView";
        invDiv.style.marginTop = "10px";
        actionsDiv.appendChild(invDiv);
      }
      invDiv.innerHTML = html;
      actionsDiv.style.display = "block";
    }
  }

  if (event.data.type === "updatePlayerPreview") {
    const info = event.data.info;
    const previewDiv = document.getElementById("playerPreviewInfo");
    if (previewDiv && info) {
      if (document.getElementById("playerActionsInfo")) {
        document.getElementById("playerActionsInfo").style.display = "block";
        if (document.getElementById("actionsPlayerName")) document.getElementById("actionsPlayerName").textContent = info.name;
        if (document.getElementById("actionsPlayerJob")) document.getElementById("actionsPlayerJob").textContent = info.job || 'N/A';
        if (document.getElementById("actionsPlayerCash")) document.getElementById("actionsPlayerCash").textContent = info.cash || 0;
        if (document.getElementById("actionsPlayerBank")) document.getElementById("actionsPlayerBank").textContent = info.bank || 0;
      }
      let html = `<div style="text-align:left;">`;
      html += `<div style="font-weight:bold;color:var(--color-primary);margin-bottom:8px;">${info.name}</div>`;
      html += `<div style="font-size:12px;line-height:1.8;">`;
      html += `<div><span style="color:var(--color-text-dim);">ID:</span> ${info.id}</div>`;
      html += `<div><span style="color:var(--color-text-dim);">Job:</span> ${info.job || 'N/A'}</div>`;
      html += `<div><span style="color:var(--color-text-dim);">Gang:</span> ${info.gang || 'N/A'}</div>`;
      html += `<div><span style="color:var(--color-text-dim);">Cash:</span> $${info.cash || 0}</div>`;
      html += `<div><span style="color:var(--color-text-dim);">Bank:</span> $${info.bank || 0}</div>`;
      html += `</div></div>`;
      previewDiv.innerHTML = html;
    }
  }
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


function viewInventory() {
  const cidInput = document.getElementById("cidPlayerActions").value;
  const cidDropdown = document.getElementById("cidPlayerActionsDropdown").value;
  const targetId = cidDropdown || cidInput;
  if (!targetId) return showToast("Please select a player");
  fetch(`https://${GetParentResourceName()}/getInventory`, { method: "POST", body: JSON.stringify({ targetId }) });
}
