//
//  ConversationalAIProvider.swift
//  LlegoiOS
//

import Foundation

enum ConversationalAIProvider: String, CaseIterable, Identifiable {
    case appleIntelligence
    case llegoAI

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appleIntelligence:
            return "Apple Intelligence"
        case .llegoAI:
            return "LlegoAI"
        }
    }
}
