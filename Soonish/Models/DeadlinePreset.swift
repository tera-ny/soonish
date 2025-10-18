//
//  DeadlinePreset.swift
//  Soonish
//
//  Created by Claude on 2025/10/18.
//

import Foundation

/// 期限のプリセット選択肢
enum DeadlinePreset: String, Codable, CaseIterable, Identifiable {
    case oneMonth
    case threeMonths
    case sixMonths
    case oneYear
    case custom

    var id: String { rawValue }

    /// 表示名
    var displayName: String {
        switch self {
        case .oneMonth:
            return "1ヶ月後くらいに"
        case .threeMonths:
            return "3ヶ月後くらいに"
        case .sixMonths:
            return "半年後くらいに"
        case .oneYear:
            return "1年後くらいに"
        case .custom:
            return "自分で決める"
        }
    }

    /// 現在の日付から計算した期限日
    /// - Parameter baseDate: 基準となる日付（デフォルトは現在日時）
    /// - Returns: 計算された期限日（customの場合はnil）
    func calculateDeadline(from baseDate: Date = Date()) -> Date? {
        let calendar = Calendar.current

        switch self {
        case .oneMonth:
            return calendar.date(byAdding: .month, value: 1, to: baseDate)

        case .threeMonths:
            return calendar.date(byAdding: .month, value: 3, to: baseDate)

        case .sixMonths:
            return calendar.date(byAdding: .month, value: 6, to: baseDate)

        case .oneYear:
            return calendar.date(byAdding: .year, value: 1, to: baseDate)

        case .custom:
            return nil
        }
    }

    /// アイコン名（SF Symbols）
    var iconName: String {
        switch self {
        case .oneMonth:
            return "calendar.badge.plus"
        case .threeMonths:
            return "calendar"
        case .sixMonths:
            return "calendar.circle"
        case .oneYear:
            return "calendar.badge.clock"
        case .custom:
            return "calendar.badge.exclamationmark"
        }
    }

    /// 説明文
    var description: String {
        switch self {
        case .oneMonth:
            return "約30日後"
        case .threeMonths:
            return "約3ヶ月後"
        case .sixMonths:
            return "約半年後"
        case .oneYear:
            return "約1年後"
        case .custom:
            return "好きな日を選ぶ"
        }
    }
}
