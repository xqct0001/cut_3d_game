#include "display_state.h"

#include <QtGlobal>

float scaledCueEnergy(float cueEnergy, bool debugOverlayEnabled, double debugOpacityMultiplier)
{
    if (!debugOverlayEnabled) {
        return cueEnergy;
    }
    return qMin(1.0f, cueEnergy * static_cast<float>(debugOpacityMultiplier));
}

void applyDebugCueVisibility(CueDisplayValues &values, bool debugOverlayEnabled, double debugOpacityMultiplier)
{
    if (!debugOverlayEnabled || !values.overlayVisible) {
        return;
    }

    const float multiplier = static_cast<float>(debugOpacityMultiplier);
    const float densityScale = 0.9f + multiplier * 0.18f;
    values.leftAlpha = qMin(1.0f, values.leftAlpha * multiplier);
    values.rightAlpha = qMin(1.0f, values.rightAlpha * multiplier);
    values.topAlpha = qMin(1.0f, values.topAlpha * multiplier);
    values.bottomAlpha = qMin(1.0f, values.bottomAlpha * multiplier);
    values.leftDensity = qMin(1.0f, values.leftDensity * densityScale);
    values.rightDensity = qMin(1.0f, values.rightDensity * densityScale);
    values.topDensity = qMin(1.0f, values.topDensity * densityScale);
    values.bottomDensity = qMin(1.0f, values.bottomDensity * densityScale);
}
