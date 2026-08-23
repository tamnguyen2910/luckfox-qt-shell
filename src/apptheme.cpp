#include "apptheme.h"

// Light mode retired: the app is locked to the dark theme.
// AppTheme stays so every QML `dk ? dark : light` binding keeps working,
// it just always resolves to the dark half of each palette.

AppTheme::AppTheme(QObject *parent)
    : QObject(parent)
    , m_isDark(true)   // locked dark
{
}

void AppTheme::setIsDark(bool dark)
{
    // No-op: theme switching removed per design decision.
    Q_UNUSED(dark)
}
