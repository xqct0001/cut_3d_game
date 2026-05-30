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
    height: 520
    minimumWidth: 720
    minimumHeight: 500
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
            width: Math.min(parent.width - 48, 620)
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

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(280, Math.max(96, contentHeight))
                    clip: true
                    spacing: 8
                    model: settingsWindow.appController.bindWindowCandidates

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 72
                        radius: 8
                        color: settingsWindow.appController.selectedBindWindowIndex === modelData.index ? "#E0F1E7" : "#FFFFFF"
                        border.color: settingsWindow.appController.selectedBindWindowIndex === modelData.index ? settingsWindow.greenColor : settingsWindow.borderColor
                        border.width: 1

                        MouseArea {
                            anchors.fill: parent
                            onClicked: settingsWindow.appController.selectedBindWindowIndex = modelData.index
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: settingsWindow.textColor
                                    font.pixelSize: 15
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: Strings.modeSummary(settingsWindow.language, modelData.mode)
                                    color: modelData.supported ? settingsWindow.greenColor : settingsWindow.warningColor
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData.exeName + "  ·  " + modelData.windowClass + "  ·  " + modelData.rect
                                color: settingsWindow.mutedColor
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: settingsWindow.appController.bindWindowCandidates.length === 0
                    text: Strings.tr(settingsWindow.language, "manualBindEmpty")
                    color: settingsWindow.warningColor
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 38
                        text: Strings.tr(settingsWindow.language, "reload")
                        onClicked: settingsWindow.appController.refreshBindableWindows()
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 38
                        text: Strings.tr(settingsWindow.language, "cancel")
                        onClicked: settingsWindow.appController.cancelBindWindow()
                    }

                    Button {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 38
                        enabled: settingsWindow.appController.selectedBindWindowIndex >= 0
                        text: Strings.tr(settingsWindow.language, "bindSelectedWindow")
                        onClicked: settingsWindow.appController.bindSelectedWindow()
                    }
                }
            }
        }
    }
}
