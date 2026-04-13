import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    id: settingsWindow
    objectName: "settingsWindow"
    width: 460
    height: 470
    minimumWidth: 460
    maximumWidth: 460
    minimumHeight: 470
    maximumHeight: 470
    visible: false
    title: "Comfort Cues"
    color: "#F3F6F8"

    readonly property var languageOptions: [
        { labelEn: "English", labelZh: "English", value: "en" },
        { labelEn: "中文", labelZh: "中文", value: "zh" }
    ]

    function currentLanguage() {
        return controller.uiLanguage === "zh" ? "zh" : "en"
    }

    function tr(key, fallback) {
        var en = {
            language: "Language",
            ratioOnly: "16:9 only",
            enabled: "Enabled",
            disabled: "Disabled",
            overlayOn: "Overlay On",
            overlayIdle: "Overlay Idle",
            enable: "Enable",
            disable: "Disable",
            quickStart: "Quick Start",
            bindWindow: "Bind Window",
            showDebug: "Show Debug",
            hideDebug: "Hide Debug",
            profileTuning: "Profile and Tuning",
            profileHint: "Pick a profile, then keep the four quick controls light and readable during play.",
            reload: "Reload",
            save: "Save",
            yaw: "Yaw",
            pitch: "Pitch",
            deadzone: "Deadzone",
            opacity: "Opacity",
            advanced: "Advanced",
            showControls: "Show controls",
            advancedHint: "Keep this collapsed during normal play. Expand only when adjusting input sources, patterns, fade timing, or simulator preview.",
            mouse: "Mouse",
            gamepad: "Gamepad",
            safeMode: "Safe Mode",
            fadeIn: "Fade In",
            fadeOut: "Fade Out",
            simulator: "Simulator",
            enableSimulator: "Enable simulator",
            lateral: "Lateral",
            resetSimulator: "Reset Simulator",
            borderless: "Borderless",
            windowed: "Windowed",
            unsupportedRatio: "Unsupported Ratio",
            unsupportedFullscreen: "Unsupported Fullscreen",
            simulatorMode: "Simulator",
            waiting: "Waiting",
            openSupportedGame: "Open a supported windowed or borderless game, then bind it here.",
            enableAppHint: "Enable Comfort Cues to start detecting a game window.",
            pausedHint: "Comfort Cues is paused. Enable it first, then bind the current game window.",
            trackingHint: "Cue overlay is tracking the current window.",
            bindHint: "Window detected. Use Bind Window to save this match to the selected profile.",
            fullscreenHint: "Best with 16:9 windowed or borderless games. Exclusive fullscreen is not supported.",
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
            exeNA: "exe n/a"
        }
        var zh = {
            language: "语言",
            ratioOnly: "仅限 16:9",
            enabled: "已开启",
            disabled: "已关闭",
            overlayOn: "覆盖层开启",
            overlayIdle: "覆盖层空闲",
            enable: "开启",
            disable: "关闭",
            quickStart: "快速开始",
            bindWindow: "绑定窗口",
            showDebug: "显示调试",
            hideDebug: "隐藏调试",
            profileTuning: "配置与调节",
            profileHint: "先选择配置，再把四个常用控制保持轻量，避免游戏中阅读负担。",
            reload: "重新加载",
            save: "保存",
            yaw: "水平",
            pitch: "垂直",
            deadzone: "死区",
            opacity: "透明度",
            advanced: "高级",
            showControls: "显示控件",
            advancedHint: "平时游戏保持折叠。只在调整输入源、样式、淡入淡出或模拟器预览时展开。",
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
            waiting: "等待中",
            openSupportedGame: "打开支持的窗口化或无边框游戏，然后在这里绑定。",
            enableAppHint: "先开启 Comfort Cues，才能开始检测游戏窗口。",
            pausedHint: "Comfort Cues 当前已暂停。请先开启，再绑定当前游戏窗口。",
            trackingHint: "提示覆盖层正在跟踪当前窗口。",
            bindHint: "已检测到窗口。使用“绑定窗口”把这次匹配保存到当前配置。",
            fullscreenHint: "最佳体验是 16:9 窗口化或无边框游戏。不支持独占全屏。",
            ready: "就绪。",
            runningBg: "Comfort Cues 正在后台运行。",
            disabledStatus: "Comfort Cues 已关闭。",
            savedProfilePrefix: "已保存配置到 ",
            bindFailedNoWindow: "绑定失败：未检测到前台游戏窗口。",
            bindFailedPrefix: "绑定失败：",
            boundPrefix: "已将当前窗口绑定到 CS2 配置：",
            activePrefix: "当前激活：",
            unsupportedRatioPrefix: "比例不支持：",
            unsupportedWindowPrefix: "窗口不支持：",
            noMatchedProfilePrefix: "检测到窗口但没有匹配配置：",
            simulatorPreviewPrefix: "模拟器预览 - ",
            exeNA: "无 exe"
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
        if (mode === "borderless") {
            return tr("borderless")
        }
        if (mode === "windowed") {
            return tr("windowed")
        }
        if (mode === "unsupported-ratio") {
            return tr("unsupportedRatio")
        }
        if (mode === "exclusive-or-unknown") {
            return tr("unsupportedFullscreen")
        }
        if (mode === "simulator") {
            return tr("simulatorMode")
        }
        if (mode === "disabled") {
            return tr("disabled")
        }
        if (mode === "idle") {
            return tr("waiting")
        }
        return mode.length > 0 ? mode : tr("waiting")
    }

    function windowSummary() {
        if (controller.activeWindowTitle.length > 0) {
            return controller.activeWindowTitle
        }
        if (controller.appEnabled) {
            return tr("openSupportedGame")
        }
        return tr("enableAppHint")
    }

    function quickHint() {
        if (!controller.appEnabled) {
            return tr("pausedHint")
        }
        if (controller.activeWindowTitle.length > 0) {
            return controller.overlayVisible
                ? tr("trackingHint")
                : tr("bindHint")
        }
        return tr("fullscreenHint")
    }

    onClosing: {
        close.accepted = false
        settingsWindow.hide()
    }

    Rectangle {
        anchors.fill: parent
        color: "#F3F6F8"
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Item {
            width: settingsWindow.width
            implicitHeight: contentColumn.implicitHeight + 32

            ColumnLayout {
                id: contentColumn
                x: 16
                y: 16
                width: parent.width - 32
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    radius: 12
                    color: "#FFFFFF"
                    border.color: "#D8E0E6"
                    border.width: 1
                    implicitHeight: headerLayout.implicitHeight + 28

                    ColumnLayout {
                        id: headerLayout
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: "Comfort Cues"
                                color: "#1F2A33"
                                font.pixelSize: 21
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Label {
                                text: settingsWindow.tr("language")
                                color: "#51606D"
                                font.pixelSize: 12
                            }

                            ComboBox {
                                id: languageCombo
                                objectName: "languageCombo"
                                implicitWidth: 92
                                model: settingsWindow.languageOptions
                                textRole: currentLanguage() === "zh" ? "labelZh" : "labelEn"
                                currentIndex: currentLanguage() === "zh" ? 1 : 0
                                onActivated: controller.uiLanguage = settingsWindow.languageOptions[currentIndex].value
                            }

                            Rectangle {
                                radius: 9
                                color: "#EEF3F6"
                                border.color: "#D8E0E6"
                                border.width: 1
                                implicitWidth: ratioBadgeLabel.implicitWidth + 16
                                implicitHeight: ratioBadgeLabel.implicitHeight + 8

                                Label {
                                    id: ratioBadgeLabel
                                    anchors.centerIn: parent
                                    text: settingsWindow.tr("ratioOnly")
                                    color: "#51606D"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }

                        Label {
                            objectName: "statusSummaryLabel"
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: settingsWindow.translateStatus(controller.statusText)
                            color: "#51606D"
                            font.pixelSize: 13
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                radius: 9
                                color: controller.appEnabled ? "#E8F6EE" : "#EEF2F5"
                                border.color: controller.appEnabled ? "#B7DEC6" : "#D5DEE5"
                                border.width: 1
                                implicitWidth: appStateLabel.implicitWidth + 16
                                implicitHeight: appStateLabel.implicitHeight + 8

                                Label {
                                    id: appStateLabel
                                    anchors.centerIn: parent
                                    text: controller.appEnabled ? settingsWindow.tr("enabled") : settingsWindow.tr("disabled")
                                    color: controller.appEnabled ? "#2E6A47" : "#61707C"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                radius: 9
                                color: controller.overlayVisible ? "#EAF5FB" : "#F2F5F7"
                                border.color: controller.overlayVisible ? "#BED8E8" : "#D8E0E6"
                                border.width: 1
                                implicitWidth: overlayStateLabel.implicitWidth + 16
                                implicitHeight: overlayStateLabel.implicitHeight + 8

                                Label {
                                    id: overlayStateLabel
                                    anchors.centerIn: parent
                                    text: controller.overlayVisible ? settingsWindow.tr("overlayOn") : settingsWindow.tr("overlayIdle")
                                    color: "#466274"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                radius: 9
                                color: "#F6F8FA"
                                border.color: "#D8E0E6"
                                border.width: 1
                                implicitWidth: windowModeLabel.implicitWidth + 16
                                implicitHeight: windowModeLabel.implicitHeight + 8

                                Label {
                                    id: windowModeLabel
                                    anchors.centerIn: parent
                                    text: settingsWindow.modeSummary(controller.activeWindowMode)
                                    color: "#5A6773"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
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
                    objectName: "quickStartCard"
                    Layout.fillWidth: true
                    radius: 12
                    color: "#FFFFFF"
                    border.color: "#D8E0E6"
                    border.width: 1
                    implicitHeight: quickStartLayout.implicitHeight + 28

                    ColumnLayout {
                        id: quickStartLayout
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Label {
                            text: settingsWindow.tr("quickStart")
                            color: "#1F2A33"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Label {
                            objectName: "windowSummaryLabel"
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: settingsWindow.windowSummary()
                            color: "#384550"
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: settingsWindow.quickHint()
                            color: "#62717E"
                            font.pixelSize: 12
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                radius: 9
                                color: "#F6F8FA"
                                border.color: "#D8E0E6"
                                border.width: 1
                                implicitWidth: exeLabel.implicitWidth + 16
                                implicitHeight: exeLabel.implicitHeight + 8

                                Label {
                                    id: exeLabel
                                    anchors.centerIn: parent
                                    text: controller.activeExeName.length > 0 ? controller.activeExeName : settingsWindow.tr("exeNA")
                                    color: "#596773"
                                    font.pixelSize: 12
                                }
                            }

                            Rectangle {
                                radius: 9
                                color: "#F6F8FA"
                                border.color: "#D8E0E6"
                                border.width: 1
                                implicitWidth: profileChipLabel.implicitWidth + 16
                                implicitHeight: profileChipLabel.implicitHeight + 8

                                Label {
                                    id: profileChipLabel
                                    anchors.centerIn: parent
                                    text: controller.activeProfileName.length > 0
                                        ? controller.activeProfileName
                                        : controller.selectedProfileName
                                    color: "#596773"
                                    font.pixelSize: 12
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
                    radius: 12
                    color: "#FFFFFF"
                    border.color: "#D8E0E6"
                    border.width: 1
                    implicitHeight: profileLayout.implicitHeight + 28

                    ColumnLayout {
                        id: profileLayout
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Label {
                            text: settingsWindow.tr("profileTuning")
                            color: "#1F2A33"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: settingsWindow.tr("profileHint")
                            color: "#62717E"
                            font.pixelSize: 12
                        }

                        ComboBox {
                            Layout.fillWidth: true
                            model: controller.profileOptions
                            currentIndex: Math.max(0, controller.profileOptions.indexOf(controller.selectedProfileName))
                            onActivated: controller.selectedProfileName = currentText
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Button {
                                id: reloadButton
                                objectName: "reloadButton"
                                Layout.fillWidth: true
                                text: settingsWindow.tr("reload")
                                onClicked: controller.reloadProfiles()
                            }

                            Button {
                                id: saveButton
                                objectName: "saveButton"
                                Layout.fillWidth: true
                                text: settingsWindow.tr("save")
                                onClicked: controller.saveSelectedProfile()
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: 8
                            rowSpacing: 6

                            Label { text: settingsWindow.tr("yaw"); color: "#384550" }
                            Slider {
                                Layout.fillWidth: true
                                from: 0.0
                                to: 2.0
                                value: controller.yawGain
                                onMoved: controller.yawGain = value
                            }
                            Label { text: settingsWindow.formatNumber(controller.yawGain); color: "#62717E" }

                            Label { text: settingsWindow.tr("pitch"); color: "#384550" }
                            Slider {
                                Layout.fillWidth: true
                                from: 0.0
                                to: 2.0
                                value: controller.pitchGain
                                onMoved: controller.pitchGain = value
                            }
                            Label { text: settingsWindow.formatNumber(controller.pitchGain); color: "#62717E" }

                            Label { text: settingsWindow.tr("deadzone"); color: "#384550" }
                            Slider {
                                Layout.fillWidth: true
                                from: 0.0
                                to: 0.5
                                value: controller.deadzone
                                onMoved: controller.deadzone = value
                            }
                            Label { text: settingsWindow.formatNumber(controller.deadzone); color: "#62717E" }

                            Label { text: settingsWindow.tr("opacity"); color: "#384550" }
                            Slider {
                                Layout.fillWidth: true
                                from: 0.05
                                to: 0.5
                                value: controller.maxOpacity
                                onMoved: controller.maxOpacity = value
                            }
                            Label { text: settingsWindow.formatNumber(controller.maxOpacity); color: "#62717E" }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 12
                    color: "#FFFFFF"
                    border.color: "#D8E0E6"
                    border.width: 1
                    implicitHeight: advancedLayout.implicitHeight + 28

                    ColumnLayout {
                        id: advancedLayout
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: settingsWindow.tr("advanced")
                                color: "#1F2A33"
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            CheckBox {
                                id: advancedToggle
                                objectName: "advancedToggle"
                                text: settingsWindow.tr("showControls")
                                checked: controller.advancedVisible
                                onToggled: controller.advancedVisible = checked
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: settingsWindow.tr("advancedHint")
                            color: "#62717E"
                            font.pixelSize: 12
                        }

                        ColumnLayout {
                            id: advancedDetails
                            objectName: "advancedDetails"
                            Layout.fillWidth: true
                            Layout.preferredHeight: visible ? implicitHeight : 0
                            spacing: 8
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
                                columnSpacing: 8
                                rowSpacing: 6

                                Label { text: settingsWindow.tr("fadeIn"); color: "#384550" }
                                Slider {
                                    Layout.fillWidth: true
                                    from: 10
                                    to: 300
                                    value: controller.fadeInMs
                                    onMoved: controller.fadeInMs = value
                                }
                                Label { text: Math.round(controller.fadeInMs) + " ms"; color: "#62717E" }

                                Label { text: settingsWindow.tr("fadeOut"); color: "#384550" }
                                Slider {
                                    Layout.fillWidth: true
                                    from: 10
                                    to: 500
                                    value: controller.fadeOutMs
                                    onMoved: controller.fadeOutMs = value
                                }
                                Label { text: Math.round(controller.fadeOutMs) + " ms"; color: "#62717E" }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: "#E7EDF1"
                            }

                            Label {
                                text: settingsWindow.tr("simulator")
                                color: "#1F2A33"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            CheckBox {
                                text: settingsWindow.tr("enableSimulator")
                                checked: controller.simulatorEnabled
                                onToggled: controller.simulatorEnabled = checked
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 3
                                columnSpacing: 8
                                rowSpacing: 6

                                Label { text: settingsWindow.tr("yaw"); color: "#384550" }
                                Slider {
                                    Layout.fillWidth: true
                                    from: -1.0
                                    to: 1.0
                                    value: controller.simYaw
                                    onMoved: controller.simYaw = value
                                }
                                Label { text: settingsWindow.formatNumber(controller.simYaw); color: "#62717E" }

                                Label { text: settingsWindow.tr("pitch"); color: "#384550" }
                                Slider {
                                    Layout.fillWidth: true
                                    from: -1.0
                                    to: 1.0
                                    value: controller.simPitch
                                    onMoved: controller.simPitch = value
                                }
                                Label { text: settingsWindow.formatNumber(controller.simPitch); color: "#62717E" }

                                Label { text: settingsWindow.tr("lateral"); color: "#384550" }
                                Slider {
                                    Layout.fillWidth: true
                                    from: -1.0
                                    to: 1.0
                                    value: controller.simLateral
                                    onMoved: controller.simLateral = value
                                }
                                Label { text: settingsWindow.formatNumber(controller.simLateral); color: "#62717E" }
                            }

                            Button {
                                text: settingsWindow.tr("resetSimulator")
                                onClicked: controller.resetSimulator()
                            }
                        }
                    }
                }
            }
        }
    }
}
