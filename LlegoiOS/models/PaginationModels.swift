//
//  PaginationModels.swift
//  LlegoiOS
//
//  Created by Claude on 2026-01-08.
//

import Foundation

/// UI model for GraphQL PageInfo
struct PageInfo {
    let hasNextPage: Bool
    let hasPreviousPage: Bool
    let startCursor: String?
    let endCursor: String?
    let totalCount: Int

    /// Initialize from Apollo generated PageInfo
    init(hasNextPage: Bool, hasPreviousPage: Bool, startCursor: String?, endCursor: String?, totalCount: Int) {
        self.hasNextPage = hasNextPage
        self.hasPreviousPage = hasPreviousPage
        self.startCursor = startCursor
        self.endCursor = endCursor
        self.totalCount = totalCount
    }
}
