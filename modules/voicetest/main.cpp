#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSurfaceFormat>
#include "AudioRecorder.h"
#include "AudioPlayer.h"
#include "DeviceManager.h"

int main(int argc, char *argv[])
{
    // Set platform to linuxfb for embedded systems (Luckfox has no GPU eglfs)
    qputenv("QT_QPA_PLATFORM", "linuxfb");
    
    // Disable mouse events (touchscreen only)
    qputenv("QT_QPA_EGLFS_HIDECURSOR", "1");
    qputenv("QT_QPA_EGLFS_PHYSICAL_WIDTH", "800");
    qputenv("QT_QPA_EGLFS_PHYSICAL_HEIGHT", "480");

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    
    QGuiApplication app(argc, argv);

    // Create QML engine and context
    QQmlApplicationEngine engine;
    
    // Create application objects
    AudioRecorder recorder;
    AudioPlayer player;
    DeviceManager deviceManager;

    // Expose objects to QML
    engine.rootContext()->setContextProperty("audioRecorder", &recorder);
    engine.rootContext()->setContextProperty("audioPlayer", &player);
    engine.rootContext()->setContextProperty("deviceManager", &deviceManager);

    // Load QML
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}