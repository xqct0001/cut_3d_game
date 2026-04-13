#include "window_tracker.h"

#include <QDir>

#ifdef Q_OS_WIN
#include <dwmapi.h>
#include <windows.h>
#endif

namespace {

#ifdef Q_OS_WIN
static constexpr int kDwmwaCloaked = 14;
static constexpr DWORD kMonitorDefaultToNearest = 2;
static constexpr UINT kSwShowMinimized = 2;
static constexpr int kGwlStyle = -16;
static constexpr long kWsCaption = 0x00C00000L;
static constexpr long kWsPopup = 0x80000000L;
static constexpr DWORD kProcessQueryLimitedInformation = 0x1000;
#endif

static constexpr double kMinSupportedAspect = 1.74;
static constexpr double kMaxSupportedAspect = 1.82;

#ifdef Q_OS_WIN
Rect rectFromWin32(const RECT &rect)
{
    return Rect{rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top};
}

QString windowText(HWND hwnd)
{
    wchar_t buffer[512] = {0};
    GetWindowTextW(hwnd, buffer, 512);
    return QString::fromWCharArray(buffer);
}

QString className(HWND hwnd)
{
    wchar_t buffer[256] = {0};
    GetClassNameW(hwnd, buffer, 256);
    return QString::fromWCharArray(buffer);
}

Rect windowRect(HWND hwnd)
{
    RECT rect{};
    GetWindowRect(hwnd, &rect);
    return rectFromWin32(rect);
}

Rect clientRect(HWND hwnd)
{
    RECT rect{};
    POINT topLeft{};
    POINT bottomRight{};
    if (!GetClientRect(hwnd, &rect)) {
        return Rect{};
    }
    topLeft.x = rect.left;
    topLeft.y = rect.top;
    bottomRight.x = rect.right;
    bottomRight.y = rect.bottom;
    if (!ClientToScreen(hwnd, &topLeft) || !ClientToScreen(hwnd, &bottomRight)) {
        return Rect{};
    }
    return Rect{topLeft.x, topLeft.y, qMax(0L, bottomRight.x - topLeft.x), qMax(0L, bottomRight.y - topLeft.y)};
}

Rect monitorRect(HWND hwnd)
{
    MONITORINFO info{};
    info.cbSize = sizeof(info);
    GetMonitorInfoW(MonitorFromWindow(hwnd, kMonitorDefaultToNearest), &info);
    return rectFromWin32(info.rcMonitor);
}

bool isCloaked(HWND hwnd)
{
    DWORD cloaked = 0;
    return DwmGetWindowAttribute(hwnd, kDwmwaCloaked, &cloaked, sizeof(cloaked)) == S_OK && cloaked != 0;
}

bool isMinimized(HWND hwnd)
{
    WINDOWPLACEMENT placement{};
    placement.length = sizeof(placement);
    GetWindowPlacement(hwnd, &placement);
    return placement.showCmd == kSwShowMinimized;
}

QString processPath(DWORD pid)
{
    HANDLE handle = OpenProcess(kProcessQueryLimitedInformation, FALSE, pid);
    if (handle == nullptr) {
        return QString();
    }

    wchar_t buffer[512] = {0};
    DWORD size = 512;
    const BOOL ok = QueryFullProcessImageNameW(handle, 0, buffer, &size);
    CloseHandle(handle);
    if (!ok) {
        return QString();
    }
    return QDir::fromNativeSeparators(QString::fromWCharArray(buffer));
}
#endif

} // namespace

std::tuple<QString, bool, QString> classifyWindowMode(const Rect &rect, const Rect &monitorRectValue, long style)
{
    const bool coversMonitor = rect.x <= monitorRectValue.x
        && rect.y <= monitorRectValue.y
        && rect.right() >= monitorRectValue.right()
        && rect.bottom() >= monitorRectValue.bottom();

    if (rect.isEmpty()) {
        return {"unsupported", false, "empty window bounds"};
    }
    if (rect.width < 320 || rect.height < 240) {
        return {"unsupported", false, "window too small"};
    }
    if (coversMonitor && (style & kWsPopup) && !(style & kWsCaption)) {
        return {"borderless", true, "borderless window supported"};
    }
    if (coversMonitor) {
        return {"exclusive-or-unknown", false, "fullscreen mode not supported"};
    }
    return {"windowed", true, "windowed mode supported"};
}

bool isSupportedAspectRatio(const Rect &rect)
{
    if (rect.isEmpty() || rect.height <= 0) {
        return false;
    }
    const double aspect = static_cast<double>(rect.width) / static_cast<double>(rect.height);
    return aspect >= kMinSupportedAspect && aspect <= kMaxSupportedAspect;
}

ForegroundWindowTracker::ForegroundWindowTracker()
{
#ifdef Q_OS_WIN
    m_ownPid = GetCurrentProcessId();
#endif
}

std::optional<WindowInfo> ForegroundWindowTracker::snapshot() const
{
#ifndef Q_OS_WIN
    return std::nullopt;
#else
    HWND hwnd = GetForegroundWindow();
    DWORD pid = 0;
    const QString cls = className(hwnd);
    const Rect frameRect = windowRect(hwnd);
    const Rect client = clientRect(hwnd);
    const Rect effectiveRect = client.isEmpty() ? frameRect : client;
    const Rect monitor = monitorRect(hwnd);
    const long style = static_cast<long>(GetWindowLongPtrW(hwnd, kGwlStyle));
    const auto [mode, supportedBase, reasonBase] = classifyWindowMode(frameRect, monitor, style);
    bool supported = supportedBase;
    QString reason = reasonBase;
    QString finalMode = mode;

    if (hwnd == nullptr || !IsWindowVisible(hwnd)) {
        return std::nullopt;
    }

    GetWindowThreadProcessId(hwnd, &pid);
    if (pid == m_ownPid) {
        return std::nullopt;
    }
    if (cls == "Progman" || cls == "WorkerW" || cls == "Shell_TrayWnd") {
        return std::nullopt;
    }
    if (isCloaked(hwnd) || isMinimized(hwnd)) {
        return std::nullopt;
    }
    if (supported && !isSupportedAspectRatio(effectiveRect)) {
        supported = false;
        reason = "expected ~16:9";
        finalMode = "unsupported-ratio";
    }

    const QString exePath = processPath(pid);
    QFileInfo fileInfo(exePath);

    WindowInfo info;
    info.hwnd = reinterpret_cast<qintptr>(hwnd);
    info.pid = pid;
    info.title = windowText(hwnd);
    info.exeName = fileInfo.fileName().isEmpty() ? QString("pid-%1").arg(pid) : fileInfo.fileName().toLower();
    info.exePath = exePath;
    info.rect = effectiveRect;
    info.monitorRect = monitor;
    info.mode = finalMode;
    info.supported = supported;
    info.reason = reason;
    return info;
#endif
}

Rect ForegroundWindowTracker::primaryMonitorRect() const
{
#ifndef Q_OS_WIN
    return Rect{0, 0, 1280, 720};
#else
    POINT point{0, 0};
    MONITORINFO info{};
    info.cbSize = sizeof(info);
    GetMonitorInfoW(MonitorFromPoint(point, kMonitorDefaultToNearest), &info);
    return rectFromWin32(info.rcMonitor);
#endif
}
