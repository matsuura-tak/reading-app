import Foundation
#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

// MARK: - WidgetSnapshot (contracts/widget-snapshot.schema.json、大きな版 1)

/// 写しを読めない理由の元（読む側の決まりの (3)〜(7)）。`WidgetSnapshotReader` が h22 の `unavailableReason` に直す。
public enum WidgetSnapshotValidationError: Error, Sendable, Equatable {
    /// (3) JSON でない、型が違う、必須の項目がない。名無しなのに書名がある（7）もここ（h22 の enum に (7) がないため）。
    case malformedJSON(String)
    /// (4) schemaVersion が 1 でない。前の版の形（`version`/`updatedAt` を持ち `schemaVersion` がない）も `nil` でここ。
    case unsupportedVersion(Int?)
    /// (6) hideOnWidgets が真なのに書名か一行か isTitlePending がある。
    case privacyInvariantViolation
    /// (7) isTitlePending が真なのに title がある。
    case titlePendingInvariantViolation
    /// (5) 値が範囲の外、知らない単位。
    case fieldConstraintViolation(String)
}

/// しおりの進み具合（`$defs/progress`）。
public struct WidgetSnapshotProgress: Codable, Sendable, Equatable {
    public var unit: ProgressUnit
    public var value: Int

    public nonisolated init(unit: ProgressUnit, value: Int) {
        self.unit = unit
        self.value = value
    }

    /// 単位ごとの範囲（page 1〜9999、location 1〜999999、percent 0〜100）。
    public nonisolated static func range(for unit: ProgressUnit) -> ClosedRange<Int> {
        switch unit {
        case .page: return 1...9999
        case .location: return 1...999999
        case .percent: return 0...100
        }
    }

    public nonisolated var isInRange: Bool { Self.range(for: unit).contains(value) }

    /// 本の今の単位の値から作る。今の単位の値がない、または範囲の外なら nil（違う単位の数字を混ぜない）。
    public nonisolated static func make(unit: ProgressUnit, page: Int?, location: Int?, percent: Int?) -> WidgetSnapshotProgress? {
        let value: Int?
        switch unit {
        case .page: value = page
        case .location: value = location
        case .percent: value = percent
        }
        guard let value else { return nil }
        let progress = WidgetSnapshotProgress(unit: unit, value: value)
        return progress.isInRange ? progress : nil
    }

    private enum CodingKeys: String, CodingKey { case unit, value }

    public nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawUnit = try container.decode(String.self, forKey: .unit)
        let value = try container.decode(Int.self, forKey: .value)
        guard let unit = ProgressUnit(rawValue: rawUnit) else {
            // 知らない単位は (5)。
            throw WidgetSnapshotValidationError.fieldConstraintViolation("unknown progress unit")
        }
        self.unit = unit
        self.value = value
    }
}

/// 今の本（`$defs/visibleBook` と `$defs/hiddenBook`）。書くのは契約の項目だけ（ISBN、著者、本の id、日時を書かない。PRD 12）。
public struct WidgetSnapshotBook: Codable, Sendable, Equatable {
    /// 書名。隠す設定のときと名無しの今の本のときは nil（キーを書かない）。
    public var title: String?
    /// 名無しの今の本の印。偽のときはキーを書かない。
    public var isTitlePending: Bool
    /// 続きの一行の全文（縮めない。ウィジェットの25字への縮め方は描くときに行う）。
    public var line: String?
    public var progress: WidgetSnapshotProgress?

    public nonisolated init(
        title: String? = nil,
        isTitlePending: Bool = false,
        line: String? = nil,
        progress: WidgetSnapshotProgress? = nil
    ) {
        self.title = title
        self.isTitlePending = isTitlePending
        self.line = line
        self.progress = progress
    }

    private enum CodingKeys: String, CodingKey { case title, isTitlePending, line, progress }

    public nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        if let pending = try container.decodeIfPresent(Bool.self, forKey: .isTitlePending) {
            // const true。偽を書くのは型の誤り（3）。
            guard pending else {
                throw DecodingError.dataCorruptedError(forKey: .isTitlePending, in: container, debugDescription: "isTitlePending must be true when present")
            }
            self.isTitlePending = true
        } else {
            self.isTitlePending = false
        }
        self.line = try container.decodeIfPresent(String.self, forKey: .line)
        self.progress = try container.decodeIfPresent(WidgetSnapshotProgress.self, forKey: .progress)
    }

    public nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        if isTitlePending { try container.encode(true, forKey: .isTitlePending) }
        try container.encodeIfPresent(line, forKey: .line)
        try container.encodeIfPresent(progress, forKey: .progress)
    }

    public nonisolated var progressUnit: ProgressUnit? { progress?.unit }
}

