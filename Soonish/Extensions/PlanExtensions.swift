//
//  PlanExtensions.swift
//  Soonish
//
//  Created by Claude on 2025/10/18.
//

import Foundation

// MARK: - Period Management

extension Plan {
    /// 期間の開始日と終了日を自動計算して更新する
    func updatePeriodDates() {
        updatedAt = Date()

        switch timeType {
        case .period:
            // だいたいの期間
            if let preset = periodPreset {
                let range = preset.calculateDateRange()
                periodStart = range.start
                periodEnd = range.end
                deadline = nil
            }

        case .deadline:
            // いつまでに
            let today = Date()
            periodStart = today

            if deadlinePreset == .custom, let customDate = customDeadlineDate {
                // 自分で決める
                periodEnd = customDate
                deadline = customDate
            } else if let preset = deadlinePreset, let calculatedDate = preset.calculateDeadline() {
                // プリセット（1ヶ月くらい、3ヶ月くらいなど）
                periodEnd = calculatedDate
                deadline = calculatedDate
            }

        case .anytime:
            // いつか（ドラフト状態）
            periodStart = nil
            periodEnd = nil
            deadline = nil
        }
    }

    /// 期間が期限切れかどうかをチェック
    var isPeriodExpired: Bool {
        guard let end = periodEnd else { return false }
        return Date() > end
    }

    /// 期限が近づいているかどうかをチェック（7日以内）
    var isDeadlineNear: Bool {
        guard let deadline = deadline else { return false }
        let now = Date()
        let daysUntilDeadline = Calendar.current.dateComponents([.day], from: now, to: deadline).day ?? 0
        return daysUntilDeadline >= 0 && daysUntilDeadline <= 7
    }
}

// MARK: - Tab Classification

extension Plan {
    /// この予定が指定されたタブに属するかどうかを判定（多対多）
    /// - Parameter tab: 判定するタブカテゴリ
    /// - Returns: そのタブに属する場合は true
    func belongsTo(tab: TabCategory) -> Bool {
        // アーカイブ済みや完了済み、anytimeの予定は除外
        if isArchived || isCompleted || timeType == .anytime {
            return false
        }

        // 期間の開始日と終了日が必要
        guard let start = periodStart, let end = periodEnd else {
            return false
        }

        let now = Date()

        // 期間が完全に過去の場合はどのタブにも属さない
        if end < now {
            return false
        }

        switch tab {
        case .thisMonth:
            // 今月（今月の開始〜終了）と重なる予定
            return dateRangesOverlap(
                start1: start, end1: end,
                start2: PeriodPreset.thisMonthStart, end2: PeriodPreset.thisMonthEnd
            )

        case .nextMonth:
            // 来月（来月の開始〜終了）と重なる予定
            return dateRangesOverlap(
                start1: start, end1: end,
                start2: PeriodPreset.nextMonthStart, end2: PeriodPreset.nextMonthEnd
            )

        case .thisYear:
            // 今年（再来月〜今年末）と重なる予定
            return dateRangesOverlap(
                start1: start, end1: end,
                start2: PeriodPreset.monthAfterNextStart, end2: PeriodPreset.thisYearEnd
            )

        case .nextYearOnwards:
            // 来年以降（来年開始〜）と重なる予定
            // 終了日は設定しない（無限大）
            return start >= PeriodPreset.nextYearStart || end >= PeriodPreset.nextYearStart
        }
    }

    /// 2つの期間が重なるかどうかを判定
    private func dateRangesOverlap(start1: Date, end1: Date, start2: Date, end2: Date) -> Bool {
        // 期間1の終了が期間2の開始より前 → 重ならない
        if end1 < start2 {
            return false
        }
        // 期間1の開始が期間2の終了より後 → 重ならない
        if start1 > end2 {
            return false
        }
        // それ以外は重なる
        return true
    }
}

// MARK: - Sorting

