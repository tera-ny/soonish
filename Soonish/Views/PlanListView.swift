//
//  PlanListView.swift
//  Soonish
//
//  Created by Claude on 2025/10/18.
//

import SwiftUI
import SwiftData

/// 予定のリスト表示ビュー
struct PlanListView: View {
    @Environment(\.modelContext) private var modelContext

    /// 表示するタブカテゴリ
    let category: TabCategory

    /// アクティブな予定のみ取得（未完了 & 未アーカイブ）
    @Query(filter: #Predicate<Plan> { plan in
        !plan.isCompleted && !plan.isArchived
    }, sort: \Plan.createdAt, order: .reverse)
    private var allPlans: [Plan]

    /// このカテゴリに属する予定
    private var plans: [Plan] {
        let filtered = allPlans.filter { $0.belongsTo(tab: category) }

        // デフォルトソート（期限優先、作成日時の新しい順）
        return filtered.sortedByDefault()
    }

    var body: some View {
        Group {
            if plans.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(plans) { plan in
                        PlanRowView(plan: plan)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deletePlan(plan)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }

                                Button {
                                    toggleComplete(plan)
                                } label: {
                                    Label("完了", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    toggleArchive(plan)
                                } label: {
                                    Label("アーカイブ", systemImage: "archivebox")
                                }
                                .tint(.orange)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: category.iconName)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("予定がありません")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var emptyStateMessage: String {
        switch category {
        case .thisMonth:
            return "今月の予定を追加してみましょう"
        case .nextMonth:
            return "来月の予定を追加してみましょう"
        case .thisYear:
            return "今年の予定を追加してみましょう"
        case .nextYearOnwards:
            return "来年以降の予定を追加してみましょう"
        }
    }

    // MARK: - Actions

    private func deletePlan(_ plan: Plan) {
        withAnimation {
            modelContext.delete(plan)
        }
    }

    private func toggleComplete(_ plan: Plan) {
        withAnimation {
            plan.isCompleted.toggle()
            plan.updatedAt = Date()
        }
    }

    private func toggleArchive(_ plan: Plan) {
        withAnimation {
            plan.isArchived.toggle()
            plan.updatedAt = Date()
        }
    }
}

// MARK: - Plan Row View

/// 予定の行表示
struct PlanRowView: View {
    let plan: Plan

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // タイトル
            Text(plan.title)
                .font(.headline)

            // 期間情報
            HStack(spacing: 8) {
                // periodLabel がある場合のみ表示（季節のみ）
                if let displayText = plan.periodDisplayText {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(displayText)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                // デッドライン予定の残り期間（ざっくり表示）
                if let remainingText = plan.remainingDaysText {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(remainingText)
                    }
                    .font(.subheadline)
                    .foregroundStyle(plan.isPeriodExpired ? .red : .blue)
                }
            }

            // メモ
            if let memo = plan.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlanListView(category: .thisMonth)
            .navigationTitle("今月")
    }
    .modelContainer(for: Plan.self, inMemory: true)
}
