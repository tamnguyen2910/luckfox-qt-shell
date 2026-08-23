#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "filescanner.h"
#include "imagebrowser.h"
#include "settings.h"

int main(int argc, char *argv[])
{
    // Embedded linuxfb defaults; overridable from the launcher script.
    // Clock widgets derive Vietnam time (UTC+7) from the UTC epoch in QML,
    // so no TZ env hack is needed (glibc and Qt/QML parse POSIX TZ differently).
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM"))
        qputenv("QT_QPA_PLATFORM",
                QByteArray("linuxfb:fb=/dev/fb0:size=800x480:mmsize=800x480"));
    if (qEnvironmentVariableIsEmpty("QT_QPA_FONTDIR"))
        qputenv("QT_QPA_FONTDIR", QByteArray("/usr/share/fonts/dejavu/"));

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("EmbeddedApps"));
    QCoreApplication::setApplicationName(QStringLiteral("PhotoFrame"));

    Settings settings;
    ImageBrowser browser;
    FileScanner scanner;
    scanner.setDirectory(settings.imageDirectory());

    QObject::connect(&scanner, &FileScanner::filesReady,
                     &browser, &ImageBrowser::onFilesReady);
    browser.setSlideshowInterval(settings.slideshowIntervalMs());
    browser.setShuffle(settings.shuffleEnabled());

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("browser"), &browser);
    engine.rootContext()->setContextProperty(QStringLiteral("scanner"), &scanner);
    engine.rootContext()->setContextProperty(QStringLiteral("settings"), &settings);

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
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