extension Plan {
    /// ソート用の優先度スコアを計算
    /// - スコアが小さいほど上位に表示される
    /// - 期限がある予定は優先的に表示
    var sortPriority: Double {
        // 期限がある場合、期限までの日数で優先度を決定
        if let deadline = deadline {
            let daysUntilDeadline = Calendar.current.dateComponents(
                [.day],
                from: Date(),
                to: deadline
            ).day ?? Int.max

            // 期限が近いほど優先度が高い（スコアが小さい）
            // 負の値（期限切れ）は最優先
            return Double(daysUntilDeadline)
        }

        // 期限がない場合は作成日時の逆順（新しいほど優先）
        // 大きな値を返すことで期限ありの予定より後に表示
        return 100000 - createdAt.timeIntervalSince1970
    }

    /// 作成日時の古い順でソート（「いつか」タブ用）
    var sortPriorityOldestFirst: Double {
        if let deadline = deadline {
            // 期限がある場合は通常通り期限優先
            let daysUntilDeadline = Calendar.current.dateComponents(
                [.day],
                from: Date(),
                to: deadline
            ).day ?? Int.max
            return Double(daysUntilDeadline)
        }

        // 期限がない場合は作成日時の昇順（古いほど優先）
        return createdAt.timeIntervalSince1970
    }
}

// MARK: - Display Helpers

extension Plan {
    /// 期間の表示用テキスト
    var periodDisplayText: String? {
        switch timeType {
        case .period:
            // 季節ラベルがあればそれを表示（普遍的）
            if let label = periodLabel {
                return label  // "春", "夏", "秋", "冬"
            }

            // ラベルがない場合は periodStart から都度計算
            guard let start = periodStart else { return nil }

            // 今週
            if start <= PeriodPreset.thisWeekEnd {
                return "今週中"
            }
            // 今月
            if start <= PeriodPreset.thisMonthEnd {
                return "今月中"
            }
            // 来月
            if start <= PeriodPreset.nextMonthEnd {
                return "来月中"
            }
            // 今年
            if start <= PeriodPreset.thisYearEnd {
                return "今年中"
            }
            // 来年以降
            if start >= PeriodPreset.nextYearStart {
                return "来年以降"
            }

            return nil

        case .deadline:
            // デッドライン予定は表示しない（混乱を避けるため）
            return nil

        case .anytime:
            return "いつか"
        }
    }

    /// 期限の表示用テキスト（オプショナル）
    var deadlineDisplayText: String? {
        guard let deadline = deadline else { return nil }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")

        return formatter.string(from: deadline)
    }

    /// 期間の残り日数テキスト（デッドライン予定のみ、ざっくり表示）
    var remainingDaysText: String? {
        // デッドラインプリセットが設定されている予定のみ表示
        guard timeType == .deadline, deadlinePreset != nil, let end = periodEnd else {
            return nil
        }

        let now = Date()

        if end < now {
            return "期限切れ"
        }

        // 今週かチェック
        if end <= PeriodPreset.thisWeekEnd {
            return "今週中"
        }

        // 今月かチェック
        if end <= PeriodPreset.thisMonthEnd {
            return "今月中"
        }

        // 来月かチェック
        if end <= PeriodPreset.nextMonthEnd {
            return "来月中"
        }

        // 今年かチェック
        if end <= PeriodPreset.thisYearEnd {
            return "今年中"
        }

        // 来年以降
        return "来年以降"
    }
}

// MARK: - Array Extensions

extension Array where Element == Plan {
    /// デフォルトのソート順（期限優先、その後作成日時の新しい順）
    func sortedByDefault() -> [Plan] {
        sorted { $0.sortPriority < $1.sortPriority }
    }

    /// 作成日時の古い順でソート（「いつか」タブ用）
    func sortedByOldestFirst() -> [Plan] {
        sorted { $0.sortPriorityOldestFirst < $1.sortPriorityOldestFirst }
    }

    /// 作成日時の新しい順でソート
    func sortedByNewestFirst() -> [Plan] {
        sorted { $0.createdAt > $1.createdAt }
    }

    /// タブカテゴリでフィルタリング
    func filtered(by category: TabCategory) -> [Plan] {
        filter { $0.belongsTo(tab: category) }
    }

    /// アクティブな予定のみフィルタリング（未完了 & 未アーカイブ）
    var active: [Plan] {
        filter { !$0.isCompleted && !$0.isArchived }
    }
}
