import QtQuick 2.15
import QtQuick.Window 2.15
import "components"

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
    readonly property real ambientBaseAlpha: controller.debugOverlayEnabled ? 0.18 : 0.032
    readonly property real ambientBaseDensity: controller.debugOverlayEnabled ? 0.38 : 0.12
    readonly property real leftStrength: strength(controller.leftAlpha)
    readonly property real rightStrength: strength(controller.rightAlpha)
    readonly property real topStrength: strength(controller.topAlpha)
    readonly property real bottomStrength: strength(controller.bottomAlpha)
    readonly property real topBandDrive: clamp01(Math.max(topStrength, Math.max(leftStrength, rightStrength) * 0.28, bottomStrength * 0.10))
    readonly property real leftBandDrive: clamp01(Math.max(leftStrength, topStrength * 0.20, bottomStrength * 0.10))
    readonly property real rightBandDrive: clamp01(Math.max(rightStrength, topStrength * 0.20, bottomStrength * 0.10))
    readonly property real topAmbientAlpha: ambientAlpha(topBandDrive, 0.72)
    readonly property real leftAmbientAlpha: ambientAlpha(leftBandDrive, 1.0)
    readonly property real rightAmbientAlpha: ambientAlpha(rightBandDrive, 1.0)
    readonly property real topAccentAlpha: accentAlpha(topBandDrive, 0.72)
    readonly property real leftAccentAlpha: accentAlpha(leftBandDrive, 1.0)
    readonly property real rightAccentAlpha: accentAlpha(rightBandDrive, 1.0)

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
        return clamp01(ambientBaseAlpha * emphasis + drive * 0.07 * emphasis)
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

    EdgeCueBand {
        objectName: "topCueBand"
        orientation: "horizontal"
        x: overlayWindow.width * 0.22
        y: overlayWindow.height * 0.085
        width: overlayWindow.width * 0.56
        height: overlayWindow.height * 0.09
        cueColor: overlayWindow.cueColor
        cueHaloColor: overlayWindow.cueHaloColor
        dotBaseSize: overlayWindow.dotBaseSize
        cueTravel: overlayWindow.cueTravel
        ambientAlpha: overlayWindow.topAmbientAlpha
        accentAlpha: overlayWindow.topAccentAlpha
        ambientDensity: overlayWindow.ambientDensity(overlayWindow.topBandDrive, controller.topDensity, 0.84)
        accentDensity: overlayWindow.accentDensity(overlayWindow.topBandDrive, controller.topDensity)
        flowPhase: controller.flowPhase
        motionX: controller.cueMotionX
        motionY: controller.cueMotionY
        seed: 0.2
        step: overlayWindow.latticeStepX
    }

    EdgeCueBand {
        objectName: "leftCueBand"
        orientation: "vertical"
        x: overlayWindow.width * 0.025
        y: overlayWindow.height * 0.28
        width: overlayWindow.width * 0.16
        height: overlayWindow.height * 0.40
        cueColor: overlayWindow.cueColor
        cueHaloColor: overlayWindow.cueHaloColor
        dotBaseSize: overlayWindow.dotBaseSize
        cueTravel: overlayWindow.cueTravel
        ambientAlpha: overlayWindow.leftAmbientAlpha
        accentAlpha: overlayWindow.leftAccentAlpha
        ambientDensity: overlayWindow.ambientDensity(overlayWindow.leftBandDrive, controller.leftDensity, 1.0)
        accentDensity: overlayWindow.accentDensity(overlayWindow.leftBandDrive, controller.leftDensity)
        flowPhase: controller.flowPhase
        motionX: controller.cueMotionX
        motionY: controller.cueMotionY
        seed: 0.35
        step: overlayWindow.latticeStepY
    }

    EdgeCueBand {
        objectName: "rightCueBand"
        orientation: "vertical"
        x: overlayWindow.width * 0.815
        y: overlayWindow.height * 0.28
        width: overlayWindow.width * 0.16
        height: overlayWindow.height * 0.40
        cueColor: overlayWindow.cueColor
        cueHaloColor: overlayWindow.cueHaloColor
        dotBaseSize: overlayWindow.dotBaseSize
        cueTravel: overlayWindow.cueTravel
        ambientAlpha: overlayWindow.rightAmbientAlpha
        accentAlpha: overlayWindow.rightAccentAlpha
        ambientDensity: overlayWindow.ambientDensity(overlayWindow.rightBandDrive, controller.rightDensity, 1.0)
        accentDensity: overlayWindow.accentDensity(overlayWindow.rightBandDrive, controller.rightDensity)
        flowPhase: controller.flowPhase
        motionX: controller.cueMotionX
        motionY: controller.cueMotionY
        seed: 0.65
        step: overlayWindow.latticeStepY
    }
}
