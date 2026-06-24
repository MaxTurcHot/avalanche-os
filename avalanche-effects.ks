# avalanche-effects.ks — custom KWin effects
# Source files live in kwin/ — edit there, then re-include here.

%post

# ── AvalancheDestroy window close effect ─────────────────────────────────────
mkdir -p /usr/share/kwin/effects/avalanchedestroy/code

cat > /usr/share/kwin/effects/avalanchedestroy/metadata.json << 'TXTEOF'
{
    "KPackageStructure": "KWin/Effect",
    "KPlugin": {
        "Authors": [{ "Email": "turcmax@avalanche-os.org", "Name": "Avalanche OS Team" }],
        "Category": "Appearance",
        "Description": "Animates closed windows by sweeping them away like an avalanche: sliding to the top-right, rotating, shrinking, and fading out.",
        "EnabledByDefault": true,
        "Id": "kwin4_effect_avalanchedestroy",
        "License": "GPL-3.0-or-later",
        "Name": "Avalanche Destroy",
        "Version": "1.0"
    },
    "X-KDE-Ordering": 60,
    "X-Plasma-API": "javascript",
    "X-Plasma-MainScript": "code/main.js"
}
TXTEOF

cat > /usr/share/kwin/effects/avalanchedestroy/code/main.js << 'TXTEOF'
// AvalancheDestroy KWin JavaScript window effect
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
TXTEOF

# ── Enable the effect system-wide via kwinrc ──────────────────────────────────
mkdir -p /etc/xdg/kdedefaults
cat >> /etc/xdg/kdedefaults/kwinrc << 'TXTEOF'

[Plugins]
kwin4_effect_avalanchedestroyEnabled=true
TXTEOF

echo "AVALANCHE: AvalancheDestroy KWin effect installed and enabled"

%end
