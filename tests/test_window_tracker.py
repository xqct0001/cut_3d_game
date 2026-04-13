from comfort_cues.models import Rect
from comfort_cues.platform.window_tracker import WS_CAPTION, WS_POPUP, _is_supported_aspect_ratio, classify_window_mode


def test_classify_window_mode_accepts_near_16_9_windowed():
    mode, supported, reason = classify_window_mode(
        Rect(10, 10, 1280, 720),
        Rect(0, 0, 1920, 1080),
        WS_CAPTION,
    )
    assert mode == "windowed"
    assert supported is True
    assert "supported" in reason


def test_classify_window_mode_rejects_non_16_9_ratio():
    mode, supported, reason = classify_window_mode(
        Rect(10, 10, 1280, 800),
        Rect(0, 0, 1920, 1080),
        WS_CAPTION,
    )
    assert mode == "windowed"
    assert supported is True
    assert "supported" in reason


def test_classify_window_mode_accepts_near_16_9_borderless():
    mode, supported, reason = classify_window_mode(
        Rect(0, 0, 1920, 1080),
        Rect(0, 0, 1920, 1080),
        WS_POPUP,
    )
    assert mode == "borderless"
    assert supported is True
    assert "supported" in reason


def test_supported_aspect_ratio_accepts_16_9_client_rect():
    assert _is_supported_aspect_ratio(Rect(0, 0, 1280, 720)) is True


def test_supported_aspect_ratio_rejects_non_16_9_client_rect():
    assert _is_supported_aspect_ratio(Rect(0, 0, 1294, 758)) is False
