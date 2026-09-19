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
    property int progress: -1
    property string status: ""
    property string eta: ""

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
                    text: {
                        if (root.status === "in_progress" && root.progress >= 0) {
                            if (root.operationType === "upload") {
                                return i18n("Uploading (%1%)", root.progress);
                            } else if (root.operationType === "download") {
                                return i18n("Downloading (%1%)", root.progress);
                            }
                        }
                        if (root.operationTitle) {
                            switch (root.operationTitle) {
                            case "Uploaded": return i18n("Uploaded");
                            case "Downloaded": return i18n("Downloaded");
                            case "Deleted": return i18n("Deleted");
                            case "Moved/Renamed": return i18n("Moved / Renamed");
                            case "Directory created": return i18n("Directory created");
                            case "Remote directory created": return i18n("Remote directory created");
                            case "Error": return i18n("Error");
                            default: return root.operationTitle;
                            }
                        }
                        return "";
                    }
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                    color: {
                        switch (root.operationType) {
                        case "upload":
                        case "download":
                            return Kirigami.Theme.highlightColor;
                        case "delete":
                        case "error":
                            return Kirigami.Theme.negativeTextColor || "#e74c3c";
                        default:
                            return Kirigami.Theme.textColor;
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents3.Label {
                    text: {
                        if (root.status === "in_progress" && root.progress >= 0) {
                            if (root.eta && root.eta !== "--:--:--") {
                                return i18n("ETA %1", root.eta);
                            }
                            return root.progress + "%";
                        }
                        return root.time;
                    }
                    opacity: root.status === "in_progress" ? 0.9 : 0.5
                    font.bold: root.status === "in_progress"
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                    color: root.status === "in_progress" ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                }
            }

            PlasmaComponents3.Label {
                text: root.fileName
                elide: Text.ElideMiddle
                Layout.fillWidth: true
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                opacity: 0.9
            }

            PlasmaComponents3.ProgressBar {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                Layout.preferredHeight: 4
                from: 0
                to: 100
                value: Math.max(0, root.progress)
                visible: root.status === "in_progress" && root.progress >= 0 && root.progress < 100
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
