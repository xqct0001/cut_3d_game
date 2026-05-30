import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    objectName: "profilePanel"
    property var controller
    property var strings
    property string language: "en"
    property color panelColor: "#F7F8F4"
    property color borderColor: "#D7DED8"
    property color textColor: "#172023"
    property color mutedColor: "#6E828A"

    Layout.fillWidth: true
    radius: 12
    color: panelColor
    border.color: borderColor
    border.width: 1
    implicitHeight: profileLayout.implicitHeight + 24

    RowLayout {
        id: profileLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 9

        Label {
            text: strings.tr(language, "profile")
            color: textColor
            font.pixelSize: 15
            font.bold: true
        }

        ComboBox {
            Layout.fillWidth: true
            model: controller.profileOptions
            currentIndex: Math.max(0, controller.profileOptions.indexOf(controller.selectedProfileName))
            onActivated: controller.selectedProfileName = currentText
        }

        Button {
            id: reloadButton
            objectName: "reloadButton"
            text: strings.tr(language, "reload")
            onClicked: controller.reloadProfiles()
        }

        Button {
            id: saveButton
            objectName: "saveButton"
            text: strings.tr(language, "save")
            onClicked: controller.saveSelectedProfile()
        }
    }
}
