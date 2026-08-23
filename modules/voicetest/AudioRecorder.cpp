#include "AudioRecorder.h"
#include <QDebug>
#include <QDir>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QEventLoop>

AudioRecorder::AudioRecorder(QObject *parent)
    : QObject(parent)
    , m_recording(false)
    , m_status("Ready")
    , m_duration(0)
    , m_timer(new QTimer(this))
    , m_pcmHandle(nullptr)
{
    connect(m_timer, &QTimer::timeout, this, &AudioRecorder::updateDuration);
    m_timer->setInterval(1000); // Update every second
}

AudioRecorder::~AudioRecorder()
{
    if (m_recording) {
        stopRecording();
    }
    cleanupAudio();
}

bool AudioRecorder::setupAudio()
{
    int err;
    snd_pcm_hw_params_t *params;
    
    // Open PCM device for recording
    if ((err = snd_pcm_open(&m_pcmHandle, AUDIO_DEVICE, SND_PCM_STREAM_CAPTURE, 0)) < 0) {
        qCritical() << "Cannot open audio device" << AUDIO_DEVICE << snd_strerror(err);
        return false;
    }

    // Allocate hardware parameters
    snd_pcm_hw_params_alloca(&params);
    
    // Fill parameters
    if ((err = snd_pcm_hw_params_any(m_pcmHandle, params)) < 0) {
        qCritical() << "Cannot initialize hardware parameter structure:" << snd_strerror(err);
        return false;
    }

    // Set access type - interleaved
    if ((err = snd_pcm_hw_params_set_access(m_pcmHandle, params, SND_PCM_ACCESS_RW_INTERLEAVED)) < 0) {
        qCritical() << "Error setting access:" << snd_strerror(err);
        return false;
    }

    // Set sample format
    if ((err = snd_pcm_hw_params_set_format(m_pcmHandle, params, SND_PCM_FORMAT_S16_LE)) < 0) {
        qCritical() << "Error setting format:" << snd_strerror(err);
        return false;
    }

    // Set channel count (stereo)
    if ((err = snd_pcm_hw_params_set_channels(m_pcmHandle, params, 2)) < 0) {
        qCritical() << "Error setting channels:" << snd_strerror(err);
        return false;
    }

    // Set sample rate (48kHz)
    unsigned int sampleRate = 48000;
    if ((err = snd_pcm_hw_params_set_rate_near(m_pcmHandle, params, &sampleRate, 0)) < 0) {
        qCritical() << "Error setting rate:" << snd_strerror(err);
        return false;
    }

    // Apply parameters
    if ((err = snd_pcm_hw_params(m_pcmHandle, params)) < 0) {
        qCritical() << "Error setting parameters:" << snd_strerror(err);
        return false;
    }

    // Prepare PCM device
    if ((err = snd_pcm_prepare(m_pcmHandle)) < 0) {
        qCritical() << "Cannot prepare audio interface for use:" << snd_strerror(err);
        return false;
    }

    return true;
}

void AudioRecorder::cleanupAudio()
{
    if (m_pcmHandle) {
        snd_pcm_drain(m_pcmHandle);
        snd_pcm_close(m_pcmHandle);
        m_pcmHandle = nullptr;
    }
}

bool AudioRecorder::startRecording(const QString &filename)
{
    if (m_recording) {
        stopRecording();
    }

    // Generate filename if not provided
    if (filename.isEmpty()) {
        QString recordingsDir = QDir::homePath() + "/recordings";
        QDir dir(recordingsDir);
        if (!dir.exists()) {
            dir.mkpath(".");
        }
        m_currentFile = recordingsDir + "/recording_" + 
                       QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss") + ".wav";
    } else {
        m_currentFile = filename;
    }

    // Initialize audio
    if (!setupAudio()) {
        m_status = "Audio setup failed";
        emit statusChanged();
        return false;
    }

    // Open output file
    m_audioFile.setFileName(m_currentFile);
    if (!m_audioFile.open(QIODevice::WriteOnly)) {
        qCritical() << "Cannot open file for writing:" << m_currentFile;
        m_status = "Cannot create file";
        emit statusChanged();
        cleanupAudio();
        return false;
    }

    m_recording = true;
    m_duration = 0;
    m_timer->start();
    m_status = "Recording...";
    emit recordingChanged();
    emit statusChanged();
    emit durationChanged();

    // Write WAV header (simplified)
    char header[44] = {
        'R', 'I', 'F', 'F', 0, 0, 0, 0, 'W', 'A', 'V', 'E',
        'f', 'm', 't', ' ', 16, 0, 0, 0, 1, 0, 2, 0,
        0x00, 0x00, 0x17, 0x73, 0x00, 0x00, 0x2E, 0x00,
        0x10, 'd', 'a', 't', 'a', 0, 0, 0, 0
    };
    m_audioFile.write(header, 44);

    // Start recording thread (simplified synchronous version)
    snd_pcm_sframes_t frames;
    char buffer[4096];
    
    while (m_recording) {
        frames = snd_pcm_readi(m_pcmHandle, buffer, 256);
        if (frames < 0) {
            frames = snd_pcm_recover(m_pcmHandle, frames, 0);
            if (frames < 0) {
                qWarning() << "Audio read error:" << snd_strerror(frames);
                break;
            }
        }
        
        if (frames > 0) {
            m_audioFile.write(buffer, frames * 4); // 16-bit stereo = 4 bytes per frame
        }
        
        QCoreApplication::processEvents(QEventLoop::AllEvents, 10);
    }

    m_audioFile.close();
    cleanupAudio();

    m_status = "Recording completed";
    emit statusChanged();
    m_timer->stop();
    
    return true;
}

bool AudioRecorder::stopRecording()
{
    if (!m_recording) {
        return false;
    }

    m_recording = false;
    m_timer->stop();

    // Patch WAV header with correct sizes (reopen ReadWrite — file was WriteOnly)
    if (m_audioFile.isOpen()) {
        m_audioFile.close();
    }
    m_audioFile.setFileName(m_currentFile);
    if (m_audioFile.open(QIODevice::ReadWrite)) {
        QByteArray data = m_audioFile.readAll();
        qint64 dataSize = data.size() - 44;

        m_audioFile.seek(0);
        quint32 fileSize = dataSize + 36;
        m_audioFile.write(reinterpret_cast<const char*>(&fileSize), 4);
        m_audioFile.write(reinterpret_cast<const char*>(&dataSize), 4);
        m_audioFile.close();
    }

    emit recordingChanged();
    m_status = "Recording stopped";
    emit statusChanged();
    
    return true;
}

void AudioRecorder::updateDuration()
{
    m_duration++;
    emit durationChanged();
}

QStringList AudioRecorder::getRecordings()
{
    QString recordingsDir = QDir::homePath() + "/recordings";
    QDir dir(recordingsDir);
    QStringList filters;
    filters << "*.wav";
    QStringList files = dir.entryList(filters, QDir::Files, QDir::Time);
    
    QStringList fullPath;
    for (const QString &file : files) {
        fullPath << recordingsDir + "/" + file;
    }
    
    return fullPath;
}