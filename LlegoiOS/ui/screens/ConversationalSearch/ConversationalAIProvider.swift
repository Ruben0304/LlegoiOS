//
//  ConversationalAIProvider.swift
//  LlegoiOS
//

import Foundation

enum ConversationalAIProvider: String, CaseIterable, Identifiable {
    case llegoAI

    var id: String { rawValue }

    var title: String {
        return "LlegoAI"
    }
}
