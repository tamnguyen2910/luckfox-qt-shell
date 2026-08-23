#include "audioplayer.h"
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDebug>
#include <QDateTime>
#include <QRegularExpression>
#include <signal.h>      // SIGTERM/SIGSTOP/SIGCONT + kill()
#include <unistd.h>      // setpgid (via child modifier)

AudioPlayer::AudioPlayer(QObject *parent)
    : QObject(parent)
    , m_process(nullptr)
    , m_positionTimer(new QTimer(this))
    , m_volumeDebounceTimer(new QTimer(this))
    , m_isPlaying(false)
    , m_isPaused(false)
    , m_currentFile("")
    , m_currentTitle("No Track")
    , m_currentIndex(-1)
    , m_position(0)
    , m_duration(0)
    , m_volume(10)
    , m_pendingVolume(10)
    , m_lastAppliedVolume(-1)
    , m_startTime(0)
    , m_pausedPosition(0)
    , m_processGroupId(0)
{
    updateStatus("Ready - Scan music folder to begin");

    // Position timer for progress tracking
    connect(m_positionTimer, &QTimer::timeout, this, &AudioPlayer::updatePosition);

    // Volume debounce timer: fires 50ms after last slider event
    m_volumeDebounceTimer->setSingleShot(true);
    connect(m_volumeDebounceTimer, &QTimer::timeout, this, &AudioPlayer::flushVolume);

    // Auto-scan music folder
    scanMusicFolder("/media/music");

    // Apply initial volume setting
    setVolume(m_volume);
}

AudioPlayer::~AudioPlayer()
{
    stop();
    delete m_positionTimer;
    delete m_volumeDebounceTimer;
}
void AudioPlayer::scanMusicFolder(const QString &folderPath)
{
    m_playlist.clear();
    m_musicFolderPath = folderPath;              // store for playlist zone label
    QDir dir(folderPath);

    if (!dir.exists()) {
        updateStatus("Music folder not found: " + folderPath);
        emit playlistChanged();
        emit musicFolderPathChanged();
        return;
    }

    // Filter for audio files
    QStringList filters;
    filters << "*.mp3" << "*.MP3"
            << "*.wav" << "*.WAV"
            << "*.flac" << "*.FLAC"
            << "*.ogg" << "*.OGG"
            << "*.m4a" << "*.M4A";

    QFileInfoList files = dir.entryInfoList(filters, QDir::Files, QDir::Name);

    for (const QFileInfo &fileInfo : files) {
        m_playlist.append(fileInfo.absoluteFilePath());
    }

    emit playlistChanged();
    emit musicFolderPathChanged();

    if (m_playlist.isEmpty()) {
        updateStatus(QString("No music files found in %1").arg(folderPath));
    } else {
        updateStatus(QString("Found %1 track(s)").arg(m_playlist.size()));
        m_currentIndex = 0;
        emit currentIndexChanged();
    }

    qDebug() << "Scanned" << m_playlist.size() << "tracks from" << folderPath;
}

QString AudioPlayer::extractTitle(const QString &filePath)
{
    QFileInfo fileInfo(filePath);
    QString baseName = fileInfo.baseName();

    // Remove common patterns like track numbers
    baseName.remove(QRegExp("^\\d+[\\s\\-_\\.]+"));

    return baseName;
}

int AudioPlayer::estimateDuration(const QString &filePath)
{
    // Scan actual duration via mpg123 metadata (accurate, one-time cost <200ms)
    // OLD: hardcoded 128 kbps bitrate → inaccurate seek
    // NEW: parse real length from mpg123 -t output
    QProcess scan;
    QString player = "mpg123";
    // -t = test mode (no audio output), --longid3 = verbose ID3 tags
    scan.start(player, QStringList() << "--longid3" << "-t" << filePath);
    if (!scan.waitForFinished(2000))
        return qMax(1, static_cast<int>(QFileInfo(filePath).size() / 16000));

    QString output = scan.readAllStandardError();   // mpg123 writes to stderr

    // Method 1: ID3v2 TLEN frame (e.g. "TLEN:266243")
    QRegularExpression lenRe("TLEN:(\\d+)");
    QRegularExpressionMatch mLen = lenRe.match(output);
    if (mLen.hasMatch()) {
        int ms = mLen.captured(1).toInt();
        int seconds = ms / 1000;
        if (seconds > 1) return seconds;
    }

    // Method 2: parse [m:ss] or [mm:ss] from "[4:26] Decoding ... finished"
    QRegularExpression timeRe("\\[(\\d+):(\\d{2})\\]");
    QRegularExpressionMatch mTime = timeRe.match(output);
    if (mTime.hasMatch()) {
        int minutes = mTime.captured(1).toInt();
        int seconds = mTime.captured(2).toInt();
        int total = minutes * 60 + seconds;
        if (total > 0) return total;
    }

    // Fallback: estimate by file size (128 kbps avg)
    int estimatedSeconds = static_cast<int>(QFileInfo(filePath).size() / 16000);
    return qMax(1, estimatedSeconds);
}

