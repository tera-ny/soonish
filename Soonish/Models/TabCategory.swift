//
//  TabCategory.swift
//  Soonish
//
//  Created by Claude on 2025/10/18.
//

import Foundation

/// タブのカテゴリを表すenum
enum TabCategory: String, Codable {
    /// 今月（今月1日〜今月末）
    case thisMonth
    /// 来月（来月1日〜来月末）
    case nextMonth
    /// 今年（再来月〜今年12月31日）
    case thisYear
    /// 来年以降（来年1月1日〜）
    case nextYearOnwards

    /// タブの表示名
    var displayName: String {
        switch self {
        case .thisMonth: return "今月中"
        case .nextMonth: return "来月中"
        case .thisYear: return "今年中"
        case .nextYearOnwards: return "来年以降"
        }
    }

    /// タブのアイコン名（SF Symbols）
    var iconName: String {
        switch self {
        case .thisMonth: return "calendar.badge.clock"
        case .nextMonth: return "calendar.badge.plus"
        case .thisYear: return "calendar.circle"
        case .nextYearOnwards: return "calendar.badge.exclamationmark"
        }
    }

    /// 再来月が今年に属するか判定
    static var isMonthAfterNextInThisYear: Bool {
        let calendar = Calendar.current
        let now = Date()
        let monthAfterNext = calendar.date(byAdding: .month, value: 2, to: now)!
        let currentYear = calendar.component(.year, from: now)
        let monthAfterNextYear = calendar.component(.year, from: monthAfterNext)
        return currentYear == monthAfterNextYear
    }

    /// 表示するタブのリスト（動的に生成）
    static var visibleTabs: [TabCategory] {
        if isMonthAfterNextInThisYear {
            return [.thisMonth, .nextMonth, .thisYear]
        } else {
            return [.thisMonth, .nextMonth, .nextYearOnwards]
        }
    }
}
