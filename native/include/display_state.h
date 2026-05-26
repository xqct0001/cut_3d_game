#ifndef DISPLAY_STATE_H
#define DISPLAY_STATE_H

struct CueDisplayValues {
    bool overlayVisible = false;
    float leftAlpha = 0.0f;
    float rightAlpha = 0.0f;
    float topAlpha = 0.0f;
    float bottomAlpha = 0.0f;
    float leftDensity = 0.0f;
    float rightDensity = 0.0f;
    float topDensity = 0.0f;
    float bottomDensity = 0.0f;
};

float scaledCueEnergy(float cueEnergy, bool debugOverlayEnabled, double debugOpacityMultiplier);
void applyDebugCueVisibility(CueDisplayValues &values, bool debugOverlayEnabled, double debugOpacityMultiplier);

#endif
