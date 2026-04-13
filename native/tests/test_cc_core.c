#include "../include/cc_core.h"

#include <assert.h>
#include <math.h>
#include <stdio.h>

static int nearly_equal(float left, float right)
{
    return fabsf(left - right) < 0.0005f;
}

static void test_signal_applies_deadzone_and_smoothing(void)
{
    CCProfileParams profile = {1.0f, 1.0f, 0.1f, 0.2f, 100.0f, 200.0f};
    CCSignalProcessorState quiet_state;
    CCSignalProcessorState state;
    CCComfortSignal quiet;
    CCComfortSignal loud;
    CCComfortSignal decayed;

    cc_signal_init(&quiet_state, 0.5f, 0.05f);
    quiet = cc_signal_process(&quiet_state, &(CCInputSnapshot){4.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 16.0, 1, 0}, &profile, 16.0);
    assert(nearly_equal(quiet.yaw_rate, 0.0f));

    cc_signal_init(&state, 0.5f, 0.05f);
    loud = cc_signal_process(&state, &(CCInputSnapshot){80.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 16.0, 1, 0}, &profile, 16.0);
    decayed = cc_signal_process(&state, &(CCInputSnapshot){0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 32.0, 1, 0}, &profile, 32.0);
    assert(loud.yaw_rate > 0.0f && loud.yaw_rate < 1.0f);
    assert(decayed.yaw_rate < loud.yaw_rate);
}

static void test_signal_combines_gamepad_and_keyboard_lateral(void)
{
    CCProfileParams profile = {1.0f, 0.85f, 0.05f, 0.2f, 100.0f, 200.0f};
    CCSignalProcessorState state;
    CCComfortSignal signal;

    cc_signal_init(&state, 1.0f, 0.05f);
    signal = cc_signal_process(&state, &(CCInputSnapshot){0.0f, 0.0f, 0.5f, 0.0f, 0.0f, 1.0f, 16.0, 0, 1}, &profile, 16.0);
    assert(signal.yaw_rate > 0.0f);
    assert(signal.lateral_rate > 0.0f);
}

static void test_cues_bias_toward_turn_direction_but_keep_secondary_edge(void)
{
    CCProfileParams profile = {1.0f, 0.85f, 0.08f, 0.3f, 10.0f, 10.0f};
    CCCueEngineState engine;
    CCCueState right;
    CCCueState left;

    cc_cue_init(&engine);
    right = cc_cue_update(&engine, &(CCComfortSignal){0.8f, 0.0f, 0.0f, 16.0}, &profile, 16.0);
    cc_cue_reset(&engine);
    left = cc_cue_update(&engine, &(CCComfortSignal){-0.8f, 0.0f, 0.0f, 16.0}, &profile, 16.0);

    assert(right.right_alpha > right.left_alpha && right.left_alpha > 0.0f);
    assert(left.left_alpha > left.right_alpha && left.right_alpha > 0.0f);
    assert(nearly_equal(right.right_alpha, left.left_alpha));
    assert(nearly_equal(right.left_alpha, left.right_alpha));
    assert(right.left_alpha / right.right_alpha >= 0.60f);
    assert(right.right_density > right.left_density && right.left_density > 0.0f);
    assert(left.left_density > left.right_density && left.right_density > 0.0f);
    assert(right.center_safe_ratio >= 0.72f && right.center_safe_ratio <= 0.78f);
    assert(right.motion_x > 0.0f);
    assert(left.motion_x < 0.0f);
    assert(nearly_equal(right.energy, left.energy));
}

static void test_pitch_only_uses_top_and_bottom_edges(void)
{
    CCProfileParams profile = {1.0f, 0.85f, 0.08f, 0.3f, 10.0f, 10.0f};
    CCCueEngineState engine;
    CCCueState down;
    CCCueState up;

    cc_cue_init(&engine);
    down = cc_cue_update(&engine, &(CCComfortSignal){0.0f, 0.9f, 0.0f, 16.0}, &profile, 16.0);
    cc_cue_reset(&engine);
    up = cc_cue_update(&engine, &(CCComfortSignal){0.0f, -0.9f, 0.0f, 16.0}, &profile, 16.0);

    assert(down.bottom_alpha > down.top_alpha && down.top_alpha > 0.0f);
    assert(up.top_alpha > up.bottom_alpha && up.bottom_alpha > 0.0f);
    assert(nearly_equal(down.left_alpha, 0.0f));
    assert(nearly_equal(down.right_alpha, 0.0f));
    assert(nearly_equal(up.left_alpha, 0.0f));
    assert(nearly_equal(up.right_alpha, 0.0f));
    assert(down.top_alpha / down.bottom_alpha >= 0.40f);
    assert(up.bottom_alpha / up.top_alpha >= 0.40f);
}

static void test_cues_fade_back_to_zero_without_input(void)
{
    CCProfileParams profile = {1.0f, 0.85f, 0.08f, 0.3f, 10.0f, 100.0f};
    CCCueEngineState engine;
    CCCueState active;
    CCCueState faded;

    cc_cue_init(&engine);
    active = cc_cue_update(&engine, &(CCComfortSignal){1.0f, 0.0f, 0.0f, 16.0}, &profile, 16.0);
    faded = cc_cue_update(&engine, &(CCComfortSignal){0.0f, 0.0f, 0.0f, 32.0}, &profile, 32.0);

    assert(active.right_alpha > active.left_alpha && active.left_alpha > 0.0f);
    assert(faded.right_alpha > 0.0f && faded.right_alpha < active.right_alpha);
    assert(faded.left_alpha > 0.0f && faded.left_alpha < active.left_alpha);
    assert(faded.right_density > 0.0f && faded.right_density < active.right_density);
    assert(faded.left_density > 0.0f && faded.left_density < active.left_density);
    assert(active.energy >= 0.0f && active.energy <= 1.0f);
    assert(faded.energy < active.energy);
}

static void test_cues_keep_motion_direction_and_decay_energy_after_stop(void)
{
    CCProfileParams profile = {1.0f, 0.85f, 0.08f, 0.3f, 20.0f, 120.0f};
    CCCueEngineState engine;
    CCCueState active;
    CCCueState settling;
    CCCueState faded;

    cc_cue_init(&engine);
    active = cc_cue_update(&engine, &(CCComfortSignal){0.9f, 0.0f, 0.5f, 16.0}, &profile, 16.0);
    settling = cc_cue_update(&engine, &(CCComfortSignal){0.0f, 0.0f, 0.0f, 64.0}, &profile, 64.0);
    faded = cc_cue_update(&engine, &(CCComfortSignal){0.0f, 0.0f, 0.0f, 196.0}, &profile, 196.0);

    assert(active.motion_x > 0.0f);
    assert(active.energy > 0.4f);
    assert(settling.energy >= 0.0f && settling.energy < active.energy);
    assert(faded.energy < settling.energy);
    assert(faded.right_alpha < settling.right_alpha && settling.right_alpha < active.right_alpha);
}

int main(void)
{
    test_signal_applies_deadzone_and_smoothing();
    test_signal_combines_gamepad_and_keyboard_lateral();
    test_cues_bias_toward_turn_direction_but_keep_secondary_edge();
    test_pitch_only_uses_top_and_bottom_edges();
    test_cues_fade_back_to_zero_without_input();
    test_cues_keep_motion_direction_and_decay_energy_after_stop();
    puts("native C core tests passed");
    return 0;
}
