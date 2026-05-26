import QtQuick 2.15

Item {
    property string orientation: "vertical"
    property color cueColor: "#F6FBFF"
    property color cueHaloColor: "#B9E6FF"
    property real dotBaseSize: 10
    property real cueTravel: 10
    property real ambientAlpha: 0
    property real accentAlpha: 0
    property real ambientDensity: 0
    property real accentDensity: 0
    property real flowPhase: 0
    property real motionX: 0
    property real motionY: 0
    property real seed: 0
    property real step: 18

    visible: ambientAlpha > 0.01 || accentAlpha > 0.01

    function bandCount() {
        var span = orientation === "horizontal" ? width : height
        return Math.max(3, Math.floor(span / Math.max(6, step)))
    }

    function wave(offset, index) {
        return Math.sin(flowPhase * 1.15 + seed + offset + index * 0.31)
    }

    Repeater {
        model: bandCount()

        delegate: Rectangle {
            width: dotBaseSize * (0.74 + ambientDensity * 0.14)
            height: width
            radius: width / 2
            color: cueHaloColor
            opacity: ambientAlpha * (0.76 + (index % 3) * 0.07)
            x: orientation === "horizontal"
                ? index * (parent.width - width) / Math.max(1, bandCount() - 1) + wave(0.20, index) * cueTravel * 0.05 + motionX * cueTravel * 0.05
                : parent.width * 0.50 - width / 2 + wave(0.35, index) * cueTravel * 0.05
            y: orientation === "horizontal"
                ? parent.height * 0.50 - height / 2 + wave(0.85, index) * cueTravel * 0.03
                : index * (parent.height - height) / Math.max(1, bandCount() - 1) + wave(1.10, index) * cueTravel * 0.05 + motionY * cueTravel * 0.05
        }
    }

    Repeater {
        model: bandCount()

        delegate: Rectangle {
            width: dotBaseSize * (0.90 + accentDensity * 0.24)
            height: width
            radius: width / 2
            color: cueColor
            opacity: accentAlpha * (0.72 + (index % 4) * 0.06)
            x: orientation === "horizontal"
                ? index * (parent.width - width) / Math.max(1, bandCount() - 1) + wave(1.20, index) * cueTravel * 0.18 + motionX * cueTravel * 0.28
                : parent.width * 0.50 - width / 2 + wave(1.55, index) * cueTravel * 0.14 + motionX * cueTravel * 0.52
            y: orientation === "horizontal"
                ? parent.height * 0.50 - height / 2 + wave(1.65, index) * cueTravel * 0.08 + motionY * cueTravel * 0.08
                : index * (parent.height - height) / Math.max(1, bandCount() - 1) + wave(2.00, index) * cueTravel * 0.16 + motionY * cueTravel * 0.14
        }
    }
}
