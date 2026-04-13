from __future__ import annotations

from ctypes import POINTER, Structure, Union, WinDLL, byref, c_uint, c_void_p, sizeof
from ctypes import wintypes
from dataclasses import dataclass
from threading import Lock
import sys

from PySide6 import QtCore, QtWidgets

from comfort_cues.models import InputSnapshot


if sys.platform == "win32":
    user32 = WinDLL("user32", use_last_error=True)
else:
    user32 = None


RID_INPUT = 0x10000003
RIM_TYPEMOUSE = 0
RIDEV_INPUTSINK = 0x00000100
WM_INPUT = 0x00FF
VK_A = 0x41
VK_D = 0x44
VK_LEFT = 0x25
VK_RIGHT = 0x27


class RAWINPUTDEVICE(Structure):
    _fields_ = [
        ("usUsagePage", wintypes.USHORT),
        ("usUsage", wintypes.USHORT),
        ("dwFlags", wintypes.DWORD),
        ("hwndTarget", wintypes.HWND),
    ]


class RAWINPUTHEADER(Structure):
    _fields_ = [
        ("dwType", wintypes.DWORD),
        ("dwSize", wintypes.DWORD),
        ("hDevice", wintypes.HANDLE),
        ("wParam", wintypes.WPARAM),
    ]


class RAWMOUSEBUTTONS(Structure):
    _fields_ = [
        ("usButtonFlags", wintypes.USHORT),
        ("usButtonData", wintypes.USHORT),
    ]


class RAWMOUSEUNION(Union):
    _fields_ = [
        ("ulButtons", wintypes.ULONG),
        ("buttons", RAWMOUSEBUTTONS),
    ]


class RAWMOUSE(Structure):
    _anonymous_ = ("union",)
    _fields_ = [
        ("usFlags", wintypes.USHORT),
        ("union", RAWMOUSEUNION),
        ("ulRawButtons", wintypes.ULONG),
        ("lLastX", wintypes.LONG),
        ("lLastY", wintypes.LONG),
        ("ulExtraInformation", wintypes.ULONG),
    ]


class RAWINPUTUNION(Union):
    _fields_ = [("mouse", RAWMOUSE)]


class RAWINPUT(Structure):
    _anonymous_ = ("data",)
    _fields_ = [
        ("header", RAWINPUTHEADER),
        ("data", RAWINPUTUNION),
    ]


class XINPUT_GAMEPAD(Structure):
    _fields_ = [
        ("wButtons", wintypes.WORD),
        ("bLeftTrigger", wintypes.BYTE),
        ("bRightTrigger", wintypes.BYTE),
        ("sThumbLX", wintypes.SHORT),
        ("sThumbLY", wintypes.SHORT),
        ("sThumbRX", wintypes.SHORT),
        ("sThumbRY", wintypes.SHORT),
    ]


class XINPUT_STATE(Structure):
    _fields_ = [("dwPacketNumber", wintypes.DWORD), ("Gamepad", XINPUT_GAMEPAD)]


@dataclass(slots=True)
class _MouseAccumulator:
    dx: float = 0.0
    dy: float = 0.0


class RawInputSink(QtWidgets.QWidget):
    def __init__(self, on_input) -> None:
        super().__init__()
        self._on_input = on_input
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_DontShowOnScreen, True)
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_NativeWindow, True)
        self.hide()

    def nativeEvent(self, event_type, message):
        if sys.platform != "win32":
            return False, 0
        msg = wintypes.MSG.from_address(int(message))
        if msg.message == WM_INPUT:
            self._on_input(msg.lParam)
        return False, 0


