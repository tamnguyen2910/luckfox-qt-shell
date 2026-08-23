#ifndef AUDIOPLAYER_H
#define AUDIOPLAYER_H

#include <QObject>
#include <QProcess>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <sys/types.h>   // pid_t for process-group kill

class AudioPlayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(bool isPaused READ isPaused NOTIFY pausedChanged)
    Q_PROPERTY(QString currentFile READ currentFile NOTIFY currentFileChanged)
    Q_PROPERTY(QString currentTitle READ currentTitle NOTIFY currentTitleChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(QStringList playlist READ playlist NOTIFY playlistChanged)
    Q_PROPERTY(QString musicFolderPath READ musicFolderPath NOTIFY musicFolderPathChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(int position READ position NOTIFY positionChanged)
    Q_PROPERTY(int duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(int volume READ volume NOTIFY volumeChanged)

public:
    explicit AudioPlayer(QObject *parent = nullptr);
    ~AudioPlayer();

    bool isPlaying() const { return m_isPlaying; }
    bool isPaused() const { return m_isPaused; }
    QString currentFile() const { return m_currentFile; }
    QString currentTitle() const { return m_currentTitle; }
    QString statusText() const { return m_statusText; }
    QStringList playlist() const { return m_playlist; }
    QString musicFolderPath() const { return m_musicFolderPath; }
    int currentIndex() const { return m_currentIndex; }
    int position() const { return m_position; }
    int duration() const { return m_duration; }
    int volume() const { return m_volume; }

public slots:
    void play(const QString &filePath = QString());
    void pause();
    void resume();
    void stop();
    void next();
    void previous();
    void setVolume(int volume);
    void volumeUp();
    void volumeDown();
    void scanMusicFolder(const QString &folderPath);
    void playAtIndex(int index);
    void seek(int position);

signals:
    void playingChanged();
    void pausedChanged();
    void currentFileChanged();
    void currentTitleChanged();
    void statusTextChanged();
    void playlistChanged();
    void musicFolderPathChanged();
    void currentIndexChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void sliderValueChanged();
    void error(const QString &errorString);

private slots:
    void onProcessFinished(int exitCode);
    void onProcessError(QProcess::ProcessError error);
    void updatePosition();
    void readProcessOutput();
    void flushVolume();               // NEW: async amixer batch, invoked by debounce timer

private:
    QProcess *m_process;
    QTimer *m_positionTimer;
    QTimer *m_volumeDebounceTimer;   // NEW: debounce rapid volume slider events
    int     m_pendingVolume;         // NEW: debounced target volume (0-100)
    int     m_lastAppliedVolume;     // NEW: last value sent to amixer (skip duplicates)
    bool m_isPlaying;
    bool m_isPaused;
    QString m_currentFile;
    QString m_currentTitle;
    QString m_statusText;
    QStringList m_playlist;
    QString m_musicFolderPath;   // /media/music (shown in playlist zone)
    int m_currentIndex;
    int m_position;
    int m_duration;
    int m_volume;
    qint64 m_startTime;
    int m_pausedPosition;  // Position when paused
    pid_t m_processGroupId;  // PGID of mpg123 child (own group → group-kill kills orphan-safe)

    void updateStatus(const QString &status);
    QString findAudioPlayer();
    void startPlayback();
    QString extractTitle(const QString &filePath);
    int estimateDuration(const QString &filePath);
    void killProcessGroup();  // SIGTERM to whole process group of mpg123
};

#endif // AUDIOPLAYER_H
