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
                { text: i18n("System OneDrive Icon (Default)"), value: "onedrive" },
                { text: i18n("Folder OneDrive Icon"), value: "folder-onedrive" },
                { text: i18n("Generic Cloud Icon"), value: "cloud" }
            ]
            currentIndex: {
                if (plasmoid.configuration.iconStyle === "folder-onedrive") return 1;
                if (plasmoid.configuration.iconStyle === "cloud") return 2;
                return 0;
            }
        }
    }
}
