#include "VoicePlayer.h"
#include <QDebug>
#include <QCoreApplication>
#include <QFileInfo>

VoicePlayer::VoicePlayer(QObject *parent)
    : QObject(parent)
    , m_playing(false)
    , m_status("Ready")
    , m_duration(0)
    , m_timer(new QTimer(this))
    , m_pcmHandle(nullptr)
{
    connect(m_timer, &QTimer::timeout, [this]() {
        m_duration++;
        emit durationChanged();
    });
    m_timer->setInterval(1000);
}

VoicePlayer::~VoicePlayer()
{
    if (m_playing) {
        stopPlayback();
    }
    cleanupAudio();
}

bool VoicePlayer::setupAudio()
{
    int err;
    snd_pcm_hw_params_t *params;

    // Open PCM device for playback
    if ((err = snd_pcm_open(&m_pcmHandle, "hw:0,0", SND_PCM_STREAM_PLAYBACK, 0)) < 0) {
        qCritical() << "Cannot open audio device for playback:" << snd_strerror(err);
        return false;
    }

    snd_pcm_hw_params_alloca(&params);

    if ((err = snd_pcm_hw_params_any(m_pcmHandle, params)) < 0) {
        qCritical() << "Cannot initialize hardware parameter structure:" << snd_strerror(err);
        return false;
    }

    if ((err = snd_pcm_hw_params_set_access(m_pcmHandle, params, SND_PCM_ACCESS_RW_INTERLEAVED)) < 0) {
        qCritical() << "Error setting access:" << snd_strerror(err);
        return false;
    }

    if ((err = snd_pcm_hw_params_set_format(m_pcmHandle, params, SND_PCM_FORMAT_S16_LE)) < 0) {
        qCritical() << "Error setting format:" << snd_strerror(err);
        return false;
    }

    if ((err = snd_pcm_hw_params_set_channels(m_pcmHandle, params, 2)) < 0) {
        qCritical() << "Error setting channels:" << snd_strerror(err);
        return false;
    }

    unsigned int sampleRate = 48000;
    if ((err = snd_pcm_hw_params_set_rate_near(m_pcmHandle, params, &sampleRate, 0)) < 0) {
        qCritical() << "Error setting rate:" << snd_strerror(err);
        return false;
    }

    if ((err = snd_pcm_hw_params(m_pcmHandle, params)) < 0) {
        qCritical() << "Error setting parameters:" << snd_strerror(err);
        return false;
    }

    if ((err = snd_pcm_prepare(m_pcmHandle)) < 0) {
        qCritical() << "Cannot prepare audio interface for use:" << snd_strerror(err);
        return false;
    }

    return true;
}

void VoicePlayer::cleanupAudio()
{
    if (m_pcmHandle) {
        snd_pcm_drain(m_pcmHandle);
        snd_pcm_close(m_pcmHandle);
        m_pcmHandle = nullptr;
    }
}

bool VoicePlayer::playFile(const QString &filename)
{
    QFileInfo fileInfo(filename);
    if (!fileInfo.exists()) {
        m_status = "File not found: " + filename;
        emit statusChanged();
        return false;
    }

    if (m_playing) {
        stopPlayback();
    }

    // Open file
    m_audioFile.setFileName(filename);
    if (!m_audioFile.open(QIODevice::ReadOnly)) {
        m_status = "Cannot open file";
        emit statusChanged();
        return false;
    }

    // Skip WAV header
    char header[44];
    m_audioFile.read(header, 44);

    // Setup audio
    if (!setupAudio()) {
        m_status = "Audio setup failed";
        emit statusChanged();
        m_audioFile.close();
        cleanupAudio();
        return false;
    }

    m_playing = true;
    m_duration = 0;
    m_timer->start();
    m_status = "Playing: " + fileInfo.fileName();
    emit playingChanged();
    emit statusChanged();
    emit durationChanged();

    // Play audio
    char buffer[4096];
    qint64 bytesRead;

    while (m_playing && !m_audioFile.atEnd()) {
        bytesRead = m_audioFile.read(buffer, sizeof(buffer));
        if (bytesRead > 0) {
            snd_pcm_sframes_t frames = snd_pcm_writei(m_pcmHandle, buffer, bytesRead / 4);
            if (frames < 0) {
                frames = snd_pcm_recover(m_pcmHandle, frames, 0);
                if (frames < 0) {
                    qWarning() << "Audio write error:" << snd_strerror(frames);
                    break;
                }
            }
        }
        QCoreApplication::processEvents(QEventLoop::AllEvents, 10);
    }

    m_audioFile.close();
    cleanupAudio();

    m_playing = false;
    m_timer->stop();
    emit playingChanged();
    m_status = "Playback completed";
    emit statusChanged();

    return true;
}

bool VoicePlayer::stopPlayback()
{
    if (!m_playing) {
        return false;
    }

    m_playing = false;
    m_timer->stop();

    if (m_audioFile.isOpen()) {
        m_audioFile.close();
    }

    cleanupAudio();

    emit playingChanged();
    m_status = "Playback stopped";
    emit statusChanged();

    return true;
}