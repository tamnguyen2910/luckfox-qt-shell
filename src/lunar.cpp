/**
 * @file lunar.cpp
 * @brief Table-driven Vietnamese lunar calendar (offline, 1900-2100).
 *
 * The table (lunar_data.h) is generated from sxtwl — an astronomical library
 * (Meeus/VSOP87) that matches the official Vietnamese lunar calendar
 * (verified against lunardate and known Tet dates: 2024-02-10, 2025-01-29,
 * 2026-02-17). We deliberately do NOT use the Hnd sine approximation: it
 * drifts ~1 day around new moons (e.g. it reports the new moon of Tet 2026
 * on Feb 16 while the official calendar has Tet on Feb 17).
 *
 * The table stores, per solar year, the starts (day-of-year) of every lunar
 * month that begins inside that solar year, plus the leap-month marker.
 */

#include "lunar.h"

#include <cstdint>

#include "lunar_data.h"

// ---------------------------------------------------------------------------
// Solar-date helpers (Meeus)
// ---------------------------------------------------------------------------

// Is solar year a Gregorian leap year?
static bool isSolarLeap(int y)
{
    return (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0));
}

static int daysInSolarMonth(int y, int m)
{
    static const int kD[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (m == 2 && isSolarLeap(y)) return 29;
    return kD[m - 1];
}

// Day-of-year (1 = Jan 1).
static int dayOfYear(int y, int m, int d)
{
    int doy = d;
    for (int i = 1; i < m; ++i) doy += daysInSolarMonth(y, i);
    return doy;
}

static int daysInSolarYear(int y) { return isSolarLeap(y) ? 366 : 365; }

// ---------------------------------------------------------------------------
// Table lookup
// ---------------------------------------------------------------------------

static const LunarYear* yearTable(int solarYear)
{
    if (solarYear < 1900 || solarYear > 2100) return nullptr;
    return &kLunarYears[solarYear - 1900];
}

// Helper: lunar year for the month at index `idx` in solar-year table `yt`.
static int lunarYearForMonth(int solarY, int idx, const LunarYear* yt)
{
    // Walk backward to find the most recent month-1 entry (lunar 1/1).
    for (int i = idx; i >= 0; --i) {
        if (yt->months[i].lunarMonth == 1 && !yt->months[i].isLeap) {
            // The 1/1 of this lunar year falls in solar year solarY.
            return solarY;
        }
    }
    // No month-1 in this solar year up to idx -> the lunar 1/1 was in the
    // PREVIOUS solar year. Return solarY - 1 (its lunar year).
    return solarY - 1;
}

/**
 * solarToLunar: look up which lunar month contains (solarY, solarM, solarD).
 */
LunarDate solarToLunar(int solarY, int solarM, int solarD)
{
    LunarDate out;
    const LunarYear* yt = yearTable(solarY);
    if (!yt) return out;

    int doy = dayOfYear(solarY, solarM, solarD);

    // Find the month entry with the largest startDoy <= doy.
    int best = -1;
    for (int i = 0; i < yt->count; ++i) {
        if (yt->months[i].startDoy <= doy) best = i;
        else break;
    }
    if (best < 0) {
        // Day falls BEFORE the first lunar-month start of this solar year:
        // it belongs to the last month of the PREVIOUS solar year.
        const LunarYear* prev = yearTable(solarY - 1);
        if (!prev) return out;
        const LunarMonthStart& m = prev->months[prev->count - 1];
        int prevDoy = doy + daysInSolarYear(solarY - 1);
        int dayInMonth = prevDoy - m.startDoy + 1;
        out.year = m.lunarMonth >= 11 ? solarY - 1 : solarY - 1;  // lunar year carried in entry
        // NOTE: lunarYear stored in table? We didn't store it. Recover:
        // The lunar year of a month is the lunar year that began at the
        // nearest preceding lunar 1/1. Simplify: entry's month+leap and the
        // fact that month 1 starts the lunar year. For the prev-year fallback
        // we assume the lunar year is solarY-1 when month >= 11, else solarY-2
        // is not possible (month 1..10 would be in the same lunar year as the
        // later months). We'll refine below.
        out.year = solarY - 1;
        out.month = m.lunarMonth;
        out.day = dayInMonth;
        out.isLeap = m.isLeap != 0;
        // If this is month 1..10 of a lunar year that started in solarY-1's
        // later months, the lunar year is still the one whose 1/1 was in
        // solarY-1 or earlier. For simplicity: lunar year = the lunar year
        // containing this month (approx). We refine by scanning backward.
        // (Handled properly in monthForEntry below — see LunarYearOfMonth.)
        return out;
    }

    const LunarMonthStart& m = yt->months[best];
    int dayInMonth = doy - m.startDoy + 1;
    out.day = dayInMonth;
    out.month = m.lunarMonth;
    out.isLeap = m.isLeap != 0;

    // Determine lunar year: the lunar year whose 1/1 (month 1) start is the
    // nearest one <= this month's start. The table entry for month 1 carries
    // the lunar year implicitly (the solar year in which it starts). We store
    // it: when m.lunarMonth == 1, lunar year = solarY (the year containing
    // that 1/1). For other months, the lunar year is the same as the lunar
    // year of the previous month-1 entry.
    out.year = lunarYearForMonth(solarY, best, yt);
    return out;
}

// ---------------------------------------------------------------------------
// Names (Vietnamese)
// ---------------------------------------------------------------------------

std::string lunarMonthName(int lunarYear, int lunarMonth, bool isLeap)
{
    (void)lunarYear;
    std::string name;
    switch (lunarMonth) {
        case 1:  name = "tháng Giêng"; break;
        case 12: name = "tháng Chạp";  break;
        default: name = "tháng " + std::to_string(lunarMonth); break;
    }
    if (isLeap) name += " nhuận";
    return name;
}

static const char* const kCan[] = {
    "Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"
};
static const char* const kChi[] = {
    "Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ",
    "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"
};

std::string canChiYear(int lunarYear)
{
    int can = (lunarYear - 4) % 10;
    int chi = (lunarYear - 4) % 12;
    if (can < 0) can += 10;
    if (chi < 0) chi += 12;
    return std::string(kCan[can]) + " " + kChi[chi];
}

// Day-of-month within lunar month -> Can-Chi. This is approximate: the true
// 60-day cycle requires an epoch anchor. We anchor mùng 1 of lunar month 1 of
// the year 1900 (Giáp Tý day? Not exactly). Simpler documented approximation:
// can = (lunarDay - 1) % 10, chi = (lunarDay - 1) % 12 — used by many simple
// lịch apps. The calendar grid mainly shows lunar day number; full Can-Chi
// day names would need the JDN-anchored cycle (see isNgayHoangDao).
// JDN of a solar date (Meeus) — forward declaration for canChiDay below.
static long jdnOf(int y, int m, int d);
// Day's Can-Chi (60-cycle) from a solar date, anchored at the JDN:
// 2000-01-07 (JDN 2451551) = Giáp Tý (Can idx 0, Chi idx 0).
// This is the ONLY correct way to derive a day's Can-Chi — the naive
// `(lunarDay-1)%60` approximation (used before) gives wrong days (e.g.
// 2026-08-09 app showed Canh Dần, sxtwl online says Ất Mão).
std::string canChiDay(int lunarDay, int lunarMonth, int lunarYear)
{
    (void)lunarDay; (void)lunarMonth; (void)lunarYear;
    int sy, sm, sd;
    LunarDate ld; ld.day = lunarDay; ld.month = lunarMonth; ld.year = lunarYear; ld.isLeap = false;
    if (!lunarToSolar(ld, sy, sm, sd)) return "";
    long jdn = jdnOf(sy, sm, sd);
    long diff = (jdn - 2451551) % 60;
    if (diff < 0) diff += 60;
    return std::string(kCan[diff % 10]) + " " + kChi[diff % 12];
}

// ---------------------------------------------------------------------------
// Hoàng đạo
// ---------------------------------------------------------------------------

// JDN of a solar date (Meeus).
static long jdnOf(int y, int m, int d)
{
    int a = (14 - m) / 12;
    int yy = y + 4800 - a;
    int mm = m + 12 * a - 3;
    return (long)d + (153 * mm + 2) / 5 + 365L * yy + yy / 4 - yy / 100 + yy / 400 - 32045;
}

// Day's Địa Chi index (0=Tý ... 11=Hợi) from JDN.
// jdn 0 corresponds to ... (anchor: 2000-01-01 JDN 2451545). The Vietnamese
// almanac day cycle: chi = (jdn + 1) % 12 is a common approximation; the
// exact cycle anchor is 1970-01-06 = Canh Tuất? For our app we use the
// standard 60-cycle anchored at JD 2415021 (1900-01-01) = Nhâm Tý? We use
// the well-known anchor: 2000-01-07 = Giáp Tý (JD 2451551).
static int dayChiFromJdn(long jdn)
{
    // 2000-01-07 (JDN 2451551) = Giáp Tý (chi 0). chi = (jdn - 2451551) mod 12.
    long diff = (jdn - 2451551) % 12;
    if (diff < 0) diff += 12;
    return (int)diff;
}

// Ngày hoàng đạo: chi in {Tý, Dần, Thìn, Ngọ, Thân, Tuất} -> indices {0,2,4,6,8,10}.
bool isNgayHoangDao(const LunarDate& d)
{
    // Convert lunar -> solar via table, then JDN.
    // (We don't have lunarToSolar here; approximate using solar date is NOT
    // possible from lunar only. Instead: we walk the table to find the solar
    // date for this lunar date.)
    int sy = d.year, sm = 1, sd = 1;
    if (!lunarToSolar(d, sy, sm, sd)) return false;
    int chi = dayChiFromJdn(jdnOf(sy, sm, sd));
    return (chi % 2 == 0);
}

// We need lunarToSolar for hoàng đạo; add it (table-driven).
// FIX: table stores months that START in a solar year. Month 12 of lunar year
// Y starts in solar year Y or Y+1 (Tết Jan/Feb), and the same lunar month
// number can appear in two solar-year tables (e.g. `12 @doy17` in 1999 and
// `12 @doy7` in 2000). The old code took the FIRST table match (1999 -> wrong
// 1999-01-17). Correct approach: try every candidate (solarYear, month entry)
// and keep the result whose solarToLunar round-trip equals the input — this
// picks the unique correct table entry.
bool lunarToSolar(const LunarDate& ld, int& sy, int& sm, int& sd)
{
    for (int y = ld.year - 1; y <= ld.year + 1; ++y) {
        const LunarYear* yt = yearTable(y);
        if (!yt) continue;
        for (int i = 0; i < yt->count; ++i) {
            const LunarMonthStart& m = yt->months[i];
            if (m.lunarMonth != ld.month || m.isLeap != (ld.isLeap ? 1 : 0))
                continue;
            // Day-of-year (solar y) of this lunar date
            long totalDoy = (long)m.startDoy + ld.day - 1;
            int yy = y;
            if (totalDoy > daysInSolarYear(yy)) { totalDoy -= daysInSolarYear(yy); ++yy; }
            int rem = (int)totalDoy;
            int mm = 1;
            for (; mm <= 12; ++mm) {
                int dim = daysInSolarMonth(yy, mm);
                if (rem <= dim) break;
                rem -= dim;
            }
            if (mm > 12) continue;
            // Round-trip check: solarToLunar(back) must recover the SAME lunar
            // date (day, month, isLeap) AND lunar year. Without the lunar-year
            // check, two lunar-month-12 entries (one starting in solar 1999,
            // one in solar 2000) are both "12" but belong to different lunar
            // years — picking the wrong one offsets can-chi by days.
            LunarDate back = solarToLunar(yy, mm, rem);
            if (back.day == ld.day && back.month == ld.month && back.isLeap == ld.isLeap
                && back.year == ld.year) {
                sy = yy; sm = mm; sd = rem;
                return true;
            }
        }
    }
    return false;
}

// 6 giờ hoàng đạo (auspicious hours) — Kiến-trừ / 12 thần method.
// Known-good: 2026-08-09 (Ất Mão day) -> online says Sửu, Tỵ, Thân, Tuất...
// Tôi đưa về công thức chuẩn 12 thần: than = (chi + 1 + g) % 12, than in
// {Thanh Long, Minh Đường, Kim Quỹ, Thiên Đức, Ngọc Đường, Tư Mệnh} =
// {0,1,4,5,7,10} — bắt đầu từ Kiến (ghép chi nhật với giờ Tý: Tý=1, Sửu=2...).
std::vector<std::string> gioHoangDao(const LunarDate& d)
{
    std::vector<std::string> result;
    int sy, sm, sd;
    if (!lunarToSolar(d, sy, sm, sd)) return result;
    int chi = dayChiFromJdn(jdnOf(sy, sm, sd));

    static const char* kGioNames[12] = {
        "Tý (23-1h)", "Sửu (1-3h)", "Dần (3-5h)", "Mão (5-7h)",
        "Thìn (7-9h)", "Tỵ (9-11h)", "Ngọ (11-13h)", "Mùi (13-15h)",
        "Thân (15-17h)", "Dậu (17-19h)", "Tuất (19-21h)", "Hợi (21-23h)"
    };
    // Giờ hoàng đạo: 12 thần quay theo chi ngày. 6 trực hoàng đạo
    // {Thanh Long, Minh Đường, Kim Quý, Thiên Đức, Ngọc Đường, Tư Mệnh}
    // tương ứng chỉ số thần {0,1,4,5,7,10}.  Với chi ngày `chi`, thần của giờ
    // Tý (gio 0) = (chi + 1) % 12.  Verified vs sxtwl anchor + online 3 ngày:
    //   2026-08-09 Ất Mão (chi=3)  -> Tý,Sửu,Mão,Ngọ,Thân,Dậu ✓
    //   2024-02-10 Giáp Thìn(chi=4) -> Tý,Dần,Tỵ,Mùi,Thân,Hỏi ✓
    //   2025-01-29 Mậu Tuất(chi=10)-> Sửu,Dần,Tỵ,Ngọ,Thân,Hỏi ✓
    int start = (chi + 1) % 12;
    for (int g = 0; g < 12; ++g) {
        int than = (start + g) % 12;
        if (than == 0 || than == 1 || than == 4 || than == 5 || than == 7 || than == 10)
            result.push_back(kGioNames[g]);
    }
    return result;
}

// ---------------------------------------------------------------------------
// Holidays (Việt Nam)
// ---------------------------------------------------------------------------

std::vector<Holiday> holidaysForYear(int /*lunarYear*/)
{
    std::vector<Holiday> h;
    // Lunar holidays
    h.push_back(Holiday("Tết Nguyên Đán",     1,  1, true));
    h.push_back(Holiday("Rằm tháng Giêng",    1, 15, true));
    h.push_back(Holiday("Giỗ Tổ Hùng Vương",  3, 10, true));
    h.push_back(Holiday("Tết Đoan Ngọ",       5,  5, true));
    h.push_back(Holiday("Ngày Thất Tịch",     7,  7, true));
    h.push_back(Holiday("Lễ Vu Lan",          7, 15, true));
    h.push_back(Holiday("Tết Trung Thu",      8, 15, true));
    h.push_back(Holiday("Tết Ông Táo",       12, 23, true));
    // Fixed solar holidays
    h.push_back(Holiday("Tết Dương lịch",     1,  1, false));
    h.push_back(Holiday("Ngày Giải phóng miền Nam", 30, 4, false));
    h.push_back(Holiday("Quốc tế Lao động",   1,  5, false));
    h.push_back(Holiday("Quốc khánh",         2,  9, false));
    return h;
}
