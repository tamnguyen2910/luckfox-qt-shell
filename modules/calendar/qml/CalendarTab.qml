import QtQuick 2.12
import QtQuick.Controls 2.12
import "Theme.js" as Theme
import "qrc:/shell/components/themes/Theme.js" as T

// CalendarTab — embeds the 01_Calendar calendar UI as a tab inside the
// Luckfox Shell StackLayout. Root is a plain Item (compatible with
// Loader/StackLayout parents), preserving the original hero panel, month
// grid and live clock. Colors follow the global appTheme light/dark.
Item {
    id: calendarTab
    anchors.fill: parent

    // ---- Global live theme (appTheme) + shared palette ----
    readonly property bool dk: appTheme.isDark
    readonly property var pal: dk ? T.calendar.dark : T.calendar.light

    readonly property color cardTop:      pal.bg
    readonly property color cardBottom:   dk ? T.calendar.dark.bg : T.light.pageBottom
    readonly property color headerBg:     pal.surface
    readonly property color itemBg:       pal.surface
    readonly property color itemBorder:   pal.border
    readonly property color itemHover:    pal.surfaceHover
    readonly property color accent:       pal.accent
    readonly property color accentDim:    pal.accentDim
    readonly property color accentSoft:   pal.accentSoft
    readonly property color text:         pal.text
    readonly property color textDim:      pal.textDim
    readonly property color textMute:     pal.textMuted
    readonly property color todayFill:    pal.todayFill
    readonly property color todayText:    pal.todayText
    readonly property color holiday:      pal.holiday
    readonly property color holidaySoft:  pal.holidaySoft
    readonly property string faintLine:   pal.divider

    // ---- Calendar state ----
    property int currentYear: 2026
    property int currentMonth: 8
    property int selectedDay: -1
    property var monthDaysData: []
    property var todayHero: null
    property string clockText: ""
    property int _cachedDayKey: -1
    property var backend: LunarBackend   // injected by shell main.cpp context property

    // ---- Responsive layout (parent is narrower than Theme's 800px canvas) ----
    readonly property real rightW: parent ? Math.max(200, Math.min(parent.width * 0.36, 320)) : Theme.Theme.layout.rightWidth
    readonly property real gridW: parent ? parent.width - rightW : Theme.Theme.layout.gridWidth
    readonly property real gridH: parent ? parent.height - Theme.Theme.layout.headerHeight : Theme.Theme.layout.gridHeight

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

    // ---- Card (Slate Aurora gradient, matches shell page background) ----
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 14
        clip: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: calendarTab.cardTop }
            GradientStop { position: 1.0; color: calendarTab.cardBottom }
        }

        // ---- Header bar ----
        Item {
            id: headerBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: parent.right
            height: Theme.Theme.layout.headerHeight

            Rectangle { anchors.fill: parent; color: calendarTab.headerBg }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: calendarTab.faintLine }

            Text {
                id: monthTitle
                text: computeMonthTitle(currentYear, currentMonth).toUpperCase()
                font.pixelSize: Theme.Theme.font.label
                font.family: "DejaVu Sans"
                font.weight: Font.Medium
                font.letterSpacing: 1.0
                color: calendarTab.textDim
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -12
            }
            Text {
                text: currentYear
                font.pixelSize: Theme.Theme.font.heroYear
                font.family: "DejaVu Sans"
                font.weight: Font.DemiBold
                color: calendarTab.text
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 14
            }

            // Prev / Next month
            Rectangle {
                id: prevBtn
                width: 44; height: 44; radius: 22
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: Theme.Theme.spacing.sm
                Text { text: "‹"; font.pixelSize: Theme.Theme.font.arrow; font.family: "DejaVu Sans"; color: calendarTab.accent; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; onClicked: calendarTab.prevMonth() }
            }
            Rectangle {
                id: nextBtn
                width: 44; height: 44; radius: 22
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right; anchors.rightMargin: Theme.Theme.spacing.sm
                Text { text: "›"; font.pixelSize: Theme.Theme.font.arrow; font.family: "DejaVu Sans"; color: calendarTab.accent; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; onClicked: calendarTab.nextMonth() }
            }
            // Today button
            Rectangle {
                id: todayBtn
                width: todayLabel.implicitWidth + Theme.Theme.spacing.xl * 2
                height: 36; radius: Theme.Theme.radius.round
                color: calendarTab.accent
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: nextBtn.left; anchors.rightMargin: Theme.Theme.spacing.md
                Text {
                    id: todayLabel
                    text: "Hôm nay"; font.pixelSize: Theme.Theme.font.button; font.bold: true
                    font.family: "DejaVu Sans"; color: calendarTab.todayText; anchors.centerIn: parent
                }
                MouseArea { anchors.fill: parent; onClicked: calendarTab.goToToday() }
            }
        }

        // ---- Month grid ----
        Rectangle {
            id: gridPanel
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: Theme.Theme.layout.headerHeight
            width: calendarTab.gridW
            color: calendarTab.itemBg
            border.width: 1; border.color: calendarTab.itemBorder

            Grid {
                id: grid
                anchors.fill: parent
                anchors.margins: Theme.Theme.spacing.sm
                columns: 7

                readonly property real cellW: width / 7
                readonly property real cellH: height / 7

                Repeater {
                    model: 7
                    delegate: Item {
                        width: grid.cellW; height: grid.cellH
                        Text {
                            text: calendarTab.dayNames[index]
                            font.pixelSize: Theme.Theme.font.weekday
                            font.family: "DejaVu Sans"
                            font.weight: Font.Medium
                            font.letterSpacing: 0.3
                            color: index === 6 ? calendarTab.holiday : (index === 5 ? calendarTab.accentDim : calendarTab.textDim)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            anchors.centerIn: parent
                        }
                    }
                }

                Repeater {
                    model: monthDaysData
                    delegate: Rectangle {
                        id: cell
                        width: grid.cellW - 4; height: grid.cellH - 4
                        radius: Theme.Theme.radius.md
                        readonly property bool isEmpty: !modelData || modelData.solarDay <= 0
                        readonly property bool isToday: modelData && modelData.isToday
                        readonly property bool isHoliday: modelData && modelData.isHoliday
                        readonly property bool isNeighbor: modelData && (modelData.isNext || modelData.isPrev)
                        opacity: cell.isNeighbor ? 0.4 : 1.0
                        color: cell.isToday ? calendarTab.todayFill : "transparent"
                        border.width: 1
                        border.color: cell.isToday ? "transparent" : calendarTab.itemBorder

                        Rectangle {
                            visible: cell.isToday
                            anchors.centerIn: parent
                            width: 42; height: 42; radius: 21
                            color: "transparent"
                            border.width: 1.5; border.color: calendarTab.todayFill
                            opacity: 0.3
                        }

                        Text {
                            text: (!cell.isEmpty && modelData.solarDay > 0) ? modelData.solarDay : ""
                            font.pixelSize: Theme.Theme.font.dayNumber
                            font.family: "DejaVu Sans"
                            font.bold: cell.isToday
                            color: cell.isToday ? calendarTab.todayText : (cell.isNeighbor ? calendarTab.textMute : calendarTab.text)
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: Math.max(2, (grid.cellH - 50) / 2)
                        }
                        Text {
                            text: (!cell.isEmpty && modelData.lunarDay > 0) ? modelData.lunarDay : ""
                            font.pixelSize: Theme.Theme.font.lunar
                            font.family: "DejaVu Sans"
                            color: cell.isToday ? calendarTab.todayText : (cell.isHoliday ? calendarTab.holiday : (cell.isNeighbor ? calendarTab.textMute : calendarTab.textDim))
                            opacity: cell.isToday ? 0.9 : 1.0
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: Math.max(2, (grid.cellH - 50) / 2) + 26
                        }
                        Row {
                            visible: cell.isHoliday && modelData && modelData.holidayName && modelData.holidayName.length > 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: Math.max(2, (grid.cellH - 50) / 2) + 40
                            spacing: 3
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; radius: 2; color: calendarTab.holiday }
                            Text {
                                text: modelData.holidayName
                                font.pixelSize: Theme.Theme.font.tiny
                                font.family: "DejaVu Sans"
                                color: calendarTab.holiday
                                width: grid.cellW - 20
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        // ---- Right hero panel (HÔM NAY) ----
        Item {
            anchors.left: gridPanel.right
            anchors.right: parent.right
            anchors.top: gridPanel.top
            anchors.bottom: gridPanel.bottom

            Rectangle {
                id: heroCard
                anchors.fill: parent
                anchors.margins: Theme.Theme.spacing.sm
                color: calendarTab.itemBg
                radius: Theme.Theme.radius.xl
                border.width: 1; border.color: calendarTab.itemBorder

                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    anchors.topMargin: Theme.Theme.spacing.xl; anchors.bottomMargin: Theme.Theme.spacing.xl
                    width: 3; radius: 2; color: calendarTab.accent
                }

                // Clock — fitted to available width so seconds/minutes never clip
                Text {
                    id: heroClock
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 20; anchors.rightMargin: 16
                    anchors.top: parent.top; anchors.topMargin: Theme.Theme.spacing.xl
                    text: calendarTab.clockText
                    font.pixelSize: 40
                    minimumPixelSize: 18
                    fontSizeMode: Text.Fit
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "DejaVu Sans"
                    font.weight: Font.Light
                    color: calendarTab.text
                }

                Rectangle {
                    anchors.left: heroClock.left; anchors.right: heroClock.right
                    anchors.top: heroClock.bottom; anchors.topMargin: 10
                    height: 1; color: calendarTab.faintLine
                }

                // Section label + date under the clock
                Text {
                    id: heroSection
                    anchors.left: heroClock.left; anchors.right: heroClock.right
                    anchors.top: heroClock.bottom; anchors.topMargin: 16
                    text: "HÔM NAY"
                    font.pixelSize: Theme.Theme.font.tiny
                    font.family: "DejaVu Sans"
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2.0
                    horizontalAlignment: Text.AlignHCenter
                    color: calendarTab.accent
                }
                Text {
                    id: heroDate
                    anchors.left: heroClock.left; anchors.right: heroClock.right
                    anchors.top: heroSection.bottom; anchors.topMargin: 4
                    text: calendarTab.heroDateStr
                    font.pixelSize: Theme.Theme.font.medium
                    font.family: "DejaVu Sans"
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: calendarTab.text
                }

                // Big day number, centered, fills the middle zone
                Item {
                    anchors.left: heroClock.left; anchors.right: heroClock.right
                    anchors.top: heroDate.bottom; anchors.topMargin: 4
                    anchors.bottom: lunarDivider.top; anchors.bottomMargin: 10

                    Text {
                        id: heroDateNum
                        anchors.centerIn: parent
                        text: calendarTab.heroDateNumStr
                        font.pixelSize: 96
                        minimumPixelSize: 44
                        fontSizeMode: Text.Fit
                        width: parent.width
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "DejaVu Sans"; font.weight: Font.Bold
                        color: calendarTab.accent
                    }
                }

                // Bottom block: divider + lunar date line
                Rectangle {
                    id: lunarDivider
                    anchors.left: heroClock.left; anchors.right: heroClock.right
                    anchors.bottom: heroLunarLine.top; anchors.bottomMargin: 8
                    height: 1; color: calendarTab.faintLine
                }
                Text {
                    id: heroLunarLine
                    anchors.left: heroClock.left; anchors.right: heroClock.right
                    anchors.bottom: parent.bottom; anchors.bottomMargin: Theme.Theme.spacing.md
                    text: calendarTab.heroLunarLine
                    font.pixelSize: Theme.Theme.font.small
                    font.family: "DejaVu Sans"
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    color: calendarTab.textDim
                }
            }
        }

        // ---- Swipe / edge navigation ----
        MouseArea {
            id: swipeOverlay
            anchors.left: gridPanel.left; anchors.top: gridPanel.top
            width: calendarTab.gridW; height: calendarTab.gridH
            z: 3
            property real dragStartX: 0; property real dragStartY: 0; property bool isDragging: false
            onPressed: { dragStartX = mouseX; dragStartY = mouseY; isDragging = false }
            onPositionChanged: {
                if (!isDragging) {
                    var dx = mouseX - dragStartX; var dy = mouseY - dragStartY
                    if (Math.abs(dx) > 25 && Math.abs(dx) > Math.abs(dy) * 1.5) isDragging = true
                }
            }
            onReleased: {
                if (isDragging) {
                    var dx = mouseX - dragStartX
                    if (dx < -50) calendarTab.nextMonth()
                    else if (dx > 50) calendarTab.prevMonth()
                }
                isDragging = false
            }
        }
    }

    property var dayNames: ["T2","T3","T4","T5","T6","T7","CN"]

    // ---- Live clock ----
    Timer {
        id: tickTimer
        interval: 1000; repeat: true; running: true
        onTriggered: {
            var now = new Date()
            interval = 1000 - now.getMilliseconds()
            tickClock()
            var key = dayKey()
            if (key !== _cachedDayKey) {
                _cachedDayKey = key
                refreshTodayHero()
                if (currentYear === now.getFullYear() && currentMonth === (now.getMonth() + 1)) loadMonth()
            }
        }
    }

    function tickClock() {
        if (backend) calendarTab.clockText = backend.timeText()
        else calendarTab.clockText = Qt.formatTime(new Date(), "HH:mm:ss")
    }
    function dayKey() {
        var now = new Date()
        return now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate()
    }
    function refreshTodayHero() {
        calendarTab.todayHero = backend ? backend.todayInfo() : computeTodayInfoJS()
    }
    function loadMonth() {
        calendarTab.monthDaysData = backend ? backend.monthGrid(currentYear, currentMonth) : computeMonthGridJS(currentYear, currentMonth)
    }
    function prevMonth() {
        currentMonth--; if (currentMonth < 1) { currentMonth = 12; currentYear-- }
        loadMonth()
    }
    function nextMonth() {
        currentMonth++; if (currentMonth > 12) { currentMonth = 1; currentYear++ }
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
    property string heroLunarLine: todayHero ? (todayHero.lunarDayName + " " + todayHero.lunarMonthName + " năm " + (todayHero.canChiYear || todayHero.lunarYear)) : ""

    function computeMonthTitle(y, m) {
        var names = ["Tháng 1","Tháng 2","Tháng 3","Tháng 4","Tháng 5","Tháng 6","Tháng 7","Tháng 8","Tháng 9","Tháng 10","Tháng 11","Tháng 12"]
        return names[m - 1]
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
    function canChiYearJS(y) {
        var can = ["Giáp","Ất","Bính","Đinh","Mậu","Kỷ","Canh","Tân","Nhâm","Quý"]
        var chi = ["Tý","Sửu","Dần","Mão","Thìn","Tỵ","Ngọ","Mùi","Thân","Dậu","Tuất","Hợi"]
        var c = (y - 4) % 10; if (c < 0) c += 10
        var z = (y - 4) % 12; if (z < 0) z += 12
        return can[c] + " " + chi[z]
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
                if (dn >= 1 && dn <= daysInMonth) { entry.solarDay = dn; entry.lunarDay = dn; entry.isToday = isCurrent && dn === todayD }
                else if (dn < 1) { entry.solarDay = daysPrev + dn + 1; entry.isPrev = true }
                else { entry.solarDay = dn - daysInMonth; entry.isNext = true }
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
    function isLeapYear(y) {
        return (y % 4 === 0 && y % 100 !== 0) || (y % 400 === 0)
    }
}
