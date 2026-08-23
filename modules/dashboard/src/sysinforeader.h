#ifndef SYSINFOREADER_H
#define SYSINFOREADER_H

#include <QObject>
#include <QTimer>

#include "SystemData.h"

class FastDataWorker;
class SlowDataWorker;
class SensorWorker;

// ============================================================
// Layer 2+4: Timer Manager + State Aggregator
// Runs entirely on Main Thread (GUI thread)
// Owns 3 worker threads, receives data via QueuedConnection,
// updates m_* members, emits Q_PROPERTY NOTIFY signals
// ============================================================

class SysInfoReader : public QObject
{
    Q_OBJECT

    // ─── QML Properties ─────────────────────────
    Q_PROPERTY(float ramTotal READ ramTotal NOTIFY ramChanged)
    Q_PROPERTY(float ramUsed READ ramUsed NOTIFY ramChanged)
    Q_PROPERTY(float ramPercent READ ramPercent NOTIFY ramChanged)

    Q_PROPERTY(float storageTotal READ storageTotal NOTIFY storageChanged)
    Q_PROPERTY(float storageUsed READ storageUsed NOTIFY storageChanged)
    Q_PROPERTY(float storagePercent READ storagePercent NOTIFY storageChanged)

    Q_PROPERTY(float cpuUsage READ cpuUsage NOTIFY cpuChanged)
    Q_PROPERTY(float cpuFreq READ cpuFreq NOTIFY cpuChanged)

    Q_PROPERTY(float temperature READ temperature NOTIFY sensorChanged)
    Q_PROPERTY(float humidity READ humidity NOTIFY sensorChanged)
    Q_PROPERTY(bool sensorAvailable READ sensorAvailable NOTIFY sensorChanged)

    Q_PROPERTY(QString ipAddress READ ipAddress NOTIFY networkChanged)
    Q_PROPERTY(QString ifaceName READ ifaceName NOTIFY networkChanged)
    Q_PROPERTY(QString wifiSSID READ wifiSSID NOTIFY wifiChanged)
    Q_PROPERTY(int linkSpeed READ linkSpeed NOTIFY wifiChanged)

    Q_PROPERTY(QString currentTime READ currentTime NOTIFY timeChanged)

public:
    explicit SysInfoReader(QObject *parent = nullptr);
    ~SysInfoReader();

    // Getters (inline)
    float ramTotal() const       { return m_ramTotal; }
    float ramUsed() const        { return m_ramUsed; }
    float ramPercent() const     { return m_ramPercent; }

    float storageTotal() const   { return m_storageTotal; }
    float storageUsed() const    { return m_storageUsed; }
    float storagePercent() const { return m_storagePercent; }

    float cpuUsage() const       { return m_cpuUsage; }
    float cpuFreq() const        { return m_cpuFreq; }

    float temperature() const    { return m_temperature; }
    float humidity() const       { return m_humidity; }
    bool sensorAvailable() const { return m_sensorAvailable; }

    QString ipAddress() const    { return m_ipAddress; }
    QString ifaceName() const    { return m_ifaceName; }
    QString wifiSSID() const     { return m_wifiSSID; }
    int linkSpeed() const        { return m_linkSpeed; }

    QString currentTime() const  { return m_currentTime; }

signals:
    void ramChanged();
    void storageChanged();
    void cpuChanged();
    void sensorChanged();
    void timeChanged();
    void networkChanged();
    void wifiChanged();

public slots:
    // Called by QML Timer (L1) to update history arrays
    void updateAll();

private slots:
    // Layer 4: Receive data from workers (QueuedConnection)
    void onFastDataReady(const FastData &data);
    void onSlowDataReady(const SlowData &data);
    void onSensorDataReady(const SensorData &data);

private:
    // Layer 2: Setup timers and workers
    void setupWorkers();
    void setupTimers();

    // Layer 2: Timer triggers
    void requestFastUpdate();
    void requestSlowUpdate();
    void requestSensorUpdate();

    // Layer 3: Workers (each owns its own QThread)
    FastDataWorker *m_fastWorker = nullptr;
    SlowDataWorker *m_slowWorker = nullptr;
    SensorWorker *m_sensorWorker = nullptr;

    QThread *m_fastThread = nullptr;
    QThread *m_slowThread = nullptr;
    QThread *m_sensorThread = nullptr;

    // Layer 2: Timers (main thread)
    QTimer m_fastTimer;    // 1s
    QTimer m_slowTimer;    // 10s
    QTimer m_sensorTimer;  // 2s

    // Layer 4: State (only written on main thread)
    float m_ramTotal = 0;
    float m_ramUsed = 0;
    float m_ramPercent = 0;

    float m_storageTotal = 0;
    float m_storageUsed = 0;
    float m_storagePercent = 0;

    float m_cpuUsage = 0;
    float m_cpuFreq = 0;

    QString m_ipAddress = "0.0.0.0";
    QString m_ifaceName = "wlan0";
    QString m_wifiSSID = "Not connected";
    int m_linkSpeed = 0;

    QString m_currentTime = "00:00:00";

    float m_temperature = 0;
    float m_humidity = 0;
    bool m_sensorAvailable = false;
};

#endif // SYSINFOREADER_H