//
//  AIChatView.swift
//  Soonish
//
//  Created by Claude on 2025/10/24.
//

import SwiftUI
import SwiftData
internal import Combine

struct AIChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: AIChatViewModel

    // テーマカラー（紫）
    private let purpleTheme = Color(red: 0.55, green: 0.4, blue: 0.8)

    init(modelContext: ModelContext) {
        viewModel = AIChatViewModel(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // メッセージリスト
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message, purpleTheme: purpleTheme)
                                    .id(message.id)
                            }

                            // ストリーミング中のレスポンスを表示
                            if !viewModel.currentResponse.isEmpty {
                                MessageBubble(
                                    message: ChatMessage(role: .assistant, content: viewModel.currentResponse),
                                    purpleTheme: purpleTheme
                                )
                                .opacity(0.7)  // ストリーミング中は薄く表示
                                .id("streaming")
                            }

                            // ローディングインジケーター（ストリーミング開始前）
                            if viewModel.isLoading && viewModel.currentResponse.isEmpty {
                                HStack {
                                    ProgressView()
                                        .tint(purpleTheme)
                                    Text("考え中...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.currentResponse) { _, _ in
                        // ストリーミング中も自動スクロール
                        if !viewModel.currentResponse.isEmpty {
                            withAnimation {
                                proxy.scrollTo("streaming", anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // 入力エリア
                HStack(spacing: 12) {
                    TextField("メッセージを入力", text: $viewModel.inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                        .lineLimit(1...5)

                    Button {
                        Task {
                            await viewModel.sendMessage()
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(purpleTheme)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("AIで予定作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.prewarmSession()
                }
            }
            .sheet(isPresented: .constant(viewModel.proposedPlan != nil)) {
                PlanConfirmationView(
                    planSuggestion: viewModel.proposedPlan!,
                    onConfirm: {
                        do {
                            try viewModel.createPlan()
                            dismiss()
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    },
                    onCancel: {
                        viewModel.cancelPlanCreation()
                    },
                    purpleTheme: purpleTheme
                )
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let purpleTheme: Color

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(backgroundColor)
                    .foregroundStyle(textColor)
                    .cornerRadius(16)

                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }

    private var backgroundColor: Color {
        message.role == .user ? purpleTheme : Color.gray.opacity(0.15)
    }

    private var textColor: Color {
        message.role == .user ? .white : .primary
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Plan Confirmation View

struct PlanConfirmationView: View {
    let planSuggestion: PlanSuggestion
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let purpleTheme: Color

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // アイコン
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(purpleTheme)
                    .padding(.top, 32)

                // 確認メッセージ
                Text("この内容で予定を作成しますか？")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // 予定の詳細
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(label: "タイトル", value: planSuggestion.title)

                    switch planSuggestion.timeType {
                    case .period(let generatedPeriodPreset):
                        DetailRow(label: "期間", value: generatedPeriodPreset.rawValue)
                    case .deadline(let generatedDeadlinePreset):
                        DetailRow(label: "期限", value: generatedDeadlinePreset.rawValue)
                    case .anytime:
                        EmptyView()
                    }

                    if let memo = planSuggestion.memo, !memo.isEmpty {
                        DetailRow(label: "メモ", value: memo)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer()

                // ボタン
                HStack(spacing: 16) {
                    Button("修正する") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .tint(purpleTheme)

                    Button("作成する") {
                        onConfirm()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(purpleTheme)
                }
                .padding()
            }
            .navigationTitle("予定の確認")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }
}


