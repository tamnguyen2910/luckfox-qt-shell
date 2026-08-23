#ifndef DEVICEMANAGER_H
#define DEVICEMANAGER_H

#include <QObject>
#include <QTimer>
#include <QStorageInfo>

class DeviceManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString storageInfo READ storageInfo NOTIFY storageChanged)
    Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY batteryChanged)
    Q_PROPERTY(QString deviceName READ deviceName CONSTANT)

public:
    explicit DeviceManager(QObject *parent = nullptr);

    QString storageInfo() const;
    int batteryLevel() const;
    QString deviceName() const;

    Q_INVOKABLE void refreshStatus();

signals:
    void storageChanged();
    void batteryChanged();

private:
    QTimer *m_timer;
    QString m_storageInfo;
    int m_batteryLevel;
    QString m_deviceName;

    void updateBattery();
    void updateStorage();
};

#endif // DEVICEMANAGER_H