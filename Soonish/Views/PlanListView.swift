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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(plans) { plan in
                            PlanRowView(plan: plan)
                                .contextMenu {
                                    Button {
                                        toggleComplete(plan)
                                    } label: {
                                        Label("完了", systemImage: "checkmark")
                                    }

                                    Button {
                                        toggleArchive(plan)
                                    } label: {
                                        Label("アーカイブ", systemImage: "archivebox")
                                    }

                                    Button(role: .destructive) {
                                        deletePlan(plan)
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
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

/// 予定の行表示（カード型）
struct PlanRowView: View {
    let plan: Plan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // タイトル
            Text(plan.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            // 期間情報
            HStack(spacing: 12) {
                // periodLabel がある場合のみ表示（季節のみ）
                if let displayText = plan.periodDisplayText {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.body)
                            .foregroundStyle(Color(red: 0.55, green: 0.4, blue: 0.8))  // 紫
                        Text(displayText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.55, green: 0.4, blue: 0.8).opacity(0.1))  // 薄紫背景
                    .cornerRadius(12)
                }

                // デッドライン予定の残り期間（ざっくり表示）
                if let remainingText = plan.remainingDaysText {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.body)
                            .foregroundStyle(plan.isPeriodExpired ? .red : Color(red: 0.55, green: 0.4, blue: 0.8))  // 紫
                        Text(remainingText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((plan.isPeriodExpired ? Color.red : Color(red: 0.55, green: 0.4, blue: 0.8)).opacity(0.1))
                    .cornerRadius(12)
                }
            }

            // メモ
            if let memo = plan.memo, !memo.isEmpty {
                Text(memo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    /// カードの背景色（白ベースで統一）
    private var cardBackgroundColor: Color {
        // すべて白ベース（紫はアクセントとして使用）
        return Color(red: 1.0, green: 1.0, blue: 1.0)
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