QString AudioPlayer::findAudioPlayer()
{
    // Try to find available audio players
    QStringList players = {"aplay", "mpg123", "ffplay", "mplayer"};

    for (const QString &player : players) {
        QProcess check;
        check.start("which", QStringList() << player);
        check.waitForFinished(500);
        if (check.exitCode() == 0) {
            qDebug() << "Found audio player:" << player;
            return player;
        }
    }

    return "aplay"; // Default fallback
}

void AudioPlayer::play(const QString &filePath)
{
    if (!filePath.isEmpty()) {
        // Playing specific file
        m_currentFile = filePath;
        m_currentIndex = m_playlist.indexOf(filePath);
        emit currentFileChanged();
        emit currentIndexChanged();
    } else if (m_currentIndex >= 0 && m_currentIndex < m_playlist.size()) {
        // Play current index
        m_currentFile = m_playlist[m_currentIndex];
        emit currentFileChanged();
    } else if (!m_playlist.isEmpty()) {
        // Play first track
        m_currentIndex = 0;
        m_currentFile = m_playlist[0];
        emit currentFileChanged();
        emit currentIndexChanged();
    } else {
        updateStatus("No tracks in playlist");
        return;
    }

    // Check if file exists
    if (!QFile::exists(m_currentFile)) {
        updateStatus("File not found: " + m_currentFile);
        emit error("File not found");
        return;
    }

    // Update track info
    m_currentTitle = extractTitle(m_currentFile);
    m_duration = estimateDuration(m_currentFile);
    m_position = 0;
    m_pausedPosition = 0;  // Reset paused position for new track
    emit currentTitleChanged();
    emit durationChanged();
    emit positionChanged();

    // Stop current playback if any
    stop();

    startPlayback();
}

void AudioPlayer::startPlayback()
{
    // Create new process
    m_process = new QProcess(this);
    connect(m_process, QOverload<int>::of(&QProcess::finished),
            this, &AudioPlayer::onProcessFinished);
    connect(m_process, &QProcess::errorOccurred,
            this, &AudioPlayer::onProcessError);
    connect(m_process, &QProcess::readyReadStandardError,
            this, &AudioPlayer::readProcessOutput);

    // Determine which player to use
    QString player = findAudioPlayer();
    QStringList args;

    if (player == "mpg123") {
        args << "-q";                         // quiet, non-interactive (no tty crash)
        args << "-a" << "default";

        // If resuming from pause or seeking, use -k frames
        if (m_pausedPosition > 0) {
            // mpg123 uses -k option to skip frames (1 frame ≈ 0.026 sec)
            // Calculate frames to skip: position (sec) * 38.28 frames/sec
            int framesToSkip = static_cast<int>(m_pausedPosition * 38.28);
            args << "-k" << QString::number(framesToSkip);
            qDebug() << "Resuming from position:" << m_pausedPosition << "seconds (skipping" << framesToSkip << "frames)";
        }

        args << m_currentFile;
    } else if (player == "aplay") {
        // For aplay, we need WAV format
        // If MP3, try to use mpg123 with output to stdout
        if (m_currentFile.endsWith(".mp3", Qt::CaseInsensitive)) {
            player = "mpg123";
            args << "-q"; // quiet, non-interactive
            args << "-a" << "default";

            if (m_pausedPosition > 0) {
                int framesToSkip = static_cast<int>(m_pausedPosition * 38.28);
                args << "-k" << QString::number(framesToSkip);
            }

            args << m_currentFile;
        } else {
            args << m_currentFile;
        }
    } else if (player == "ffplay") {
        args << "-nodisp" << "-autoexit";

        if (m_pausedPosition > 0) {
            args << "-ss" << QString::number(m_pausedPosition);
        }

        args << m_currentFile;
    } else {
        args << m_currentFile;
    }

    qDebug() << "Starting playback:" << player << args;
    m_process->start(player, args);

    // Put mpg123 in its own process group → group-kill prevents orphans.
    // (Parent calls setpgid on child after start — POSIX allows while child
    //  hasn't exec'd yet; QProcess pid() is available on this Qt build.)
    m_processGroupId = m_process->processId();
    if (m_processGroupId > 0)
        ::setpgid(m_processGroupId, m_processGroupId);   // pgid = pid

    if (m_process->waitForStarted(1000)) {
        m_isPlaying = true;
        m_isPaused = false;

        // Adjust start time based on paused position
        m_startTime = QDateTime::currentMSecsSinceEpoch() - (m_pausedPosition * 1000);

        emit playingChanged();
        emit pausedChanged();
        updateStatus("Playing: " + m_currentTitle);

        // Start position timer
        m_positionTimer->start(1000); // Update every second
    } else {
        updateStatus("Failed to start player");
        emit error("Failed to start audio player");
        delete m_process;
        m_process = nullptr;
    }
}