class Win32InputSource(QtCore.QObject):
    def __init__(self, parent: QtCore.QObject | None = None) -> None:
        super().__init__(parent)
        self._lock = Lock()
        self._mouse = _MouseAccumulator()
        self._raw_input_active = False
        self._raw_sink: RawInputSink | None = None
        self._xinput = self._load_xinput()

    def start(self) -> None:
        if sys.platform != "win32":
            return
        if self._raw_sink is None:
            self._raw_sink = RawInputSink(self._handle_raw_input)
            self._raw_sink.winId()
        device = RAWINPUTDEVICE(usUsagePage=0x01, usUsage=0x02, dwFlags=RIDEV_INPUTSINK, hwndTarget=int(self._raw_sink.winId()))
        user32.RegisterRawInputDevices(byref(device), 1, sizeof(RAWINPUTDEVICE))

    def snapshot(self, timestamp_ms: float) -> InputSnapshot:
        mouse_dx, mouse_dy = self._consume_mouse()
        gamepad_yaw, gamepad_pitch, gamepad_lateral, gamepad_connected = self._poll_gamepad()
        keyboard_lateral = self._keyboard_lateral()
        return InputSnapshot(
            mouse_dx=mouse_dx,
            mouse_dy=mouse_dy,
            gamepad_yaw=gamepad_yaw,
            gamepad_pitch=gamepad_pitch,
            gamepad_lateral=gamepad_lateral,
            keyboard_lateral=keyboard_lateral,
            timestamp_ms=timestamp_ms,
            raw_input_active=self._raw_input_active,
            gamepad_connected=gamepad_connected,
        )

    def _consume_mouse(self) -> tuple[float, float]:
        with self._lock:
            dx = self._mouse.dx
            dy = self._mouse.dy
            self._mouse.dx = 0.0
            self._mouse.dy = 0.0
        return dx, dy

    def _handle_raw_input(self, lparam: int) -> None:
        size = c_uint(0)
        user32.GetRawInputData(lparam, RID_INPUT, None, byref(size), sizeof(RAWINPUTHEADER))
        if not size.value:
            return
        raw = RAWINPUT()
        if user32.GetRawInputData(lparam, RID_INPUT, byref(raw), byref(size), sizeof(RAWINPUTHEADER)) != size.value:
            return
        if raw.header.dwType != RIM_TYPEMOUSE:
            return
        with self._lock:
            self._mouse.dx += raw.mouse.lLastX
            self._mouse.dy += raw.mouse.lLastY
            self._raw_input_active = True

    def _poll_gamepad(self) -> tuple[float, float, float, bool]:
        if self._xinput is None:
            return 0.0, 0.0, 0.0, False
        state = XINPUT_STATE()
        for user_index in range(4):
            if self._xinput.XInputGetState(user_index, byref(state)) == 0:
                return (
                    _normalize_thumb(state.Gamepad.sThumbRX),
                    -_normalize_thumb(state.Gamepad.sThumbRY),
                    _normalize_thumb(state.Gamepad.sThumbLX),
                    True,
                )
        return 0.0, 0.0, 0.0, False

    @staticmethod
    def _keyboard_lateral() -> float:
        if sys.platform != "win32":
            return 0.0
        left = bool(user32.GetAsyncKeyState(VK_A) & 0x8000 or user32.GetAsyncKeyState(VK_LEFT) & 0x8000)
        right = bool(user32.GetAsyncKeyState(VK_D) & 0x8000 or user32.GetAsyncKeyState(VK_RIGHT) & 0x8000)
        if left == right:
            return 0.0
        return 1.0 if right else -1.0

    @staticmethod
    def _load_xinput():
        if sys.platform != "win32":
            return None
        for library in ("xinput1_4.dll", "xinput9_1_0.dll", "xinput1_3.dll"):
            try:
                dll = WinDLL(library)
            except OSError:
                continue
            dll.XInputGetState.argtypes = [wintypes.DWORD, POINTER(XINPUT_STATE)]
            dll.XInputGetState.restype = wintypes.DWORD
            return dll
        return None


def _normalize_thumb(value: int) -> float:
    magnitude = max(-32768, min(32767, int(value)))
    if abs(magnitude) < 6000:
        return 0.0
    return max(-1.0, min(1.0, magnitude / 32767.0))


if sys.platform == "win32":
    user32.RegisterRawInputDevices.argtypes = [POINTER(RAWINPUTDEVICE), wintypes.UINT, wintypes.UINT]
    user32.RegisterRawInputDevices.restype = wintypes.BOOL
    user32.GetRawInputData.argtypes = [wintypes.HANDLE, wintypes.UINT, c_void_p, POINTER(c_uint), wintypes.UINT]
    user32.GetRawInputData.restype = c_uint
    user32.GetAsyncKeyState.argtypes = [wintypes.INT]
    user32.GetAsyncKeyState.restype = wintypes.SHORT
