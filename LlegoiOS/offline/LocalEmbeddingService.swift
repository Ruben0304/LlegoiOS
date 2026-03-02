//
//  LocalEmbeddingService.swift
//  LlegoiOS
//
//  Servicio de embeddings locales usando NaturalLanguage de Apple.
//  Usa modelos en español e inglés en paralelo para manejar términos
//  mixtos (nombres de marca, anglicismos, etc.).
//

import Foundation
import NaturalLanguage

final class LocalEmbeddingService: @unchecked Sendable {
    static let shared = LocalEmbeddingService()

    private let embeddingES: NLEmbedding?
    private let embeddingEN: NLEmbedding?

    private init() {
        embeddingES = NLEmbedding.sentenceEmbedding(for: .spanish)
        embeddingEN = NLEmbedding.sentenceEmbedding(for: .english)
    }

    var isAvailable: Bool { embeddingES != nil || embeddingEN != nil }

    // MARK: - Indexing

    /// Genera el mejor vector para indexar un texto.
    /// Prueba ambos modelos y devuelve el vector con mayor magnitud
    /// (el modelo más "seguro" para ese texto).
    func embed(text: String) -> [Double]? {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let vecES = embeddingES?.vector(for: normalized)
        let vecEN = embeddingEN?.vector(for: normalized)

        switch (vecES, vecEN) {
        case (.some(let es), .some(let en)):
            // Elegir el de mayor magnitud: indica que el modelo reconoció mejor el texto
            return magnitude(es) >= magnitude(en) ? es : en
        case (.some(let es), nil):
            return es
        case (nil, .some(let en)):
            return en
        default:
            return nil
        }
    }

    // MARK: - Search

    /// Calcula la similitud máxima de una query contra un vector indexado,
    /// probando la query en ambos idiomas.
    /// Devuelve el score más alto encontrado (0...1).
    func bestSimilarity(queryText: String, against stored: [Double]) -> Double {
        let normalized = queryText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return 0 }

        var best: Double = 0

        if let vecES = embeddingES?.vector(for: normalized) {
            best = max(best, cosineSimilarity(vecES, stored))
        }
        if let vecEN = embeddingEN?.vector(for: normalized) {
            best = max(best, cosineSimilarity(vecEN, stored))
        }

        return best
    }

    // MARK: - Math

    /// Similitud coseno entre dos vectores (0...1)
    func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        let dot = zip(a, b).reduce(0.0) { $0 + $1.0 * $1.1 }
        let magA = sqrt(a.reduce(0.0) { $0 + $1 * $1 })
        let magB = sqrt(b.reduce(0.0) { $0 + $1 * $1 })
        guard magA > 0, magB > 0 else { return 0 }
        return dot / (magA * magB)
    }

    private func magnitude(_ v: [Double]) -> Double {
        sqrt(v.reduce(0.0) { $0 + $1 * $1 })
    }
}
