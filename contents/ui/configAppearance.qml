import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: root

    property alias cfg_iconStyle: iconStyleCombo.currentValue

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
            currentIndex: {
                var current = plasmoid.configuration.iconStyle || "onedrive";
                for (var i = 0; i < model.length; ++i) {
                    if (model[i].value === current) {
                        return i;
                    }
                }
                return 0;
            }
        }
    }
}
