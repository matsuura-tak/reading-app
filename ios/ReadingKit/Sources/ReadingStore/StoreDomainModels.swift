import Foundation
import ReadingCore

public enum SessionStateValue: String, Codable, Sendable, Equatable {
    case idle
    case reading
}

public enum SessionEntryPoint: String, Codable, Sendable, Equatable {
    case app
    case lockWidget = "lock_widget"
    case smallWidget = "small_widget"
    case liveActivity = "live_activity"
    case intentStart = "intent_start"
    case intentOpen = "intent_open"
}

public struct BookSnapshot: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var isbn13: String?
    public var title: String
    public var author: String
    public var publisher: String?
    public var label: String?
    public var publishedYear: Int?
    public var seriesTitle: String?
    public var volumeNumber: Int?
    public var ndc: String?
    public var status: BookStatus
    public var isEbook: Bool
    public var isTitlePending: Bool
    public var progressUnit: ProgressUnit
    public var currentPage: Int?
    public var currentLocation: Int?
    public var currentPercent: Int?
    public var lastSavedLine: String?
    public var createdAt: String
    public var updatedAt: String
    public var tsundokuAt: String?
    public var finishedAt: String?

    public init(
        id: UUID = UUID(),
        isbn13: String? = nil,
        title: String,
        author: String = "",
        publisher: String? = nil,
        label: String? = nil,
        publishedYear: Int? = nil,
        seriesTitle: String? = nil,
        volumeNumber: Int? = nil,
        ndc: String? = nil,
        status: BookStatus = .current,
        isEbook: Bool = false,
        isTitlePending: Bool = false,
        progressUnit: ProgressUnit = .page,
        currentPage: Int? = nil,
        currentLocation: Int? = nil,
        currentPercent: Int? = nil,
        lastSavedLine: String? = nil,
        createdAt: String = "2026-10-18T21:00:00+09:00",
        updatedAt: String = "2026-10-18T21:00:00+09:00",
        tsundokuAt: String? = nil,
        finishedAt: String? = nil
    ) {
        self.id = id
        self.isbn13 = isbn13
        self.title = title
        self.author = author
        self.publisher = publisher
        self.label = label
        self.publishedYear = publishedYear
        self.seriesTitle = seriesTitle
        self.volumeNumber = volumeNumber
        self.ndc = ndc
        self.status = status
        self.isEbook = isEbook
        self.isTitlePending = isTitlePending
        self.progressUnit = progressUnit
        self.currentPage = currentPage
        self.currentLocation = currentLocation
        self.currentPercent = currentPercent
        self.lastSavedLine = lastSavedLine
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tsundokuAt = tsundokuAt
        self.finishedAt = finishedAt
    }
}

public struct ReadingRecordSnapshot: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var bookId: UUID
    public var startedAt: String
    public var endedAt: String
    public var durationMinutes: Int
    public var nightDate: String
    public var entry: SessionEntryPoint
    public var progressUnit: ProgressUnit?
    public var startPage: Int?
    public var endPage: Int?
    public var startLocation: Int?
    public var endLocation: Int?
    public var startPercent: Int?
    public var endPercent: Int?
    public var savedLine: String?

    public init(
        id: UUID = UUID(),
        bookId: UUID,
        startedAt: String,
        endedAt: String,
        durationMinutes: Int,
        nightDate: String,
        entry: SessionEntryPoint = .app,
        progressUnit: ProgressUnit? = nil,
        startPage: Int? = nil,
        endPage: Int? = nil,
        startLocation: Int? = nil,
        endLocation: Int? = nil,
        startPercent: Int? = nil,
        endPercent: Int? = nil,
        savedLine: String? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationMinutes = durationMinutes
        self.nightDate = nightDate
        self.entry = entry
        self.progressUnit = progressUnit
        self.startPage = startPage
        self.endPage = endPage
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.startPercent = startPercent
        self.endPercent = endPercent
        self.savedLine = savedLine
    }
}

public struct RecommendationCategoryCounter: Codable, Sendable, Equatable {
    public var chosen: Int
    public var skipped: Int

    public init(chosen: Int = 0, skipped: Int = 0) {
        self.chosen = chosen
        self.skipped = skipped
    }
}

public struct RecommendationWeights: Codable, Sendable, Equatable {
    public var readers: RecommendationCategoryCounter
    public var nextVolume: RecommendationCategoryCounter
    public var author: RecommendationCategoryCounter
    public var award: RecommendationCategoryCounter
    public var sameLabel: RecommendationCategoryCounter

    public init(
        readers: RecommendationCategoryCounter = RecommendationCategoryCounter(),
        nextVolume: RecommendationCategoryCounter = RecommendationCategoryCounter(),
        author: RecommendationCategoryCounter = RecommendationCategoryCounter(),
        award: RecommendationCategoryCounter = RecommendationCategoryCounter(),
        sameLabel: RecommendationCategoryCounter = RecommendationCategoryCounter()
    ) {
        self.readers = readers
        self.nextVolume = nextVolume
        self.author = author
        self.award = award
        self.sameLabel = sameLabel
    }

