import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: root

    property string cfg_serviceMode: "systemd"
    property alias cfg_systemdService: systemdServiceField.text
    property alias cfg_onedriveBin: onedriveBinField.text
    property alias cfg_syncDir: syncDirField.text
    property alias cfg_pollInterval: pollIntervalSpin.value
    property alias cfg_quotaInterval: quotaIntervalSpin.value
    property alias cfg_showNotifications: showNotificationsCheck.checked
    property alias cfg_webUrl: webUrlField.text

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: serviceModeCombo
            Kirigami.FormData.label: i18n("Operation mode:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Systemd User Service (Recommended)"), value: "systemd" },
                { text: i18n("Standalone Process / CLI Monitor"), value: "standalone" }
            ]
            currentIndex: indexOfValue(root.cfg_serviceMode) >= 0 ? indexOfValue(root.cfg_serviceMode) : 0
            onActivated: root.cfg_serviceMode = currentValue
        }

        QQC2.TextField {
            id: systemdServiceField
            Kirigami.FormData.label: i18n("Systemd service unit:")
            text: plasmoid.configuration.systemdService
            visible: root.cfg_serviceMode === "systemd"
            placeholderText: "onedrive.service"
        }

        QQC2.TextField {
            id: onedriveBinField
            Kirigami.FormData.label: i18n("OneDrive executable:")
            text: plasmoid.configuration.onedriveBin
            placeholderText: "onedrive"
        }

        QQC2.TextField {
            id: syncDirField
            Kirigami.FormData.label: i18n("Local sync folder:")
            text: plasmoid.configuration.syncDir
            placeholderText: "~/OneDrive"
        }

        QQC2.TextField {
            id: webUrlField
            Kirigami.FormData.label: i18n("OneDrive web URL:")
            text: plasmoid.configuration.webUrl
            placeholderText: "https://onedrive.live.com"
        }

        QQC2.SpinBox {
            id: pollIntervalSpin
            Kirigami.FormData.label: i18n("Status check interval:")
            from: 5
            to: 300
            stepSize: 5
            value: plasmoid.configuration.pollInterval
            textFromValue: function(value) {
                return i18n("%1 s", value);
            }
        }

        QQC2.SpinBox {
            id: quotaIntervalSpin
            Kirigami.FormData.label: i18n("Quota refresh interval:")
            from: 60
            to: 7200
            stepSize: 60
            value: plasmoid.configuration.quotaInterval
            textFromValue: function(value) {
                return i18n("%1 min", Math.round(value / 60));
            }
        }

        QQC2.CheckBox {
            id: showNotificationsCheck
            Kirigami.FormData.label: i18n("Notifications:")
            text: i18n("Show desktop notification on sync events and errors")
            checked: plasmoid.configuration.showNotifications
        }
    }
}
