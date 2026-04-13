#ifndef CC_CORE_H
#define CC_CORE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    float yaw_gain;
    float pitch_gain;
    float deadzone;
    float max_opacity;
    float fade_in_ms;
    float fade_out_ms;
} CCProfileParams;

typedef struct {
    float mouse_dx;
    float mouse_dy;
    float gamepad_yaw;
    float gamepad_pitch;
    float gamepad_lateral;
    float keyboard_lateral;
    float timestamp_ms;
    int raw_input_active;
    int gamepad_connected;
} CCInputSnapshot;

typedef struct {
    float yaw_rate;
    float pitch_rate;
    float lateral_rate;
    float timestamp_ms;
} CCComfortSignal;

typedef struct {
    float left_alpha;
    float right_alpha;
    float top_alpha;
    float bottom_alpha;
    float center_bias;
    float left_density;
    float right_density;
    float top_density;
    float bottom_density;
    float center_safe_ratio;
    float motion_x;
    float motion_y;
    float energy;
} CCCueState;

typedef struct {
    float smoothing;
    float mouse_scale;
    float last_timestamp_ms;
    int has_last_timestamp;
    float yaw_state;
    float pitch_state;
    float lateral_state;
} CCSignalProcessorState;

typedef struct {
    CCCueState state;
    float last_timestamp_ms;
    int has_last_timestamp;
} CCCueEngineState;

void cc_signal_init(CCSignalProcessorState *state, float smoothing, float mouse_scale);
void cc_signal_reset(CCSignalProcessorState *state);
CCComfortSignal cc_signal_process(CCSignalProcessorState *state, const CCInputSnapshot *snapshot, const CCProfileParams *profile, float timestamp_ms);

void cc_cue_init(CCCueEngineState *state);
void cc_cue_reset(CCCueEngineState *state);
CCCueState cc_cue_update(CCCueEngineState *state, const CCComfortSignal *signal, const CCProfileParams *profile, float timestamp_ms);

float cc_flow_speed(const char *pattern, float cue_energy);
CCCueState cc_cue_zero(void);
CCComfortSignal cc_comfort_signal_zero(float timestamp_ms);
CCCueState cc_cue_state_zero(void);

#ifdef __cplusplus
}
#endif

#endif
