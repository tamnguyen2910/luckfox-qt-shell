// ==================================================================
// Theme.js — Unified Design System for Luckfox Shell
// ==================================================================
// Shared theme across all modules: Dashboard, Music, Calendar, WiFi,
// Recorder, Wireframe, and Shell core.
//
// Design Language (v2 "Nordic Aurora"):
//   - Dark base: #0f1115 → #090b0e (deep space, low power on OLED/LCD)
//   - Accent: Teal-cyan #00e5c3 (already in ShellTabBar, unify here)
//   - Semantic status colors: green=ok, amber=warn, red=error, blue=info
//   - Typography: DejaVu Sans Mono for data, DejaVu Sans for UI
//   - Touch targets: 48px minimum, 12px grid spacing
//   - No QtGraphicalEffects dependency (pure QML/Canvas)
//
// LIGHT/DARK:
//   Both complete palettes live here (`var dark`, `var light`) and the
//   active one is selected at runtime through the "appTheme" context
//   property (src/apptheme.{h,cpp}):
//       import "qrc:/shell/components/themes/Theme.js" as T
//       readonly property bool dk: appTheme.isDark
//       readonly property var TD: T.dark
//       readonly property var TL: T.light
//       color: dk ? TD.bgCard : TL.bgCard        // live-switchable
//   `colors` still points at the dark palette for backward compatibility.
//
// Usage in QML:
//   font.pixelSize: T.sizes.primary
// ==================================================================

.pragma library

// ─── DARK PALETTE (default) ──────────────────────────────────────────
var dark = {
    // Backgrounds — unified gradient base
    bgTop:      "#090b0e",   // darkest (top of card gradient)
    bgBottom:   "#0f1115",   // base background
    bgCard:     "#12151c",   // card surface
    bgCardHover:"#1a1e27",   // card hover state
    pageTop:    "#12192a",   // shell page card gradient (top)
    pageBottom: "#0b101c",   // shell page card gradient (bottom)

    // Borders & dividers
    border:     "#2a2e3a",   // card border
    divider:    "#1e222e",   // internal divider line
    faintLine:  "rgba(255,255,255,0.05)",  // faint top/bottom hairlines

    // Text hierarchy
    textPrimary:   "#eef1f7",  // near-white
    textSecondary: "#8a90a2",  // soft gray
    textTertiary:  "#5a5f73",  // muted gray
    textDisabled:  "#3a3e4d",  // disabled

    // Accent (primary brand color)
    accent:      "#00e5c3",   // teal-cyan
    accentHover: "#00f0d4",
    accentSoft:  "rgba(0,229,195,0.08)",  // accent tint bg
    accentBorder:"rgba(0,229,195,0.30)",  // accent border

    // Semantic status colors
    ok:       "#36d399",   // green — success/connected
    warn:     "#fbbf24",   // amber — warning
    error:    "#f87171",   // red — error/offline
    info:     "#60a5fa",   // blue — informational

    // Data visualization colors (matching original Dashboard)
    blue:     "#3b82f6",
    amber:    "#f59e0b",
    green:    "#10b981",
    red:      "#ef4444",
    cyan:     "#06b6d4",

    // Special
    overlay:  "rgba(0,0,0,0.55)",  // modal overlay
    disabled: "#3a4456",          // disabled button bg
}

// ─── LIGHT PALETTE ───────────────────────────────────────────────────
var light = {
    // Backgrounds
    bgTop:      "#ffffff",
    bgBottom:   "#f4f6fa",
    bgCard:     "#ffffff",
    bgCardHover:"#eef2f8",
    pageTop:    "#ffffff",
    pageBottom: "#eaeef5",

    // Borders & dividers
    border:     "#d5dbe6",
    divider:    "#e6eaf1",
    faintLine:  "rgba(26,35,50,0.07)",

    // Text hierarchy
    textPrimary:   "#1a2332",
    textSecondary: "#5a6579",
    textTertiary:  "#8a93a6",
    textDisabled:  "#b8bfcc",

    // Accent — deeper teal for contrast on light surfaces
    accent:      "#00b8a0",
    accentHover: "#00a58f",
    accentSoft:  "rgba(0,184,160,0.10)",
    accentBorder:"rgba(0,184,160,0.35)",

    // Semantic status colors (tuned for light bg)
    ok:       "#188a52",
    warn:     "#b45309",
    error:    "#d64545",
    info:     "#2563eb",

    // Data visualization colors (readable light-mode variants)
    blue:     "#2563eb",
    amber:    "#d97706",
    green:    "#16a34a",
    red:      "#dc2626",
    cyan:     "#0891b2",

    // Special
    overlay:  "rgba(15,23,42,0.40)",
    disabled: "#c3cad6",
}

