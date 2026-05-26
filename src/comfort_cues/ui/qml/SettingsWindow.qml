import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "components"
import "i18n/Strings.js" as Strings

Window {
    id: settingsWindow
    objectName: "settingsWindow"
    width: 760
    height: 640
    minimumWidth: 720
    minimumHeight: 560
    visible: false
    title: "Comfort Cues"
    color: pageColor

    readonly property color pageColor: "#F6F7F4"
    readonly property color panelColor: "#FFFFFF"
    readonly property color borderColor: "#D7DDD8"
    readonly property color textColor: "#1E252B"
    readonly property color mutedColor: "#65706A"
    readonly property color greenColor: "#256B4D"
    readonly property color blueColor: "#2F5E85"
    readonly property color warningColor: "#8A5B20"
    readonly property color lineColor: "#E4E8E2"
    readonly property string language: controller.uiLanguage === "zh" ? "zh" : "en"
    readonly property var languageOptions: [
        { labelEn: "English", labelZh: "English", value: "en" },
        { labelEn: "Chinese", labelZh: "中文", value: "zh" }
    ]

    onClosing: {
        close.accepted = false
        settingsWindow.hide()
    }

    Rectangle {
        anchors.fill: parent
        color: pageColor
    }

    ScrollView {
        id: settingsScrollView
        anchors.fill: parent
        clip: true
        leftPadding: 20
        topPadding: 18
        rightPadding: 20
        bottomPadding: 20
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: settingsScrollView.availableWidth
            spacing: 12

            StatusHeader {
                controller: controller
                strings: Strings
                language: settingsWindow.language
                languageOptions: settingsWindow.languageOptions
                textColor: settingsWindow.textColor
                mutedColor: settingsWindow.mutedColor
                greenColor: settingsWindow.greenColor
            }

            SessionPanel {
                controller: controller
                strings: Strings
                language: settingsWindow.language
                panelColor: settingsWindow.panelColor
                borderColor: settingsWindow.borderColor
                textColor: settingsWindow.textColor
                mutedColor: settingsWindow.mutedColor
                greenColor: settingsWindow.greenColor
                blueColor: settingsWindow.blueColor
                warningColor: settingsWindow.warningColor
                lineColor: settingsWindow.lineColor
            }

            ComfortControls {
                controller: controller
                strings: Strings
                language: settingsWindow.language
                panelColor: settingsWindow.panelColor
                borderColor: settingsWindow.borderColor
                textColor: settingsWindow.textColor
                mutedColor: settingsWindow.mutedColor
                greenColor: settingsWindow.greenColor
            }

            ProfilePanel {
                controller: controller
                strings: Strings
                language: settingsWindow.language
                panelColor: settingsWindow.panelColor
                borderColor: settingsWindow.borderColor
                textColor: settingsWindow.textColor
                mutedColor: settingsWindow.mutedColor
            }

            AdvancedPanel {
                controller: controller
                strings: Strings
                language: settingsWindow.language
                panelColor: settingsWindow.panelColor
                borderColor: settingsWindow.borderColor
                textColor: settingsWindow.textColor
                mutedColor: settingsWindow.mutedColor
                lineColor: settingsWindow.lineColor
            }
        }
    }
}
