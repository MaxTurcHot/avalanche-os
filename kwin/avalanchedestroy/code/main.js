// AvalancheDestroy KWin JavaScript window effect
// Designed for Avalanche OS (backcountry/splitboard snowboard theme)
// Window sweeps toward top-right and tumbles away on close.

var animationCount = {};

var runAnimate = (typeof animate !== 'undefined') ? animate : (typeof effect !== 'undefined' && effect.animate ? effect.animate.bind(effect) : null);

if (runAnimate && effect) {
    effect.windowClosed.connect(function(window) {
        if (window.desktopWindow || window.dock || window.popupWindow) {
            return;
        }

        effect.keepAlive(window, true);

        var winId = window.internalId ? window.internalId.toString() : (window.windowId ? window.windowId.toString() : null);
        if (!winId) {
            winId = (window.caption ? window.caption : '') + Math.random().toString();
        }
        animationCount[winId] = 4;

        var screenGeom = workspace.clientArea(KWin.ScreenArea, window);
        var winH = (typeof window.height !== 'undefined') ? window.height : (window.geometry ? window.geometry.height : 300);

        var targetX = screenGeom.x + screenGeom.width + 150;
        var targetY = screenGeom.y - winH - 150;

        runAnimate(window, {
            type: Effect.Position,
            curve: QEasingCurve.OutQuad,
            duration: 500,
            to: { value1: targetX, value2: targetY },
            keepAlive: true
        });

        runAnimate(window, {
            type: Effect.Scale,
            curve: QEasingCurve.OutQuad,
            duration: 500,
            to: { value1: 0.0, value2: 0.0 },
            keepAlive: true
        });

        runAnimate(window, {
            type: Effect.Opacity,
            curve: QEasingCurve.OutQuad,
            duration: 500,
            to: { value1: 0.0 },
            keepAlive: true
        });

        runAnimate(window, {
            type: Effect.Rotation,
            curve: QEasingCurve.OutQuad,
            duration: 500,
            to: { value1: 360 },
            keepAlive: true
        });
    });

    effect.animationEnded.connect(function(window, animationId) {
        var winId = window.internalId ? window.internalId.toString() : (window.windowId ? window.windowId.toString() : null);
        if (!winId) {
            for (var key in animationCount) {
                if (animationCount.hasOwnProperty(key)) {
                    animationCount[key]--;
                    if (animationCount[key] <= 0) {
                        delete animationCount[key];
                        effect.keepAlive(window, false);
                    }
                    return;
                }
            }
            effect.keepAlive(window, false);
            return;
        }

        if (typeof animationCount[winId] !== 'undefined') {
            animationCount[winId]--;
            if (animationCount[winId] <= 0) {
                delete animationCount[winId];
                effect.keepAlive(window, false);
            }
        }
    });
}
