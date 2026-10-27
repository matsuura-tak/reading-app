import Foundation

public struct RecommendableBook: Codable, Sendable, Equatable {
    public var id: UUID?
    public var isbn13: String?
    public var ndc: String?
    public var title: String
    public var author: String?
    public var publisher: String?
    public var label: String?
    public var publishedYear: Int?
    public var award: String?
    public var awardSessionOrYear: String?
    public var seriesTitle: String?
    public var volumeNumber: Int?
    public var status: BookStatus?
    public var addedAt: String?
    public var finishedAt: String?

    public nonisolated init(
        id: UUID? = nil,
        isbn13: String? = nil,
        ndc: String? = nil,
        title: String,
        author: String? = nil,
        publisher: String? = nil,
        label: String? = nil,
        publishedYear: Int? = nil,
        award: String? = nil,
        awardSessionOrYear: String? = nil,
        seriesTitle: String? = nil,
        volumeNumber: Int? = nil,
        status: BookStatus? = nil,
        addedAt: String? = nil,
        finishedAt: String? = nil
    ) {
        self.id = id
        self.isbn13 = isbn13
        self.ndc = ndc
        self.title = title
        self.author = author
        self.publisher = publisher
        self.label = label
        self.publishedYear = publishedYear
        self.award = award
        self.awardSessionOrYear = awardSessionOrYear
        self.seriesTitle = seriesTitle
        self.volumeNumber = volumeNumber
        self.status = status
        self.addedAt = addedAt
        self.finishedAt = finishedAt
    }
}

public struct RecommendationCandidate: Codable, Sendable, Equatable {
    public var id: String
    public var bookId: UUID?
    public var isbn13: String?
    public var ndc: String?
    public var title: String
    public var author: String?
    public var publisher: String?
    public var label: String?
    public var publishedYear: Int?
    public var award: String?
    public var seriesTitle: String?
    public var volumeNumber: Int?
    public var axis: RecommendationAxis
    public var reason: String
    public var isOwnedTsundoku: Bool

    public nonisolated init(
        id: String,
        bookId: UUID? = nil,
        isbn13: String? = nil,
        ndc: String? = nil,
        title: String,
        author: String? = nil,
        publisher: String? = nil,
        label: String? = nil,
        publishedYear: Int? = nil,
        award: String? = nil,
        seriesTitle: String? = nil,
        volumeNumber: Int? = nil,
        axis: RecommendationAxis,
        reason: String,
        isOwnedTsundoku: Bool
    ) {
        self.id = id
        self.bookId = bookId
        self.isbn13 = isbn13
        self.ndc = ndc
        self.title = title
        self.author = author
        self.publisher = publisher
        self.label = label
        self.publishedYear = publishedYear
        self.award = award
        self.seriesTitle = seriesTitle
        self.volumeNumber = volumeNumber
        self.axis = axis
        self.reason = reason
        self.isOwnedTsundoku = isOwnedTsundoku
    }
}

public enum RecommendationEngine: Sendable {
    public static let minimumCooccurrenceCount: Int = 10

    /// Computes the weight score `chosen * 2 - skipped` (AC-147).
    public nonisolated static func score(chosenCount: Int, skippedCount: Int) -> Int {
        chosenCount * 2 - skippedCount
    }

    /// Returns the 5 recommendation axes sorted by descending weight score, breaking ties with default priority rank (AC-147).
    public nonisolated static func orderedAxes(from weights: [H02SeedRecommendationWeight]) -> [RecommendationAxis] {
        var scoreByAxis: [RecommendationAxis: Int] = [:]
        for axis in RecommendationAxis.allCases {
            scoreByAxis[axis] = 0
        }
        for w in weights {
            scoreByAxis[w.axis] = score(chosenCount: w.chosenCount, skippedCount: w.skippedCount)
        }
        return RecommendationAxis.allCases.sorted { lhs, rhs in
            let lScore = scoreByAxis[lhs, default: 0]
            let rScore = scoreByAxis[rhs, default: 0]
            if lScore != rScore {
                return lScore > rScore
            }
            return lhs.defaultPriorityRank < rhs.defaultPriorityRank
        }
    }

