import Foundation
import Observation
import SwiftData
import ReadingCore

// MARK: - SwiftData Schema V1

public enum ReadingSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    public static var models: [any PersistentModel.Type] {
        [
            PersistedBookModel.self,
            PersistedReadingRecordModel.self,
            PersistedActiveSessionModel.self,
            PersistedSettingsModel.self
        ]
    }

    @Model
    public final class PersistedBookModel {
        @Attribute(.unique) public var id: UUID
        public var isbn13: String?
        public var title: String
        public var author: String
        public var publisher: String?
        public var label: String?
        public var publishedYear: Int?
        public var seriesTitle: String?
        public var volumeNumber: Int?
        public var ndc: String?
        public var statusRaw: String
        public var isEbook: Bool
        public var isTitlePending: Bool
        public var progressUnitRaw: String
        public var currentPage: Int?
        public var currentLocation: Int?
        public var currentPercent: Int?
        public var lastSavedLine: String?
        public var createdAt: String
        public var updatedAt: String
        public var tsundokuAt: String?
        public var finishedAt: String?

        public init(from snapshot: BookSnapshot) {
            self.id = snapshot.id
            self.isbn13 = snapshot.isbn13
            self.title = snapshot.title
            self.author = snapshot.author
            self.publisher = snapshot.publisher
            self.label = snapshot.label
            self.publishedYear = snapshot.publishedYear
            self.seriesTitle = snapshot.seriesTitle
            self.volumeNumber = snapshot.volumeNumber
            self.ndc = snapshot.ndc
            self.statusRaw = snapshot.status.rawValue
            self.isEbook = snapshot.isEbook
            self.isTitlePending = snapshot.isTitlePending
            self.progressUnitRaw = snapshot.progressUnit.rawValue
            self.currentPage = snapshot.currentPage
            self.currentLocation = snapshot.currentLocation
            self.currentPercent = snapshot.currentPercent
            self.lastSavedLine = snapshot.lastSavedLine
            self.createdAt = snapshot.createdAt
            self.updatedAt = snapshot.updatedAt
            self.tsundokuAt = snapshot.tsundokuAt
            self.finishedAt = snapshot.finishedAt
        }
    }

    @Model
    public final class PersistedReadingRecordModel {
        @Attribute(.unique) public var id: UUID
        public var bookId: UUID
        public var startedAt: String
        public var endedAt: String
        public var durationMinutes: Int
        public var nightDate: String
        public var entryRaw: String
        public var progressUnitRaw: String?
        public var startPage: Int?
        public var endPage: Int?
        public var startLocation: Int?
        public var endLocation: Int?
        public var startPercent: Int?
        public var endPercent: Int?
        public var savedLine: String?

        public init(from snapshot: ReadingRecordSnapshot) {
            self.id = snapshot.id
            self.bookId = snapshot.bookId
            self.startedAt = snapshot.startedAt
            self.endedAt = snapshot.endedAt
            self.durationMinutes = snapshot.durationMinutes
            self.nightDate = snapshot.nightDate
            self.entryRaw = snapshot.entry.rawValue
            self.progressUnitRaw = snapshot.progressUnit?.rawValue
            self.startPage = snapshot.startPage
            self.endPage = snapshot.endPage
            self.startLocation = snapshot.startLocation
            self.endLocation = snapshot.endLocation
            self.startPercent = snapshot.startPercent
            self.endPercent = snapshot.endPercent
            self.savedLine = snapshot.savedLine
        }
    }

    @Model
    public final class PersistedActiveSessionModel {
        @Attribute(.unique) public var id: String
        public var bookId: UUID
        public var startedAt: String
        public var startedByRaw: String
        public var entryRaw: String
        public var liveActivityId: String?

        public init(from session: ActiveSessionSnapshot) {
            self.id = "active"
            self.bookId = session.bookId
            self.startedAt = session.startedAt
            self.startedByRaw = session.startedBy
            self.entryRaw = session.entry.rawValue
            self.liveActivityId = session.liveActivityId
        }
    }

    @Model
    public final class PersistedSettingsModel {
        @Attribute(.unique) public var id: String
        public var flipToStartEnabled: Bool
        public var hideOnWidgets: Bool
        public var widgetGuideShown: Bool
        public var entryTime: String
        public var appearanceIDRaw: String
        public var isPlusPurchased: Bool
        public var firstNightCompletedAt: String?
        public var seventhNightReachedAt: String?

        public init(from settings: SettingsSnapshot) {
            self.id = "singleton"
            self.flipToStartEnabled = settings.flipToStartEnabled
            self.hideOnWidgets = settings.hideOnWidgets
            self.widgetGuideShown = settings.widgetGuideShown
            self.entryTime = settings.entryTime
            self.appearanceIDRaw = settings.appearanceID.rawValue
            self.isPlusPurchased = settings.isPlusPurchased
            self.firstNightCompletedAt = settings.firstNightCompletedAt
            self.seventhNightReachedAt = settings.seventhNightReachedAt
        }
    }
}

public enum ReadingMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [ReadingSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

// MARK: - Persisted State Snapshot

public struct ActiveSessionSnapshot: Codable, Sendable, Equatable {
    public var bookId: UUID
    public var startedAt: String
    public var startedBy: String
    public var entry: SessionEntryPoint
    public var liveActivityId: String?
    public var hadCancelledTonightSchedule: Bool

    public init(
        bookId: UUID,
        startedAt: String,
        startedBy: String = "tap",
        entry: SessionEntryPoint = .app,
        liveActivityId: String? = nil,
        hadCancelledTonightSchedule: Bool = false
    ) {
        self.bookId = bookId
        self.startedAt = startedAt
        self.startedBy = startedBy
        self.entry = entry
        self.liveActivityId = liveActivityId
        self.hadCancelledTonightSchedule = hadCancelledTonightSchedule
    }
}

public struct PersistedStoreEnvelope: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var books: [BookSnapshot]
    public var records: [ReadingRecordSnapshot]
    public var settings: SettingsSnapshot
    public var activeSession: ActiveSessionSnapshot?

    public init(
        schemaVersion: Int = 1,
        books: [BookSnapshot] = [],
        records: [ReadingRecordSnapshot] = [],
        settings: SettingsSnapshot = SettingsSnapshot(),
        activeSession: ActiveSessionSnapshot? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.books = books
        self.records = records
        self.settings = settings
        self.activeSession = activeSession
    }
}

// MARK: - Live Activity & StoreKit & Intents Models

public struct LiveActivityItemState: Codable, Sendable, Equatable {
    public var id: String
    public var kind: String
    public var state: String
    public var scheduledFor: String?
    public var staleDate: String?
    public var url: String
    public var title: String
    public var line: String?
    public var progressText: String?
    public var startedAt: String?
    public var endButtonIdentifier: String?
    public var endButtonLabel: String?
    public var endIntentName: String?
    public var summaryText: String?

    public init(
        id: String,
        kind: String,
        state: String,
        scheduledFor: String? = nil,
        staleDate: String? = nil,
        url: String = "yomuma://open?entry=live_activity",
        title: String,
        line: String? = nil,
        progressText: String? = nil,
        startedAt: String? = nil,
        endButtonIdentifier: String? = nil,
        endButtonLabel: String? = nil,
        endIntentName: String? = nil,
        summaryText: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.state = state
        self.scheduledFor = scheduledFor
        self.staleDate = staleDate
        self.url = url
        self.title = title
        self.line = line
        self.progressText = progressText
        self.startedAt = startedAt
        self.endButtonIdentifier = endButtonIdentifier
        self.endButtonLabel = endButtonLabel
        self.endIntentName = endIntentName
        self.summaryText = summaryText
    }
}

public struct LiveActivityRequestLog: Codable, Sendable, Equatable {
    public var kind: String
    public var source: String
    public var timestamp: String
    public var scheduledFor: String?
    public var succeeded: Bool

    public init(kind: String, source: String, timestamp: String, scheduledFor: String? = nil, succeeded: Bool = true) {
        self.kind = kind
        self.source = source
        self.timestamp = timestamp
        self.scheduledFor = scheduledFor
        self.succeeded = succeeded
    }
}

public struct IntentInvocationLog: Codable, Sendable, Equatable {
    public var intent: String
    public var outcome: String
    public var dialogKey: String
    public var spokenText: String
    public var snippetTexts: [String]
    public var opensApp: Bool
    public var requestedForeground: Bool
    public var authenticationPolicy: String
    public var timestamp: String

    public init(
        intent: String,
        outcome: String,
        dialogKey: String,
        spokenText: String,
        snippetTexts: [String],
        opensApp: Bool,
        requestedForeground: Bool,
        authenticationPolicy: String = "alwaysAllowed",
        timestamp: String
    ) {
        self.intent = intent
        self.outcome = outcome
        self.dialogKey = dialogKey
        self.spokenText = spokenText
        self.snippetTexts = snippetTexts
        self.opensApp = opensApp
        self.requestedForeground = requestedForeground
        self.authenticationPolicy = authenticationPolicy
        self.timestamp = timestamp
    }
}

public struct ActiveScreenState: Sendable, Equatable {
    public var isOnBookmarkScreen: Bool = true
    public var hasOverlayOrSheet: Bool = false

    public init(isOnBookmarkScreen: Bool = true, hasOverlayOrSheet: Bool = false) {
        self.isOnBookmarkScreen = isOnBookmarkScreen
        self.hasOverlayOrSheet = hasOverlayOrSheet
    }
}

public enum EndSessionResult: Sendable, Equatable {
    case saved(record: ReadingRecordSnapshot, capped: Bool)
    case discardedTooShort
    case discardedInvalidTime
    case failedSave
    case ignoredDuplicate
}

public enum SaveMarkResult: Sendable, Equatable {
    case saved(summaryText: String?, showedWidgetGuide: Bool)
    case invalidLine
    case invalidPage
    case failedSave
}

public enum StorePurchaseResult: Sendable, Equatable {
    case success
    case userCancelled
    case error
    case unavailable
    case offline
}

public enum StoreRestoreResult: Sendable, Equatable {
    case restored
    case none
}

// MARK: - ReadingDataStore

@MainActor
@Observable
public final class ReadingDataStore {
    public let containerDirectory: URL
    public let storeFileURL: URL
    public let stateJSONURL: URL
    public let clock: ReadingClock
    public let snapshotStore: SnapshotStore
    public let catalogDB: CatalogDatabase
    public private(set) var modelContainer: ModelContainer?

    // Core persisted data
    public var books: [BookSnapshot] = []
    public var records: [ReadingRecordSnapshot] = []
    public var settings: SettingsSnapshot = SettingsSnapshot()
    public var activeSession: ActiveSessionSnapshot?

    // Session & UI state
    public var sessionState: SessionStateValue = .idle
    public var lastStartedBy: String = "tap"
    public var lastEntryPoint: SessionEntryPoint = .app
    public var pendingEntryURL: (entry: SessionEntryPoint, openedAt: Date)?
    public var pendingMarkRecordId: UUID?
    public var pendingMarkPreviousProgress: Int?
    public var pendingMarkPreviousUnit: ProgressUnit?
    public var latestResultSummary: String?
    public var activeErrorKey: String?
    public var isStoreLoadFailed: Bool = false
    public var showWidgetGuide: Bool = false

    // Haptic, announcements, notices
    public var hapticCount: Int = 0
    public var announcements: [String: Int] = [:]
    public var notices: [String: Int] = [:]
    public var activeNoticeKey: String?

    // Flip monitoring & orientation
    public var isFlipAvailable: Bool = true
    public var currentOrientation: String = "portrait"
    public var wasLaunchedFaceDown: Bool = false
    public var faceDownEnteredAtMs: Int64?
    public var screenState: ActiveScreenState = ActiveScreenState()
    private var lastSessionActionAt: Date?

