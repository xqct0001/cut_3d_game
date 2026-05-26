import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    objectName: "simulatorPanel"
    property var controller
    property var strings
    property string language: "en"
    property color textColor: "#1E252B"
    property color mutedColor: "#65706A"

    Layout.fillWidth: true
    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Label { text: strings.tr(language, "simulator"); color: textColor; font.pixelSize: 14; font.bold: true }
        CheckBox {
            text: strings.tr(language, "enableSimulator")
            checked: controller.simulatorEnabled
            onToggled: controller.simulatorEnabled = checked
        }
        Item { Layout.fillWidth: true }
        Button {
            text: strings.tr(language, "resetSimulator")
            onClicked: controller.resetSimulator()
        }
    }

    LabeledSlider {
        label: strings.tr(language, "yaw")
        from: -1.0
        to: 1.0
        value: controller.simYaw
        valueText: strings.formatNumber(controller.simYaw)
        textColor: textColor
        mutedColor: mutedColor
        onMoved: controller.simYaw = value
    }

    LabeledSlider {
        label: strings.tr(language, "pitch")
        from: -1.0
        to: 1.0
        value: controller.simPitch
        valueText: strings.formatNumber(controller.simPitch)
        textColor: textColor
        mutedColor: mutedColor
        onMoved: controller.simPitch = value
    }

    LabeledSlider {
        label: strings.tr(language, "lateral")
        from: -1.0
        to: 1.0
        value: controller.simLateral
        valueText: strings.formatNumber(controller.simLateral)
        textColor: textColor
        mutedColor: mutedColor
        onMoved: controller.simLateral = value
    }
}
