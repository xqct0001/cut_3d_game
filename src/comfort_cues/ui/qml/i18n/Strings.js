.pragma library

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
    stepEnable: "Enable",
    stepGame: "Open game",
    stepBind: "Bind window",
    currentWindow: "Current window",
    mode: "Mode",
    executable: "Executable",
    noWindow: "No game window detected",
    exeNA: "Not available",
    profile: "Game profile",
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
    unsupportedTitle: "请切换到无边框或窗口化",
    appOn: "开启",
    appOff: "关闭",
    overlayOn: "覆盖层运行中",
    overlayIdle: "覆盖层待机",
    enable: "开启",
    disable: "关闭",
    bindWindow: "绑定当前游戏",
    showDebug: "显示校准",
    hideDebug: "隐藏校准",
    stepEnable: "开启",
    stepGame: "打开游戏",
    stepBind: "绑定窗口",
    currentWindow: "当前窗口",
    mode: "模式",
    executable: "程序",
    noWindow: "未检测到游戏窗口",
    exeNA: "不可用",
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
    if (!controller.appEnabled) return tr(language, "pausedTitle")
    if (controller.activeWindowMode === "unsupported-ratio" || controller.activeWindowMode === "exclusive-or-unknown") return tr(language, "unsupportedTitle")
    if (controller.overlayVisible) return tr(language, "trackingTitle")
    if (controller.activeWindowTitle.length > 0) return tr(language, "readyTitle")
    return tr(language, "setupTitle")
}

function sessionColorKey(controller) {
    if (!controller.appEnabled) return "muted"
    if (controller.activeWindowMode === "unsupported-ratio" || controller.activeWindowMode === "exclusive-or-unknown") return "warning"
    if (controller.overlayVisible) return "green"
    return "blue"
}

function windowSummary(language, controller) {
    return controller.activeWindowTitle.length > 0 ? controller.activeWindowTitle : tr(language, "noWindow")
}

function formatNumber(value) {
    return Number(value).toFixed(2)
}
