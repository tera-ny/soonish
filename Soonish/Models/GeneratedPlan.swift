//
//  GeneratedPlan.swift
//  Soonish
//
//  Created by Claude on 2025/10/24.
//

import Foundation
import FoundationModels

/// 時間タイプの列挙型
@Generable
enum GeneratedTimeType {
    case period(GeneratedPeriodPreset)
    case deadline(GeneratedDeadlinePreset)
    case anytime
}

/// 期間プリセットの列挙型
@Generable
enum GeneratedPeriodPreset: String {
    case spring
    case summer
    case autumn
    case winter
    case thisWeek
    case thisMonth
    case nextMonth
    case thisYear
    case nextYear
}

/// 期限プリセットの列挙型
@Generable
enum GeneratedDeadlinePreset: String {
    case oneMonth
    case threeMonths
    case sixMonths
    case oneYear
}

