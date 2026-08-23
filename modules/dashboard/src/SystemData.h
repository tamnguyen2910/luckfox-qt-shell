#ifndef SYSTEMDATA_H
#define SYSTEMDATA_H

// ============================================================
// Shared Data Transfer Objects (DTOs)
// Layer 3 Workers emit these structs via signals
// Layer 4 Aggregator receives and updates state
// Pure POD + QString — no QObject, no inheritance
// ============================================================

#include <QString>
#include <QMetaType>

struct FastData {
    float cpuUsage       = 0.0f;   // %
    float cpuFreq        = 0.0f;   // MHz
    float ramTotal       = 0.0f;   // MB
    float ramUsed        = 0.0f;   // MB
    float ramPercent     = 0.0f;   // %
    float storageTotal   = 0.0f;   // MB
    float storageUsed    = 0.0f;   // MB
    float storagePercent = 0.0f;   // %
    QString currentTime;            // HH:mm:ss (UTC+7)
};

struct SlowData {
    QString ipAddress = "0.0.0.0";
    QString interfaceName = "wlan0";     // iface holding the IP (wlan0/eth0/ap0...)
    QString wifiSSID  = "Not connected";
    int linkSpeed     = 0;          // from /proc/net/wireless
};

struct SensorData {
    float temperature = 0.0f;       // °C
    float humidity    = 0.0f;       // %
    bool available    = false;      // AHT30 found in hwmon?
};

// Register for QueuedConnection cross-thread signals
Q_DECLARE_METATYPE(FastData)
Q_DECLARE_METATYPE(SlowData)
Q_DECLARE_METATYPE(SensorData)

#endif // SYSTEMDATA_H