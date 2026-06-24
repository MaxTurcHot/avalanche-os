// AvalancheDestroy KWin 6 scripted effect
// Window sweeps to top-right, shrinks, and fades out on close.

effect.windowClosed.connect(function(window) {
    if (window.desktopWindow || window.dock || window.popupWindow) {
        return;
    }

    var screenGeom = workspace.clientArea(KWin.ScreenArea, window);
    var winH = window.height || 300;

    // Off-screen target: past the top-right corner
    var targetX = screenGeom.x + screenGeom.width + 200;
    var targetY = screenGeom.y - winH - 200;

    animate(window, {
        type: Effect.Position,
        curve: QEasingCurve.InQuad,
        duration: 500,
        to: { value1: targetX, value2: targetY },
        keepAlive: true
    });

    animate(window, {
        type: Effect.Scale,
        curve: QEasingCurve.InQuad,
        duration: 500,
        to: { value1: 0.2, value2: 0.2 },
        keepAlive: true
    });

    animate(window, {
        type: Effect.Opacity,
        curve: QEasingCurve.InQuad,
        duration: 500,
        to: { value1: 0.0 },
        keepAlive: true
    });
});
