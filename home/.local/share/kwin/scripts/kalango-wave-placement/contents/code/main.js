// Wave runs under XWayland (see kalango-wave) and positions its own new windows,
// usually on the wrong monitor. Send them to the monitor the user was on.
let current = workspace.activeScreen;
let previous = current;

workspace.windowActivated.connect(window => {
    if (!window) return;
    previous = current;
    current = window.output;
});

workspace.windowAdded.connect(window => {
    if (window.resourceClass !== "Wave" && window.resourceClass !== "wave") return;
    // A focused new window has already been activated, so "current" is its own monitor
    const target = workspace.activeWindow === window ? previous : current;
    // After Wave has applied its own position
    const timer = new QTimer();
    timer.singleShot = true;
    timer.interval = 300;
    timer.timeout.connect(() => {
        workspace.sendClientToScreen(window, target);
        workspace.activeWindow = window;
    });
    timer.start();
});
