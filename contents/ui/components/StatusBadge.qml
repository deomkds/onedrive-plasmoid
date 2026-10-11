import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Rectangle {
    id: root

    property string status: "idle" // "idle", "syncing", "suspended", "offline", "error"
    property string statusText: i18n("Ready")

    implicitHeight: 22
    implicitWidth: layout.implicitWidth + Kirigami.Units.mediumSpacing

    radius: height / 2

    color: {
        switch (root.status) {
        case "syncing":
            return Kirigami.Theme.highlightColor;
        case "idle": {
            var pos = Kirigami.Theme.positiveTextColor;
            return (pos && pos.r !== undefined) ? Qt.rgba(pos.r, pos.g, pos.b, 0.15) : Qt.rgba(0.2, 0.8, 0.2, 0.15);
        }
        case "suspended": {
            var neu = Kirigami.Theme.neutralTextColor;
            return (neu && neu.r !== undefined) ? Qt.rgba(neu.r, neu.g, neu.b, 0.15) : Qt.rgba(0.9, 0.7, 0.1, 0.15);
        }
        case "error":
        case "offline": {
            var neg = Kirigami.Theme.negativeTextColor;
            return (neg && neg.r !== undefined) ? Qt.rgba(neg.r, neg.g, neg.b, 0.15) : Qt.rgba(0.9, 0.2, 0.2, 0.15);
        }
        default:
            return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1);
        }
    }

    border.width: 1
    border.color: {
        switch (root.status) {
        case "syncing":
            return Kirigami.Theme.highlightColor;
        case "idle":
            return Kirigami.Theme.positiveTextColor || "#27ae60";
        case "suspended":
            return Kirigami.Theme.neutralTextColor || "#f39c12";
        case "error":
        case "offline":
            return Kirigami.Theme.negativeTextColor || "#e74c3c";
        default:
            return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2);
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 4

        PlasmaComponents3.BusyIndicator {
            visible: root.status === "syncing"
            running: root.status === "syncing"
            implicitWidth: 12
            implicitHeight: 12
            Layout.alignment: Qt.AlignVCenter
        }

        Kirigami.Icon {
            visible: root.status !== "syncing"
            source: {
                switch (root.status) {
                case "idle":
                    return "state-sync";
                case "suspended":
                    return "media-playback-pause";
                case "error":
                    return "dialog-error";
                case "offline":
                    return "network-offline";
                default:
                    return "state-ok";
                }
            }
            implicitWidth: 12
            implicitHeight: 12
            Layout.alignment: Qt.AlignVCenter
        }

        PlasmaComponents3.Label {
            text: root.statusText
            font.bold: true
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
            color: {
                if (root.status === "syncing") {
                    return Kirigami.Theme.highlightedTextColor;
                }
                return Kirigami.Theme.textColor;
            }
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
