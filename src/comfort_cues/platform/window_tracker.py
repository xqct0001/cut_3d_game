from __future__ import annotations

from ctypes import POINTER, Structure, WinDLL, byref, c_int, c_void_p, create_unicode_buffer, sizeof
from ctypes import wintypes
from pathlib import Path
import os
import sys

from comfort_cues.models import Rect, WindowInfo


if sys.platform == "win32":
    user32 = WinDLL("user32", use_last_error=True)
    kernel32 = WinDLL("kernel32", use_last_error=True)
    dwmapi = WinDLL("dwmapi", use_last_error=True)
else:
    user32 = kernel32 = dwmapi = None


DWMWA_CLOAKED = 14
MONITOR_DEFAULTTONEAREST = 2
SW_SHOWMINIMIZED = 2
GWL_STYLE = -16
WS_CAPTION = 0x00C00000
WS_POPUP = 0x80000000
PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
MIN_SUPPORTED_ASPECT = 1.74
MAX_SUPPORTED_ASPECT = 1.82


class RECT(Structure):
    _fields_ = [
        ("left", wintypes.LONG),
        ("top", wintypes.LONG),
        ("right", wintypes.LONG),
        ("bottom", wintypes.LONG),
    ]


class POINT(Structure):
    _fields_ = [("x", wintypes.LONG), ("y", wintypes.LONG)]


class WINDOWPLACEMENT(Structure):
    _fields_ = [
        ("length", wintypes.UINT),
        ("flags", wintypes.UINT),
        ("showCmd", wintypes.UINT),
        ("ptMinPosition", POINT),
        ("ptMaxPosition", POINT),
        ("rcNormalPosition", RECT),
    ]


class MONITORINFO(Structure):
    _fields_ = [
        ("cbSize", wintypes.DWORD),
        ("rcMonitor", RECT),
        ("rcWork", RECT),
        ("dwFlags", wintypes.DWORD),
    ]


def classify_window_mode(rect: Rect, monitor_rect: Rect, style: int) -> tuple[str, bool, str]:
    if rect.is_empty:
        return "unsupported", False, "empty window bounds"
    if rect.width < 320 or rect.height < 240:
        return "unsupported", False, "window too small"

    covers_monitor = (
        rect.x <= monitor_rect.x
        and rect.y <= monitor_rect.y
        and rect.right >= monitor_rect.right
        and rect.bottom >= monitor_rect.bottom
    )
    if covers_monitor and style & WS_POPUP and not style & WS_CAPTION:
        return "borderless", True, "borderless window supported"
    if covers_monitor:
        return "exclusive-or-unknown", False, "fullscreen mode not supported"
    return "windowed", True, "windowed mode supported"


