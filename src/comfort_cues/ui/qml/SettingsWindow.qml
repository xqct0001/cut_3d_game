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
    height: 560
    minimumWidth: 720
    minimumHeight: 520
    visible: false
    title: "Comfort Cues"
    color: pageColor

    readonly property color pageColor: "#202426"
    readonly property color panelColor: "#F7F8F4"
    readonly property color borderColor: "#D7DED8"
    readonly property color textColor: "#172023"
    readonly property color mutedColor: "#6E828A"
    readonly property color greenColor: "#238D65"
    readonly property color blueColor: "#286B78"
    readonly property color warningColor: "#A66E18"
    readonly property color lineColor: "#DCE3DE"
    readonly property var appController: controller
    readonly property string language: appController.uiLanguage === "zh" ? "zh" : "en"
    readonly property var languageOptions: [
        { labelEn: "English", labelZh: "English", value: "en" },
        { labelEn: "Chinese", labelZh: "中文", value: "zh" }
    ]

    onClosing: {
        close.accepted = false
        settingsWindow.hide()
    }

    ScrollView {
        id: settingsScrollView
        anchors.fill: parent
        clip: true
        leftPadding: 24
        topPadding: 22
        rightPadding: 24
        bottomPadding: 22
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        background: Rectangle { color: pageColor }

        ColumnLayout {
            width: settingsScrollView.availableWidth
            spacing: 14

            StatusHeader {
                controller: settingsWindow.appController
                strings: Strings
                language: settingsWindow.language
                languageOptions: settingsWindow.languageOptions
                textColor: "#F7F8F4"
                mutedColor: "#A9B8B8"
                greenColor: "#78D6A4"
            }

            SessionPanel {
                controller: settingsWindow.appController
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
                controller: settingsWindow.appController
                strings: Strings
                language: settingsWindow.language
                panelColor: settingsWindow.panelColor
                borderColor: settingsWindow.borderColor
                textColor: settingsWindow.textColor
                mutedColor: settingsWindow.mutedColor
                greenColor: settingsWindow.greenColor
            }

            ProfilePanel {
                controller: settingsWindow.appController
                strings: Strings
                language: settingsWindow.language
                panelColor: settingsWindow.panelColor
                borderColor: settingsWindow.borderColor
                textColor: settingsWindow.textColor
                mutedColor: settingsWindow.mutedColor
            }

            AdvancedPanel {
                controller: settingsWindow.appController
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

    Rectangle {
        anchors.fill: parent
        visible: settingsWindow.appController.bindInProgress
        color: "#99000000"

        Rectangle {
            anchors.centerIn: parent
            width: 360
            implicitHeight: scanLayout.implicitHeight + 34
            radius: 10
            color: "#F7F8F4"
            border.color: "#78D6A4"
            border.width: 1

            ColumnLayout {
                id: scanLayout
                anchors.fill: parent
                anchors.margins: 17
                spacing: 10

                Label {
                    Layout.fillWidth: true
                    text: Strings.tr(settingsWindow.language, "scanDialogTitle")
                    color: settingsWindow.textColor
                    font.pixelSize: 22
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    text: Strings.tr(settingsWindow.language, "scanDialogBody")
                    color: settingsWindow.mutedColor
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Label { text: "1 " + Strings.tr(settingsWindow.language, "scanStepHide"); color: settingsWindow.greenColor; font.bold: true }
                    Label { text: "2 " + Strings.tr(settingsWindow.language, "scanStepFocus"); color: settingsWindow.textColor; font.bold: true }
                    Label { text: "3 " + Strings.tr(settingsWindow.language, "scanStepBind"); color: settingsWindow.textColor; font.bold: true }
                }
            }
        }
    }
}
