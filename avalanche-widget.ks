# avalanche-widget.ks — Snow Watch Plasma widget
# Shows live powder conditions for user-configured resorts via wheretosnow API.
# Widget ID: org.avalanche.snowwatch
# Available in Add Widgets — not placed automatically.

%post

WIDGET_DIR="/usr/share/plasma/plasmoids/org.avalanche.snowwatch"
mkdir -p "${WIDGET_DIR}/contents/ui"
mkdir -p "${WIDGET_DIR}/contents/config"

# ── metadata.json ─────────────────────────────────────────────────────────────
cat > "${WIDGET_DIR}/metadata.json" << 'TXTEOF'
{
    "KPackageStructure": "Plasma/Applet",
    "KPlugin": {
        "Authors": [{ "Name": "Maxime Turcotte" }],
        "Category": "Online Services",
        "Description": "Live powder conditions for your watched resorts, powered by wheretosnow.",
        "EnabledByDefault": false,
        "Id": "org.avalanche.snowwatch",
        "License": "GPL-2.0-or-later",
        "Name": "Snow Watch",
        "Version": "1.0"
    },
    "X-Plasma-API-Minimum-Version": "6.0",
    "X-Plasma-StandAloneApp": false
}
TXTEOF

# ── Config schema ─────────────────────────────────────────────────────────────
cat > "${WIDGET_DIR}/contents/config/main.xml" << 'TXTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
                          http://www.kde.org/standards/kcfg/1.0/kcfg.xsd">
  <kcfgfile name=""/>
  <group name="General">
    <entry name="watchedResorts" type="String">
      <default>massif-du-sud</default>
    </entry>
    <entry name="refreshInterval" type="Int">
      <default>30</default>
    </entry>
  </group>
</kcfg>
TXTEOF

cat > "${WIDGET_DIR}/contents/config/config.qml" << 'TXTEOF'
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Resorts"
        icon: "globe"
        source: "ConfigPage.qml"
    }
}
TXTEOF

