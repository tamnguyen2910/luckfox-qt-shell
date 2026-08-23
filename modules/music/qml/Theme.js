// Theme.js — Shared design system for Music Player
// "Spotify" look: black surfaces + brand green (#1DB954) accent.
// QML picks the active one via `appTheme.isDark` (see MainScreen.qml).
.pragma library

var FONT = "DejaVu Sans"

// ─── DARK (default — classic Spotify black) ──────────────────────────
var dark = {
    // Backgrounds — pure black → #121212 base
    bgTop:      "#000000",
    bgBottom:   "#121212",
    headerBg:   "#0A0A0A",
    panelBg:    "#141414",
    panelBorder:"#282828",

    // Surfaces / cards
    surface:    "#181818",
    surfaceHi:  "#242424",   // hover/pressed card bg
    track:      "#282828",
    bezel:      "#333333",
    disc:       "#111111",   // vinyl base
    groove:     "#232323",   // vinyl groove rings
    activeRow:  "#173623",   // selected track row (green tint)
    rowPress:   "#11281A",   // pressed track row
    rowBorder:  "#1F5C38",

    // Accent — Spotify green family
    accent:     "#1DB954",
    accent2:    "#1ED760",
    accentSoft: "#5CE692",

    // Radial glow behind the player (ARGB)
    glowStrong: "#141DB954",
    glowWeak:   "#001DB954",

    // Text
    text:      "#FFFFFF",
    textDim:   "#B3B3B3",
    textFaint: "#7F7F7F",
    textOnAccent: "#04140A",

    // Status
    ok:          "#1ED760",
    warn:        "#FBAB00",
    idle:        "#7F7F7F",

    bannerBg:    "#262626",
}

// ─── LIGHT ───────────────────────────────────────────────────────────
var light = {
    bgTop:      "#FFFFFF",
    bgBottom:   "#F4F6FA",
    headerBg:   "#F0F3F9",
    panelBg:    "#FFFFFF",
    panelBorder:"#DDE3EE",

    surface:    "#FFFFFF",
    surfaceHi:  "#E8EDF5",
    track:      "#DDE3EE",
    bezel:      "#CBD3E0",
    disc:       "#E6EBF3",
    groove:     "#CDD6E4",
    activeRow:  "#DFF3E5",
    rowPress:   "#EDF9F1",
    rowBorder:  "#86DCA5",

    accent:     "#169C46",
    accent2:    "#1DB954",
    accentSoft: "#0F6B33",

    glowStrong: "#18169C46",
    glowWeak:   "#00169C46",

    text:      "#1A2332",
    textDim:   "#4A5568",
    textFaint: "#8A93A6",
    textOnAccent: "#FFFFFF",

    ok:          "#188A52",
    warn:        "#B45309",
    idle:        "#8A93A6",

    bannerBg:    "#FDF6E8",
}

// Backward-compatible alias — components that haven't been migrated yet
// keep working against the dark palette.
var colors = dark
