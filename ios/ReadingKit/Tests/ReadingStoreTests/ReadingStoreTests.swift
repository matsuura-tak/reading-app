import Foundation
import Testing
@testable import ReadingCore
@testable import ReadingStore

@MainActor
struct ReadingStoreTests {

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ReadingStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("ReadingClock advances seconds, milliseconds, timezone, and records 8 latency metrics")
    func clockAndLatencyMetrics() {
        let clock = ReadingClock(nowISO8601: "2026-10-18T03:59:00+09:00", timeZoneID: "Asia/Tokyo")
        #expect(clock.nightDate() == "2026-10-17")

        clock.advance(seconds: 60)
        #expect(clock.nightDate() == "2026-10-18")

        clock.advance(milliseconds: 900)
        #expect(clock.currentOffsetMilliseconds == 60_900)
        clock.advance(milliseconds: 100)
        #expect(clock.currentOffsetMilliseconds == 61_000)

        clock.setTimeZone(identifier: "America/Los_Angeles")
        #expect(clock.timeZone().identifier == "America/Los_Angeles")

        for metric in LatencyMetric.allCases {
            clock.beginInterval(metric)
            let elapsed = clock.endInterval(metric)
            #expect(elapsed >= 0)
            #expect((clock.latestSample(for: metric) ?? -1) <= 500.0)
        }
        let readout = clock.latencyReadout()
        #expect(readout.latestMs.count == LatencyMetric.allCases.count)
    }

    @Test("CatalogDatabase builds SQLite with FTS5, opens read-only, excludes from backup, and queries ISBN/Title/Cooccurrence")
    func catalogDatabaseOperations() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let stubJSON = """
        {
          "stubVersion": 1,
          "status": "ready",
          "books": [
            {
              "isbn": "9784101000015",
              "title": "こころ",
              "author": "夏目, 漱石, 1867-1916 著",
              "publisher": "新潮社",
              "label": "新潮文庫",
              "publishedYear": 2004,
              "ndc": "913.6"
            },
            {
              "isbn": "9784101000046",
              "title": "人間失格",
              "author": "太宰治",
              "publisher": "新潮社",
              "label": "新潮文庫",
              "publishedYear": 1952,
              "ndc": "913.6"
            },
            {
              "isbn": "9784101000099",
              "title": "非文学の本",
              "author": "テスト著者",
              "publisher": "新潮社",
              "publishedYear": 2020,
              "ndc": "400"
            }
          ],
          "cooccurrences": [
            { "fromISBN": "9784101000015", "toISBN": "9784101000046", "count": 15, "ndc": "913.6" },
            { "fromISBN": "9784101000015", "toISBN": "9784101000099", "count": 20, "ndc": "400" }
          ]
        }
        """

        let dbURL = dir.appendingPathComponent("catalog.sqlite")
        let db = CatalogDatabase(databaseURL: dbURL)
        db.configure(fromStubJSON: stubJSON)
        #expect(db.status == .ready)
        #expect(db.allBooks().count == 3)
        #expect(db.isExcludedFromBackup() == true)

        let byISBN = db.lookupByISBN("978-4-10-100001-5")
        if case .found(let item) = byISBN {
            #expect(item.title == "こころ")
            #expect(item.author == "夏目漱石")
        } else {
            Issue.record("Expected ISBN lookup to find こころ")
        }

        let byTitle = db.searchByTitleOrAuthor("人間失格")
        #expect(byTitle.count == 1)
        #expect(byTitle.first?.isbn13 == "9784101000046")

        let cooc = db.cooccurrenceCandidates(forISBN13: "9784101000015")
        #expect(cooc.count == 1)
        #expect(cooc.first?.isbn13 == "9784101000046")

        #expect(db.queryLogs.count == 2)

        // Not downloaded state (AC-9)
        db.configure(fromStubJSON: #"{"stubVersion":1,"status":"notDownloaded","books":[],"cooccurrences":[]}"#)
        #expect(db.status == .notDownloaded)
        if case .databaseNotReady = db.lookupByISBN("9784101000015") {
            // expected
        } else {
            Issue.record("Expected .databaseNotReady when status is notDownloaded")
        }
    }

