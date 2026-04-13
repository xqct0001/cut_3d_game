#include "cc_core.h"

#include <math.h>
#include <string.h>

static float clamp01(float value)
{
    if (value < 0.0f) {
        return 0.0f;
    }
    if (value > 1.0f) {
        return 1.0f;
    }
    return value;
}

static float clamp_signed(float value)
{
    if (value < -1.0f) {
        return -1.0f;
    }
    if (value > 1.0f) {
        return 1.0f;
    }
    return value;
}

static float density(float edge_factor, float floor_value, float ambient)
{
    const float strength = clamp01(edge_factor * 0.82f + ambient * 0.32f);
    if (strength <= 0.01f) {
        return 0.0f;
    }
    return clamp01(floor_value + strength * (1.0f - floor_value));
}

static float delta_ms(CCCueEngineState *state, float timestamp_ms)
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

static float ease(float current, float target, float dt_ms, const CCProfileParams *profile, float extra_scale)
{
    float duration = profile->fade_out_ms;
    float ratio = 1.0f;
    if (target > current) {
        duration = profile->fade_in_ms;
    }
    if (duration <= 0.0f) {
        return target;
    }
    ratio = dt_ms / duration;
    if (ratio > 1.0f) {
        ratio = 1.0f;
    }
    ratio *= extra_scale;
    return current + (target - current) * ratio;
}

CCCueState cc_cue_zero(void)
{
    CCCueState state;
    memset(&state, 0, sizeof(state));
    state.center_safe_ratio = 0.74f;
    return state;
}

CCCueState cc_cue_state_zero(void)
{
    return cc_cue_zero();
}

void cc_cue_init(CCCueEngineState *state)
{
    cc_cue_reset(state);
}

void cc_cue_reset(CCCueEngineState *state)
{
    if (state == 0) {
        return;
    }
    state->state = cc_cue_zero();
    state->last_timestamp_ms = 0.0f;
    state->has_last_timestamp = 0;
}

static CCCueState target_state(const CCComfortSignal *signal, const CCProfileParams *profile)
{
    const float yaw_magnitude = clamp01(fabsf(signal->yaw_rate));
    const float pitch_magnitude = clamp01(fabsf(signal->pitch_rate));
    const float lateral_magnitude = clamp01(fabsf(signal->lateral_rate));
    const float max_opacity = profile->max_opacity;
    const float turn_strength = clamp01(yaw_magnitude * 1.08f + lateral_magnitude * 0.28f);
    const float side_breath = clamp01(turn_strength * 0.18f + lateral_magnitude * 0.16f);
    const float side_floor = yaw_magnitude * 0.10f;
    const float vertical_factor = clamp01(pitch_magnitude * 0.84f);
    const float vertical_floor = pitch_magnitude * 0.12f;
    float left_factor = 0.0f;
    float right_factor = 0.0f;
    float top_factor = 0.0f;
    float bottom_factor = 0.0f;
    const float vertical_cap = max_opacity * 0.70f;
    CCCueState cue = cc_cue_zero();

    if (signal->yaw_rate < -0.01f) {
        left_factor = fminf(1.0f, turn_strength * 0.98f + side_breath * 0.38f + side_floor * 0.28f);
        right_factor = fminf(0.86f, turn_strength * 0.68f + side_breath * 0.24f + side_floor * 0.18f);
    } else if (signal->yaw_rate > 0.01f) {
        left_factor = fminf(0.86f, turn_strength * 0.68f + side_breath * 0.24f + side_floor * 0.18f);
        right_factor = fminf(1.0f, turn_strength * 0.98f + side_breath * 0.38f + side_floor * 0.28f);
    } else {
        left_factor = side_breath * 0.72f;
        right_factor = side_breath * 0.72f;
    }

    if (signal->pitch_rate < -0.01f) {
        top_factor = vertical_factor + vertical_floor;
        bottom_factor = vertical_factor * 0.40f + vertical_floor * 0.46f;
    } else if (signal->pitch_rate > 0.01f) {
        top_factor = vertical_factor * 0.40f + vertical_floor * 0.46f;
        bottom_factor = vertical_factor + vertical_floor;
    }

    cue.left_alpha = max_opacity * fminf(1.0f, left_factor);
    cue.right_alpha = max_opacity * fminf(1.0f, right_factor);
    cue.top_alpha = vertical_cap * top_factor;
    cue.bottom_alpha = vertical_cap * bottom_factor;
    cue.energy = clamp01(fmaxf(turn_strength, fmaxf(vertical_factor * 0.92f, lateral_magnitude * 0.46f)));
    cue.center_safe_ratio = fminf(0.78f, 0.74f + turn_strength * 0.022f + vertical_factor * 0.028f);
    cue.center_bias = fminf(0.34f, 0.12f + fmaxf(turn_strength, vertical_factor) * 0.14f);
    cue.motion_x = clamp_signed(signal->yaw_rate * 1.00f + signal->lateral_rate * 0.34f);
    cue.motion_y = clamp_signed(signal->pitch_rate * 1.08f);
    cue.left_density = density(left_factor, 0.26f, side_breath);
    cue.right_density = density(right_factor, 0.26f, side_breath);
    cue.top_density = density(top_factor, 0.14f, 0.0f);
    cue.bottom_density = density(bottom_factor, 0.14f, 0.0f);
    return cue;
}

CCCueState cc_cue_update(CCCueEngineState *state, const CCComfortSignal *signal, const CCProfileParams *profile, float timestamp_ms)
{
    const float dt_ms = delta_ms(state, timestamp_ms);
    const CCCueState target = target_state(signal, profile);
    CCCueState current = cc_cue_zero();

    if (state == 0 || signal == 0 || profile == 0) {
        return cc_cue_zero();
    }

    current.left_alpha = ease(state->state.left_alpha, target.left_alpha, dt_ms, profile, 1.0f);
    current.right_alpha = ease(state->state.right_alpha, target.right_alpha, dt_ms, profile, 1.0f);
    current.top_alpha = ease(state->state.top_alpha, target.top_alpha, dt_ms, profile, 1.0f);
    current.bottom_alpha = ease(state->state.bottom_alpha, target.bottom_alpha, dt_ms, profile, 1.0f);
    current.center_bias = ease(state->state.center_bias, target.center_bias, dt_ms, profile, 0.6f);
    current.left_density = ease(state->state.left_density, target.left_density, dt_ms, profile, 0.85f);
    current.right_density = ease(state->state.right_density, target.right_density, dt_ms, profile, 0.85f);
    current.top_density = ease(state->state.top_density, target.top_density, dt_ms, profile, 0.85f);
    current.bottom_density = ease(state->state.bottom_density, target.bottom_density, dt_ms, profile, 0.85f);
    current.center_safe_ratio = ease(state->state.center_safe_ratio, target.center_safe_ratio, dt_ms, profile, 0.5f);
    current.motion_x = ease(state->state.motion_x, target.motion_x, dt_ms, profile, 0.9f);
    current.motion_y = ease(state->state.motion_y, target.motion_y, dt_ms, profile, 0.9f);
    current.energy = ease(state->state.energy, target.energy, dt_ms, profile, 0.9f);

    state->state = current;
    return current;
}

float cc_flow_speed(const char *pattern, float cue_energy)
{
    float energy = clamp01(cue_energy);
    if (energy <= 0.001f) {
        return 0.0f;
    }
    if (pattern != 0 && strcmp(pattern, "dynamic") == 0) {
        return 0.22f + energy * 4.6f;
    }
    return 0.12f + energy * 2.1f;
}
