#ifndef APPTHEME_H
#define APPTHEME_H

#include <QObject>

// Global light/dark theme switch, exposed to QML as the "appTheme"
// context property. The choice persists in
// QSettings("EmbeddedApps","LuckfoxShell") under "theme/isDark" so it
// survives reboots; default is dark.
class AppTheme : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isDark READ isDark WRITE setIsDark NOTIFY isDarkChanged)

public:
    explicit AppTheme(QObject *parent = nullptr);

    bool isDark() const { return m_isDark; }
    void setIsDark(bool dark);

signals:
    void isDarkChanged();

private:
    bool m_isDark;
};

#endif // APPTHEME_H
