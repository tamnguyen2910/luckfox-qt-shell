#ifndef SENSORWORKER_H
#define SENSORWORKER_H

#include "SysInfoWorker.h"
#include "SystemData.h"
#include <QDir>
#include <QFile>

// ============================================================
// Worker-Sensor (Layer 3, Thread C)
// Handles AHT30 sensor data
// Reads: /sys/class/hwmon/*/name (to find aht30)
//        /sys/class/hwmon/*/temp1_input, humidity1_input (scaled by 10)
// Polling: 2s for readings, 30s for hwmon rescan if not found
// ============================================================

class SensorWorker : public SysInfoWorker
{
    Q_OBJECT
public:
    explicit SensorWorker(QObject *parent = nullptr);
    Q_INVOKABLE void startWork() override;

signals:
    void sensorDataReady(const SensorData &data);

private:
    QString findHwmonPath();
    bool    readSensorValues(const QString &hwmonPath, float &temp, float &hum);

    QString m_hwmonPath;
    int     m_scanCounter = 0; // counts SensorWorker cycles (~2s each)
    const int m_scanInterval = 15; // 15 * 2s = 30s
};

#endif // SENSORWORKER_H