import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    id: root

    property real percentUsed: 0.0
    property string usedFormatted: "0 GB"
    property string totalFormatted: "0 GB"
    property string remainingFormatted: "0 GB"
    property bool loading: false

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true

        Kirigami.Icon {
            source: "drive-harddisk"
            implicitWidth: 16
            implicitHeight: 16
            Layout.alignment: Qt.AlignVCenter
        }

        PlasmaComponents3.Label {
            text: i18n("Cloud Storage")
            font.bold: true
            Layout.fillWidth: true
        }

        PlasmaComponents3.Label {
            text: root.totalFormatted !== "0 GB"
                ? i18n("%1 / %2 (%3%)", root.usedFormatted, root.totalFormatted, Math.round(root.percentUsed * 100))
                : i18n("Checking quota...")
            opacity: 0.75
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
        }
    }

    PlasmaComponents3.ProgressBar {
        id: progressBar
        Layout.fillWidth: true
        from: 0.0
        to: 1.0
        value: root.percentUsed
        indeterminate: root.loading && root.totalFormatted === "0 GB"
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: root.remainingFormatted !== "0 GB"
                ? i18n("Free space: %1", root.remainingFormatted)
                : ""
            opacity: 0.65
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
            Layout.fillWidth: true
        }
    }
}