    // Fail-save fault injection (H7)
    public var remainingFailSaves: [String: Int] = [:]

    // Live Activity state (H17)
    public var areActivitiesEnabled: Bool = true
    public var failScheduleCount: Int = 0
    public var failStartImmediateCount: Int = 0
    public var needsRescheduleOnActivate: Bool = false
    public var liveActivities: [LiveActivityItemState] = []
    public var liveActivityRequests: [LiveActivityRequestLog] = []

    // StoreKit state (H19)
    public var storeCanMakePayments: Bool = true
    public var storeProductLoadAvailable: Bool = true
    public var storePurchaseOutcome: String = "success"
    public var storeRestoreOutcome: String = "hasEntitlement"
    public var pendingRefundOnActivate: Bool = false
    public var previewAppearanceID: AppearanceID?
    public var storeStatusMessageKey: String?

    // Intents state (H20)
    public var intentDefaultCanContinueInForeground: Bool = true
    public var intentInvocations: [IntentInvocationLog] = []
    public var lastIntentRequestedForeground: Bool = false
    public var shouldPresentMarkInputAfterIntentEnd: Bool = false

    // Share cards, Awards, Outbound, Media audit, OCR, Camera
    public var shareCards: [ShareCardAuditItem] = []
    public var awardsMode: String = "bundled"
    public var activeAwards: [H25AwardItem] = AwardsCatalog.allBundledAwards()
    public var openedURLs: [H16OpenedURL] = []
    public var savedImageFileCount: Int = 0
    public var photoLibraryWriteCount: Int = 0
    public var isOffline: Bool = false
    public var cameraAuthorization: String = "authorized"
    public var ocrConfiguration: H23OCRStubConfig?
    public var isOCRHoldReleased: Bool = false

    public static let uuidBookA = UUID(uuidString: "00000000-0000-4000-8000-000000000001") ?? UUID()
    public static let uuidBookB = UUID(uuidString: "00000000-0000-4000-8000-000000000002") ?? UUID()
    public static let uuidBookC = UUID(uuidString: "00000000-0000-4000-8000-000000000003") ?? UUID()
    public static let uuidBookD = UUID(uuidString: "00000000-0000-4000-8000-000000000004") ?? UUID()
    public static let uuidBookE = UUID(uuidString: "00000000-0000-4000-8000-000000000005") ?? UUID()

    public init(
        containerDirectory: URL? = nil,
        clock: ReadingClock? = nil
    ) {
        let baseDir = containerDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.containerDirectory = baseDir
        let appSupportDir = baseDir.appendingPathComponent("Application Support", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        self.storeFileURL = appSupportDir.appendingPathComponent("ReadingStore.store")
        self.stateJSONURL = appSupportDir.appendingPathComponent("ReadingStoreState.json")
        self.clock = clock ?? ReadingClock()
        self.snapshotStore = SnapshotStore(containerDirectory: baseDir)
        let catalogURL = appSupportDir.appendingPathComponent("catalog.sqlite")
        self.catalogDB = CatalogDatabase(databaseURL: catalogURL)

        let schema = Schema(versionedSchema: ReadingSchemaV1.self)
        let config = ModelConfiguration(schema: schema, url: storeFileURL, allowsSave: true)
        self.modelContainer = try? ModelContainer(for: schema, migrationPlan: ReadingMigrationPlan.self, configurations: [config])
        setExcludedFromBackup(false, for: storeFileURL)
    }

    private func setExcludedFromBackup(_ excluded: Bool, for url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        var rv = URLResourceValues()
        rv.isExcludedFromBackup = excluded
        var mutable = url
        try? mutable.setResourceValues(rv)
    }

    // MARK: - Reset, Seed, and Launch Configuration

    public func resetAllData() {
        books = []
        records = []
        settings = SettingsSnapshot()
        activeSession = nil
        sessionState = .idle
        lastStartedBy = "tap"
        lastEntryPoint = .app
        pendingEntryURL = nil
        pendingMarkRecordId = nil
        pendingMarkPreviousProgress = nil
        pendingMarkPreviousUnit = nil
        latestResultSummary = nil
        activeErrorKey = nil
        isStoreLoadFailed = false
        showWidgetGuide = false
        hapticCount = 0
        announcements = [:]
        notices = [:]
        activeNoticeKey = nil
        faceDownEnteredAtMs = nil
        lastSessionActionAt = nil
        liveActivities = []
        liveActivityRequests = []
        needsRescheduleOnActivate = false
        intentInvocations = []
        shareCards = []
        openedURLs = []
        savedImageFileCount = 0
        photoLibraryWriteCount = 0
        previewAppearanceID = nil
        storeStatusMessageKey = nil
        snapshotStore.resetCounts()

        try? FileManager.default.removeItem(at: stateJSONURL)
        try? FileManager.default.removeItem(at: snapshotStore.fileURL)
        try? persistCurrentEnvelopeToDisk()
        _ = try? snapshotStore.writeSnapshot(
            currentBook: currentBook,
            settings: settings,
            nowISO: clock.nowISO8601(),
            cause: nil,
            recordReload: false
        )
    }

    public func configureFailSave(_ rawSpec: String?) {
        remainingFailSaves = [:]
        guard let rawSpec, !rawSpec.isEmpty else { return }
        let items = rawSpec.split(separator: ",")
        for item in items {
            let parts = item.split(separator: ":", maxSplits: 1).map(String.init)
            if parts.count == 2, let count = Int(parts[1]), count > 0 {
                remainingFailSaves[parts[0], default: 0] += count
            } else if parts.count == 1, !parts[0].isEmpty {
                remainingFailSaves[parts[0], default: 0] += 1
            }
        }
    }

    public func consumeFailSave(for point: String) -> Bool {
        guard let remaining = remainingFailSaves[point], remaining > 0 else {
            return false
        }
        remainingFailSaves[point] = remaining - 1
        return true
    }

    public func seedFromJSON(_ jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8),
              let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        let nowISO = clock.nowISO8601()
        var seededBooks: [BookSnapshot] = []
        if let rawBooks = root["books"] as? [[String: Any]] {
            for item in rawBooks {
                let idStr = (item["id"] as? String) ?? UUID().uuidString
                let id = UUID(uuidString: idStr) ?? UUID()
                let title = (item["title"] as? String) ?? ""
                let author = (item["author"] as? String) ?? ""
                let isbn13 = item["isbn13"] as? String
                let publisher = item["publisher"] as? String
                let label = item["label"] as? String
                let publishedYear = item["publishedYear"] as? Int
                let seriesTitle = item["seriesTitle"] as? String
                let volumeNumber = item["volumeNumber"] as? Int
                let ndc = item["ndc"] as? String
                let statusRaw = (item["status"] as? String) ?? "current"
                let status = BookStatus(rawValue: statusRaw) ?? .current
                let isEbook = (item["isEbook"] as? Bool) ?? false
                let isTitlePending = (item["isTitlePending"] as? Bool) ?? false
                let unitRaw = (item["progressUnit"] as? String) ?? "page"
                let progressUnit = ProgressUnit(rawValue: unitRaw) ?? .page
                let page = (item["page"] as? Int) ?? (item["currentPage"] as? Int)
                let location = (item["location"] as? Int) ?? (item["currentLocation"] as? Int)
                let percent = (item["percent"] as? Int) ?? (item["currentPercent"] as? Int)
                let lastLine = (item["lastLine"] as? String) ?? (item["lastSavedLine"] as? String)
                let createdAt = (item["createdAt"] as? String) ?? nowISO
                let updatedAt = (item["updatedAt"] as? String) ?? createdAt
                let tsundokuAt = (item["tsundokuAt"] as? String) ?? (status == .tsundoku ? createdAt : nil)
                let finishedAt = (item["finishedAt"] as? String) ?? (status == .finished ? updatedAt : nil)

                seededBooks.append(
                    BookSnapshot(
                        id: id,
                        isbn13: isbn13,
                        title: title,
                        author: author,
                        publisher: publisher,
                        label: label,
                        publishedYear: publishedYear,
                        seriesTitle: seriesTitle,
                        volumeNumber: volumeNumber,
                        ndc: ndc,
                        status: status,
                        isEbook: isEbook,
                        isTitlePending: isTitlePending,
                        progressUnit: progressUnit,
                        currentPage: page,
                        currentLocation: location,
                        currentPercent: percent,
                        lastSavedLine: lastLine,
                        createdAt: createdAt,
                        updatedAt: updatedAt,
                        tsundokuAt: tsundokuAt,
                        finishedAt: finishedAt
                    )
                )
            }
        }

        var seededRecords: [ReadingRecordSnapshot] = []
        let rawRecords = (root["records"] as? [[String: Any]]) ?? (root["readingRecords"] as? [[String: Any]]) ?? []
        for item in rawRecords {
            let idStr = (item["id"] as? String) ?? UUID().uuidString
            let id = UUID(uuidString: idStr) ?? UUID()
            let bookIdStr = (item["bookId"] as? String) ?? Self.uuidBookA.uuidString
            let bookId = UUID(uuidString: bookIdStr) ?? Self.uuidBookA
            let startedAt = (item["startedAt"] as? String) ?? nowISO
            let endedAt = (item["endedAt"] as? String) ?? startedAt
            let minutes = (item["minutes"] as? Int) ?? (item["durationMinutes"] as? Int) ?? 15
            let parsedStart = NightDateCalculator.parseISO8601(startedAt) ?? clock.now()
            let nightDate = (item["nightDate"] as? String) ?? clock.nightDate(for: parsedStart)
            let entryRaw = (item["entry"] as? String) ?? "app"
            let entry = SessionEntryPoint(rawValue: entryRaw) ?? .app
            let unitRaw = item["progressUnit"] as? String
            let unit = unitRaw.flatMap(ProgressUnit.init(rawValue:))

            seededRecords.append(
                ReadingRecordSnapshot(
                    id: id,
                    bookId: bookId,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    durationMinutes: minutes,
                    nightDate: nightDate,
                    entry: entry,
                    progressUnit: unit,
                    startPage: item["startPage"] as? Int,
                    endPage: item["endPage"] as? Int,
                    startLocation: item["startLocation"] as? Int,
                    endLocation: item["endLocation"] as? Int,
                    startPercent: item["startPercent"] as? Int,
                    endPercent: item["endPercent"] as? Int,
                    savedLine: item["savedLine"] as? String
                )
            )
        }

        var seededSettings = SettingsSnapshot()
        if let rawSettings = root["settings"] as? [String: Any] {
            seededSettings.flipToStartEnabled = (rawSettings["flipToStartEnabled"] as? Bool) ?? true
            seededSettings.hideOnWidgets = (rawSettings["hideOnWidgets"] as? Bool) ?? false
            seededSettings.widgetGuideShown = (rawSettings["widgetGuideShown"] as? Bool) ?? false
            seededSettings.entryTime = (rawSettings["entryTime"] as? String) ?? "21:00"
            if let appStr = rawSettings["appearanceID"] as? String,
               let parsedApp = AppearanceID(rawValue: appStr) {
                seededSettings.appearanceID = parsedApp
            }
            seededSettings.isPlusPurchased = (rawSettings["isPlusPurchased"] as? Bool) ?? false
            seededSettings.firstNightCompletedAt = rawSettings["firstNightCompletedAt"] as? String
            seededSettings.seventhNightReachedAt = rawSettings["seventhNightReachedAt"] as? String

            if let rawWeights = rawSettings["recommendationWeights"] as? [String: Any] {
                var weights = RecommendationWeights()
                if let r = rawWeights["readers"] as? [String: Any] {
                    weights.readers = RecommendationCategoryCounter(
                        chosen: (r["chosen"] as? Int) ?? 0,
                        skipped: (r["skipped"] as? Int) ?? 0
                    )
                }
                if let a = rawWeights["author"] as? [String: Any] {
                    weights.author = RecommendationCategoryCounter(
                        chosen: (a["chosen"] as? Int) ?? 0,
                        skipped: (a["skipped"] as? Int) ?? 0
                    )
                }
                if let aw = rawWeights["award"] as? [String: Any] {
                    weights.award = RecommendationCategoryCounter(
                        chosen: (aw["chosen"] as? Int) ?? 0,
                        skipped: (aw["skipped"] as? Int) ?? 0
                    )
                }
                seededSettings.recommendationWeights = weights
            }
        }

        var seededActiveSession: ActiveSessionSnapshot?
        if let rawSession = root["activeSession"] as? [String: Any] {
            let bIdStr = (rawSession["bookId"] as? String) ?? Self.uuidBookA.uuidString
            let bId = UUID(uuidString: bIdStr) ?? Self.uuidBookA
            let startedAt = (rawSession["startedAt"] as? String) ?? nowISO
            let entryRaw = (rawSession["entry"] as? String) ?? "app"
            let entry = SessionEntryPoint(rawValue: entryRaw) ?? .app
            let startedBy = (rawSession["startedBy"] as? String) ?? "tap"
            let laId = rawSession["liveActivityId"] as? String
            seededActiveSession = ActiveSessionSnapshot(
                bookId: bId,
                startedAt: startedAt,
                startedBy: startedBy,
                entry: entry,
                liveActivityId: laId
            )
        }

        let envelope = PersistedStoreEnvelope(
            schemaVersion: 1,
            books: seededBooks,
            records: seededRecords,
            settings: seededSettings,
            activeSession: seededActiveSession
        )
        try writeEnvelopeToDisk(envelope)

        if consumeFailSave(for: "store.load") {
            self.books = []
            self.records = []
            self.settings = SettingsSnapshot()
            self.activeSession = nil
            self.sessionState = .idle
            self.isStoreLoadFailed = true
            self.activeErrorKey = "store.load.error"
            return
        }

        applyEnvelope(envelope)
    }

