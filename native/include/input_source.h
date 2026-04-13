#ifndef INPUT_SOURCE_H
#define INPUT_SOURCE_H

#include "cc_core.h"

#include <QObject>

class RawInputSink;

class Win32InputSource : public QObject {
public:
    explicit Win32InputSource(QObject *parent = nullptr);
    ~Win32InputSource() override;

    void start();
    CCInputSnapshot snapshot(double timestampMs);

    void handleRawInput(qintptr lParam);

private:
    float keyboardLateral() const;
    void loadXInput();
    void pollGamepad(float &yaw, float &pitch, float &lateral, bool &connected) const;

    RawInputSink *m_rawSink = nullptr;
    void *m_xinputLibrary = nullptr;
    void *m_xinputGetState = nullptr;
    mutable double m_mouseDx = 0.0;
    mutable double m_mouseDy = 0.0;
    bool m_rawInputActive = false;
};

#endif
