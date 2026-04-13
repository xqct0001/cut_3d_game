#ifndef MODELS_H
#define MODELS_H

#include "cc_core.h"

#include <QString>

struct Rect {
    int x = 0;
    int y = 0;
    int width = 0;
    int height = 0;

    int right() const { return x + width; }
    int bottom() const { return y + height; }
    bool isEmpty() const { return width <= 0 || height <= 0; }
};

struct WindowInfo {
    qintptr hwnd = 0;
    unsigned long pid = 0;
    QString title;
    QString exeName;
    QString exePath;
    Rect rect;
    Rect monitorRect;
    QString mode;
    bool supported = false;
    QString reason;
};

struct RuntimeViewState {
    bool overlayVisible = false;
    Rect overlayRect;
    CCCueState cueState = cc_cue_zero();
    QString statusText;
    QString activeProfileName;
    QString activeWindowTitle;
    QString supportMode;
    bool simulatorEnabled = false;
};

#endif
