#include "overlay_utils.h"

#include <QGuiApplication>
#include <QQuickWindow>
#include <QRect>
#include <QScreen>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

namespace {

Rect rectFromQt(const QRect &rect)
{
    return Rect{rect.x(), rect.y(), rect.width(), rect.height()};
}

Rect scaleRectToLogical(const Rect &rect, qreal scale)
{
    if (scale <= 1.0) {
        return rect;
    }
    return Rect{
        qRound(rect.x / scale),
        qRound(rect.y / scale),
        qMax(1, qRound(rect.width / scale)),
        qMax(1, qRound(rect.height / scale)),
    };
}

int boundsPenalty(const Rect &rect, const Rect &bounds)
{
    const int widthOverflow = qMax(0, rect.width - bounds.width);
    const int heightOverflow = qMax(0, rect.height - bounds.height);
    const int leftOverflow = qMax(0, bounds.x - rect.x);
    const int topOverflow = qMax(0, bounds.y - rect.y);
    const int rightOverflow = qMax(0, rect.right() - bounds.right());
    const int bottomOverflow = qMax(0, rect.bottom() - bounds.bottom());
    return widthOverflow + heightOverflow + leftOverflow + topOverflow + rightOverflow + bottomOverflow;
}

Rect clampRectToBounds(const Rect &rect, const Rect &bounds)
{
    if (rect.isEmpty() || bounds.isEmpty()) {
        return rect;
    }
    const int width = qMax(1, qMin(rect.width, bounds.width));
    const int height = qMax(1, qMin(rect.height, bounds.height));
    const int maxX = bounds.right() - width;
    const int maxY = bounds.bottom() - height;
    return Rect{
        qMin(qMax(rect.x, bounds.x), maxX),
        qMin(qMax(rect.y, bounds.y), maxY),
        width,
        height,
    };
}

Rect normalizeRectForScreen(const Rect &rect, const Rect &bounds, qreal scale)
{
    if (scale <= 1.0 || (rect.width <= bounds.width && rect.height <= bounds.height)) {
        return rect;
    }
    const Rect scaled = scaleRectToLogical(rect, scale);
    return boundsPenalty(scaled, bounds) < boundsPenalty(rect, bounds) ? scaled : rect;
}

} // namespace

void configureOverlayWindow(QQuickWindow *window)
{
#ifdef Q_OS_WIN
    if (window == nullptr) {
        return;
    }
    const HWND hwnd = reinterpret_cast<HWND>(window->winId());
    const LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE)
        | WS_EX_LAYERED
        | WS_EX_TRANSPARENT
        | WS_EX_TOOLWINDOW
        | WS_EX_NOACTIVATE;
    SetWindowLongPtrW(hwnd, GWL_EXSTYLE, style);
    SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
#else
    Q_UNUSED(window)
#endif
}

Rect resolveOverlayRect(QQuickWindow *window, const Rect &rect)
{
    if (window == nullptr || rect.isEmpty()) {
        return rect;
    }

    QScreen *screen = window->screen();
    if (screen == nullptr) {
        screen = QGuiApplication::primaryScreen();
    }
    if (screen == nullptr) {
        return rect;
    }

    const Rect bounds = rectFromQt(screen->geometry());
    const qreal scale = qMax<qreal>(1.0, screen->devicePixelRatio());
    return clampRectToBounds(normalizeRectForScreen(rect, bounds, scale), bounds);
}

void applyOverlayGeometry(QQuickWindow *window, const Rect &rect)
{
    if (window == nullptr || rect.isEmpty()) {
        return;
    }
    window->setX(rect.x);
    window->setY(rect.y);
    window->setWidth(rect.width);
    window->setHeight(rect.height);
}
