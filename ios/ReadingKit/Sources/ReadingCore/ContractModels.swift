import Foundation

// MARK: - WidgetSnapshot (contracts/widget-snapshot.schema.json)

public enum WidgetSnapshotValidationError: Error, Sendable, Equatable {
    case malformedJSON(String)
    case unsupportedVersion(Int)
    case privacyInvariantViolation
    case titlePendingInvariantViolation
    case fieldConstraintViolation(String)
}

public struct WidgetSnapshotBook: Codable, Sendable, Equatable {
    public var id: UUID
    public var title: String?
    public var author: String?
    public var isTitlePending: Bool
    public var progressUnit: ProgressUnit
    public var progressDisplay: String?
    public var latestLine: String?
    public var latestLineId: UUID?

    public nonisolated init(
        id: UUID,
        title: String?,
        author: String?,
        isTitlePending: Bool,
        progressUnit: ProgressUnit,
        progressDisplay: String?,
        latestLine: String?,
        latestLineId: UUID?
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.isTitlePending = isTitlePending
        self.progressUnit = progressUnit
        self.progressDisplay = progressDisplay
        self.latestLine = latestLine
        self.latestLineId = latestLineId
    }
}

public struct WidgetSnapshot: Codable, Sendable, Equatable {
    public var version: Int
    public var updatedAt: String
    public var appearanceID: AppearanceID
    public var hideOnWidgets: Bool
    public var currentBook: WidgetSnapshotBook?

    public nonisolated init(
        version: Int = 1,
        updatedAt: String,
        appearanceID: AppearanceID = .default,
        hideOnWidgets: Bool = false,
        currentBook: WidgetSnapshotBook? = nil
    ) {
        self.version = version
        self.updatedAt = updatedAt
        self.appearanceID = appearanceID
        self.hideOnWidgets = hideOnWidgets
        self.currentBook = currentBook
    }

    enum CodingKeys: String, CodingKey {
        case version
        case updatedAt
        case appearanceID
        case hideOnWidgets
        case currentBook
    }

    public nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(Int.self, forKey: .version)
        self.updatedAt = try container.decode(String.self, forKey: .updatedAt)
        let rawAppearance = try container.decode(String.self, forKey: .appearanceID)
        // Unknown appearanceID values fall back to .default in the widget renderer per contract
        self.appearanceID = AppearanceID.resolve(rawAppearance)
        self.hideOnWidgets = try container.decode(Bool.self, forKey: .hideOnWidgets)
        self.currentBook = try container.decodeIfPresent(WidgetSnapshotBook.self, forKey: .currentBook)
    }

    public nonisolated func validate() throws(WidgetSnapshotValidationError) {
        guard version == 1 else {
            throw .unsupportedVersion(version)
        }
        guard !updatedAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw .fieldConstraintViolation("updatedAt must not be empty")
        }
        guard let book = currentBook else {
            return
        }
        // Privacy invariant: when hideOnWidgets is true, latestLine and latestLineId MUST be nil
        if hideOnWidgets && (book.latestLine != nil || book.latestLineId != nil) {
            throw .privacyInvariantViolation
        }
        if book.latestLine == nil && book.latestLineId != nil {
            throw .privacyInvariantViolation
        }
        // Title pending invariant
        if book.isTitlePending {
            if book.title != nil || book.author != nil {
                throw .titlePendingInvariantViolation
            }
        } else {
            guard let title = book.title, !title.isEmpty else {
                throw .titlePendingInvariantViolation
            }
            if title.count > 100 {
                throw .fieldConstraintViolation("title exceeds 100 characters")
            }
        }
        if let author = book.author, author.count > 100 {
            throw .fieldConstraintViolation("author exceeds 100 characters")
        }
        if let progressDisplay = book.progressDisplay, progressDisplay.count > 20 {
            throw .fieldConstraintViolation("progressDisplay exceeds 20 characters")
        }
        if let latestLine = book.latestLine {
            if latestLine.isEmpty || latestLine.count > 25 {
                throw .fieldConstraintViolation("latestLine must be 1...25 characters")
            }
        }
    }

    public nonisolated static func decodeAndValidate(from data: Data) throws(WidgetSnapshotValidationError) -> WidgetSnapshot {
        // First inspect raw version if present so version != 1 reports .unsupportedVersion
        if let rawObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let rawVersion = rawObject["version"] as? Int,
           rawVersion != 1 {
            throw .unsupportedVersion(rawVersion)
        }
        let decoder = JSONDecoder()
        let snapshot: WidgetSnapshot
        do {
            snapshot = try decoder.decode(WidgetSnapshot.self, from: data)
        } catch {
            throw .malformedJSON(error.localizedDescription)
        }
        try snapshot.validate()
        return snapshot
    }

    /// Safe decoder for the widget extension: treats version != 1 or malformed JSON as "no current book"
    /// and renders the empty state without crashing.
    public nonisolated static func decodeForWidgetRenderer(from data: Data, fallbackNowISO8601: String = "1970-01-01T00:00:00Z") -> WidgetSnapshot {
        if let valid = try? decodeAndValidate(from: data) {
            return valid
        }
        return WidgetSnapshot(
            version: 1,
            updatedAt: fallbackNowISO8601,
            appearanceID: .default,
            hideOnWidgets: false,
            currentBook: nil
        )
    }
}

// MARK: - H02 Seed Payload (contracts/hooks/h02-seed.schema.json)

