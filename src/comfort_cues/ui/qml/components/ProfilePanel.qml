import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    objectName: "profilePanel"
    property var controller
    property var strings
    property string language: "en"
    property color panelColor: "#FFFFFF"
    property color borderColor: "#D7DDD8"
    property color textColor: "#1E252B"
    property color mutedColor: "#65706A"

    Layout.fillWidth: true
    radius: 8
    color: panelColor
    border.color: borderColor
    border.width: 1
    implicitHeight: profileLayout.implicitHeight + 28

    ColumnLayout {
        id: profileLayout
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label { text: strings.tr(language, "profile"); color: textColor; font.pixelSize: 16; font.bold: true }
            Label {
                Layout.fillWidth: true
                text: controller.activeProfileName.length > 0
                    ? strings.tr(language, "activeProfile") + ": " + controller.activeProfileName
                    : strings.tr(language, "activeProfile") + ": " + strings.tr(language, "none")
                color: mutedColor
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

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
}
