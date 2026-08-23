#include "SensorWorker.h"
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QDebug>

SensorWorker::SensorWorker(QObject *parent)
    : SysInfoWorker(parent)
{
    // Initial scan at construction
    m_hwmonPath = findHwmonPath();
}

void SensorWorker::startWork()
{
    SensorData d;

    if (!m_hwmonPath.isEmpty()) {
        d.available = readSensorValues(m_hwmonPath, d.temperature, d.humidity);
    }

    // Re-scan every 30s if sensor not found
    if (!d.available && ++m_scanCounter >= m_scanInterval) {
        m_scanCounter = 0;
        m_hwmonPath = findHwmonPath();
        if (!m_hwmonPath.isEmpty()) {
            d.available = readSensorValues(m_hwmonPath, d.temperature, d.humidity);
        }
    }

    emit sensorDataReady(d);
}

QString SensorWorker::findHwmonPath()
{
    QDir hwmonDir("/sys/class/hwmon");
    QStringList entries = hwmonDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

    foreach (const QString &entry, entries) {
        QString namePath = QString("/sys/class/hwmon/%1/name").arg(entry);
        QFile nameFile(namePath);
        if (nameFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString name = nameFile.readLine().trimmed();
            nameFile.close();
            if (name == "aht30") {
                return QString("/sys/class/hwmon/%1").arg(entry);
            }
        }
    }

    return QString();
}

bool SensorWorker::readSensorValues(const QString &hwmonPath, float &temp, float &hum)
{
    auto readFloat = [](const QString &path) -> float {
        QFile f(path);
        if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
            return 0;
        QByteArray data = f.readLine().trimmed();
        return data.toFloat();
    };

    temp = readFloat(hwmonPath + "/temp1_input") / 10.0f;
    hum  = readFloat(hwmonPath + "/humidity1_input") / 10.0f;

    // Valid values should be > 0
    return (temp > 0 || hum > 0);
}