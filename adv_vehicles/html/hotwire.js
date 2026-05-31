let connectedWires = 0;
const totalWires = 3;
let isDragging = false;
let currentWireColor = null;
let currentStartPoint = null;
let currentPath = null;
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
    svg.innerHTML = ''; // Clear SVG paths

    document.querySelectorAll('.wire-point.start').forEach(point => {
        point.classList.remove('connected');
        point.style.pointerEvents = 'auto';
    });

    document.querySelectorAll('.wire-point.end').forEach(terminal => {
        terminal.classList.remove('connected');
        terminal.style.backgroundColor = '#444';
    });

    // Shuffle terminals
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

function drawPath(startX, startY, endX, endY, color) {
    const offset = 50;
    return `M ${startX} ${startY} C ${startX + offset} ${startY}, ${endX - offset} ${endY}, ${endX} ${endY}`;
}

document.querySelectorAll('.wire-point.start').forEach(point => {
    point.addEventListener('mousedown', (e) => {
        if (point.classList.contains('connected')) return;

        isDragging = true;
        currentStartPoint = point;
        currentWireColor = point.dataset.color;

        const startPos = getCenter(point);
        currentPath = document.createElementNS("http://www.w3.org/2000/svg", "path");
        currentPath.setAttribute("stroke", point.style.backgroundColor);
        currentPath.setAttribute("stroke-width", "8");
        currentPath.setAttribute("fill", "none");
        currentPath.setAttribute("d", drawPath(startPos.x, startPos.y, startPos.x, startPos.y, currentWireColor));
        svg.appendChild(currentPath);
    });
});

document.addEventListener('mousemove', (e) => {
    if (!isDragging || !currentPath) return;

    const svgRect = svg.getBoundingClientRect();
    const mouseX = e.clientX - svgRect.left;
    const mouseY = e.clientY - svgRect.top;
    const startPos = getCenter(currentStartPoint);

    currentPath.setAttribute("d", drawPath(startPos.x, startPos.y, mouseX, mouseY, currentWireColor));
});

document.addEventListener('mouseup', (e) => {
    if (!isDragging) return;
    isDragging = false;

    // Check if mouse is over a terminal
    const endPoints = document.querySelectorAll('.wire-point.end');
    let hitTerminal = null;

    endPoints.forEach(terminal => {
        const rect = terminal.getBoundingClientRect();
        if (e.clientX >= rect.left && e.clientX <= rect.right &&
            e.clientY >= rect.top && e.clientY <= rect.bottom) {
            hitTerminal = terminal;
        }
    });

    if (hitTerminal && !hitTerminal.classList.contains('connected')) {
        const acceptColor = hitTerminal.dataset.accept;

        if (currentWireColor === acceptColor) {
            // Success snap
            const startPos = getCenter(currentStartPoint);
            const endPos = getCenter(hitTerminal);
            currentPath.setAttribute("d", drawPath(startPos.x, startPos.y, endPos.x, endPos.y, currentWireColor));

            hitTerminal.classList.add('connected');
            hitTerminal.style.backgroundColor = currentStartPoint.style.backgroundColor;
            currentStartPoint.classList.add('connected');
            currentStartPoint.style.pointerEvents = 'none';

            connectedWires++;
            if (connectedWires === totalWires) {
                document.getElementById('status').innerText = 'Engine Started!';
                document.getElementById('status').style.color = 'lime';
                setTimeout(() => closeMinigame(true), 1000);
            }
        } else {
            // Fail
            document.getElementById('status').innerText = 'Spark! Wrong connection!';
            document.getElementById('status').style.color = 'red';
            svg.removeChild(currentPath);
            setTimeout(() => closeMinigame(false), 1000);
        }
    } else {
        // Missed terminal, remove wire
        svg.removeChild(currentPath);
    }

    currentPath = null;
    currentStartPoint = null;
    currentWireColor = null;
});

document.addEventListener('keydown', (e) => {
    if (document.getElementById('hotwire-container').style.display === 'block') {
        if (e.key === "Escape" || e.key === "Backspace") {
            closeMinigame(false);
        }
    }
});
