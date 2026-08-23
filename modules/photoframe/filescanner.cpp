#include "filescanner.h"

#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QThread>
#include <QTimer>

class ScanWorker : public QObject
{
    Q_OBJECT

public slots:
    void scan(const QString &path);

signals:
    void finished(const QStringList &files);
};

void ScanWorker::scan(const QString &path)
{
    QStringList files;
    QDir dir(path);
    if (dir.exists()) {
        const QStringList filters = { "*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif" };
        const QFileInfoList list = dir.entryInfoList(filters, QDir::Files, QDir::Name);
        for (const QFileInfo &fi : list)
            files.append(fi.absoluteFilePath());
    }
    emit finished(files);
}

FileScanner::FileScanner(QObject *parent)
    : QObject(parent)
    , m_watcher(new QFileSystemWatcher(this))
    , m_debounce(new QTimer(this))
{
    m_debounce->setSingleShot(true);
    m_debounce->setInterval(300);
    connect(m_debounce, &QTimer::timeout, this, &FileScanner::startScan);
    connect(m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &FileScanner::scheduleScan);
}

bool FileScanner::isScanning() const
{
    return m_scanning;
}

QString FileScanner::directory() const
{
    return m_directory;
}

void FileScanner::setDirectory(const QString &path)
{
    if (m_directory == path)
        return;
    m_directory = path;
    updateWatcher();
    scheduleScan();
}

void FileScanner::scheduleScan()
{
    m_debounce->start();
}

void FileScanner::startScan()
{
    if (m_directory.isEmpty())
        return;
    if (m_scanning) {
        m_pendingRescan = true;
        return;
    }

    m_scanning = true;
    emit scanningChanged();

    const QString dir = m_directory; // copy for the worker thread

    ScanWorker *worker = new ScanWorker;
    QThread *thread = new QThread(this);
    worker->moveToThread(thread);

    connect(thread, &QThread::finished, worker, &QObject::deleteLater);
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);
    connect(thread, &QThread::started, worker,
            [worker, dir] { worker->scan(dir); });
    connect(worker, &ScanWorker::finished, this, &FileScanner::onFilesReady);
    connect(worker, &ScanWorker::finished, thread, &QThread::quit);

    thread->start();
}

void FileScanner::onFilesReady(const QStringList &files)
{
    m_scanning = false;
    emit scanningChanged();
    emit filesReady(files);

    if (m_pendingRescan) {
        m_pendingRescan = false;
        startScan();
    }
}

void FileScanner::updateWatcher()
{
    if (!m_watcher->directories().isEmpty())
        m_watcher->removePaths(m_watcher->directories());

    QString watchPath = m_directory;
    if (!QDir(watchPath).exists())
        watchPath = QFileInfo(m_directory).path(); // watch parent for mount events
    if (QDir(watchPath).exists())
        m_watcher->addPath(watchPath);
}

#include "filescanner.moc"