// Backward compatibility: everything that predates light/dark switching
// reads the dark palette.
var colors = dark

// Convenience selector for JS-side code (not reactive — prefer
// `dk ? T.dark.x : T.light.x` bindings in QML).
function palette(isDark) { return isDark ? dark : light }

// ─── TYPOGRAPHY ───────────────────────────────────────────────────────
var font = "DejaVu Sans"
var fontMono = "DejaVu Sans Mono"

var sizes = {
    // Display
    hero:        24,   // large page titles
    heroSmall:   20,   // secondary titles
    title:       16,   // card headers
    primary:     14,   // body text
    secondary:   12,   // captions
    tertiary:    10,   // tiny labels
    micro:        8,   // smallest readable

    // Data/Monospace
    dataDisplay: 20,   // large data values
    dataPrimary: 15,   // main data
    dataSmall:   12,   // small data
    dataMicro:    9,   // tiny data labels

    // UI elements
    button:      12,
    tabLabel:    10,
    navIcon:     20,
}

// ─── SPACING (8px grid system) ───────────────────────────────────────
var spacing = {
    xs:  4,
    sm:  8,
    md:  12,
    lg:  16,
    xl:  24,
    xxl: 32,
}

// ─── RADIUS ───────────────────────────────────────────────────────────
var radius = {
    sm:    4,
    md:    8,
    lg:    12,
    xl:    16,
    xxl:   20,
    round: 999,
}

// ─── LAYOUT (screen metrics) ──────────────────────────────────────────
var layout = {
    screenW:     800,
    screenH:     480,
    tabBarW:      72,  // vertical tab rail width
    contentX:     96,  // tabBarW + spacing.md
    contentMargins: 12,
    headerH:      40,
    footerH:      48,
}

// ─── ANIMATION DURATIONS ───────────────────────────────────────────────
var duration = {
    instant:  80,   // pressed feedback
    fast:    150,   // color transitions
    normal:  250,   // layout transitions
    slow:    420,   // page slide (shell)
    pulse:   1500,  // breathing animations
}

// ─── GRADIENT PRESETS ─────────────────────────────────────────────────
// Helper: build a 2-stop gradient for a card
function cardGradient(topColor, bottomColor) {
    return {
        stops: [
            { position: 0.0, color: topColor },
            { position: 1.0, color: bottomColor }
        ]
    }
}

// Convenience: the default card gradient (dark palette)
function defaultCardGradient() {
    return cardGradient(colors.bgTop, colors.bgBottom)
}

// ─── COMPONENT THEMES ─────────────────────────────────────────────────
// Card background with border, radius, gradient (dark palette defaults)
// Usage: Rectangle { color: dk ? TD.bgCard : TL.bgCard; ... }
var card = {
    bgColor:      dark.bgCard,
    borderColor:  dark.border,
    radius:       radius.lg,
    borderWidth:  1,
}

// Button default styles
var button = {
    minWidth:    44,
    minHeight:   44,
    cornerRadius: radius.md,
    padding:     12,
    border:      1,
}

// Slider/track styles
var slider = {
    height:      5,
    handleSize:  20,
    trackColor:  dark.divider,
}

// ─── MODULE-SPECIFIC SUB-THEMES (each ships a dark + light variant) ───

