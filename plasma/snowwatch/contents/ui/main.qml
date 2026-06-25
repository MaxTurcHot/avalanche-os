import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents

PlasmoidItem {
    id: root

    readonly property string apiBase: "https://turcserv.duckdns.org/wheretosnow/api"
    property var nameMap: ({})
    property string lastUpdated: ""
    property var lastRefreshTime: 0

    ListModel { id: resortModel }

    // ── Data loading ────────────────────────────────────────────────────────

    function loadResortNames() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", apiBase + "/resorts")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) {
                try {
                    var list = JSON.parse(xhr.responseText)
                    var map = {}
                    for (var i = 0; i < list.length; i++) {
                        map[list[i].id] = list[i].name
                    }
                    root.nameMap = map
                } catch(e) {}
            }
            refreshAll()
        }
        xhr.send()
    }

    function refreshAll() {
        resortModel.clear()
        var ids = Plasmoid.configuration.watchedResorts
            .split(",")
            .map(function(s) { return s.trim() })
            .filter(function(s) { return s.length > 0 })
        for (var i = 0; i < ids.length; i++) {
            fetchResort(ids[i])
        }
        root.lastRefreshTime = Date.now()
        updateRelativeTime()
    }

    function fetchResort(id) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", apiBase + "/resort-snow-detail?id=" + id)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) {
                try {
                    var d = JSON.parse(xhr.responseText)
                    var pi = (d.pi_state && d.pi_state.current_pi !== undefined)
                        ? Math.round(d.pi_state.current_pi) : 0
                    resortModel.append({
                        resortId:   id,
                        resortName: root.nameMap[id] || id,
                        pi:         pi,
                        snow24h:    d.last_24h_cm   !== undefined ? d.last_24h_cm.toFixed(1)   : "—",
                        depth:      d.snow_depth_cm !== undefined ? d.snow_depth_cm.toFixed(0)  : "—"
                    })
                } catch(e) {}
            }
        }
        xhr.send()
    }

    function updateRelativeTime() {
        if (root.lastRefreshTime === 0) {
            root.lastUpdated = ""
            return
        }
        var secs = Math.round((Date.now() - root.lastRefreshTime) / 1000)
        if (secs < 60)       root.lastUpdated = "just now"
        else if (secs < 3600) root.lastUpdated = Math.floor(secs / 60) + " min ago"
        else                  root.lastUpdated = Math.floor(secs / 3600) + " hr ago"
    }

    Timer {
        id: refreshTimer
        interval: Plasmoid.configuration.refreshInterval * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refreshAll()
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.updateRelativeTime()
    }

    Component.onCompleted: root.loadResortNames()

    Connections {
        target: Plasmoid.configuration
        function onWatchedResortsChanged() { root.refreshAll() }
    }

    // ── Compact (panel) representation ──────────────────────────────────────

    compactRepresentation: Row {
        spacing: 4

        Text {
            text: "⛰"
            color: "white"
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: resortModel.count > 0
                ? resortModel.get(0).resortName + "  PI:" + resortModel.get(0).pi
                  + "  ❄" + resortModel.get(0).snow24h + "cm"
                : "Snow Watch"
            color: "white"
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
        }
    }

    // ── Full (desktop) representation ────────────────────────────────────────

    fullRepresentation: ColumnLayout {
        spacing: 8
        width: 320
        implicitWidth: 320

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Snow Watch"
                color: "#FF4D1C"
                font.pixelSize: 16
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.lastUpdated
                color: "#aaaaaa"
                font.pixelSize: 11
            }
            QQC2.Button {
                text: "↻"
                flat: true
                implicitWidth: 28
                implicitHeight: 28
                onClicked: root.refreshAll()
                contentItem: Text {
                    text: "↻"
                    color: "white"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Empty state
        Text {
            visible: resortModel.count === 0
            text: "Add resorts in widget settings"
            color: "#aaaaaa"
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter
            topPadding: 16
            bottomPadding: 16
        }

        // Resort list
        ListView {
            visible: resortModel.count > 0
            Layout.fillWidth: true
            implicitHeight: Math.min(resortModel.count * 44, 220)
            model: resortModel
            clip: true
            spacing: 2

            delegate: Rectangle {
                width: ListView.view.width
                height: 40
                color: mouseArea.containsMouse ? "#22ffffff" : "transparent"
                radius: 4

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://turcserv.duckdns.org/wheretosnow/")
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    spacing: 8

                    Text {
                        text: model.resortName
                        color: "white"
                        font.bold: true
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "PI " + model.pi
                        color: model.pi < 20 ? "#888888"
                             : model.pi < 60 ? "#38bdf8"
                             : "white"
                        font.pixelSize: 12
                        font.bold: model.pi >= 60
                    }

                    Text {
                        text: "❄ " + model.snow24h + "cm"
                        color: "#cccccc"
                        font.pixelSize: 12
                    }

                    Text {
                        text: "↕ " + model.depth + "cm"
                        color: "#aaaaaa"
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