void AudioPlayer::pause()
{
    if (m_process && m_isPlaying && !m_isPaused) {
        // Save current position before pausing
        m_pausedPosition = m_position;

        m_isPaused = true;
        m_isPlaying = false;
        m_positionTimer->stop();

        // D-02: SIGSTOP instead of kill+restart — process frozen in place,
        // resume is instant (SIGCONT), position preserved exactly.
        if (m_processGroupId > 0) {
            ::kill(-m_processGroupId, SIGSTOP);   // freeze whole group
        } else {
            m_process->terminate();
            if (!m_process->waitForFinished(300)) {
                m_process->kill();
                m_process->waitForFinished(300);
            }
        }

        emit playingChanged();
        emit pausedChanged();
        updateStatus("Paused: " + m_currentTitle);
    }
}

void AudioPlayer::resume()
{
    if (m_isPaused) {
        m_isPaused = false;

        // D-02: if process still alive (SIGSTOP'd), SIGCONT it — instant resume,
        // exact position, no restart latency.
        if (m_process && m_processGroupId > 0
            && m_process->state() != QProcess::NotRunning) {
            ::kill(-m_processGroupId, SIGCONT);
            m_isPlaying = true;
            m_startTime = QDateTime::currentMSecsSinceEpoch() - (m_pausedPosition * 1000);
            m_positionTimer->start(1000);
            emit playingChanged();
            emit pausedChanged();
            updateStatus("Playing: " + m_currentTitle);
        } else {
            // Process was killed (e.g. stopped externally) — restart from saved pos
            startPlayback();
        }
    }
}

void AudioPlayer::killProcessGroup()
{
    // Kill entire process group of mpg123 child (created via setpgid in
    // startPlayback). Prevents orphaned mpg123 when app is SIGKILLed.
    if (m_processGroupId > 0) {
        ::kill(-m_processGroupId, SIGTERM);   // TERM to whole group
        // Give it a moment, then force-kill group if still alive
        m_process->waitForFinished(300);
        if (m_process && m_process->state() != QProcess::NotRunning)
            ::kill(-m_processGroupId, SIGKILL);
        m_processGroupId = 0;
    }
}

void AudioPlayer::stop()
{
    if (m_process) {
        // Disconnect signals to avoid crashes
        disconnect(m_process, nullptr, this, nullptr);

        // Kill whole process group (mpg123 + any children) — orphan-safe
        killProcessGroup();

        if (m_process->state() != QProcess::NotRunning) {
            m_process->waitForFinished(300);
        }
        delete m_process;
        m_process = nullptr;
    }

    m_positionTimer->stop();
    m_isPlaying = false;
    m_isPaused = false;
    m_position = 0;

    emit playingChanged();
    emit pausedChanged();
    emit positionChanged();
    updateStatus("Stopped");
}

void AudioPlayer::next()
{
    if (m_playlist.isEmpty()) {
        updateStatus("No tracks in playlist");
        return;
    }

    m_currentIndex = (m_currentIndex + 1) % m_playlist.size();
    emit currentIndexChanged();
    play();
}

void AudioPlayer::previous()
{
    if (m_playlist.isEmpty()) {
        updateStatus("No tracks in playlist");
        return;
    }

    m_currentIndex = (m_currentIndex - 1 + m_playlist.size()) % m_playlist.size();
    emit currentIndexChanged();
    play();
}

void AudioPlayer::playAtIndex(int index)
{
    if (index >= 0 && index < m_playlist.size()) {
        m_currentIndex = index;
        emit currentIndexChanged();
        play();
    }
}

void AudioPlayer::seek(int position)
{
    // Seeking with CLI player requires restart from new position
    if (m_process && m_isPlaying) {
        // Save target position
        m_pausedPosition = qBound(0, position, m_duration);
        m_isPaused = true; // Will trigger position-based restart

        // Disconnect signals before killing
        disconnect(m_process, nullptr, this, nullptr);

        // Stop current process
        m_process->terminate();
        if (!m_process->waitForFinished(300)) {
            m_process->kill();
            m_process->waitForFinished(300);
        }
        delete m_process;
        m_process = nullptr;

        // Restart from new position
        m_isPaused = false;
        startPlayback();
    }
}

