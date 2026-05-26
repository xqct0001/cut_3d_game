import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

RowLayout {
    objectName: "statusHeader"
    property var controller
    property var strings
    property var languageOptions: []
    property string language: "en"
    property color textColor: "#1E252B"
    property color mutedColor: "#65706A"
    property color greenColor: "#256B4D"

    Layout.fillWidth: true
    spacing: 12

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Label {
            text: "Comfort Cues"
            color: textColor
            font.pixelSize: 24
            font.bold: true
        }

        Label {
            Layout.fillWidth: true
            text: strings.tr(language, "subtitle")
            color: mutedColor
            font.pixelSize: 13
            elide: Text.ElideRight
        }
    }

    Rectangle {
        radius: 8
        color: controller.appEnabled ? "#E8F3EC" : "#ECEFEC"
        border.color: controller.appEnabled ? "#B9D7C4" : "#D2D8D2"
        border.width: 1
        implicitWidth: appPillLabel.implicitWidth + 18
        implicitHeight: 30

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
        implicitWidth: 120
        model: languageOptions
        textRole: language === "zh" ? "labelZh" : "labelEn"
        currentIndex: language === "zh" ? 1 : 0
        onActivated: controller.uiLanguage = languageOptions[currentIndex].value
    }
}
