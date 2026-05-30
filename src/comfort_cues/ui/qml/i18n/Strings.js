.pragma library

var en = {
    language: "Language",
    subtitle: "Comfort overlay for windowed 3D games",
    waitingTitle: "No game detected",
    trackingTitle: "Game detected",
    unsupportedTitle: "Unsupported window",
    pausedTitle: "Overlay paused",
    scanningTitle: "Detecting game",
    appOn: "On",
    appOff: "Off",
    overlayOn: "Overlay active",
    overlayIdle: "Overlay idle",
    enable: "Enable overlay",
    disable: "Disable overlay",
    bindWindow: "Detect game",
    cancel: "Cancel",
    showDebug: "Show preview",
    hideDebug: "Hide preview",
    currentWindow: "Current game",
    executable: "Executable",
    noWindow: "--",
    exeNA: "--",
    scanHint: "The window will hide. Switch back to your game within 5 seconds.",
    scanDialogTitle: "Detecting game",
    scanDialogBody: "Switch to the game window. Comfort Cues will bind it automatically.",
    scanStepHide: "Hide window",
    scanStepFocus: "Wait for game foreground",
    scanStepBind: "Bind profile",
    supportedHint: "Supports 16:9 windowed / borderless games",
    profile: "Profile",
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
    showControls: "Advanced settings",
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
    unsupportedFullscreen: "Fullscreen not supported",
    simulatorMode: "Simulator",
    waiting: "Waiting",
    disabled: "Disabled",
    ready: "Ready.",
    runningBg: "Comfort Cues running in background.",
    disabledStatus: "Comfort Cues disabled.",
    savedProfilePrefix: "Saved profile to ",
    bindFailedNoWindow: "Bind failed: no foreground game window detected.",
    bindFailedPrefix: "Bind failed: ",
    bindingPrefix: "Binding: ",
    boundGenericPrefix: "Bound current window to ",
    activePrefix: "Active: ",
    unsupportedRatioPrefix: "Unsupported ratio: ",
    unsupportedWindowPrefix: "Unsupported window: ",
    noMatchedProfilePrefix: "Window detected but no matched profile: ",
    simulatorPreviewPrefix: "Simulator preview - "
}

var zh = {
    language: "语言",
    subtitle: "游戏舒适度覆盖层",
    waitingTitle: "未识别游戏",
    trackingTitle: "已识别游戏",
    unsupportedTitle: "窗口不支持",
    pausedTitle: "覆盖层已关闭",
    scanningTitle: "正在识别游戏",
    appOn: "已开启",
    appOff: "已关闭",
    overlayOn: "覆盖层运行中",
    overlayIdle: "覆盖层待机",
    enable: "开启覆盖层",
    disable: "关闭覆盖层",
    bindWindow: "识别游戏",
    cancel: "取消",
    showDebug: "显示预览",
    hideDebug: "隐藏预览",
    currentWindow: "当前游戏",
    executable: "程序",
    noWindow: "--",
    exeNA: "--",
    scanHint: "点击后窗口会自动隐藏，请在 5 秒内切回游戏。",
    scanDialogTitle: "正在识别游戏",
    scanDialogBody: "请切回游戏窗口，Comfort Cues 会自动绑定。",
    scanStepHide: "隐藏窗口",
    scanStepFocus: "等待游戏前台",
    scanStepBind: "绑定配置",
    supportedHint: "支持窗口化 / 无边框 16:9 游戏",
    profile: "游戏配置",
    activeProfile: "生效配置",
    none: "无",
    reload: "刷新",
    save: "保存",
    comfort: "舒适度",
    cueStrength: "提示强度",
    turnSensitivity: "转向灵敏度",
    verticalSensitivity: "垂直灵敏度",
    calmInput: "输入稳定",
    advanced: "高级设置",
    showControls: "展开高级设置",
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
    unsupportedFullscreen: "独占全屏不支持",
    simulatorMode: "模拟器",
    waiting: "等待中",
    disabled: "已关闭",
    ready: "就绪。",
    runningBg: "Comfort Cues 正在后台运行。",
    disabledStatus: "Comfort Cues 已关闭。",
    savedProfilePrefix: "已保存配置到 ",
    bindFailedNoWindow: "识别失败：没有检测到前台游戏窗口。",
    bindFailedPrefix: "识别失败：",
    bindingPrefix: "正在识别：",
    boundGenericPrefix: "已绑定到 ",
    activePrefix: "当前：",
    unsupportedRatioPrefix: "比例不支持：",
    unsupportedWindowPrefix: "窗口不支持：",
    noMatchedProfilePrefix: "检测到窗口但没有匹配配置：",
    simulatorPreviewPrefix: "模拟器预览 - "
}

