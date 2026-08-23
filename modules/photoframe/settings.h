#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QString>

class QSettings;

// Persistent app settings, stored in /etc/photoframe.conf
// (survives reboots, unlike ~/.config which was wiped together with /root).
class Settings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString imageDirectory READ imageDirectory NOTIFY imageDirectoryChanged)
    Q_PROPERTY(int slideshowIntervalMs READ slideshowIntervalMs WRITE setSlideshowIntervalMs NOTIFY slideshowIntervalMsChanged)
    Q_PROPERTY(bool shuffleEnabled READ shuffleEnabled WRITE setShuffleEnabled NOTIFY shuffleEnabledChanged)
    Q_PROPERTY(bool slideshowAutoStart READ slideshowAutoStart WRITE setSlideshowAutoStart NOTIFY slideshowAutoStartChanged)
    Q_PROPERTY(bool kenBurnsEnabled READ kenBurnsEnabled WRITE setKenBurnsEnabled NOTIFY kenBurnsEnabledChanged)
    Q_PROPERTY(int transitionMode READ transitionMode WRITE setTransitionMode NOTIFY transitionModeChanged)
    Q_PROPERTY(int fitMode READ fitMode WRITE setFitMode NOTIFY fitModeChanged)
    Q_PROPERTY(bool clockEnabled READ clockEnabled WRITE setClockEnabled NOTIFY clockEnabledChanged)
    Q_PROPERTY(bool clockAnalog READ clockAnalog WRITE setClockAnalog NOTIFY clockAnalogChanged)
    Q_PROPERTY(bool clock24h READ clock24h WRITE setClock24h NOTIFY clock24hChanged)
    Q_PROPERTY(int clockPosition READ clockPosition WRITE setClockPosition NOTIFY clockPositionChanged)
    Q_PROPERTY(bool photoInfo READ photoInfo WRITE setPhotoInfo NOTIFY photoInfoChanged)

public:
    explicit Settings(QObject *parent = nullptr);

    QString imageDirectory() const;
    void setImageDirectory(const QString &path);

    int slideshowIntervalMs() const;
    void setSlideshowIntervalMs(int ms);

    bool shuffleEnabled() const;
    void setShuffleEnabled(bool on);

    bool slideshowAutoStart() const;
    void setSlideshowAutoStart(bool on);

    bool kenBurnsEnabled() const;
    void setKenBurnsEnabled(bool on);

    int transitionMode() const;
    void setTransitionMode(int mode);

    int fitMode() const;
    void setFitMode(int mode);

    bool clockEnabled() const;
    void setClockEnabled(bool on);

    bool clockAnalog() const;
    void setClockAnalog(bool on);

    bool clock24h() const;
    void setClock24h(bool on);

    int clockPosition() const;
    void setClockPosition(int pos);

    bool photoInfo() const;
    void setPhotoInfo(bool on);

signals:
    void imageDirectoryChanged();
    void slideshowIntervalMsChanged();
    void shuffleEnabledChanged();
    void slideshowAutoStartChanged();
    void kenBurnsEnabledChanged();
    void transitionModeChanged();
    void fitModeChanged();
    void clockEnabledChanged();
    void clockAnalogChanged();
    void clock24hChanged();
    void clockPositionChanged();
    void photoInfoChanged();

private:
    static QSettings *store();

    static const int kDefaultIntervalMs;
    static const bool kDefaultShuffle;
    static const bool kDefaultAutoStart;
    static const bool kDefaultKenBurns;
    static const int kDefaultTransitionMode;
    static const int kDefaultFitMode;
    static const bool kDefaultClockEnabled;
    static const bool kDefaultClockAnalog;
    static const bool kDefaultClock24h;
    static const int kDefaultClockPosition;
    static const bool kDefaultPhotoInfo;
};

#endif // SETTINGS_H
