#include "cc_core.h"

#include <math.h>

static float cc_clamp(float value, float minimum, float maximum)
{
    if (value < minimum) {
        return minimum;
    }
    if (value > maximum) {
        return maximum;
    }
    return value;
}

static float lateral_input(const CCInputSnapshot *snapshot)
{
    const float lateral = snapshot->gamepad_lateral + snapshot->keyboard_lateral;
    return cc_clamp(lateral, -1.0f, 1.0f);
}

static float delta_ms(CCSignalProcessorState *state, float timestamp_ms)
{
    float result = 16.0f;
    if (state->has_last_timestamp) {
        result = timestamp_ms - state->last_timestamp_ms;
        if (result < 1.0f) {
            result = 1.0f;
        }
    }
    state->last_timestamp_ms = timestamp_ms;
    state->has_last_timestamp = 1;
    return result;
}

static float smooth(float previous, float current, float smoothing)
{
    return previous + (current - previous) * smoothing;
}

static float apply_deadzone(float value, float deadzone)
{
    const float magnitude = fabsf(value);
    float scaled = 0.0f;
    if (magnitude <= deadzone) {
        return 0.0f;
    }
    scaled = (magnitude - deadzone) / fmaxf(1e-6f, 1.0f - deadzone);
    scaled = cc_clamp(scaled, 0.0f, 1.0f);
    return copysignf(scaled, value);
}

void cc_signal_reset(CCSignalProcessorState *state)
{
    if (state == 0) {
        return;
    }
    state->smoothing = 0.32f;
    state->mouse_scale = 0.045f;
    state->last_timestamp_ms = 0.0f;
    state->has_last_timestamp = 0;
    state->yaw_state = 0.0f;
    state->pitch_state = 0.0f;
    state->lateral_state = 0.0f;
}

void cc_signal_init(CCSignalProcessorState *state, float smoothing, float mouse_scale)
{
    if (state == 0) {
        return;
    }
    state->smoothing = smoothing;
    state->mouse_scale = mouse_scale;
    cc_signal_reset(state);
}

CCComfortSignal cc_comfort_signal_zero(float timestamp_ms)
{
    CCComfortSignal signal;
    signal.yaw_rate = 0.0f;
    signal.pitch_rate = 0.0f;
    signal.lateral_rate = 0.0f;
    signal.timestamp_ms = timestamp_ms;
    return signal;
}

CCComfortSignal cc_signal_process(CCSignalProcessorState *state, const CCInputSnapshot *snapshot, const CCProfileParams *profile, float timestamp_ms)
{
    float yaw_raw = 0.0f;
    float pitch_raw = 0.0f;
    float lateral_raw = 0.0f;
    float yaw = 0.0f;
    float pitch = 0.0f;
    float lateral = 0.0f;
    float dt_ms = 16.0f;
    CCComfortSignal signal;

    if (state == 0 || snapshot == 0 || profile == 0) {
        return cc_comfort_signal_zero(timestamp_ms);
    }

    dt_ms = delta_ms(state, timestamp_ms);
    if (dt_ms < 8.0f) {
        dt_ms = 8.0f;
    }

    if (snapshot->raw_input_active) {
        yaw_raw += snapshot->mouse_dx / dt_ms * state->mouse_scale * profile->yaw_gain;
        pitch_raw += snapshot->mouse_dy / dt_ms * state->mouse_scale * profile->pitch_gain;
    }
    if (snapshot->gamepad_connected) {
        yaw_raw += snapshot->gamepad_yaw * 0.7f * profile->yaw_gain;
        pitch_raw += snapshot->gamepad_pitch * 0.7f * profile->pitch_gain;
    }

    lateral_raw = lateral_input(snapshot) * 0.75f;

    yaw = smooth(state->yaw_state, apply_deadzone(yaw_raw, profile->deadzone), state->smoothing);
    pitch = smooth(state->pitch_state, apply_deadzone(pitch_raw, profile->deadzone), state->smoothing);
    lateral = smooth(state->lateral_state, apply_deadzone(lateral_raw, profile->deadzone * 0.8f), state->smoothing);

    state->yaw_state = yaw;
    state->pitch_state = pitch;
    state->lateral_state = lateral;

    signal.yaw_rate = yaw;
    signal.pitch_rate = pitch;
    signal.lateral_rate = lateral;
    signal.timestamp_ms = timestamp_ms;
    return signal;
}