function table(language) {
    return language === "zh" ? zh : en
}

function tr(language, key, fallback) {
    var values = table(language)
    return values[key] || fallback || key
}

function translateStatus(language, text) {
    if (text === "Ready.") return tr(language, "ready")
    if (text === "Comfort Cues running in background.") return tr(language, "runningBg")
    if (text === "Comfort Cues disabled.") return tr(language, "disabledStatus")
    if (text === "Bind failed: no foreground game window detected.") return tr(language, "bindFailedNoWindow")
    if (text.indexOf("Binding: ") === 0) return tr(language, "bindingPrefix") + text.substring("Binding: ".length)
    if (text.indexOf("Saved profile to ") === 0) return tr(language, "savedProfilePrefix") + text.substring("Saved profile to ".length)
    if (text.indexOf("Bound current window to ") === 0) return tr(language, "boundGenericPrefix") + text.substring("Bound current window to ".length)
    if (text.indexOf("Bind failed: ") === 0) return tr(language, "bindFailedPrefix") + text.substring("Bind failed: ".length)
    if (text.indexOf("Active: ") === 0) return tr(language, "activePrefix") + text.substring("Active: ".length)
    if (text.indexOf("Unsupported ratio: ") === 0) return tr(language, "unsupportedRatioPrefix") + text.substring("Unsupported ratio: ".length)
    if (text.indexOf("Unsupported window: ") === 0) return tr(language, "unsupportedWindowPrefix") + text.substring("Unsupported window: ".length)
    if (text.indexOf("Window detected but no matched profile: ") === 0) return tr(language, "noMatchedProfilePrefix") + text.substring("Window detected but no matched profile: ".length)
    if (text.indexOf("Simulator preview - ") === 0) return tr(language, "simulatorPreviewPrefix") + text.substring("Simulator preview - ".length)
    return text
}

function modeSummary(language, mode) {
    if (mode === "borderless") return tr(language, "borderless")
    if (mode === "windowed") return tr(language, "windowed")
    if (mode === "unsupported-ratio") return tr(language, "unsupportedRatio")
    if (mode === "exclusive-or-unknown") return tr(language, "unsupportedFullscreen")
    if (mode === "simulator") return tr(language, "simulatorMode")
    if (mode === "disabled") return tr(language, "disabled")
    if (mode === "idle") return tr(language, "waiting")
    return mode && mode.length > 0 ? mode : tr(language, "waiting")
}

function sessionTitle(language, controller) {
    if (controller.bindInProgress) return tr(language, "scanningTitle")
    if (!controller.appEnabled) return tr(language, "pausedTitle")
    if (controller.activeWindowMode === "unsupported-ratio" || controller.activeWindowMode === "exclusive-or-unknown") return tr(language, "unsupportedTitle")
    if (controller.activeWindowTitle.length > 0 || controller.overlayVisible) return tr(language, "trackingTitle")
    return tr(language, "waitingTitle")
}

function sessionColorKey(controller) {
    if (controller.bindInProgress) return "blue"
    if (!controller.appEnabled) return "muted"
    if (controller.activeWindowMode === "unsupported-ratio" || controller.activeWindowMode === "exclusive-or-unknown") return "warning"
    if (controller.activeWindowTitle.length > 0 || controller.overlayVisible) return "green"
    return "muted"
}

function windowSummary(language, controller) {
    return controller.activeWindowTitle.length > 0 ? controller.activeWindowTitle : tr(language, "noWindow")
}

function formatNumber(value) {
    return Number(value).toFixed(2)
}