    /// Filters co-occurrence candidates to `count >= 10` AND `ndc` starting with `"9"` (literature) (AC-148).
    public nonisolated static func filterCooccurrenceCandidates(
        _ candidates: [H24CooccurrenceCandidate]
    ) -> [H24CooccurrenceCandidate] {
        candidates
            .filter { item in
                item.count >= minimumCooccurrenceCount &&
                item.ndc.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("9")
            }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count {
                    return lhs.count > rhs.count
                }
                return lhs.isbn13 < rhs.isbn13
            }
    }

    /// Formats the 1-line recommendation reason (never includes headcount numbers for `.readers`, AC-79, AC-80, AC-87, AC-148).
    public nonisolated static func formatReason(
        axis: RecommendationAxis,
        isOwnedTsundoku: Bool = false,
        baseBookTitle: String? = nil,
        seriesTitle: String? = nil,
        volumeNumber: Int? = nil,
        author: String? = nil,
        award: String? = nil,
        awardSessionOrYear: String? = nil,
        label: String? = nil
    ) -> String {
        _ = baseBookTitle
        _ = seriesTitle
        _ = volumeNumber
        _ = author
        if isOwnedTsundoku {
            switch axis {
            case .readers:
                return "積読から・この本を読み終えた人が、次に読んだ本"
            case .nextVolume:
                return "積読から・シリーズの次の巻"
            case .sameAuthor:
                return "積読から・同じ著者"
            case .sameAward:
                if let award, !award.isEmpty {
                    return "積読から・同じ賞（\(award)）"
                }
                return "積読から・同じ賞"
            case .sameLabel:
                if let label, !label.isEmpty {
                    return "積読から・同じレーベル（\(label)）"
                }
                return "積読から・同じレーベル"
            }
        } else {
            switch axis {
            case .readers:
                return "この本を読み終えた人が、次に読んだ本"
            case .nextVolume:
                return "シリーズの次の巻"
            case .sameAuthor:
                return "同じ著者の本"
            case .sameAward:
                let awardName = (award?.isEmpty == false) ? award ?? "文学賞" : "文学賞"
                if let session = awardSessionOrYear, !session.isEmpty, !awardName.contains(session) {
                    return "同じ賞（\(session) \(awardName)）"
                }
                return "同じ賞（\(awardName)）"
            case .sameLabel:
                if let label, !label.isEmpty {
                    return "同じレーベル（\(label)）"
                }
                return "同じレーベルの本"
            }
        }
    }

    /// Extracts series title and volume number if not explicitly set, or uses explicit properties.
    public nonisolated static func resolveSeriesAndVolume(for book: RecommendableBook) -> (series: String, volume: Int)? {
        if let s = book.seriesTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
           !s.isEmpty,
           let v = book.volumeNumber, v >= 1 {
            return (series: s, volume: v)
        }
        return parseSeriesAndVolumeFromTitle(book.title)
    }

    /// Parses trailing volume numbers like `"物語シリーズ 2"` or `"物語シリーズ（2）"` or `"物語シリーズ 第2巻"`.
    public nonisolated static func parseSeriesAndVolumeFromTitle(_ rawTitle: String) -> (series: String, volume: Int)? {
        let normalized = InputValidator.normalizeDigits(rawTitle)
            .replacingOccurrences(of: "（", with: "(")
            .replacingOccurrences(of: "）", with: ")")
            .replacingOccurrences(of: "第", with: " ")
            .replacingOccurrences(of: "巻", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.hasSuffix(")"), let openIdx = normalized.lastIndex(of: "(") {
            let inside = normalized[normalized.index(after: openIdx)..<normalized.index(before: normalized.endIndex)]
                .trimmingCharacters(in: .whitespaces)
            if let vol = Int(inside), vol >= 1 {
                let prefix = String(normalized[..<openIdx]).trimmingCharacters(in: .whitespaces)
                if !prefix.isEmpty {
                    return (series: prefix, volume: vol)
                }
            }
        }

        let parts = normalized.split(separator: " ")
        if parts.count >= 2, let last = parts.last, let vol = Int(last), vol >= 1 {
            let prefix = parts.dropLast().joined(separator: " ").trimmingCharacters(in: .whitespaces)
            if !prefix.isEmpty {
                return (series: prefix, volume: vol)
            }
        }
        return nil
    }

    /// Checks whether `candidate` is the immediate next volume (`volume + 1`) of `baseBook` (AC-87).
    public nonisolated static func isNextVolume(candidate: RecommendableBook, of baseBook: RecommendableBook) -> Bool {
        guard let baseSV = resolveSeriesAndVolume(for: baseBook),
              let candSV = resolveSeriesAndVolume(for: candidate) else {
            return false
        }
        let normBase = AwardsCatalog.normalizeTitle(baseSV.series)
        let normCand = AwardsCatalog.normalizeTitle(candSV.series)
        return !normBase.isEmpty && normBase == normCand && candSV.volume == baseSV.volume + 1
    }

    /// Checks whether `candidate` matches `baseBook` on the given `axis`, and returns the formatted reason if matched.
    public nonisolated static func matchAxis(
        _ axis: RecommendationAxis,
        candidate: RecommendableBook,
        baseBook: RecommendableBook,
        isOwnedTsundoku: Bool = false,
        validCooccurrenceISBNs: Set<String> = [],
        awardsCatalog: [H25AwardItem]? = nil
    ) -> String? {
        switch axis {
        case .readers:
            if let isbn = candidate.isbn13, validCooccurrenceISBNs.contains(isbn) {
                return formatReason(axis: .readers, isOwnedTsundoku: isOwnedTsundoku, baseBookTitle: baseBook.title)
            }
            return nil
        case .nextVolume:
            guard isNextVolume(candidate: candidate, of: baseBook) else { return nil }
            let sv = resolveSeriesAndVolume(for: candidate)
            return formatReason(
                axis: .nextVolume,
                isOwnedTsundoku: isOwnedTsundoku,
                baseBookTitle: baseBook.title,
                seriesTitle: sv?.series ?? baseBook.seriesTitle,
                volumeNumber: sv?.volume ?? candidate.volumeNumber
            )
        case .sameAuthor:
            let baseAuthor = AwardsCatalog.normalizeAuthor(baseBook.author)
            let candAuthor = AwardsCatalog.normalizeAuthor(candidate.author)
            guard !baseAuthor.isEmpty, baseAuthor == candAuthor else { return nil }
            // Do not match if it's the exact same normalized title
            guard AwardsCatalog.normalizeTitle(baseBook.title) != AwardsCatalog.normalizeTitle(candidate.title) else {
                return nil
            }
            return formatReason(
                axis: .sameAuthor,
                isOwnedTsundoku: isOwnedTsundoku,
                author: AuthorNameFormatter.format(candidate.author ?? baseBook.author)
            )
        case .sameAward:
            let catalog = awardsCatalog ?? AwardsCatalog.allBundledAwards()
            let baseAward = (baseBook.award ?? AwardsCatalog.matchAwardName(title: baseBook.title, author: baseBook.author, catalog: catalog))?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let candAward = (candidate.award ?? AwardsCatalog.matchAwardName(title: candidate.title, author: candidate.author, catalog: catalog))?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !baseAward.isEmpty, baseAward == candAward else { return nil }
            guard AwardsCatalog.normalizeTitle(baseBook.title) != AwardsCatalog.normalizeTitle(candidate.title) else {
                return nil
            }
            return formatReason(
                axis: .sameAward,
                isOwnedTsundoku: isOwnedTsundoku,
                award: candAward,
                awardSessionOrYear: candidate.awardSessionOrYear
            )
        case .sameLabel:
            let baseLabel = baseBook.label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let candLabel = candidate.label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !baseLabel.isEmpty, baseLabel == candLabel else { return nil }
            guard AwardsCatalog.normalizeTitle(baseBook.title) != AwardsCatalog.normalizeTitle(candidate.title) else {
                return nil
            }
            return formatReason(axis: .sameLabel, isOwnedTsundoku: isOwnedTsundoku, label: candLabel)
        }
    }

    /// Generates up to 3 candidates for S-9 (after finishing a book):
    /// Prioritizes up to 2 related `.tsundoku` shelf books first (or up to 3 when no unowned candidates exist),
    /// then fills with unowned related candidates, then falls back to remaining `.tsundoku` books (AC-75〜80, AC-87).
    public nonisolated static func nextCandidates(
        justFinishedBook: RecommendableBook,
        shelfBooks: [RecommendableBook],
        externalPool: [RecommendableBook] = [],
        cooccurrence: [H24CooccurrenceCandidate] = [],
        awardsCatalog: [H25AwardItem]? = nil,
        weights: [H02SeedRecommendationWeight] = [],
        maxCount: Int = 3
    ) -> [RecommendationCandidate] {
        guard maxCount > 0 else { return [] }
        let axes = orderedAxes(from: weights)
        let filteredCooc = filterCooccurrenceCandidates(cooccurrence)
        let coocISBNs = Set(filteredCooc.map(\.isbn13))
        let resolvedCatalog = awardsCatalog ?? AwardsCatalog.allBundledAwards()

        var seenKeys = Set<String>()
        seenKeys.insert(dedupKey(for: justFinishedBook))
        for b in shelfBooks where b.status == .finished || b.status?.isCurrentReading == true {
            seenKeys.insert(dedupKey(for: b))
        }

        var unownedSeenKeys = seenKeys
        for b in shelfBooks {
            unownedSeenKeys.insert(dedupKey(for: b))
        }
        let unownedByAxis = buildUnownedCandidatesByAxis(
            baseBooks: [justFinishedBook],
            externalPool: externalPool,
            filteredCooccurrence: filteredCooc,
            awardsCatalog: resolvedCatalog,
            seenKeys: unownedSeenKeys
        )
        var availableUnowned: [RecommendationCandidate] = []
        for axis in axes {
            for cand in unownedByAxis[axis, default: []] {
                let key = dedupKey(title: cand.title, author: cand.author, isbn13: cand.isbn13)
                guard !unownedSeenKeys.contains(key) else { continue }
                unownedSeenKeys.insert(key)
                availableUnowned.append(cand)
            }
        }

        let ownedRelatedLimit = availableUnowned.isEmpty ? maxCount : min(maxCount - 1, 2)
        let tsundokuBooks = shelfBooks
            .filter { $0.status == .tsundoku }
            .sorted { ($0.addedAt ?? "") > ($1.addedAt ?? "") }
        var results: [RecommendationCandidate] = []

        // 1. Owned tsundoku books matching an axis in priority order (up to 2 when unowned exist, or up to 3 when none)
        for axis in axes {
            for book in tsundokuBooks {
                guard results.count < ownedRelatedLimit else { break }
                let key = dedupKey(for: book)
                guard !seenKeys.contains(key) else { continue }
                if let reason = matchAxis(
                    axis,
                    candidate: book,
                    baseBook: justFinishedBook,
                    isOwnedTsundoku: true,
                    validCooccurrenceISBNs: coocISBNs,
                    awardsCatalog: resolvedCatalog
                ) {
                    seenKeys.insert(key)
                    results.append(makeCandidate(from: book, axis: axis, reason: reason, isOwnedTsundoku: true))
                }
            }
        }

        // 2. Unowned related candidates in axis priority order
        for cand in availableUnowned {
            guard results.count < maxCount else { break }
            let key = dedupKey(title: cand.title, author: cand.author, isbn13: cand.isbn13)
            guard !seenKeys.contains(key) else { continue }
            seenKeys.insert(key)
            results.append(cand)
        }

        // 3. Fallback: remaining owned tsundoku books that didn't match an axis (AC-80)
        let includedBookIDs = Set(results.compactMap(\.bookId))
        for book in tsundokuBooks {
            guard results.count < maxCount else { break }
            if let bid = book.id, includedBookIDs.contains(bid) { continue }
            if results.contains(where: { $0.title == book.title }) { continue }
            results.append(makeCandidate(from: book, axis: .sameAuthor, reason: "積読から", isOwnedTsundoku: true))
        }

        return results
    }

    /// Generates up to 5 unowned candidates for S-7 ("つぎの1冊"):
    /// Uses round-robin across axes first so multiple axes are represented (AC-146), then fills up to 5 in axis priority order.
    public nonisolated static func afterCandidates(
        shelfBooks: [RecommendableBook],
        externalPool: [RecommendableBook] = [],
        cooccurrence: [H24CooccurrenceCandidate] = [],
        awardsCatalog: [H25AwardItem]? = nil,
        weights: [H02SeedRecommendationWeight] = [],
        maxCount: Int = 5
    ) -> [RecommendationCandidate] {
        guard maxCount > 0 else { return [] }
        let axes = orderedAxes(from: weights)
        let filteredCooc = filterCooccurrenceCandidates(cooccurrence)

        var seenKeys = Set<String>()
        for b in shelfBooks {
            seenKeys.insert(dedupKey(for: b))
        }

        // Reference books: finished first (newest first), then reading, then tsundoku
        let baseBooks = shelfBooks.sorted { lhs, rhs in
            let lRank = statusReferenceRank(lhs.status)
            let rRank = statusReferenceRank(rhs.status)
            if lRank != rRank {
                return lRank < rRank
            }
            return (lhs.finishedAt ?? lhs.addedAt ?? "") > (rhs.finishedAt ?? rhs.addedAt ?? "")
        }

        let EffectiveBaseBooks = baseBooks.isEmpty
            ? [RecommendableBook(title: "コンビニ人間", author: "村田沙耶香", award: "芥川龍之介賞")]
            : baseBooks

        var queuesByAxis = buildUnownedCandidatesByAxis(
            baseBooks: EffectiveBaseBooks,
            externalPool: externalPool,
            filteredCooccurrence: filteredCooc,
            awardsCatalog: awardsCatalog ?? AwardsCatalog.allBundledAwards(),
            seenKeys: seenKeys
        )

        var results: [RecommendationCandidate] = []

        // First pass: round-robin (1 from each axis in priority order) so multiple axes appear when available (AC-146)
        for axis in axes {
            guard results.count < maxCount else { break }
            var queue = queuesByAxis[axis, default: []]
            while !queue.isEmpty {
                let first = queue.removeFirst()
                let key = dedupKey(title: first.title, author: first.author, isbn13: first.isbn13)
                if !seenKeys.contains(key) {
                    seenKeys.insert(key)
                    results.append(first)
                    break
                }
            }
            queuesByAxis[axis] = queue
        }

        // Second pass: fill remaining slots in axis priority order
        for axis in axes {
            guard results.count < maxCount else { break }
            let queue = queuesByAxis[axis, default: []]
            for cand in queue {
                guard results.count < maxCount else { break }
                let key = dedupKey(title: cand.title, author: cand.author, isbn13: cand.isbn13)
                if !seenKeys.contains(key) {
                    seenKeys.insert(key)
                    results.append(cand)
                }
            }
        }

        return results
    }

    /// Generates up to 3 candidates from `.tsundoku` shelf books for S-1 when there is no current reading book (AC-145).
    public nonisolated static func noCurrentCandidates(
        shelfBooks: [RecommendableBook],
        weights: [H02SeedRecommendationWeight] = [],
        maxCount: Int = 3
    ) -> [RecommendationCandidate] {
        guard maxCount > 0 else { return [] }
        let tsundokuBooks = shelfBooks
            .filter { $0.status == .tsundoku }
            .sorted { ($0.addedAt ?? "") > ($1.addedAt ?? "") }

        guard !tsundokuBooks.isEmpty else { return [] }

        let axes = orderedAxes(from: weights)
        let referenceBooks = shelfBooks
            .filter { $0.status == .finished || $0.status == .paused }
            .sorted { ($0.finishedAt ?? $0.addedAt ?? "") > ($1.finishedAt ?? $1.addedAt ?? "") }

        var results: [RecommendationCandidate] = []
        var usedKeys = Set<String>()

        if !referenceBooks.isEmpty {
            for axis in axes {
                for tsundoku in tsundokuBooks {
                    guard results.count < maxCount else { break }
                    let key = dedupKey(for: tsundoku)
                    guard !usedKeys.contains(key) else { continue }
                    for ref in referenceBooks {
                        if let reason = matchAxis(axis, candidate: tsundoku, baseBook: ref, isOwnedTsundoku: true) {
                            usedKeys.insert(key)
                            results.append(makeCandidate(from: tsundoku, axis: axis, reason: reason, isOwnedTsundoku: true))
                            break
                        }
                    }
                }
            }
        }

        for tsundoku in tsundokuBooks {
            guard results.count < maxCount else { break }
            let key = dedupKey(for: tsundoku)
            guard !usedKeys.contains(key) else { continue }
            usedKeys.insert(key)
            results.append(makeCandidate(from: tsundoku, axis: .sameAuthor, reason: "積読から", isOwnedTsundoku: true))
        }

        return results
    }

    // MARK: - Private Helpers

    private nonisolated static func statusReferenceRank(_ status: BookStatus?) -> Int {
        switch status {
        case .finished: return 0
        case .current, .reading: return 1
        case .tsundoku: return 2
        case .paused: return 3
        case nil: return 4
        }
    }

    private nonisolated static func dedupKey(for book: RecommendableBook) -> String {
        dedupKey(title: book.title, author: book.author, isbn13: book.isbn13)
    }

    private nonisolated static func dedupKey(title: String, author: String?, isbn13: String?) -> String {
        let normTitle = AwardsCatalog.normalizeTitle(title)
        let normAuthor = AwardsCatalog.normalizeAuthor(author)
        if !normTitle.isEmpty {
            return "\(normTitle)|\(normAuthor)"
        }
        return isbn13 ?? title
    }

    private nonisolated static func makeCandidate(
        from book: RecommendableBook,
        axis: RecommendationAxis,
        reason: String,
        isOwnedTsundoku: Bool
    ) -> RecommendationCandidate {
        let candidateID = book.id?.uuidString ?? book.isbn13 ?? dedupKey(for: book)
        return RecommendationCandidate(
            id: candidateID,
            bookId: book.id,
            isbn13: book.isbn13,
            ndc: book.ndc,
            title: book.title,
            author: book.author,
            publisher: book.publisher,
            label: book.label,
            publishedYear: book.publishedYear,
            award: book.award,
            seriesTitle: book.seriesTitle,
            volumeNumber: book.volumeNumber,
            axis: axis,
            reason: reason,
            isOwnedTsundoku: isOwnedTsundoku
        )
    }

    private nonisolated static func buildUnownedCandidatesByAxis(
        baseBooks: [RecommendableBook],
        externalPool: [RecommendableBook],
        filteredCooccurrence: [H24CooccurrenceCandidate],
        awardsCatalog: [H25AwardItem],
        seenKeys: Set<String>
    ) -> [RecommendationAxis: [RecommendationCandidate]] {
        var result: [RecommendationAxis: [RecommendationCandidate]] = [:]
        let primaryBase = baseBooks.first

        // 1. .readers from filtered cooccurrence
        var readersList: [RecommendationCandidate] = []
        for item in filteredCooccurrence {
            let key = dedupKey(title: item.title, author: item.author, isbn13: item.isbn13)
            guard !seenKeys.contains(key) else { continue }
            let extMatch = externalPool.first { $0.isbn13 == item.isbn13 }
            let reason = formatReason(axis: .readers, baseBookTitle: primaryBase?.title)
            readersList.append(
                RecommendationCandidate(
                    id: item.isbn13,
                    bookId: nil,
                    isbn13: item.isbn13,
                    ndc: item.ndc,
                    title: item.title,
                    author: item.author,
                    publisher: item.publisher ?? extMatch?.publisher,
                    label: item.label ?? extMatch?.label,
                    publishedYear: extMatch?.publishedYear,
                    award: AwardsCatalog.matchAwardName(title: item.title, author: item.author, catalog: awardsCatalog),
                    seriesTitle: extMatch?.seriesTitle,
                    volumeNumber: extMatch?.volumeNumber,
                    axis: .readers,
                    reason: reason,
                    isOwnedTsundoku: false
                )
            )
        }
        result[.readers] = readersList

        // 2. .nextVolume, .sameAuthor, .sameLabel, .sameAward from externalPool
        var nextVolList: [RecommendationCandidate] = []
        var sameAuthorList: [RecommendationCandidate] = []
        var sameLabelList: [RecommendationCandidate] = []
        var sameAwardList: [RecommendationCandidate] = []

        for ext in externalPool {
            let key = dedupKey(for: ext)
            guard !seenKeys.contains(key) else { continue }
            for base in baseBooks {
                if let r = matchAxis(.nextVolume, candidate: ext, baseBook: base, awardsCatalog: awardsCatalog) {
                    nextVolList.append(makeCandidate(from: ext, axis: .nextVolume, reason: r, isOwnedTsundoku: false))
                    break
                }
            }
            for base in baseBooks {
                if let r = matchAxis(.sameAuthor, candidate: ext, baseBook: base, awardsCatalog: awardsCatalog) {
                    sameAuthorList.append(makeCandidate(from: ext, axis: .sameAuthor, reason: r, isOwnedTsundoku: false))
                    break
                }
            }
            for base in baseBooks {
                if let r = matchAxis(.sameLabel, candidate: ext, baseBook: base, awardsCatalog: awardsCatalog) {
                    sameLabelList.append(makeCandidate(from: ext, axis: .sameLabel, reason: r, isOwnedTsundoku: false))
                    break
                }
            }
            for base in baseBooks {
                if let r = matchAxis(.sameAward, candidate: ext, baseBook: base, awardsCatalog: awardsCatalog) {
                    sameAwardList.append(makeCandidate(from: ext, axis: .sameAward, reason: r, isOwnedTsundoku: false))
                    break
                }
            }
        }

        // Also populate .sameAuthor and .sameAward from awardsCatalog
        for awardItem in awardsCatalog {
            let key = dedupKey(title: awardItem.title, author: awardItem.author, isbn13: nil)
            guard !seenKeys.contains(key) else { continue }
            let bookRep = RecommendableBook(
                title: awardItem.title,
                author: awardItem.author,
                award: awardItem.award,
                awardSessionOrYear: awardItem.sessionOrYear
            )
            for base in baseBooks {
                if let r = matchAxis(.sameAuthor, candidate: bookRep, baseBook: base, awardsCatalog: awardsCatalog) {
                    sameAuthorList.append(
                        RecommendationCandidate(
                            id: awardItem.id ?? "award-\(awardItem.award)-\(awardItem.order)",
                            title: awardItem.title,
                            author: awardItem.author,
                            award: awardItem.award,
                            axis: .sameAuthor,
                            reason: r,
                            isOwnedTsundoku: false
                        )
                    )
                    break
                }
            }
            for base in baseBooks {
                if let r = matchAxis(.sameAward, candidate: bookRep, baseBook: base, awardsCatalog: awardsCatalog) {
                    sameAwardList.append(
                        RecommendationCandidate(
                            id: awardItem.id ?? "award-\(awardItem.award)-\(awardItem.order)",
                            title: awardItem.title,
                            author: awardItem.author,
                            award: awardItem.award,
                            axis: .sameAward,
                            reason: r,
                            isOwnedTsundoku: false
                        )
                    )
                    break
                }
            }
        }

        result[.nextVolume] = nextVolList
        result[.sameAuthor] = sameAuthorList
        result[.sameAward] = sameAwardList
        result[.sameLabel] = sameLabelList
        return result
    }
}
