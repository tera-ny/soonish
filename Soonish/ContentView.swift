//
//  ContentView.swift
//  Soonish
//
//  Created by Haruta Yamada on 2025/10/18.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabCategory = .thisMonth
    @State private var showingAddPlan = false
    @State private var addPlanViewHeight: CGFloat = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabCategory.visibleTabs, id: \.self) { category in
                NavigationStack {
                    PlanListView(category: category)
                        .navigationTitle(category.displayName)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    showingAddPlan = true
                                } label: {
                                    Label("予定を追加", systemImage: "plus")
                                }
                            }
                        }
                }
                .tabItem {
                    Label(category.displayName, systemImage: category.iconName)
                }
                .tag(category)
            }
        }
        .sheet(isPresented: $showingAddPlan) {
            GeometryReader { geometry in
                AddPlanView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Plan.self, inMemory: true)
}
