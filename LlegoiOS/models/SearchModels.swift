import Foundation

// MARK: - Search Category
enum SearchCategory: String, CaseIterable {
    case products = "Productos"
    case stores = "Negocios"
    case both = "Ambos"
}

/// Una selección de productos normales ofrecida como una sola acción de carrito.
struct SearchCombination: Identifiable, Sendable {
    let id: String
    let branchId: String
    let branchName: String
    let products: [SearchCombinationProduct]
    let totalPrice: Double
    let currency: String
}

struct SearchCombinationProduct: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let price: Double
    let currency: String
    let imageUrl: String?
    let quantity: Int

    init(
        id: String,
        branchId: String,
        name: String,
        price: Double,
        currency: String,
        imageUrl: String?,
        quantity: Int = 1
    ) {
        self.id = id
        self.branchId = branchId
        self.name = name
        self.price = price
        self.currency = currency
        self.imageUrl = imageUrl
        self.quantity = quantity
    }
}

struct SearchCombinationSegment: Sendable, Equatable {
    let text: String
    let canMergeWithPrevious: Bool
}

/// Parsing is deliberately tentative: every conjunction is split, and the
/// catalog resolver decides whether adjacent `y` fragments name one product.
enum SearchCombinationParser {
    enum ParseResult: Equatable {
        case single
        case combination([String])
        case quantityNeedsConfiguration
        case tooManyIntents
    }

    static func parse(_ query: String) -> ParseResult {
        let parsedSegments = segments(query)
        guard !parsedSegments.isEmpty else { return .single }
        guard !parsedSegments.contains(where: hasLeadingQuantity) else {
            return .quantityNeedsConfiguration
        }
        let hasTrailingQuantity = parsedSegments.contains { segment in
            segment.text.range(
                of: #"\bx\s*\d+\s*$"#,
                options: [.regularExpression, .caseInsensitive]
            ) != nil
        }
        guard !hasTrailingQuantity else { return .quantityNeedsConfiguration }

        let intents = parsedSegments.map(\.text)
        guard intents.count > 1 else { return .single }
        guard intents.count <= 4 else { return .tooManyIntents }
        return .combination(intents)
    }

