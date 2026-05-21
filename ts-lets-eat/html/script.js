let currentPage = 0;
let menuData = [];
let currentRestId = null;

window.addEventListener("message", (event) => {
    if (event.data.action === "openMenu") {
        document.getElementById("menu-wrapper").style.display = "flex";
        menuData = event.data.menuData || [];
        currentRestId = event.data.restId;
        currentPage = 0;
        renderPage();
    }
    if (event.data.action === "closeMenu") {
        document.getElementById("menu-wrapper").style.display = "none";
    }
    if (event.data.action === "setTheme") {
        document.getElementById("themeStylesheet").href = event.data.theme + ".css";
    }
});

function closeMenu() {
    document.getElementById("menu-wrapper").style.display = "none";
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: "POST",
        body: JSON.stringify({})
    });
}

function renderPage() {
    const left = menuData[currentPage];
    const right = menuData[currentPage + 1];

    document.getElementById("category-left").innerText = left?.category || "";
    document.getElementById("category-right").innerText = right?.category || "";

    document.getElementById("items-left").innerHTML = left?.items.map(itemHTML).join("") || "";
    document.getElementById("items-right").innerHTML = right?.items.map(itemHTML).join("") || "";
}

function itemHTML(item) {
    let mixersHTML = "";

    if (item.mixers) {
        mixersHTML = `
            <div class="mixers">
                ${item.mixers.map(m => `
                    <button class="mixer-btn" onclick="addMixer('${item.id}', '${m}')">${m}</button>
                `).join("")}
            </div>
        `;
    }

    return `
        <div class="item bottle-card">
            <div class="item-name">${item.name}</div>
            <div class="item-desc">${item.desc}</div>
            <div class="item-price">$${item.price}</div>
            ${mixersHTML}
            <button class="order-btn" onclick="orderItem(${item.id}, ${item.price})">Order</button>
        </div>
    `;
}

function orderItem(itemIndex, price) {
    fetch(`https://${GetParentResourceName()}/orderItem`, {
        method: "POST",
        body: JSON.stringify({ itemIndex: itemIndex, restId: currentRestId })
    });
}

function addMixer(bottleId, mixer) {
    fetch(`https://${GetParentResourceName()}/addMixer`, {
        method: "POST",
        body: JSON.stringify({ bottleId: bottleId, mixer: mixer, restId: currentRestId })
    });
}

document.getElementById("nextPage").onclick = () => {
    if (currentPage < menuData.length - 2) currentPage += 2;
    renderPage();
};

document.getElementById("prevPage").onclick = () => {
    if (currentPage > 0) currentPage -= 2;
    renderPage();
};
