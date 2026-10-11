XS.camera = (function () {
    const root = document.getElementById('root');
    const deck = document.querySelector('[data-camdeck]');

    let wanted = '';
    let running = false;
    let drag = null;
    let moved = { dx: 0, dy: 0 };
    let frame = 0;

    // The camera runs on the sheet screens, with a car connected, while the
    // panel is up. The key changes when the car does, so a new car is framed.
    function want() {
        const car = XS.state.vehicle;

        if (!root.classList.contains('open') || document.body.dataset.layout !== 'sheet' || !car) return '';
        return `${car.plate || ''}|${car.model || ''}`;
    }

    function dress() {
        root.classList.toggle('cam', running);
        if (deck) deck.hidden = !running;
    }

    async function sync() {
        const key = want();
        if (key === wanted) return;

        wanted = key;

        if (!key) {
            running = false;
            drag = null;
            dress();
            XS.post('carCam', { on: false });
            return;
        }

        const device = document.querySelector('.device');
        const edge = device ? device.getBoundingClientRect().right / Math.max(1, innerWidth) : 0;

        const reply = await XS.post('carCam', {
            on: true,
            edge: Math.min(0.6, Math.max(0, edge)),
            aspect: innerWidth / Math.max(1, innerHeight),
        });

        if (wanted !== key) return;

        running = !!(reply && reply.ok);
        dress();
    }

    function flush() {
        frame = 0;
        if (!moved.dx && !moved.dy) return;

        XS.post('camOrbit', moved);
        moved = { dx: 0, dy: 0 };
    }

    function stop() {
        drag = null;
        root.classList.remove('dragging');
    }

    // Only the open part of the screen turns the camera. The panel keeps its
    // own clicks and its own scrolling.
    root.addEventListener('mousedown', (ev) => {
        if (!running || ev.target !== root || ev.button !== 0) return;

        drag = { x: ev.clientX, y: ev.clientY };
        root.classList.add('dragging');
        ev.preventDefault();
    });

    window.addEventListener('mousemove', (ev) => {
        if (!drag) return;

        moved.dx += ev.clientX - drag.x;
        moved.dy += ev.clientY - drag.y;
        drag = { x: ev.clientX, y: ev.clientY };

        if (!frame) frame = requestAnimationFrame(flush);
    });

    window.addEventListener('mouseup', stop);
    window.addEventListener('blur', stop);

    root.addEventListener('wheel', (ev) => {
        if (!running || ev.target !== root) return;
        XS.post('camZoom', { step: Math.max(-3, Math.min(3, ev.deltaY / 100)) });
    }, { passive: true });

    for (const button of deck ? deck.querySelectorAll('[data-cam]') : []) {
        button.addEventListener('click', () => XS.post('camView', { view: button.dataset.cam }));
    }

    return { sync };
})();
