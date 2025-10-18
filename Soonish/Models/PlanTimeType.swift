//
//  PlanTimeType.swift
//  Soonish
//
//  Created by Claude on 2025/10/18.
//

import Foundation

/// 予定の時間設定タイプ
enum PlanTimeType: String, Codable, CaseIterable, Identifiable {
    /// だいたいの期間（開始日〜終了日の範囲）
    case period

    /// いつまでに（今日から期限日まで）
    case deadline

    /// いつか（時期未定・ドラフト状態）
    case anytime

    var id: String { rawValue }

    /// 表示名
    var displayName: String {
        switch self {
        case .period:
            return "だいたいの期間"
        case .deadline:
            return "いつまでに"
        case .anytime:
            return "いつか"
        }
    }

    /// 説明文
    var description: String {
        switch self {
        case .period:
            return "春に、来月中になど"
        case .deadline:
            return "1ヶ月以内になど"
        case .anytime:
            return "時期未定"
        }
    }
}
