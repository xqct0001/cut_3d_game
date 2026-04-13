#ifndef OVERLAY_UTILS_H
#define OVERLAY_UTILS_H

#include "models.h"

class QQuickWindow;

void configureOverlayWindow(QQuickWindow *window);
Rect resolveOverlayRect(QQuickWindow *window, const Rect &rect);
void applyOverlayGeometry(QQuickWindow *window, const Rect &rect);

#endif
