from comfort_cues.config import Profile
from comfort_cues.engine.cues import CueEngine
from comfort_cues.models import ComfortSignal


def test_cues_bias_toward_turn_direction_but_keep_secondary_edge():
    profile = Profile(name="Test", max_opacity=0.3, fade_in_ms=10, fade_out_ms=10)
    engine = CueEngine()

    right = engine.update(ComfortSignal(yaw_rate=0.8, timestamp_ms=16.0), profile, 16.0)
    engine.reset()
    left = engine.update(ComfortSignal(yaw_rate=-0.8, timestamp_ms=16.0), profile, 16.0)

    assert right.right_alpha > right.left_alpha > 0.0
    assert left.left_alpha > left.right_alpha > 0.0
    assert right.right_alpha == left.left_alpha
    assert right.left_alpha == left.right_alpha
    assert right.left_alpha / right.right_alpha >= 0.60
    assert right.right_density > right.left_density > 0.0
    assert left.left_density > left.right_density > 0.0
    assert 0.72 <= right.center_safe_ratio <= 0.78
    assert right.motion_x > 0.0
    assert left.motion_x < 0.0
    assert right.energy == left.energy


def test_pitch_only_uses_top_and_bottom_edges():
    profile = Profile(name="Test", max_opacity=0.3, fade_in_ms=10, fade_out_ms=10)
    engine = CueEngine()

    down = engine.update(ComfortSignal(pitch_rate=0.9, timestamp_ms=16.0), profile, 16.0)
    engine.reset()
    up = engine.update(ComfortSignal(pitch_rate=-0.9, timestamp_ms=16.0), profile, 16.0)

    assert down.bottom_alpha > down.top_alpha > 0.0
    assert up.top_alpha > up.bottom_alpha > 0.0
    assert down.left_alpha == 0.0
    assert down.right_alpha == 0.0
    assert up.left_alpha == 0.0
    assert up.right_alpha == 0.0
    assert down.top_alpha / down.bottom_alpha >= 0.40
    assert up.bottom_alpha / up.top_alpha >= 0.40


def test_cues_fade_back_to_zero_without_input():
    profile = Profile(name="Test", max_opacity=0.3, fade_in_ms=10, fade_out_ms=100)
    engine = CueEngine()

    active = engine.update(ComfortSignal(yaw_rate=1.0, timestamp_ms=16.0), profile, 16.0)
    assert active.right_alpha > active.left_alpha > 0.0

    faded = engine.update(ComfortSignal.zero(32.0), profile, 32.0)
    assert 0.0 < faded.right_alpha < active.right_alpha
    assert 0.0 < faded.left_alpha < active.left_alpha
    assert 0.0 < faded.right_density < active.right_density
    assert 0.0 < faded.left_density < active.left_density
    assert 0.0 <= active.energy <= 1.0
    assert faded.energy < active.energy


def test_cues_keep_motion_direction_and_decay_energy_after_stop():
    profile = Profile(name="Test", max_opacity=0.3, fade_in_ms=20, fade_out_ms=120)
    engine = CueEngine()

    active = engine.update(ComfortSignal(yaw_rate=0.9, lateral_rate=0.5, timestamp_ms=16.0), profile, 16.0)
    settling = engine.update(ComfortSignal.zero(64.0), profile, 64.0)
    faded = engine.update(ComfortSignal.zero(196.0), profile, 196.0)

    assert active.motion_x > 0.0
    assert active.energy > 0.4
    assert 0.0 <= settling.energy < active.energy
    assert faded.energy < settling.energy
    assert faded.right_alpha < settling.right_alpha < active.right_alpha
