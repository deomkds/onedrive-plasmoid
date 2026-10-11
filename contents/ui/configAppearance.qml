import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: root

    property string cfg_iconStyle: "onedrive"

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: iconStyleCombo
            Kirigami.FormData.label: i18n("Panel icon style:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("System OneDrive Icon (Color - Default)"), value: "onedrive" },
                { text: i18n("OneDrive Monochrome (Adapts to Light/Dark Theme)"), value: "onedrive-monochrome" },
                { text: i18n("Breeze OneDrive Symbolic"), value: "folder-onedrive-symbolic" },
                { text: i18n("Breeze Cloud Symbolic"), value: "cloudstatus" },
                { text: i18n("Folder OneDrive Icon (Color)"), value: "folder-onedrive" }
            ]
            currentIndex: indexOfValue(root.cfg_iconStyle) >= 0 ? indexOfValue(root.cfg_iconStyle) : 0
            onActivated: root.cfg_iconStyle = currentValue
        }
    }
}
