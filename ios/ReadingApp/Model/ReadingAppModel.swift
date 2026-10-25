import Foundation
import Observation
import ReadingCore
import ReadingStore

@MainActor
@Observable
public final class ReadingAppModel {
    public let store: ReadingDataStore
    public var activeTab: AppActiveTab = .bookmark {
        didSet {
            store.screenState.isOnBookmarkScreen = (activeTab == .bookmark && currentScreen == .bookmarkCurrent)
        }
    }
    public var currentScreen: AppScreenID = .bookmarkEmpty {
        didSet {
            store.screenState.isOnBookmarkScreen = (activeTab == .bookmark && (currentScreen == .bookmarkCurrent || currentScreen == .bookmarkEmpty))
        }
    }
    public var hookGeneration: Int = 0

    public init(store: ReadingDataStore? = nil) {
        if let store {
            self.store = store
        } else {
            self.store = ReadingDataStore()
        }
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
