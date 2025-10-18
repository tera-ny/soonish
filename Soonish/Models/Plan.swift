//
//  Plan.swift
//  Soonish
//
//  Created by Claude on 2025/10/18.
//

import Foundation
import SwiftData

/// 「なんとなくの予定」を表すSwiftDataモデル
@Model
final class Plan {
    // MARK: - 基本情報

    /// 一意の識別子（SwiftDataが自動生成）
    @Attribute(.unique) var id: UUID

    /// 予定のタイトル（必須）
    var title: String

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    // MARK: - 時間設定情報

    /// 時間設定タイプ（period/deadline/anytime）
    var timeType: PlanTimeType

    /// 期間プリセット（timeType = .period の場合のみ）
    var periodPreset: PeriodPreset?

    /// 期間ラベル（季節名のみ保存、相対期間は保存しない）
    var periodLabel: String?

    /// 期限プリセット（timeType = .deadline の場合のみ）
    var deadlinePreset: DeadlinePreset?

    /// カスタム期限日（deadlinePreset = .custom の場合のみ）
    var customDeadlineDate: Date?

    /// 計算用の開始日（自動計算される）
    var periodStart: Date?

    /// 計算用の終了日（自動計算される）
    var periodEnd: Date?

    /// 期限（自動計算される、deadlineタイプまたはdeadlinePresetがある場合）
    var deadline: Date?

    // MARK: - メタ情報

    /// メモ（任意）
    var memo: String?

    /// 完了フラグ
    var isCompleted: Bool

    /// アーカイブフラグ
    var isArchived: Bool

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        title: String,
        timeType: PlanTimeType = .anytime,
        periodPreset: PeriodPreset? = nil,
        periodLabel: String? = nil,
        deadlinePreset: DeadlinePreset? = nil,
        customDeadlineDate: Date? = nil,
        periodStart: Date? = nil,
        periodEnd: Date? = nil,
        deadline: Date? = nil,
        memo: String? = nil,
        isCompleted: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.timeType = timeType
        self.periodPreset = periodPreset
        self.periodLabel = periodLabel
        self.deadlinePreset = deadlinePreset
        self.customDeadlineDate = customDeadlineDate
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.deadline = deadline
        self.memo = memo
        self.isCompleted = isCompleted
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Convenience Initializers

extension Plan {
    /// 期間プリセットを使用して予定を作成
    static func withPeriod(
        title: String,
        periodPreset: PeriodPreset,
        memo: String? = nil
    ) -> Plan {
        // 季節のみラベルとして保存（普遍的なため）
        let label: String?
        switch periodPreset {
        case .spring, .summer, .autumn, .winter:
            label = periodPreset.displayName
        case .thisWeek, .thisMonth, .nextMonth, .thisYear, .nextYear:
            label = nil  // 相対期間はラベルとして保存しない
        }

        let plan = Plan(
            title: title,
            timeType: .period,
            periodPreset: periodPreset,
            periodLabel: label,
            memo: memo
        )
        plan.updatePeriodDates()
        return plan
    }

    /// 期限プリセットを使用して予定を作成
    static func withDeadline(
        title: String,
        deadlinePreset: DeadlinePreset,
        customDeadlineDate: Date? = nil,
        memo: String? = nil
    ) -> Plan {
        let plan = Plan(
            title: title,
            timeType: .deadline,
            deadlinePreset: deadlinePreset,
            customDeadlineDate: customDeadlineDate,
            memo: memo
        )
        plan.updatePeriodDates()
        return plan
    }

    /// 「いつか」の予定を作成（ドラフト状態）
    static func withAnytime(
        title: String,
        memo: String? = nil
    ) -> Plan {
        Plan(
            title: title,
            timeType: .anytime,
            memo: memo
        )
    }
}
