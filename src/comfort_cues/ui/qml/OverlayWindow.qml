import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: overlayWindow
    objectName: "overlayWindow"
    visible: controller.overlayVisible
    color: "transparent"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    x: controller.overlayX
    y: controller.overlayY
    width: controller.overlayWidth
    height: controller.overlayHeight

    readonly property color cueColor: "#F6FBFF"
    readonly property color cueHaloColor: "#B9E6FF"
    readonly property bool dynamicPattern: controller.cuePattern === "dynamic"
    readonly property bool largerDots: controller.cueVisibility === "larger_dots" || controller.debugOverlayEnabled
    readonly property bool moreDots: controller.cueVisibility === "more_dots" || controller.debugOverlayEnabled
    readonly property real dotBaseSize: (largerDots ? 15 : 10) + controller.cueEnergy * (largerDots ? 5.5 : 3.5)
    readonly property real latticeStepX: dotBaseSize * (moreDots ? 1.75 : 2.05)
    readonly property real latticeStepY: latticeStepX * 0.78
    readonly property real cueTravel: Math.min(width, height) * (dynamicPattern ? 0.048 : 0.030)
    readonly property real ambientBaseAlpha: controller.debugOverlayEnabled ? 0.18 : 0.05
    readonly property real ambientBaseDensity: controller.debugOverlayEnabled ? 0.38 : 0.16
    readonly property real leftStrength: overlayWindow.strength(controller.leftAlpha)
    readonly property real rightStrength: overlayWindow.strength(controller.rightAlpha)
    readonly property real topStrength: overlayWindow.strength(controller.topAlpha)
    readonly property real bottomStrength: overlayWindow.strength(controller.bottomAlpha)
    readonly property real topBandDrive: overlayWindow.clamp01(Math.max(topStrength, Math.max(leftStrength, rightStrength) * 0.28, bottomStrength * 0.10))
    readonly property real leftBandDrive: overlayWindow.clamp01(Math.max(leftStrength, topStrength * 0.20, bottomStrength * 0.10))
    readonly property real rightBandDrive: overlayWindow.clamp01(Math.max(rightStrength, topStrength * 0.20, bottomStrength * 0.10))
    readonly property real topAmbientAlpha: overlayWindow.ambientAlpha(overlayWindow.topBandDrive, 0.72)
    readonly property real leftAmbientAlpha: overlayWindow.ambientAlpha(overlayWindow.leftBandDrive, 1.0)
    readonly property real rightAmbientAlpha: overlayWindow.ambientAlpha(overlayWindow.rightBandDrive, 1.0)
    readonly property real topAccentAlpha: overlayWindow.accentAlpha(overlayWindow.topBandDrive, 0.72)
    readonly property real leftAccentAlpha: overlayWindow.accentAlpha(overlayWindow.leftBandDrive, 1.0)
    readonly property real rightAccentAlpha: overlayWindow.accentAlpha(overlayWindow.rightBandDrive, 1.0)

    function currentLanguage() {
        return controller.uiLanguage === "zh" ? "zh" : "en"
    }

    function clamp01(value) {
        return Math.max(0.0, Math.min(1.0, value))
    }

    function strength(alpha) {
        return clamp01(alpha / Math.max(0.001, controller.maxOpacity))
    }

    function ambientAlpha(drive, emphasis) {
        return clamp01(ambientBaseAlpha * emphasis + drive * 0.08 * emphasis)
    }

    function ambientDensity(drive, density, emphasis) {
        return clamp01(ambientBaseDensity * emphasis + density * 0.08 + drive * 0.10)
    }

    function accentAlpha(drive, emphasis) {
        return clamp01(Math.pow(drive, 0.90) * (controller.debugOverlayEnabled ? 0.98 : 0.82) * emphasis)
    }

    function accentDensity(drive, density) {
        return clamp01(drive * 0.56 + density * 0.46)
    }

    function wave(seed, index) {
        return Math.sin(controller.flowPhase * 1.15 + seed + index * 0.31)
    }

    function edgeCount(span, step) {
        return Math.max(3, Math.floor(span / Math.max(6, step)))
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(18, height * 0.028)
        width: Math.min(parent.width * 0.44, 430)
        height: debugLabel.implicitHeight + 16
        radius: height / 2
        color: "#CC15212B"
        opacity: controller.debugOverlayEnabled && controller.overlayVisible ? 0.94 : 0.0

        Text {
            id: debugLabel
            anchors.centerIn: parent
            text: controller.activeProfileName.length > 0
                ? controller.activeProfileName + (currentLanguage() === "zh" ? " 校准中" : " calibration active")
                : (currentLanguage() === "zh" ? "调试 / 校准已开启" : "Debug / Calibration active")
            color: "#F5FBFF"
            font.pixelSize: 17
            font.bold: true
        }
    }

    Item {
        id: topBand
        x: overlayWindow.width * 0.22
        y: overlayWindow.height * 0.085
        width: overlayWindow.width * 0.56
        height: overlayWindow.height * 0.09
        visible: overlayWindow.topAmbientAlpha > 0.01 || overlayWindow.topAccentAlpha > 0.01

        readonly property int ambientCount: overlayWindow.edgeCount(width, overlayWindow.latticeStepX)
        readonly property int accentCount: ambientCount
        readonly property real ambientDensityValue: overlayWindow.ambientDensity(overlayWindow.topBandDrive, controller.topDensity, 0.84)
        readonly property real accentDensityValue: overlayWindow.accentDensity(overlayWindow.topBandDrive, controller.topDensity)

        Repeater {
            model: topBand.ambientCount

            delegate: Rectangle {
                width: overlayWindow.dotBaseSize * (0.72 + topBand.ambientDensityValue * 0.14)
                height: width
                radius: width / 2
                color: overlayWindow.cueHaloColor
                opacity: overlayWindow.topAmbientAlpha * (0.75 + (index % 3) * 0.08)
                x: index * (topBand.width - width) / Math.max(1, topBand.ambientCount - 1)
                   + overlayWindow.wave(0.20, index) * overlayWindow.cueTravel * 0.05
                   + controller.cueMotionX * overlayWindow.cueTravel * 0.05
                y: topBand.height * 0.50 - height / 2
                   + overlayWindow.wave(0.85, index) * overlayWindow.cueTravel * 0.03
            }
        }

        Repeater {
            model: topBand.accentCount

            delegate: Rectangle {
                width: overlayWindow.dotBaseSize * (0.88 + topBand.accentDensityValue * 0.20)
                height: width
                radius: width / 2
                color: overlayWindow.cueColor
                opacity: overlayWindow.topAccentAlpha * (0.70 + (index % 4) * 0.07)
                x: index * (topBand.width - width) / Math.max(1, topBand.accentCount - 1)
                   + overlayWindow.wave(1.20, index) * overlayWindow.cueTravel * 0.18
                   + controller.cueMotionX * overlayWindow.cueTravel * 0.28
                y: topBand.height * 0.50 - height / 2
                   + overlayWindow.wave(1.65, index) * overlayWindow.cueTravel * 0.08
                   + controller.cueMotionY * overlayWindow.cueTravel * 0.08
            }
        }
    }

    Item {
        id: leftBand
        x: overlayWindow.width * 0.025
        y: overlayWindow.height * 0.28
        width: overlayWindow.width * 0.16
        height: overlayWindow.height * 0.40
        visible: overlayWindow.leftAmbientAlpha > 0.01 || overlayWindow.leftAccentAlpha > 0.01

        readonly property int ambientCount: overlayWindow.edgeCount(height, overlayWindow.latticeStepY)
        readonly property int accentCount: ambientCount
        readonly property real ambientDensityValue: overlayWindow.ambientDensity(overlayWindow.leftBandDrive, controller.leftDensity, 1.0)
        readonly property real accentDensityValue: overlayWindow.accentDensity(overlayWindow.leftBandDrive, controller.leftDensity)

        Repeater {
            model: leftBand.ambientCount

            delegate: Rectangle {
                width: overlayWindow.dotBaseSize * (0.74 + leftBand.ambientDensityValue * 0.14)
                height: width
                radius: width / 2
                color: overlayWindow.cueHaloColor
                opacity: overlayWindow.leftAmbientAlpha * (0.76 + (index % 3) * 0.07)
                x: leftBand.width * 0.52 - width / 2
                   + overlayWindow.wave(0.35, index) * overlayWindow.cueTravel * 0.05
                y: index * (leftBand.height - height) / Math.max(1, leftBand.ambientCount - 1)
                   + overlayWindow.wave(1.10, index) * overlayWindow.cueTravel * 0.05
                   + controller.cueMotionY * overlayWindow.cueTravel * 0.05
            }
        }

        Repeater {
            model: leftBand.accentCount

            delegate: Rectangle {
                width: overlayWindow.dotBaseSize * (0.90 + leftBand.accentDensityValue * 0.24)
                height: width
                radius: width / 2
                color: overlayWindow.cueColor
                opacity: overlayWindow.leftAccentAlpha * (0.72 + (index % 4) * 0.06)
                x: leftBand.width * 0.52 - width / 2
                   + overlayWindow.wave(1.55, index) * overlayWindow.cueTravel * 0.14
                   + controller.cueMotionX * overlayWindow.cueTravel * 0.52
                y: index * (leftBand.height - height) / Math.max(1, leftBand.accentCount - 1)
                   + overlayWindow.wave(2.00, index) * overlayWindow.cueTravel * 0.16
                   + controller.cueMotionY * overlayWindow.cueTravel * 0.14
            }
        }
    }

    Item {
        id: rightBand
        x: overlayWindow.width * 0.815
        y: overlayWindow.height * 0.28
        width: overlayWindow.width * 0.16
        height: overlayWindow.height * 0.40
        visible: overlayWindow.rightAmbientAlpha > 0.01 || overlayWindow.rightAccentAlpha > 0.01

        readonly property int ambientCount: overlayWindow.edgeCount(height, overlayWindow.latticeStepY)
        readonly property int accentCount: ambientCount
        readonly property real ambientDensityValue: overlayWindow.ambientDensity(overlayWindow.rightBandDrive, controller.rightDensity, 1.0)
        readonly property real accentDensityValue: overlayWindow.accentDensity(overlayWindow.rightBandDrive, controller.rightDensity)

        Repeater {
            model: rightBand.ambientCount

            delegate: Rectangle {
                width: overlayWindow.dotBaseSize * (0.74 + rightBand.ambientDensityValue * 0.14)
                height: width
                radius: width / 2
                color: overlayWindow.cueHaloColor
                opacity: overlayWindow.rightAmbientAlpha * (0.76 + (index % 3) * 0.07)
                x: rightBand.width * 0.48 - width / 2
                   + overlayWindow.wave(0.65, index) * overlayWindow.cueTravel * 0.05
                y: index * (rightBand.height - height) / Math.max(1, rightBand.ambientCount - 1)
                   + overlayWindow.wave(1.45, index) * overlayWindow.cueTravel * 0.05
                   + controller.cueMotionY * overlayWindow.cueTravel * 0.05
            }
        }

        Repeater {
            model: rightBand.accentCount

            delegate: Rectangle {
                width: overlayWindow.dotBaseSize * (0.90 + rightBand.accentDensityValue * 0.24)
                height: width
                radius: width / 2
                color: overlayWindow.cueColor
                opacity: overlayWindow.rightAccentAlpha * (0.72 + (index % 4) * 0.06)
                x: rightBand.width * 0.48 - width / 2
                   + overlayWindow.wave(1.85, index) * overlayWindow.cueTravel * 0.14
                   + controller.cueMotionX * overlayWindow.cueTravel * 0.52
                y: index * (rightBand.height - height) / Math.max(1, rightBand.accentCount - 1)
                   + overlayWindow.wave(2.30, index) * overlayWindow.cueTravel * 0.16
                   + controller.cueMotionY * overlayWindow.cueTravel * 0.14
            }
        }
    }
}
