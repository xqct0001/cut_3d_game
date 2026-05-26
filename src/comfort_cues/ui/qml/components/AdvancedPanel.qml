import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: advancedPanelRoot
    objectName: "advancedPanel"
    property var controller
    property var strings
    property string language: "en"
    property color panelColor: "#FFFFFF"
    property color borderColor: "#D7DDD8"
    property color textColor: "#1E252B"
    property color mutedColor: "#65706A"
    property color lineColor: "#E4E8E2"

    Layout.fillWidth: true
    radius: 8
    color: panelColor
    border.color: borderColor
    border.width: 1
    implicitHeight: advancedLayout.implicitHeight + 28

    ColumnLayout {
        id: advancedLayout
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label { text: strings.tr(language, "advanced"); color: textColor; font.pixelSize: 16; font.bold: true }
            Item { Layout.fillWidth: true }
            CheckBox {
                id: advancedToggle
                objectName: "advancedToggle"
                text: strings.tr(language, "showControls")
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
                spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                CheckBox { text: strings.tr(language, "mouse"); checked: advancedPanelRoot.controller.enableMouse; onToggled: advancedPanelRoot.controller.enableMouse = checked }
                CheckBox { text: strings.tr(language, "gamepad"); checked: advancedPanelRoot.controller.enableGamepad; onToggled: advancedPanelRoot.controller.enableGamepad = checked }
                CheckBox { text: strings.tr(language, "safeMode"); checked: advancedPanelRoot.controller.safeMode; onToggled: advancedPanelRoot.controller.safeMode = checked }
                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ComboBox {
                    Layout.fillWidth: true
                    model: advancedPanelRoot.controller.cuePatternOptions
                    currentIndex: Math.max(0, advancedPanelRoot.controller.cuePatternOptions.indexOf(advancedPanelRoot.controller.cuePattern))
                    onActivated: advancedPanelRoot.controller.cuePattern = currentText
                }

                ComboBox {
                    Layout.fillWidth: true
                    model: advancedPanelRoot.controller.cueVisibilityOptions
                    currentIndex: Math.max(0, advancedPanelRoot.controller.cueVisibilityOptions.indexOf(advancedPanelRoot.controller.cueVisibility))
                    onActivated: advancedPanelRoot.controller.cueVisibility = currentText
                }
            }

            LabeledSlider {
                label: strings.tr(language, "calmInput")
                from: 0.0
                to: 0.5
                value: advancedPanelRoot.controller.deadzone
                valueText: strings.formatNumber(advancedPanelRoot.controller.deadzone)
                textColor: textColor
                mutedColor: mutedColor
                onMoved: advancedPanelRoot.controller.deadzone = value
            }

            LabeledSlider {
                label: strings.tr(language, "fadeIn")
                from: 10
                to: 300
                value: advancedPanelRoot.controller.fadeInMs
                valueText: Math.round(advancedPanelRoot.controller.fadeInMs) + " ms"
                textColor: textColor
                mutedColor: mutedColor
                onMoved: advancedPanelRoot.controller.fadeInMs = value
            }

            LabeledSlider {
                label: strings.tr(language, "fadeOut")
                from: 10
                to: 500
                value: advancedPanelRoot.controller.fadeOutMs
                valueText: Math.round(advancedPanelRoot.controller.fadeOutMs) + " ms"
                textColor: textColor
                mutedColor: mutedColor
                onMoved: advancedPanelRoot.controller.fadeOutMs = value
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: lineColor }

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
