//
//  ChatBotMessage.swift
//  Soonish
//
//  Created by Claude on 2025/10/24.
//

import Foundation
import FoundationModels

/// チャットボットからのメッセージ型
@Generable
enum ChatBotMessage {
    /// 質問メッセージ（情報収集中）
    case question(String)

    /// 確認・相槌メッセージ
    case confirmation(String)

    /// 予定作成の提案メッセージ
    case suggestion(text: String, plan: PlanSuggestion)
}

/// 予定の提案内容
@Generable
struct PlanSuggestion {
    @Guide(description: "予定のタイトル（例: 春の旅行、確定申告、歯医者に行く）")
    var title: String

    @Guide(description: "時間タイプ: period（期間指定）, deadline（期限指定）, anytime（いつか）")
    var timeType: GeneratedTimeType

    @Guide(description: "メモ（オプション）。ユーザーが追加情報を提供した場合に設定")
    var memo: String?
}

// MARK: - Conversion to Plan

extension PlanSuggestion {
    /// PlanSuggestion を Plan に変換
    func toPlan() throws -> Plan {
        switch timeType {
        case .period(let period):
            guard let preset = PeriodPreset(rawValue: period.rawValue) else {
                throw ConversionError.invalidPeriodPreset(period.rawValue)
            }
            return Plan.withPeriod(title: title, periodPreset: preset, memo: memo)

        case .deadline(let deadline):
            guard let preset = DeadlinePreset(rawValue: deadline.rawValue) else {
                throw ConversionError.invalidDeadlinePreset(deadline.rawValue)
            }
            return Plan.withDeadline(title: title, deadlinePreset: preset, memo: memo)

        case .anytime:
            return Plan.withAnytime(title: title, memo: memo)
        }
    }

    enum ConversionError: LocalizedError {
        case missingPeriodPreset
        case missingDeadlinePreset
        case invalidPeriodPreset(String)
        case invalidDeadlinePreset(String)

        var errorDescription: String? {
            switch self {
            case .missingPeriodPreset:
                return "期間プリセットが指定されていません"
            case .missingDeadlinePreset:
                return "期限プリセットが指定されていません"
            case .invalidPeriodPreset(let value):
                return "無効な期間プリセット: \(value)"
            case .invalidDeadlinePreset(let value):
                return "無効な期限プリセット: \(value)"
            }
        }
    }
}
