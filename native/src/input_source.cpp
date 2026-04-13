#include "input_source.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QWidget>

#ifdef Q_OS_WIN
#include <windows.h>
#include <xinput.h>
#endif

namespace {

#ifdef Q_OS_WIN
static constexpr UINT kRidInput = 0x10000003;
static constexpr DWORD kRidevInputSink = 0x00000100;
static constexpr UINT kWmInput = 0x00FF;
static constexpr int kVkA = 0x41;
static constexpr int kVkD = 0x44;
static constexpr int kVkLeft = 0x25;
static constexpr int kVkRight = 0x27;

using XInputGetStateFn = DWORD(WINAPI *)(DWORD, XINPUT_STATE *);

float normalizeThumb(SHORT value)
{
    const int magnitude = qBound(-32768, static_cast<int>(value), 32767);
    if (qAbs(magnitude) < 6000) {
        return 0.0f;
    }
    return qBound(-1.0f, static_cast<float>(magnitude) / 32767.0f, 1.0f);
}
#endif

QString smokeProgressPath()
{
    const QString runtimePath = qEnvironmentVariable("CC_RUNTIME_PROGRESS_PATH");
    if (!runtimePath.isEmpty()) {
        return runtimePath;
    }
    return qEnvironmentVariable("CC_SMOKE_PROGRESS_PATH");
}

void appendSmokeProgress(const QString &message)
{
    const QString path = smokeProgressPath();
    if (path.isEmpty()) {
        return;
    }

    QFileInfo info(path);
    QDir().mkpath(info.absolutePath());
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append)) {
        return;
    }

    file.write(message.toUtf8());
    file.write("\n");
    file.close();
}
} // namespace

class RawInputSink : public QWidget {
public:
    explicit RawInputSink(Win32InputSource *owner)
        : QWidget(nullptr)
        , m_owner(owner)
    {
        setAttribute(Qt::WA_DontShowOnScreen, true);
        setAttribute(Qt::WA_NativeWindow, true);
        hide();
    }

protected:
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    bool nativeEvent(const QByteArray &eventType, void *message, qintptr *result) override
#else
    bool nativeEvent(const QByteArray &eventType, void *message, long *result) override
#endif
    {
        Q_UNUSED(eventType)
#ifdef Q_OS_WIN
        MSG *msg = static_cast<MSG *>(message);
        if (msg != nullptr && msg->message == kWmInput && m_owner != nullptr) {
            m_owner->handleRawInput(msg->lParam);
        }
        if (result != nullptr) {
            *result = 0;
        }
#else
        Q_UNUSED(message)
        Q_UNUSED(result)
#endif
        return false;
    }

private:
    Win32InputSource *m_owner = nullptr;
};

Win32InputSource::Win32InputSource(QObject *parent)
    : QObject(parent)
{
    appendSmokeProgress("input_source: constructor entered");
    if (!qEnvironmentVariable("CC_SMOKE_TEST_OUTPUT").isEmpty()) {
        appendSmokeProgress("input_source: skipping XInput load for smoke");
        return;
    }

    loadXInput();
    appendSmokeProgress("input_source: XInput load complete");
}

Win32InputSource::~Win32InputSource()
{
#ifdef Q_OS_WIN
    if (m_xinputLibrary != nullptr) {
        FreeLibrary(static_cast<HMODULE>(m_xinputLibrary));
    }
#endif
}

void Win32InputSource::start()
{
#ifdef Q_OS_WIN
    if (m_rawSink == nullptr) {
        m_rawSink = new RawInputSink(this);
        m_rawSink->winId();
    }
    RAWINPUTDEVICE device{};
    device.usUsagePage = 0x01;
    device.usUsage = 0x02;
    device.dwFlags = kRidevInputSink;
    device.hwndTarget = reinterpret_cast<HWND>(m_rawSink->winId());
    RegisterRawInputDevices(&device, 1, sizeof(device));
#endif
}

