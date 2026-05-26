import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

RowLayout {
    property string label: ""
    property string value: ""
    property string valueObjectName: ""
    property color labelColor: "#65706A"
    property color valueColor: "#1E252B"

    Layout.fillWidth: true
    spacing: 12

    Label {
        text: label
        color: labelColor
        font.pixelSize: 12
        Layout.preferredWidth: 120
    }

    Label {
        objectName: valueObjectName
        Layout.fillWidth: true
        text: value
        color: valueColor
        elide: Text.ElideRight
    }
}
