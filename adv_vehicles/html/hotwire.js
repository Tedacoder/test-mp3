let connectedWires = 0;
const totalWires = 3;
let isDragging = false;
let currentStartPoint = null;
let currentPath1 = null;
let currentPath2 = null;
let currentTargetTerminal = null;
let currentWireColor = null;

const svg = document.getElementById('wire-svg');

window.addEventListener('message', (event) => {
    if (event.data.action === "openHotwire") {
        document.getElementById('hotwire-container').style.display = 'block';
        resetMinigame();
    }
});

function closeMinigame(success) {
    document.getElementById('hotwire-container').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/hotwireResult`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ success: success })
    });
}

function resetMinigame() {
    connectedWires = 0;
    document.getElementById('status').innerText = 'Waiting for connection...';
    document.getElementById('status').style.color = 'white';
    svg.innerHTML = '';

    document.querySelectorAll('.wire-point.start').forEach(point => {
        point.classList.remove('connected');
        point.style.pointerEvents = 'auto';
    });

    document.querySelectorAll('.wire-point.end').forEach(terminal => {
        terminal.classList.remove('connected');
        terminal.style.backgroundColor = '#444';
    });

    const terminalsContainer = document.getElementById('wire-ends');
    for (let i = terminalsContainer.children.length; i >= 0; i--) {
        terminalsContainer.appendChild(terminalsContainer.children[Math.random() * i | 0]);
    }
}

function getCenter(el) {
    const rect = el.getBoundingClientRect();
    const svgRect = svg.getBoundingClientRect();
    return {
        x: rect.left + rect.width / 2 - svgRect.left,
        y: rect.top + rect.height / 2 - svgRect.top
    };
}

function drawPath(startX, startY, endX, endY) {
    const offset = 50;
    return `M ${startX} ${startY} C ${startX + offset} ${startY}, ${endX - offset} ${endY}, ${endX} ${endY}`;
}

function drawReversePath(startX, startY, endX, endY) {
    const offset = 50;
    return `M ${startX} ${startY} C ${startX - offset} ${startY}, ${endX + offset} ${endY}, ${endX} ${endY}`;
}

document.querySelectorAll('.wire-point.start').forEach(point => {
    point.addEventListener('mousedown', (e) => {
        if (point.classList.contains('connected')) return;

        isDragging = true;
        currentStartPoint = point;
        currentWireColor = point.dataset.color;

        const startPos = getCenter(point);
        currentPath1 = document.createElementNS("http://www.w3.org/2000/svg", "path");
        currentPath1.setAttribute("stroke", currentWireColor);
        currentPath1.setAttribute("stroke-width", "8");
        currentPath1.setAttribute("fill", "none");
        svg.appendChild(currentPath1);

        // Find matching terminal
        currentTargetTerminal = document.querySelector(`.wire-point.end[data-accept="${currentWireColor}"]`);

        currentPath2 = document.createElementNS("http://www.w3.org/2000/svg", "path");
        currentPath2.setAttribute("stroke", currentWireColor);
        currentPath2.setAttribute("stroke-width", "8");
        currentPath2.setAttribute("fill", "none");
        svg.appendChild(currentPath2);
    });
});

document.addEventListener('mousemove', (e) => {
    if (!isDragging || !currentPath1) return;

    const svgRect = svg.getBoundingClientRect();
    const mouseX = e.clientX - svgRect.left;
    const mouseY = e.clientY - svgRect.top;

    const startPos = getCenter(currentStartPoint);
    currentPath1.setAttribute("d", drawPath(startPos.x, startPos.y, mouseX, mouseY));

    // Dynamic opposite wire meeting it
    const termPos = getCenter(currentTargetTerminal);
    // Calc mirror pos
    const dx = mouseX - startPos.x;
    const pct = Math.min(1.0, Math.max(0.0, dx / (termPos.x - startPos.x)));

    // Reverse side draws out proportional to how far left side is dragged
    const targetMouseX = termPos.x - dx;
    const targetMouseY = termPos.y + (mouseY - startPos.y);

    // Give it a spark-meet effect in the middle
    if (pct > 0.45 && pct < 0.55) {
       currentPath2.setAttribute("d", drawReversePath(termPos.x, termPos.y, mouseX, mouseY));
    } else {
       currentPath2.setAttribute("d", drawReversePath(termPos.x, termPos.y, targetMouseX, targetMouseY));
    }
});

document.addEventListener('mouseup', (e) => {
    if (!isDragging) return;
    isDragging = false;

    const svgRect = svg.getBoundingClientRect();
    const mouseX = e.clientX - svgRect.left;
    const startPos = getCenter(currentStartPoint);
    const termPos = getCenter(currentTargetTerminal);
    const dx = mouseX - startPos.x;
    const pct = dx / (termPos.x - startPos.x);

    if (pct > 0.45 && pct < 0.55) {
        // They met in the middle
        const midY = e.clientY - svgRect.top;
        currentPath1.setAttribute("d", drawPath(startPos.x, startPos.y, mouseX, midY));
        currentPath2.setAttribute("d", drawReversePath(termPos.x, termPos.y, mouseX, midY));

        currentTargetTerminal.classList.add('connected');
        currentTargetTerminal.style.backgroundColor = currentWireColor;
        currentStartPoint.classList.add('connected');
        currentStartPoint.style.pointerEvents = 'none';

        // Add a spark dot
        const spark = document.createElementNS("http://www.w3.org/2000/svg", "circle");
        spark.setAttribute("cx", mouseX);
        spark.setAttribute("cy", midY);
        spark.setAttribute("r", "8");
        spark.setAttribute("fill", "yellow");
        svg.appendChild(spark);

        connectedWires++;
        if (connectedWires === totalWires) {
            document.getElementById('status').innerText = 'Engine Started!';
            document.getElementById('status').style.color = 'lime';
            setTimeout(() => closeMinigame(true), 1000);
        }
    } else {
        // Missed connection
        document.getElementById('status').innerText = 'Spark! Wrong connection!';
        document.getElementById('status').style.color = 'red';
        svg.removeChild(currentPath1);
        svg.removeChild(currentPath2);
        setTimeout(() => closeMinigame(false), 1000);
    }

    currentPath1 = null;
    currentPath2 = null;
    currentStartPoint = null;
    currentTargetTerminal = null;
});

document.addEventListener('keydown', (e) => {
    if (document.getElementById('hotwire-container').style.display === 'block') {
        if (e.key === "Escape" || e.key === "Backspace") {
            closeMinigame(false);
        }
    }
});