    @Test("SnapshotStore writes widget-snapshot.json atomically, enforces hideOnWidgets privacy, and tracks reloads")
    func snapshotStorePrivacyAndReloads() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let snapStore = SnapshotStore(containerDirectory: dir)
        snapStore.configureSpecs(from: "accessoryRectangular:172x76,systemSmall:170x170")

        let book = BookSnapshot(
            id: ReadingDataStore.uuidBookA,
            title: "羅生門",
            author: "芥川龍之介",
            status: .current,
            progressUnit: .page,
            currentPage: 61,
            lastSavedLine: "「下人の行方は、誰も知らなーい。」"
        )
        var settings = SettingsSnapshot(hideOnWidgets: false, appearanceID: .kinari, isPlusPurchased: true)

        _ = try snapStore.writeSnapshot(
            currentBook: book,
            settings: settings,
            nowISO: "2026-10-18T21:00:00+09:00",
            cause: "mark.save",
            recordReload: true
        )
        #expect(snapStore.reloadTimelineCount == 1)
        #expect(snapStore.reloadsByCause["mark.save"] == 1)

        let rv = try snapStore.fileURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(rv.isExcludedFromBackup == true)

        let payload1 = snapStore.fullHookPayload()
        #expect(payload1.renders.count == 2)
        #expect(payload1.renders.first?.appearanceID == "kinari")
        #expect(payload1.renders.first?.state == "hasLine")
        #expect(payload1.composition.accessibilityLabel.unicodeScalars.allSatisfy { !(0xFE10...0xFE4F).contains($0.value) })

