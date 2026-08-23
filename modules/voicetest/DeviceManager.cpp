#include "DeviceManager.h"
#include <QDebug>
#include <QStorageInfo>
#include <QFile>
#include <QDir>
#include <QStandardPaths>

DeviceManager::DeviceManager(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
    , m_batteryLevel(-1)
    , m_deviceName("Luckfox Pico Ultra W")
{
    m_timer->setInterval(5000); // Update every 5 seconds
    connect(m_timer, &QTimer::timeout, this, &DeviceManager::refreshStatus);
    
    updateStorage();
    updateBattery();
    
    m_timer->start();
}

QString DeviceManager::storageInfo() const
{
    return m_storageInfo;
}

int DeviceManager::batteryLevel() const
{
    return m_batteryLevel;
}

QString DeviceManager::deviceName() const
{
    return m_deviceName;
}

void DeviceManager::updateStorage()
{
    QStorageInfo storage = QStorageInfo::root();
    qint64 bytesAvailable = storage.bytesAvailable();
    qint64 bytesTotal = storage.bytesTotal();
    
    double availableGB = bytesAvailable / (1024.0 * 1024.0 * 1024.0);
    double totalGB = bytesTotal / (1024.0 * 1024.0 * 1024.0);
    int percentage = (bytesAvailable * 100) / bytesTotal;
    
    m_storageInfo = QString("Storage: %1% free (%2GB/%3GB)").arg(percentage).arg(availableGB, 0, 'f', 1).arg(totalGB, 0, 'f', 1);
    
    emit storageChanged();
}

void DeviceManager::updateBattery()
{
    // Try to read battery level from system
    QFile batteryFile("/sys/class/power_supply/battery/capacity");
    if (batteryFile.exists() && batteryFile.open(QIODevice::ReadOnly)) {
        QByteArray data = batteryFile.readAll().trimmed();
        bool ok;
        int level = data.toInt(&ok);
        if (ok) {
            m_batteryLevel = level;
        }
        batteryFile.close();
    }
    
    // Alternative path for Luckfox
    QFile batteryFile2("/sys/class/power_supply/BAT0/capacity");
    if (m_batteryLevel == -1 && batteryFile2.exists() && batteryFile2.open(QIODevice::ReadOnly)) {
        QByteArray data = batteryFile2.readAll().trimmed();
        bool ok;
        int level = data.toInt(&ok);
        if (ok) {
            m_batteryLevel = level;
        }
        batteryFile2.close();
    }
}

void DeviceManager::refreshStatus()
{
    updateStorage();
    updateBattery();
}