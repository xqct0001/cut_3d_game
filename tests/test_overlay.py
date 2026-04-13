from comfort_cues.models import Rect
from comfort_cues.ui.overlay import _clamp_rect_to_bounds, _normalize_rect_for_screen, _scale_rect_to_logical


def test_scale_rect_to_logical_reduces_native_pixels_by_dpi_scale():
    scaled = _scale_rect_to_logical(Rect(200, 120, 1600, 900), 1.25)
    assert scaled == Rect(160, 96, 1280, 720)


def test_clamp_rect_to_bounds_keeps_overlay_inside_screen():
    clamped = _clamp_rect_to_bounds(Rect(1500, 30, 900, 700), Rect(0, 0, 1920, 1080))
    assert clamped.right <= 1920
    assert clamped.bottom <= 1080
    assert clamped.width == 900
    assert clamped.height == 700


def test_normalize_rect_prefers_scaled_geometry_when_native_rect_overflows():
    normalized = _normalize_rect_for_screen(Rect(200, 120, 1600, 900), Rect(0, 0, 1280, 720), 1.25)
    assert normalized == Rect(160, 96, 1280, 720)


def test_normalize_rect_keeps_existing_logical_geometry_when_it_already_fits():
    logical = Rect(160, 96, 1280, 720)
    normalized = _normalize_rect_for_screen(logical, Rect(0, 0, 1280, 720), 1.25)
    assert normalized == logical
