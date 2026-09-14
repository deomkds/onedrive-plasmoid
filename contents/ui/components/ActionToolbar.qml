import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

RowLayout {
    id: root

    property string status: "idle"
    property bool isBusy: false

    signal syncTriggered()
    signal togglePauseTriggered()
    signal openFolderTriggered()
    signal openWebTriggered()
    signal refreshTriggered()

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    readonly property real sharedActionWidth: Math.max(syncBtn.implicitWidth, pauseBtn.implicitWidth)
    readonly property real maxActionWidth: Kirigami.Units.gridUnit * 9

    PlasmaComponents3.Button {
        id: syncBtn
        text: root.status === "syncing" ? i18n("Syncing...") : i18n("Sync Now")
        icon.name: "state-sync"
        enabled: !root.isBusy && root.status !== "syncing"
        Layout.fillWidth: true
        Layout.preferredWidth: root.sharedActionWidth
        Layout.maximumWidth: root.maxActionWidth
        onClicked: root.syncTriggered()
    }

    PlasmaComponents3.Button {
        id: pauseBtn
        text: (root.status === "suspended" || root.status === "offline") ? i18n("Resume") : i18n("Pause")
        icon.name: (root.status === "suspended" || root.status === "offline") ? "media-playback-start" : "media-playback-pause"
        enabled: !root.isBusy
        Layout.fillWidth: true
        Layout.preferredWidth: root.sharedActionWidth
        Layout.maximumWidth: root.maxActionWidth
        onClicked: root.togglePauseTriggered()
    }

    Item {
        Layout.fillWidth: true
    }

    PlasmaComponents3.ToolButton {
        icon.name: "folder-open"
        display: PlasmaComponents3.AbstractButton.IconOnly
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("Open OneDrive Folder")
        onClicked: root.openFolderTriggered()
    }

    PlasmaComponents3.ToolButton {
        icon.name: "internet-services"
        display: PlasmaComponents3.AbstractButton.IconOnly
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("Open OneDrive on Web")
        onClicked: root.openWebTriggered()
    }

    PlasmaComponents3.ToolButton {
        icon.name: "view-refresh"
        display: PlasmaComponents3.AbstractButton.IconOnly
        enabled: !root.isBusy
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("Refresh Status")
        onClicked: root.refreshTriggered()
    }
}