    static func segments(_ query: String) -> [SearchCombinationSegment] {
        let source = query as NSString
        guard source.length > 0 else { return [] }
        let expression = try? NSRegularExpression(pattern: #"(?i)\by\b|[,;+]"#)
        let matches = expression?.matches(
            in: query,
            range: NSRange(location: 0, length: source.length)
        ) ?? []
        var result: [SearchCombinationSegment] = []
        var cursor = 0
        var canMergeNext = false
        var hardBoundaryPending = false

        for match in matches {
            let fragment = source.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !fragment.isEmpty {
                result.append(SearchCombinationSegment(text: fragment, canMergeWithPrevious: canMergeNext))
                hardBoundaryPending = false
            }
            let delimiter = source.substring(with: match.range)
            if delimiter.lowercased() == "y" {
                canMergeNext = !hardBoundaryPending
            } else {
                canMergeNext = false
                hardBoundaryPending = true
            }
            cursor = NSMaxRange(match.range)
        }

        let tail = source.substring(from: cursor).trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty {
            result.append(SearchCombinationSegment(text: tail, canMergeWithPrevious: canMergeNext))
        }
        return result
    }

    private static func hasLeadingQuantity(_ segment: SearchCombinationSegment) -> Bool {
        let words = segment.text.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
        var index = 0
        let requestVerbs: Set<String> = ["quiero", "quisiera", "dame", "necesito"]
        while index < words.count, requestVerbs.contains(words[index]) { index += 1 }
        guard index < words.count else { return false }

        let first = words[index]
        let numericPrefix = first.replacingOccurrences(of: #"x$"#, with: "", options: .regularExpression)
        if Int(numericPrefix) != nil { return true }
        let numberWords: Set<String> = [
            "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve",
            "diez", "once", "doce"
        ]
        return numberWords.contains(first)
    }

    fileprivate static func canonical(_ word: String) -> String {
        var value = word.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        let commonPlurals = [
            "jamones": "jamon", "limones": "limon", "frijoles": "frijol",
            "pasteles": "pastel", "tamales": "tamal", "sabores": "sabor"
        ]
        if let singular = commonPlurals[value] { return singular }
        if value.count > 4, value.hasSuffix("ces") {
            value.removeLast(3)
            value.append("z")
        } else if value.count > 3, value.hasSuffix("s") {
            value.removeLast()
        }
        return value
    }

}

/// Product data used only for combination matching; unlike Product it retains
/// the actual branch ID, availability, description and numeric currency values.
struct SearchCombinationCandidate: Sendable {
    let id: String
    let branchId: String
    let branchName: String
    let businessName: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let imageUrl: String?
    let availability: Bool
}

struct SearchCombinationIntentResult: Identifiable, Sendable {
    let intent: String
    let products: [SearchCombinationCandidate]
    var id: String { intent }
}

enum SearchCombinationIntentResolver {
    static func resolve(
        segments: [SearchCombinationSegment],
        candidatesBySegment: [[SearchCombinationCandidate]],
        catalogCandidates: [SearchCombinationCandidate]
    ) -> [SearchCombinationIntentResult] {
        guard !segments.isEmpty, candidatesBySegment.count == segments.count else { return [] }
        var results: [SearchCombinationIntentResult] = []
        var start = 0

        while start < segments.count {
            var mergedEnd: Int?
            if start + 1 < segments.count {
                for end in stride(from: segments.count - 1, through: start + 1, by: -1) {
                    guard (start + 1...end).allSatisfy({ segments[$0].canMergeWithPrevious }) else { continue }
                    let mergedText = segments[start...end].map(\.text).joined(separator: " y ")
                    let demonstratedByCatalogName = catalogCandidates.contains { candidate in
                        candidate.availability && SearchCombinationMatcher.productNameContainsAllMeaningfulTerms(
                            intent: mergedText,
                            name: candidate.name
                        )
                    }
                    if demonstratedByCatalogName {
                        mergedEnd = end
                        break
                    }
                }
            }

            if let end = mergedEnd {
                let intent = segments[start...end].map(\.text).joined(separator: " y ")
                results.append(SearchCombinationIntentResult(intent: intent, products: catalogCandidates))
                start = end + 1
            } else {
                results.append(SearchCombinationIntentResult(
                    intent: segments[start].text,
                    products: candidatesBySegment[start]
                ))
                start += 1
            }
        }
        return results
    }
}

enum SearchCombinationMatcher {
    static func matchingCandidates(
        intent: String,
        candidates: [SearchCombinationCandidate],
        limit: Int = 6
    ) -> [SearchCombinationCandidate] {
        var seen: Set<String> = []
        return candidates.filter {
            seen.insert($0.id).inserted && !$0.branchId.isEmpty && $0.availability && $0.price.isFinite && $0.price >= 0
                && !$0.currency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && isReasonableMatch(intent: intent, candidate: $0)
        }.prefix(max(0, limit)).map { $0 }
    }

    static func build(
        intents: [String],
        candidatesByIntent: [[SearchCombinationCandidate]],
        limit: Int = 8
    ) -> [SearchCombination] {
        guard (2...4).contains(intents.count), candidatesByIntent.count == intents.count else { return [] }
        let boundedCandidates = candidatesByIntent.enumerated().map { index, candidates in
            matchingCandidates(intent: intents[index], candidates: candidates, limit: 60)
        }
        let branchIDs = Set(boundedCandidates[0].map(\.branchId).filter { !$0.isEmpty })
        var combinations: [SearchCombination] = []

        for branchID in branchIDs.sorted() {
            let lists = boundedCandidates.map { $0.filter { $0.branchId == branchID } }
            guard lists.allSatisfy({ !$0.isEmpty }) else { continue }
            var budget = 2048
            guard let chosen = selectProducts(lists, chosen: [], budget: &budget) else { continue }
            guard chosen.count == intents.count, let first = chosen.first else { continue }
            let products = chosen.map {
                SearchCombinationProduct(
                    id: $0.id,
                    branchId: $0.branchId,
                    name: $0.name,
                    price: $0.price,
                    currency: $0.currency,
                    imageUrl: $0.imageUrl
                )
            }
            combinations.append(SearchCombination(
                id: "\(branchID):\(products.map(\.id).joined(separator: "+"))",
                branchId: branchID,
                branchName: first.businessName,
                products: products,
                totalPrice: chosen.reduce(0) { $0 + $1.price },
                currency: first.currency
            ))
        }

        return combinations
            .sorted {
                $0.currency == $1.currency ? $0.totalPrice < $1.totalPrice : $0.currency < $1.currency
            }
            .prefix(max(0, limit))
            .map { $0 }
    }

    /// Bounded backtracking avoids losing a match when an early, broad intent
    /// chooses the only product that can satisfy a later, more specific intent.
    private static func selectProducts(
        _ lists: [[SearchCombinationCandidate]],
        chosen: [SearchCombinationCandidate],
        budget: inout Int
    ) -> [SearchCombinationCandidate]? {
        guard chosen.count < lists.count else { return chosen }
        for candidate in lists[chosen.count] {
            guard budget > 0 else { return nil }
            budget -= 1
            guard !chosen.contains(where: { $0.id == candidate.id }),
                  chosen.first.map({ $0.currency == candidate.currency }) ?? true else { continue }
            if let result = selectProducts(lists, chosen: chosen + [candidate], budget: &budget) {
                return result
            }
        }
        return nil
    }

    private static func canonical(_ word: String) -> String {
        SearchCombinationParser.canonical(word)
    }

    private static func isReasonableMatch(intent: String, candidate: SearchCombinationCandidate) -> Bool {
        let terms = meaningfulTerms(intent)
        guard !terms.isEmpty else { return false }
        let nameTerms = Set(tokens(candidate.name).map(canonical))
        let allTerms = nameTerms.union(tokens(candidate.description).map(canonical))
        // A single specific term can be established by an exact description
        // token when the catalog name uses a different product label. Multi-
        // term searches still need every qualifier and an anchor in the name.
        if terms.count == 1 { return terms.isSubset(of: allTerms) }
        return !terms.intersection(nameTerms).isEmpty && terms.isSubset(of: allTerms)
    }

    static func productNameContainsAllMeaningfulTerms(intent: String, name: String) -> Bool {
        let terms = meaningfulTerms(intent)
        guard !terms.isEmpty else { return false }
        return terms.isSubset(of: Set(tokens(name).map(canonical)))
    }

    private static func meaningfulTerms(_ value: String) -> Set<String> {
        Set(tokens(value).filter { !stopWords.contains($0) }.map(canonical).filter { $0.count > 1 })
    }

    private static func tokens(_ value: String) -> Set<String> {
        Set(value.lowercased().folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init))
    }

    private static let stopWords: Set<String> = [
        "con", "del", "de", "para", "por", "una", "uno", "un", "el", "la", "los", "las",
        "quiero", "quisiera", "porfa", "favor", "mas", "y", "the", "and", "unos", "unas"
    ]
}
