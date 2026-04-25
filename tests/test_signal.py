from comfort_cues.config import Profile
from comfort_cues.engine.signal import SignalProcessor
from comfort_cues.models import InputSnapshot


def test_signal_applies_deadzone_and_smoothing():
    profile = Profile(name="Test", deadzone=0.1, yaw_gain=1.0, pitch_gain=1.0)
    processor = SignalProcessor(smoothing=0.5, mouse_scale=0.05)

    quiet = processor.process(InputSnapshot(mouse_dx=4, raw_input_active=True), profile, 16.0)
    assert quiet.yaw_rate == 0.0

    loud = processor.process(InputSnapshot(mouse_dx=80, raw_input_active=True), profile, 32.0)
    assert 0.0 < loud.yaw_rate < 1.0

    decayed = processor.process(InputSnapshot(raw_input_active=True), profile, 48.0)
    assert decayed.yaw_rate < loud.yaw_rate


def test_signal_combines_gamepad_and_keyboard_lateral():
    profile = Profile(name="Test", deadzone=0.05)
    processor = SignalProcessor(smoothing=1.0, mouse_scale=0.05)
    signal = processor.process(
        InputSnapshot(gamepad_connected=True, gamepad_yaw=0.5, keyboard_lateral=1.0),
        profile,
        16.0,
    )
    assert signal.yaw_rate > 0.0
    assert signal.lateral_rate > 0.0


def test_signal_respects_disabled_mouse_and_gamepad_sources():
    profile = Profile(name="Test", deadzone=0.05, enable_mouse=False, enable_gamepad=False)
    processor = SignalProcessor(smoothing=1.0, mouse_scale=0.05)
    signal = processor.process(
        InputSnapshot(
            mouse_dx=200.0,
            mouse_dy=100.0,
            raw_input_active=True,
            gamepad_connected=True,
            gamepad_yaw=1.0,
            gamepad_pitch=1.0,
            gamepad_lateral=1.0,
            keyboard_lateral=1.0,
        ),
        profile,
        16.0,
    )
    assert signal.yaw_rate == 0.0
    assert signal.pitch_rate == 0.0
    assert signal.lateral_rate > 0.0
