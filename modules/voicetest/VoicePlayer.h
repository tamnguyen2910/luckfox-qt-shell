#ifndef VOICEPLAYER_H
#define VOICEPLAYER_H

#include <QObject>
#include <QTimer>
#include <QFile>
#include <alsa/asoundlib.h>

class VoicePlayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(int duration READ duration NOTIFY durationChanged)

public:
    explicit VoicePlayer(QObject *parent = nullptr);
    ~VoicePlayer();

    bool isPlaying() const { return m_playing; }
    QString status() const { return m_status; }
    int duration() const { return m_duration; }

    Q_INVOKABLE bool playFile(const QString &filename);
    Q_INVOKABLE bool stopPlayback();

signals:
    void playingChanged();
    void statusChanged();
    void durationChanged();

private:
    bool m_playing;
    QString m_status;
    int m_duration;
    QTimer *m_timer;
    snd_pcm_t *m_pcmHandle;
    QFile m_audioFile;

    bool setupAudio();
    void cleanupAudio();
};

#endif // VOICEPLAYER_H