        // Enable hideOnWidgets -> neither book title nor saved line appears
        settings.hideOnWidgets = true
        _ = try snapStore.writeSnapshot(
            currentBook: book,
            settings: settings,
            nowISO: "2026-10-18T21:05:00+09:00",
            cause: "settings.hideOnWidgets",
            recordReload: true
        )
        let data2 = try JSONEncoder().encode(snapStore.fullHookPayload())
        let json2 = String(data: data2, encoding: .utf8) ?? ""
        #expect(!json2.contains("羅生門"))
        #expect(!json2.contains("下人の行方は"))
        #expect(json2.contains("p.61"))
        #expect(json2.contains("しおり"))
    }

    @Test("ReadingDataStore book CRUD, title-pending book, and H7 failSave rollback across all 10 points")
    func storeCRUDAndFailSaveRollback() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let clock = ReadingClock(nowISO8601: "2026-10-18T21:00:00+09:00")
        let store = ReadingDataStore(containerDirectory: dir, clock: clock)
        store.resetAllData()

        // 1. book.add failSave -> rollback, then retry succeeds
        store.configureFailSave("book.add:1")
        let failAdd = store.addBook(id: ReadingDataStore.uuidBookA, title: "羅生門", author: "芥川龍之介")
        #expect(store.books.isEmpty)
        #expect(store.activeErrorKey == "common.save.error")
        if case .success = failAdd { Issue.record("Expected failure on book.add:1") }

        let okAdd1 = try store.addBook(id: ReadingDataStore.uuidBookA, title: "羅生門", author: "芥川龍之介").get()
        #expect(okAdd1.status == .current)
        let okAdd2 = try store.addBook(id: ReadingDataStore.uuidBookB, title: "檸檬", author: "梶井基次郎").get()
        #expect(okAdd2.status == .tsundoku)

        // 2. book.update failSave -> rollback, then retry succeeds
        store.configureFailSave("book.update:1")
        _ = store.updateBook(bookId: ReadingDataStore.uuidBookA, title: "変更後", author: "芥川")
        #expect(store.books.first?.title == "羅生門")
        _ = store.updateBook(bookId: ReadingDataStore.uuidBookA, title: "羅生門・改", author: "芥川龍之介")
        #expect(store.books.first?.title == "羅生門・改")

        // 3. book.status failSave -> rollback, then retry succeeds
        store.configureFailSave("book.status:1")
        #expect(!store.switchToCurrentBook(bookId: ReadingDataStore.uuidBookB))
        #expect(store.currentBook?.id == ReadingDataStore.uuidBookA)
        #expect(store.switchToCurrentBook(bookId: ReadingDataStore.uuidBookB))
        #expect(store.currentBook?.id == ReadingDataStore.uuidBookB)

        // 4. session.start & session.end & mark.save failSave
        store.configureFailSave("session.start:1,session.end:1,mark.save:1")
        #expect(!store.startReadingSession(startedBy: "tap"))
        #expect(store.sessionState == .idle)
        #expect(store.activeErrorKey == "session.start.error")

        #expect(store.startReadingSession(startedBy: "tap"))
        #expect(store.sessionState == .reading)
        clock.advance(seconds: 1080) // 18 min

        let endFail = store.endReadingSession()
        #expect(endFail == .failedSave)
        #expect(store.sessionState == .reading)

        clock.advance(seconds: 120) // +2 min = 20 min total
        let endOk = store.endReadingSession()
        if case .saved(let rec, _) = endOk {
            #expect(rec.durationMinutes == 20)
        } else {
            Issue.record("Expected session end to succeed on retry")
        }

        let markFail = store.saveBookmark(mode: "manual", rawLine: "えたいの知れない不吉な塊が", rawProgress: "32")
        #expect(markFail == .failedSave)
        #expect(store.currentBook?.lastSavedLine == nil)

        let markOk = store.saveBookmark(mode: "manual", rawLine: "えたいの知れない不吉な塊が", rawProgress: "32")
        if case .saved(let summary, let guide) = markOk {
            #expect(summary == "p.32　20分")
            #expect(guide == true)
        } else {
            Issue.record("Expected mark save to succeed on retry")
        }

        // 5. record.update & record.delete & book.delete failSave
        let recId = try #require(store.records.first?.id)
        store.configureFailSave("record.update:1,record.delete:1,book.delete:1")
        _ = store.updateRecordMinutes(recordId: recId, rawMinutes: "45")
        #expect(store.records.first?.durationMinutes == 20)
        _ = store.updateRecordMinutes(recordId: recId, rawMinutes: "45")
        #expect(store.records.first?.durationMinutes == 45)

        #expect(!store.deleteRecord(recordId: recId))
        #expect(store.records.count == 1)

        #expect(!store.deleteBook(bookId: ReadingDataStore.uuidBookB))
        #expect(store.books.count == 2)
        #expect(store.deleteBook(bookId: ReadingDataStore.uuidBookB))
        #expect(store.books.count == 1)
        #expect(store.records.isEmpty)

        // 6. store.load failSave preserves disk data on subsequent relaunch (AC-90)
        store.configureFailSave("store.load:1")
        store.loadFromDisk()
        #expect(store.isStoreLoadFailed == true)
        #expect(store.books.isEmpty)

        store.loadFromDisk()
        #expect(store.isStoreLoadFailed == false)
        #expect(store.books.count == 1)
    }

    @Test("ReadingDataStore flip-to-start, session duration boundaries, Live Activity, StoreKit, Intents, and perf500 preset")
    func sessionBoundariesAndExtensions() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let clock = ReadingClock(nowISO8601: "2026-10-18T20:30:00+09:00", timeZoneID: "Asia/Tokyo")
        let store = ReadingDataStore(containerDirectory: dir, clock: clock)
        store.resetAllData()
        _ = store.addBook(id: ReadingDataStore.uuidBookA, title: "羅生門", author: "芥川龍之介")
        _ = store.saveBookmark(mode: "pageOnly", rawLine: nil, rawProgress: "43")

        // Flip-to-start: 900ms pickup cancels, 1000ms starts with 1 haptic + announcement
        #expect(store.isFlipMonitoringOn == true)
        store.setOrientation("faceDown")
        clock.advance(milliseconds: 900)
        store.evaluateFlipOnClockAdvance()
        store.setOrientation("portrait")
        #expect(store.sessionState == .idle)
        #expect(store.hapticCount == 0)

        store.setOrientation("faceDown")
        clock.advance(milliseconds: 1000)
        store.evaluateFlipOnClockAdvance()
        #expect(store.sessionState == .reading)
        #expect(store.lastStartedBy == "flip")
        #expect(store.hapticCount == 1)
        #expect(store.announcements["session.flipStarted.announcement"] == 1)

        // Under 60s -> discardedTooShort + restores tonight's 21:00 Live Activity schedule (AC-130(2))
        clock.advance(seconds: 50)
        #expect(store.endReadingSession() == .discardedTooShort)
        #expect(store.activeNoticeKey == "session.tooShort")
        #expect(store.hookLiveActivityJSONString().contains("2026-10-18T21:00:00+09:00"))

        // Over 24h (86460s) -> capped at 1440m (AC-57)
        store.activeNoticeKey = nil
        #expect(store.startReadingSession())
        clock.advance(seconds: 86460)
        let cappedRes = store.endReadingSession()
        if case .saved(let rec, let capped) = cappedRes {
            #expect(capped == true)
            #expect(rec.durationMinutes == 1440)
        } else {
            Issue.record("Expected capped save")
        }
        store.completeMarkLater()

        // App Intents: WhereStoppedIntent, StartReadingIntent, EndReadingFromActivityIntent
        let whereLog = store.handleExternalIntent("WhereStoppedIntent")
        #expect(whereLog.dialogKey == "intent.whereStopped.page")
        #expect(whereLog.spokenText == "43ページからです。")

        let startLog = store.handleExternalIntent("StartReadingIntent")
        #expect(startLog.dialogKey == "intent.start.started")
        #expect(store.sessionState == .reading)

        clock.advance(seconds: 600)
        let endLog = store.handleExternalIntent("EndReadingFromActivityIntent:fg=0")
        #expect(endLog.requestedForeground == false)
        #expect(store.sessionState == .idle)
        #expect(store.records.count == 2)

        // StoreKit purchase & refund on activate (AC-106, AC-111)
        store.selectAppearance(.kinari)
        #expect(store.previewAppearanceID == .kinari)
        #expect(store.purchasePlus() == .success)
        #expect(store.settings.isPlusPurchased == true)
        #expect(store.settings.appearanceID == .kinari)

        store.triggerStoreRefund()
        store.handleDidBecomeActive()
        #expect(store.settings.isPlusPurchased == false)
        #expect(store.settings.appearanceID == .default)

        // perf500 preset (AC-101)
        try store.seedPreset("perf500")
        #expect(store.books.count == 500)
        #expect(store.records.count == 5000)
        #expect(store.records(for: ReadingDataStore.uuidBookA).count == 1000)
    }

    @Test("ReadingDataStore entry URL 300s expiry, crash recovery, clock rollback, title-pending book, and all 11+ hook readouts")
    func entryURLCrashRecoveryTitlePendingAndHookReadouts() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let clock = ReadingClock(nowISO8601: "2026-10-18T21:00:00+09:00", timeZoneID: "Asia/Tokyo")
        let store = ReadingDataStore(containerDirectory: dir, clock: clock)
        store.resetAllData()

        // Title-pending book (AC-139, AC-140)
        #expect(store.startReadingWithPendingTitleBook() == true)
        #expect(store.hasTitlePendingBook == true)
        #expect(store.sessionState == .reading)
        #expect(store.startReadingWithPendingTitleBook() == false) // max 1 title-pending book

        // Crash recovery while reading (AC-53)
        clock.advance(seconds: 300)
        let relaunchedStore = ReadingDataStore(containerDirectory: dir, clock: clock)
        relaunchedStore.loadFromDisk()
        #expect(relaunchedStore.sessionState == .reading)
        clock.advance(seconds: 300) // total 600s = 10m
        let recoveredEnd = relaunchedStore.endReadingSession()
        if case .saved(let rec, _) = recoveredEnd {
            #expect(rec.durationMinutes == 10)
        } else {
            Issue.record("Expected crash-recovered session to save 10 minutes")
        }
        _ = relaunchedStore.saveBookmark(mode: "pageOnly", rawLine: nil, rawProgress: "45")
        #expect(relaunchedStore.currentBook?.currentPage == 45)

        // Populate title-pending book later (AC-140)
        #expect(relaunchedStore.populateTitlePendingBook(
            isbn13: "9784101000015",
            title: "こころ",
            author: "夏目漱石",
            publisher: "新潮社",
            label: "新潮文庫",
            publishedYear: 2004
        ) == true)
        #expect(relaunchedStore.hasTitlePendingBook == false)
        #expect(relaunchedStore.currentBook?.title == "こころ")
        #expect(relaunchedStore.currentBook?.currentPage == 45)
        #expect(relaunchedStore.records.count == 1)

        // Entry URL 299s vs 301s vs background reset (AC-40)
        relaunchedStore.openEntryURL("lock_widget")
        clock.advance(seconds: 299)
        #expect(relaunchedStore.startReadingSession() == true)
        clock.advance(seconds: 120)
        _ = relaunchedStore.endReadingSession()
        relaunchedStore.completeMarkLater()
        #expect(relaunchedStore.lastEntryPoint == .lockWidget)

        relaunchedStore.openEntryURL("lock_widget")
        clock.advance(seconds: 301)
        #expect(relaunchedStore.startReadingSession() == true)
        clock.advance(seconds: 120)
        _ = relaunchedStore.endReadingSession()
        relaunchedStore.completeMarkLater()
        #expect(relaunchedStore.lastEntryPoint == .app)

        relaunchedStore.openEntryURL("small_widget")
        relaunchedStore.handleDidEnterBackground()
        #expect(relaunchedStore.startReadingSession() == true)
        clock.advance(seconds: 120)
        _ = relaunchedStore.endReadingSession()
        relaunchedStore.completeMarkLater()
        #expect(relaunchedStore.lastEntryPoint == .app)

        // Clock rollback (< 0s) -> discardedInvalidTime (AC-58)
        #expect(relaunchedStore.startReadingSession() == true)
        clock.advance(seconds: -120)
        #expect(relaunchedStore.endReadingSession() == .discardedInvalidTime)
        #expect(relaunchedStore.activeNoticeKey == "session.invalidTime")

        // Verify all 11+ hook readouts produce valid non-empty strings/JSON
        if let bookId = relaunchedStore.currentBook?.id {
            relaunchedStore.recordShareCard(for: bookId)
        }
        relaunchedStore.openExternalURL("https://creativecommons.org/licenses/by/4.0/deed.ja")

        #expect(relaunchedStore.hookStateString().contains("state=idle"))
        #expect(relaunchedStore.hookStoreJSONString().contains("こころ"))
        #expect(relaunchedStore.hookWidgetJSONString().contains("こころ"))
        #expect(relaunchedStore.hookLiveActivityJSONString().contains("areActivitiesEnabled"))
        #expect(relaunchedStore.hookNDLJSONString().contains("queries"))
        #expect(relaunchedStore.hookOutboundJSONString().contains("creativecommons.org"))
        #expect(relaunchedStore.hookLatencyJSONString().contains("samplesMs"))
        #expect(relaunchedStore.hookStoreKitJSONString().contains("canMakePayments"))
        #expect(relaunchedStore.hookIntentsJSONString().contains("registeredShortcuts"))
        #expect(relaunchedStore.hookShareCardJSONString().contains("こころ"))
        #expect(relaunchedStore.hookAwardsJSONString().contains("\"bundledCount\":76"))
        #expect(relaunchedStore.hookMediaAuditJSONString().contains("\"savedImageFileCount\":0"))
    }

    @Test("ReadingDataStore and subcomponents deallocate cleanly with no retain cycles (weak reference becomes nil)")
    func storeWeakReferenceDeallocation() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        weak var weakStore: ReadingDataStore?
        weak var weakClock: ReadingClock?
        weak var weakSnapshotStore: SnapshotStore?
        weak var weakCatalogDB: CatalogDatabase?

        do {
            let clock = ReadingClock(nowISO8601: "2026-10-18T21:00:00+09:00", timeZoneID: "Asia/Tokyo")
            let store = ReadingDataStore(containerDirectory: dir, clock: clock)
            weakStore = store
            weakClock = clock
            weakSnapshotStore = store.snapshotStore
            weakCatalogDB = store.catalogDB

            store.resetAllData()
            _ = store.addBook(id: ReadingDataStore.uuidBookA, title: "羅生門", author: "芥川龍之介")
            _ = store.startReadingSession(startedBy: "tap")
            clock.advance(seconds: 600)
            _ = store.endReadingSession()
            _ = store.saveBookmark(mode: "manual", rawLine: "テストの一行", rawProgress: "12")
            #expect(weakStore != nil)
        }

        #expect(weakStore == nil)
        #expect(weakClock == nil)
        #expect(weakSnapshotStore == nil)
        #expect(weakCatalogDB == nil)
    }

    @Test("SwiftData ReadingStore.store persistence without JSON state file, entry URL scheme/host validation, and <60s discarded session entry preservation")
    func swiftDataPersistenceAndEntryURLValidation() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let clock = ReadingClock(nowISO8601: "2026-10-18T21:00:00+09:00", timeZoneID: "Asia/Tokyo")
        let store = ReadingDataStore(containerDirectory: dir, clock: clock)
        store.resetAllData()

        _ = store.addBook(id: ReadingDataStore.uuidBookA, title: "羅生門", author: "芥川龍之介")
        store.recordRecommendationFeedback(chosenCategory: "readers", allShownCategories: ["readers", "author"])

        let legacyJSONURL = dir
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("ReadingStoreState.json")
        #expect(FileManager.default.fileExists(atPath: store.storeFileURL.path) == true)
        #expect(FileManager.default.fileExists(atPath: legacyJSONURL.path) == false)

        // Invalid scheme or host must be ignored
        store.openEntryURL("shiori://open?entry=lock_widget")
        #expect(store.pendingEntryURL == nil)
        store.openEntryURL("yomuma://wrong?entry=lock_widget")
        #expect(store.pendingEntryURL == nil)

        // Valid URL sets pendingEntryURL; discarded <60s session preserves pendingEntryURL for retry within 300s
        store.openEntryURL("YOMUMA://OPEN?entry=small_widget")
        #expect(store.pendingEntryURL?.entry == .smallWidget)

        clock.advance(seconds: 30)
        #expect(store.startReadingSession() == true)
        clock.advance(seconds: 45) // < 60s -> discardedTooShort
        #expect(store.endReadingSession() == .discardedTooShort)
        #expect(store.pendingEntryURL?.entry == .smallWidget)

        // Retry within 300s of initial URL open still uses small_widget
        clock.advance(seconds: 20)
        #expect(store.startReadingSession() == true)
        clock.advance(seconds: 120) // >= 60s -> saved and clears pendingEntryURL
        let savedRes = store.endReadingSession()
        if case .saved(let rec, _) = savedRes {
            #expect(rec.entry == .smallWidget)
        } else {
            Issue.record("Expected second session to save with small_widget entry")
        }
        #expect(store.pendingEntryURL == nil)

        // Relaunch store from SwiftData and verify recommendationWeights and records persisted
        let relaunched = ReadingDataStore(containerDirectory: dir, clock: clock)
        relaunched.loadFromDisk()
        #expect(relaunched.books.count == 1)
        #expect(relaunched.records.count == 1)
        #expect(relaunched.settings.recommendationWeights.readers.chosen == 1)
        #expect(relaunched.settings.recommendationWeights.author.skipped == 1)
    }
}