public struct H02SeedBook: Codable, Sendable, Equatable {
    public var id: UUID
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
    public var status: BookStatus
    public var progressUnit: ProgressUnit
    public var currentPage: Int?
    public var currentLocation: Int?
    public var currentPercent: Double?
    public var entrySource: EntrySource
    public var isTitlePending: Bool
    public var addedAt: String?
    public var startedReadingAt: String?
    public var finishedAt: String?
    public var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, isbn13, ndc, title, author, publisher, label, publishedYear
        case award, seriesTitle, volumeNumber, status, progressUnit
        case currentPage, currentLocation, currentPercent
        case entrySource, isTitlePending
        case addedAt, startedReadingAt, finishedAt, updatedAt
    }

    public nonisolated init(
        id: UUID,
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
        status: BookStatus,
        progressUnit: ProgressUnit = .page,
        currentPage: Int? = nil,
        currentLocation: Int? = nil,
        currentPercent: Double? = nil,
        entrySource: EntrySource = .manual,
        isTitlePending: Bool = false,
        addedAt: String? = nil,
        startedReadingAt: String? = nil,
        finishedAt: String? = nil,
        updatedAt: String? = nil
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
        self.seriesTitle = seriesTitle
        self.volumeNumber = volumeNumber
        self.status = status
        self.progressUnit = progressUnit
        self.currentPage = currentPage
        self.currentLocation = currentLocation
        self.currentPercent = currentPercent
        self.entrySource = entrySource
        self.isTitlePending = isTitlePending
        self.addedAt = addedAt
        self.startedReadingAt = startedReadingAt
        self.finishedAt = finishedAt
        self.updatedAt = updatedAt
    }

    public nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.isbn13 = try c.decodeIfPresent(String.self, forKey: .isbn13)
        self.ndc = try c.decodeIfPresent(String.self, forKey: .ndc)
        self.title = try c.decode(String.self, forKey: .title)
        self.author = try c.decodeIfPresent(String.self, forKey: .author)
        self.publisher = try c.decodeIfPresent(String.self, forKey: .publisher)
        self.label = try c.decodeIfPresent(String.self, forKey: .label)
        self.publishedYear = try c.decodeIfPresent(Int.self, forKey: .publishedYear)
        self.award = try c.decodeIfPresent(String.self, forKey: .award)
        self.seriesTitle = try c.decodeIfPresent(String.self, forKey: .seriesTitle)
        self.volumeNumber = try c.decodeIfPresent(Int.self, forKey: .volumeNumber)
        self.status = try c.decode(BookStatus.self, forKey: .status)
        self.progressUnit = try c.decodeIfPresent(ProgressUnit.self, forKey: .progressUnit) ?? .page
        self.currentPage = try c.decodeIfPresent(Int.self, forKey: .currentPage)
        self.currentLocation = try c.decodeIfPresent(Int.self, forKey: .currentLocation)
        self.currentPercent = try c.decodeIfPresent(Double.self, forKey: .currentPercent)
        self.entrySource = try c.decodeIfPresent(EntrySource.self, forKey: .entrySource) ?? .manual
        self.isTitlePending = try c.decodeIfPresent(Bool.self, forKey: .isTitlePending) ?? false
        self.addedAt = try c.decodeIfPresent(String.self, forKey: .addedAt)
        self.startedReadingAt = try c.decodeIfPresent(String.self, forKey: .startedReadingAt)
        self.finishedAt = try c.decodeIfPresent(String.self, forKey: .finishedAt)
        self.updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}

public struct H02SeedReadingRecord: Codable, Sendable, Equatable {
    public var id: UUID
    public var bookId: UUID
    public var startedAt: String
    public var endedAt: String
    public var durationSeconds: Int
    public var timeZoneID: String
    public var nightDate: String?
    public var startedBy: StartedBy

    enum CodingKeys: String, CodingKey {
        case id, bookId, startedAt, endedAt, durationSeconds, timeZoneID, nightDate, startedBy
    }

    public nonisolated init(
        id: UUID,
        bookId: UUID,
        startedAt: String,
        endedAt: String,
        durationSeconds: Int,
        timeZoneID: String = "Asia/Tokyo",
        nightDate: String? = nil,
        startedBy: StartedBy = .tap
    ) {
        self.id = id
        self.bookId = bookId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.timeZoneID = timeZoneID
        self.nightDate = nightDate
        self.startedBy = startedBy
    }

    public nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.bookId = try c.decode(UUID.self, forKey: .bookId)
        self.startedAt = try c.decode(String.self, forKey: .startedAt)
        self.endedAt = try c.decode(String.self, forKey: .endedAt)
        self.durationSeconds = try c.decode(Int.self, forKey: .durationSeconds)
        self.timeZoneID = try c.decodeIfPresent(String.self, forKey: .timeZoneID) ?? "Asia/Tokyo"
        self.nightDate = try c.decodeIfPresent(String.self, forKey: .nightDate)
        self.startedBy = try c.decodeIfPresent(StartedBy.self, forKey: .startedBy) ?? .tap
    }
}

public struct H02SeedBookMark: Codable, Sendable, Equatable {
    public var id: UUID
    public var bookId: UUID
    public var progressUnit: ProgressUnit
    public var page: Int?
    public var location: Int?
    public var percent: Double?
    public var createdAt: String

