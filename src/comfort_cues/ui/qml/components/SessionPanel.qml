import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    objectName: "sessionPanel"
    property var controller
    property var strings
    property string language: "en"
    property color panelColor: "#FFFFFF"
    property color borderColor: "#D7DDD8"
    property color textColor: "#1E252B"
    property color mutedColor: "#65706A"
    property color greenColor: "#256B4D"
    property color blueColor: "#2F5E85"
    property color warningColor: "#8A5B20"
    property color lineColor: "#E4E8E2"

    function sessionColor() {
        var key = strings.sessionColorKey(controller)
        if (key === "warning") return warningColor
        if (key === "green") return greenColor
        if (key === "blue") return blueColor
        return mutedColor
    }

    Layout.fillWidth: true
    radius: 8
    color: panelColor
    border.color: borderColor
    border.width: 1
    implicitHeight: startLayout.implicitHeight + 32

    ColumnLayout {
        id: startLayout
        objectName: "quickStartCard"
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 8
                Layout.fillHeight: true
                radius: 4
                color: sessionColor()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Label {
                    text: strings.sessionTitle(language, controller)
                    color: textColor
                    font.pixelSize: 23
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    text: strings.translateStatus(language, controller.statusText)
                    color: mutedColor
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }

            Button {
                id: bindWindowButton
                objectName: "bindWindowButton"
                Layout.preferredWidth: 178
                Layout.preferredHeight: 42
                text: strings.tr(language, "bindWindow")
                onClicked: controller.bindCurrentWindow()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: lineColor
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 16
            rowSpacing: 8

            Label { text: "1  " + strings.tr(language, "stepEnable"); color: controller.appEnabled ? greenColor : textColor; font.bold: true }
            Label { text: "2  " + strings.tr(language, "stepGame"); color: controller.activeWindowTitle.length > 0 ? greenColor : textColor; font.bold: true }
            Label { text: "3  " + strings.tr(language, "stepBind"); color: controller.activeProfileName.length > 0 || controller.overlayVisible ? greenColor : textColor; font.bold: true }
        }

        MetricRow {
            label: strings.tr(language, "currentWindow")
            value: strings.windowSummary(language, controller)
            valueObjectName: "windowSummaryLabel"
            labelColor: mutedColor
            valueColor: textColor
        }

        MetricRow {
            label: strings.tr(language, "mode")
            value: strings.modeSummary(language, controller.activeWindowMode)
            labelColor: mutedColor
            valueColor: textColor
        }

        MetricRow {
            label: strings.tr(language, "executable")
            value: controller.activeExeName.length > 0 ? controller.activeExeName : strings.tr(language, "exeNA")
            labelColor: mutedColor
            valueColor: textColor
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                id: enableButton
                objectName: "enableButton"
                Layout.fillWidth: true
                text: strings.tr(language, "enable")
                enabled: !controller.appEnabled
                onClicked: controller.enableApp()
            }

            Button {
                id: disableButton
                objectName: "disableButton"
                Layout.fillWidth: true
                text: strings.tr(language, "disable")
                enabled: controller.appEnabled
                onClicked: controller.disableApp()
            }

            Button {
                id: debugButton
                objectName: "debugButton"
                Layout.fillWidth: true
                text: controller.debugOverlayEnabled ? strings.tr(language, "hideDebug") : strings.tr(language, "showDebug")
                onClicked: controller.debugOverlayEnabled = !controller.debugOverlayEnabled
            }
        }
    }
}
