import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    property var mainRoot: plasmoid.rootItem || null

    readonly property bool inVerticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property string currentStatus: mainRoot ? mainRoot.syncStatus : "idle"
    readonly property string statusDesc: mainRoot ? mainRoot.statusDescription : i18n("Ready")
    readonly property string freeSpace: mainRoot ? mainRoot.quotaRemaining : ""
    readonly property string lastSync: mainRoot ? mainRoot.lastSyncTime : ""

    Layout.preferredWidth: inVerticalPanel ? Kirigami.Units.iconSizes.medium : Kirigami.Units.iconSizes.medium
    Layout.preferredHeight: inVerticalPanel ? Kirigami.Units.iconSizes.medium : Kirigami.Units.iconSizes.medium
    Layout.minimumWidth: Kirigami.Units.iconSizes.small
    Layout.minimumHeight: Kirigami.Units.iconSizes.small

    Item {
        id: iconContainer
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width

        Kirigami.Icon {
            id: mainIcon
            anchors.fill: parent
            source: {
                if (plasmoid.configuration.iconStyle === "color") {
                    return Qt.resolvedUrl("../../images/OneDrive.svg");
                }
                return "cloud";
            }
            active: mouseArea.containsMouse
        }

        // Animated sync badge when syncing
        Kirigami.Icon {
            id: syncEmblem
            visible: compactRoot.currentStatus === "syncing"
            source: "state-sync"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: Math.round(parent.width * 0.5)
            height: width

            RotationAnimation on rotation {
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 1500
                running: compactRoot.currentStatus === "syncing"
            }
        }

        // Pause emblem
        Kirigami.Icon {
            id: pauseEmblem
            visible: compactRoot.currentStatus === "suspended"
            source: "media-playback-pause"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: Math.round(parent.width * 0.45)
            height: width
        }

        // Error emblem
        Kirigami.Icon {
            id: errorEmblem
            visible: compactRoot.currentStatus === "error" || compactRoot.currentStatus === "offline"
            source: "dialog-warning"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: Math.round(parent.width * 0.45)
            height: width
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        onClicked: {
            plasmoid.expanded = !plasmoid.expanded;
        }
    }

    PlasmaCore.ToolTipArea {
        id: toolTip
        anchors.fill: parent
        mainText: i18n("Microsoft OneDrive")
        subText: {
            var text = i18n("Status: %1", compactRoot.statusDesc);
            if (compactRoot.freeSpace !== "") {
                text += "\n" + i18n("Free space: %1", compactRoot.freeSpace);
            }
            if (compactRoot.lastSync !== "") {
                text += "\n" + i18n("Last updated: %1", compactRoot.lastSync);
            }
            return text;
        }
    }
}