CCInputSnapshot Win32InputSource::snapshot(double timestampMs)
{
    CCInputSnapshot snapshot{};
    float gamepadYaw = 0.0f;
    float gamepadPitch = 0.0f;
    float gamepadLateral = 0.0f;
    bool gamepadConnected = false;

    pollGamepad(gamepadYaw, gamepadPitch, gamepadLateral, gamepadConnected);

    snapshot.mouse_dx = static_cast<float>(m_mouseDx);
    snapshot.mouse_dy = static_cast<float>(m_mouseDy);
    snapshot.gamepad_yaw = gamepadYaw;
    snapshot.gamepad_pitch = gamepadPitch;
    snapshot.gamepad_lateral = gamepadLateral;
    snapshot.keyboard_lateral = keyboardLateral();
    snapshot.timestamp_ms = static_cast<float>(timestampMs);
    snapshot.raw_input_active = m_rawInputActive ? 1 : 0;
    snapshot.gamepad_connected = gamepadConnected ? 1 : 0;

    m_mouseDx = 0.0;
    m_mouseDy = 0.0;
    return snapshot;
}

void Win32InputSource::handleRawInput(qintptr lParam)
{
#ifdef Q_OS_WIN
    UINT size = 0;
    GetRawInputData(reinterpret_cast<HRAWINPUT>(lParam), kRidInput, nullptr, &size, sizeof(RAWINPUTHEADER));
    if (size == 0) {
        return;
    }

    QByteArray buffer;
    buffer.resize(static_cast<int>(size));
    if (GetRawInputData(reinterpret_cast<HRAWINPUT>(lParam), kRidInput, buffer.data(), &size, sizeof(RAWINPUTHEADER)) != size) {
        return;
    }

    RAWINPUT *raw = reinterpret_cast<RAWINPUT *>(buffer.data());
    if (raw->header.dwType != RIM_TYPEMOUSE) {
        return;
    }

    m_mouseDx += raw->data.mouse.lLastX;
    m_mouseDy += raw->data.mouse.lLastY;
    m_rawInputActive = true;
#else
    Q_UNUSED(lParam)
#endif
}

float Win32InputSource::keyboardLateral() const
{
#ifdef Q_OS_WIN
    const bool left = (GetAsyncKeyState(kVkA) & 0x8000) || (GetAsyncKeyState(kVkLeft) & 0x8000);
    const bool right = (GetAsyncKeyState(kVkD) & 0x8000) || (GetAsyncKeyState(kVkRight) & 0x8000);
    if (left == right) {
        return 0.0f;
    }
    return right ? 1.0f : -1.0f;
#else
    return 0.0f;
#endif
}

void Win32InputSource::loadXInput()
{
#ifdef Q_OS_WIN
    for (const wchar_t *name : {L"xinput1_4.dll", L"xinput9_1_0.dll", L"xinput1_3.dll"}) {
        HMODULE library = LoadLibraryW(name);
        if (library == nullptr) {
            continue;
        }
        void *symbol = reinterpret_cast<void *>(GetProcAddress(library, "XInputGetState"));
        if (symbol != nullptr) {
            m_xinputLibrary = library;
            m_xinputGetState = symbol;
            return;
        }
        FreeLibrary(library);
    }
#endif
}

void Win32InputSource::pollGamepad(float &yaw, float &pitch, float &lateral, bool &connected) const
{
#ifdef Q_OS_WIN
    XINPUT_STATE state{};
    if (m_xinputGetState == nullptr) {
        return;
    }

    auto fn = reinterpret_cast<XInputGetStateFn>(m_xinputGetState);
    for (DWORD index = 0; index < 4; ++index) {
        if (fn(index, &state) == ERROR_SUCCESS) {
            yaw = normalizeThumb(state.Gamepad.sThumbRX);
            pitch = -normalizeThumb(state.Gamepad.sThumbRY);
            lateral = normalizeThumb(state.Gamepad.sThumbLX);
            connected = true;
            return;
        }
    }
#else
    Q_UNUSED(yaw)
    Q_UNUSED(pitch)
    Q_UNUSED(lateral)
    Q_UNUSED(connected)
#endif
}
