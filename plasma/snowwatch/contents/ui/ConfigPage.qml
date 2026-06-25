import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: configRoot
    spacing: Kirigami.Units.smallSpacing

    readonly property string apiBase: "https://turcserv.duckdns.org/wheretosnow/api"
    property var allResorts: []
    property var nameMap: ({})
    property var watchedIds: []

    Component.onCompleted: {
        watchedIds = Plasmoid.configuration.watchedResorts
            .split(",").map(function(s) { return s.trim() })
            .filter(function(s) { return s.length > 0 })
        loadAllResorts()
    }

    function saveWatched() {
        Plasmoid.configuration.watchedResorts = watchedIds.join(",")
    }
    function addResort(id) {
        if (watchedIds.indexOf(id) === -1) {
            var n = watchedIds.slice(); n.push(id); watchedIds = n; saveWatched()
        }
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

    // Computed — QML re-evaluates automatically when allResorts, watchedIds, or
    // searchField.text changes. No manual rebuild() needed.
    property var filteredResorts: {
        var filter = searchField.text.toLowerCase()
        return configRoot.allResorts.filter(function(r) {
            if (configRoot.watchedIds.indexOf(r.id) !== -1) return false
            if (filter && r.name.toLowerCase().indexOf(filter) === -1) return false
            return true
        })
    }

    // ── Currently watching ───────────────────────────────────────────────────
    Kirigami.Heading { text: "Currently watching"; level: 4 }

    QQC2.Label {
        visible: configRoot.watchedIds.length === 0
        text: "No resorts watched — add some below."
        color: Kirigami.Theme.disabledTextColor
    }

    Repeater {
        model: configRoot.watchedIds
        delegate: RowLayout {
            Layout.fillWidth: true
            QQC2.Label {
                text: configRoot.nameMap[modelData] || modelData
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            QQC2.Button {
                text: "Remove"
                onClicked: configRoot.removeResort(modelData)
            }
        }
    }

    Kirigami.Separator { Layout.fillWidth: true }

    // ── Add resort ───────────────────────────────────────────────────────────
    Kirigami.Heading { text: "Add resort"; level: 4 }

    QQC2.TextField {
        id: searchField
        Layout.fillWidth: true
        placeholderText: "Search resorts…"
    }

    QQC2.Label {
        visible: configRoot.allResorts.length === 0
        text: "Loading resort list…"
        color: Kirigami.Theme.disabledTextColor
    }

    ListView {
        Layout.fillWidth: true
        implicitHeight: Math.min(contentHeight, 200)
        clip: true
        model: configRoot.filteredResorts

        delegate: QQC2.ItemDelegate {
            width: ListView.view.width
            text: modelData.name
            onClicked: configRoot.addResort(modelData.id)
        }
    }
}
