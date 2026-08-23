#include "imagebrowser.h"

#include <QFileInfo>
#include <QImageReader>
#include <QRandomGenerator>
#include <QTimer>

ImageBrowser::ImageBrowser(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
{
    m_timer->setInterval(m_intervalMs);
    connect(m_timer, &QTimer::timeout, this, &ImageBrowser::onSlideshowTick);
}

QStringList ImageBrowser::files() const
{
    return m_files;
}

int ImageBrowser::count() const
{
    return m_files.size();
}

int ImageBrowser::currentIndex() const
{
    return m_currentIndex;
}

QString ImageBrowser::currentFile() const
{
    if (m_currentIndex >= 0 && m_currentIndex < m_files.size())
        return m_files.at(m_currentIndex);
    return QString();
}

bool ImageBrowser::isPlaying() const
{
    return m_playing;
}

int ImageBrowser::interval() const
{
    return m_intervalMs;
}

bool ImageBrowser::isShuffle() const
{
    return m_shuffle;
}

qint64 ImageBrowser::fileSize() const
{
    return m_fileSize;
}

int ImageBrowser::imageWidth() const
{
    return m_imageWidth;
}

int ImageBrowser::imageHeight() const
{
    return m_imageHeight;
}

void ImageBrowser::setShuffle(bool on)
{
    if (on == m_shuffle)
        return;
    m_shuffle = on;
    emit shuffleChanged();
}

void ImageBrowser::next()
{
    moveBy(1);
}

void ImageBrowser::previous()
{
    moveBy(-1);
}

void ImageBrowser::jumpTo(int index)
{
    if (m_files.isEmpty())
        return;
    const int clamped = qBound(0, index, m_files.size() - 1);
    setCurrentIndexInternal(clamped);
}

void ImageBrowser::startSlideshow()
{
    if (m_playing || m_files.size() < 2)
        return;
    m_playing = true;
    emit playingChanged();
    m_timer->start();
}

void ImageBrowser::stopSlideshow()
{
    if (!m_playing)
        return;
    m_playing = false;
    m_timer->stop();
    emit playingChanged();
}

void ImageBrowser::toggleSlideshow()
{
    if (m_playing)
        stopSlideshow();
    else
        startSlideshow();
}

void ImageBrowser::setSlideshowInterval(int ms)
{
    if (ms < 1000)
        ms = 1000;
    if (ms == m_intervalMs)
        return;
    m_intervalMs = ms;
    m_timer->setInterval(ms);
    emit intervalChanged();
}

void ImageBrowser::setDirectory(const QString &path)
{
    Q_UNUSED(path)
}

void ImageBrowser::setAutoStart(bool on)
{
    m_autoStart = on;
}

void ImageBrowser::onFilesReady(const QStringList &files)
{
    const QString previous = currentFile();
    m_files = files;
    setCurrentIndexInternal(0);

    if (!previous.isEmpty()) {
        const int idx = m_files.indexOf(previous);
        if (idx >= 0)
            setCurrentIndexInternal(idx);
    }

    emit filesChanged();
    if (m_playing && m_files.size() < 2)
        stopSlideshow();

    // First batch of files arriving: start the slideshow if auto-start is on.
    if (m_autoStart && m_files.size() >= 2) {
        m_autoStart = false;
        startSlideshow();
    }
}

void ImageBrowser::onSlideshowTick()
{
    if (m_files.size() > 1)
        next();
}

void ImageBrowser::moveBy(int delta)
{
    if (m_files.isEmpty())
        return;

    int next;
    if (m_shuffle && delta > 0) {
        // Random pick, never the current image.
        next = QRandomGenerator::global()->bounded(m_files.size());
        if (m_files.size() > 1 && next == m_currentIndex)
            next = (next + 1) % m_files.size();
    } else {
        next = m_currentIndex + delta;
        if (next >= m_files.size())
            next = 0;                       // wrap-around
        else if (next < 0)
            next = m_files.size() - 1;
    }
    setCurrentIndexInternal(next);
}

void ImageBrowser::setCurrentIndexInternal(int index)
{
    if (index == m_currentIndex)
        return;
    m_currentIndex = index;
    updateFileInfo();
    emit currentIndexChanged();
}

void ImageBrowser::updateFileInfo()
{
    const QString file = currentFile();
    m_fileSize = 0;
    m_imageWidth = 0;
    m_imageHeight = 0;
    if (!file.isEmpty()) {
        m_fileSize = QFileInfo(file).size() / 1024; // KB
        QImageReader reader(file);
        const QSize size = reader.size();
        if (size.isValid()) {
            m_imageWidth = size.width();
            m_imageHeight = size.height();
        }
    }
    emit fileInfoChanged();
}
