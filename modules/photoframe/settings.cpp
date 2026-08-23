#include "settings.h"

#include <QSettings>

namespace {
const char kKeyImageDir[] = "viewer/imageDirectory";
const char kKeyIntervalMs[] = "viewer/slideshowIntervalMs";
const char kKeyShuffle[] = "viewer/shuffle";
const char kKeyAutoStart[] = "viewer/slideshowAutoStart";
const char kKeyKenBurns[] = "viewer/kenBurns";
const char kKeyTransition[] = "viewer/transitionMode";
const char kKeyFit[] = "viewer/fitMode";
const char kKeyClockEnabled[] = "viewer/clockEnabled";
const char kKeyClockAnalog[] = "viewer/clockAnalog";
const char kKeyClock24h[] = "viewer/clock24h";
const char kKeyClockPosition[] = "viewer/clockPosition";
const char kKeyPhotoInfo[] = "viewer/photoInfo";
const char kConfigPath[] = "/etc/photoframe.conf";
}

const int Settings::kDefaultIntervalMs = 5000;
const bool Settings::kDefaultShuffle = false;
const bool Settings::kDefaultAutoStart = true;
const bool Settings::kDefaultKenBurns = true;
const int Settings::kDefaultTransitionMode = 0; // Fade
const int Settings::kDefaultFitMode = 0;        // Fit (contain)
const bool Settings::kDefaultClockEnabled = true;
const bool Settings::kDefaultClockAnalog = true;
const bool Settings::kDefaultClock24h = true;
const int Settings::kDefaultClockPosition = 0;   // top-right
const bool Settings::kDefaultPhotoInfo = true;

QSettings *Settings::store()
{
    static QSettings s(QString::fromLatin1(kConfigPath), QSettings::IniFormat);
    return &s;
}

Settings::Settings(QObject *parent)
    : QObject(parent)
{
    if (imageDirectory().isEmpty()) {
        QString dir = qgetenv("IMAGE_VIEWER_DIR");
        if (dir.isEmpty())
            dir = "/root/images";
        setImageDirectory(dir);
    }
}

QString Settings::imageDirectory() const
{
    return store()->value(QLatin1String(kKeyImageDir)).toString();
}

void Settings::setImageDirectory(const QString &path)
{
    if (path == imageDirectory())
        return;
    store()->setValue(QLatin1String(kKeyImageDir), path);
    store()->sync();
    emit imageDirectoryChanged();
}

int Settings::slideshowIntervalMs() const
{
    return store()->value(QLatin1String(kKeyIntervalMs), kDefaultIntervalMs).toInt();
}

void Settings::setSlideshowIntervalMs(int ms)
{
    if (ms < 1000)
        ms = 1000;
    if (ms == slideshowIntervalMs())
        return;
    store()->setValue(QLatin1String(kKeyIntervalMs), ms);
    store()->sync();
    emit slideshowIntervalMsChanged();
}

bool Settings::shuffleEnabled() const
{
    return store()->value(QLatin1String(kKeyShuffle), kDefaultShuffle).toBool();
}

void Settings::setShuffleEnabled(bool on)
{
    if (on == shuffleEnabled())
        return;
    store()->setValue(QLatin1String(kKeyShuffle), on);
    store()->sync();
    emit shuffleEnabledChanged();
}

bool Settings::slideshowAutoStart() const
{
    return store()->value(QLatin1String(kKeyAutoStart), kDefaultAutoStart).toBool();
}

void Settings::setSlideshowAutoStart(bool on)
{
    if (on == slideshowAutoStart())
        return;
    store()->setValue(QLatin1String(kKeyAutoStart), on);
    store()->sync();
    emit slideshowAutoStartChanged();
}

bool Settings::kenBurnsEnabled() const
{
    return store()->value(QLatin1String(kKeyKenBurns), kDefaultKenBurns).toBool();
}

void Settings::setKenBurnsEnabled(bool on)
{
    if (on == kenBurnsEnabled())
        return;
    store()->setValue(QLatin1String(kKeyKenBurns), on);
    store()->sync();
    emit kenBurnsEnabledChanged();
}

int Settings::transitionMode() const
{
    return store()->value(QLatin1String(kKeyTransition), kDefaultTransitionMode).toInt();
}

void Settings::setTransitionMode(int mode)
{
    if (mode == transitionMode())
        return;
    store()->setValue(QLatin1String(kKeyTransition), mode);
    store()->sync();
    emit transitionModeChanged();
}

int Settings::fitMode() const
{
    return store()->value(QLatin1String(kKeyFit), kDefaultFitMode).toInt();
}

void Settings::setFitMode(int mode)
{
    if (mode == fitMode())
        return;
    store()->setValue(QLatin1String(kKeyFit), mode);
    store()->sync();
    emit fitModeChanged();
}

bool Settings::clockEnabled() const
{
    return store()->value(QLatin1String(kKeyClockEnabled), kDefaultClockEnabled).toBool();
}

void Settings::setClockEnabled(bool on)
{
    if (on == clockEnabled())
        return;
    store()->setValue(QLatin1String(kKeyClockEnabled), on);
    store()->sync();
    emit clockEnabledChanged();
}

bool Settings::clockAnalog() const
{
    return store()->value(QLatin1String(kKeyClockAnalog), kDefaultClockAnalog).toBool();
}

void Settings::setClockAnalog(bool on)
{
    if (on == clockAnalog())
        return;
    store()->setValue(QLatin1String(kKeyClockAnalog), on);
    store()->sync();
    emit clockAnalogChanged();
}

bool Settings::clock24h() const
{
    return store()->value(QLatin1String(kKeyClock24h), kDefaultClock24h).toBool();
}

void Settings::setClock24h(bool on)
{
    if (on == clock24h())
        return;
    store()->setValue(QLatin1String(kKeyClock24h), on);
    store()->sync();
    emit clock24hChanged();
}

int Settings::clockPosition() const
{
    return store()->value(QLatin1String(kKeyClockPosition), kDefaultClockPosition).toInt();
}

void Settings::setClockPosition(int pos)
{
    if (pos == clockPosition())
        return;
    store()->setValue(QLatin1String(kKeyClockPosition), pos);
    store()->sync();
    emit clockPositionChanged();
}

bool Settings::photoInfo() const
{
    return store()->value(QLatin1String(kKeyPhotoInfo), kDefaultPhotoInfo).toBool();
}

void Settings::setPhotoInfo(bool on)
{
    if (on == photoInfo())
        return;
    store()->setValue(QLatin1String(kKeyPhotoInfo), on);
    store()->sync();
    emit photoInfoChanged();
}
