import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Rectangle {
    id: root

    property string iconName: "document-share"
    property string operationTitle: ""
    property string fileName: ""
    property string filePath: ""
    property string time: ""
    property string operationType: "info"

    signal itemClicked(string file)

    implicitHeight: layout.implicitHeight + Kirigami.Units.smallSpacing * 2
    Layout.fillWidth: true

    radius: Kirigami.Units.smallSpacing
    color: mouseArea.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1) : "transparent"

    RowLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.mediumSpacing

        Kirigami.Icon {
            source: {
                if (root.iconName) return root.iconName;
                switch (root.operationType) {
                case "upload": return "upload";
                case "download": return "download";
                case "delete": return "edit-delete";
                case "move": return "edit-rename";
                case "folder": return "folder";
                case "error": return "dialog-error";
                default: return "document-share";
                }
            }
            implicitWidth: 18
            implicitHeight: 18
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents3.Label {
                    text: root.operationTitle
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                    color: {
                        switch (root.operationType) {
                        case "upload":
                        case "download":
                            return Kirigami.Theme.highlightColor;
                        case "delete":
                            return Kirigami.Theme.negativeTextColor || "#e74c3c";
                        case "error":
                            return Kirigami.Theme.negativeTextColor || "#e74c3c";
                        default:
                            return Kirigami.Theme.textColor;
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents3.Label {
                    text: root.time
                    opacity: 0.5
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                }
            }

            PlasmaComponents3.Label {
                text: root.fileName
                elide: Text.ElideMiddle
                Layout.fillWidth: true
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                opacity: 0.9
            }
        }

        PlasmaComponents3.ToolButton {
            icon.name: "folder-open"
            display: PlasmaComponents3.AbstractButton.IconOnly
            visible: mouseArea.containsMouse && root.operationType !== "error" && root.operationType !== "delete"
            implicitWidth: 24
            implicitHeight: 24
            PlasmaComponents3.ToolTip.visible: hovered
            PlasmaComponents3.ToolTip.text: i18n("Open in File Manager")
            onClicked: root.itemClicked(root.filePath || root.fileName)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.operationType !== "error" && root.operationType !== "delete") {
                root.itemClicked(root.filePath || root.fileName);
            }
        }
    }
}
