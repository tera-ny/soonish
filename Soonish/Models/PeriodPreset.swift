//
//  PeriodPreset.swift
//  Soonish
//
//  Created by Claude on 2025/10/18.
//

import Foundation

/// 期間プリセット（だいたいの期間）
enum PeriodPreset: String, Codable, CaseIterable, Identifiable {
    /// 今週（今日〜今週日曜日）
    case thisWeek
    /// 今月（今週より後〜今月末）
    case thisMonth
    /// 来月（来月1日〜来月末）
    case nextMonth
    /// 今年（再来月〜今年12月31日）
    case thisYear
    /// 来年
    case nextYear
    /// 春（3-5月）
    case spring
    /// 夏（6-8月）
    case summer
    /// 秋（9-11月）
    case autumn
    /// 冬（12-2月）
    case winter

    var id: String { rawValue }

    /// 表示名
    var displayName: String {
        switch self {
        case .thisWeek: return "今週"
        case .thisMonth: return "今月"
        case .nextMonth: return "来月"
        case .thisYear: return "今年"
        case .nextYear: return "来年"
        case .spring: return "春"
        case .summer: return "夏"
        case .autumn: return "秋"
        case .winter: return "冬"
        }
    }

    /// 期間の日付範囲を計算
    /// - Returns: 開始日と終了日のタプル
    func calculateDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current

        switch self {
        case .thisWeek:
            return (PeriodPreset.thisWeekStart, PeriodPreset.thisWeekEnd)

        case .thisMonth:
            // 今週より後〜今月末
            let start = calendar.date(byAdding: .day, value: 1, to: PeriodPreset.thisWeekEnd)!
            return (start, PeriodPreset.thisMonthEnd)

        case .nextMonth:
            return (PeriodPreset.nextMonthStart, PeriodPreset.nextMonthEnd)

        case .thisYear:
            // 再来月〜今年末
            let start = calendar.date(byAdding: .month, value: 2, to: PeriodPreset.thisMonthStart)!
            return (start, PeriodPreset.thisYearEnd)

        case .nextYear:
            return (PeriodPreset.nextYearStart, PeriodPreset.nextYearEnd)

        case .spring, .summer, .autumn, .winter:
            return calculateSeasonDateRange()
        }
    }

    /// 季節の日付範囲を計算
    private func calculateSeasonDateRange(year: Int? = nil) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let targetYear = year ?? calendar.component(.year, from: Date())
        var components = DateComponents()
        components.year = targetYear

        switch self {
        case .spring: // 3-5月
            components.month = 3
            components.day = 1
            let start = calendar.date(from: components)!
            components.month = 6
            components.day = 0 // 5月の最終日
            let end = calendar.date(from: components)!.endOfDay
            return (start, end)

        case .summer: // 6-8月
            components.month = 6
            components.day = 1
            let start = calendar.date(from: components)!
            components.month = 9
            components.day = 0 // 8月の最終日
            let end = calendar.date(from: components)!.endOfDay
            return (start, end)

        case .autumn: // 9-11月
            components.month = 9
            components.day = 1
            let start = calendar.date(from: components)!
            components.month = 12
            components.day = 0 // 11月の最終日
            let end = calendar.date(from: components)!.endOfDay
            return (start, end)

        case .winter: // 12-2月（年をまたぐ）
            components.month = 12
            components.day = 1
            let start = calendar.date(from: components)!
            components.year = targetYear + 1
            components.month = 3
            components.day = 0 // 2月の最終日
            let end = calendar.date(from: components)!.endOfDay
            return (start, end)

        default:
            // 季節以外の場合はデフォルト値（発生しないはず）
            return (Date(), Date())
        }
    }

    // MARK: - 静的プロパティ（DateHelpersから移行）

    private static let calendar = Calendar.current

    /// 今週の開始日（日曜日の午前0時）
    static var thisWeekStart: Date {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1
        return calendar.date(byAdding: .day, value: -daysFromSunday, to: today)!
    }

    /// 今週の終了日（土曜日の23:59:59）
    static var thisWeekEnd: Date {
        let start = thisWeekStart
        return calendar.date(byAdding: .day, value: 6, to: start)!.endOfDay
    }

    /// 今月の開始日
    static var thisMonthStart: Date {
        calendar.dateInterval(of: .month, for: Date())!.start
    }

    /// 今月の終了日
    static var thisMonthEnd: Date {
        calendar.dateInterval(of: .month, for: Date())!.end.addingTimeInterval(-1)
    }

    /// 来月の開始日
    static var nextMonthStart: Date {
        calendar.date(byAdding: .month, value: 1, to: thisMonthStart)!
    }

    /// 来月の終了日
    static var nextMonthEnd: Date {
        let nextMonth = nextMonthStart
        return calendar.dateInterval(of: .month, for: nextMonth)!.end.addingTimeInterval(-1)
    }

    /// 今年の開始日
    static var thisYearStart: Date {
        calendar.dateInterval(of: .year, for: Date())!.start
    }

    /// 今年の終了日
    static var thisYearEnd: Date {
        calendar.dateInterval(of: .year, for: Date())!.end.addingTimeInterval(-1)
    }

    /// 来年の開始日
    static var nextYearStart: Date {
        calendar.date(byAdding: .year, value: 1, to: thisYearStart)!
    }

    /// 来年の終了日
    static var nextYearEnd: Date {
        let nextYear = nextYearStart
        return calendar.dateInterval(of: .year, for: nextYear)!.end.addingTimeInterval(-1)
    }

    /// 再来月の開始日
    static var monthAfterNextStart: Date {
        calendar.date(byAdding: .month, value: 2, to: thisMonthStart)!
    }
}

// MARK: - Date Extensions

extension Date {
    /// その日の終了時刻（23:59:59.999）を取得
    var endOfDay: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        components.hour = 23
        components.minute = 59
        components.second = 59
        components.nanosecond = 999_999_999
        return Calendar.current.date(from: components) ?? self
    }

    /// その日の開始時刻（00:00:00）を取得
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
