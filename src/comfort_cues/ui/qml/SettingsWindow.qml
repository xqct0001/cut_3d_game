import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    id: settingsWindow
    objectName: "settingsWindow"
    width: 720
    height: 760
    minimumWidth: 640
    minimumHeight: 620
    visible: false
    title: "Comfort Cues"
    color: "#F4F6F7"

    readonly property color pageColor: "#F4F6F7"
    readonly property color cardColor: "#FFFFFF"
    readonly property color borderColor: "#D9E0E5"
    readonly property color textColor: "#1F2A33"
    readonly property color mutedColor: "#5D6974"
    readonly property color subtleColor: "#F7F9FA"

    readonly property var languageOptions: [
        { labelEn: "English", labelZh: "English", value: "en" },
        { labelEn: "Chinese", labelZh: "中文", value: "zh" }
    ]

    function currentLanguage() {
        return controller.uiLanguage === "zh" ? "zh" : "en"
    }

    function tr(key, fallback) {
        var en = {
            language: "Language",
            status: "Status",
            compatibility: "Compatibility",
            quickStart: "Quick Start",
            profile: "Profile",
            advanced: "Advanced",
            enabled: "Enabled",
            disabled: "Disabled",
            overlayOn: "Overlay on",
            overlayIdle: "Overlay idle",
            enable: "Enable",
            disable: "Disable",
            bindWindow: "Bind Window",
            showDebug: "Show Debug",
            hideDebug: "Hide Debug",
            reload: "Reload",
            save: "Save",
            yaw: "Yaw",
            pitch: "Pitch",
            deadzone: "Deadzone",
            opacity: "Opacity",
            showControls: "Show controls",
            mouse: "Mouse",
            gamepad: "Gamepad",
            safeMode: "Safe mode",
            fadeIn: "Fade in",
            fadeOut: "Fade out",
            simulator: "Simulator",
            enableSimulator: "Enable simulator",
            lateral: "Lateral",
            resetSimulator: "Reset simulator",
            borderless: "Borderless",
            windowed: "Windowed",
            unsupportedRatio: "Unsupported ratio",
            unsupportedFullscreen: "Unsupported fullscreen",
            simulatorMode: "Simulator",
            waiting: "Waiting",
            appState: "App",
            overlayState: "Overlay",
            mode: "Mode",
            activeWindow: "Window",
            executable: "Executable",
            selectedProfile: "Selected profile",
            activeProfile: "Active profile",
            ratioOnly: "16:9 windowed or borderless",
            quickStep1: "Enable Comfort Cues.",
            quickStep2: "Open the game in windowed or borderless mode.",
            quickStep3: "Bind the current window.",
            openSupportedGame: "Open a supported game window.",
            enableAppHint: "Enable Comfort Cues to detect a game.",
            pausedHint: "Enable Comfort Cues first.",
            trackingHint: "Tracking the current window.",
            bindHint: "Window detected. Bind it to this profile.",
            fullscreenHint: "Use 16:9 windowed or borderless mode.",
            ready: "Ready.",
            runningBg: "Comfort Cues running in background.",
            disabledStatus: "Comfort Cues disabled.",
            savedProfilePrefix: "Saved profile to ",
            bindFailedNoWindow: "Bind failed: no foreground game window detected.",
            bindFailedPrefix: "Bind failed: ",
            boundPrefix: "Bound current window to CS2 profile: ",
            activePrefix: "Active: ",
            unsupportedRatioPrefix: "Unsupported ratio: ",
            unsupportedWindowPrefix: "Unsupported window: ",
            noMatchedProfilePrefix: "Window detected but no matched profile: ",
            simulatorPreviewPrefix: "Simulator preview - ",
            none: "None",
            exeNA: "exe n/a"
        }
        var zh = {
            language: "语言",
            status: "状态",
            compatibility: "兼容性",
            quickStart: "快速开始",
            profile: "Profile",
            advanced: "高级",
            enabled: "已开启",
            disabled: "已关闭",
            overlayOn: "覆盖层开启",
            overlayIdle: "覆盖层空闲",
            enable: "开启",
            disable: "关闭",
            bindWindow: "绑定窗口",
            showDebug: "显示调试",
            hideDebug: "隐藏调试",
            reload: "重新加载",
            save: "保存",
            yaw: "水平",
            pitch: "垂直",
            deadzone: "死区",
            opacity: "透明度",
            showControls: "显示控件",
            mouse: "鼠标",
            gamepad: "手柄",
            safeMode: "安全模式",
            fadeIn: "淡入",
            fadeOut: "淡出",
            simulator: "模拟器",
            enableSimulator: "启用模拟器",
            lateral: "侧向",
            resetSimulator: "重置模拟器",
            borderless: "无边框",
            windowed: "窗口化",
            unsupportedRatio: "比例不支持",
            unsupportedFullscreen: "不支持独占全屏",
            simulatorMode: "模拟器",
            waiting: "等待",
            appState: "应用",
            overlayState: "覆盖层",
            mode: "模式",
            activeWindow: "窗口",
            executable: "程序",
            selectedProfile: "当前 Profile",
            activeProfile: "生效 Profile",
            ratioOnly: "16:9 窗口化或无边框",
            quickStep1: "开启 Comfort Cues。",
            quickStep2: "用窗口化或无边框打开游戏。",
            quickStep3: "绑定当前窗口。",
            openSupportedGame: "打开受支持的游戏窗口。",
            enableAppHint: "先开启 Comfort Cues 以检测游戏。",
            pausedHint: "请先开启 Comfort Cues。",
            trackingHint: "正在跟踪当前窗口。",
            bindHint: "已检测到窗口，可绑定到此 Profile。",
            fullscreenHint: "使用 16:9 窗口化或无边框模式。",
            ready: "就绪。",
            runningBg: "Comfort Cues 正在后台运行。",
            disabledStatus: "Comfort Cues 已关闭。",
            savedProfilePrefix: "已保存 Profile 到 ",
            bindFailedNoWindow: "绑定失败：未检测到前台游戏窗口。",
            bindFailedPrefix: "绑定失败：",
            boundPrefix: "已将当前窗口绑定到 CS2 Profile：",
            activePrefix: "当前：",
            unsupportedRatioPrefix: "比例不支持：",
            unsupportedWindowPrefix: "窗口不支持：",
            noMatchedProfilePrefix: "检测到窗口但没有匹配 Profile：",
            simulatorPreviewPrefix: "模拟器预览 - ",
            none: "无",
            exeNA: "exe 不可用"
        }
        var table = currentLanguage() === "zh" ? zh : en
        return table[key] || fallback || key
    }

    function translateStatus(text) {
        if (text === "Ready.") return tr("ready")
        if (text === "Comfort Cues running in background.") return tr("runningBg")
        if (text === "Comfort Cues disabled.") return tr("disabledStatus")
        if (text === "Bind failed: no foreground game window detected.") return tr("bindFailedNoWindow")
        if (text.indexOf("Saved profile to ") === 0) return tr("savedProfilePrefix") + text.substring("Saved profile to ".length)
        if (text.indexOf("Bound current window to CS2 profile: ") === 0) return tr("boundPrefix") + text.substring("Bound current window to CS2 profile: ".length)
        if (text.indexOf("Bind failed: ") === 0) return tr("bindFailedPrefix") + text.substring("Bind failed: ".length)
        if (text.indexOf("Active: ") === 0) return tr("activePrefix") + text.substring("Active: ".length)
        if (text.indexOf("Unsupported ratio: ") === 0) return tr("unsupportedRatioPrefix") + text.substring("Unsupported ratio: ".length)
        if (text.indexOf("Unsupported window: ") === 0) return tr("unsupportedWindowPrefix") + text.substring("Unsupported window: ".length)
        if (text.indexOf("Window detected but no matched profile: ") === 0) return tr("noMatchedProfilePrefix") + text.substring("Window detected but no matched profile: ".length)
        if (text.indexOf("Simulator preview - ") === 0) return tr("simulatorPreviewPrefix") + text.substring("Simulator preview - ".length)
        return text
    }

    function formatNumber(value) {
        return Number(value).toFixed(2)
    }

    function modeSummary(mode) {
        if (mode === "borderless") return tr("borderless")
        if (mode === "windowed") return tr("windowed")
        if (mode === "unsupported-ratio") return tr("unsupportedRatio")
        if (mode === "exclusive-or-unknown") return tr("unsupportedFullscreen")
        if (mode === "simulator") return tr("simulatorMode")
        if (mode === "disabled") return tr("disabled")
        if (mode === "idle") return tr("waiting")
        return mode.length > 0 ? mode : tr("waiting")
    }

    function windowSummary() {
        if (controller.activeWindowTitle.length > 0) return controller.activeWindowTitle
        if (controller.appEnabled) return tr("openSupportedGame")
        return tr("enableAppHint")
    }

    function quickHint() {
        if (!controller.appEnabled) return tr("pausedHint")
        if (controller.activeWindowTitle.length > 0) {
            return controller.overlayVisible ? tr("trackingHint") : tr("bindHint")
        }
        return tr("fullscreenHint")
    }

    onClosing: {
        close.accepted = false
        settingsWindow.hide()
    }

    Rectangle {
        anchors.fill: parent
        color: settingsWindow.pageColor
    }

    ScrollView {
        id: settingsScrollView
        anchors.fill: parent
        clip: true
        leftPadding: 22
        topPadding: 20
        rightPadding: 22
        bottomPadding: 22
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: contentColumn
            width: settingsScrollView.availableWidth
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Label {
                        text: "Comfort Cues"
                        color: settingsWindow.textColor
                        font.pixelSize: 24
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        text: settingsWindow.translateStatus(controller.statusText)
                        color: settingsWindow.mutedColor
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }

                Label {
                    text: settingsWindow.tr("language")
                    color: settingsWindow.mutedColor
                    font.pixelSize: 12
                }

                ComboBox {
                    id: languageCombo
                    objectName: "languageCombo"
                    implicitWidth: 118
                    model: settingsWindow.languageOptions
                    textRole: currentLanguage() === "zh" ? "labelZh" : "labelEn"
                    currentIndex: currentLanguage() === "zh" ? 1 : 0
                    onActivated: controller.uiLanguage = settingsWindow.languageOptions[currentIndex].value
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: settingsWindow.width >= 700 ? 2 : 1
                columnSpacing: 14
                rowSpacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    radius: 8
                    color: settingsWindow.cardColor
                    border.color: settingsWindow.borderColor
                    border.width: 1
                    implicitHeight: statusLayout.implicitHeight + 32

                    ColumnLayout {
                        id: statusLayout
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Label {
                            text: settingsWindow.tr("status")
                            color: settingsWindow.textColor
                            font.pixelSize: 16
                            font.bold: true
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 10
                            rowSpacing: 8

                            Label { text: settingsWindow.tr("appState"); color: settingsWindow.mutedColor; font.pixelSize: 12 }
                            Label {
                                Layout.fillWidth: true
                                text: controller.appEnabled ? settingsWindow.tr("enabled") : settingsWindow.tr("disabled")
                                color: controller.appEnabled ? "#2E6A47" : "#6B747B"
                                font.bold: true
                            }

                            Label { text: settingsWindow.tr("overlayState"); color: settingsWindow.mutedColor; font.pixelSize: 12 }
                            Label {
                                Layout.fillWidth: true
                                text: controller.overlayVisible ? settingsWindow.tr("overlayOn") : settingsWindow.tr("overlayIdle")
                                color: controller.overlayVisible ? "#2B6383" : "#6B747B"
                                font.bold: true
                            }

                            Label { text: settingsWindow.tr("mode"); color: settingsWindow.mutedColor; font.pixelSize: 12 }
                            Label {
                                Layout.fillWidth: true
                                text: settingsWindow.modeSummary(controller.activeWindowMode)
                                color: settingsWindow.textColor
                                font.bold: true
                                elide: Text.ElideRight
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Button {
                                id: enableButton
                                objectName: "enableButton"
                                Layout.fillWidth: true
                                text: settingsWindow.tr("enable")
                                enabled: !controller.appEnabled
                                onClicked: controller.enableApp()
                            }

                            Button {
                                id: disableButton
                                objectName: "disableButton"
                                Layout.fillWidth: true
                                text: settingsWindow.tr("disable")
                                enabled: controller.appEnabled
                                onClicked: controller.disableApp()
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    radius: 8
                    color: settingsWindow.cardColor
                    border.color: settingsWindow.borderColor
                    border.width: 1
                    implicitHeight: compatibilityLayout.implicitHeight + 32

                    ColumnLayout {
                        id: compatibilityLayout
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        Label {
                            text: settingsWindow.tr("compatibility")
                            color: settingsWindow.textColor
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true
                            text: settingsWindow.tr("ratioOnly")
                            color: settingsWindow.mutedColor
                            font.pixelSize: 12
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 10
                            rowSpacing: 8

                            Label { text: settingsWindow.tr("activeWindow"); color: settingsWindow.mutedColor; font.pixelSize: 12 }
                            Label {
                                objectName: "windowSummaryLabel"
                                Layout.fillWidth: true
                                text: settingsWindow.windowSummary()
                                color: settingsWindow.textColor
                                elide: Text.ElideRight
                            }

                            Label { text: settingsWindow.tr("executable"); color: settingsWindow.mutedColor; font.pixelSize: 12 }
                            Label {
                                Layout.fillWidth: true
                                text: controller.activeExeName.length > 0 ? controller.activeExeName : settingsWindow.tr("exeNA")
                                color: settingsWindow.textColor
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Rectangle {
                objectName: "quickStartCard"
                Layout.fillWidth: true
                radius: 8
                color: settingsWindow.cardColor
                border.color: settingsWindow.borderColor
                border.width: 1
                implicitHeight: quickStartLayout.implicitHeight + 32

                ColumnLayout {
                    id: quickStartLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label {
                            text: settingsWindow.tr("quickStart")
                            color: settingsWindow.textColor
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: settingsWindow.quickHint()
                            color: settingsWindow.mutedColor
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: [settingsWindow.tr("quickStep1"), settingsWindow.tr("quickStep2"), settingsWindow.tr("quickStep3")]

                            Rectangle {
                                Layout.fillWidth: true
                                radius: 8
                                color: settingsWindow.subtleColor
                                border.color: "#E4EAEE"
                                border.width: 1
                                implicitHeight: 46

                                Label {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    text: modelData
                                    color: settingsWindow.textColor
                                    font.pixelSize: 13
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Button {
                            id: bindWindowButton
                            objectName: "bindWindowButton"
                            Layout.fillWidth: true
                            text: settingsWindow.tr("bindWindow")
                            onClicked: controller.bindCurrentWindow()
                        }

                        Button {
                            id: debugButton
                            objectName: "debugButton"
                            Layout.fillWidth: true
                            text: controller.debugOverlayEnabled ? settingsWindow.tr("hideDebug") : settingsWindow.tr("showDebug")
                            onClicked: controller.debugOverlayEnabled = !controller.debugOverlayEnabled
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 8
                color: settingsWindow.cardColor
                border.color: settingsWindow.borderColor
                border.width: 1
                implicitHeight: profileLayout.implicitHeight + 32

                ColumnLayout {
                    id: profileLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label {
                            text: settingsWindow.tr("profile")
                            color: settingsWindow.textColor
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true
                            text: controller.activeProfileName.length > 0
                                ? settingsWindow.tr("activeProfile") + ": " + controller.activeProfileName
                                : settingsWindow.tr("activeProfile") + ": " + settingsWindow.tr("none")
                            color: settingsWindow.mutedColor
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ComboBox {
                            Layout.fillWidth: true
                            model: controller.profileOptions
                            currentIndex: Math.max(0, controller.profileOptions.indexOf(controller.selectedProfileName))
                            onActivated: controller.selectedProfileName = currentText
                        }

                        Button {
                            id: reloadButton
                            objectName: "reloadButton"
                            text: settingsWindow.tr("reload")
                            onClicked: controller.reloadProfiles()
                        }

                        Button {
                            id: saveButton
                            objectName: "saveButton"
                            text: settingsWindow.tr("save")
                            onClicked: controller.saveSelectedProfile()
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 12
                        rowSpacing: 8

                        Label { text: settingsWindow.tr("yaw"); color: settingsWindow.textColor }
                        Slider {
                            Layout.fillWidth: true
                            from: 0.0
                            to: 2.0
                            value: controller.yawGain
                            onMoved: controller.yawGain = value
                        }
                        Label { text: settingsWindow.formatNumber(controller.yawGain); color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }

                        Label { text: settingsWindow.tr("pitch"); color: settingsWindow.textColor }
                        Slider {
                            Layout.fillWidth: true
                            from: 0.0
                            to: 2.0
                            value: controller.pitchGain
                            onMoved: controller.pitchGain = value
                        }
                        Label { text: settingsWindow.formatNumber(controller.pitchGain); color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }

                        Label { text: settingsWindow.tr("deadzone"); color: settingsWindow.textColor }
                        Slider {
                            Layout.fillWidth: true
                            from: 0.0
                            to: 0.5
                            value: controller.deadzone
                            onMoved: controller.deadzone = value
                        }
                        Label { text: settingsWindow.formatNumber(controller.deadzone); color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }

                        Label { text: settingsWindow.tr("opacity"); color: settingsWindow.textColor }
                        Slider {
                            Layout.fillWidth: true
                            from: 0.05
                            to: 0.5
                            value: controller.maxOpacity
                            onMoved: controller.maxOpacity = value
                        }
                        Label { text: settingsWindow.formatNumber(controller.maxOpacity); color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 8
                color: settingsWindow.cardColor
                border.color: settingsWindow.borderColor
                border.width: 1
                implicitHeight: advancedLayout.implicitHeight + 32

                ColumnLayout {
                    id: advancedLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: settingsWindow.tr("advanced")
                            color: settingsWindow.textColor
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        CheckBox {
                            id: advancedToggle
                            objectName: "advancedToggle"
                            text: settingsWindow.tr("showControls")
                            checked: controller.advancedVisible
                            onToggled: controller.advancedVisible = checked
                        }
                    }

                    ColumnLayout {
                        id: advancedDetails
                        objectName: "advancedDetails"
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? implicitHeight : 0
                        spacing: 12
                        visible: controller.advancedVisible

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            CheckBox {
                                text: settingsWindow.tr("mouse")
                                checked: controller.enableMouse
                                onToggled: controller.enableMouse = checked
                            }

                            CheckBox {
                                text: settingsWindow.tr("gamepad")
                                checked: controller.enableGamepad
                                onToggled: controller.enableGamepad = checked
                            }

                            CheckBox {
                                text: settingsWindow.tr("safeMode")
                                checked: controller.safeMode
                                onToggled: controller.safeMode = checked
                            }

                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ComboBox {
                                Layout.fillWidth: true
                                model: controller.cuePatternOptions
                                currentIndex: Math.max(0, controller.cuePatternOptions.indexOf(controller.cuePattern))
                                onActivated: controller.cuePattern = currentText
                            }

                            ComboBox {
                                Layout.fillWidth: true
                                model: controller.cueVisibilityOptions
                                currentIndex: Math.max(0, controller.cueVisibilityOptions.indexOf(controller.cueVisibility))
                                onActivated: controller.cueVisibility = currentText
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: 12
                            rowSpacing: 8

                            Label { text: settingsWindow.tr("fadeIn"); color: settingsWindow.textColor }
                            Slider {
                                Layout.fillWidth: true
                                from: 10
                                to: 300
                                value: controller.fadeInMs
                                onMoved: controller.fadeInMs = value
                            }
                            Label { text: Math.round(controller.fadeInMs) + " ms"; color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 58 }

                            Label { text: settingsWindow.tr("fadeOut"); color: settingsWindow.textColor }
                            Slider {
                                Layout.fillWidth: true
                                from: 10
                                to: 500
                                value: controller.fadeOutMs
                                onMoved: controller.fadeOutMs = value
                            }
                            Label { text: Math.round(controller.fadeOutMs) + " ms"; color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 58 }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: "#E7EDF1"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Label {
                                text: settingsWindow.tr("simulator")
                                color: settingsWindow.textColor
                                font.pixelSize: 14
                                font.bold: true
                            }

                            CheckBox {
                                text: settingsWindow.tr("enableSimulator")
                                checked: controller.simulatorEnabled
                                onToggled: controller.simulatorEnabled = checked
                            }

                            Item { Layout.fillWidth: true }

                            Button {
                                text: settingsWindow.tr("resetSimulator")
                                onClicked: controller.resetSimulator()
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: 12
                            rowSpacing: 8

                            Label { text: settingsWindow.tr("yaw"); color: settingsWindow.textColor }
                            Slider {
                                Layout.fillWidth: true
                                from: -1.0
                                to: 1.0
                                value: controller.simYaw
                                onMoved: controller.simYaw = value
                            }
                            Label { text: settingsWindow.formatNumber(controller.simYaw); color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }

                            Label { text: settingsWindow.tr("pitch"); color: settingsWindow.textColor }
                            Slider {
                                Layout.fillWidth: true
                                from: -1.0
                                to: 1.0
                                value: controller.simPitch
                                onMoved: controller.simPitch = value
                            }
                            Label { text: settingsWindow.formatNumber(controller.simPitch); color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }

                            Label { text: settingsWindow.tr("lateral"); color: settingsWindow.textColor }
                            Slider {
                                Layout.fillWidth: true
                                from: -1.0
                                to: 1.0
                                value: controller.simLateral
                                onMoved: controller.simLateral = value
                            }
                            Label { text: settingsWindow.formatNumber(controller.simLateral); color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }
                        }
                    }
                }
            }
        }
    }
}