    public nonisolated init(
        id: UUID,
        bookId: UUID,
        progressUnit: ProgressUnit,
        page: Int? = nil,
        location: Int? = nil,
        percent: Double? = nil,
        createdAt: String
    ) {
        self.id = id
        self.bookId = bookId
        self.progressUnit = progressUnit
        self.page = page
        self.location = location
        self.percent = percent
        self.createdAt = createdAt
    }
}

public struct H02SeedLineMark: Codable, Sendable, Equatable {
    public var id: UUID
    public var bookId: UUID
    public var text: String
    public var page: Int?
    public var progressUnit: ProgressUnit?
    public var location: Int?
    public var percent: Double?
    public var isHiddenOnWidgets: Bool
    public var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, bookId, text, page, progressUnit, location, percent, isHiddenOnWidgets, createdAt
    }

    public nonisolated init(
        id: UUID,
        bookId: UUID,
        text: String,
        page: Int? = nil,
        progressUnit: ProgressUnit? = nil,
        location: Int? = nil,
        percent: Double? = nil,
        isHiddenOnWidgets: Bool = false,
        createdAt: String
    ) {
        self.id = id
        self.bookId = bookId
        self.text = text
        self.page = page
        self.progressUnit = progressUnit
        self.location = location
        self.percent = percent
        self.isHiddenOnWidgets = isHiddenOnWidgets
        self.createdAt = createdAt
    }

    public nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.bookId = try c.decode(UUID.self, forKey: .bookId)
        self.text = try c.decode(String.self, forKey: .text)
        self.page = try c.decodeIfPresent(Int.self, forKey: .page)
        self.progressUnit = try c.decodeIfPresent(ProgressUnit.self, forKey: .progressUnit)
        self.location = try c.decodeIfPresent(Int.self, forKey: .location)
        self.percent = try c.decodeIfPresent(Double.self, forKey: .percent)
        self.isHiddenOnWidgets = try c.decodeIfPresent(Bool.self, forKey: .isHiddenOnWidgets) ?? false
        self.createdAt = try c.decode(String.self, forKey: .createdAt)
    }
}

public struct H02SeedRecommendationWeight: Codable, Sendable, Equatable {
    public var axis: RecommendationAxis
    public var chosenCount: Int
    public var skippedCount: Int

    public nonisolated init(axis: RecommendationAxis, chosenCount: Int, skippedCount: Int) {
        self.axis = axis
        self.chosenCount = chosenCount
        self.skippedCount = skippedCount
    }
}

public struct H02SeedCooccurrenceItem: Codable, Sendable, Equatable {
    public var sourceISBN13: String
    public var candidateISBN13: String
    public var title: String
    public var author: String?
    public var publisher: String?
    public var label: String?
    public var ndc: String
    public var count: Int
    public var cachedAt: String?

    public nonisolated init(
        sourceISBN13: String,
        candidateISBN13: String,
        title: String,
        author: String? = nil,
        publisher: String? = nil,
        label: String? = nil,
        ndc: String,
        count: Int,
        cachedAt: String? = nil
    ) {
        self.sourceISBN13 = sourceISBN13
        self.candidateISBN13 = candidateISBN13
        self.title = title
        self.author = author
        self.publisher = publisher
        self.label = label
        self.ndc = ndc
        self.count = count
        self.cachedAt = cachedAt
    }
}

public struct H02SeedSettings: Codable, Sendable, Equatable {
    public var appearanceID: AppearanceID?
    public var hideLineOnWidgets: Bool?
    public var hasSeenOnboarding: Bool?
    public var hasShownWidgetGuideBanner: Bool?
    public var defaultProgressUnit: ProgressUnit?

    public nonisolated init(
        appearanceID: AppearanceID? = nil,
        hideLineOnWidgets: Bool? = nil,
        hasSeenOnboarding: Bool? = nil,
        hasShownWidgetGuideBanner: Bool? = nil,
        defaultProgressUnit: ProgressUnit? = nil
    ) {
        self.appearanceID = appearanceID
        self.hideLineOnWidgets = hideLineOnWidgets
        self.hasSeenOnboarding = hasSeenOnboarding
        self.hasShownWidgetGuideBanner = hasShownWidgetGuideBanner
        self.defaultProgressUnit = defaultProgressUnit
    }
}

public struct H02SeedSession: Codable, Sendable, Equatable {
    public var state: SessionState
    public var bookId: UUID?
    public var startedAt: String?
    public var elapsedSeconds: Int?
    public var startedBy: StartedBy?
    public var pendingPromptSessionId: UUID?

    public nonisolated init(
        state: SessionState,
        bookId: UUID? = nil,
        startedAt: String? = nil,
        elapsedSeconds: Int? = nil,
        startedBy: StartedBy? = nil,
        pendingPromptSessionId: UUID? = nil
    ) {
        self.state = state
        self.bookId = bookId
        self.startedAt = startedAt
        self.elapsedSeconds = elapsedSeconds
        self.startedBy = startedBy
        self.pendingPromptSessionId = pendingPromptSessionId
    }
}

public struct H02SeedPayload: Codable, Sendable, Equatable {
    public var books: [H02SeedBook]?
    public var readingRecords: [H02SeedReadingRecord]?
    public var bookMarks: [H02SeedBookMark]?
    public var lineMarks: [H02SeedLineMark]?
    public var recommendationWeights: [H02SeedRecommendationWeight]?
    public var cooccurrenceCache: [H02SeedCooccurrenceItem]?
    public var settings: H02SeedSettings?
    public var session: H02SeedSession?

