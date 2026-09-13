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

        property bool wasExpanded: false

        onPressed: mouse => {
            wasExpanded = plasmoid.expanded;
        }

        onClicked: mouse => {
            plasmoid.expanded = !wasExpanded;
        }
    }
}
