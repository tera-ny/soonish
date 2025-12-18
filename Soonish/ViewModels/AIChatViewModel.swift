//
//  AIChatViewModel.swift
//  Soonish
//
//  Created by Claude on 2025/10/24.
//

import Foundation
import FoundationModels
import SwiftData

@MainActor
@Observable
class AIChatViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var proposedPlan: PlanSuggestion?
    var currentResponse: String = ""  // ストリーミング中のレスポンス
    var session: LanguageModelSession

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // LanguageModelSession の初期化
        let instructions = Instructions("""
あなたは「Soonish」という予定管理アプリのアシスタントです。
ユーザーのメッセージから予定を作成するために必要な情報を抽出し、足りない情報だけを聞いてください。

## 必要な情報
1. **タイトル**（必須）: 予定の概要を簡潔に。ユーザーの入力をそのまま使ってください
   例: 「冬に北陸でカニ食べたい」→ タイトル「北陸でカニ食べたい」
   例: 「確定申告しないと」→ タイトル「確定申告」
   例: 「春に旅行行きたいな、温泉とか」→ タイトル「春に旅行」、メモ「温泉」

2. **時期**（必須）: 以下のいずれかに該当するか判断してください
   - 期間タイプ: 「春」「夏」「秋」「冬」「今週」「今月」「来月」「今年」「来年」
   - 期限タイプ: 「1ヶ月後」「3ヶ月後」「半年後」「1年後」
   - いつか: 具体的な時期が決まっていない

   ※ユーザーが「冬に」「春頃」など時期を含めている場合は、それを使ってください。聞き直さないでください。

3. **メモ**（オプション）: タイトルに入れなかった追加の詳細情報がある場合のみ設定
   - タイトルだけで十分な場合は、メモは空（null）にしてください
   - 具体的な場所、持ち物、注意事項など、補足情報がある場合のみ使用

## 重要なルール
- 具体的な日付は聞かないでください。このアプリは「なんとなくの予定」を管理するものです
- ユーザーのメッセージに時期が含まれている場合は、それを使ってください。わざわざ聞き直さないでください
- タイトルと時期が揃ったら、すぐにsuggestionで提案してください。無駄な確認は不要です
- 足りない情報だけをquestionで聞いてください
- メモはタイトルと重複する内容を避け、本当に追加情報がある場合のみ設定してください

## メッセージタイプの使い分け
- **question**: タイトルまたは時期が不明な時のみ使用
- **confirmation**: ユーザーの回答を受け止める相槌（次の質問に繋げる）
- **suggestion**: タイトルと時期が両方揃った時。必ずPlanSuggestionを含めること

フレンドリーで親しみやすい口調で対話してください。
""")

        session = LanguageModelSession(instructions: instructions)

        // 初回メッセージ
        messages.append(ChatMessage(
            role: .assistant,
            content: "こんにちは！どんな予定を作りたいですか？😊"
        ))
    }

    // MARK: - Session Management

    func prewarmSession() async {
        session.prewarm()
    }

    // MARK: - Message Sending

    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: inputText)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil
        currentResponse = ""

        do {
            // プロンプトの構築
            let conversationHistory = messages.map {
                "\($0.role == .user ? "User:" : "ChatBot (you):") \($0.content)"
            }.joined(separator: "\n")

            let prompt = """
Previous messages: \(conversationHistory)

Respond to this new user message as best as you can.
You can use the previous messages included here as context if you are confused by the user's new message.

New user message: \(userMessage.content)
"""

            // ChatBotMessage のストリーミングレスポンス
            let response = try await session.respond(
                generating: ChatBotMessage.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(sampling: .random(top: 1)),
                prompt: {
                    Prompt(prompt)
                }
            )

            // ストリーミングで受
            

            switch response.content {
            case .question(let text):
                // 質問メッセージ
                let assistantMessage = ChatMessage(role: .assistant, content: text)
                messages.append(assistantMessage)

            case .confirmation(let text):
                // 確認・相槌メッセージ
                let assistantMessage = ChatMessage(role: .assistant, content: text)
                messages.append(assistantMessage)

            case .suggestion(let text, let plan):
                // 提案メッセージ
                let assistantMessage = ChatMessage(role: .assistant, content: text)
                messages.append(assistantMessage)

                // 予定提案をセット（モーダル表示される）
                proposedPlan = plan
            }
            currentResponse = ""

        } catch {
            errorMessage = "エラーが発生しました: \(error.localizedDescription)"
            print("Error generating response: \(error)")
        }

        isLoading = false
    }

    // MARK: - Plan Creation

    func createPlan() throws {
        guard let proposedPlan = proposedPlan else {
            throw PlanCreationError.noPlanProposed
        }

        let plan = try proposedPlan.toPlan()
        modelContext.insert(plan)
        try modelContext.save()
    }

    func cancelPlanCreation() {
        proposedPlan = nil

        // チャットを続ける
        let message = ChatMessage(
            role: .assistant,
            content: "わかりました。他に変更したいことはありますか？"
        )
        messages.append(message)
    }

    enum PlanCreationError: LocalizedError {
        case noPlanProposed

        var errorDescription: String? {
            switch self {
            case .noPlanProposed:
                return "作成する予定が提案されていません"
            }
        }
    }
}