    public nonisolated init(
        books: [H02SeedBook]? = nil,
        readingRecords: [H02SeedReadingRecord]? = nil,
        bookMarks: [H02SeedBookMark]? = nil,
        lineMarks: [H02SeedLineMark]? = nil,
        recommendationWeights: [H02SeedRecommendationWeight]? = nil,
        cooccurrenceCache: [H02SeedCooccurrenceItem]? = nil,
        settings: H02SeedSettings? = nil,
        session: H02SeedSession? = nil
    ) {
        self.books = books
        self.readingRecords = readingRecords
        self.bookMarks = bookMarks
        self.lineMarks = lineMarks
        self.recommendationWeights = recommendationWeights
        self.cooccurrenceCache = cooccurrenceCache
        self.settings = settings
        self.session = session
    }
}

// MARK: - H13 Store Readout (contracts/hooks/h13-store.schema.json)

public struct H13Book: Codable, Sendable, Equatable {
    public var id: UUID
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
    public var status: BookStatus
    public var progressUnit: ProgressUnit
    public var currentPage: Int?
    public var currentLocation: Int?
    public var currentPercent: Double?
    public var entrySource: EntrySource
    public var isTitlePending: Bool
    public var addedAt: String
    public var startedReadingAt: String?
    public var finishedAt: String?
    public var updatedAt: String

    public nonisolated init(
        id: UUID,
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
        status: BookStatus,
        progressUnit: ProgressUnit,
        currentPage: Int? = nil,
        currentLocation: Int? = nil,
        currentPercent: Double? = nil,
        entrySource: EntrySource,
        isTitlePending: Bool,
        addedAt: String,
        startedReadingAt: String? = nil,
        finishedAt: String? = nil,
        updatedAt: String
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
        self.seriesTitle = seriesTitle
        self.volumeNumber = volumeNumber
        self.status = status
        self.progressUnit = progressUnit
        self.currentPage = currentPage
        self.currentLocation = currentLocation
        self.currentPercent = currentPercent
        self.entrySource = entrySource
        self.isTitlePending = isTitlePending
        self.addedAt = addedAt
        self.startedReadingAt = startedReadingAt
        self.finishedAt = finishedAt
        self.updatedAt = updatedAt
    }
}

public struct H13ReadingRecord: Codable, Sendable, Equatable {
    public var id: UUID
    public var bookId: UUID
    public var startedAt: String
    public var endedAt: String
    public var durationSeconds: Int
    public var timeZoneID: String
    public var nightDate: String
    public var startedBy: StartedBy

    public nonisolated init(
        id: UUID,
        bookId: UUID,
        startedAt: String,
        endedAt: String,
        durationSeconds: Int,
        timeZoneID: String,
        nightDate: String,
        startedBy: StartedBy
    ) {
        self.id = id
        self.bookId = bookId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.timeZoneID = timeZoneID
        self.nightDate = nightDate
        self.startedBy = startedBy
    }
}

public struct H13BookMark: Codable, Sendable, Equatable {
    public var id: UUID
    public var bookId: UUID
    public var progressUnit: ProgressUnit
    public var page: Int?
    public var location: Int?
    public var percent: Double?
    public var createdAt: String

    public nonisolated init(
        id: UUID,
        bookId: UUID,
        progressUnit: ProgressUnit,
        page: Int? = nil,
        location: Int? = nil,
        percent: Double? = nil,
        createdAt: String
    ) {
        self.id = id
        self.bookId = bookId
        self.progressUnit = progressUnit
        self.page = page
        self.location = location
        self.percent = percent
        self.createdAt = createdAt
    }
}

public struct H13LineMark: Codable, Sendable, Equatable {
    public var id: UUID
    public var bookId: UUID
    public var text: String
    public var page: Int?
    public var progressUnit: ProgressUnit?
    public var location: Int?
    public var percent: Double?
    public var isHiddenOnWidgets: Bool
    public var createdAt: String

    public nonisolated init(
        id: UUID,
        bookId: UUID,
        text: String,
        page: Int? = nil,
        progressUnit: ProgressUnit? = nil,
        location: Int? = nil,
        percent: Double? = nil,
        isHiddenOnWidgets: Bool = false,
        createdAt: String
    ) {
        self.id = id
        self.bookId = bookId
        self.text = text
        self.page = page
        self.progressUnit = progressUnit
        self.location = location
        self.percent = percent
        self.isHiddenOnWidgets = isHiddenOnWidgets
        self.createdAt = createdAt
    }
}

public struct H13RecommendationWeight: Codable, Sendable, Equatable {
    public var axis: RecommendationAxis
    public var chosenCount: Int
    public var skippedCount: Int
    public var score: Int

    public nonisolated init(
        axis: RecommendationAxis,
        chosenCount: Int,
        skippedCount: Int,
        score: Int? = nil
    ) {
        self.axis = axis
        self.chosenCount = chosenCount
        self.skippedCount = skippedCount
        self.score = score ?? (chosenCount * 2 - skippedCount)
    }
}

public struct H13CooccurrenceCacheItem: Codable, Sendable, Equatable {
    public var sourceISBN13: String
    public var candidateISBN13: String
    public var title: String
    public var author: String?
    public var publisher: String?
    public var label: String?
    public var ndc: String
    public var count: Int
    public var cachedAt: String

