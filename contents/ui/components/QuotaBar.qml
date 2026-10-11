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

    spacing: 3
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true

        Kirigami.Icon {
            source: "drive-harddisk"
            implicitWidth: 14
            implicitHeight: 14
            Layout.alignment: Qt.AlignVCenter
        }

        PlasmaComponents3.Label {
            text: i18n("Storage")
            font.bold: true
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
        }

        Item { Layout.fillWidth: true }

        PlasmaComponents3.Label {
            text: (root.totalFormatted && root.totalFormatted !== "0 GB")
                ? ((root.remainingFormatted && root.remainingFormatted !== "0 GB")
                    ? i18n("%1 / %2 • %3 free", root.usedFormatted, root.totalFormatted, root.remainingFormatted)
                    : i18n("%1 / %2 (%3%)", root.usedFormatted, root.totalFormatted, Math.round(root.percentUsed * 100)))
                : i18n("Checking quota...")
            opacity: 0.75
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.82
        }
    }

    PlasmaComponents3.ProgressBar {
        id: progressBar
        Layout.fillWidth: true
        Layout.preferredHeight: 6
        from: 0.0
        to: 1.0
        value: root.percentUsed
        indeterminate: root.loading && root.totalFormatted === "0 GB"
    }
}