// Dashboard: data visualization chrome (series colors come from the
// main palette's blue/amber/green/red/cyan above).
var dashboard = {
    dark: {
        cardColor:  "#12151c",
        cardBorder: "#232b3b",
        barColor:   "#0d1220",   // internal tab strip bg
        hairline:   "#1a2234",   // header underline / chart badge bg
        offline:    "#3a4557",   // sensor-offline side bar
        textColor:  "#e4e8f0",
        textDim:    "#8a90a2",
        gaugeTick:  "#2c3752",
    },
    light: {
        cardColor:  "#ffffff",
        cardBorder: "#d5dbe6",
        barColor:   "#f0f3f9",
        hairline:   "#dde3ee",
        offline:    "#c3cad6",
        textColor:  "#1a2332",
        textDim:    "#5a6579",
        gaugeTick:  "#c3cad6",
    },
}

// Calendar: Slate Aurora (dark) / warm stone (light)
var calendar = {
    light: {
        bg:         "#f4f6fa",
        surface:    "#ffffff",
        surfaceHover: "#eef2f8",
        accent:     "#00b8a0",
        accentDim:  "#00a58f",
        accentSoft: "#d7f2ee",
        text:       "#1a2332",
        textDim:    "#5a6579",
        textMuted:  "#8a93a6",
        todayFill:  "#00b8a0",
        todayText:  "#ffffff",
        holiday:    "#c2542f",
        holidaySoft:"#f7e3da",
        border:     "#d5dbe6",
        divider:    "rgba(26,35,50,0.10)",
        shadow:     "rgba(26,35,50,0.08)",
    },
    dark: {
        bg:         "#1A2332",
        surface:    "#253344",
        surfaceHover: "#2F4055",
        accent:     "#5CCEFA",
        accentDim:  "#38BDF8",
        accentSoft: "#1E3550",
        text:       "#F0F4F8",
        textDim:    "#94A3B8",
        textMuted:  "#64748B",
        todayFill:  "#5CCEFA",
        todayText:  "#1A2332",
        holiday:    "#FB923C",
        holidaySoft:"#3D2A1A",
        border:     "#334155",
        divider:    "#2D3D50",
        shadow:     "rgba(0,0,0,0.30)",
    },
}

// Music: teal accent family (Spotify green retired — the whole shell
// shares the teal brand now).
var music = {
    dark: {
        bgTop:      "#07090A",
        bgBottom:   "#101213",
        headerBg:   "#0E0F10",
        panelBg:    "#121212",
        panelBorder:"#22262b",

        surface:    "#181818",
        surfaceHi:  "#252525",
        track:      "#2A2A2A",
        bezel:      "#33383f",
        disc:       "#0C111C",
        groove:     "#1E2836",

        accent:     "#00e5c3",
        accent2:    "#33ffe0",
        accentSoft: "#8ff5e6",

        glowStrong: "#1400E5C3",   // radial accent glow behind player
        glowWeak:   "#0000E5C3",

        text:      "#E6E6E6",
        textDim:   "#B3B3B3",
        textFaint: "#8A8A8A",
        textOnAccent:"#04120f",

        bannerBg:  "#1A1F29",

        ok:         "#36d399",
        warn:       "#FBAB00",
        idle:       "#8E8E8E",
    },
    light: {
        bgTop:      "#ffffff",
        bgBottom:   "#f4f6fa",
        headerBg:   "#f0f3f9",
        panelBg:    "#ffffff",
        panelBorder:"#dde3ee",

        surface:    "#ffffff",
        surfaceHi:  "#e8edf5",
        track:      "#dde3ee",
        bezel:      "#cbd3e0",
        disc:       "#e6ebf3",
        groove:     "#cdd6e4",

        accent:     "#00b8a0",
        accent2:    "#00d3b6",
        accentSoft: "#007767",

        glowStrong: "#1800B8A0",
        glowWeak:   "#0000B8A0",

        text:      "#1a2332",
        textDim:   "#4a5568",
        textFaint: "#8a93a6",
        textOnAccent:"#ffffff",

        bannerBg:  "#fdf6e8",

        ok:         "#188a52",
        warn:       "#b45309",
        idle:       "#8a93a6",
    },
}

