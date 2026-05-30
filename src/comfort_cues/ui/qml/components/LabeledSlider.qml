import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

RowLayout {
    property string label: ""
    property real from: 0.0
    property real to: 1.0
    property real value: 0.0
    property string valueText: ""
    property color textColor: "#172023"
    property color mutedColor: "#6E828A"
    property color accentColor: "#238D65"
    signal moved(real value)

    Layout.fillWidth: true
    spacing: 12

    Label {
        text: label
        color: textColor
        font.pixelSize: 13
        Layout.preferredWidth: 118
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        from: parent.from
        to: parent.to
        value: parent.value
        onMoved: parent.moved(value)
        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 4
            radius: 2
            color: "#D8E1DC"

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: accentColor
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 16
            height: 16
            radius: 8
            color: "#F7F8F4"
            border.color: accentColor
            border.width: 2
        }
    }

    Label {
        text: valueText
        color: mutedColor
        font.pixelSize: 12
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: 54
    }
}
