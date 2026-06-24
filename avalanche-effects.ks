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
// AvalancheDestroy KWin 6 scripted effect
// Window sweeps to top-right, shrinks, and fades out on close.

effect.windowClosed.connect(function(window) {
    if (window.desktopWindow || window.dock || window.popupWindow) {
        return;
    }

    var screenGeom = workspace.clientArea(KWin.ScreenArea, window);
    var winH = window.height || 300;

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
TXTEOF

# ── Enable the effect system-wide via kwinrc ──────────────────────────────────
mkdir -p /etc/xdg/kdedefaults
cat >> /etc/xdg/kdedefaults/kwinrc << 'TXTEOF'

[Plugins]
kwin4_effect_avalanchedestroyEnabled=true
TXTEOF

echo "AVALANCHE: AvalancheDestroy KWin effect installed and enabled"

%end
