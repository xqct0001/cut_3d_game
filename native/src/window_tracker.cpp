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
static constexpr DWORD kProcessQueryLimitedInformation = 0x1000;
#endif

static constexpr long kWsCaption = 0x00C00000L;
static constexpr long kWsPopup = 0x80000000L;

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

bool ignoredWindow(HWND hwnd, DWORD ownPid)
{
    if (hwnd == nullptr || !IsWindowVisible(hwnd)) {
        return true;
    }

    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    if (pid == ownPid) {
        return true;
    }

    const QString cls = className(hwnd);
    if (cls == "Progman" || cls == "WorkerW" || cls == "Shell_TrayWnd") {
        return true;
    }
    if (isCloaked(hwnd) || isMinimized(hwnd)) {
        return true;
    }
    return false;
}

std::optional<WindowInfo> windowInfoFromHwnd(HWND hwnd, DWORD ownPid)
{
    if (ignoredWindow(hwnd, ownPid)) {
        return std::nullopt;
    }

    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    const Rect frameRect = windowRect(hwnd);
    const Rect client = clientRect(hwnd);
    const Rect effectiveRect = client.isEmpty() ? frameRect : client;
    const Rect monitor = monitorRect(hwnd);
    const long style = static_cast<long>(GetWindowLongPtrW(hwnd, kGwlStyle));
    const auto [mode, supportedBase, reasonBase] = classifyWindowMode(frameRect, monitor, style);
    bool supported = supportedBase;
    QString reason = reasonBase;
    QString finalMode = mode;

    if (supported && !isSupportedAspectRatio(effectiveRect)) {
        supported = false;
        reason = "empty client area";
        finalMode = "unsupported";
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
}

struct WindowSearch {
    DWORD ownPid = 0;
    QVector<WindowInfo> windows;
};

BOOL CALLBACK collectVisibleWindow(HWND hwnd, LPARAM lParam)
{
    auto *search = reinterpret_cast<WindowSearch *>(lParam);
    const std::optional<WindowInfo> info = windowInfoFromHwnd(hwnd, search->ownPid);
    if (info.has_value()) {
        search->windows.append(*info);
    }
    return TRUE;
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
    if (rect.width < 160 || rect.height < 120) {
        return {"unsupported", false, "window too small"};
    }
    if (coversMonitor && (style & kWsPopup) && !(style & kWsCaption)) {
        return {"borderless", true, "borderless window supported"};
    }
    if (coversMonitor) {
        return {"fullscreen", true, "fullscreen window supported"};
    }
    return {"windowed", true, "windowed mode supported"};
}

bool isSupportedAspectRatio(const Rect &rect)
{
    return !rect.isEmpty() && rect.height > 0;
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
    return windowInfoFromHwnd(GetForegroundWindow(), static_cast<DWORD>(m_ownPid));
#endif
}

QVector<WindowInfo> ForegroundWindowTracker::visibleWindows() const
{
#ifndef Q_OS_WIN
    return {};
#else
    WindowSearch search;
    search.ownPid = static_cast<DWORD>(m_ownPid);
    EnumWindows(collectVisibleWindow, reinterpret_cast<LPARAM>(&search));
    return search.windows;
#endif
}

std::optional<WindowInfo> ForegroundWindowTracker::bestVisibleWindow() const
{
#ifndef Q_OS_WIN
    return std::nullopt;
#else
    const QVector<WindowInfo> windows = visibleWindows();
    std::optional<WindowInfo> bestSupported;
    std::optional<WindowInfo> bestUnsupported;
    auto area = [](const WindowInfo &window) {
        return static_cast<long long>(window.rect.width) * static_cast<long long>(window.rect.height);
    };

    for (const WindowInfo &window : windows) {
        if (window.supported) {
            if (!bestSupported.has_value() || area(window) > area(*bestSupported)) {
                bestSupported = window;
            }
        } else if (!bestUnsupported.has_value() || area(window) > area(*bestUnsupported)) {
            bestUnsupported = window;
        }
    }

    if (bestSupported.has_value()) {
        return bestSupported;
    }
    return bestUnsupported;
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