    public nonisolated init(
        sourceISBN13: String,
        candidateISBN13: String,
        title: String,
        author: String? = nil,
        publisher: String? = nil,
        label: String? = nil,
        ndc: String,
        count: Int,
        cachedAt: String
    ) {
        self.sourceISBN13 = sourceISBN13
        self.candidateISBN13 = candidateISBN13
        self.title = title
        self.author = author
        self.publisher = publisher
        self.label = label
        self.ndc = ndc
        self.count = count
        self.cachedAt = cachedAt
    }
}

public struct H13Settings: Codable, Sendable, Equatable {
    public var appearanceID: AppearanceID
    public var hideLineOnWidgets: Bool
    public var hasSeenOnboarding: Bool
    public var hasShownWidgetGuideBanner: Bool
    public var defaultProgressUnit: ProgressUnit

    public nonisolated init(
        appearanceID: AppearanceID = .default,
        hideLineOnWidgets: Bool = false,
        hasSeenOnboarding: Bool = false,
        hasShownWidgetGuideBanner: Bool = false,
        defaultProgressUnit: ProgressUnit = .page
    ) {
        self.appearanceID = appearanceID
        self.hideLineOnWidgets = hideLineOnWidgets
        self.hasSeenOnboarding = hasSeenOnboarding
        self.hasShownWidgetGuideBanner = hasShownWidgetGuideBanner
        self.defaultProgressUnit = defaultProgressUnit
    }
}

public struct H13StoreReadout: Codable, Sendable, Equatable {
    public var books: [H13Book]
    public var readingRecords: [H13ReadingRecord]
    public var bookMarks: [H13BookMark]
    public var lineMarks: [H13LineMark]
    public var recommendationWeights: [H13RecommendationWeight]
    public var cooccurrenceCache: [H13CooccurrenceCacheItem]?
    public var settings: H13Settings
    public var outboundNetworkCount: Int?

    public nonisolated init(
        books: [H13Book] = [],
        readingRecords: [H13ReadingRecord] = [],
        bookMarks: [H13BookMark] = [],
        lineMarks: [H13LineMark] = [],
        recommendationWeights: [H13RecommendationWeight] = [],
        cooccurrenceCache: [H13CooccurrenceCacheItem]? = [],
        settings: H13Settings = H13Settings(),
        outboundNetworkCount: Int? = 0
    ) {
        self.books = books
        self.readingRecords = readingRecords
        self.bookMarks = bookMarks
        self.lineMarks = lineMarks
        self.recommendationWeights = recommendationWeights
        self.cooccurrenceCache = cooccurrenceCache
        self.settings = settings
        self.outboundNetworkCount = outboundNetworkCount
    }
}

// MARK: - H17 State Readout (contracts/hooks/h17-state.schema.json)

public struct H17StateReadout: Codable, Sendable, Equatable {
    public var state: SessionState
    public var startedAt: String?
    public var elapsedSeconds: Int
    public var bookId: UUID?
    public var startedBy: StartedBy?
    public var liveActivityActive: Bool
    public var pendingPromptSessionId: UUID?

    public nonisolated init(
        state: SessionState,
        startedAt: String? = nil,
        elapsedSeconds: Int = 0,
        bookId: UUID? = nil,
        startedBy: StartedBy? = nil,
        liveActivityActive: Bool = false,
        pendingPromptSessionId: UUID? = nil
    ) {
        self.state = state
        self.startedAt = startedAt
        self.elapsedSeconds = elapsedSeconds
        self.bookId = bookId
        self.startedBy = startedBy
        self.liveActivityActive = liveActivityActive
        self.pendingPromptSessionId = pendingPromptSessionId
    }

    public nonisolated var compactSummary: String {
        "state=\(state.rawValue),elapsed=\(elapsedSeconds),liveActivity=\(liveActivityActive)"
    }
}

// MARK: - H20 NDL Stub Config (contracts/hooks/h20-ndl-stub.schema.json)

public enum H20StubMode: String, Codable, Sendable, Equatable {
    case fixture
    case empty
    case http500
    case timeout
    case malformed
    case rateLimit429
}

public struct H20BiblioItem: Codable, Sendable, Equatable {
    public var isbn13: String?
    public var title: String
    public var author: String?
    public var rawDcCreator: String?
    public var publisher: String?
    public var label: String?
    public var publishedYear: Int?
    public var ndc: String?
    public var seriesTitle: String?
    public var volumeNumber: Int?

    public nonisolated init(
        isbn13: String? = nil,
        title: String,
        author: String? = nil,
        rawDcCreator: String? = nil,
        publisher: String? = nil,
        label: String? = nil,
        publishedYear: Int? = nil,
        ndc: String? = nil,
        seriesTitle: String? = nil,
        volumeNumber: Int? = nil
    ) {
        self.isbn13 = isbn13
        self.title = title
        self.author = author
        self.rawDcCreator = rawDcCreator
        self.publisher = publisher
        self.label = label
        self.publishedYear = publishedYear
        self.ndc = ndc
        self.seriesTitle = seriesTitle
        self.volumeNumber = volumeNumber
    }
}

public struct H20StubEntry: Codable, Sendable, Equatable {
    public var mode: H20StubMode
    public var delayMs: Int
    public var items: [H20BiblioItem]

