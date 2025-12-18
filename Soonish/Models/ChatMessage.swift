//
//  ChatMessage.swift
//  Soonish
//
//  Created by Claude on 2025/10/24.
//

import Foundation
import FoundationModels

/// チャットメッセージ
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date

    enum Role: String {
        case user
        case assistant
    }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
