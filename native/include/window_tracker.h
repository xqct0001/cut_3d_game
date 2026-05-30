#ifndef WINDOW_TRACKER_H
#define WINDOW_TRACKER_H

#include "models.h"

#include <QVector>

#include <optional>
#include <tuple>

std::tuple<QString, bool, QString> classifyWindowMode(const Rect &rect, const Rect &monitorRect, long style);
bool isSupportedAspectRatio(const Rect &rect);

class ForegroundWindowTracker {
public:
    ForegroundWindowTracker();

    std::optional<WindowInfo> snapshot() const;
    QVector<WindowInfo> visibleWindows() const;
    std::optional<WindowInfo> bestVisibleWindow() const;
    Rect primaryMonitorRect() const;

private:
    unsigned long m_ownPid = 0;
};

#endif
