import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    objectName: "sessionPanel"
    property var controller
    property var strings
    property string language: "en"
    property color panelColor: "#F7F8F4"
    property color borderColor: "#D7DED8"
    property color textColor: "#172023"
    property color mutedColor: "#6E828A"
    property color greenColor: "#238D65"
    property color blueColor: "#286B78"
    property color warningColor: "#A66E18"
    property color lineColor: "#DCE3DE"

    function sessionColor() {
        var key = strings.sessionColorKey(controller)
        if (key === "warning") return warningColor
        if (key === "green") return greenColor
        if (key === "blue") return blueColor
        return mutedColor
    }

    Layout.fillWidth: true
    radius: 12
    color: panelColor
    border.color: borderColor
    border.width: 1
    implicitHeight: startLayout.implicitHeight + 34

    ColumnLayout {
        id: startLayout
        objectName: "quickStartCard"
        anchors.fill: parent
        anchors.margins: 17
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 11
                        Layout.preferredHeight: 11
                        radius: 6
                        color: sessionColor()
                    }

                    Label {
                        text: strings.sessionTitle(language, controller)
                        color: textColor
                        font.pixelSize: 26
                        font.bold: true
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: strings.translateStatus(language, controller.statusText)
                    color: mutedColor
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.preferredWidth: 190
                Layout.preferredHeight: 92
                radius: 10
                color: "#E8F2EC"
                border.color: "#C8DAD1"
                border.width: 1

                Canvas {
                    id: cuePreviewCanvas
                    anchors.fill: parent
                    anchors.margins: 14
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = "#9BB2AC"
                        ctx.lineWidth = 1
                        ctx.strokeRect(8, 8, width - 16, height - 16)
                        ctx.fillStyle = controller.overlayVisible ? "#42B883" : "#8EA2AA"
                        for (var y = 14; y < height - 12; y += 12) {
                            ctx.beginPath(); ctx.arc(10, y, 2.4, 0, Math.PI * 2); ctx.fill()
                            ctx.beginPath(); ctx.arc(width - 10, y, 2.4, 0, Math.PI * 2); ctx.fill()
                        }
                    }
                    Connections {
                        target: controller
                        function onCueChanged() { cuePreviewCanvas.requestPaint() }
                        function onStateChanged() { cuePreviewCanvas.requestPaint() }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: lineColor }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 18
            rowSpacing: 8

            MetricRow {
                label: strings.tr(language, "currentWindow")
                value: strings.windowSummary(language, controller)
                valueObjectName: "windowSummaryLabel"
                labelColor: mutedColor
                valueColor: textColor
            }

            MetricRow {
                label: strings.tr(language, "executable")
                value: controller.activeExeName.length > 0 ? controller.activeExeName : strings.tr(language, "exeNA")
                labelColor: mutedColor
                valueColor: textColor
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                id: bindWindowButton
                objectName: "bindWindowButton"
                Layout.preferredWidth: 190
                Layout.preferredHeight: 44
                text: strings.tr(language, "bindWindow")
                enabled: !controller.bindInProgress
                onClicked: controller.bindCurrentWindow()
                contentItem: Label {
                    text: bindWindowButton.text
                    color: "#F7F8F4"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                background: Rectangle {
                    radius: 8
                    color: bindWindowButton.enabled ? "#238D65" : "#8EA2AA"
                }
            }

            Button {
                id: disableButton
                objectName: "disableButton"
                Layout.preferredWidth: 130
                Layout.preferredHeight: 44
                text: controller.appEnabled ? strings.tr(language, "disable") : strings.tr(language, "enable")
                onClicked: controller.appEnabled ? controller.disableApp() : controller.enableApp()
                contentItem: Label {
                    text: disableButton.text
                    color: "#172023"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                background: Rectangle {
                    radius: 8
                    color: "#E6ECE7"
                    border.color: "#C8DAD1"
                    border.width: 1
                }
            }

            Label {
                Layout.fillWidth: true
                text: strings.tr(language, "scanHint")
                color: mutedColor
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Button {
                id: enableButton
                objectName: "enableButton"
                visible: false
                text: strings.tr(language, "enable")
                onClicked: controller.enableApp()
            }

            Button {
                id: debugButton
                objectName: "debugButton"
                visible: false
                text: controller.debugOverlayEnabled ? strings.tr(language, "hideDebug") : strings.tr(language, "showDebug")
                onClicked: controller.debugOverlayEnabled = !controller.debugOverlayEnabled
            }
        }
    }
}
