/**
 * @file lunar.h
 * @brief Pure C++17 Vietnamese lunar calendar core for Luckfox (offline).
 *
 * Backend: a precomputed table generated from sxtwl (astronomical Meeus/VSOP),
 * the same reference used by lunardate. This is NOT the Hnd sine approximation
 * (which drifts ~1 day near new moons). The table is embedded in lunar_data.h
 * and is accurate for solar years 1900-2100.
 */

#ifndef LUNAR_H
#define LUNAR_H

#include <string>
#include <vector>

struct LunarDate {
    int year;
    int month;
    int day;
    bool isLeap;
    LunarDate() : year(0), month(0), day(0), isLeap(false) {}
    LunarDate(int y, int m, int d, bool leap) : year(y), month(m), day(d), isLeap(leap) {}
};

struct Holiday {
    std::string name;
    int lunarMonth;
    int lunarDay;
    bool isLunar;  // true = lunar (month/day on lunar calendar); false = fixed solar
    Holiday() : name(""), lunarMonth(0), lunarDay(0), isLunar(false) {}
    Holiday(const std::string& n, int lm, int ld, bool il)
        : name(n), lunarMonth(lm), lunarDay(ld), isLunar(il) {}
};

// Convert a Gregorian (solar) date to a Vietnamese lunar date. 1900-2100.
LunarDate solarToLunar(int solarY, int solarM, int solarD);

// Convert a Vietnamese lunar date back to a Gregorian (solar) date. 1900-2100.
// Returns false if the lunar date is out of the table range.
bool lunarToSolar(const LunarDate& ld, int& sy, int& sm, int& sd);

// (Optional) Vietnamese name of a lunar month: 1 -> "tháng Giêng", 12 -> "tháng Chạp",
//   others -> "tháng N"; leap months get " nhuận" suffix.
std::string lunarMonthName(int lunarYear, int lunarMonth, bool isLeap);

// Sexagenary (Can-Chi) year name. 2024 -> "Giáp Thìn", 2025 -> "Ất Tỵ", 2026 -> "Bính Ngọ".
std::string canChiYear(int lunarYear);

// Sexagenary (Can-Chi) day name for a lunar day-of-month (1-based).
// The 60-day cycle starts at Giáp Tý for mùng 1 of the 1st lunar month of
// a Giáp-Tý year; here we map day-of-month within the lunar month.
std::string canChiDay(int lunarDay, int lunarMonth, int lunarYear);

// Ngày hoàng đạo (auspicious lunar days). Rule (stated in lunar.cpp).
bool isNgayHoangDao(const LunarDate& d);

// 6 giờ hoàng đạo (auspicious two-hour periods) for a lunar day.
std::vector<std::string> gioHoangDao(const LunarDate& d);

// List of holidays for a LUNAR year (lunar holidays + fixed solar holidays).
std::vector<Holiday> holidaysForYear(int lunarYear);

#endif // LUNAR_H