    enum CodingKeys: String, CodingKey {
        case mode, delayMs, items
    }

    public nonisolated init(
        mode: H20StubMode = .fixture,
        delayMs: Int = 0,
        items: [H20BiblioItem] = []
    ) {
        self.mode = mode
        self.delayMs = delayMs
        self.items = items
    }

    public nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.mode = try c.decodeIfPresent(H20StubMode.self, forKey: .mode) ?? .fixture
        self.delayMs = try c.decodeIfPresent(Int.self, forKey: .delayMs) ?? 0
        self.items = try c.decodeIfPresent([H20BiblioItem].self, forKey: .items) ?? []
    }
}

public struct H20NDLStubConfig: Codable, Sendable, Equatable {
    public var defaultMode: H20StubMode
    public var defaultDelayMs: Int
    public var isbnResponses: [String: H20StubEntry]
    public var searchResponses: [String: H20StubEntry]

    enum CodingKeys: String, CodingKey {
        case defaultMode, defaultDelayMs, isbnResponses, searchResponses
    }

    public nonisolated init(
        defaultMode: H20StubMode = .empty,
        defaultDelayMs: Int = 0,
        isbnResponses: [String: H20StubEntry] = [:],
        searchResponses: [String: H20StubEntry] = [:]
    ) {
        self.defaultMode = defaultMode
        self.defaultDelayMs = defaultDelayMs
        self.isbnResponses = isbnResponses
        self.searchResponses = searchResponses
    }

    public nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.defaultMode = try c.decodeIfPresent(H20StubMode.self, forKey: .defaultMode) ?? .empty
        self.defaultDelayMs = try c.decodeIfPresent(Int.self, forKey: .defaultDelayMs) ?? 0
        self.isbnResponses = try c.decodeIfPresent([String: H20StubEntry].self, forKey: .isbnResponses) ?? [:]
        self.searchResponses = try c.decodeIfPresent([String: H20StubEntry].self, forKey: .searchResponses) ?? [:]
    }
}

// MARK: - H22 Widget Readout (contracts/hooks/h22-widget.schema.json)

public enum H22Orientation: String, Codable, Sendable, Equatable {
    case vertical
    case horizontal
    case empty
}

public struct H22GlyphCell: Codable, Sendable, Equatable {
    public var column: Int
    public var row: Int
    public var source: String
    public var display: String
    public var rotation: Int
    public var dx: Double
    public var dy: Double

    public nonisolated init(
        column: Int,
        row: Int,
        source: String,
        display: String,
        rotation: Int,
        dx: Double = 0.0,
        dy: Double = 0.0
    ) {
        self.column = column
        self.row = row
        self.source = source
        self.display = display
        self.rotation = rotation
        self.dx = dx
        self.dy = dy
    }
}

public struct H22WidgetComposition: Codable, Sendable, Equatable {
    public var orientation: H22Orientation
    public var displayedLine: String?
    public var shortened: Bool
    public var columnCount: Int
    public var rowsPerColumn: Int
    public var accessibilityLabel: String
    public var cells: [H22GlyphCell]

    public nonisolated init(
        orientation: H22Orientation,
        displayedLine: String?,
        shortened: Bool,
        columnCount: Int,
        rowsPerColumn: Int,
        accessibilityLabel: String,
        cells: [H22GlyphCell]
    ) {
        self.orientation = orientation
        self.displayedLine = displayedLine
        self.shortened = shortened
        self.columnCount = columnCount
        self.rowsPerColumn = rowsPerColumn
        self.accessibilityLabel = accessibilityLabel
        self.cells = cells
    }
}

public struct H22WidgetReadout: Codable, Sendable, Equatable {
    public var snapshot: WidgetSnapshot
    public var composition: H22WidgetComposition
    public var reloadTimelineCount: Int
    public var lastReloadAt: String?

    public nonisolated init(
        snapshot: WidgetSnapshot,
        composition: H22WidgetComposition,
        reloadTimelineCount: Int = 0,
        lastReloadAt: String? = nil
    ) {
        self.snapshot = snapshot
        self.composition = composition
        self.reloadTimelineCount = reloadTimelineCount
        self.lastReloadAt = lastReloadAt
    }
}

// MARK: - H29 Outbound Network Readout (contracts/hooks/h29-outbound.schema.json)

public enum H29RequestPurpose: String, Codable, Sendable, Equatable {
    case ndlIsbn
    case ndlSearch
    case cooccurrence
    case other
}

public struct H29OutboundRequest: Codable, Sendable, Equatable {
    public var url: String
    public var host: String
    public var method: String
    public var purpose: H29RequestPurpose
    public var timestamp: String
    public var hasTrackingIdentifiers: Bool

    public nonisolated init(
        url: String,
        host: String,
        method: String = "GET",
        purpose: H29RequestPurpose,
        timestamp: String,
        hasTrackingIdentifiers: Bool = false
    ) {
        self.url = url
        self.host = host
        self.method = method
        self.purpose = purpose
        self.timestamp = timestamp
        self.hasTrackingIdentifiers = hasTrackingIdentifiers
    }
}

public struct H29OutboundReadout: Codable, Sendable, Equatable {
    public var totalCount: Int
    public var requests: [H29OutboundRequest]

    public nonisolated init(totalCount: Int = 0, requests: [H29OutboundRequest] = []) {
        self.totalCount = totalCount
        self.requests = requests
    }
}