    public func asSeedWeights() -> [H02SeedRecommendationWeight] {
        var result: [H02SeedRecommendationWeight] = []
        if readers.chosen > 0 || readers.skipped > 0 {
            result.append(H02SeedRecommendationWeight(axis: .readers, chosenCount: readers.chosen, skippedCount: readers.skipped))
        }
        if nextVolume.chosen > 0 || nextVolume.skipped > 0 {
            result.append(H02SeedRecommendationWeight(axis: .nextVolume, chosenCount: nextVolume.chosen, skippedCount: nextVolume.skipped))
        }
        if author.chosen > 0 || author.skipped > 0 {
            result.append(H02SeedRecommendationWeight(axis: .sameAuthor, chosenCount: author.chosen, skippedCount: author.skipped))
        }
        if award.chosen > 0 || award.skipped > 0 {
            result.append(H02SeedRecommendationWeight(axis: .sameAward, chosenCount: award.chosen, skippedCount: award.skipped))
        }
        if sameLabel.chosen > 0 || sameLabel.skipped > 0 {
            result.append(H02SeedRecommendationWeight(axis: .sameLabel, chosenCount: sameLabel.chosen, skippedCount: sameLabel.skipped))
        }
        return result
    }
}

public struct SettingsSnapshot: Codable, Sendable, Equatable {
    public var flipToStartEnabled: Bool
    public var hideOnWidgets: Bool
    public var widgetGuideShown: Bool
    public var entryTime: String
    public var appearanceID: AppearanceID
    public var isPlusPurchased: Bool
    public var firstNightCompletedAt: String?
    public var seventhNightReachedAt: String?
    public var recommendationWeights: RecommendationWeights

    public init(
        flipToStartEnabled: Bool = true,
        hideOnWidgets: Bool = false,
        widgetGuideShown: Bool = false,
        entryTime: String = "21:00",
        appearanceID: AppearanceID = .default,
        isPlusPurchased: Bool = false,
        firstNightCompletedAt: String? = nil,
        seventhNightReachedAt: String? = nil,
        recommendationWeights: RecommendationWeights = RecommendationWeights()
    ) {
        self.flipToStartEnabled = flipToStartEnabled
        self.hideOnWidgets = hideOnWidgets
        self.widgetGuideShown = widgetGuideShown
        self.entryTime = entryTime
        self.appearanceID = appearanceID
        self.isPlusPurchased = isPlusPurchased
        self.firstNightCompletedAt = firstNightCompletedAt
        self.seventhNightReachedAt = seventhNightReachedAt
        self.recommendationWeights = recommendationWeights
    }
}

public struct ShareCardAuditItem: Codable, Sendable, Equatable {
    public var renderedTexts: [String]
    public var containsSavedLine: Bool
    public var containsPhoto: Bool
    public var containsReflection: Bool
    public var widthPx: Int
    public var heightPx: Int

    public init(
        renderedTexts: [String],
        containsSavedLine: Bool = false,
        containsPhoto: Bool = false,
        containsReflection: Bool = false,
        widthPx: Int = 1080,
        heightPx: Int = 1350
    ) {
        self.renderedTexts = renderedTexts
        self.containsSavedLine = containsSavedLine
        self.containsPhoto = containsPhoto
        self.containsReflection = containsReflection
        self.widthPx = widthPx
        self.heightPx = heightPx
    }
}

public struct H14ShareCardReadout: Codable, Sendable, Equatable {
    public var cards: [ShareCardAuditItem]

    public init(cards: [ShareCardAuditItem] = []) {
        self.cards = cards
    }
}

public struct H15MediaAuditReadout: Codable, Sendable, Equatable {
    public var savedImageFileCount: Int
    public var photoLibraryWriteCount: Int

    public init(savedImageFileCount: Int = 0, photoLibraryWriteCount: Int = 0) {
        self.savedImageFileCount = savedImageFileCount
        self.photoLibraryWriteCount = photoLibraryWriteCount
    }
}

public struct H16OpenedURL: Codable, Sendable, Equatable {
    public var url: String
    public var timestamp: String

    public init(url: String, timestamp: String) {
        self.url = url
        self.timestamp = timestamp
    }
}

public struct H16OutboundReadout: Codable, Sendable, Equatable {
    public var totalCount: Int
    public var requests: [H29OutboundRequest]
    public var openedURLs: [H16OpenedURL]

    public init(
        totalCount: Int = 0,
        requests: [H29OutboundRequest] = [],
        openedURLs: [H16OpenedURL] = []
    ) {
        self.totalCount = totalCount
        self.requests = requests
        self.openedURLs = openedURLs
    }
}
