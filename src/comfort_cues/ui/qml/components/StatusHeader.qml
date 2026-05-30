import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

RowLayout {
    objectName: "statusHeader"
    property var controller
    property var strings
    property var languageOptions: []
    property string language: "en"
    property color textColor: "#F7F8F4"
    property color mutedColor: "#A9B8B8"
    property color greenColor: "#78D6A4"

    Layout.fillWidth: true
    spacing: 14

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 3

        Label {
            text: "Comfort Cues"
            color: textColor
            font.pixelSize: 30
            font.bold: true
        }

        Label {
            Layout.fillWidth: true
            text: strings.tr(language, "subtitle")
            color: mutedColor
            font.pixelSize: 14
            elide: Text.ElideRight
        }
    }

    Rectangle {
        radius: 15
        color: controller.appEnabled ? "#263A34" : "#33383A"
        border.color: controller.appEnabled ? "#78D6A4" : "#58666A"
        border.width: 1
        implicitWidth: appPillLabel.implicitWidth + 22
        implicitHeight: 32

        Label {
            id: appPillLabel
            anchors.centerIn: parent
            text: controller.appEnabled ? strings.tr(language, "appOn") : strings.tr(language, "appOff")
            color: controller.appEnabled ? greenColor : mutedColor
            font.pixelSize: 12
            font.bold: true
        }
    }

    ComboBox {
        id: languageCombo
        objectName: "languageCombo"
        implicitWidth: 118
        model: languageOptions
        textRole: language === "zh" ? "labelZh" : "labelEn"
        currentIndex: language === "zh" ? 1 : 0
        onActivated: controller.uiLanguage = languageOptions[currentIndex].value
    }
}
