let connectedWires = 0;
const totalWires = 3;

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

    document.querySelectorAll('.wire').forEach(wire => {
        wire.style.visibility = 'visible';
    });

    document.querySelectorAll('.terminal').forEach(terminal => {
        terminal.classList.remove('connected');
    });

    // Shuffle terminals
    const terminalsContainer = document.querySelector('.terminals');
    for (let i = terminalsContainer.children.length; i >= 0; i--) {
        terminalsContainer.appendChild(terminalsContainer.children[Math.random() * i | 0]);
    }
}

document.querySelectorAll('.wire').forEach(wire => {
    wire.addEventListener('dragstart', e => {
        e.dataTransfer.setData('text/plain', e.target.dataset.color);
    });
});

document.querySelectorAll('.terminal').forEach(terminal => {
    terminal.addEventListener('dragover', e => e.preventDefault());

    terminal.addEventListener('drop', e => {
        e.preventDefault();
        const wireColor = e.dataTransfer.getData('text/plain');
        const acceptColor = e.target.dataset.accept;

        if (wireColor === acceptColor && !e.target.classList.contains('connected')) {
            e.target.classList.add('connected');
            e.target.style.backgroundColor = getComputedStyle(document.querySelector(`.wire.${wireColor}`)).backgroundColor;
            document.querySelector(`.wire.${wireColor}`).style.visibility = 'hidden';
            connectedWires++;

            if (connectedWires === totalWires) {
                document.getElementById('status').innerText = 'Engine Started!';
                document.getElementById('status').style.color = 'lime';
                setTimeout(() => closeMinigame(true), 1000);
            }
        } else {
            document.getElementById('status').innerText = 'Spark! Wrong connection!';
            document.getElementById('status').style.color = 'red';
            setTimeout(() => closeMinigame(false), 1000);
        }
    });
});

document.addEventListener('keydown', (e) => {
    if (e.key === "Escape" || e.key === "Backspace") {
        closeMinigame(false);
    }
});
