import QtQuick 2.12
import QtQuick.Controls 2.12
import "Theme.js" as Theme

// UI v6 — Colors as QML properties, updated directly on toggle.

ApplicationWindow {
    id: mainScreen
    width: 800
    height: 480
    color: bg
    visible: true
    font.family: "DejaVu Sans"

    property var backend: null
    property bool isDark: false

    // Theme colors as QML properties
    property string bg: Theme.Theme.light.bg
    property string surface: Theme.Theme.light.surface
    property string surfaceHover: Theme.Theme.light.surfaceHover
    property string accent: Theme.Theme.light.accent
    property string accentDim: Theme.Theme.light.accentDim
    property string accentSoft: Theme.Theme.light.accentSoft
    property string text: Theme.Theme.light.text
    property string textDim: Theme.Theme.light.textDim
    property string textMuted: Theme.Theme.light.textMuted
    property string todayFill: Theme.Theme.light.todayFill
    property string todayText: Theme.Theme.light.todayText
    property string holiday: Theme.Theme.light.holiday
    property string holidaySoft: Theme.Theme.light.holidaySoft
    property string border: Theme.Theme.light.border
    property string divider: Theme.Theme.light.divider
    property string shadow: Theme.Theme.light.shadow

    property int currentYear: 2026
    property int currentMonth: 8
    property int selectedDay: -1
    property var monthDaysData: []

    property var todayHero: null
    property string clockText: ""

    property int _cachedDayKey: -1

    function applyTheme(dark) {
        var t = dark ? Theme.Theme.dark : Theme.Theme.light
        isDark = dark
        bg = t.bg
        surface = t.surface
        surfaceHover = t.surfaceHover
        accent = t.accent
        accentDim = t.accentDim
        accentSoft = t.accentSoft
        text = t.text
        textDim = t.textDim
        textMuted = t.textMuted
        todayFill = t.todayFill
        todayText = t.todayText
        holiday = t.holiday
        holidaySoft = t.holidaySoft
        border = t.border
        divider = t.divider
        shadow = t.shadow
    }

    function toggleTheme() {
        applyTheme(!isDark)
    }

    Component.onCompleted: {
        if (typeof LunarBackend !== "undefined") backend = LunarBackend
        var now = new Date()
        if (backend) {
            var t = backend.today()
            currentYear = t.year
            currentMonth = t.month
        } else {
            currentYear = now.getFullYear()
            currentMonth = now.getMonth() + 1
        }
        refreshTodayHero()
        _cachedDayKey = dayKey()
        loadMonth()
        tickClock()
    }

    HeaderBar {
        id: header
        x: 0; y: 0
        width: Theme.Theme.layout.width
        height: Theme.Theme.layout.headerHeight
        monthTitle: computeMonthTitle(currentYear, currentMonth)
        displayYear: currentYear
        isDark: mainScreen.isDark
        onPrevMonth: mainScreen.prevMonth()
        onNextMonth: mainScreen.nextMonth()
        onGoToToday: mainScreen.goToToday()
        onToggleTheme: mainScreen.toggleTheme()
    }

    Rectangle {
        id: gridPanel
        x: 0
        y: Theme.Theme.layout.headerHeight
        width: Theme.Theme.layout.gridWidth
        height: Theme.Theme.layout.gridHeight
        color: mainScreen.surface

        MonthGrid {
            id: monthGrid
            anchors.fill: parent
            anchors.margins: Theme.Theme.spacing.sm
            monthDays: mainScreen.monthDaysData
            isDark: mainScreen.isDark
            onDayClicked: { /* read-only */ }
            onPrevMonth: mainScreen.prevMonth()
            onNextMonth: mainScreen.nextMonth()
        }
    }

    Rectangle {
        id: rightPanel
        x: Theme.Theme.layout.gridWidth
        y: Theme.Theme.layout.headerHeight
        width: Theme.Theme.layout.rightWidth
        height: Theme.Theme.layout.gridHeight
        color: "transparent"

        Rectangle {
            id: heroCard
            anchors.fill: parent
            anchors.margins: Theme.Theme.spacing.sm
            color: mainScreen.surface
            radius: Theme.Theme.radius.xl

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: Theme.Theme.spacing.xl
                anchors.bottomMargin: Theme.Theme.spacing.xl
                width: 3
                radius: 2
                color: mainScreen.accent
            }

            Text {
                id: heroClock
                text: mainScreen.clockText
                font.pixelSize: Theme.Theme.font.clock
                font.family: "DejaVu Sans"
                font.weight: Font.Light
                color: mainScreen.text
                horizontalAlignment: Text.AlignLeft
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.topMargin: 28
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                anchors.top: heroClock.bottom
                anchors.topMargin: 16
                height: 1
                color: mainScreen.divider
            }

            Text {
                id: heroDate
                text: mainScreen.heroDateStr
                font.pixelSize: Theme.Theme.font.large
                font.family: "DejaVu Sans"
                font.weight: Font.Medium
                color: mainScreen.text
                anchors.top: heroClock.bottom
                anchors.topMargin: 32
                anchors.left: parent.left
                anchors.leftMargin: 24
            }

            Text {
                id: heroDateNum
                text: mainScreen.heroDateNumStr
                font.pixelSize: 64
                font.family: "DejaVu Sans"
                font.weight: Font.Bold
                color: mainScreen.accent
                anchors.top: heroDate.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.leftMargin: 24
            }

            Rectangle {
                id: lunarChip
                anchors.top: heroDate.bottom
                anchors.topMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 24
                width: lunarText.implicitWidth + 16
                height: lunarText.implicitHeight + 10
                radius: Theme.Theme.radius.round
                color: mainScreen.accentSoft

                Text {
                    id: lunarText
                    text: mainScreen.heroLunarStr
                    font.pixelSize: Theme.Theme.font.medium
                    font.family: "DejaVu Sans"
                    font.weight: Font.Medium
                    color: mainScreen.accent
                    anchors.centerIn: parent
                }
            }

            Text {
                id: heroLunar
                text: mainScreen.heroLunarFullStr
                font.pixelSize: Theme.Theme.font.medium
                font.family: "DejaVu Sans"
                color: mainScreen.textDim
                anchors.top: heroDateNum.bottom
                anchors.topMargin: 20
                anchors.left: parent.left
                anchors.leftMargin: 24
                wrapMode: Text.Wrap
                width: parent.width - 48
            }
        }
    }

    MouseArea {
        id: swipeOverlay
        x: 0
        y: Theme.Theme.layout.headerHeight
        width: Theme.Theme.layout.gridWidth
        height: Theme.Theme.layout.gridHeight
        z: 3

        property real dragStartX: 0
        property real dragStartY: 0
        property bool isDragging: false

        onPressed: { dragStartX = mouseX; dragStartY = mouseY; isDragging = false }
        onPositionChanged: {
            if (!isDragging) {
                var dx = mouseX - dragStartX
                var dy = mouseY - dragStartY
                if (Math.abs(dx) > 25 && Math.abs(dx) > Math.abs(dy) * 1.5) isDragging = true
            }
        }
        onReleased: {
            if (isDragging) {
                var dx = mouseX - dragStartX
                if (dx < -50) nextMonth()
                else if (dx > 50) prevMonth()
            }
            isDragging = false
        }
    }

    MouseArea {
        id: edgeSwipeArea
        width: 40; height: parent.height
        anchors.left: parent.left; anchors.top: parent.top
        z: 999
        property real startX: 0; property real startY: 0; property bool tracking: false
        onPressed: { startX = mouseX; startY = mouseY; tracking = true }
        onReleased: {
            var dx = mouseX - startX; var dy = Math.abs(mouseY - startY)
            if (dx > 80 && dy < 150) Qt.quit()
            else if (dx < -50) prevMonth()
            tracking = false
        }
        onCanceled: tracking = false
    }

    Timer {
        id: tickTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            var now = new Date()
            interval = 1000 - now.getMilliseconds()
            tickClock()

            var key = dayKey()
            if (key !== _cachedDayKey) {
                _cachedDayKey = key
                refreshTodayHero()
                if (currentYear === now.getFullYear() && currentMonth === (now.getMonth() + 1)) {
                    loadMonth()
                }
            }
        }
    }

    function tickClock() {
        if (backend) {
            clockText = backend.timeText()
        } else {
            clockText = Qt.formatTime(new Date(), "HH:mm:ss")
        }
    }

    function dayKey() {
        var now = new Date()
        return now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate()
    }

    function refreshTodayHero() {
        todayHero = backend ? backend.todayInfo() : computeTodayInfoJS()
    }

    function loadMonth() {
        monthDaysData = backend ? backend.monthGrid(currentYear, currentMonth)
                                : computeMonthGridJS(currentYear, currentMonth)
    }
    function prevMonth() {
        currentMonth--
        if (currentMonth < 1) { currentMonth = 12; currentYear-- }
        loadMonth()
    }
    function nextMonth() {
        currentMonth++
        if (currentMonth > 12) { currentMonth = 1; currentYear++ }
        loadMonth()
    }
    function goToToday() {
        if (backend) { var t = backend.today(); currentYear = t.year; currentMonth = t.month }
        else { var n = new Date(); currentYear = n.getFullYear(); currentMonth = n.getMonth() + 1 }
        loadMonth()
    }

    property string heroDateStr: todayHero ? (todayHero.weekdayName + ", " + todayHero.dateStr) : ""
    property string heroDateNumStr: todayHero ? ("" + todayHero.day) : ""
    property string heroLunarStr: todayHero ? (todayHero.lunarDayName + " " + todayHero.lunarMonthName) : ""
    property string heroLunarFullStr: todayHero ? ("Nguyệt lịch: " + todayHero.lunarDayName + " " + todayHero.lunarMonthName + " năm " + (todayHero.canChiYear || todayHero.lunarYear)) : ""

    function computeMonthTitle(y, m) {
        var names = ["Tháng 1","Tháng 2","Tháng 3","Tháng 4","Tháng 5","Tháng 6",
                          "Tháng 7","Tháng 8","Tháng 9","Tháng 10","Tháng 11","Tháng 12"]
        return names[m - 1]
    }

    function canChiYearJS(y) {
        var can = ["Giáp","Ất","Bính","Đinh","Mậu","Kỷ","Canh","Tân","Nhâm","Quý"]
        var chi = ["Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"]
        var c = (y - 4) % 10; if (c < 0) c += 10
        var z = (y - 4) % 12; if (z < 0) z += 12
        return can[c] + " " + chi[z]
    }

    function computeTodayInfoJS() {
        var now = new Date()
        var names = ["Chủ Nhật","Thứ Hai","Thứ Ba","Thứ Tư","Thứ Năm","Thứ Sáu","Thứ Bảy"]
        var f = function(n) { return n < 10 ? "0" + n : "" + n }
        return {
            day: now.getDate(), month: now.getMonth() + 1, year: now.getFullYear(),
            weekday: now.getDay(), weekdayName: names[now.getDay()],
            lunarDay: now.getDate(), lunarMonth: now.getMonth() + 1, lunarYear: now.getFullYear(),
            lunarMonthName: "tháng " + (now.getMonth() + 1),
            lunarDayName: lunarDayName(now.getDate()),
            canChiYear: canChiYearJS(now.getFullYear()),
            dateStr: f(now.getDate()) + "/" + f(now.getMonth() + 1) + "/" + now.getFullYear(),
            holidays: []
        }
    }

    function lunarDayName(d) {
        if (d === 15) return "Rằm"
        if (d >= 1 && d <= 10) return "Mùng " + d
        return "Ngày " + d
    }

    function computeMonthGridJS(y, m) {
        var daysInMonth = getDaysInSolarMonth(y, m)
        var firstDay = new Date(y, m - 1, 1).getDay()
        var mondayIndex = (firstDay + 6) % 7
        var today = new Date()
        var todayY = today.getFullYear(), todayM = today.getMonth() + 1, todayD = today.getDate()
        var isCurrent = (y === todayY && m === todayM)
        var daysPrev = getDaysInSolarMonth(y, m - 1)
        var g = []
        for (var r = 0; r < 6; r++) {
            for (var c = 0; c < 7; c++) {
                var idx = r * 7 + c
                var dn = idx - mondayIndex + 1
                var entry = { solarDay: 0, lunarDay: 0, isToday: false, isHoliday: false, holidayName: "", isNext: false, isPrev: false }
                if (dn >= 1 && dn <= daysInMonth) {
                    entry.solarDay = dn; entry.lunarDay = dn; entry.isToday = isCurrent && dn === todayD
                } else if (dn < 1) {
                    entry.solarDay = daysPrev + dn + 1; entry.isPrev = true
                } else {
                    entry.solarDay = dn - daysInMonth; entry.isNext = true
                }
                g.push(entry)
            }
        }
        return g
    }

    function getDaysInSolarMonth(y, m) {
        if (m < 1) { m = 12; y-- }
        if (m > 12) { m = 1; y++ }
        var d = [31, (isLeapYear(y) ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        return d[m - 1]
    }
    function isLeapYear(y) { return (y % 4 === 0 && (y % 100 !== 0 || y % 400 === 0)) }
}
