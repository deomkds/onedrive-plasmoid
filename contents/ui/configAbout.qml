import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.plasma.components as PlasmaComponents3

KCMUtils.SimpleKCM {
    id: root

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        Layout.fillWidth: true

        // Header / Identity
        RowLayout {
            spacing: Kirigami.Units.mediumSpacing
            Layout.fillWidth: true

            Kirigami.Icon {
                source: "onedrive"
                implicitWidth: 48
                implicitHeight: 48
                Layout.alignment: Qt.AlignTop
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                PlasmaComponents3.Label {
                    text: i18n("Microsoft OneDrive Plasmoid")
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                }

                PlasmaComponents3.Label {
                    text: i18n("Version 3.0.0 • Native KDE Plasma 6 Applet")
                    opacity: 0.7
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                }

                PlasmaComponents3.Label {
                    text: i18n("Monitor and control Microsoft OneDrive synchronization client on Linux")
                    opacity: 0.85
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // Authors
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.fillWidth: true

            PlasmaComponents3.Label {
                text: i18n("Author & Maintainer")
                font.bold: true
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
            }

            RowLayout {
                spacing: Kirigami.Units.mediumSpacing
                Layout.fillWidth: true

                Kirigami.Icon {
                    source: "user"
                    implicitWidth: 22
                    implicitHeight: 22
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true

                    PlasmaComponents3.Label {
                        text: "Marcus Vinícius"
                        font.bold: true
                    }

                    PlasmaComponents3.Label {
                        text: "mv.cunha2009@gmail.com"
                        opacity: 0.6
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                    }
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // Acknowledgments & Credits
        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.fillWidth: true

            PlasmaComponents3.Label {
                text: i18n("Acknowledgments")
                font.bold: true
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
            }

            RowLayout {
                spacing: Kirigami.Units.mediumSpacing
                Layout.fillWidth: true

                Kirigami.Icon {
                    source: "rating"
                    implicitWidth: 22
                    implicitHeight: 22
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true

                    PlasmaComponents3.Label {
                        text: "Daniel Borges de Oliveira"
                        font.bold: true
                    }

                    PlasmaComponents3.Label {
                        text: i18n("Original author of the onedrive_tray application")
                        opacity: 0.7
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                    }
                }
            }

            RowLayout {
                spacing: Kirigami.Units.mediumSpacing
                Layout.fillWidth: true

                Kirigami.Icon {
                    source: "application-x-executable"
                    implicitWidth: 22
                    implicitHeight: 22
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true

                    PlasmaComponents3.Label {
                        text: "abraunegg"
                        font.bold: true
                    }

                    PlasmaComponents3.Label {
                        text: i18n("Creator of the OneDrive Client for Linux (github.com/abraunegg/onedrive)")
                        opacity: 0.7
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                    }
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // License
        PlasmaComponents3.Label {
            text: i18n("License: GNU General Public License v3.0 (GPL-3.0-or-later)")
            opacity: 0.5
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
        }
    }
}