void AudioPlayer::setVolume(int volume)
{
    if (volume < 0) volume = 0;
    if (volume > 100) volume = 100;

    m_volume = volume;
    m_pendingVolume = volume;
    m_volumeDebounceTimer->start(50);   // Deb: collapse a fast drag into one amixer call
    emit volumeChanged();
}

void AudioPlayer::flushVolume()
{
    int volume = m_pendingVolume;
        if (volume == m_lastAppliedVolume) return;   // skip redundant calls
        m_lastAppliedVolume = volume;

        int hpmixRaw, lineoutRaw;
        if (volume > 0) {
            hpmixRaw = (volume * 31) / 100;
            lineoutRaw = (volume * 31) / 100;
            if (hpmixRaw == 0) hpmixRaw = 1;
            if (lineoutRaw == 0) lineoutRaw = 1;
        } else {
            hpmixRaw = 1;
            lineoutRaw = 0;
        }

        qDebug() << "async volume:" << volume << "% -> HPMIX:" << hpmixRaw << "LINEOUT:" << lineoutRaw;

        // Single QProcess::start (non-blocking) — replaces 2x synchronous QProcess::execute
        QProcess *amixer = new QProcess(this);
        QString cmd = QString("amixer sset 'DAC HPMIX' %1; amixer sset 'DAC LINEOUT' %2")
                          .arg(hpmixRaw).arg(lineoutRaw);
        amixer->start("sh", QStringList() << "-c" << cmd);
        connect(amixer, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                amixer, &QObject::deleteLater);
    }

void AudioPlayer::volumeUp()
{
    setVolume(m_volume + 10);
}

void AudioPlayer::volumeDown()
{
    setVolume(m_volume - 10);
}

void AudioPlayer::updatePosition()
{
    if (m_isPlaying && m_process) {
        qint64 elapsed = (QDateTime::currentMSecsSinceEpoch() - m_startTime) / 1000;
        m_position = static_cast<int>(elapsed);

        if (m_position >= m_duration) {
            m_position = m_duration;
        }

        emit positionChanged();
    }
}

void AudioPlayer::readProcessOutput()
{
    if (!m_process) return;

    QString output = m_process->readAllStandardError();
    // mpg123 outputs frames info like: Frame# 1234 [5678], Time: 01:23.45 [04:56.78]
    QRegExp rx("Time: (\\d+):(\\d+)\\.(\\d+) \\[(\\d+):(\\d+)\\.(\\d+)\\]");
    if (rx.indexIn(output) != -1) {
        int currentMin = rx.cap(1).toInt();
        int currentSec = rx.cap(2).toInt();
        int totalMin = rx.cap(4).toInt();
        int totalSec = rx.cap(5).toInt();

        m_position = currentMin * 60 + currentSec;
        int newDuration = totalMin * 60 + totalSec;

        if (newDuration > 0 && newDuration != m_duration) {
            m_duration = newDuration;
            emit durationChanged();
        }

        emit positionChanged();
    }
}

void AudioPlayer::onProcessFinished(int exitCode)
{
    qDebug() << "Process finished with code:" << exitCode;
    m_positionTimer->stop();
    m_isPlaying = false;
    m_isPaused = false;
    emit playingChanged();
    emit pausedChanged();

    // Auto-play next track
    if (!m_playlist.isEmpty() && exitCode == 0) {
        updateStatus("Finished - Playing next...");
        QTimer::singleShot(500, this, &AudioPlayer::next);
    } else {
        updateStatus("Playback finished");
    }
}

void AudioPlayer::onProcessError(QProcess::ProcessError error)
{
    qDebug() << "Process error:" << error;
    m_positionTimer->stop();
    m_isPlaying = false;
    m_isPaused = false;
    emit playingChanged();
    emit pausedChanged();

    QString errorMsg;
    switch (error) {
        case QProcess::FailedToStart:
            errorMsg = "Failed to start audio player. Install mpg123: opkg install mpg123";
            break;
        case QProcess::Crashed:
            errorMsg = "Audio player crashed";
            break;
        default:
            errorMsg = "Unknown error";
    }

    updateStatus(errorMsg);
    emit this->error(errorMsg);
}

void AudioPlayer::updateStatus(const QString &status)
{
    m_statusText = status;
    emit statusTextChanged();
}