class ForegroundWindowTracker:
    def __init__(self) -> None:
        self._own_pid = os.getpid()

    def snapshot(self) -> WindowInfo | None:
        if sys.platform != "win32":
            return None

        hwnd = user32.GetForegroundWindow()
        if not hwnd or not user32.IsWindowVisible(hwnd):
            return None

        pid = wintypes.DWORD()
        user32.GetWindowThreadProcessId(hwnd, byref(pid))
        if pid.value == self._own_pid:
            return None

        class_name = self._get_class_name(hwnd)
        if class_name in {"Progman", "WorkerW", "Shell_TrayWnd"}:
            return None
        if self._is_cloaked(hwnd) or self._is_minimized(hwnd):
            return None

        frame_rect = self._get_window_rect(hwnd)
        client_rect = self._get_client_rect(hwnd)
        rect = client_rect if not client_rect.is_empty else frame_rect
        monitor_rect = self._get_monitor_rect(hwnd)
        style = int(user32.GetWindowLongPtrW(hwnd, GWL_STYLE) or 0)
        mode, supported, reason = classify_window_mode(frame_rect, monitor_rect, style)
        if supported and not _is_supported_aspect_ratio(rect):
            mode, supported, reason = "unsupported-ratio", False, "expected ~16:9"
        exe_path = self._get_process_path(pid.value)
        exe_name = Path(exe_path).name.lower() if exe_path else f"pid-{pid.value}"
        return WindowInfo(
            hwnd=int(hwnd),
            pid=pid.value,
            title=self._get_window_text(hwnd),
            exe_name=exe_name,
            exe_path=exe_path,
            rect=rect,
            monitor_rect=monitor_rect,
            mode=mode,
            supported=supported,
            reason=reason,
        )

    def primary_monitor_rect(self) -> Rect:
        if sys.platform != "win32":
            return Rect(0, 0, 1280, 720)
        point = POINT(0, 0)
        monitor = user32.MonitorFromPoint(point, MONITOR_DEFAULTTONEAREST)
        info = MONITORINFO(cbSize=sizeof(MONITORINFO))
        user32.GetMonitorInfoW(monitor, byref(info))
        return _rect_from_win32(info.rcMonitor)

    @staticmethod
    def _get_window_text(hwnd: int) -> str:
        buffer = create_unicode_buffer(512)
        user32.GetWindowTextW(hwnd, buffer, len(buffer))
        return buffer.value

    @staticmethod
    def _get_class_name(hwnd: int) -> str:
        buffer = create_unicode_buffer(256)
        user32.GetClassNameW(hwnd, buffer, len(buffer))
        return buffer.value

    @staticmethod
    def _get_window_rect(hwnd: int) -> Rect:
        rect = RECT()
        user32.GetWindowRect(hwnd, byref(rect))
        return _rect_from_win32(rect)

    @staticmethod
    def _get_client_rect(hwnd: int) -> Rect:
        rect = RECT()
        if not user32.GetClientRect(hwnd, byref(rect)):
            return Rect()
        top_left = POINT(rect.left, rect.top)
        bottom_right = POINT(rect.right, rect.bottom)
        if not user32.ClientToScreen(hwnd, byref(top_left)):
            return Rect()
        if not user32.ClientToScreen(hwnd, byref(bottom_right)):
            return Rect()
        return Rect(
            x=top_left.x,
            y=top_left.y,
            width=max(0, bottom_right.x - top_left.x),
            height=max(0, bottom_right.y - top_left.y),
        )

    @staticmethod
    def _get_monitor_rect(hwnd: int) -> Rect:
        monitor = user32.MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)
        info = MONITORINFO(cbSize=sizeof(MONITORINFO))
        user32.GetMonitorInfoW(monitor, byref(info))
        return _rect_from_win32(info.rcMonitor)

    @staticmethod
    def _is_cloaked(hwnd: int) -> bool:
        cloaked = wintypes.DWORD()
        result = dwmapi.DwmGetWindowAttribute(hwnd, DWMWA_CLOAKED, byref(cloaked), sizeof(cloaked))
        return result == 0 and cloaked.value != 0

    @staticmethod
    def _is_minimized(hwnd: int) -> bool:
        placement = WINDOWPLACEMENT()
        placement.length = sizeof(WINDOWPLACEMENT)
        user32.GetWindowPlacement(hwnd, byref(placement))
        return placement.showCmd == SW_SHOWMINIMIZED

    @staticmethod
    def _get_process_path(pid: int) -> str:
        handle = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
        if not handle:
            return ""
        try:
            size = wintypes.DWORD(512)
            buffer = create_unicode_buffer(size.value)
            if kernel32.QueryFullProcessImageNameW(handle, 0, buffer, byref(size)):
                return buffer.value
            return ""
        finally:
            kernel32.CloseHandle(handle)


def _rect_from_win32(rect: RECT) -> Rect:
    return Rect(x=rect.left, y=rect.top, width=rect.right - rect.left, height=rect.bottom - rect.top)


def _is_supported_aspect_ratio(rect: Rect) -> bool:
    if rect.is_empty or rect.height <= 0:
        return False
    aspect_ratio = rect.width / rect.height
    return MIN_SUPPORTED_ASPECT <= aspect_ratio <= MAX_SUPPORTED_ASPECT


if sys.platform == "win32":
    user32.GetForegroundWindow.restype = wintypes.HWND
    user32.IsWindowVisible.argtypes = [wintypes.HWND]
    user32.GetWindowThreadProcessId.argtypes = [wintypes.HWND, POINTER(wintypes.DWORD)]
    user32.GetWindowTextW.argtypes = [wintypes.HWND, wintypes.LPWSTR, c_int]
    user32.GetClassNameW.argtypes = [wintypes.HWND, wintypes.LPWSTR, c_int]
    user32.GetWindowRect.argtypes = [wintypes.HWND, POINTER(RECT)]
    user32.GetClientRect.argtypes = [wintypes.HWND, POINTER(RECT)]
    user32.GetClientRect.restype = wintypes.BOOL
    user32.ClientToScreen.argtypes = [wintypes.HWND, POINTER(POINT)]
    user32.ClientToScreen.restype = wintypes.BOOL
    user32.GetWindowPlacement.argtypes = [wintypes.HWND, POINTER(WINDOWPLACEMENT)]
    user32.MonitorFromWindow.argtypes = [wintypes.HWND, wintypes.DWORD]
    user32.MonitorFromPoint.argtypes = [POINT, wintypes.DWORD]
    user32.GetMonitorInfoW.argtypes = [wintypes.HMONITOR, POINTER(MONITORINFO)]
    user32.GetWindowLongPtrW.argtypes = [wintypes.HWND, c_int]
    user32.GetWindowLongPtrW.restype = c_void_p
    kernel32.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
    kernel32.OpenProcess.restype = wintypes.HANDLE
    kernel32.QueryFullProcessImageNameW.argtypes = [wintypes.HANDLE, wintypes.DWORD, wintypes.LPWSTR, POINTER(wintypes.DWORD)]
    kernel32.CloseHandle.argtypes = [wintypes.HANDLE]