// MARK: - Hook Config Envelope (contracts/hooks/hook-config.schema.json)

public enum H19BarcodeSymbology: String, Codable, Sendable, Equatable {
    case ean13 = "EAN-13"
    case ean13WithSupplemental = "EAN-13+192"
    case nonBook = "NON-BOOK"
}

public struct H19BarcodeInjection: Codable, Sendable, Equatable {
    public var isbn13: String?
    public var supplementalCode: String?
    public var symbology: H19BarcodeSymbology?
    public var delayMs: Int?

    public nonisolated init(
        isbn13: String? = nil,
        supplementalCode: String? = nil,
        symbology: H19BarcodeSymbology? = nil,
        delayMs: Int? = nil
    ) {
        self.isbn13 = isbn13
        self.supplementalCode = supplementalCode
        self.symbology = symbology
        self.delayMs = delayMs
    }
}

public enum H23OCRStubMode: String, Codable, Sendable, Equatable {
    case pageVertical
    case pageHorizontal
    case colophon
    case cover
    case bookshelf
    case empty
}

public struct H23OCRColumn: Codable, Sendable, Equatable {
    public var id: String?
    public var text: String
    public var normalizedX: Double
    public var normalizedY: Double?
    public var isPageNumber: Bool?

    public nonisolated init(
        id: String? = nil,
        text: String,
        normalizedX: Double,
        normalizedY: Double? = nil,
        isPageNumber: Bool? = nil
    ) {
        self.id = id
        self.text = text
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.isPageNumber = isPageNumber
    }
}

public struct H23OCRColophon: Codable, Sendable, Equatable {
    public var rawLines: [String]
    public var extractedTitle: String?
    public var extractedAuthor: String?
    public var extractedPublisher: String?
    public var extractedLabel: String?
    public var extractedPublishedYear: Int?
    public var extractedISBN13: String?

    public nonisolated init(
        rawLines: [String],
        extractedTitle: String? = nil,
        extractedAuthor: String? = nil,
        extractedPublisher: String? = nil,
        extractedLabel: String? = nil,
        extractedPublishedYear: Int? = nil,
        extractedISBN13: String? = nil
    ) {
        self.rawLines = rawLines
        self.extractedTitle = extractedTitle
        self.extractedAuthor = extractedAuthor
        self.extractedPublisher = extractedPublisher
        self.extractedLabel = extractedLabel
        self.extractedPublishedYear = extractedPublishedYear
        self.extractedISBN13 = extractedISBN13
    }
}

public struct H23OCRSpineItem: Codable, Sendable, Equatable {
    public var id: String?
    public var title: String
    public var author: String?
    public var normalizedX: Double?

    public nonisolated init(
        id: String? = nil,
        title: String,
        author: String? = nil,
        normalizedX: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.normalizedX = normalizedX
    }
}

public struct H23OCRStubConfig: Codable, Sendable, Equatable {
    public var mode: H23OCRStubMode?
    public var columns: [H23OCRColumn]?
    public var detectedPageNumber: Int?
    public var colophon: H23OCRColophon?
    public var coverLines: [String]?
    public var spineItems: [H23OCRSpineItem]?

    public nonisolated init(
        mode: H23OCRStubMode? = nil,
        columns: [H23OCRColumn]? = nil,
        detectedPageNumber: Int? = nil,
        colophon: H23OCRColophon? = nil,
        coverLines: [String]? = nil,
        spineItems: [H23OCRSpineItem]? = nil
    ) {
        self.mode = mode
        self.columns = columns
        self.detectedPageNumber = detectedPageNumber
        self.colophon = colophon
        self.coverLines = coverLines
        self.spineItems = spineItems
    }
}

public struct H24CooccurrenceCandidate: Codable, Sendable, Equatable {
    public var isbn13: String
    public var title: String
    public var author: String?
    public var publisher: String?
    public var label: String?
    public var ndc: String
    public var count: Int

    public nonisolated init(
        isbn13: String,
        title: String,
        author: String? = nil,
        publisher: String? = nil,
        label: String? = nil,
        ndc: String,
        count: Int
    ) {
        self.isbn13 = isbn13
        self.title = title
        self.author = author
        self.publisher = publisher
        self.label = label
        self.ndc = ndc
        self.count = count
    }
}

public struct H24CooccurrenceStubConfig: Codable, Sendable, Equatable {
    public var mode: H20StubMode?
    public var responsesByISBN: [String: [H24CooccurrenceCandidate]]?

    public nonisolated init(
        mode: H20StubMode? = nil,
        responsesByISBN: [String: [H24CooccurrenceCandidate]]? = nil
    ) {
        self.mode = mode
        self.responsesByISBN = responsesByISBN
    }
}

public enum AwardName: String, Codable, Sendable, CaseIterable, Equatable {
    case akutagawa = "芥川龍之介賞"
    case naoki = "直木三十五賞"
    case hontai = "本屋大賞"
}

public struct H25AwardItem: Codable, Sendable, Equatable {
    public var id: String?
    public var award: String
    public var sessionOrYear: String
    public var order: Int
    public var title: String
    public var author: String

    enum CodingKeys: String, CodingKey {
        case id
        case award
        case sessionOrYear
        case session
        case order
        case title
        case author
    }