public struct WidgetSnapshot: Codable, Sendable, Equatable {
    public nonisolated static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var appearanceID: AppearanceID
    public var hideOnWidgets: Bool
    public var currentBook: WidgetSnapshotBook?

    public nonisolated init(
        schemaVersion: Int = WidgetSnapshot.currentSchemaVersion,
        appearanceID: AppearanceID = .default,
        hideOnWidgets: Bool = false,
        currentBook: WidgetSnapshotBook? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.appearanceID = appearanceID
        self.hideOnWidgets = hideOnWidgets
        self.currentBook = currentBook
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case appearanceID
        case hideOnWidgets
        case currentBook
    }

    public nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        // 省いたときと知らない値のときは default で描く（読む側の決まり）。
        let rawAppearance = try container.decodeIfPresent(String.self, forKey: .appearanceID)
        self.appearanceID = AppearanceID.resolve(rawAppearance)
        self.hideOnWidgets = try container.decode(Bool.self, forKey: .hideOnWidgets)
        self.currentBook = try container.decodeIfPresent(WidgetSnapshotBook.self, forKey: .currentBook)
    }

    public nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(appearanceID.rawValue, forKey: .appearanceID)
        try container.encode(hideOnWidgets, forKey: .hideOnWidgets)
        try container.encodeIfPresent(currentBook, forKey: .currentBook)
    }

    /// 字は書記素で数え、前後の空白を除く（読む側の決まりの (5)）。
    nonisolated static func graphemeCount(_ text: String) -> Int {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    /// 読む側の決まりの (4)〜(7)。
    public nonisolated func validate() throws(WidgetSnapshotValidationError) {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw .unsupportedVersion(schemaVersion)
        }
        guard let book = currentBook else { return }
        if hideOnWidgets && (book.title != nil || book.line != nil || book.isTitlePending) {
            throw .privacyInvariantViolation
        }
        if book.isTitlePending && book.title != nil {
            throw .titlePendingInvariantViolation
        }
        if let title = book.title, !(1...100).contains(Self.graphemeCount(title)) {
            throw .fieldConstraintViolation("title must be 1...100 graphemes")
        }
        if let line = book.line, !(1...60).contains(Self.graphemeCount(line)) {
            throw .fieldConstraintViolation("line must be 1...60 graphemes")
        }
        if let progress = book.progress, !progress.isInRange {
            throw .fieldConstraintViolation("progress value out of range for unit")
        }
    }

    public nonisolated static func decodeAndValidate(from data: Data) throws(WidgetSnapshotValidationError) -> WidgetSnapshot {
        // 型を読む前に大きな版を見る：schemaVersion が整数で 1 でなければ (4)。
        // 前の版の形（schemaVersion がなく version を持つ。G3 r2 までのアプリが書いた形）も (4) として読めないものにする。
        // 契約に移行の決まりはなく、アプリは起動のたびに写しを書き直すので、次に書くまでの間だけ読めない（ADR 0002）。
        if let rawObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let rawVersion = rawObject["schemaVersion"] as? Int, rawVersion != currentSchemaVersion {
                throw .unsupportedVersion(rawVersion)
            }
            if rawObject["schemaVersion"] == nil, rawObject["version"] != nil {
                throw .unsupportedVersion(nil)
            }
        }
        let snapshot: WidgetSnapshot
        do {
            snapshot = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        } catch let error as WidgetSnapshotValidationError {
            throw error
        } catch {
            throw .malformedJSON(String(describing: type(of: error)))
        }
        try snapshot.validate()
        return snapshot
    }

    /// 読めないときは今の本なしとして扱う読み方（W-5 の拡張の外の呼び出しだけが使う。W-1・W-2 は `WidgetSnapshotReader`）。
    public nonisolated static func decodeForWidgetRenderer(from data: Data) -> WidgetSnapshot {
        (try? decodeAndValidate(from: data)) ?? WidgetSnapshot()
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

public struct HookConfigEnvelope: Codable, Sendable, Equatable {
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

#if canImport(ActivityKit) && os(iOS)
public struct ReadingActivityAttributes: ActivityAttributes, Codable, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var mode: String
        public var title: String
        public var line: String?
        public var progressText: String?
        public var summaryText: String?
        public var hideOnWidgets: Bool

        public nonisolated init(
            mode: String = "reading",
            title: String,
            line: String? = nil,
            progressText: String? = nil,
            summaryText: String? = nil,
            hideOnWidgets: Bool = false
        ) {
            self.mode = mode
            self.title = title
            self.line = line
            self.progressText = progressText
            self.summaryText = summaryText
            self.hideOnWidgets = hideOnWidgets
        }
    }

    public var bookId: UUID?
    public var startedAt: Date?

    public nonisolated init(bookId: UUID? = nil, startedAt: Date? = nil) {
        self.bookId = bookId
        self.startedAt = startedAt
    }
}
#endif

