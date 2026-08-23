#ifndef SYSINFOWORKER_H
#define SYSINFOWORKER_H

#include <QObject>
#include <QThread>

// ============================================================
// Abstract base class for all system info workers
// Each worker runs in its own QThread
// Communication: signals/slots with QueuedConnection
// ============================================================

class SysInfoWorker : public QObject
{
    Q_OBJECT
public:
    explicit SysInfoWorker(QObject *parent = nullptr) : QObject(parent) {}

    // Called by SysInfoReader to move worker to its own thread
    void setupThread(QThread *thread)
    {
        moveToThread(thread);
        connect(thread, &QThread::started, this, &SysInfoWorker::onThreadStarted);
        connect(thread, &QThread::finished, this, &SysInfoWorker::onThreadFinished);
    }

    // Request worker to do one cycle of work
    // Implemented by derived classes
    Q_INVOKABLE virtual void startWork() = 0;

signals:
    // Derived classes emit their specific data ready signals
    // (declared in derived classes)

protected slots:
    virtual void onThreadStarted() {}
    virtual void onThreadFinished() {}
};

#endif // SYSINFOWORKER_H