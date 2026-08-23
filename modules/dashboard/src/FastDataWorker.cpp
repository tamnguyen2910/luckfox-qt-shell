#include "FastDataWorker.h"
#include <QFile>
#include <QTextStream>
#include <QStorageInfo>
#include <QDateTime>

FastDataWorker::FastDataWorker(QObject *parent)
    : SysInfoWorker(parent)
{
    // Seed CPU delta from /proc/stat so first reading is valid
    QFile stat("/proc/stat");
    if (stat.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QByteArray line = stat.readLine();
        QTextStream ts(line);
        QString cpu;
        quint64 user, nice, system, idle, iowait, irq, softirq, steal;
        ts >> cpu >> user >> nice >> system >> idle >> iowait >> irq >> softirq >> steal;
        m_prevTotal = user + nice + system + idle + iowait + irq + softirq + steal;
        m_prevIdle = idle;
    }
}

void FastDataWorker::startWork()
{
    FastData d;

    // CPU
    d.cpuUsage = readCpuUsage();
    d.cpuFreq = readCpuFreq();

    // RAM
    readRam(d.ramTotal, d.ramUsed, d.ramPercent);

    // Storage
    readStorage(d.storageTotal, d.storageUsed, d.storagePercent);

    // Time (UTC+7)
    d.currentTime = readCurrentTime();

    emit fastDataReady(d);
}

float FastDataWorker::readCpuUsage()
{
    QFile stat("/proc/stat");
    if (!stat.open(QIODevice::ReadOnly | QIODevice::Text))
        return 0;

    QByteArray line = stat.readLine();
    QTextStream ts(line);
    QString cpu;
    quint64 user, nice, system, idle, iowait, irq, softirq, steal;
    ts >> cpu >> user >> nice >> system >> idle >> iowait >> irq >> softirq >> steal;

    quint64 total = user + nice + system + idle + iowait + irq + softirq + steal;
    quint64 totalDiff = total - m_prevTotal;
    quint64 idleDiff = idle - m_prevIdle;

    m_prevTotal = total;
    m_prevIdle = idle;

    if (totalDiff > 0)
        return 100.0f * (totalDiff - idleDiff) / totalDiff;

    return 0;
}

float FastDataWorker::readCpuFreq()
{
    QFile freqFile("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq");
    if (!freqFile.open(QIODevice::ReadOnly | QIODevice::Text))
        return 0;

    QByteArray data = freqFile.readLine().trimmed();
    return data.toFloat() / 1000.0f;  // kHz -> MHz
}

void FastDataWorker::readRam(float &total, float &used, float &percent)
{
    QFile meminfo("/proc/meminfo");
    if (!meminfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        total = used = percent = 0;
        return;
    }

    QTextStream in(&meminfo);
    quint64 totalKB = 0, availableKB = 0;
    QString line;

    while (in.readLineInto(&line)) {
        if (line.startsWith("MemTotal:")) {
            QTextStream ts(&line);
            QString key;
            ts >> key >> totalKB;
        } else if (line.startsWith("MemAvailable:")) {
            QTextStream ts(&line);
            QString key;
            ts >> key >> availableKB;
        }
    }

    float totalMB = totalKB / 1024.0f;
    float usedMB = (totalKB > availableKB) ? (totalKB - availableKB) / 1024.0f : 0;

    total = totalMB;
    used = usedMB;
    percent = (totalMB > 0) ? (usedMB / totalMB * 100.0f) : 0;
}

void FastDataWorker::readStorage(float &total, float &used, float &percent)
{
    QStorageInfo root = QStorageInfo::root();
    float totalMB = root.bytesTotal() / (1024.0f * 1024.0f);
    float freeMB = root.bytesFree() / (1024.0f * 1024.0f);
    float usedMB = totalMB - freeMB;

    total = totalMB;
    used = usedMB;
    percent = (totalMB > 0) ? (usedMB / totalMB * 100.0f) : 0;
}

QString FastDataWorker::readCurrentTime()
{
    QDateTime utc = QDateTime::currentDateTimeUtc();
    QDateTime vn = utc.addSecs(7 * 3600);
    return vn.toString("HH:mm:ss");
}