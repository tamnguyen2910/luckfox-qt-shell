#ifndef LUNARBACKEND_H
#define LUNARBACKEND_H

#include <QObject>
#include <QDateTime>
#include <QDate>
#include <QStringList>
#include <QVariant>
#include <QVariantMap>
#include <QVariantList>
#include "lunar.h"

// Vietnamese lunar-calendar backend exposed to QML as context property
// `LunarBackend`. Ported from the standalone 01_Calendar app.
//
// API contract (QML calendar UI depends on this):
//   - QVariantMap today()            -> {year, month, day} (solar today)
//   - QVariantList   monthGrid(y, m) -> 42 cells {solarDay, lunarDay, isToday,
//                                          isHoliday, holidayName, isNext, isPrev}
//   - QVariantMap    dayInfo(y, m, d)
//   - QVariantMap    lunarMonthTitle(y, m)
//   - QString         lunarMonthLabel(y, m)
//   - QVariantMap    todayInfo()      -> hero HÔM NAY
//   - QString         timeText()      -> 24h, UTC+7 local
class LunarBackend : public QObject
{
    Q_OBJECT
public:
    explicit LunarBackend(QObject* parent = nullptr) : QObject(parent) {}

    // Vietnam local date (UTC+7 — board zoneinfo incomplete).
    static QDate vnToday()
    {
        return QDateTime::currentDateTimeUtc().addSecs(7 * 3600).date();
    }

    Q_INVOKABLE QVariantMap today() const
    {
        QVariantMap m;
        QDate d = vnToday();
        m["year"]  = d.year();
        m["month"] = d.month();
        m["day"]   = d.day();
        return m;
    }

    Q_INVOKABLE QVariantList monthGrid(int year, int month) const
    {
        QVariantList cells;
        QDate first(year, month, 1);
        if (!first.isValid()) {
            for (int i = 0; i < 42; ++i) {
                QVariantMap c;
                c["solarDay"] = 0; c["lunarDay"] = 0; c["isToday"] = false;
                c["isHoliday"] = false; c["holidayName"] = "";
                c["isNext"] = false; c["isPrev"] = false;
                cells << c;
            }
            return cells;
        }

        // Monday-first offset: 0=Mon..6=Sun
        int mondayOffset = (first.dayOfWeek() + 6) % 7;  // dayOfWeek: 1=Mon..7=Sun
        QDate today = vnToday();
        int daysInMonth = first.daysInMonth();

        for (int i = 0; i < 42; ++i) {
            int dayNum = i - mondayOffset + 1;
            QVariantMap c;
            c["isToday"] = false; c["isHoliday"] = false;
            c["holidayName"] = ""; c["isNext"] = false; c["isPrev"] = false;
            c["lunarDay"] = 0; c["solarDay"] = 0;

            QDate d;
            if (dayNum >= 1 && dayNum <= daysInMonth) {
                d = QDate(year, month, dayNum);
                c["solarDay"] = dayNum;
            } else if (dayNum < 1) {
                QDate prev = first.addMonths(-1);
                QDate pd = QDate(prev.year(), prev.month(), prev.daysInMonth() + dayNum);
                if (pd.isValid()) { c["solarDay"] = pd.day(); c["isPrev"] = true; d = pd; }
            } else {
                QDate next = first.addMonths(1);
                QDate nd = QDate(next.year(), next.month(), dayNum - daysInMonth);
                if (nd.isValid()) { c["solarDay"] = nd.day(); c["isNext"] = true; d = nd; }
            }

            if (d.isValid()) {
                LunarDate l = solarToLunar(d.year(), d.month(), d.day());
                c["lunarDay"] = l.day;
                c["isToday"] = (d == today);
                c["isHoliday"] = false;
                c["holidayName"] = holidayForDate(d.year(), d.month(), d.day());
            }
            cells << c;
        }
        return cells;
    }

    Q_INVOKABLE QVariantMap dayInfo(int year, int month, int day) const
    {
        QVariantMap info;
        QDate d(year, month, day);
        if (!d.isValid()) return info;

        LunarDate l = solarToLunar(year, month, day);
        info["solarDay"]   = day;
        info["solarMonth"] = month;
        info["solarYear"]  = year;
        info["lunarDay"]   = l.day;
        info["lunarMonth"] = l.month;
        info["lunarYear"]  = l.year;
        info["lunarMonthName"] = QString::fromStdString(lunarMonthName(l.year, l.month, l.isLeap));
        info["lunarDayName"]   = lunarDayName(l.day);   // shared naming rule (C++)
        info["canChiYear"] = QString::fromStdString(canChiYear(l.year));
        info["canChiDay"]  = QString::fromStdString(canChiDay(l.day, l.month, l.year));
        info["isHoangDao"] = isNgayHoangDao(l);

        QStringList gio;
        for (const std::string& s : gioHoangDao(l))
            gio << QString::fromStdString(s);
        info["gioHoangDao"] = gio;

        QStringList hol;
        QString h = holidayForDate(year, month, day);
        if (!h.isEmpty()) hol << h;
        info["holidays"] = hol;

        int wd = d.dayOfWeek();  // 1=Mon..7=Sun
        info["weekday"] = (wd == 7) ? 0 : wd;  // convert to 0=Sun..6=Sat
        static const char* kDays[] = {"Ch\u1EE7 Nh\u1EBD","Th\u1EE9 Hai","Th\u1EE9 Ba","Th\u1EE9 T\u0169","Th\u1EE9 N\u0103m","Th\u1EE9 S\u00E1u","Th\u1EE9 B\u1ea3y"};
        int vnIdx = (wd == 7) ? 0 : wd;
        info["weekdayName"] = QString::fromUtf8(kDays[vnIdx]);
        return info;
    }