    public func seedPreset(_ preset: String) throws {
        guard preset == "perf500" else { return }
        let nowISO = clock.nowISO8601()
        var presetBooks: [BookSnapshot] = []
        presetBooks.reserveCapacity(500)
        var presetRecords: [ReadingRecordSnapshot] = []
        presetRecords.reserveCapacity(5000)

        for idx in 1...500 {
            let id: UUID
            switch idx {
            case 1: id = Self.uuidBookA
            case 2: id = Self.uuidBookB
            case 3: id = Self.uuidBookC
            case 4: id = Self.uuidBookD
            case 5: id = Self.uuidBookE
            default:
                id = UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", idx)) ?? UUID()
            }
            let status: BookStatus
            if idx == 1 {
                status = .current
            } else if idx <= 250 {
                status = .tsundoku
            } else {
                status = .finished
            }
            presetBooks.append(
                BookSnapshot(
                    id: id,
                    isbn13: String(format: "9784101%06d", idx),
                    title: "テスト書名\(idx)",
                    author: "テスト著者\(idx)",
                    publisher: "新潮社",
                    label: "新潮文庫",
                    publishedYear: 2020,
                    status: status,
                    progressUnit: .page,
                    currentPage: 45,
                    lastSavedLine: idx == 1 ? "ある日の暮方の事である。" : nil,
                    createdAt: nowISO,
                    updatedAt: nowISO,
                    tsundokuAt: status == .tsundoku ? nowISO : nil,
                    finishedAt: status == .finished ? nowISO : nil
                )
            )
        }

        for rIdx in 1...5000 {
            let recId = UUID(uuidString: String(format: "00000000-0000-4000-9000-%012d", rIdx)) ?? UUID()
            let bookId: UUID
            if rIdx <= 1000 {
                bookId = Self.uuidBookA
            } else {
                let bOffset = ((rIdx - 1001) % 499) + 2
                bookId = presetBooks[bOffset - 1].id
            }
            let dayOffset = (rIdx % 28) + 1
            let nightDate = String(format: "2026-10-%02d", dayOffset)
            presetRecords.append(
                ReadingRecordSnapshot(
                    id: recId,
                    bookId: bookId,
                    startedAt: "\(nightDate)T21:00:00+09:00",
                    endedAt: "\(nightDate)T21:15:00+09:00",
                    durationMinutes: 15,
                    nightDate: nightDate,
                    entry: .app
                )
            )
        }

        let envelope = PersistedStoreEnvelope(
            schemaVersion: 1,
            books: presetBooks,
            records: presetRecords,
            settings: SettingsSnapshot(),
            activeSession: nil
        )
        try writeEnvelopeToDisk(envelope)
        applyEnvelope(envelope)
    }

    public func loadFromDisk() {
        if consumeFailSave(for: "store.load") {
            self.books = []
            self.records = []
            self.settings = SettingsSnapshot()
            self.activeSession = nil
            self.sessionState = .idle
            self.isStoreLoadFailed = true
            self.activeErrorKey = "store.load.error"
            return
        }

        if FileManager.default.fileExists(atPath: stateJSONURL.path),
           let data = try? Data(contentsOf: stateJSONURL),
           let envelope = try? JSONDecoder().decode(PersistedStoreEnvelope.self, from: data) {
            applyEnvelope(envelope)
        } else {
            applyEnvelope(PersistedStoreEnvelope())
        }
    }

    private func applyEnvelope(_ envelope: PersistedStoreEnvelope) {
        self.isStoreLoadFailed = false
        self.activeErrorKey = nil
        self.books = envelope.books
        self.records = envelope.records
        self.settings = envelope.settings
        self.activeSession = envelope.activeSession
        if let active = envelope.activeSession {
            self.sessionState = .reading
            self.lastStartedBy = active.startedBy
            self.lastEntryPoint = active.entry
        } else {
            self.sessionState = .idle
        }
        _ = try? snapshotStore.writeSnapshot(
            currentBook: currentBook,
            settings: settings,
            nowISO: clock.nowISO8601(),
            cause: nil,
            recordReload: false
        )
        if liveActivities.isEmpty && areActivitiesEnabled && currentBook != nil && sessionState == .idle {
            scheduleNextEntryLiveActivityIfNeeded(source: "launch")
        }
    }

    private func currentEnvelope() -> PersistedStoreEnvelope {
        PersistedStoreEnvelope(
            schemaVersion: 1,
            books: books,
            records: records,
            settings: settings,
            activeSession: activeSession
        )
    }

    private func persistCurrentEnvelopeToDisk() throws {
        try writeEnvelopeToDisk(currentEnvelope())
    }

