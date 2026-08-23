#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>

#include "settings.h"
#include "apptheme.h"
#include "imagebrowser.h"
#include "filescanner.h"
#include "AudioRecorder.h"
#include "modules/music/audioplayer.h"
#include "VoicePlayer.h"
#include "DeviceManager.h"
#include "lunarbackend.h"
#include "wifimanager.h"
#include "sysinforeader.h"
#include "wireframecanvas.h"

int main(int argc, char *argv[])
{
    // Embedded linuxfb defaults; overridable from the launcher script.
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM"))
        qputenv("QT_QPA_PLATFORM",
                QByteArray("linuxfb:fb=/dev/fb0:size=800x480:mmsize=800x480"));
    if (qEnvironmentVariableIsEmpty("QT_QPA_FONTDIR"))
        qputenv("QT_QPA_FONTDIR", QByteArray("/usr/share/fonts/dejavu/"));
    // Fallback font dir for Unicode glyphs (Vietnamese diacritics etc.)
    qputenv("QT_QPA_FONTDIR_FALLBACK", QByteArray("/usr/share/fonts/dejavu/"));
    qputenv("LANG", QByteArray("C.UTF-8"));   // UTF-8 locale — stable Vietnamese rendering
    qputenv("QT_SCALE_FACTOR", QByteArray("1.0"));
    qputenv("QT_FONT_DPI", QByteArray("96"));
    qputenv("TZ", QByteArray("Asia/Ho_Chi_Minh"));
    ::tzset();

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("EmbeddedApps"));
    QCoreApplication::setApplicationName(QStringLiteral("LuckfoxShell"));

    // ---- photo-frame backends ----
    Settings settings;
    AppTheme appTheme;            // global light/dark switch (QML "appTheme")
    ImageBrowser browser;
    FileScanner scanner;
    scanner.setDirectory(settings.imageDirectory());

    QObject::connect(&scanner, &FileScanner::filesReady,
                     &browser, &ImageBrowser::onFilesReady);
    browser.setSlideshowInterval(settings.slideshowIntervalMs());
    browser.setShuffle(settings.shuffleEnabled());

    // ---- voice-test backends ----
    AudioRecorder recorder;
    AudioPlayer player;           // Music player (mpg123-based)
    VoicePlayer voicePlayer;      // Voice test player (ALSA raw WAV)

    DeviceManager deviceManager;

    // ---- calendar (lunar) backend ----
    LunarBackend lunarBackend;

    // ---- wifi backend ----
    WifiManager wifiManager;

    // ---- dashboard backend (sysmon) ----
    SysInfoReader sysInfo;

    // ---- wireframe (3D) backend ----
    qmlRegisterType<WireframeCanvas>("Wireframe", 1, 0, "WireframeCanvas");

    QQmlApplicationEngine engine;
    // GPU detection: tắt FastBlur / glassmorphism nếu render bằng software
    const bool gpuAccelerated =
            QQuickWindow::sceneGraphBackend() != QLatin1String("software");
    engine.rootContext()->setContextProperty(QStringLiteral("gpuAccelerated"),
                                             gpuAccelerated);
    engine.rootContext()->setContextProperty(QStringLiteral("appTheme"), &appTheme);
    engine.rootContext()->setContextProperty(QStringLiteral("browser"), &browser);
    engine.rootContext()->setContextProperty(QStringLiteral("scanner"), &scanner);
    engine.rootContext()->setContextProperty(QStringLiteral("settings"), &settings);
    engine.rootContext()->setContextProperty(QStringLiteral("audioRecorder"), &recorder);
    engine.rootContext()->setContextProperty(QStringLiteral("audioPlayer"), &player);       // Music tab
    engine.rootContext()->setContextProperty(QStringLiteral("voicePlayer"), &voicePlayer); // Recorder tab
    engine.rootContext()->setContextProperty(QStringLiteral("deviceManager"), &deviceManager);
    engine.rootContext()->setContextProperty(QStringLiteral("LunarBackend"), &lunarBackend);
    engine.rootContext()->setContextProperty(QStringLiteral("wifiManager"), &wifiManager);
    engine.rootContext()->setContextProperty(QStringLiteral("sysInfo"), &sysInfo);

    const QUrl url(QStringLiteral("qrc:/shell/shell.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    if (settings.slideshowAutoStart()) {
        browser.setAutoStart(true);
        browser.startSlideshow(); // no-op until files arrive, retried in onFilesReady
    }

    return app.exec();
}
