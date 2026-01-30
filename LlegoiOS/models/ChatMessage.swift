//
//  ChatMessage.swift
//  LlegoiOS
//
//  Modelo de mensaje para el chat conversacional con IA
//

import Foundation

struct ConversationalChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    var responseType: String?
    var productEntities: [AIChatProductEntity]?
    var branchEntities: [AIChatBranchEntity]?
    var confidence: Double?
    
    init(
        text: String,
        isFromUser: Bool,
        timestamp: Date,
        responseType: String? = nil,
        productEntities: [AIChatProductEntity]? = nil,
        branchEntities: [AIChatBranchEntity]? = nil,
        confidence: Double? = nil
    ) {
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.responseType = responseType
        self.productEntities = productEntities
        self.branchEntities = branchEntities
        self.confidence = confidence
    }
    
    static func == (lhs: ConversationalChatMessage, rhs: ConversationalChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}
