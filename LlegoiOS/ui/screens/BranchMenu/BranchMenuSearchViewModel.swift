//
//  BranchMenuSearchViewModel.swift
//  LlegoiOS
//
//  Búsqueda de texto dentro de las cartas de sucursales (con debounce)
//

import Foundation
import Combine

@MainActor
final class BranchMenuSearchViewModel: ObservableObject {
    @Published private(set) var results: [MenuSearchHit] = []
    @Published private(set) var isLoading = false

    private static let minQueryChars = 3
    private static let debounceNanoseconds: UInt64 = 350_000_000

    private let repository: BranchMenuRepository
    private var searchTask: Task<Void, Never>?

    init(repository: BranchMenuRepository = BranchMenuRepository()) {
        self.repository = repository
    }

    func search(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minQueryChars else {
            results = []
            isLoading = false
            return
        }
        isLoading = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: Self.debounceNanoseconds)
            guard !Task.isCancelled else { return }
            do {
                let hits = try await repository.searchMenus(query: trimmed)
                guard !Task.isCancelled else { return }
                results = hits
            } catch {
                guard !Task.isCancelled else { return }
                // Sección secundaria: si falla, simplemente no se muestra
                results = []
            }
            isLoading = false
        }
    }
}
