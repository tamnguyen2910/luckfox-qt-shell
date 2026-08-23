#ifndef FILESCANNER_H
#define FILESCANNER_H

#include <QObject>
#include <QStringList>

class QFileSystemWatcher;
class QTimer;

// Scans an image directory in a background thread and emits the file list.
// Watches the directory (and its parent, if the directory does not exist yet,
// e.g. a not-yet-mounted USB drive) and re-scans automatically on changes.
class FileScanner : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool scanning READ isScanning NOTIFY scanningChanged)

public:
    explicit FileScanner(QObject *parent = nullptr);

    bool isScanning() const;
    QString directory() const;
    void setDirectory(const QString &path);

signals:
    void filesReady(const QStringList &files);
    void scanningChanged();

private slots:
    void scheduleScan();
    void startScan();
    void onFilesReady(const QStringList &files);

private:
    void updateWatcher();

    QString m_directory;
    bool m_scanning = false;
    bool m_pendingRescan = false;
    QFileSystemWatcher *m_watcher = nullptr;
    QTimer *m_debounce = nullptr;
};

#endif // FILESCANNER_H
