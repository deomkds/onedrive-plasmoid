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
                { text: i18n("Breeze Theme Monochrome / Adaptive"), value: "breeze" },
                { text: i18n("Official OneDrive Blue / Colored"), value: "color" }
            ]
            currentIndex: plasmoid.configuration.iconStyle === "color" ? 1 : 0
        }
    }
}
