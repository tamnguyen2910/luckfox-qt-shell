#include "sysinforeader.h"
#include "FastDataWorker.h"
#include "SlowDataWorker.h"
#include "SensorWorker.h"

#include <QThread>
#include <QDebug>

// ============================================================
// SysInfoReader Implementation
// Layer 2 (Timer Manager) + Layer 4 (State Aggregator)
// ============================================================

SysInfoReader::SysInfoReader(QObject *parent)
    : QObject(parent)
{
    // Register custom types for QueuedConnection cross-thread signals
    qRegisterMetaType<FastData>("FastData");
    qRegisterMetaType<SlowData>("SlowData");
    qRegisterMetaType<SensorData>("SensorData");

    setupWorkers();
    setupTimers();

    // Initial trigger
    requestFastUpdate();
    requestSlowUpdate();
    requestSensorUpdate();
}

SysInfoReader::~SysInfoReader()
{
    // Stop timers
    m_fastTimer.stop();
    m_slowTimer.stop();
    m_sensorTimer.stop();

    // Stop worker threads gracefully
    auto stopThread = [](QThread *thread) {
        if (thread && thread->isRunning()) {
            thread->quit();
            thread->wait(1000);
        }
    };

    stopThread(m_fastThread);
    stopThread(m_slowThread);
    stopThread(m_sensorThread);
}

void SysInfoReader::setupWorkers()
{
    // Create workers
    m_fastWorker   = new FastDataWorker();
    m_slowWorker   = new SlowDataWorker();
    m_sensorWorker = new SensorWorker();

    // Create dedicated threads
    m_fastThread   = new QThread(this);
    m_slowThread   = new QThread(this);
    m_sensorThread = new QThread(this);

    // Move workers to their threads
    m_fastWorker->moveToThread(m_fastThread);
    m_slowWorker->moveToThread(m_slowThread);
    m_sensorWorker->moveToThread(m_sensorThread);

    // Connect worker signals to aggregator slots (QueuedConnection = thread-safe)
    connect(m_fastWorker,   &FastDataWorker::fastDataReady,
            this, &SysInfoReader::onFastDataReady,   Qt::QueuedConnection);
    connect(m_slowWorker,   &SlowDataWorker::slowDataReady,
            this, &SysInfoReader::onSlowDataReady,   Qt::QueuedConnection);
    connect(m_sensorWorker, &SensorWorker::sensorDataReady,
            this, &SysInfoReader::onSensorDataReady, Qt::QueuedConnection);

    // Start threads
    m_fastThread->start();
    m_slowThread->start();
    m_sensorThread->start();
}

void SysInfoReader::setupTimers()
{
    m_fastTimer.setInterval(1000);   // 1s
    m_slowTimer.setInterval(10000);  // 10s
    m_sensorTimer.setInterval(2000); // 2s

    connect(&m_fastTimer,   &QTimer::timeout, this, &SysInfoReader::requestFastUpdate);
    connect(&m_slowTimer,   &QTimer::timeout, this, &SysInfoReader::requestSlowUpdate);
    connect(&m_sensorTimer, &QTimer::timeout, this, &SysInfoReader::requestSensorUpdate);

    m_fastTimer.start();
    m_slowTimer.start();
    m_sensorTimer.start();
}

// ─── Layer 2: Timer triggers (called on main thread) ──────────────

void SysInfoReader::requestFastUpdate()
{
    // Invoke startWork on worker's thread
    QMetaObject::invokeMethod(m_fastWorker, "startWork", Qt::QueuedConnection);
}

void SysInfoReader::requestSlowUpdate()
{
    QMetaObject::invokeMethod(m_slowWorker, "startWork", Qt::QueuedConnection);
}

void SysInfoReader::requestSensorUpdate()
{
    QMetaObject::invokeMethod(m_sensorWorker, "startWork", Qt::QueuedConnection);
}

// ─── Layer 4: Data aggregation slots (main thread) ────────────────

void SysInfoReader::onFastDataReady(const FastData &d)
{
    bool ramDirty   = false;
    bool storageDirty = false;
    bool cpuDirty   = false;

    // Hysteresis to reduce signal emission
    if (qAbs(m_cpuUsage - d.cpuUsage) > 0.5f) {
        m_cpuUsage = d.cpuUsage;
        cpuDirty = true;
    }
    if (qAbs(m_cpuFreq - d.cpuFreq) > 1.0f) {
        m_cpuFreq = d.cpuFreq;
        cpuDirty = true;
    }

    if (qAbs(m_ramTotal - d.ramTotal) > 0.5f ||
        qAbs(m_ramUsed  - d.ramUsed)  > 0.5f) {
        m_ramTotal   = d.ramTotal;
        m_ramUsed    = d.ramUsed;
        m_ramPercent = d.ramPercent;
        ramDirty = true;
    }

    if (qAbs(m_storageTotal - d.storageTotal) > 0.5f ||
        qAbs(m_storageUsed  - d.storageUsed)  > 0.5f) {
        m_storageTotal   = d.storageTotal;
        m_storageUsed    = d.storageUsed;
        m_storagePercent = d.storagePercent;
        storageDirty = true;
    }

    // Time always updates
    m_currentTime = d.currentTime;

    if (ramDirty)       emit ramChanged();
    if (storageDirty)   emit storageChanged();
    if (cpuDirty)       emit cpuChanged();
    emit timeChanged();
}

void SysInfoReader::onSlowDataReady(const SlowData &d)
{
    if (m_ipAddress != d.ipAddress || m_ifaceName != d.interfaceName) {
        m_ipAddress = d.ipAddress;
        m_ifaceName = d.interfaceName;
        emit networkChanged();
    }
    if (m_wifiSSID != d.wifiSSID) {
        m_wifiSSID = d.wifiSSID;
        emit wifiChanged();
    }
    if (m_linkSpeed != d.linkSpeed) {
        m_linkSpeed = d.linkSpeed;
        emit wifiChanged();
    }
}

void SysInfoReader::onSensorDataReady(const SensorData &d)
{
    bool changed = false;

    if (qAbs(m_temperature - d.temperature) > 0.1f) {
        m_temperature = d.temperature;
        changed = true;
    }
    if (qAbs(m_humidity - d.humidity) > 0.1f) {
        m_humidity = d.humidity;
        changed = true;
    }
    if (m_sensorAvailable != d.available) {
        m_sensorAvailable = d.available;
        changed = true;
    }

    if (changed)
        emit sensorChanged();
}

// ─── QML-called slot ──────────────────────────────────────────────

void SysInfoReader::updateAll()
{
    // This is called from QML Timer to push history arrays
    // Workers are triggered by internal timers, so nothing needed here
    // Keeping for QML compatibility
}