    Q_INVOKABLE QVariantMap lunarMonthTitle(int year, int month) const
    {
        QVariantMap m;
        QDate first(year, month, 1);
        if (!first.isValid()) { m["title"] = ""; return m; }
        QDate mid(year, month, qMin(15, first.daysInMonth()));
        LunarDate l = solarToLunar(mid.year(), mid.month(), mid.day());
        m["title"] = QString("%1 n\u0103m %2")
            .arg(QString::fromStdString(lunarMonthName(l.year, l.month, l.isLeap)))
            .arg(QString::fromStdString(canChiYear(l.year)));
        return m;
    }

    // v2 API (no can-chi strings)
    static QString lunarDayName(int lunarDay)
    {
        if (lunarDay == 15) return QStringLiteral("R\u1EB9m");
        if (lunarDay >= 1 && lunarDay <= 10) return QStringLiteral("Mùng %1").arg(lunarDay);
        return QStringLiteral("Ngày %1").arg(lunarDay);
    }

    Q_INVOKABLE QString lunarMonthLabel(int year, int month) const
    {
        QDate first(year, month, 1);
        if (!first.isValid()) return QString();
        QDate mid(year, month, qMin(15, first.daysInMonth()));
        LunarDate l = solarToLunar(mid.year(), mid.month(), mid.day());
        QString s = QString::fromStdString(lunarMonthName(l.year, l.month, l.isLeap));
        return s;  // e.g. "tháng 6" / "tháng 6 nhuận"
    }

    Q_INVOKABLE QVariantMap todayInfo() const
    {
        QVariantMap m;
        QDate d = vnToday();
        if (!d.isValid()) return m;
        LunarDate l = solarToLunar(d.year(), d.month(), d.day());

        static const char* kDays[] = {"Ch\u1EE7 Nh\u1EBD","Th\u1EE9 Hai","Th\u1EE9 Ba","Th\u1EE9 T\u0169","Th\u1EE9 N\u0103m","Th\u1EE9 S\u00E1u","Th\u1EE9 B\u1ea3y"};
        int wd = d.dayOfWeek();
        int vnIdx = (wd == 7) ? 0 : wd;

        m["day"]   = d.day();
        m["month"] = d.month();
        m["year"]  = d.year();
        m["weekday"]    = vnIdx;
        m["weekdayName"] = QString::fromUtf8(kDays[vnIdx]);
        m["lunarDay"]   = l.day;
        m["lunarMonth"] = l.month;
        m["lunarYear"]  = l.year;
        m["lunarMonthName"] = QString::fromStdString(lunarMonthName(l.year, l.month, l.isLeap));
        m["lunarDayName"]   = lunarDayName(l.day);
        m["canChiYear"]     = QString::fromStdString(canChiYear(l.year));
        m["timeText"] = timeText();
        m["dateStr"]  = d.toString("dd/MM/yyyy");
        QStringList hol;
        QString h = holidayForDate(d.year(), d.month(), d.day());
        if (!h.isEmpty()) hol << h;
        m["holidays"] = hol;
        return m;
    }

    Q_INVOKABLE QString timeText() const
    {
        QDateTime utc = QDateTime::currentDateTimeUtc();
        QDateTime vn  = utc.addSecs(7 * 3600);   // UTC+7, no DST in VN
        return vn.toString("HH:mm:ss");
    }

private:
    static QString holidayForDate(int y, int m, int d)
    {
        if (m == 1 && d == 1)  return "Tết Dương lịch";
        if (m == 4 && d == 30) return "Giải phóng miền Nam";
        if (m == 5 && d == 1)  return "Quốc tế Lao động";
        if (m == 9 && d == 2)  return "Quốc khánh";

        LunarDate l = solarToLunar(y, m, d);
        if (l.isLeap) return QString();
        if (l.month == 1  && l.day == 1)  return "Tết Nguyên Đán";
        if (l.month == 1  && l.day == 15) return "Rằm tháng Giêng";
        if (l.month == 3  && l.day == 10) return "Giỗ Tổ Hùng Vương";
        if (l.month == 5  && l.day == 5)  return "Tết Đoan Ngọ";
        if (l.month == 7  && l.day == 7)  return "Ngày Thất Tịch";
        if (l.month == 7  && l.day == 15) return "Lễ Vu Lan";
        if (l.month == 8  && l.day == 15) return "Tết Trung Thu";
        if (l.month == 12 && l.day == 23) return "Tết Ông Táo";
        return QString();
    }
};

#endif // LUNARBACKEND_H
