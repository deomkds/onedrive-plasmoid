import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: compactRoot

    required property PlasmoidItem plasmoidItem

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        property bool wasExpanded: false

        onPressed: mouse => {
            wasExpanded = compactRoot.plasmoidItem.expanded;
        }

        onClicked: mouse => {
            compactRoot.plasmoidItem.expanded = !wasExpanded;
        }
    }

    Kirigami.Icon {
        id: mainIcon
        anchors.fill: parent
        source: Plasmoid.icon
        active: mouseArea.containsMouse
        isMask: {
            var s = plasmoid.configuration.iconStyle;
            return s === "onedrive-monochrome" || s === "folder-onedrive-symbolic" || s === "cloudstatus";
        }
    }

    // Overlay animated sync emblem when syncing
    Kirigami.Icon {
        visible: compactRoot.plasmoidItem && compactRoot.plasmoidItem.syncStatus === "syncing"
        source: "state-sync"
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: Math.round(parent.width * 0.45)
        height: width

        RotationAnimation on rotation {
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1500
            running: compactRoot.plasmoidItem && compactRoot.plasmoidItem.syncStatus === "syncing"
        }
    }

    // Overlay pause emblem
    Kirigami.Icon {
        visible: compactRoot.plasmoidItem && compactRoot.plasmoidItem.syncStatus === "suspended"
        source: "media-playback-pause"
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: Math.round(parent.width * 0.45)
        height: width
    }

    // Overlay error emblem
    Kirigami.Icon {
        visible: compactRoot.plasmoidItem && (compactRoot.plasmoidItem.syncStatus === "error" || compactRoot.plasmoidItem.syncStatus === "offline")
        source: "dialog-warning"
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: Math.round(parent.width * 0.45)
        height: width
    }
}
