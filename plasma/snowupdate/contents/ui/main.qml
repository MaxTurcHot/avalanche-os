/*
 * Avalanche OS — "Snowfall" updater
 *
 * Reframes pending system updates as a snowstorm the user controls:
 *   1 pending package = 1 mm of snow.  "Call the storm" runs the upgrade and
 *   the falling snow buries a planted snowboard as packages install.
 *
 * Flat-geometric to match the Avalanche brand. Everything is drawn in QML
 * (sky gradient, mountains, drift, snow particles) except the snowboard, which
 * is a hand-authored SVG. No frame sequences — one `progress` value (0..1)
 * drives the whole animation.
 *
 * Run standalone for development:
 *   plasmawindowed org.avalanche.snowupdate
 */
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Particles
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    // ── Tunables ────────────────────────────────────────────────────────────
    readonly property color cSkyTop:   "#0a0e1a"
    readonly property color cSkyBot:   "#10182a"
    readonly property color cPeakBack: "#1e3a5f"
    readonly property color cPeakFront:"#0d1520"
    readonly property color cSnow:     "#f0f4f8"
    readonly property color cSnowBack: "#cdd9e6"
    readonly property color cAccent:   "#FF4D1C"
    readonly property color cText:     "#ffffff"
    readonly property color cSub:      "#8aa0b8"

    // ── Dev stub ────────────────────────────────────────────────────────────
    // While true, "Call the storm" fakes progress with a Timer instead of
    // running dnf/pkexec — lets us tune the animation without real upgrades.
    property bool devStub: false
    property int  fakeCount: 23
    // Shell-expanded by the plasma5support executable engine, so no PATH guessing.
    // (Phase B / ISO: change to /usr/local/bin/avalanche-update-run.)
    readonly property string helper: "$HOME/.local/bin/avalanche-update-run"

    // ── State ───────────────────────────────────────────────────────────────
    // "checking" | "idle" | "falling" | "done" | "empty"
    property string phase: "idle"
    property int  updateCount: 0
    property int  doneCount: 0          // mm reported "down" so far
    property bool needsReboot: false
    property bool stormStarted: false   // upgrade launched (detached, survives close)
    property int  txTotal: 0            // dnf5 transaction total (incl. deps)

    property real progress: 0           // target fraction 0..1
    property real shown: 0              // settled floor fraction the scene renders
    // Long ease so the floor glides smoothly between the delayed snow steps
    // (the buffer below sets the timing; this keeps the motion fluid).
    Behavior on shown { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }

    // The floor only rises once the falling snow has had time to reach it.
    // Each progress bump is held "in the air" for `fallMs` (≈ a flake's fall
    // time) before the floor accepts it, using a timestamped history buffer.
    readonly property int fallMs: 1500
    property var snowHist: []
    onProgressChanged: snowHist.push({ t: Date.now(), v: progress })

    Timer {
        interval: 60; repeat: true; running: true
        onTriggered: {
            var cutoff = Date.now() - root.fallMs
            var v = root.shown
            while (root.snowHist.length > 0 && root.snowHist[0].t <= cutoff) {
                v = root.snowHist[0].v
                root.snowHist.shift()
            }
            if (v !== root.shown) root.shown = v
        }
    }

    // Keep snowing until the floor has caught up with the storm.
    onShownChanged: {
        if (phase === "falling" && progress >= 1 && shown >= 0.999)
            phase = "done"
    }

    function mm(n) { return n + (n === 1 ? " mm" : " mm") } // singular guard (label is "mm" either way; helper for tone)

    // ── Backend (real mode) ──────────────────────────────────────────────────
    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            var out = (data["stdout"] || "").trim()
            if (source.indexOf("count") !== -1) {
                root.updateCount = parseInt(out) || 0
                root.phase = root.updateCount > 0 ? "idle" : "empty"
            }
            // The detached "apply" launch returns immediately; completion is
            // detected by the progress poll below, not here.
            exec.disconnectSource(source)
        }
    }

    // Polls the progress file the helper writes: "<current> <total>" or "done <rc>"
    P5Support.DataSource {
        id: poll
        engine: "executable"
        interval: 400
        connectedSources: []
        onNewData: function(source, data) {
            var out = (data["stdout"] || "").trim()
            if (!out) return
            if (out.indexOf("done") === 0) {
                root.progress = 1
                root.doneCount = root.txTotal > 0 ? root.txTotal : root.updateCount
                poll.connectedSources = []   // stop polling once finished
            } else {
                var parts = out.split(/\s+/)
                var cur = parseInt(parts[0]); var tot = parseInt(parts[1])
                if (!isNaN(cur) && !isNaN(tot) && tot > 0) {
                    // dnf5's transaction total (incl. deps) can differ from the
                    // check-update count, so the live counter uses this total.
                    root.txTotal = tot
                    root.doneCount = Math.min(cur, tot)
                    root.progress = Math.min(1, cur / tot)
                }
            }
        }
    }

    // ── Dev-stub driver ───────────────────────────────────────────────────────
    Timer {
        id: stubTimer
        interval: 450; repeat: true
        onTriggered: {
            if (root.doneCount >= root.updateCount) {
                stop()
                root.progress = 1   // floor finishes via onShownChanged
                return
            }
            root.doneCount += Math.max(1, Math.round(root.updateCount / 20))
            root.doneCount = Math.min(root.doneCount, root.updateCount)
            root.progress = root.doneCount / root.updateCount
        }
    }

    // ── Actions ─────────────────────────────────────────────────────────────
    // plasmawindowed ignores both Qt.quit() and Window.close(), so the reliable
    // way to close the window is to terminate its own process. We try the clean
    // close first, then a detached pkill matching our exact command line as a
    // guaranteed fallback (detached so it outlives the process it kills; the
    // detached upgrade lives in a separate process tree and is untouched).
    property var appWindow: null
    function closeWindow() {
        if (appWindow) appWindow.close()
        exec.connectSource("setsid -f sh -c \"pkill -f 'plasmawindowed org.avalanche.snowupdate'\"")
    }

    // Launch the upgrade detached so it survives the window closing. setsid -f
    // double-forks; progress is read from the file the helper writes, so the
    // animation never depends on the process being our child.
    function startUpgrade() {
        if (root.stormStarted) return
        root.stormStarted = true
        if (devStub) {
            stubTimer.start()
        } else {
            poll.connectedSources = ["cat \"${XDG_RUNTIME_DIR:-/tmp}/avalanche-update.progress\" 2>/dev/null"]
            exec.connectSource("setsid -f " + helper + " apply")
        }
    }

    // "Call the storm" — start it and watch the snow fall.
    function callTheStorm() {
        root.phase = "falling"
        root.doneCount = 0
        root.progress = 0
        startUpgrade()
    }

    // "Snow outside" — always available. If the storm is already running it just
    // closes (the upgrade is detached and keeps going); otherwise it starts the
    // upgrade in the background first, then closes.
    Timer { id: quitTimer; interval: 200; onTriggered: root.closeWindow() }
    function snowOutside() {
        if (root.stormStarted) { root.closeWindow(); return }
        startUpgrade()
        quitTimer.start()
    }

    Component.onCompleted: {
        if (devStub) {
            updateCount = fakeCount
            phase = "idle"
        } else {
            phase = "checking"
            exec.connectSource(helper + " count")
        }
    }

    // ── Scene ─────────────────────────────────────────────────────────────────
    fullRepresentation: Item {
        id: scene
        implicitWidth: 560
        implicitHeight: 660
        Layout.minimumWidth: 520
        Layout.minimumHeight: 560

        // Capture the host window here (in-scope) for closeWindow().
        Component.onCompleted: root.appWindow = Window.window

        // 1 — Sky
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.cSkyTop }
                GradientStop { position: 1.0; color: root.cSkyBot }
            }
        }

        // 2 — Mountains
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                var w = width, h = height
                ctx.clearRect(0, 0, w, h)
                var horizon = h * 0.66
                // back range (translucent)
                ctx.fillStyle = Qt.rgba(0.118, 0.227, 0.373, 0.55)
                ctx.beginPath()
                ctx.moveTo(0, horizon)
                ctx.lineTo(w * 0.22, horizon - 150)
                ctx.lineTo(w * 0.40, horizon - 40)
                ctx.lineTo(w * 0.60, horizon - 175)
                ctx.lineTo(w * 0.82, horizon - 55)
                ctx.lineTo(w, horizon - 120)
                ctx.lineTo(w, h); ctx.lineTo(0, h); ctx.closePath(); ctx.fill()
                // front silhouette
                ctx.fillStyle = root.cPeakFront
                ctx.beginPath()
                ctx.moveTo(0, horizon + 40)
                ctx.lineTo(w * 0.30, horizon - 70)
                ctx.lineTo(w * 0.52, horizon + 20)
                ctx.lineTo(w * 0.74, horizon - 95)
                ctx.lineTo(w, horizon + 10)
                ctx.lineTo(w, h); ctx.lineTo(0, h); ctx.closePath(); ctx.fill()
            }
        }

        // 3 — Snowboard (planted, slight lean). Drift (z above) buries it.
        Image {
            id: board
            source: Qt.resolvedUrl("../images/snowboard.svg")
            sourceSize.width: 120
            sourceSize.height: 460
            width: 84
            height: 322
            smooth: true
            antialiasing: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -22
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4          // tail sits below the snow line → planted
            transformOrigin: Item.Bottom
            rotation: -8
        }

        // 4 — Snowdrift (rises with `shown`, buries the board)
        Canvas {
            id: driftCanvas
            anchors.fill: parent
            z: 2                         // floor sits in front of the falling snow
            // Repaint whenever the snow level changes. Driving this from an
            // in-scope bound property is reliable; a cross-scope requestPaint
            // from the root silently fails to fire.
            property real lvl: root.shown
            onLvlChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                var w = width, h = height
                ctx.clearRect(0, 0, w, h)
                // permanent base mound the board is planted into (keeps it upright)
                var base = 88
                function drift(levelPx, color, amp, periods, phase) {
                    var top = h - levelPx
                    ctx.fillStyle = color
                    ctx.beginPath()
                    ctx.moveTo(0, h)
                    ctx.lineTo(0, top)
                    for (var x = 0; x <= w; x += 8) {
                        var y = top + amp * Math.sin((x / w) * periods * Math.PI * 2 + phase)
                        ctx.lineTo(x, y)
                    }
                    ctx.lineTo(w, h); ctx.closePath(); ctx.fill()
                }
                // overfill at 100% so the snow reaches (and tops) the window edge
                var level = base + root.shown * (h - base + 60)
                // back layer slightly higher + lighter for depth
                drift(level * 1.05 + 6, root.cSnowBack, 9, 2.5, 1.3)
                // front layer (white)
                drift(level, root.cSnow, 11, 3.0, 0.0)
            }
        }

        // 5 — Falling snow (built-in Qt particle image; zero asset)
        ParticleSystem {
            id: snowSys
            anchors.fill: parent
            z: 1                         // behind the floor, in front of the board
            // No snow until the user calls the storm — that's the whole concept.
            running: root.phase === "falling"

            ImageParticle {
                source: "qrc:///particleresources/glowdot.png"
                color: "#ffffff"
                colorVariation: 0.0
                alpha: 0.0
                entryEffect: ImageParticle.Fade
            }

            Emitter {
                width: parent.width
                height: 4
                y: -8
                emitRate: 150
                lifeSpan: 3200
                size: 9
                sizeVariation: 7
                velocity: AngleDirection {
                    angle: 90; angleVariation: 10
                    magnitude: 230; magnitudeVariation: 60
                }
            }

            // gentle sideways sway, like real snow
            Wander {
                anchors.fill: parent
                affectedParameter: Wander.Position
                xVariance: 36
                pace: 50
            }
        }

        // Drag handle — frameless windows have no titlebar, so the header strip
        // moves the window via the compositor (works on KWin Wayland).
        MouseArea {
            id: dragArea
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 96
            z: 4
            acceptedButtons: Qt.LeftButton
            // Resolve the window from this item's own scope at press time — the
            // root-level capture can be null, which is why the drag did nothing.
            onPressed: {
                var w = dragArea.Window.window
                if (w) w.startSystemMove()
            }
        }

        // ── UI overlay ────────────────────────────────────────────────────────
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26
            anchors.bottomMargin: 34
            z: 3                         // text + buttons always on top of the snow
            spacing: 0

            // Headline block
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                RowLayout {
                    spacing: 8
                    Text {
                        text: "❄"
                        color: root.cAccent
                        font.pixelSize: 24
                    }
                    Text {
                        Layout.fillWidth: true
                        // dark on the white buried climax, white otherwise
                        color: root.phase === "done" ? "#0a1018" : root.cText
                        font.pixelSize: 25
                        font.bold: true
                        wrapMode: Text.WordWrap
                        text: {
                            switch (root.phase) {
                            case "checking": return "Reading the forecast…"
                            case "falling":  return "Storm's rolling in…"
                            case "done":     return root.doneCount + " mm down. Slope's reset."
                            case "empty":    return "Bluebird day — nothing on radar."
                            default:         return "Storm's loaded: " + root.updateCount + " mm"
                            }
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    color: root.phase === "done" ? "#33445c" : root.cSub
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    visible: text.length > 0
                    text: {
                        switch (root.phase) {
                        case "idle":    return "Call it down now, or bank it for later."
                        case "falling": return root.doneCount + " / " + (root.txTotal > 0 ? root.txTotal : root.updateCount) + " mm down"
                        case "done":    return root.needsReboot ? "Reboot to let it settle." : ""
                        default:        return ""
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true } // push controls to the bottom

            // Controls
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }

                PillButton {
                    visible: root.phase === "idle"
                    label: "Bank it"
                    primary: false
                    onClicked: root.closeWindow()
                }
                PillButton {
                    visible: root.phase === "idle" || root.phase === "falling"
                    label: "Let it snow outside"
                    primary: false
                    onClicked: root.snowOutside()
                }
                PillButton {
                    visible: root.phase === "idle"
                    label: "Call the storm  ❄"
                    primary: true
                    onClicked: root.callTheStorm()
                }
                PillButton {
                    visible: root.phase === "done" || root.phase === "empty"
                    label: "Done"
                    primary: true
                    onClicked: root.closeWindow()
                }
            }
        }
    }

    // ── Reusable button ─────────────────────────────────────────────────────
    component PillButton: Rectangle {
        id: btn
        property string label: ""
        property bool primary: false
        signal clicked()
        implicitWidth: txt.implicitWidth + 36
        implicitHeight: 42
        radius: height / 2
        // Secondary is a solid dark pill so it stays readable over the white
        // snow drift as well as the dark sky.
        color: primary
               ? (ma.containsMouse ? Qt.lighter(root.cAccent, 1.12) : root.cAccent)
               : (ma.containsMouse ? "#f22b3a52" : "#e61b2536")
        border.width: primary ? 0 : 1
        border.color: primary ? "transparent" : "#7aa8c0e0"
        Text {
            id: txt
            anchors.centerIn: parent
            text: btn.label
            color: btn.primary ? "#0a0e1a" : root.cText
            font.pixelSize: 14
            font.bold: true
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
