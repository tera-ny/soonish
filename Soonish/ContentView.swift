//
//  ContentView.swift
//  Soonish
//
//  Created by Haruta Yamada on 2025/10/18.
//

import SwiftUI
import SwiftData
import FoundationModels

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabCategory = .thisMonth
    @State private var sheetType: SheetType?
    @State private var showingAddMenu = false

    // テーマカラー（紫）
    private let purpleTheme = Color(red: 0.55, green: 0.4, blue: 0.8)

    // シートの種類
    enum SheetType: Identifiable {
        case addPlan
        case aiChat

        var id: Int {
            switch self {
            case .addPlan: return 0
            case .aiChat: return 1
            }
        }
    }

    private var isAIAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabCategory.visibleTabs, id: \.self) { category in
                NavigationStack {
                    PlanListView(category: category)
                        .navigationTitle(category.displayName)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    sheetType = .aiChat
                                } label: {
                                    HStack {
                                        Image(systemName: "bubble.left.and.text.bubble.right")
                                            .font(.title3)
                                            .foregroundStyle(purpleTheme)
                                        Text("AIで相談")
                                            .font(.body)
                                        Spacer()
                                    }
                                    .padding()
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            ToolbarItem {
                                Button {
                                    sheetType = .addPlan
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.pencil")
                                            .font(.title3)
                                            .foregroundStyle(purpleTheme)
                                        Text("フォームで追加")
                                            .font(.body)
                                        Spacer()
                                    }
                                    .padding()
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                }
                .tabItem {
                    Label(category.displayName, systemImage: category.iconName)
                }
                .tag(category)
            }
        }
        .tint(purpleTheme)  // タブバーの選択色を紫に
        .sheet(item: $sheetType) { type in
            switch type {
            case .addPlan:
                AddPlanView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .aiChat:
                AIChatView(modelContext: modelContext)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Add Menu Content

    private var addMenuContent: some View {
        VStack(spacing: 0) {
            Button {
                showingAddMenu = false
                // ポップオーバーが閉じるのを待ってからシートを表示
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    sheetType = .addPlan
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                        .foregroundStyle(purpleTheme)
                    Text("フォームで追加")
                        .font(.body)
                    Spacer()
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                showingAddMenu = false
                // ポップオーバーが閉じるのを待ってからシートを表示
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    sheetType = .aiChat
                }
            } label: {
                HStack {
                    Image(systemName: "bubble.left.and.text.bubble.right")
                        .font(.title3)
                        .foregroundStyle(purpleTheme)
                    Text("AIで相談")
                        .font(.body)
                    Spacer()
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 250)
    }

    // MARK: - Helper Methods

    private func handleAddButtonTap() {
        // FoundationModels が利用可能かチェック
        if isAIAvailable {
            // AI が利用可能な場合: メニューを表示
            showingAddMenu = true
        } else {
            // AI が利用不可の場合: 直接フォームを開く
            sheetType = .addPlan
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Plan.self, inMemory: true)
}
