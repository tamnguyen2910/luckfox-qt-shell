#ifndef SLOWDATAWORKER_H
#define SLOWDATAWORKER_H

#include "SysInfoWorker.h"
#include "SystemData.h"
#include <QProcess>
#include <QTimer>

// ============================================================
// Worker-Slow (Layer 3, Thread B)
// Handles data that changes infrequently (10s interval)
// Uses NON-BLOCKING QProcess with signal/slot
// Fallback to /proc reads if commands fail
// Timeout guard: 3s per process
// ============================================================

class SlowDataWorker : public SysInfoWorker
{
    Q_OBJECT
public:
    explicit SlowDataWorker(QObject *parent = nullptr);
    ~SlowDataWorker();
    Q_INVOKABLE void startWork() override;

signals:
    void slowDataReady(const SlowData &data);

private slots:
    void onIpFinished(int exitCode, QProcess::ExitStatus);
    void onSsidFinished(int exitCode, QProcess::ExitStatus);
    void onProcessTimeout();

private:
    void readLinkSpeed();
    void checkBothDone();

    QProcess *m_ipProcess = nullptr;
    QProcess *m_iwProcess = nullptr;
    SlowData m_pendingData;
    bool m_ipDone = false;
    bool m_iwDone = false;
    QTimer *m_timeoutTimer = nullptr;
};

#endif // SLOWDATAWORKER_H