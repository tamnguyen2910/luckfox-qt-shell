// Theme.js — UI v6: Simple theme data, no reactive logic here.
// All reactive bindings handled by QML properties in MainScreen.

var Theme = {
    // =================================================================
    // THEME DATA (static)
    // =================================================================
    light: {
        bg:              "#AFAFA4",
        surface:         "#BCBAB0",
        surfaceHover:    "#A2A096",
        accent:          "#4E8E7E",
        accentDim:       "#417A6D",
        accentSoft:      "#A9C8BE",
        text:            "rgba(34,32,26,0.85)",
        textDim:         "rgba(34,32,26,0.52)",
        textMuted:       "rgba(34,32,26,0.32)",
        todayFill:       "#4E8E7E",
        todayText:       "#FFFFFF",
        holiday:         "#A85040",
        holidaySoft:     "#CEB8AE",
        border:          "rgba(34,32,26,0.12)",
        divider:         "rgba(34,32,26,0.10)",
        shadow:          "rgba(34,32,26,0.08)",
    },

    dark: {
        bg:              "#1A2332",
        surface:         "#253344",
        surfaceHover:    "#2F4055",
        accent:          "#5CCEFA",
        accentDim:       "#38BDF8",
        accentSoft:      "#1E3550",
        text:            "#F0F4F8",
        textDim:         "#94A3B8",
        textMuted:       "#64748B",
        todayFill:       "#5CCEFA",
        todayText:       "#1A2332",
        holiday:         "#FB923C",
        holidaySoft:     "#3D2A1A",
        border:          "#334155",
        divider:         "#2D3D50",
        shadow:          "rgba(0,0,0,0.30)",
    },

    // =================================================================
    // FONT SCALE
    // =================================================================
    font: {
        tiny:       10,
        small:      12,
        medium:     14,
        large:      16,
        xlarge:     20,
        header:     26,
        heroYear:   16,
        clock:      52,
        clockSmall: 14,
        dayNumber:  22,
        lunar:      12,
        arrow:      30,
        button:     14,
        label:      11,
        weekday:    14,
    },

    // =================================================================
    // SPACING
    // =================================================================
    spacing: { xs: 4, sm: 6, md: 10, lg: 14, xl: 18, xxl: 24 },

    // =================================================================
    // RADIUS
    // =================================================================
    radius:  { sm: 6, md: 8, lg: 12, xl: 16, xxl: 20, round: 999 },

    // =================================================================
    // LAYOUT
    // =================================================================
    layout: {
        width:          800,
        height:         480,
        headerHeight:   64,
        statusHeight:   0,
        gridWidth:      520,
        rightWidth:     280,
    },

    // =================================================================
    // TRANSITION
    // =================================================================
    transition: {
        fast:   150,
        normal: 250,
        slow:   400,
    },
};

// Derived layout
Theme.layout.gridHeight = Theme.layout.height - Theme.layout.headerHeight - Theme.layout.statusHeight;
Theme.layout.cellW      = Math.floor(Theme.layout.gridWidth / 7);
Theme.layout.cellH      = Math.floor(Theme.layout.gridHeight / 7);
