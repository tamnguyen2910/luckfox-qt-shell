#ifndef AUDIORECORDER_H
#define AUDIORECORDER_H

#include <QObject>
#include <QTimer>
#include <QFile>
#include <QDir>
#include <QDateTime>
#include <alsa/asoundlib.h>

#ifdef __arm__
#define AUDIO_DEVICE "hw:0,0"
#else
#define AUDIO_DEVICE "hw:0,0"
#endif

class AudioRecorder : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool recording READ isRecording NOTIFY recordingChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(int duration READ duration NOTIFY durationChanged)

public:
    explicit AudioRecorder(QObject *parent = nullptr);
    ~AudioRecorder();

    bool isRecording() const { return m_recording; }
    QString status() const { return m_status; }
    int duration() const { return m_duration; }

    Q_INVOKABLE bool startRecording(const QString &filename = "");
    Q_INVOKABLE bool stopRecording();
    Q_INVOKABLE QStringList getRecordings();

signals:
    void recordingChanged();
    void statusChanged();
    void durationChanged();

private slots:
    void updateDuration();

private:
    bool m_recording;
    QString m_status;
    int m_duration;
    QTimer *m_timer;
    QFile m_audioFile;
    snd_pcm_t *m_pcmHandle;
    QString m_currentFile;

    bool setupAudio();
    void cleanupAudio();
};

#endif // AUDIORECORDER_H