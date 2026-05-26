import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

RowLayout {
    property string label: ""
    property real from: 0.0
    property real to: 1.0
    property real value: 0.0
    property string valueText: ""
    property color textColor: "#1E252B"
    property color mutedColor: "#65706A"
    signal moved(real value)

    Layout.fillWidth: true
    spacing: 12

    Label {
        text: label
        color: textColor
        Layout.preferredWidth: 130
    }

    Slider {
        Layout.fillWidth: true
        from: parent.from
        to: parent.to
        value: parent.value
        onMoved: parent.moved(value)
    }

    Label {
        text: valueText
        color: mutedColor
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: 58
    }
}
