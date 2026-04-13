QT += core gui widgets quick qml quickcontrols2

CONFIG += c11 c++17
CONFIG -= app_bundle

TEMPLATE = app
TARGET = ComfortCues

DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000

single_exe {
    DEFINES += CC_TRUE_SINGLE_EXE
    QTPLUGIN += qwindows
    QTPLUGIN += qico
    QTPLUGIN += qjpeg
    QTPLUGIN += qwindowsvistastyle
    QTPLUGIN += qmlplugin
    QTPLUGIN += modelsplugin
    QTPLUGIN += qtquick2plugin
    QTPLUGIN += windowplugin
    QTPLUGIN += qquicklayoutsplugin
    QTPLUGIN += qtquickcontrols2plugin
    QTPLUGIN += qtquicktemplates2plugin
}

INCLUDEPATH += $$PWD/include

!equals($$(CC_QMAKE_MOC), "") {
    QMAKE_MOC = $$(CC_QMAKE_MOC)
}

!equals($$(CC_QMAKE_UIC), "") {
    QMAKE_UIC = $$(CC_QMAKE_UIC)
}

!equals($$(CC_QMAKE_RCC), "") {
    QMAKE_RCC = $$(CC_QMAKE_RCC)
}

HEADERS += \
    $$PWD/include/app_controller.h \
    $$PWD/include/app_state.h \
    $$PWD/include/cc_core.h \
    $$PWD/include/input_source.h \
    $$PWD/include/models.h \
    $$PWD/include/overlay_utils.h \
    $$PWD/include/profile_store.h \
    $$PWD/include/runtime_service.h \
    $$PWD/include/window_tracker.h

SOURCES += \
    $$PWD/src/app_controller.cpp \
    $$PWD/src/app_state.cpp \
    $$PWD/src/cc_cues.c \
    $$PWD/src/cc_signal.c \
    $$PWD/src/input_source.cpp \
    $$PWD/src/main.cpp \
    $$PWD/src/overlay_utils.cpp \
    $$PWD/src/profile_store.cpp \
    $$PWD/src/runtime_service.cpp \
    $$PWD/src/window_tracker.cpp

RESOURCES += $$PWD/resources.qrc

win32 {
    RC_ICONS = ../src/comfort_cues/ui/assets/comfort-cues.ico
    LIBS += -ldwmapi user32.lib
}
