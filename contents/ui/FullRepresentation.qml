import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import "components"

Item {
    id: fullRoot

    property var mainRoot: plasmoid.rootItem || null

    readonly property string syncStatus: mainRoot ? mainRoot.syncStatus : "idle"
    readonly property string statusDescription: mainRoot ? mainRoot.statusDescription : i18n("Ready")
    readonly property string accountType: mainRoot ? mainRoot.accountType : ""
    readonly property string resolvedSyncDir: mainRoot ? mainRoot.resolvedSyncDir : "~/OneDrive"
    readonly property real quotaPercent: mainRoot ? mainRoot.quotaPercent : 0.0
    readonly property string quotaUsed: mainRoot ? mainRoot.quotaUsed : "0 GB"
    readonly property string quotaTotal: mainRoot ? mainRoot.quotaTotal : "0 GB"
    readonly property string quotaRemaining: mainRoot ? mainRoot.quotaRemaining : "0 GB"
    readonly property bool isBusy: mainRoot ? mainRoot.isBusy : false
    readonly property var activityModel: mainRoot ? mainRoot.activityModel : dummyModel

    ListModel {
        id: dummyModel
    }

    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
    Layout.maximumWidth: Kirigami.Units.gridUnit * 28

    Layout.minimumHeight: Kirigami.Units.gridUnit * 28
    Layout.preferredHeight: Kirigami.Units.gridUnit * 34
    Layout.maximumHeight: Kirigami.Units.gridUnit * 40

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing * 1.5
        spacing: Kirigami.Units.smallSpacing

        // Header Section (Integrated with Folder Path)
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: Plasmoid.icon || "onedrive"
                implicitWidth: 24
                implicitHeight: 24
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        text: i18n("Microsoft OneDrive")
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    }

                    PlasmaComponents3.Label {
                        text: fullRoot.accountType ? "• " + fullRoot.accountType : ""
                        opacity: 0.5
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                    }
                }

                PlasmaComponents3.Label {
                    text: fullRoot.resolvedSyncDir
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                    opacity: 0.7
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.82
                }
            }

            StatusBadge {
                status: fullRoot.syncStatus
                statusText: fullRoot.statusDescription
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Storage Quota Bar
        QuotaBar {
            percentUsed: fullRoot.quotaPercent
            usedFormatted: fullRoot.quotaUsed
            totalFormatted: fullRoot.quotaTotal
            remainingFormatted: fullRoot.quotaRemaining
            loading: fullRoot.isBusy
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // Quick Actions
        ActionToolbar {
            status: fullRoot.syncStatus
            isBusy: fullRoot.isBusy

            onSyncTriggered: { if (mainRoot) mainRoot.triggerSync(); }
            onTogglePauseTriggered: { if (mainRoot) mainRoot.togglePause(); }
            onOpenFolderTriggered: { if (mainRoot) mainRoot.openFolder(); }
            onOpenWebTriggered: { if (mainRoot) mainRoot.openWeb(); }
            onRefreshTriggered: { if (mainRoot) mainRoot.refreshAll(); }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // Recent Activity Feed Header
        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents3.Label {
                text: i18n("Recent Activity")
                font.bold: true
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
                Layout.fillWidth: true
            }

            PlasmaComponents3.Label {
                text: i18n("(%1)", fullRoot.activityModel ? fullRoot.activityModel.count : 0)
                opacity: 0.5
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                visible: fullRoot.activityModel && fullRoot.activityModel.count > 0
            }

            PlasmaComponents3.ToolButton {
                icon.name: "edit-clear"
                display: PlasmaComponents3.AbstractButton.IconOnly
                visible: fullRoot.activityModel && fullRoot.activityModel.count > 0
                implicitWidth: 20
                implicitHeight: 20
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.text: i18n("Clear activity log")
                onClicked: {
                    if (mainRoot) mainRoot.clearActivityLog();
                }
            }
        }

        // Activity List View
        PlasmaComponents3.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: activityListView
                clip: true
                model: fullRoot.activityModel
                spacing: 2

                delegate: ActivityItem {
                    width: activityListView.width
                    operationType: model.type || "info"
                    operationTitle: model.title || ""
                    fileName: model.fileName || ""
                    filePath: model.filePath || model.fileName || ""
                    time: model.time || ""
                    iconName: model.icon || ""

                    onItemClicked: function(file) {
                        if (mainRoot) mainRoot.openFileOrFolder(file);
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: activityListView.count === 0
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: "state-sync"
                        implicitWidth: Kirigami.Units.iconSizes.large
                        implicitHeight: Kirigami.Units.iconSizes.large
                        opacity: 0.35
                        Layout.alignment: Qt.AlignHCenter
                    }

                    PlasmaComponents3.Label {
                        text: i18n("No recent activity")
                        opacity: 0.6
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                        Layout.alignment: Qt.AlignHCenter
                    }

                    PlasmaComponents3.Label {
                        text: i18n("Files synced by OneDrive will appear here.")
                        opacity: 0.4
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // Footer Section
        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents3.Label {
                text: plasmoid.configuration.serviceMode === "systemd"
                    ? i18n("Service: %1", plasmoid.configuration.systemdService)
                    : i18n("Mode: Standalone CLI")
                opacity: 0.5
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.78
                Layout.fillWidth: true
            }

            PlasmaComponents3.ToolButton {
                icon.name: "utilities-terminal"
                display: PlasmaComponents3.AbstractButton.IconOnly
                implicitWidth: 22
                implicitHeight: 22
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.text: i18n("View OneDrive Service Logs")
                onClicked: {
                    if (mainRoot) mainRoot.viewLogs();
                }
            }

            PlasmaComponents3.ToolButton {
                icon.name: "configure"
                display: PlasmaComponents3.AbstractButton.IconOnly
                implicitWidth: 22
                implicitHeight: 22
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.text: i18n("Configure OneDrive Widget")
                onClicked: {
                    if (plasmoid.action("configure")) {
                        plasmoid.action("configure").trigger();
                    }
                }
            }
        }
    }
}
