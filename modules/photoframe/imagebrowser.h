#ifndef IMAGEBROWSER_H
#define IMAGEBROWSER_H

#include <QObject>
#include <QStringList>

class QTimer;

// Image collection + navigation + slideshow playback. Exposed to QML as
// the "browser" context property.
class ImageBrowser : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList files READ files NOTIFY filesChanged)
    Q_PROPERTY(int count READ count NOTIFY filesChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(QString currentFile READ currentFile NOTIFY currentIndexChanged)
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(int interval READ interval NOTIFY intervalChanged)
    Q_PROPERTY(bool shuffle READ isShuffle WRITE setShuffle NOTIFY shuffleChanged)
    Q_PROPERTY(qint64 fileSize READ fileSize NOTIFY fileInfoChanged)
    Q_PROPERTY(int imageWidth READ imageWidth NOTIFY fileInfoChanged)
    Q_PROPERTY(int imageHeight READ imageHeight NOTIFY fileInfoChanged)

public:
    explicit ImageBrowser(QObject *parent = nullptr);

    QStringList files() const;
    int count() const;
    int currentIndex() const;
    QString currentFile() const;
    bool isPlaying() const;
    int interval() const;
    bool isShuffle() const;
    void setShuffle(bool on);
    qint64 fileSize() const;
    int imageWidth() const;
    int imageHeight() const;

    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void jumpTo(int index);
    Q_INVOKABLE void startSlideshow();
    Q_INVOKABLE void stopSlideshow();
    Q_INVOKABLE void toggleSlideshow();
    Q_INVOKABLE void setSlideshowInterval(int ms);
    Q_INVOKABLE void setDirectory(const QString &path);
    void setAutoStart(bool on);

public slots:
    void onFilesReady(const QStringList &files);

signals:
    void filesChanged();
    void currentIndexChanged();
    void playingChanged();
    void intervalChanged();
    void shuffleChanged();
    void fileInfoChanged();

private slots:
    void onSlideshowTick();

private:
    void moveBy(int delta);
    void setCurrentIndexInternal(int index);
    void updateFileInfo();

    QStringList m_files;
    int m_currentIndex = -1; // -1 = nothing shown yet; first set always emits
    bool m_playing = false;
    bool m_autoStart = false;
    bool m_shuffle = false;
    int m_intervalMs = 5000;
    qint64 m_fileSize = 0;
    int m_imageWidth = 0;
    int m_imageHeight = 0;
    QTimer *m_timer = nullptr;
};

#endif // IMAGEBROWSER_H