# ── main.qml ──────────────────────────────────────────────────────────────────
cat > "${WIDGET_DIR}/contents/ui/main.qml" << 'TXTEOF'
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
                        snow24h:    d.last_24h_cm   !== undefined ? d.last_24h_cm.toFixed(1)  : "—",
                        depth:      d.snow_depth_cm !== undefined ? d.snow_depth_cm.toFixed(0) : "—"
                    })
                } catch(e) {}
            }
        }
        xhr.send()
    }

    function updateRelativeTime() {
        if (root.lastRefreshTime === 0) { root.lastUpdated = ""; return }
        var secs = Math.round((Date.now() - root.lastRefreshTime) / 1000)
        if (secs < 60)        root.lastUpdated = "just now"
        else if (secs < 3600) root.lastUpdated = Math.floor(secs / 60) + " min ago"
        else                  root.lastUpdated = Math.floor(secs / 3600) + " hr ago"
    }

    Timer {
        interval: Plasmoid.configuration.refreshInterval * 60 * 1000
        repeat: true; running: true
        onTriggered: root.refreshAll()
    }
    Timer {
        interval: 30000; repeat: true; running: true
        onTriggered: root.updateRelativeTime()
    }

    Component.onCompleted: root.loadResortNames()

    Connections {
        target: Plasmoid.configuration
        function onWatchedResortsChanged() { root.refreshAll() }
    }

    compactRepresentation: Row {
        spacing: 4
        Text {
            text: "⛰"
            color: "white"; font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: resortModel.count > 0
                ? resortModel.get(0).resortName + "  PI:" + resortModel.get(0).pi
                  + "  ❄" + resortModel.get(0).snow24h + "cm"
                : "Snow Watch"
            color: "white"; font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
        }
    }

    fullRepresentation: ColumnLayout {
        spacing: 8
        width: 320; implicitWidth: 320

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Snow Watch"; color: "#FF4D1C"; font.pixelSize: 16; font.bold: true }
            Item { Layout.fillWidth: true }
            Text { text: root.lastUpdated; color: "#aaaaaa"; font.pixelSize: 11 }
            QQC2.Button {
                flat: true; implicitWidth: 28; implicitHeight: 28
                onClicked: root.refreshAll()
                contentItem: Text {
                    text: "↻"; color: "white"; font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Text {
            visible: resortModel.count === 0
            text: "Add resorts in widget settings"
            color: "#aaaaaa"; font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter
            topPadding: 16; bottomPadding: 16
        }

        ListView {
            visible: resortModel.count > 0
            Layout.fillWidth: true
            implicitHeight: Math.min(resortModel.count * 44, 220)
            model: resortModel; clip: true; spacing: 2

            delegate: Rectangle {
                width: ListView.view.width; height: 40
                color: mouseArea.containsMouse ? "#22ffffff" : "transparent"; radius: 4

                MouseArea {
                    id: mouseArea; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://turcserv.duckdns.org/wheretosnow/")
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    spacing: 8
                    Text {
                        text: model.resortName; color: "white"; font.bold: true; font.pixelSize: 13
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                    Text {
                        text: "PI " + model.pi
                        color: model.pi < 20 ? "#888888" : model.pi < 60 ? "#38bdf8" : "white"
                        font.pixelSize: 12; font.bold: model.pi >= 60
                    }
                    Text { text: "❄ " + model.snow24h + "cm"; color: "#cccccc"; font.pixelSize: 12 }
                    Text { text: "↕ " + model.depth + "cm"; color: "#aaaaaa"; font.pixelSize: 11 }
                }
            }
        }
    }
}
TXTEOF

# ── ConfigPage.qml ────────────────────────────────────────────────────────────
cat > "${WIDGET_DIR}/contents/ui/ConfigPage.qml" << 'TXTEOF'
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid

ColumnLayout {
    id: configRoot
    spacing: 12

    readonly property string apiBase: "https://turcserv.duckdns.org/wheretosnow/api"
    property var allResorts: []
    property var nameMap: ({})
    property var watchedIds: Plasmoid.configuration.watchedResorts
        .split(",").map(function(s) { return s.trim() }).filter(function(s) { return s.length > 0 })

    function saveWatched() { Plasmoid.configuration.watchedResorts = watchedIds.join(",") }
    function addResort(id) {
        if (watchedIds.indexOf(id) === -1) { watchedIds = watchedIds.concat([id]); saveWatched() }
    }
    function removeResort(id) {
        watchedIds = watchedIds.filter(function(x) { return x !== id }); saveWatched()
    }
    function loadAllResorts() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", apiBase + "/resorts")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) {
                try {
                    var list = JSON.parse(xhr.responseText)
                    var map = {}
                    for (var i = 0; i < list.length; i++) map[list[i].id] = list[i].name
                    configRoot.nameMap = map
                    configRoot.allResorts = list
                } catch(e) {}
            }
        }
        xhr.send()
    }

    Component.onCompleted: loadAllResorts()

    Text { text: "Currently watching"; color: "white"; font.bold: true; font.pixelSize: 13 }
    Text {
        visible: configRoot.watchedIds.length === 0
        text: "None — add resorts below."; color: "#888888"; font.pixelSize: 12
    }
    Repeater {
        model: configRoot.watchedIds
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text {
                text: configRoot.nameMap[modelData] || modelData
                color: "white"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight
            }
            QQC2.Button { text: "Remove"; onClicked: configRoot.removeResort(modelData) }
        }
    }

    Rectangle { height: 1; Layout.fillWidth: true; color: "#44ffffff" }

    Text { text: "Add resort"; color: "white"; font.bold: true; font.pixelSize: 13 }
    QQC2.TextField {
        id: searchField; Layout.fillWidth: true; placeholderText: "Search…"; color: "white"
        background: Rectangle { color: "#22ffffff"; radius: 4 }
    }
    ListView {
        id: resortPicker
        Layout.fillWidth: true
        implicitHeight: Math.min(filteredResorts.count * 36, 180)
        clip: true
        model: ListModel { id: filteredResorts }

        function rebuild() {
            filteredResorts.clear()
            var filter = searchField.text.toLowerCase()
            for (var i = 0; i < configRoot.allResorts.length; i++) {
                var r = configRoot.allResorts[i]
                if (configRoot.watchedIds.indexOf(r.id) !== -1) continue
                if (filter && r.name.toLowerCase().indexOf(filter) === -1) continue
                filteredResorts.append({ resortId: r.id, resortName: r.name })
            }
        }
        Connections { target: searchField;  function onTextChanged()      { resortPicker.rebuild() } }
        Connections { target: configRoot;   function onAllResortsChanged() { resortPicker.rebuild() }
                                            function onWatchedIdsChanged() { resortPicker.rebuild() } }

        delegate: Rectangle {
            width: ListView.view.width; height: 34
            color: addMouse.containsMouse ? "#33ffffff" : "transparent"; radius: 4
            Text {
                text: model.resortName; color: "white"; font.pixelSize: 12
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 8 }
                elide: Text.ElideRight; width: parent.width - 16
            }
            MouseArea {
                id: addMouse; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: configRoot.addResort(model.resortId)
            }
        }
    }
}
TXTEOF

echo "AVALANCHE: Snow Watch widget installed (org.avalanche.snowwatch)"

%end
