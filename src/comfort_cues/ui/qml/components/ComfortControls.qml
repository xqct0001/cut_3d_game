import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    objectName: "comfortControls"
    property var controller
    property var strings
    property string language: "en"
    property color panelColor: "#F7F8F4"
    property color borderColor: "#D7DED8"
    property color textColor: "#172023"
    property color mutedColor: "#6E828A"
    property color greenColor: "#238D65"

    Layout.fillWidth: true
    radius: 12
    color: panelColor
    border.color: borderColor
    border.width: 1
    implicitHeight: comfortLayout.implicitHeight + 30

    ColumnLayout {
        id: comfortLayout
        anchors.fill: parent
        anchors.margins: 15
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label { text: strings.tr(language, "comfort"); color: textColor; font.pixelSize: 18; font.bold: true }
            Item { Layout.fillWidth: true }
            Label {
                text: strings.tr(language, "supportedHint")
                color: mutedColor
                font.pixelSize: 12
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
            accentColor: greenColor
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
            accentColor: greenColor
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
            accentColor: greenColor
            onMoved: controller.pitchGain = value
        }
    }
}
