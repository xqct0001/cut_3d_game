import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    id: settingsWindow
    objectName: "settingsWindow"
    width: 760
    height: 640
    minimumWidth: 720
    minimumHeight: 560
    visible: false
    title: "Comfort Cues"
    color: "#F6F7F4"

    readonly property color pageColor: "#F6F7F4"
    readonly property color panelColor: "#FFFFFF"
    readonly property color borderColor: "#D7DDD8"
    readonly property color textColor: "#1E252B"
    readonly property color mutedColor: "#65706A"
    readonly property color greenColor: "#256B4D"
    readonly property color blueColor: "#2F5E85"
    readonly property color warningColor: "#8A5B20"
    readonly property color lineColor: "#E4E8E2"

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
            subtitle: "Comfort overlay for windowed 3D games",
            readyTitle: "Ready",
            pausedTitle: "Paused",
            setupTitle: "Waiting for a game window",
            trackingTitle: "Tracking game window",
            unsupportedTitle: "Switch game to borderless/windowed",
            appOn: "On",
            appOff: "Off",
            overlayOn: "Overlay active",
            overlayIdle: "Overlay idle",
            enable: "Enable",
            disable: "Disable",
            bindWindow: "Bind current game",
            showDebug: "Show calibration",
            hideDebug: "Hide calibration",
            start: "Start",
            stepEnable: "Enable",
            stepGame: "Open game",
            stepBind: "Bind window",
            currentWindow: "Current window",
            mode: "Mode",
            executable: "Executable",
            noWindow: "No game window detected",
            exeNA: "Not available",
            profile: "Game profile",
            selectedProfile: "Selected profile",
            activeProfile: "Active profile",
            none: "None",
            reload: "Reload",
            save: "Save",
            comfort: "Comfort",
            cueStrength: "Cue strength",
            turnSensitivity: "Turn sensitivity",
            verticalSensitivity: "Vertical sensitivity",
            calmInput: "Input calm",
            advanced: "Advanced",
            showControls: "Show controls",
            mouse: "Mouse",
            gamepad: "Gamepad",
            safeMode: "Safe mode",
            style: "Cue style",
            visibility: "Visibility",
            fadeIn: "Fade in",
            fadeOut: "Fade out",
            simulator: "Simulator",
            enableSimulator: "Enable simulator",
            yaw: "Yaw",
            pitch: "Pitch",
            lateral: "Lateral",
            resetSimulator: "Reset simulator",
            borderless: "Borderless",
            windowed: "Windowed",
            unsupportedRatio: "Unsupported ratio",
            unsupportedFullscreen: "Unsupported fullscreen",
            simulatorMode: "Simulator",
            waiting: "Waiting",
            disabled: "Disabled",
            ready: "Ready.",
            runningBg: "Comfort Cues running in background.",
            disabledStatus: "Comfort Cues disabled.",
            savedProfilePrefix: "Saved profile to ",
            bindFailedNoWindow: "Bind failed: no foreground game window detected.",
            bindFailedPrefix: "Bind failed: ",
            boundGenericPrefix: "Bound current window to ",
            activePrefix: "Active: ",
            unsupportedRatioPrefix: "Unsupported ratio: ",
            unsupportedWindowPrefix: "Unsupported window: ",
            noMatchedProfilePrefix: "Window detected but no matched profile: ",
            simulatorPreviewPrefix: "Simulator preview - "
        }
        var zh = {
            language: "语言",
            subtitle: "面向窗口化 3D 游戏的舒适覆盖层",
            readyTitle: "已就绪",
            pausedTitle: "已暂停",
            setupTitle: "等待游戏窗口",
            trackingTitle: "正在跟踪游戏窗口",
            unsupportedTitle: "请切到无边框或窗口化",
            appOn: "开启",
            appOff: "关闭",
            overlayOn: "覆盖层运行中",
            overlayIdle: "覆盖层空闲",
            enable: "开启",
            disable: "关闭",
            bindWindow: "绑定当前游戏",
            showDebug: "显示校准",
            hideDebug: "隐藏校准",
            start: "开始",
            stepEnable: "开启",
            stepGame: "打开游戏",
            stepBind: "绑定窗口",
            currentWindow: "当前窗口",
            mode: "模式",
            executable: "程序",
            noWindow: "未检测到游戏窗口",
            exeNA: "不可用",
            profile: "游戏配置",
            selectedProfile: "选择配置",
            activeProfile: "生效配置",
            none: "无",
            reload: "刷新",
            save: "保存",
            comfort: "舒适度",
            cueStrength: "提示强度",
            turnSensitivity: "转向灵敏度",
            verticalSensitivity: "垂直灵敏度",
            calmInput: "输入稳定",
            advanced: "高级",
            showControls: "显示控件",
            mouse: "鼠标",
            gamepad: "手柄",
            safeMode: "安全模式",
            style: "提示样式",
            visibility: "可见度",
            fadeIn: "淡入",
            fadeOut: "淡出",
            simulator: "模拟器",
            enableSimulator: "启用模拟器",
            yaw: "水平",
            pitch: "垂直",
            lateral: "侧向",
            resetSimulator: "重置模拟器",
            borderless: "无边框",
            windowed: "窗口化",
            unsupportedRatio: "比例不支持",
            unsupportedFullscreen: "不支持独占全屏",
            simulatorMode: "模拟器",
            waiting: "等待",
            disabled: "已关闭",
            ready: "就绪。",
            runningBg: "Comfort Cues 正在后台运行。",
            disabledStatus: "Comfort Cues 已关闭。",
            savedProfilePrefix: "已保存配置到 ",
            bindFailedNoWindow: "绑定失败：未检测到前台游戏窗口。",
            bindFailedPrefix: "绑定失败：",
            boundGenericPrefix: "已将当前窗口绑定到 ",
            activePrefix: "当前：",
            unsupportedRatioPrefix: "比例不支持：",
            unsupportedWindowPrefix: "窗口不支持：",
            noMatchedProfilePrefix: "检测到窗口但没有匹配配置：",
            simulatorPreviewPrefix: "模拟器预览 - "
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
        if (text.indexOf("Bound current window to ") === 0) return tr("boundGenericPrefix") + text.substring("Bound current window to ".length)
        if (text.indexOf("Bind failed: ") === 0) return tr("bindFailedPrefix") + text.substring("Bind failed: ".length)
        if (text.indexOf("Active: ") === 0) return tr("activePrefix") + text.substring("Active: ".length)
        if (text.indexOf("Unsupported ratio: ") === 0) return tr("unsupportedRatioPrefix") + text.substring("Unsupported ratio: ".length)
        if (text.indexOf("Unsupported window: ") === 0) return tr("unsupportedWindowPrefix") + text.substring("Unsupported window: ".length)
        if (text.indexOf("Window detected but no matched profile: ") === 0) return tr("noMatchedProfilePrefix") + text.substring("Window detected but no matched profile: ".length)
        if (text.indexOf("Simulator preview - ") === 0) return tr("simulatorPreviewPrefix") + text.substring("Simulator preview - ".length)
        return text
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

    function sessionTitle() {
        if (!controller.appEnabled) return tr("pausedTitle")
        if (controller.activeWindowMode === "unsupported-ratio" || controller.activeWindowMode === "exclusive-or-unknown") {
            return tr("unsupportedTitle")
        }
        if (controller.overlayVisible) return tr("trackingTitle")
        if (controller.activeWindowTitle.length > 0) return tr("readyTitle")
        return tr("setupTitle")
    }

    function sessionColor() {
        if (!controller.appEnabled) return settingsWindow.mutedColor
        if (controller.activeWindowMode === "unsupported-ratio" || controller.activeWindowMode === "exclusive-or-unknown") {
            return settingsWindow.warningColor
        }
        if (controller.overlayVisible) return settingsWindow.greenColor
        return settingsWindow.blueColor
    }

    function windowSummary() {
        return controller.activeWindowTitle.length > 0 ? controller.activeWindowTitle : tr("noWindow")
    }

    function formatNumber(value) {
        return Number(value).toFixed(2)
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
        leftPadding: 20
        topPadding: 18
        rightPadding: 20
        bottomPadding: 20
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: settingsScrollView.availableWidth
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: "Comfort Cues"
                        color: settingsWindow.textColor
                        font.pixelSize: 24
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        text: settingsWindow.tr("subtitle")
                        color: settingsWindow.mutedColor
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    radius: 8
                    color: controller.appEnabled ? "#E8F3EC" : "#ECEFEC"
                    border.color: controller.appEnabled ? "#B9D7C4" : "#D2D8D2"
                    border.width: 1
                    implicitWidth: appPillLabel.implicitWidth + 18
                    implicitHeight: 30

                    Label {
                        id: appPillLabel
                        anchors.centerIn: parent
                        text: controller.appEnabled ? settingsWindow.tr("appOn") : settingsWindow.tr("appOff")
                        color: controller.appEnabled ? settingsWindow.greenColor : settingsWindow.mutedColor
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                ComboBox {
                    id: languageCombo
                    objectName: "languageCombo"
                    implicitWidth: 120
                    model: settingsWindow.languageOptions
                    textRole: currentLanguage() === "zh" ? "labelZh" : "labelEn"
                    currentIndex: currentLanguage() === "zh" ? 1 : 0
                    onActivated: controller.uiLanguage = settingsWindow.languageOptions[currentIndex].value
                }
            }

            Rectangle {
                objectName: "quickStartCard"
                Layout.fillWidth: true
                radius: 8
                color: settingsWindow.panelColor
                border.color: settingsWindow.borderColor
                border.width: 1
                implicitHeight: startLayout.implicitHeight + 32

                ColumnLayout {
                    id: startLayout
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
                            color: settingsWindow.sessionColor()
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Label {
                                text: settingsWindow.sessionTitle()
                                color: settingsWindow.textColor
                                font.pixelSize: 23
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

                        Button {
                            id: bindWindowButton
                            objectName: "bindWindowButton"
                            Layout.preferredWidth: 178
                            Layout.preferredHeight: 42
                            text: settingsWindow.tr("bindWindow")
                            onClicked: controller.bindCurrentWindow()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: settingsWindow.lineColor
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 16
                        rowSpacing: 8

                        Label {
                            text: "1  " + settingsWindow.tr("stepEnable")
                            color: controller.appEnabled ? settingsWindow.greenColor : settingsWindow.textColor
                            font.bold: true
                        }

                        Label {
                            text: "2  " + settingsWindow.tr("stepGame")
                            color: controller.activeWindowTitle.length > 0 ? settingsWindow.greenColor : settingsWindow.textColor
                            font.bold: true
                        }

                        Label {
                            text: "3  " + settingsWindow.tr("stepBind")
                            color: controller.activeProfileName.length > 0 || controller.overlayVisible ? settingsWindow.greenColor : settingsWindow.textColor
                            font.bold: true
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 18
                        rowSpacing: 8

                        Label { text: settingsWindow.tr("currentWindow"); color: settingsWindow.mutedColor; font.pixelSize: 12 }
                        Label {
                            objectName: "windowSummaryLabel"
                            Layout.fillWidth: true
                            text: settingsWindow.windowSummary()
                            color: settingsWindow.textColor
                            elide: Text.ElideRight
                        }

                        Label { text: settingsWindow.tr("mode"); color: settingsWindow.mutedColor; font.pixelSize: 12 }
                        Label {
                            Layout.fillWidth: true
                            text: settingsWindow.modeSummary(controller.activeWindowMode)
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
                color: settingsWindow.panelColor
                border.color: settingsWindow.borderColor
                border.width: 1
                implicitHeight: comfortLayout.implicitHeight + 32

                ColumnLayout {
                    id: comfortLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label {
                            text: settingsWindow.tr("comfort")
                            color: settingsWindow.textColor
                            font.pixelSize: 17
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: controller.overlayVisible ? settingsWindow.tr("overlayOn") : settingsWindow.tr("overlayIdle")
                            color: controller.overlayVisible ? settingsWindow.greenColor : settingsWindow.mutedColor
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 12
                        rowSpacing: 9

                        Label { text: settingsWindow.tr("cueStrength"); color: settingsWindow.textColor }
                        Slider {
                            Layout.fillWidth: true
                            from: 0.05
                            to: 0.5
                            value: controller.maxOpacity
                            onMoved: controller.maxOpacity = value
                        }
                        Label { text: settingsWindow.formatNumber(controller.maxOpacity); color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }

                        Label { text: settingsWindow.tr("turnSensitivity"); color: settingsWindow.textColor }
                        Slider {
                            Layout.fillWidth: true
                            from: 0.0
                            to: 2.0
                            value: controller.yawGain
                            onMoved: controller.yawGain = value
                        }
                        Label { text: settingsWindow.formatNumber(controller.yawGain); color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }

                        Label { text: settingsWindow.tr("verticalSensitivity"); color: settingsWindow.textColor }
                        Slider {
                            Layout.fillWidth: true
                            from: 0.0
                            to: 2.0
                            value: controller.pitchGain
                            onMoved: controller.pitchGain = value
                        }
                        Label { text: settingsWindow.formatNumber(controller.pitchGain); color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 8
                color: settingsWindow.panelColor
                border.color: settingsWindow.borderColor
                border.width: 1
                implicitHeight: profileLayout.implicitHeight + 28

                ColumnLayout {
                    id: profileLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

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
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 8
                color: settingsWindow.panelColor
                border.color: settingsWindow.borderColor
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

                            Label { text: settingsWindow.tr("calmInput"); color: settingsWindow.textColor }
                            Slider {
                                Layout.fillWidth: true
                                from: 0.0
                                to: 0.5
                                value: controller.deadzone
                                onMoved: controller.deadzone = value
                            }
                            Label { text: settingsWindow.formatNumber(controller.deadzone); color: settingsWindow.mutedColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }

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
                            color: settingsWindow.lineColor
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
