//
//  ChatMessage.swift
//  LlegoiOS
//
//  Modelo de mensaje para el chat conversacional con IA
//

import Foundation

enum ConversationalChatAction: Equatable {
    case openPlans
}

struct ConversationalChatMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    var responseType: String?
    var productEntities: [AIChatProductEntity]?
    var branchEntities: [AIChatBranchEntity]?
    var confidence: Double?
    var actionTitle: String?
    var action: ConversationalChatAction?
    
    init(
        id: UUID = UUID(),
        text: String,
        isFromUser: Bool,
        timestamp: Date,
        responseType: String? = nil,
        productEntities: [AIChatProductEntity]? = nil,
        branchEntities: [AIChatBranchEntity]? = nil,
        confidence: Double? = nil,
        actionTitle: String? = nil,
        action: ConversationalChatAction? = nil
    ) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.responseType = responseType
        self.productEntities = productEntities
        self.branchEntities = branchEntities
        self.confidence = confidence
        self.actionTitle = actionTitle
        self.action = action
    }
    
    static func == (lhs: ConversationalChatMessage, rhs: ConversationalChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}
