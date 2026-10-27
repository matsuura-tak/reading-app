import Foundation
import Observation
import ReadingCore
import ReadingStore

public enum BookmarkSheetKind: Identifiable, Equatable, Sendable {
    case addBook(titlePendingMode: Bool)
    case markFlow
    case resultSheet
    case widgetGuide
    case finishNight(bookId: UUID)
    case manualInput(isbn13: String?, title: String, author: String, publisher: String?, label: String?, publishedYear: Int?, titlePendingMode: Bool)
    case coverCapture(isbn13: String?, titlePendingMode: Bool)
    case colophonCapture(bookId: UUID)

    public var id: String {
        switch self {
        case .addBook(let pending): return "addBook-\(pending)"
        case .markFlow: return "markFlow"
        case .resultSheet: return "resultSheet"
        case .widgetGuide: return "widgetGuide"
        case .finishNight(let bookId): return "finishNight-\(bookId.uuidString)"
        case .manualInput(let isbn, _, _, _, _, _, let pending): return "manual-\(isbn ?? "nil")-\(pending)"
        case .coverCapture(let isbn, let pending): return "cover-\(isbn ?? "nil")-\(pending)"
        case .colophonCapture(let bookId): return "colophon-\(bookId.uuidString)"
        }
    }
}

public enum NavigationDestinationItem: Hashable, Sendable {
    case shelf
    case settings
    case bookDetail(UUID)
}

@MainActor
@Observable
public final class ReadingAppModel {
    public let store: ReadingDataStore
    public var activeTab: AppActiveTab = .bookmark {
        didSet {
            updateScreenStateFlags()
        }
    }
    public var currentScreen: AppScreenID = .bookmarkEmpty {
        didSet {
            updateScreenStateFlags()
        }
    }
    public var navigationPath: [NavigationDestinationItem] = [] {
        didSet {
            updateScreenStateFlags()
        }
    }
    public var activeSheet: BookmarkSheetKind? {
        didSet {
            updateScreenStateFlags()
        }
    }
    public var hookGeneration: Int = 0
    public var barcodeEventCounter: Int = 0
    public var pendingBarcodes: [String] = []

    public init(store: ReadingDataStore? = nil) {
        if let store {
            self.store = store
        } else {
            self.store = ReadingDataStore()
        }
    }

    public func updateScreenStateFlags() {
        let onHome = navigationPath.isEmpty && (currentScreen == .bookmarkCurrent || currentScreen == .bookmarkEmpty)
        store.screenState.isOnBookmarkScreen = onHome
        store.screenState.hasOverlayOrSheet = (activeSheet != nil)
    }

    public var books: [BookSnapshot] {
        store.books
    }

    public var records: [ReadingRecordSnapshot] {
        store.records
    }

    public var settings: SettingsSnapshot {
        store.settings
    }

    public var currentBook: BookSnapshot? {
        store.currentBook
    }

    public var sessionState: SessionStateValue {
        store.sessionState
    }

    public var activeErrorKey: String? {
        get { store.activeErrorKey }
        set { store.activeErrorKey = newValue }
    }

    public var isStoreLoadFailed: Bool {
        store.isStoreLoadFailed
    }

    public func notifyHookChanged() {
        hookGeneration += 1
    }
}
