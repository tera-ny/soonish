//
//  AddPlanView.swift
//  Soonish
//
//  Created by Claude on 2025/10/18.
//

import SwiftUI
import SwiftData

// MARK: - ContentHeightPreferenceKey

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 100

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - AddPlanView

/// 予定追加ビュー
struct AddPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var timeType: PlanTimeType = .period
    @State private var periodPreset: PeriodPreset = .thisWeek
    @State private var deadlinePreset: DeadlinePreset = .oneMonth
    @State private var customDeadlineDate = Date()
    @State private var memo = ""
    @State private var contentHeight: CGFloat = 500

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("なにする？", text: $title)
                }

                Section {
                    Picker("どう決める？", selection: $timeType) {
                        ForEach(PlanTimeType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    switch timeType {
                    case .period:
                        Picker("期間", selection: $periodPreset) {
                            ForEach(PeriodPreset.allCases) { preset in
                                Text(preset.displayName).tag(preset)
                            }
                        }
                    case .deadline:
                        Picker("期限", selection: $deadlinePreset) {
                            ForEach(DeadlinePreset.allCases) { preset in
                                HStack {
                                    Text(preset.displayName)
                                    Spacer()
                                    if preset != .custom, let deadline = preset.calculateDeadline() {
                                        Text(formatDate(deadline))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(preset)
                            }
                        }

                        if deadlinePreset == .custom {
                            DatePicker(
                                "日にちを選ぶ",
                                selection: $customDeadlineDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                        }
                    case .anytime:
                        EmptyView()
                    }
                    // timeType == .anytime の場合は何も表示しない
                }

                Section {
                    TextEditor(text: $memo)
                        .frame(height: 100)
                } header: {
                    Text("メモ（なくてもOK）")
                }

                Section {
                    Button {
                        addPlan()
                    } label: {
                        Text("追加する")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("やりたいこと")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(false)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ContentHeightPreferenceKey.self, value: geometry.size.height)
                }
            )
            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                contentHeight = height
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func addPlan() {
        let plan: Plan

        switch timeType {
        case .period:
            plan = Plan.withPeriod(
                title: title,
                periodPreset: periodPreset,
                memo: memo.isEmpty ? nil : memo
            )

        case .deadline:
            plan = Plan.withDeadline(
                title: title,
                deadlinePreset: deadlinePreset,
                customDeadlineDate: deadlinePreset == .custom ? customDeadlineDate : nil,
                memo: memo.isEmpty ? nil : memo
            )

        case .anytime:
            plan = Plan.withAnytime(
                title: title,
                memo: memo.isEmpty ? nil : memo
            )
        }

        modelContext.insert(plan)

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddPlanView()
        .modelContainer(for: Plan.self, inMemory: true)
}
