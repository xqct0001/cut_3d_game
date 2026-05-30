import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: advancedPanelRoot
    objectName: "advancedPanel"
    property var controller
    property var strings
    property string language: "en"
    property color panelColor: "#F7F8F4"
    property color borderColor: "#D7DED8"
    property color textColor: "#172023"
    property color mutedColor: "#6E828A"
    property color lineColor: "#DCE3DE"

    Layout.fillWidth: true
    radius: 12
    color: panelColor
    border.color: borderColor
    border.width: 1
    implicitHeight: advancedLayout.implicitHeight + 24

    ColumnLayout {
        id: advancedLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: strings.tr(language, "advanced")
                color: textColor
                font.pixelSize: 15
                font.bold: true
            }

            Label {
                Layout.fillWidth: true
                text: advancedPanelRoot.controller.advancedVisible ? "" : strings.tr(language, "showControls")
                color: mutedColor
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            CheckBox {
                id: advancedToggle
                objectName: "advancedToggle"
                text: ""
                checked: advancedPanelRoot.controller ? advancedPanelRoot.controller.advancedVisible : false
                onToggled: if (advancedPanelRoot.controller) advancedPanelRoot.controller.advancedVisible = checked
            }
        }

        Item {
            id: advancedDetails
            objectName: "advancedDetails"
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? advancedDetailsLayout.implicitHeight : 0
            visible: advancedPanelRoot.controller ? advancedPanelRoot.controller.advancedVisible : false

            ColumnLayout {
                id: advancedDetailsLayout
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    CheckBox { text: strings.tr(language, "mouse"); checked: advancedPanelRoot.controller.enableMouse; onToggled: advancedPanelRoot.controller.enableMouse = checked }
                    CheckBox { text: strings.tr(language, "gamepad"); checked: advancedPanelRoot.controller.enableGamepad; onToggled: advancedPanelRoot.controller.enableGamepad = checked }
                    CheckBox { text: strings.tr(language, "safeMode"); checked: advancedPanelRoot.controller.safeMode; onToggled: advancedPanelRoot.controller.safeMode = checked }
                    CheckBox { text: advancedPanelRoot.controller.debugOverlayEnabled ? strings.tr(language, "hideDebug") : strings.tr(language, "showDebug"); checked: advancedPanelRoot.controller.debugOverlayEnabled; onToggled: advancedPanelRoot.controller.debugOverlayEnabled = checked }
                    Item { Layout.fillWidth: true }
                }

                LabeledSlider {
                    label: strings.tr(language, "calmInput")
                    from: 0.0
                    to: 0.5
                    value: advancedPanelRoot.controller.deadzone
                    valueText: strings.formatNumber(advancedPanelRoot.controller.deadzone)
                    textColor: textColor
                    mutedColor: mutedColor
                    accentColor: "#238D65"
                    onMoved: advancedPanelRoot.controller.deadzone = value
                }

                LabeledSlider {
                    label: strings.tr(language, "fadeOut")
                    from: 10
                    to: 500
                    value: advancedPanelRoot.controller.fadeOutMs
                    valueText: Math.round(advancedPanelRoot.controller.fadeOutMs) + " ms"
                    textColor: textColor
                    mutedColor: mutedColor
                    accentColor: "#238D65"
                    onMoved: advancedPanelRoot.controller.fadeOutMs = value
                }

                SimulatorPanel {
                    controller: advancedPanelRoot.controller
                    strings: advancedPanelRoot.strings
                    language: advancedPanelRoot.language
                    textColor: advancedPanelRoot.textColor
                    mutedColor: advancedPanelRoot.mutedColor
                }
            }
        }
    }
}
