QT += quick svg

CONFIG += c++17

DEFINES += QT_DEPRECATED_WARNINGS

TARGET = luckfox-shell
TEMPLATE = app

# Source files
SOURCES += \
    src/main.cpp \
    src/apptheme.cpp \
    src/lunar.cpp \
    modules/photoframe/filescanner.cpp \
    modules/photoframe/imagebrowser.cpp \
    modules/photoframe/settings.cpp \
    modules/voicetest/AudioRecorder.cpp \
    modules/voicetest/VoicePlayer.cpp \
    modules/voicetest/DeviceManager.cpp \
    modules/wifi/wifimanager.cpp \
    modules/dashboard/src/sysinforeader.cpp \
    modules/dashboard/src/FastDataWorker.cpp \
    modules/dashboard/src/SlowDataWorker.cpp \
    modules/dashboard/src/SensorWorker.cpp \
    modules/music/audioplayer.cpp \
    modules/wireframe/wireframecanvas.cpp

HEADERS += \
    src/lunarbackend.h \
    src/apptheme.h \
    modules/photoframe/filescanner.h \
    modules/photoframe/imagebrowser.h \
    modules/photoframe/settings.h \
    modules/voicetest/AudioRecorder.h \
    modules/voicetest/DeviceManager.h \
    modules/voicetest/VoicePlayer.h \
    modules/wifi/wifimanager.h \
    modules/dashboard/src/SystemData.h \
    modules/dashboard/src/SysInfoWorker.h \
    modules/dashboard/src/sysinforeader.h \
    modules/dashboard/src/FastDataWorker.h \
    modules/dashboard/src/SlowDataWorker.h \
    modules/dashboard/src/SensorWorker.h \
    modules/music/audioplayer.h \
    modules/wireframe/wireframecanvas.h \
    modules/wireframe/matrix4.h

INCLUDEPATH += modules/photoframe modules/voicetest src modules/wifi modules/dashboard/src modules/wireframe

# voice-test ALSA backend
LIBS += -lasound

# Resources - each module gets its own prefix to avoid collisions
RESOURCES += \
    qml/shell.qrc \
    modules/photoframe/photoframe.qrc \
    modules/voicetest/voicetest.qrc \
    modules/calendar/calendar.qrc \
    modules/wifi/wifi.qrc \
    modules/dashboard/dashboard.qrc \
    modules/music/music.qrc \
    modules/wireframe/wireframe.qrc

# RV1106 toolchain needs non-compressed resources (zlib compressed QML fails to link)
QMAKE_RCC_FLAGS += -no-compress

# Deployment
target.path = /root
INSTALLS += target