    private func writeEnvelopeToDisk(_ envelope: PersistedStoreEnvelope) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(envelope)
        let dir = stateJSONURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try data.write(to: stateJSONURL, options: .atomic)
        setExcludedFromBackup(false, for: stateJSONURL)
        setExcludedFromBackup(false, for: storeFileURL)
    }

    // MARK: - Computed Properties

    public var currentBook: BookSnapshot? {
        books.first { $0.status.isCurrentReading }
    }

    public var tsundokuBooks: [BookSnapshot] {
        books
            .filter { $0.status == .tsundoku }
            .sorted { ($0.tsundokuAt ?? $0.createdAt) > ($1.tsundokuAt ?? $1.createdAt) }
    }

    public var finishedBooks: [BookSnapshot] {
        books
            .filter { $0.status == .finished }
            .sorted { ($0.finishedAt ?? $0.updatedAt) > ($1.finishedAt ?? $1.updatedAt) }
    }

    public var hasTitlePendingBook: Bool {
        books.contains { $0.isTitlePending }
    }

    public func records(for bookId: UUID) -> [ReadingRecordSnapshot] {
        records
            .filter { $0.bookId == bookId }
            .sorted { $0.startedAt > $1.startedAt }
    }

    public func totalMinutes(for bookId: UUID) -> Int {
        records.filter { $0.bookId == bookId }.reduce(0) { $0 + $1.durationMinutes }
    }

    public func distinctNightCount(for bookId: UUID) -> Int {
        let nights = Set(records.filter { $0.bookId == bookId }.map(\.nightDate))
        return nights.count
    }

    public var isFlipMonitoringOn: Bool {
        guard !isStoreLoadFailed else { return false }
        guard isFlipAvailable && settings.flipToStartEnabled else { return false }
        guard sessionState == .idle else { return false }
        guard currentBook != nil else { return false }
        guard screenState.isOnBookmarkScreen && !screenState.hasOverlayOrSheet else { return false }
        guard activeNoticeKey == nil && activeErrorKey == nil else { return false }
        return true
    }

    // MARK: - Book CRUD & Status Management

    @discardableResult
    public func addBook(
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
        isEbook: Bool = false,
        progressUnit: ProgressUnit = .page,
        forceTsundoku: Bool = false
    ) -> Result<BookSnapshot, ValidationError> {
        let cleanTitle: String
        switch InputValidator.validateTitle(title) {
        case .failure(let err):
            activeErrorKey = "book.title.invalid"
            return .failure(err)
        case .success(let t):
            cleanTitle = t
        }

        let cleanAuthor: String
        switch InputValidator.validateAuthor(author) {
        case .failure(let err):
            activeErrorKey = "book.author.invalid"
            return .failure(err)
        case .success(let a):
            cleanAuthor = a
        }

        if consumeFailSave(for: "book.add") {
            activeErrorKey = "common.save.error"
            return .failure(.empty)
        }
        let nowISO = clock.nowISO8601()
        let shouldBeCurrent = !forceTsundoku && (currentBook == nil)
        let status: BookStatus = shouldBeCurrent ? .current : .tsundoku
        let newBook = BookSnapshot(
            id: id,
            isbn13: isbn13?.isEmpty == true ? nil : isbn13,
            title: cleanTitle,
            author: cleanAuthor,
            publisher: publisher?.isEmpty == true ? nil : publisher,
            label: label?.isEmpty == true ? nil : label,
            publishedYear: publishedYear,
            seriesTitle: seriesTitle,
            volumeNumber: volumeNumber,
            ndc: ndc,
            status: status,
            isEbook: isEbook,
            isTitlePending: false,
            progressUnit: progressUnit,
            createdAt: nowISO,
            updatedAt: nowISO,
            tsundokuAt: status == .tsundoku ? nowISO : nil,
            finishedAt: nil
        )
        let prevBooks = books
        books.append(newBook)
        do {
            try persistCurrentEnvelopeToDisk()
            activeErrorKey = nil
            if shouldBeCurrent {
                _ = try? snapshotStore.writeSnapshot(
                    currentBook: currentBook,
                    settings: settings,
                    nowISO: nowISO,
                    cause: "book.add",
                    recordReload: true
                )
            }
            return .success(newBook)
        } catch {
            books = prevBooks
            activeErrorKey = "common.save.error"
            return .failure(.empty)
        }
    }

    @discardableResult
    public func addMultipleBooksToTsundoku(_ items: [(isbn13: String?, title: String, author: String, publisher: String?, label: String?, publishedYear: Int?, ndc: String?)]) -> Bool {
        if consumeFailSave(for: "book.add") {
            activeErrorKey = "common.save.error"
            return false
        }
        let prevBooks = books
        let nowISO = clock.nowISO8601()
        for (idx, item) in items.enumerated() {
            let trimmedTitle = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else { continue }
            let trimmedAuthor = item.author.trimmingCharacters(in: .whitespacesAndNewlines)
            let shouldBeCurrent = (currentBook == nil && idx == 0 && !books.contains(where: { $0.status.isCurrentReading }))
            let status: BookStatus = shouldBeCurrent ? .current : .tsundoku
            let book = BookSnapshot(
                id: UUID(),
                isbn13: item.isbn13?.isEmpty == true ? nil : item.isbn13,
                title: trimmedTitle,
                author: trimmedAuthor,
                publisher: item.publisher?.isEmpty == true ? nil : item.publisher,
                label: item.label?.isEmpty == true ? nil : item.label,
                publishedYear: item.publishedYear,
                ndc: item.ndc,
                status: status,
                isEbook: false,
                isTitlePending: false,
                progressUnit: .page,
                createdAt: nowISO,
                updatedAt: nowISO,
                tsundokuAt: status == .tsundoku ? nowISO : nil
            )
            books.append(book)
        }
        do {
            try persistCurrentEnvelopeToDisk()
            activeErrorKey = nil
            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: nowISO,
                cause: "book.add",
                recordReload: true
            )
            return true
        } catch {
            books = prevBooks
            activeErrorKey = "common.save.error"
            return false
        }
    }

    @discardableResult
    public func startReadingWithPendingTitleBook() -> Bool {
        guard !hasTitlePendingBook else { return false }
        if consumeFailSave(for: "book.add") || consumeFailSave(for: "session.start") {
            activeErrorKey = "common.save.error"
            return false
        }
        let prevBooks = books
        let prevSession = activeSession
        let prevState = sessionState
        let nowISO = clock.nowISO8601()

        for idx in books.indices where books[idx].status.isCurrentReading {
            books[idx].status = .tsundoku
            books[idx].tsundokuAt = nowISO
            books[idx].updatedAt = nowISO
        }

        let newBook = BookSnapshot(
            id: UUID(),
            title: "",
            author: "",
            status: .current,
            isEbook: false,
            isTitlePending: true,
            progressUnit: .page,
            createdAt: nowISO,
            updatedAt: nowISO
        )
        books.append(newBook)

        let entry = resolveEntryForSessionStart()
        let session = ActiveSessionSnapshot(
            bookId: newBook.id,
            startedAt: nowISO,
            startedBy: "tap",
            entry: entry
        )
        activeSession = session
        sessionState = .reading
        lastStartedBy = "tap"
        lastEntryPoint = entry

        do {
            try persistCurrentEnvelopeToDisk()
            activeErrorKey = nil
            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: nowISO,
                cause: "book.add",
                recordReload: true
            )
            return true
        } catch {
            books = prevBooks
            activeSession = prevSession
            sessionState = prevState
            activeErrorKey = "common.save.error"
            return false
        }
    }

    @discardableResult
    public func populateTitlePendingBook(
        isbn13: String?,
        title: String,
        author: String,
        publisher: String?,
        label: String?,
        publishedYear: Int?,
        ndc: String? = nil
    ) -> Bool {
        guard let idx = books.firstIndex(where: { $0.isTitlePending }) else {
            return false
        }
        let cleanTitle: String
        switch InputValidator.validateTitle(title) {
        case .failure:
            activeErrorKey = "book.title.invalid"
            return false
        case .success(let t):
            cleanTitle = t
        }
        let cleanAuthor: String
        switch InputValidator.validateAuthor(author) {
        case .failure:
            activeErrorKey = "book.author.invalid"
            return false
        case .success(let a):
            cleanAuthor = a
        }
        if consumeFailSave(for: "book.update") {
            activeErrorKey = "common.save.error"
            return false
        }
        let prevBooks = books
        let nowISO = clock.nowISO8601()
        books[idx].isTitlePending = false
        books[idx].isbn13 = isbn13?.isEmpty == true ? nil : isbn13
        books[idx].title = cleanTitle
        books[idx].author = cleanAuthor
        books[idx].publisher = publisher?.isEmpty == true ? nil : publisher
        books[idx].label = label?.isEmpty == true ? nil : label
        books[idx].publishedYear = publishedYear
        if let ndc {
            books[idx].ndc = ndc
        }
        books[idx].updatedAt = nowISO

        do {
            try persistCurrentEnvelopeToDisk()
            activeErrorKey = nil
            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: nowISO,
                cause: "book.setTitle",
                recordReload: true
            )
            return true
        } catch {
            books = prevBooks
            activeErrorKey = "common.save.error"
            return false
        }
    }

    @discardableResult
    public func updateBook(
        bookId: UUID,
        title: String,
        author: String,
        publisher: String? = nil,
        label: String? = nil,
        publishedYear: Int? = nil,
        isbn13: String? = nil,
        isEbook: Bool? = nil,
        progressUnit: ProgressUnit? = nil
    ) -> Result<BookSnapshot, ValidationError> {
        guard let idx = books.firstIndex(where: { $0.id == bookId }) else {
            return .failure(.empty)
        }
        let cleanTitle: String
        switch InputValidator.validateTitle(title) {
        case .failure(let err):
            activeErrorKey = "book.title.invalid"
            return .failure(err)
        case .success(let t):
            cleanTitle = t
        }
        let cleanAuthor: String
        switch InputValidator.validateAuthor(author) {
        case .failure(let err):
            activeErrorKey = "book.author.invalid"
            return .failure(err)
        case .success(let a):
            cleanAuthor = a
        }

        if consumeFailSave(for: "book.update") {
            activeErrorKey = "common.save.error"
            return .failure(.empty)
        }
        let prevBooks = books
        let nowISO = clock.nowISO8601()
        books[idx].title = cleanTitle
        books[idx].author = cleanAuthor
        books[idx].isTitlePending = false
        if let publisher {
            books[idx].publisher = publisher.isEmpty ? nil : publisher
        }
        if let label {
            books[idx].label = label.isEmpty ? nil : label
        }
        if let publishedYear {
            books[idx].publishedYear = publishedYear
        }
        if let isbn13 {
            books[idx].isbn13 = isbn13.isEmpty ? nil : isbn13
        }
        if let isEbook {
            books[idx].isEbook = isEbook
        }
        if let progressUnit {
            books[idx].progressUnit = progressUnit
        }
        books[idx].updatedAt = nowISO

        do {
            try persistCurrentEnvelopeToDisk()
            activeErrorKey = nil
            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: nowISO,
                cause: "book.update",
                recordReload: true
            )
            return .success(books[idx])
        } catch {
            books = prevBooks
            activeErrorKey = "common.save.error"
            return .failure(.empty)
        }
    }

    @discardableResult
    public func switchToCurrentBook(bookId: UUID) -> Bool {
        guard let targetIdx = books.firstIndex(where: { $0.id == bookId }) else {
            return false
        }
        if consumeFailSave(for: "book.status") {
            activeErrorKey = "common.save.error"
            return false
        }
        let prevBooks = books
        let nowISO = clock.nowISO8601()
        for idx in books.indices {
            if idx == targetIdx {
                books[idx].status = .current
                books[idx].updatedAt = nowISO
            } else if books[idx].status.isCurrentReading {
                books[idx].status = .tsundoku
                books[idx].tsundokuAt = nowISO
                books[idx].updatedAt = nowISO
            }
        }
        do {
            try persistCurrentEnvelopeToDisk()
            activeErrorKey = nil
            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: nowISO,
                cause: "book.switch",
                recordReload: true
            )
            return true
        } catch {
            books = prevBooks
            activeErrorKey = "common.save.error"
            return false
        }
    }

    @discardableResult
    public func markBookFinished(bookId: UUID) -> Bool {
        guard let targetIdx = books.firstIndex(where: { $0.id == bookId }) else {
            return false
        }
        if consumeFailSave(for: "book.status") {
            activeErrorKey = "common.save.error"
            return false
        }
        let prevBooks = books
        let nowISO = clock.nowISO8601()
        books[targetIdx].status = .finished
        books[targetIdx].finishedAt = nowISO
        books[targetIdx].updatedAt = nowISO
        do {
            try persistCurrentEnvelopeToDisk()
            activeErrorKey = nil
            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: nowISO,
                cause: "book.finish",
                recordReload: true
            )
            return true
        } catch {
            books = prevBooks
            activeErrorKey = "common.save.error"
            return false
        }
    }

    @discardableResult
    public func deleteBook(bookId: UUID) -> Bool {
        guard books.contains(where: { $0.id == bookId }) else {
            return false
        }
        if consumeFailSave(for: "book.delete") {
            activeErrorKey = "common.save.error"
            return false
        }
        let prevBooks = books
        let prevRecords = records
        let nowISO = clock.nowISO8601()
        books.removeAll { $0.id == bookId }
        records.removeAll { $0.bookId == bookId }
        do {
            try persistCurrentEnvelopeToDisk()
            activeErrorKey = nil
            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: nowISO,
                cause: "book.delete",
                recordReload: true
            )
            return true
        } catch {
            books = prevBooks
            records = prevRecords
            activeErrorKey = "common.save.error"
            return false
        }
    }

    // MARK: - Reading Record Editing & Deletion

    @discardableResult
    public func updateRecordMinutes(recordId: UUID, rawMinutes: String) -> Result<ReadingRecordSnapshot, ValidationError> {
        guard let idx = records.firstIndex(where: { $0.id == recordId }) else {
            return .failure(.empty)
        }
        switch InputValidator.validateMinutes(rawMinutes) {
        case .failure(let err):
            activeErrorKey = "record.minutes.invalid"
            return .failure(err)
        case .success(let validMinutes):
            if consumeFailSave(for: "record.update") {
                activeErrorKey = "common.save.error"
                return .failure(.empty)
            }
            let prevRecords = records
            records[idx].durationMinutes = validMinutes
            do {
                try persistCurrentEnvelopeToDisk()
                activeErrorKey = nil
                return .success(records[idx])
            } catch {
                records = prevRecords
                activeErrorKey = "common.save.error"
                return .failure(.empty)
            }
        }
    }

    @discardableResult
    public func deleteRecord(recordId: UUID) -> Bool {
        guard records.contains(where: { $0.id == recordId }) else {
            return false
        }
        if consumeFailSave(for: "record.delete") {
            activeErrorKey = "common.save.error"
            return false
        }
        let prevRecords = records
        records.removeAll { $0.id == recordId }
        do {
            try persistCurrentEnvelopeToDisk()
            activeErrorKey = nil
            return true
        } catch {
            records = prevRecords
            activeErrorKey = "common.save.error"
            return false
        }
    }

    // MARK: - Entry URL & App Lifecycle

    public func openEntryURL(_ entryRaw: String) {
        let entry = SessionEntryPoint(rawValue: entryRaw) ?? .app
        pendingEntryURL = (entry: entry, openedAt: clock.now())
        lastEntryPoint = entry
    }

    public func handleDidEnterBackground() {
        if sessionState == .idle {
            pendingEntryURL = nil
        }
    }

    public func handleDidBecomeActive() {
        if pendingRefundOnActivate {
            pendingRefundOnActivate = false
            settings.isPlusPurchased = false
            settings.appearanceID = .default
            try? persistCurrentEnvelopeToDisk()
            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: clock.nowISO8601(),
                cause: "store.refund",
                recordReload: true
            )
        }

        let now = clock.now()
        var cleanedUpUnread = false
        for idx in liveActivities.indices.reversed() {
            let item = liveActivities[idx]
            if item.state == "started",
               let staleStr = item.staleDate,
               let staleDate = NightDateCalculator.parseISO8601(staleStr),
               now >= staleDate {
                liveActivities.remove(at: idx)
                liveActivityRequests.append(
                    LiveActivityRequestLog(
                        kind: "endUnread",
                        source: "foreground",
                        timestamp: clock.nowISO8601()
                    )
                )
                cleanedUpUnread = true
            }
        }

        if needsRescheduleOnActivate || cleanedUpUnread {
            needsRescheduleOnActivate = false
            scheduleNextEntryLiveActivityIfNeeded(source: "foreground")
        }
    }

    private func resolveEntryForSessionStart() -> SessionEntryPoint {
        if let pending = pendingEntryURL {
            pendingEntryURL = nil
            let elapsed = clock.now().timeIntervalSince(pending.openedAt)
            if elapsed >= 0 && elapsed <= 300 {
                return pending.entry
            }
        }
        return .app
    }

    // MARK: - Orientation & Flip-to-Start

    public func setOrientation(_ orientation: String, isInitialLaunch: Bool = false) {
        if isInitialLaunch {
            currentOrientation = orientation
            wasLaunchedFaceDown = (orientation == "faceDown")
            faceDownEnteredAtMs = nil
            return
        }

        if orientation != "faceDown" {
            currentOrientation = orientation
            wasLaunchedFaceDown = false
            faceDownEnteredAtMs = nil
            return
        }

        currentOrientation = "faceDown"
        guard !wasLaunchedFaceDown, isFlipMonitoringOn else {
            faceDownEnteredAtMs = nil
            return
        }
        faceDownEnteredAtMs = clock.currentOffsetMilliseconds
    }

    public func evaluateFlipOnClockAdvance() {
        guard currentOrientation == "faceDown",
              !wasLaunchedFaceDown,
              let enteredMs = faceDownEnteredAtMs,
              isFlipMonitoringOn else {
            return
        }
        let elapsedMs = clock.currentOffsetMilliseconds - enteredMs
        if elapsedMs >= 1000 {
            faceDownEnteredAtMs = nil
            _ = startReadingSession(startedBy: "flip", explicitEntry: nil)
        }
    }

    // MARK: - Reading Session Start & End

    @discardableResult
    public func startReadingSession(
        startedBy: String = "tap",
        explicitEntry: SessionEntryPoint? = nil
    ) -> Bool {
        guard sessionState == .idle, let book = currentBook else {
            return false
        }
        if let lastAction = lastSessionActionAt {
            let diff = abs(clock.now().timeIntervalSince(lastAction))
            if diff > 0 && diff < 0.3 {
                return false
            }
        }

        if consumeFailSave(for: "session.start") {
            activeErrorKey = "session.start.error"
            return false
        }

        let nowISO = clock.nowISO8601()
        let entry = explicitEntry ?? resolveEntryForSessionStart()
        var hadCancelledTonight = false

        var activeLAId: String?
        if areActivitiesEnabled {
            let source = startedBy == "intent" ? "intent" : "app"
            if let startedIdx = liveActivities.firstIndex(where: { $0.state == "started" }) {
                liveActivities[startedIdx].state = "reading"
                liveActivities[startedIdx].startedAt = nowISO
                liveActivities[startedIdx].line = nil
                liveActivities[startedIdx].progressText = nil
                liveActivities[startedIdx].endButtonIdentifier = "liveActivity.end"
                liveActivities[startedIdx].endButtonLabel = "終える"
                liveActivities[startedIdx].endIntentName = "EndReadingFromActivityIntent"
                activeLAId = liveActivities[startedIdx].id
                liveActivityRequests.append(
                    LiveActivityRequestLog(kind: "updateToReading", source: source, timestamp: nowISO)
                )
            } else {
                if let scheduledIdx = liveActivities.firstIndex(where: { $0.state == "scheduled" }) {
                    liveActivities.remove(at: scheduledIdx)
                    hadCancelledTonight = true
                    liveActivityRequests.append(
                        LiveActivityRequestLog(kind: "cancel", source: source, timestamp: nowISO)
                    )
                } else if isBeforeEntryTimeTonight(clock.now()) {
                    hadCancelledTonight = true
                }

                if startedBy == "intent" || isBeforeEntryTimeTonight(clock.now()) {
                    if failStartImmediateCount > 0 {
                        failStartImmediateCount -= 1
                        liveActivityRequests.append(
                            LiveActivityRequestLog(kind: "startImmediate", source: source, timestamp: nowISO, succeeded: false)
                        )
                    } else {
                        let newId = "la-reading-\(liveActivityRequests.count + 1)"
                        let displayTitle = settings.hideOnWidgets ? "しおり" : (book.title.isEmpty ? "しおり" : book.title)
                        let item = LiveActivityItemState(
                            id: newId,
                            kind: "immediate",
                            state: "reading",
                            staleDate: nextFourAMISO(from: clock.now()),
                            title: displayTitle,
                            line: nil,
                            progressText: nil,
                            startedAt: nowISO,
                            endButtonIdentifier: "liveActivity.end",
                            endButtonLabel: "終える",
                            endIntentName: "EndReadingFromActivityIntent"
                        )
                        liveActivities.append(item)
                        activeLAId = newId
                        liveActivityRequests.append(
                            LiveActivityRequestLog(kind: "startImmediate", source: source, timestamp: nowISO, succeeded: true)
                        )
                    }
                }
            }
        }

        let session = ActiveSessionSnapshot(
            bookId: book.id,
            startedAt: nowISO,
            startedBy: startedBy,
            entry: entry,
            liveActivityId: activeLAId,
            hadCancelledTonightSchedule: hadCancelledTonight
        )
        let prevSession = activeSession
        let prevState = sessionState
        activeSession = session
        sessionState = .reading
        lastStartedBy = startedBy
        lastEntryPoint = entry
        activeErrorKey = nil
        activeNoticeKey = nil
        lastSessionActionAt = clock.now()

        do {
            try persistCurrentEnvelopeToDisk()
            if startedBy == "flip" {
                hapticCount += 1
                announcements["session.flipStarted.announcement", default: 0] += 1
            }
            return true
        } catch {
            activeSession = prevSession
            sessionState = prevState
            activeErrorKey = "session.start.error"
            return false
        }
    }

    @discardableResult
    public func endReadingSession(source: String = "app") -> EndSessionResult {
        guard sessionState == .reading, let session = activeSession else {
            return .ignoredDuplicate
        }
        clock.beginInterval(.endToMark)
        defer {
            _ = clock.endInterval(.endToMark)
        }

        let startDate = NightDateCalculator.parseISO8601(session.startedAt) ?? clock.now()
        let endDate = clock.now()
        let elapsedSeconds = endDate.timeIntervalSince(startDate)

        if elapsedSeconds < 0 {
            activeSession = nil
            sessionState = .idle
            activeNoticeKey = "session.invalidTime"
            notices["session.invalidTime", default: 0] += 1
            try? persistCurrentEnvelopeToDisk()
            return .discardedInvalidTime
        }

        if elapsedSeconds < 60 {
            let hadCancelledTonight = session.hadCancelledTonightSchedule
            activeSession = nil
            sessionState = .idle
            activeNoticeKey = "session.tooShort"
            notices["session.tooShort", default: 0] += 1
            liveActivities.removeAll { $0.state == "reading" }
            if hadCancelledTonight {
                scheduleEntryLiveActivityForTonightOrTomorrow(forceTonightIfBeforeEntry: true, source: source)
            }
            try? persistCurrentEnvelopeToDisk()
            return .discardedTooShort
        }

        if consumeFailSave(for: "session.end") {
            activeErrorKey = "session.save.error"
            return .failedSave
        }

        let rawMinutes = Int(floor(elapsedSeconds / 60.0))
        let isCapped = elapsedSeconds >= 86460.0 || rawMinutes > 1440
        let finalMinutes = min(1440, max(1, rawMinutes))
        if isCapped {
            activeNoticeKey = "session.capped"
            notices["session.capped", default: 0] += 1
        } else {
            activeNoticeKey = nil
        }

        let nightDate = clock.nightDate(for: startDate)
        let book = books.first { $0.id == session.bookId } ?? currentBook
        let prevProgress: Int?
        let unit = book?.progressUnit ?? .page
        switch unit {
        case .page: prevProgress = book?.currentPage
        case .location: prevProgress = book?.currentLocation
        case .percent: prevProgress = book?.currentPercent
        }

        let record = ReadingRecordSnapshot(
            id: UUID(),
            bookId: session.bookId,
            startedAt: session.startedAt,
            endedAt: clock.nowISO8601(),
            durationMinutes: finalMinutes,
            nightDate: nightDate,
            entry: session.entry,
            progressUnit: unit,
            startPage: unit == .page ? prevProgress : nil,
            endPage: nil,
            startLocation: unit == .location ? prevProgress : nil,
            endLocation: nil,
            startPercent: unit == .percent ? prevProgress : nil,
            endPercent: nil,
            savedLine: nil
        )

        let prevRecords = records
        let prevSession = activeSession
        let prevSettings = settings

        records.append(record)
        activeSession = nil
        sessionState = .idle
        pendingMarkRecordId = record.id
        pendingMarkPreviousProgress = prevProgress
        pendingMarkPreviousUnit = unit
        latestResultSummary = "\(finalMinutes)分"
        activeErrorKey = nil

        let totalDistinctNights = Set(records.map(\.nightDate)).count
        if settings.firstNightCompletedAt == nil && totalDistinctNights >= 1 {
            settings.firstNightCompletedAt = clock.nowISO8601()
        }
        if settings.seventhNightReachedAt == nil && totalDistinctNights >= 7 {
            settings.seventhNightReachedAt = clock.nowISO8601()
        }

        do {
            try persistCurrentEnvelopeToDisk()
            updateLiveActivityOnSessionEnd(minutes: finalMinutes, progressText: nil, source: source)
            return .saved(record: record, capped: isCapped)
        } catch {
            records = prevRecords
            activeSession = prevSession
            settings = prevSettings
            sessionState = .reading
            activeErrorKey = "session.save.error"
            return .failedSave
        }
    }

    // MARK: - Bookmark Saving (S-3 -> S-4)

    public func completeMarkLater() {
        if let recId = pendingMarkRecordId,
           let rec = records.first(where: { $0.id == recId }) {
            latestResultSummary = "\(rec.durationMinutes)分"
            updateLiveActivityOnSessionEnd(minutes: rec.durationMinutes, progressText: nil, source: "mark.later")
        }
        pendingMarkRecordId = nil
        pendingMarkPreviousProgress = nil
        pendingMarkPreviousUnit = nil
        scheduleNextEntryLiveActivityIfNeeded(source: "mark.later")
    }

    @discardableResult
    public func saveBookmark(
        mode: String,
        rawLine: String?,
        rawProgress: String?
    ) -> SaveMarkResult {
        guard let bookIdx = books.firstIndex(where: { $0.status.isCurrentReading }) else {
            return .failedSave
        }
        let book = books[bookIdx]
        let unit = book.progressUnit

        var validatedLine: String?
        if mode != "pageOnly" {
            let lineInput = rawLine ?? ""
            switch InputValidator.validateLine(lineInput) {
            case .failure:
                activeErrorKey = "mark.line.invalid"
                return .invalidLine
            case .success(let cleanLine):
                validatedLine = cleanLine
            }
        } else {
            validatedLine = nil
        }

        var validatedProgress: Int?
        let trimmedProgress = (rawProgress ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if mode == "pageOnly" || !trimmedProgress.isEmpty {
            let validation: Result<Int, ValidationError>
            switch unit {
            case .page:
                validation = InputValidator.validatePage(trimmedProgress)
            case .location:
                validation = InputValidator.validateLocation(trimmedProgress)
            case .percent:
                validation = InputValidator.validatePercent(trimmedProgress)
            }
            switch validation {
            case .failure:
                activeErrorKey = "mark.page.invalid"
                return .invalidPage
            case .success(let val):
                validatedProgress = val
            }
        }

        if consumeFailSave(for: "mark.save") {
            activeErrorKey = "common.save.error"
            return .failedSave
        }

        let prevBooks = books
        let prevRecords = records
        let prevSettings = settings
        let nowISO = clock.nowISO8601()

        let oldProgress: Int?
        switch unit {
        case .page: oldProgress = pendingMarkPreviousProgress ?? book.currentPage
        case .location: oldProgress = pendingMarkPreviousProgress ?? book.currentLocation
        case .percent: oldProgress = pendingMarkPreviousProgress ?? book.currentPercent
        }

        if mode == "pageOnly" {
            books[bookIdx].lastSavedLine = nil
        } else if let validatedLine {
            books[bookIdx].lastSavedLine = validatedLine
        }

        if let validatedProgress {
            switch unit {
            case .page:
                books[bookIdx].currentPage = validatedProgress
            case .location:
                books[bookIdx].currentLocation = validatedProgress
            case .percent:
                books[bookIdx].currentPercent = validatedProgress
            }
        }
        books[bookIdx].updatedAt = nowISO

        var sessionMinutes: Int?
        if let recId = pendingMarkRecordId,
           let recIdx = records.firstIndex(where: { $0.id == recId }) {
            sessionMinutes = records[recIdx].durationMinutes
            if let validatedLine {
                records[recIdx].savedLine = validatedLine
            }
            if let validatedProgress {
                switch unit {
                case .page: records[recIdx].endPage = validatedProgress
                case .location: records[recIdx].endLocation = validatedProgress
                case .percent: records[recIdx].endPercent = validatedProgress
                }
            }
        }

        var triggeredGuide = false
        if validatedLine != nil && !settings.widgetGuideShown {
            settings.widgetGuideShown = true
            showWidgetGuide = true
            triggeredGuide = true
            notices["widgetGuide", default: 0] += 1
        }

        do {
            try persistCurrentEnvelopeToDisk()
            activeErrorKey = nil

            let newProgressVal: Int?
            switch unit {
            case .page: newProgressVal = books[bookIdx].currentPage
            case .location: newProgressVal = books[bookIdx].currentLocation
            case .percent: newProgressVal = books[bookIdx].currentPercent
            }
            let newProgStr = InputValidator.formatProgressDisplay(
                unit: unit,
                page: unit == .page ? newProgressVal : nil,
                location: unit == .location ? newProgressVal : nil,
                percent: unit == .percent ? newProgressVal.map(Double.init) : nil
            )

            var summary: String?
            if let mins = sessionMinutes {
                if let validatedProgress, let newDisp = newProgStr {
                    let oldDisp = InputValidator.formatProgressDisplay(
                        unit: unit,
                        page: unit == .page ? oldProgress : nil,
                        location: unit == .location ? oldProgress : nil,
                        percent: unit == .percent ? oldProgress.map(Double.init) : nil
                    )
                    if let oldDisp, oldProgress != validatedProgress {
                        summary = "\(oldDisp) → \(newDisp)　\(mins)分"
                    } else {
                        summary = "\(newDisp)　\(mins)分"
                    }
                } else {
                    summary = "\(mins)分"
                }
                latestResultSummary = summary
                updateLiveActivityOnSessionEnd(minutes: mins, progressText: newProgStr, source: "mark.save")
                scheduleNextEntryLiveActivityIfNeeded(source: "mark.save")
            } else {
                latestResultSummary = nil
            }

            pendingMarkRecordId = nil
            pendingMarkPreviousProgress = nil
            pendingMarkPreviousUnit = nil

            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: nowISO,
                cause: "mark.save",
                recordReload: true
            )

            return .saved(summaryText: summary, showedWidgetGuide: triggeredGuide)
        } catch {
            books = prevBooks
            records = prevRecords
            settings = prevSettings
            activeErrorKey = "common.save.error"
            return .failedSave
        }
    }

    // MARK: - Colophon OCR Update (AC-113)

    @discardableResult
    public func applyColophonOCR(bookId: UUID, info: ColophonExtractionResult) -> Bool {
        guard let idx = books.firstIndex(where: { $0.id == bookId }) else {
            return false
        }
        if consumeFailSave(for: "book.update") {
            activeErrorKey = "common.save.error"
            return false
        }
        let prevBooks = books
        if let author = info.author, !author.isEmpty {
            books[idx].author = author
        }
        if let publisher = info.publisher, !publisher.isEmpty {
            books[idx].publisher = publisher
        }
        if let label = info.label, !label.isEmpty {
            books[idx].label = label
        }
        if let year = info.publishedYear {
            books[idx].publishedYear = year
        }
        if let isbn13 = info.isbn13, !isbn13.isEmpty {
            books[idx].isbn13 = isbn13
        }
        books[idx].updatedAt = clock.nowISO8601()
        do {
            try persistCurrentEnvelopeToDisk()
            activeErrorKey = nil
            return true
        } catch {
            books = prevBooks
            activeErrorKey = "common.save.error"
            return false
        }
    }

    // MARK: - Settings & StoreKit 2 (S-10, S-11)

    public func setFlipToStartEnabled(_ enabled: Bool) {
        settings.flipToStartEnabled = enabled
        try? persistCurrentEnvelopeToDisk()
    }

    public func setHideOnWidgets(_ hide: Bool) {
        settings.hideOnWidgets = hide
        try? persistCurrentEnvelopeToDisk()
        _ = try? snapshotStore.writeSnapshot(
            currentBook: currentBook,
            settings: settings,
            nowISO: clock.nowISO8601(),
            cause: "settings.hideOnWidgets",
            recordReload: true
        )
        refreshScheduledLiveActivityPrivacy()
    }

    public func setEntryTime(_ entryTime: String) {
        settings.entryTime = entryTime
        try? persistCurrentEnvelopeToDisk()
        scheduleNextEntryLiveActivityIfNeeded(source: "settings.entryTime")
    }

    public func selectAppearance(_ appearance: AppearanceID) {
        if appearance == .default || settings.isPlusPurchased {
            settings.appearanceID = appearance
            previewAppearanceID = nil
            try? persistCurrentEnvelopeToDisk()
            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: clock.nowISO8601(),
                cause: "settings.appearance",
                recordReload: true
            )
        } else {
            previewAppearanceID = appearance
            if !storeCanMakePayments {
                storeStatusMessageKey = "store.unavailable"
            } else if !storeProductLoadAvailable {
                storeStatusMessageKey = "store.offline"
            } else {
                storeStatusMessageKey = nil
            }
        }
    }

    public func closeStorePreview() {
        previewAppearanceID = nil
        storeStatusMessageKey = nil
    }

    @discardableResult
    public func purchasePlus() -> StorePurchaseResult {
        guard storeCanMakePayments else {
            storeStatusMessageKey = "store.unavailable"
            return .unavailable
        }
        guard storeProductLoadAvailable else {
            storeStatusMessageKey = "store.offline"
            return .offline
        }
        switch storePurchaseOutcome {
        case "success":
            settings.isPlusPurchased = true
            if let preview = previewAppearanceID {
                settings.appearanceID = preview
            }
            previewAppearanceID = nil
            storeStatusMessageKey = nil
            try? persistCurrentEnvelopeToDisk()
            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: clock.nowISO8601(),
                cause: "store.purchase",
                recordReload: true
            )
            return .success
        case "userCancelled":
            storeStatusMessageKey = nil
            return .userCancelled
        default:
            storeStatusMessageKey = "store.purchase.error"
            return .error
        }
    }

    @discardableResult
    public func restorePurchases() -> StoreRestoreResult {
        if storeRestoreOutcome == "hasEntitlement" {
            settings.isPlusPurchased = true
            if let preview = previewAppearanceID {
                settings.appearanceID = preview
                previewAppearanceID = nil
            }
            storeStatusMessageKey = "store.restore.done"
            try? persistCurrentEnvelopeToDisk()
            _ = try? snapshotStore.writeSnapshot(
                currentBook: currentBook,
                settings: settings,
                nowISO: clock.nowISO8601(),
                cause: "store.restore",
                recordReload: true
            )
            return .restored
        } else {
            settings.isPlusPurchased = false
            storeStatusMessageKey = "store.restore.none"
            try? persistCurrentEnvelopeToDisk()
            return .none
        }
    }

    public func triggerStoreRefund() {
        pendingRefundOnActivate = true
    }

    // MARK: - Live Activity Scheduling & Transitions

    public func configureLiveActivity(from jsonString: String?) {
        guard let jsonString, !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        if let enabled = obj["areActivitiesEnabled"] as? Bool {
            areActivitiesEnabled = enabled
        }
        if let failSched = obj["failScheduleCount"] as? Int {
            failScheduleCount = failSched
        }
        if let failImm = obj["failStartImmediateCount"] as? Int {
            failStartImmediateCount = failImm
        }
        if let initial = obj["initialActivities"] as? [[String: Any]] {
            liveActivities = initial.map { item in
                LiveActivityItemState(
                    id: (item["id"] as? String) ?? "la-init",
                    kind: (item["kind"] as? String) ?? "scheduled",
                    state: (item["state"] as? String) ?? "scheduled",
                    scheduledFor: item["scheduledFor"] as? String,
                    staleDate: item["staleDate"] as? String,
                    url: (item["url"] as? String) ?? "yomuma://open?entry=live_activity",
                    title: (item["title"] as? String) ?? "しおり",
                    line: item["line"] as? String,
                    progressText: item["progressText"] as? String,
                    startedAt: item["startedAt"] as? String,
                    endButtonIdentifier: item["endButtonIdentifier"] as? String,
                    endButtonLabel: item["endButtonLabel"] as? String,
                    endIntentName: item["endIntentName"] as? String
                )
            }
        }
    }

    public func transitionLiveActivity(_ targetState: String) {
        let nowISO = clock.nowISO8601()
        if targetState == "dismissedBySystem" {
            liveActivities.removeAll()
            liveActivityRequests.append(
                LiveActivityRequestLog(kind: "dismissedBySystem", source: "system", timestamp: nowISO)
            )
            return
        }
        if targetState == "started" {
            if liveActivities.isEmpty {
                scheduleNextEntryLiveActivityIfNeeded(source: "transition")
            }
            for idx in liveActivities.indices {
                liveActivities[idx].state = "started"
            }
        }
    }

    public func scheduleNextEntryLiveActivityIfNeeded(source: String) {
        scheduleEntryLiveActivityForTonightOrTomorrow(forceTonightIfBeforeEntry: false, source: source)
    }

    private func scheduleEntryLiveActivityForTonightOrTomorrow(forceTonightIfBeforeEntry: Bool, source: String) {
        guard areActivitiesEnabled, let book = currentBook else {
            return
        }
        let now = clock.now()
        let nowISO = clock.nowISO8601()

        if failScheduleCount > 0 {
            failScheduleCount -= 1
            needsRescheduleOnActivate = true
            liveActivityRequests.append(
                LiveActivityRequestLog(kind: "schedule", source: source, timestamp: nowISO, succeeded: false)
            )
            return
        }

        let (scheduledISO, staleISO) = computeNextEntrySchedule(from: now, forceTonight: forceTonightIfBeforeEntry)
        liveActivities.removeAll { $0.state == "scheduled" }

        let displayTitle = settings.hideOnWidgets ? "しおり" : (book.title.isEmpty ? "しおり" : book.title)
        let displayLine = settings.hideOnWidgets ? nil : book.lastSavedLine
        let progressText = InputValidator.formatProgressDisplay(
            unit: book.progressUnit,
            page: book.currentPage,
            location: book.currentLocation,
            percent: book.currentPercent.map(Double.init)
        )

        let item = LiveActivityItemState(
            id: "la-sched-\(liveActivityRequests.count + 1)",
            kind: "scheduled",
            state: "scheduled",
            scheduledFor: scheduledISO,
            staleDate: staleISO,
            url: "yomuma://open?entry=live_activity",
            title: displayTitle,
            line: displayLine,
            progressText: progressText
        )
        liveActivities.append(item)
        liveActivityRequests.append(
            LiveActivityRequestLog(
                kind: "schedule",
                source: source,
                timestamp: nowISO,
                scheduledFor: scheduledISO,
                succeeded: true
            )
        )
    }

    private func updateLiveActivityOnSessionEnd(minutes: Int, progressText: String?, source: String) {
        guard areActivitiesEnabled else { return }
        for idx in liveActivities.indices where liveActivities[idx].state == "reading" || liveActivities[idx].state == "ended" {
            liveActivities[idx].state = "ended"
            if let progressText {
                liveActivities[idx].progressText = progressText
                liveActivities[idx].summaryText = "\(progressText)　\(minutes)分"
            } else {
                liveActivities[idx].summaryText = "\(minutes)分"
            }
        }
    }

    private func refreshScheduledLiveActivityPrivacy() {
        guard let book = currentBook else { return }
        for idx in liveActivities.indices {
            if settings.hideOnWidgets {
                liveActivities[idx].title = "しおり"
                liveActivities[idx].line = nil
            } else {
                liveActivities[idx].title = book.title.isEmpty ? "しおり" : book.title
                liveActivities[idx].line = book.lastSavedLine
            }
        }
    }

    private func parseEntryHourMinute() -> (hour: Int, minute: Int) {
        let parts = settings.entryTime.split(separator: ":").compactMap { Int($0) }
        if parts.count == 2 {
            return (parts[0], parts[1])
        }
        return (21, 0)
    }

    private func isBeforeEntryTimeTonight(_ date: Date) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = clock.timeZone()
        let comps = cal.dateComponents([.hour, .minute], from: date)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        if hour < 4 {
            return false
        }
        let entry = parseEntryHourMinute()
        return (hour * 60 + minute) < (entry.hour * 60 + entry.minute)
    }

    private func computeNextEntrySchedule(from date: Date, forceTonight: Bool) -> (scheduledISO: String, staleISO: String) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = clock.timeZone()
        let entry = parseEntryHourMinute()

        let currentHour = cal.component(.hour, from: date)
        let baseDay: Date
        if currentHour < 4 {
            baseDay = date
        } else if forceTonight && isBeforeEntryTimeTonight(date) {
            baseDay = date
        } else {
            baseDay = cal.date(byAdding: .day, value: 1, to: date) ?? date
        }

        var schedComps = cal.dateComponents([.year, .month, .day], from: baseDay)
        schedComps.hour = entry.hour
        schedComps.minute = entry.minute
        schedComps.second = 0
        let schedDate = cal.date(from: schedComps) ?? date
        let staleDate = cal.date(byAdding: .day, value: 1, to: schedDate).flatMap { nextDay in
            var sComps = cal.dateComponents([.year, .month, .day], from: nextDay)
            sComps.hour = 4
            sComps.minute = 0
            sComps.second = 0
            return cal.date(from: sComps)
        } ?? schedDate.addingTimeInterval(7 * 3600)

        return (clock.formatISO8601(schedDate), clock.formatISO8601(staleDate))
    }

    private func nextFourAMISO(from date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = clock.timeZone()
        let hour = cal.component(.hour, from: date)
        let targetDay = hour < 4 ? date : (cal.date(byAdding: .day, value: 1, to: date) ?? date)
        var comps = cal.dateComponents([.year, .month, .day], from: targetDay)
        comps.hour = 4
        comps.minute = 0
        comps.second = 0
        let fourAM = cal.date(from: comps) ?? date.addingTimeInterval(6 * 3600)
        return clock.formatISO8601(fourAM)
    }

    // MARK: - External App Intents Execution (H20)

    public func configureIntents(from jsonString: String?) {
        guard let jsonString, !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        if let canFG = obj["canContinueInForeground"] as? Bool {
            intentDefaultCanContinueInForeground = canFG
        }
    }

    @discardableResult
    public func handleExternalIntent(_ rawPayload: String) -> IntentInvocationLog {
        let parts = rawPayload.split(separator: ":", maxSplits: 1).map(String.init)
        let intentName = parts.first ?? rawPayload
        let explicitFG: Bool?
        if parts.count == 2 {
            explicitFG = (parts[1] == "fg=1" || parts[1] == "true")
        } else {
            explicitFG = nil
        }
        let canContinueInForeground = explicitFG ?? intentDefaultCanContinueInForeground
        let nowISO = clock.nowISO8601()

        switch intentName {
        case "StartReadingIntent":
            clock.beginInterval(.intentStartRequest)
            clock.beginInterval(.intentStartForeground)
            defer {
                _ = clock.endInterval(.intentStartRequest)
                _ = clock.endInterval(.intentStartForeground)
            }

            if sessionState == .reading {
                let log = IntentInvocationLog(
                    intent: intentName,
                    outcome: "alreadyReading",
                    dialogKey: "intent.start.alreadyReading",
                    spokenText: "すでに読書中です。",
                    snippetTexts: ["すでに読書中です。"],
                    opensApp: false,
                    requestedForeground: false,
                    timestamp: nowISO
                )
                intentInvocations.append(log)
                return log
            }

            guard currentBook != nil else {
                let log = IntentInvocationLog(
                    intent: intentName,
                    outcome: "noCurrentBook",
                    dialogKey: "intent.start.noCurrent",
                    spokenText: "いま読んでいる本がありません。",
                    snippetTexts: ["いま読んでいる本がありません。"],
                    opensApp: true,
                    requestedForeground: true,
                    timestamp: nowISO
                )
                intentInvocations.append(log)
                return log
            }

            let prevReqCount = liveActivityRequests.count
            let started = startReadingSession(startedBy: "intent", explicitEntry: .intentStart)
            if !started {
                let log = IntentInvocationLog(
                    intent: intentName,
                    outcome: "error",
                    dialogKey: "session.start.error",
                    spokenText: "読書を始められませんでした。",
                    snippetTexts: ["読書を始められませんでした。"],
                    opensApp: false,
                    requestedForeground: false,
                    timestamp: nowISO
                )
                intentInvocations.append(log)
                return log
            }

            let newRequests = liveActivityRequests.dropFirst(prevReqCount)
            let startImmFailed = newRequests.contains { $0.kind == "startImmediate" && !$0.succeeded }
            let needsForegroundOpen = !areActivitiesEnabled || startImmFailed
            let opensApp = needsForegroundOpen && canContinueInForeground
            let requestedFG = needsForegroundOpen ? canContinueInForeground : false

            let log = IntentInvocationLog(
                intent: intentName,
                outcome: "started",
                dialogKey: "intent.start.started",
                spokenText: "読書を始めました。",
                snippetTexts: ["読書を始めました。"],
                opensApp: opensApp,
                requestedForeground: requestedFG,
                timestamp: nowISO
            )
            intentInvocations.append(log)
            return log

        case "EndReadingFromActivityIntent":
            let endRes = endReadingSession(source: "intent")
            switch endRes {
            case .saved:
                shouldPresentMarkInputAfterIntentEnd = canContinueInForeground
                if !canContinueInForeground {
                    completeMarkLater()
                }
                let log = IntentInvocationLog(
                    intent: intentName,
                    outcome: "ended",
                    dialogKey: "intent.end.completed",
                    spokenText: "読書を終えました。",
                    snippetTexts: ["読書を終えました。"],
                    opensApp: canContinueInForeground,
                    requestedForeground: canContinueInForeground,
                    timestamp: nowISO
                )
                intentInvocations.append(log)
                return log
            case .discardedTooShort:
                shouldPresentMarkInputAfterIntentEnd = false
                let log = IntentInvocationLog(
                    intent: intentName,
                    outcome: "tooShort",
                    dialogKey: "session.tooShort",
                    spokenText: "1分未満のため記録しませんでした。",
                    snippetTexts: ["1分未満のため記録しませんでした。"],
                    opensApp: canContinueInForeground,
                    requestedForeground: canContinueInForeground,
                    timestamp: nowISO
                )
                intentInvocations.append(log)
                return log
            case .failedSave:
                shouldPresentMarkInputAfterIntentEnd = false
                let log = IntentInvocationLog(
                    intent: intentName,
                    outcome: "error",
                    dialogKey: "session.save.error",
                    spokenText: "保存できませんでした。",
                    snippetTexts: ["保存できませんでした。"],
                    opensApp: canContinueInForeground,
                    requestedForeground: canContinueInForeground,
                    timestamp: nowISO
                )
                intentInvocations.append(log)
                return log
            default:
                let log = IntentInvocationLog(
                    intent: intentName,
                    outcome: "ignored",
                    dialogKey: "intent.end.ignored",
                    spokenText: "",
                    snippetTexts: [],
                    opensApp: false,
                    requestedForeground: false,
                    timestamp: nowISO
                )
                intentInvocations.append(log)
                return log
            }

        case "WhereStoppedIntent":
            if isStoreLoadFailed {
                let log = IntentInvocationLog(
                    intent: intentName,
                    outcome: "error",
                    dialogKey: "intent.whereStopped.error",
                    spokenText: "しおりを読み込めませんでした。",
                    snippetTexts: ["しおりを読み込めませんでした。"],
                    opensApp: false,
                    requestedForeground: false,
                    authenticationPolicy: "alwaysAllowed",
                    timestamp: nowISO
                )
                intentInvocations.append(log)
                return log
            }
            guard let book = currentBook else {
                let log = IntentInvocationLog(
                    intent: intentName,
                    outcome: "noCurrent",
                    dialogKey: "intent.whereStopped.noCurrent",
                    spokenText: "いま読んでいる本はまだありません。",
                    snippetTexts: ["いま読んでいる本はまだありません。"],
                    opensApp: false,
                    requestedForeground: false,
                    authenticationPolicy: "alwaysAllowed",
                    timestamp: nowISO
                )
                intentInvocations.append(log)
                return log
            }

            switch book.progressUnit {
            case .page:
                if let page = book.currentPage {
                    let spoken = "\(page)ページからです。"
                    let log = IntentInvocationLog(
                        intent: intentName,
                        outcome: "page",
                        dialogKey: "intent.whereStopped.page",
                        spokenText: spoken,
                        snippetTexts: [spoken],
                        opensApp: false,
                        requestedForeground: false,
                        authenticationPolicy: "alwaysAllowed",
                        timestamp: nowISO
                    )
                    intentInvocations.append(log)
                    return log
                }
            case .location:
                if let loc = book.currentLocation {
                    let spoken = "位置\(loc)からです。"
                    let log = IntentInvocationLog(
                        intent: intentName,
                        outcome: "location",
                        dialogKey: "intent.whereStopped.location",
                        spokenText: spoken,
                        snippetTexts: [spoken],
                        opensApp: false,
                        requestedForeground: false,
                        authenticationPolicy: "alwaysAllowed",
                        timestamp: nowISO
                    )
                    intentInvocations.append(log)
                    return log
                }
            case .percent:
                if let pct = book.currentPercent {
                    let spoken = "\(pct)パーセントからです。"
                    let log = IntentInvocationLog(
                        intent: intentName,
                        outcome: "percent",
                        dialogKey: "intent.whereStopped.percent",
                        spokenText: spoken,
                        snippetTexts: [spoken],
                        opensApp: false,
                        requestedForeground: false,
                        authenticationPolicy: "alwaysAllowed",
                        timestamp: nowISO
                    )
                    intentInvocations.append(log)
                    return log
                }
            }

            let log = IntentInvocationLog(
                intent: intentName,
                outcome: "noPage",
                dialogKey: "intent.whereStopped.noPage",
                spokenText: "まだページが記録されていません。",
                snippetTexts: ["まだページが記録されていません。"],
                opensApp: false,
                requestedForeground: false,
                authenticationPolicy: "alwaysAllowed",
                timestamp: nowISO
            )
            intentInvocations.append(log)
            return log

        case "ContinueReadingIntent":
            openEntryURL("intent_open")
            let log = IntentInvocationLog(
                intent: intentName,
                outcome: "opened",
                dialogKey: "intent.continue.opened",
                spokenText: "",
                snippetTexts: [],
                opensApp: true,
                requestedForeground: true,
                timestamp: nowISO
            )
            intentInvocations.append(log)
            return log

        default:
            let log = IntentInvocationLog(
                intent: intentName,
                outcome: "unknown",
                dialogKey: "intent.unknown",
                spokenText: "",
                snippetTexts: [],
                opensApp: false,
                requestedForeground: false,
                timestamp: nowISO
            )
            intentInvocations.append(log)
            return log
        }
    }

    // MARK: - Share Card, Recommendations, Awards, Outbound

    public func recordShareCard(for bookId: UUID) {
        guard let book = books.first(where: { $0.id == bookId }) else { return }
        let nights = distinctNightCount(for: bookId)
        let mins = totalMinutes(for: bookId)
        var texts = [book.title]
        if !book.author.isEmpty {
            texts.append(book.author)
        }
        texts.append("\(nights)晩")
        texts.append("\(mins)分")
        shareCards.append(
            ShareCardAuditItem(
                renderedTexts: texts,
                containsSavedLine: false,
                containsPhoto: false,
                containsReflection: false
            )
        )
    }

    public func recordRecommendationFeedback(chosenCategory: String?, allShownCategories: [String]) {
        for cat in allShownCategories {
            let isChosen = (cat == chosenCategory)
            switch cat {
            case "readers":
                if isChosen { settings.recommendationWeights.readers.chosen += 1 }
                else { settings.recommendationWeights.readers.skipped += 1 }
            case "author":
                if isChosen { settings.recommendationWeights.author.chosen += 1 }
                else { settings.recommendationWeights.author.skipped += 1 }
            case "award":
                if isChosen { settings.recommendationWeights.award.chosen += 1 }
                else { settings.recommendationWeights.award.skipped += 1 }
            default:
                break
            }
        }
        try? persistCurrentEnvelopeToDisk()
    }

    public func configureAwardsOverride(from jsonString: String?) {
        guard let jsonString, !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8) else {
            awardsMode = "bundled"
            activeAwards = AwardsCatalog.allBundledAwards()
            return
        }
        if let decoded = try? JSONDecoder().decode([H25AwardItem].self, from: data) {
            awardsMode = "override"
            activeAwards = decoded
        } else if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let itemsArr = obj["items"] as? [[String: Any]],
                  let itemsData = try? JSONSerialization.data(withJSONObject: itemsArr),
                  let decoded = try? JSONDecoder().decode([H25AwardItem].self, from: itemsData) {
            awardsMode = "override"
            activeAwards = decoded
        } else {
            awardsMode = "bundled"
            activeAwards = AwardsCatalog.allBundledAwards()
        }
    }

    public func openExternalURL(_ urlString: String) {
        openedURLs.append(H16OpenedURL(url: urlString, timestamp: clock.nowISO8601()))
    }

    // MARK: - Hook Readout Generators (11+ hooks)

    public func hookStateString() -> String {
        var dict: [String: String] = [
            "state": sessionState.rawValue,
            "startedBy": lastStartedBy,
            "entry": lastEntryPoint.rawValue,
            "haptic": "\(hapticCount)",
            "flipMonitoring": isFlipMonitoringOn ? "on" : "off",
            "idleTimerDisabled": "false",
            "proximity": "false"
        ]

        let announceStr = announcements.keys.sorted().compactMap { k in
            guard let v = announcements[k] else { return nil }
            return "\(k):\(v)"
        }.joined(separator: ",")
        dict["announce"] = announceStr

        let noticeStr = notices.keys.sorted().compactMap { k in
            guard let v = notices[k] else { return nil }
            return "\(k):\(v)"
        }.joined(separator: ",")
        dict["notice"] = noticeStr

        dict["widgetReloads"] = snapshotStore.formattedReloadsSummary()
        clock.appendLatencyStatePairs(into: &dict)

        return dict.keys.sorted().compactMap { key in
            guard let val = dict[key] else { return nil }
            return "\(key)=\(val)"
        }.joined(separator: ";")
    }

    public func hookStoreJSONString() -> String {
        let booksArray: [[String: Any]] = books.map { b in
            var dict: [String: Any] = [
                "id": b.id.uuidString,
                "title": b.title,
                "author": b.author,
                "status": b.status.rawValue,
                "isEbook": b.isEbook,
                "isTitlePending": b.isTitlePending,
                "progressUnit": b.progressUnit.rawValue,
                "createdAt": b.createdAt,
                "updatedAt": b.updatedAt
            ]
            if let isbn = b.isbn13 { dict["isbn13"] = isbn }
            if let pub = b.publisher { dict["publisher"] = pub }
            if let lbl = b.label { dict["label"] = lbl }
            if let yr = b.publishedYear { dict["publishedYear"] = yr }
            if let ser = b.seriesTitle { dict["seriesTitle"] = ser }
            if let vol = b.volumeNumber { dict["volumeNumber"] = vol }
            if let ndc = b.ndc { dict["ndc"] = ndc }
            if let p = b.currentPage {
                dict["page"] = p
                dict["currentPage"] = p
            }
            if let loc = b.currentLocation {
                dict["location"] = loc
                dict["currentLocation"] = loc
            }
            if let pct = b.currentPercent {
                dict["percent"] = pct
                dict["currentPercent"] = pct
            }
            if let line = b.lastSavedLine {
                dict["lastLine"] = line
                dict["lastSavedLine"] = line
            }
            if let tAt = b.tsundokuAt { dict["tsundokuAt"] = tAt }
            if let fAt = b.finishedAt { dict["finishedAt"] = fAt }
            return dict
        }

        let recordsArray: [[String: Any]] = records.map { r in
            var dict: [String: Any] = [
                "id": r.id.uuidString,
                "bookId": r.bookId.uuidString,
                "startedAt": r.startedAt,
                "endedAt": r.endedAt,
                "minutes": r.durationMinutes,
                "durationMinutes": r.durationMinutes,
                "nightDate": r.nightDate,
                "entry": r.entry.rawValue
            ]
            if let u = r.progressUnit { dict["progressUnit"] = u.rawValue }
            if let sp = r.startPage { dict["startPage"] = sp }
            if let ep = r.endPage { dict["endPage"] = ep }
            if let sl = r.startLocation { dict["startLocation"] = sl }
            if let el = r.endLocation { dict["endLocation"] = el }
            if let spc = r.startPercent { dict["startPercent"] = spc }
            if let epc = r.endPercent { dict["endPercent"] = epc }
            if let line = r.savedLine { dict["savedLine"] = line }
            return dict
        }

        var settingsDict: [String: Any] = [
            "flipToStartEnabled": settings.flipToStartEnabled,
            "hideOnWidgets": settings.hideOnWidgets,
            "widgetGuideShown": settings.widgetGuideShown,
            "entryTime": settings.entryTime,
            "appearanceID": settings.appearanceID.rawValue,
            "isPlusPurchased": settings.isPlusPurchased,
            "recommendationWeights": [
                "readers": [
                    "chosen": settings.recommendationWeights.readers.chosen,
                    "skipped": settings.recommendationWeights.readers.skipped
                ],
                "author": [
                    "chosen": settings.recommendationWeights.author.chosen,
                    "skipped": settings.recommendationWeights.author.skipped
                ],
                "award": [
                    "chosen": settings.recommendationWeights.award.chosen,
                    "skipped": settings.recommendationWeights.award.skipped
                ]
            ]
        ]
        if let fNight = settings.firstNightCompletedAt { settingsDict["firstNightCompletedAt"] = fNight }
        if let sNight = settings.seventhNightReachedAt { settingsDict["seventhNightReachedAt"] = sNight }

        let root: [String: Any] = [
            "state": [
                "books": booksArray,
                "records": recordsArray,
                "settings": settingsDict
            ],
            "books": booksArray,
            "readingRecords": recordsArray,
            "settings": settingsDict,
            "outboundNetworkCount": 0
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public func hookWidgetJSONString() -> String {
        let payload = snapshotStore.fullHookPayload()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(payload),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public func hookLiveActivityJSONString() -> String {
        struct Payload: Codable {
            var areActivitiesEnabled: Bool
            var activities: [LiveActivityItemState]
            var requests: [LiveActivityRequestLog]
        }
        let payload = Payload(
            areActivitiesEnabled: areActivitiesEnabled,
            activities: liveActivities,
            requests: liveActivityRequests
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(payload),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public func hookNDLJSONString() -> String {
        struct Payload: Codable {
            var status: String
            var queries: [CatalogQueryLog]
            var metadata: CatalogMetadata
        }
        let payload = Payload(
            status: catalogDB.status.rawValue,
            queries: catalogDB.queryLogs,
            metadata: catalogDB.metadata
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(payload),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public func hookOutboundJSONString() -> String {
        let readout = H16OutboundReadout(totalCount: 0, requests: [], openedURLs: openedURLs)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(readout),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public func hookLatencyJSONString() -> String {
        let readout = clock.latencyReadout()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(readout),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public func hookStoreKitJSONString() -> String {
        struct Payload: Codable {
            var isPlusPurchased: Bool
            var canMakePayments: Bool
            var productLoadAvailable: Bool
            var appearanceID: String
        }
        let payload = Payload(
            isPlusPurchased: settings.isPlusPurchased,
            canMakePayments: storeCanMakePayments,
            productLoadAvailable: storeProductLoadAvailable,
            appearanceID: settings.appearanceID.rawValue
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(payload),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public func hookIntentsJSONString() -> String {
        struct ShortcutItem: Codable {
            var intent: String
            var phrases: [String]
        }
        struct ControlItem: Codable {
            var kind: String
            var intent: String
            var labelKey: String
        }
        struct Payload: Codable {
            var invocations: [IntentInvocationLog]
            var registeredShortcuts: [ShortcutItem]
            var registeredControls: [ControlItem]
        }
        let shortcuts: [ShortcutItem] = [
            ShortcutItem(
                intent: "StartReadingIntent",
                phrases: [
                    "${applicationName} 読書を始める",
                    "${applicationName} 読み始める"
                ]
            ),
            ShortcutItem(
                intent: "WhereStoppedIntent",
                phrases: [
                    "${applicationName} どこまで読んだ",
                    "${applicationName} しおりを確認"
                ]
            ),
            ShortcutItem(
                intent: "ContinueReadingIntent",
                phrases: [
                    "${applicationName} 続きを読む",
                    "${applicationName} しおりを開く"
                ]
            )
        ]
        let controls: [ControlItem] = [
            ControlItem(
                kind: "button",
                intent: "StartReadingIntent",
                labelKey: "control.startReading"
            )
        ]
        let payload = Payload(
            invocations: intentInvocations,
            registeredShortcuts: shortcuts,
            registeredControls: controls
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(payload),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public func hookShareCardJSONString() -> String {
        let readout = H14ShareCardReadout(cards: shareCards)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(readout),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public func hookAwardsJSONString() -> String {
        struct Payload: Codable {
            var mode: String
            var bundledCount: Int
            var activeItems: [H25AwardItem]
        }
        let payload = Payload(
            mode: awardsMode,
            bundledCount: AwardsCatalog.allBundledAwards().count,
            activeItems: activeAwards
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(payload),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public func hookMediaAuditJSONString() -> String {
        let readout = H15MediaAuditReadout(
            savedImageFileCount: savedImageFileCount,
            photoLibraryWriteCount: photoLibraryWriteCount
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(readout),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }
}