    public nonisolated init(
        id: String? = nil,
        award: String,
        sessionOrYear: String,
        order: Int,
        title: String,
        author: String
    ) {
        self.id = id
        self.award = award
        self.sessionOrYear = sessionOrYear
        self.order = order
        self.title = title
        self.author = author
    }

    public nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(String.self, forKey: .id)
        self.award = try c.decode(String.self, forKey: .award)
        if let s = try c.decodeIfPresent(String.self, forKey: .sessionOrYear) {
            self.sessionOrYear = s
        } else if let s = try c.decodeIfPresent(String.self, forKey: .session) {
            self.sessionOrYear = s
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.sessionOrYear,
                DecodingError.Context(codingPath: c.codingPath, debugDescription: "Missing sessionOrYear")
            )
        }
        self.order = try c.decodeIfPresent(Int.self, forKey: .order) ?? 1
        self.title = try c.decode(String.self, forKey: .title)
        self.author = try c.decode(String.self, forKey: .author)
    }

    public nonisolated func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encode(award, forKey: .award)
        try c.encode(sessionOrYear, forKey: .sessionOrYear)
        try c.encode(order, forKey: .order)
        try c.encode(title, forKey: .title)
        try c.encode(author, forKey: .author)
    }
}

public struct H27StorageFaultConfig: Codable, Sendable, Equatable {
    public var failNextSave: Bool?
    public var corruptSnapshotFile: Bool?
    public var snapshotCorruptPayload: String?
    public var simulateICloudMerge: H02SeedPayload?

    public nonisolated init(
        failNextSave: Bool? = nil,
        corruptSnapshotFile: Bool? = nil,
        snapshotCorruptPayload: String? = nil,
        simulateICloudMerge: H02SeedPayload? = nil
    ) {
        self.failNextSave = failNextSave
        self.corruptSnapshotFile = corruptSnapshotFile
        self.snapshotCorruptPayload = snapshotCorruptPayload
        self.simulateICloudMerge = simulateICloudMerge
    }
}

public enum CameraPermissionState: String, Codable, Sendable, Equatable {
    case authorized
    case denied
    case notDetermined
}

public struct H32PermissionStates: Codable, Sendable, Equatable {
    public var camera: CameraPermissionState?
    public var liveActivitiesEnabled: Bool?
    public var networkOnline: Bool?

    public nonisolated init(
        camera: CameraPermissionState? = nil,
        liveActivitiesEnabled: Bool? = nil,
        networkOnline: Bool? = nil
    ) {
        self.camera = camera
        self.liveActivitiesEnabled = liveActivitiesEnabled
        self.networkOnline = networkOnline
    }
}

public struct UITestHookConfig: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var seed: H02SeedPayload?
    public var nowISO8601: String?
    public var barcodeInjection: H19BarcodeInjection?
    public var ndlStub: H20NDLStubConfig?
    public var ocrStub: H23OCRStubConfig?
    public var cooccurrenceStub: H24CooccurrenceStubConfig?
    public var awardsOverride: [H25AwardItem]?
    public var storageFault: H27StorageFaultConfig?
    public var entryURL: String?
    public var permissionStates: H32PermissionStates?

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case seed
        case nowISO8601
        case barcodeInjection
        case ndlStub
        case ocrStub
        case cooccurrenceStub
        case awardsOverride
        case storageFault
        case entryURL
        case permissionStates
    }

    public nonisolated init(
        schemaVersion: Int = 1,
        seed: H02SeedPayload? = nil,
        nowISO8601: String? = nil,
        barcodeInjection: H19BarcodeInjection? = nil,
        ndlStub: H20NDLStubConfig? = nil,
        ocrStub: H23OCRStubConfig? = nil,
        cooccurrenceStub: H24CooccurrenceStubConfig? = nil,
        awardsOverride: [H25AwardItem]? = nil,
        storageFault: H27StorageFaultConfig? = nil,
        entryURL: String? = nil,
        permissionStates: H32PermissionStates? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.seed = seed
        self.nowISO8601 = nowISO8601
        self.barcodeInjection = barcodeInjection
        self.ndlStub = ndlStub
        self.ocrStub = ocrStub
        self.cooccurrenceStub = cooccurrenceStub
        self.awardsOverride = awardsOverride
        self.storageFault = storageFault
        self.entryURL = entryURL
        self.permissionStates = permissionStates
    }

    public nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        self.seed = try c.decodeIfPresent(H02SeedPayload.self, forKey: .seed)
        self.nowISO8601 = try c.decodeIfPresent(String.self, forKey: .nowISO8601)
        self.barcodeInjection = try c.decodeIfPresent(H19BarcodeInjection.self, forKey: .barcodeInjection)
        self.ndlStub = try c.decodeIfPresent(H20NDLStubConfig.self, forKey: .ndlStub)
        self.ocrStub = try c.decodeIfPresent(H23OCRStubConfig.self, forKey: .ocrStub)
        self.cooccurrenceStub = try c.decodeIfPresent(H24CooccurrenceStubConfig.self, forKey: .cooccurrenceStub)
        self.awardsOverride = try c.decodeIfPresent([H25AwardItem].self, forKey: .awardsOverride)
        self.storageFault = try c.decodeIfPresent(H27StorageFaultConfig.self, forKey: .storageFault)
        self.entryURL = try c.decodeIfPresent(String.self, forKey: .entryURL)
        self.permissionStates = try c.decodeIfPresent(H32PermissionStates.self, forKey: .permissionStates)
    }
}
