import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    objectName: "comfortControls"
    property var controller
    property var strings
    property string language: "en"
    property color panelColor: "#FFFFFF"
    property color borderColor: "#D7DDD8"
    property color textColor: "#1E252B"
    property color mutedColor: "#65706A"
    property color greenColor: "#256B4D"

    Layout.fillWidth: true
    radius: 8
    color: panelColor
    border.color: borderColor
    border.width: 1
    implicitHeight: comfortLayout.implicitHeight + 32

    ColumnLayout {
        id: comfortLayout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label { text: strings.tr(language, "comfort"); color: textColor; font.pixelSize: 17; font.bold: true }
            Item { Layout.fillWidth: true }
            Label {
                text: controller.overlayVisible ? strings.tr(language, "overlayOn") : strings.tr(language, "overlayIdle")
                color: controller.overlayVisible ? greenColor : mutedColor
                font.pixelSize: 12
                font.bold: true
            }
        }

        LabeledSlider {
            label: strings.tr(language, "cueStrength")
            from: 0.05
            to: 0.5
            value: controller.maxOpacity
            valueText: strings.formatNumber(controller.maxOpacity)
            textColor: textColor
            mutedColor: mutedColor
            onMoved: controller.maxOpacity = value
        }

        LabeledSlider {
            label: strings.tr(language, "turnSensitivity")
            from: 0.0
            to: 2.0
            value: controller.yawGain
            valueText: strings.formatNumber(controller.yawGain)
            textColor: textColor
            mutedColor: mutedColor
            onMoved: controller.yawGain = value
        }

        LabeledSlider {
            label: strings.tr(language, "verticalSensitivity")
            from: 0.0
            to: 2.0
            value: controller.pitchGain
            valueText: strings.formatNumber(controller.pitchGain)
            textColor: textColor
            mutedColor: mutedColor
            onMoved: controller.pitchGain = value
        }
    }
}
