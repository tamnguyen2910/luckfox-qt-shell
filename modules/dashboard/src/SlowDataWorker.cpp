#include "SlowDataWorker.h"
#include <QFile>
#include <QRegularExpression>
#include <QTimer>

SlowDataWorker::SlowDataWorker(QObject *parent)
    : SysInfoWorker(parent)
{
    m_ipProcess = new QProcess(this);
    m_iwProcess = new QProcess(this);
    m_timeoutTimer = new QTimer(this);
    m_timeoutTimer->setSingleShot(true);
    m_timeoutTimer->setInterval(3000);  // 3s timeout per process

    connect(m_ipProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &SlowDataWorker::onIpFinished);
    connect(m_iwProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &SlowDataWorker::onSsidFinished);
    connect(m_timeoutTimer, &QTimer::timeout,
            this, &SlowDataWorker::onProcessTimeout);
}

SlowDataWorker::~SlowDataWorker()
{
    if (m_ipProcess->state() != QProcess::NotRunning)
        m_ipProcess->kill();
    if (m_iwProcess->state() != QProcess::NotRunning)
        m_iwProcess->kill();
}

void SlowDataWorker::startWork()
{
    // Reset state
    m_pendingData = SlowData();
    m_ipDone = false;
    m_iwDone = false;
    m_timeoutTimer->start();

    // Start both processes in parallel
    // IP scoped to wlan0 — same as reference app (ip -4 addr show wlan0).
    // Querying all interfaces can pick a wrong address (USB RNDIS eth0, softAP...)
    m_ipProcess->start("ip", QStringList() << "-4" << "addr" << "show" << "wlan0");
    m_iwProcess->start("iwgetid", QStringList() << "-r");

    // Also read link speed immediately (non-blocking file read)
    readLinkSpeed();
}

void SlowDataWorker::onIpFinished(int exitCode, QProcess::ExitStatus)
{
    if (exitCode == 0) {
        QString out = m_ipProcess->readAllStandardOutput();
        // Robust regex: tolerates with/without /prefix, extra whitespace, inet6 lines
        static const QRegularExpression re("\\binet\\s+(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})(?:/\\d{1,2})?");
        QRegularExpressionMatch match = re.match(out);
        if (match.hasMatch()) {
            m_pendingData.ipAddress = match.captured(1);
            m_pendingData.interfaceName = "wlan0";
        }
    }
    m_ipDone = true;
    checkBothDone();
}

void SlowDataWorker::onSsidFinished(int exitCode, QProcess::ExitStatus)
{
    if (exitCode == 0) {
        QString ssid = QString(m_iwProcess->readAllStandardOutput()).trimmed();
        if (!ssid.isEmpty())
            m_pendingData.wifiSSID = ssid;
    }
    m_iwDone = true;
    checkBothDone();
}

void SlowDataWorker::onProcessTimeout()
{
    // Kill hanging processes
    if (m_ipProcess->state() != QProcess::NotRunning)
        m_ipProcess->kill();
    if (m_iwProcess->state() != QProcess::NotRunning)
        m_iwProcess->kill();

    // Mark as done if not already
    if (!m_ipDone) m_ipDone = true;
    if (!m_iwDone) m_iwDone = true;
    checkBothDone();
}

void SlowDataWorker::readLinkSpeed()
{
    QFile wireless("/proc/net/wireless");
    if (wireless.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QByteArray data = wireless.readAll();
        QRegularExpression wsRe("wlan0:\\s+\\S+\\s+\\S+\\s+(\\d+)");
        QRegularExpressionMatch wsMatch = wsRe.match(QString(data));
        if (wsMatch.hasMatch()) {
            m_pendingData.linkSpeed = wsMatch.captured(1).toInt();
        }
    }
}

void SlowDataWorker::checkBothDone()
{
    if (m_ipDone && m_iwDone) {
        m_timeoutTimer->stop();
        emit slowDataReady(m_pendingData);
    }
}