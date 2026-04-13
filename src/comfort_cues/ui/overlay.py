from __future__ import annotations

from ctypes import WinDLL, wintypes
from ctypes import c_int, c_void_p
import sys

from PySide6.QtGui import QGuiApplication
from PySide6.QtGui import QWindow

from comfort_cues.models import Rect


if sys.platform == "win32":
    user32 = WinDLL("user32", use_last_error=True)
else:
    user32 = None


GWL_EXSTYLE = -20
WS_EX_LAYERED = 0x00080000
WS_EX_TRANSPARENT = 0x00000020
WS_EX_TOOLWINDOW = 0x00000080
WS_EX_NOACTIVATE = 0x08000000
HWND_TOPMOST = -1
SWP_NOMOVE = 0x0002
SWP_NOSIZE = 0x0001
SWP_NOACTIVATE = 0x0010
SWP_SHOWWINDOW = 0x0040


def configure_overlay_window(window: QWindow) -> None:
    if sys.platform != "win32":
        return
    hwnd = int(window.winId())
    style = int(user32.GetWindowLongPtrW(hwnd, GWL_EXSTYLE) or 0)
    style |= WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE
    user32.SetWindowLongPtrW(hwnd, GWL_EXSTYLE, style)
    user32.SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW)


def resolve_overlay_rect(window: QWindow, rect: Rect) -> Rect:
    if rect.is_empty:
        return rect
    screen = window.screen() or QGuiApplication.primaryScreen()
    if screen is None:
        return rect
    bounds = _rect_from_qt(screen.geometry())
    scale = max(1.0, float(screen.devicePixelRatio()))
    logical_rect = _normalize_rect_for_screen(rect, bounds, scale)
    return _clamp_rect_to_bounds(logical_rect, bounds)


def apply_overlay_geometry(window: QWindow, rect: Rect) -> None:
    if rect.is_empty:
        return
    window.setX(rect.x)
    window.setY(rect.y)
    window.setWidth(rect.width)
    window.setHeight(rect.height)


def _scale_rect_to_logical(rect: Rect, scale: float) -> Rect:
    if scale <= 1.0:
        return rect
    return Rect(
        x=round(rect.x / scale),
        y=round(rect.y / scale),
        width=max(1, round(rect.width / scale)),
        height=max(1, round(rect.height / scale)),
    )


def _normalize_rect_for_screen(rect: Rect, bounds: Rect, scale: float) -> Rect:
    if scale <= 1.0:
        return rect
    if rect.width <= bounds.width and rect.height <= bounds.height:
        return rect
    scaled = _scale_rect_to_logical(rect, scale)
    return scaled if _bounds_penalty(scaled, bounds) < _bounds_penalty(rect, bounds) else rect


def _clamp_rect_to_bounds(rect: Rect, bounds: Rect) -> Rect:
    if rect.is_empty or bounds.is_empty:
        return rect
    width = max(1, min(rect.width, bounds.width))
    height = max(1, min(rect.height, bounds.height))
    max_x = bounds.right - width
    max_y = bounds.bottom - height
    return Rect(
        x=min(max(rect.x, bounds.x), max_x),
        y=min(max(rect.y, bounds.y), max_y),
        width=width,
        height=height,
    )


def _bounds_penalty(rect: Rect, bounds: Rect) -> int:
    width_overflow = max(0, rect.width - bounds.width)
    height_overflow = max(0, rect.height - bounds.height)
    left_overflow = max(0, bounds.x - rect.x)
    top_overflow = max(0, bounds.y - rect.y)
    right_overflow = max(0, rect.right - bounds.right)
    bottom_overflow = max(0, rect.bottom - bounds.bottom)
    return width_overflow + height_overflow + left_overflow + top_overflow + right_overflow + bottom_overflow


def _rect_from_qt(rect) -> Rect:
    return Rect(rect.x(), rect.y(), rect.width(), rect.height())


if sys.platform == "win32":
    user32.GetWindowLongPtrW.argtypes = [wintypes.HWND, c_int]
    user32.GetWindowLongPtrW.restype = c_void_p
    user32.SetWindowLongPtrW.argtypes = [wintypes.HWND, c_int, c_void_p]
    user32.SetWindowLongPtrW.restype = c_void_p
    user32.SetWindowPos.argtypes = [wintypes.HWND, wintypes.HWND, c_int, c_int, c_int, c_int, wintypes.UINT]
