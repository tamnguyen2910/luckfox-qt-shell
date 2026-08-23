#ifndef FASTDATAWORKER_H
#define FASTDATAWORKER_H

#include "SysInfoWorker.h"
#include "SystemData.h"

// ============================================================
// Worker-Fast (Layer 3, Thread A)
// Handles data that changes every 1s
// Reads: /proc/stat, /proc/meminfo, /sys/devices/.../scaling_cur_freq,
//        QStorageInfo, QDateTime
// Total IO: ~2ms per cycle, QFile direct reads only
// ============================================================

class FastDataWorker : public SysInfoWorker
{
    Q_OBJECT
public:
    explicit FastDataWorker(QObject *parent = nullptr);
    Q_INVOKABLE void startWork() override;

signals:
    void fastDataReady(const FastData &data);

private:
    float readCpuUsage();
    float readCpuFreq();
    void readRam(float &total, float &used, float &percent);
    void readStorage(float &total, float &used, float &percent);
    QString readCurrentTime();

    quint64 m_prevTotal = 0;
    quint64 m_prevIdle = 0;
};

#endif // FASTDATAWORKER_H