// WiFi: accent follows the shell teal; surfaces from the slate family
var wifi = {
    dark: {
        accent:       "#00e5c3",
        accentDim:    "#00c0a6",
        accentSoft:   "#12332f",
        cardTop:      "#1c2533",
        cardBottom:   "#141a26",
        headerBg:     "#222c3f",
        surface:      "#273142",
        surfaceHover: "#324158",
        itemBg:       "#273142",
        itemBorder:   "#3c4a63",
        pressedBg:    "#0f8f7d",
        keyBg:        "#2c3850",
        keyBorder:    "#3f4d68",
        keyPressed:   "#3a4a66",
        text:         "#f3f6fb",
        textDim:      "#aab4c5",
        textMute:     "#7e8aa0",
        onAccent:     "#04120f",
        dialogBg:     "#0b1119",
        weakWarnBg:   "#3a1f1f",
        spinner:      "#0e1422",
        good:         "#36d399",
        warn:         "#fbbf24",
        error:        "#f87171",
        errBar:       "#dc2626",
        errPress:     "#991b1b",
        disabled:     "#3a4456",
        faintLine:    "rgba(255,255,255,0.10)",
    },
    light: {
        accent:       "#00b8a0",
        accentDim:    "#00957f",
        accentSoft:   "#d7f2ee",
        cardTop:      "#ffffff",
        cardBottom:   "#eef2f8",
        headerBg:     "#f0f3f9",
        surface:      "#ffffff",
        surfaceHover: "#e8edf5",
        itemBg:       "#ffffff",
        itemBorder:   "#d5dbe6",
        pressedBg:    "#00a58f",
        keyBg:        "#f0f3f9",
        keyBorder:    "#cbd3e0",
        keyPressed:   "#d5dbe6",
        text:         "#1a2332",
        textDim:      "#4a5568",
        textMute:     "#8a93a6",
        onAccent:     "#ffffff",
        dialogBg:     "#f4f6fa",
        weakWarnBg:   "#fbeaea",
        spinner:      "#ffffff",
        good:         "#188a52",
        warn:         "#b45309",
        error:        "#d64545",
        errBar:       "#c2352f",
        errPress:     "#8f2018",
        disabled:     "#c3cad6",
        faintLine:    "rgba(26,35,50,0.10)",
    }
}

// Recorder (voicetest)
var recorder = {
    dark: {
        cardTop:      "#131b2e",
        cardBottom:   "#0b0f1a",
        waveBg:       "#0e1524",
        waveIdle:     "#33415c",
        accent:       "#00e5c3",
        accentDisc:   "rgba(0,229,195,0.10)",
        accentDiscHot:"rgba(0,229,195,0.35)",
        error:        "#ff5e5e",
        duration:     "#f1c40f",   // semantic: recording timer
        text:         "#c9d4e6",
        textDim:      "#94a3b8",
        textMute:     "#64748b",
    },
    light: {
        cardTop:      "#ffffff",
        cardBottom:   "#eef2f8",
        waveBg:       "#f0f3f9",
        waveIdle:     "#c3cad6",
        accent:       "#00b8a0",
        accentDisc:   "rgba(0,184,160,0.12)",
        accentDiscHot:"rgba(0,184,160,0.35)",
        error:        "#d64545",
        duration:     "#a16207",
        text:         "#1a2332",
        textDim:      "#5a6579",
        textMute:     "#8a93a6",
    },
}

// Wireframe: only text lives in QML; shapes are painted in C++
var wireframe = {
    dark: {
        title:  "#e1e1f0",
        status: "#aaaaaa",
    },
    light: {
        title:  "#1a2332",
        status: "#5a6579",
    },
}

// ─── FONT HELPER ────────────────────────────────────────────────────────
// Returns a FontLoader-friendly string for importing into QML
function fontFamily() { return font }
function fontFamilyMono() { return fontMono }

// ─── EXPORT ───────────────────────────────────────────────────────────
// The entire theme is available as: T.dark / T.light (T.colors = T.dark).
// Sub-themes: T.dashboard, T.calendar, T.music, T.wifi, T.recorder,
// T.wireframe — each with a .dark and .light variant.
