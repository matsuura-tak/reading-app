import Foundation
import SwiftData
import Testing

@testable import Yomutoki

/// 保存の層をメモリの中の保存先で組み立てる。時計は止めたまま、advance で進める。失敗は FailureInjector で本物の save の前に入れる。
@MainActor
struct StoreHarness {
    let container: ModelContainer
    let clock: ClockController
    let sink: CapturingSink
    let recorder: TelemetryRecorder
    let store: LibraryStore
    let defaults: UserDefaults

    static let base = Date(timeIntervalSince1970: 1_792_585_800)  // 2026-10-21T21:30:00+09:00（水曜）

    init(fail: [StoreOperation: FailureBudget] = [:], container existing: ModelContainer? = nil) throws {
        let container = try existing ?? LibraryContainer.makeInMemory()
        let clock = ClockController(start: StoreHarness.base, frozen: true)
        let sink = CapturingSink()
        let defaults = try #require(UserDefaults(suiteName: "YomutokiTests.\(UUID().uuidString)"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        calendar.firstWeekday = 2
        let recorder = TelemetryRecorder(sink: sink, defaults: defaults, clock: clock.clock, calendar: calendar)
        let store = LibraryStore(
            clock: clock.clock, calendar: calendar, telemetry: recorder, openContainer: { container })
        let injector = FailureInjector(fail)
        store.beforeSave = { operation in try injector.check(operation) }
        self.container = container
        self.clock = clock
        self.sink = sink
        self.recorder = recorder
        self.store = store
        self.defaults = defaults
    }

    func advance(_ seconds: Int) {
        clock.apply(.advance(seconds))
    }

    func events() async -> [TelemetryEvent] {
        await recorder.waitForDelivery()
        return await sink.events
    }

    func count<T: PersistentModel>(_ type: T.Type) throws -> Int {
        try container.mainContext.fetchCount(FetchDescriptor<T>())
    }
}

@MainActor
struct LibraryStoreTests {
    // MARK: ふだんの流れ

    @Test("読み始め → 10分 → 終える → 72ページで保存：記録600秒、最後のページ72、ActiveReading は消える")
    func finishFlow() async throws {
        let h = try StoreHarness()
        h.store.load()
        let bookID = try h.store.addBook(title: "  坊っちゃん\n", totalPages: 300)
        #expect(h.store.book(id: bookID)?.title == "坊っちゃん")
        try h.store.startReading(bookID: bookID, source: .afterAdd)
        h.advance(600)
        #expect(try h.store.finish() == .finishing)
        #expect(h.store.active?.initialMinutes == 10)
        h.advance(120)  // finishing の間は経過を進めない
        try h.store.finishSession(endPage: 72, minutes: 10)
        let session = try #require(h.store.sessions(for: bookID).first)
        #expect(session.durationSeconds == 600)
        #expect(session.pagesRead == 72)
        #expect(h.store.book(id: bookID)?.lastPage == 72)
        #expect(h.store.book(id: bookID)?.progressPercent == 24)
        #expect(h.store.active == nil)
        #expect(try h.count(ActiveReading.self) == 0)
        #expect(try h.count(ReadingSession.self) == 1)
        let events = await h.events()
        #expect(events.contains(.readingSessionStarted(isFirstSession: true, startSource: .afterAdd)))
        #expect(events.last?.name == "Reading Session Finished")
    }

    @Test("分を直したら「分 × 60」、直さなければ経過の秒（切り捨て）")
    func editedMinutes() throws {
        let h = try StoreHarness()
        h.store.load()
        let bookID = try h.store.addBook(title: "こころ", totalPages: nil)
        try h.store.startReading(bookID: bookID, source: .home)
        h.advance(659)
        _ = try h.store.finish()
        #expect(throws: StoreError.invalidInput) { _ = try h.store.finishSession(endPage: nil, minutes: 11) }
        #expect(throws: StoreError.invalidInput) { _ = try h.store.finishSession(endPage: nil, minutes: 0) }
        try h.store.finishSession(endPage: nil, minutes: 5)
        #expect(h.store.sessions(for: bookID).first?.durationSeconds == 300)
        #expect(h.store.sessions(for: bookID).first?.endPage == nil)
    }

    @Test("一時停止と再開：止めていた時間は経過に入らない。終える入力をやめた時間も入らない")
    func pauseResumeAndCancel() throws {
        let h = try StoreHarness()
        h.store.load()
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        try h.store.startReading(bookID: bookID, source: .bookDetail)
        h.advance(100)
        try h.store.pause()
        h.advance(50)
        #expect(h.store.active?.elapsedSeconds(now: h.clock.now()) == 100)
        try h.store.resume()
        h.advance(30)
        #expect(h.store.active?.elapsedSeconds(now: h.clock.now()) == 130)
        _ = try h.store.finish()
        h.advance(40)
        try h.store.cancelFinish()
        #expect(h.store.active?.state == .reading)
        #expect(h.store.active?.elapsedSeconds(now: h.clock.now()) == 130)
        #expect(h.store.active?.wasPaused == true)
    }

    @Test("60秒未満で終えると記録せずに idle（AC-13）。Discarded を出す")
    func discardTooShort() async throws {
        let h = try StoreHarness()
        h.store.load()
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        try h.store.startReading(bookID: bookID, source: .home)
        h.advance(59)
        #expect(try h.store.finish() == .discarded(bookID: bookID))
        #expect(h.store.active == nil)
        #expect(try h.count(ReadingSession.self) == 0)
        #expect(await h.events().last == .readingSessionDiscarded)
    }

    // MARK: 前の本（PRD 10）

    @Test("前の本：記録がなければ最後に追加した本（AC-26）、あれば最後に記録を保存した本（AC-25）、消すと次の記録の本")
    func previousBook() throws {
        let h = try StoreHarness()
        h.store.load()
        let kokoro = try h.store.addBook(title: "こころ", totalPages: nil)
        h.advance(60)
        let botchan = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        #expect(h.store.previousBookID == botchan)

        try h.store.startReading(bookID: botchan, source: .home)
        #expect(h.store.previousBookID == botchan)
        h.advance(600)
        _ = try h.store.finish()
        try h.store.finishSession(endPage: nil, minutes: 10)

        try h.store.startReading(bookID: kokoro, source: .bookDetail)
        #expect(h.store.previousBookID == kokoro)
        #expect(h.store.books.first?.id == kokoro)
        h.advance(600)
        _ = try h.store.finish()
        let kokoroSession = try h.store.finishSession(endPage: 40, minutes: 10)
        #expect(h.store.previousBookID == kokoro)

        try h.store.deleteSession(id: kokoroSession)
        #expect(h.store.previousBookID == botchan)
        #expect(h.store.book(id: kokoro)?.lastPage == 40)  // 記録を消しても最後のページは変えない（AC-16）
        #expect(h.store.book(id: kokoro)?.sessionCount == 0)
    }

    @Test("本の一覧の順：前の本が先頭、ほかは最後の記録（なければ追加）の新しい順（D-31。指揮役の決定）")
    func bookOrder() throws {
        let h = try StoreHarness()
        h.store.load()
        let kokoro = try h.store.addBook(title: "こころ", totalPages: nil)
        h.advance(60)
        let botchan = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        #expect(h.store.books.map(\.id) == [botchan, kokoro])

        h.advance(60)
        try h.store.startReading(bookID: kokoro, source: .bookDetail)
        h.advance(600)
        _ = try h.store.finish()
        try h.store.finishSession(endPage: nil, minutes: 10)
        h.advance(60)
        let neko = try h.store.addBook(title: "吾輩は猫である", totalPages: nil)
        // 記録のない「吾輩は猫である」は追加が新しいが、前の本（最後に記録を保存した「こころ」）が先頭。
        #expect(h.store.previousBookID == kokoro)
        #expect(h.store.books.map(\.id) == [kokoro, neko, botchan])

        // 読書中の本が先頭。ほかは「吾輩は猫である」の追加（780秒）が「こころ」の記録の保存（720秒）より新しい。
        try h.store.startReading(bookID: botchan, source: .home)
        #expect(h.store.books.map(\.id) == [botchan, neko, kokoro])
    }

    @Test("今週の合計は今週に読み始めた記録だけを秒で足す（AC-15、AC-36）")
    func weekTotal() throws {
        let h = try StoreHarness()
        h.store.load()
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        for _ in 0..<3 {
            try h.store.startReading(bookID: bookID, source: .home)
            h.advance(90)
            _ = try h.store.finish()
            try h.store.finishSession(endPage: nil, minutes: 1)
        }
        #expect(h.store.weekTotalMinutes(now: h.clock.now()) == 4)
        #expect(h.store.book(id: bookID)?.totalMinutes == 4)
        #expect(h.store.weekTotalMinutes(now: h.clock.now().addingTimeInterval(7 * 86_400)) == 0)
    }

    // MARK: 保存の失敗（FailureInjector で本物の save の前に失敗させ、rollback を確かめる）

    @Test("読み始めの保存に失敗：idle のまま、ActiveReading は増えず、Started を出さない。再試行の時刻が startedAt（AC-56、AC-57）")
    func startFailureThenRetry() async throws {
        let h = try StoreHarness(fail: [.sessionStart: .times(1)])
        h.store.load()
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        #expect(throws: StoreError.saveFailed(.sessionStart)) {
            try h.store.startReading(bookID: bookID, source: .home)
        }
        #expect(h.store.active == nil)
        #expect(try h.count(ActiveReading.self) == 0)
        h.advance(60)
        try h.store.startReading(bookID: bookID, source: .home)
        #expect(h.store.active?.startedAt == StoreHarness.base.addingTimeInterval(60))
        #expect(h.store.active?.elapsedSeconds(now: h.clock.now()) == 0)
        let events = await h.events()
        #expect(events.filter { $0 == .saveFailed(operation: .sessionStart) }.count == 1)
        #expect(events.filter { $0.name == "Reading Session Started" }.count == 1)
    }

    @Test("一時停止の保存に失敗：reading のまま、保存先の state も reading（AC-58）")
    func pauseFailure() throws {
        let h = try StoreHarness(fail: [.sessionPause: .times(1)])
        h.store.load()
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        try h.store.startReading(bookID: bookID, source: .home)
        h.advance(600)
        #expect(throws: StoreError.saveFailed(.sessionPause)) { try h.store.pause() }
        #expect(h.store.active?.state == .reading)
        let row = try #require(try h.container.mainContext.fetch(FetchDescriptor<ActiveReading>()).first)
        #expect(row.state == "reading")
        #expect(row.pausedAt == nil)
        h.advance(60)
        #expect(h.store.active?.elapsedSeconds(now: h.clock.now()) == 660)
    }

    @Test("「終える」の保存に失敗：paused のまま、止めていた時間を足していない（AC-62）")
    func beginFinishFailure() throws {
        let h = try StoreHarness(fail: [.sessionBeginFinish: .always])
        h.store.load()
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        try h.store.startReading(bookID: bookID, source: .home)
        h.advance(300)
        try h.store.pause()
        h.advance(120)
        #expect(throws: StoreError.saveFailed(.sessionBeginFinish)) { _ = try h.store.finish() }
        #expect(h.store.active?.state == .paused)
        #expect(h.store.active?.pausedTotalSeconds == 0)
        let row = try #require(try h.container.mainContext.fetch(FetchDescriptor<ActiveReading>()).first)
        #expect(row.state == "paused")
        #expect(row.finishedAt == nil)
        #expect(row.pausedTotalSeconds == 0)
    }

    @Test("60秒未満で終える保存に失敗 → 再試行は押した時点の経過で分ける（AC-66、AC-67、D-59）")
    func discardFailureThenRetry() throws {
        let h = try StoreHarness(fail: [.sessionDiscard: .times(1)])
        h.store.load()
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        try h.store.startReading(bookID: bookID, source: .home)
        h.advance(30)
        #expect(throws: StoreError.saveFailed(.sessionDiscard)) { _ = try h.store.finish() }
        #expect(h.store.active?.state == .reading)
        #expect(try h.count(ActiveReading.self) == 1)
        h.advance(10)
        #expect(try h.store.finish() == .discarded(bookID: bookID))

        let late = try StoreHarness(fail: [.sessionDiscard: .times(1)])
        late.store.load()
        let lateBook = try late.store.addBook(title: "こころ", totalPages: nil)
        try late.store.startReading(bookID: lateBook, source: .home)
        late.advance(30)
        #expect(throws: StoreError.saveFailed(.sessionDiscard)) { _ = try late.store.finish() }
        late.advance(40)
        #expect(try late.store.finish() == .finishing)
        #expect(late.store.active?.initialMinutes == 1)
    }

    @Test("やめる保存に失敗：finishing のまま（AC-64）。再試行の時刻までを読書時間に数えない（AC-65）")
    func cancelFailureThenRetry() throws {
        let h = try StoreHarness(fail: [.sessionCancelFinish: .times(1)])
        h.store.load()
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        try h.store.startReading(bookID: bookID, source: .home)
        h.advance(600)
        _ = try h.store.finish()
        #expect(throws: StoreError.saveFailed(.sessionCancelFinish)) { try h.store.cancelFinish() }
        #expect(h.store.active?.state == .finishing)
        h.advance(60)
        try h.store.cancelFinish()
        #expect(h.store.active?.state == .reading)
        #expect(h.store.active?.elapsedSeconds(now: h.clock.now()) == 600)
    }

    @Test("記録の保存に失敗：記録は増えず、finishing のまま、最後のページも変わらない（AC-19、AC-35）")
    func finishFailure() async throws {
        let h = try StoreHarness(fail: [.sessionFinish: .times(1)])
        h.store.load()
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        try h.store.startReading(bookID: bookID, source: .home)
        h.advance(600)
        _ = try h.store.finish()
        #expect(throws: StoreError.saveFailed(.sessionFinish)) { _ = try h.store.finishSession(endPage: 72, minutes: 10) }
        #expect(h.store.active?.state == .finishing)
        #expect(try h.count(ReadingSession.self) == 0)
        #expect(try h.count(ActiveReading.self) == 1)
        let book = try #require(try h.container.mainContext.fetch(FetchDescriptor<Book>()).first)
        #expect(book.lastPage == 0)
        #expect(h.store.book(id: bookID)?.lastPage == 0)
        try h.store.finishSession(endPage: 72, minutes: 10)
        #expect(try h.count(ReadingSession.self) == 1)
        let events = await h.events()
        #expect(events.filter { $0 == .saveFailed(operation: .sessionFinish) }.count == 1)
        #expect(events.filter { $0.name == "Reading Session Finished" }.count == 1)
    }

    @Test("記録の保存が1回だけ失敗 → もう一度保存で通る：記録はちょうど1件増え、active は nil、最後のページは入れたページ（AC-35）")
    func finishFailureThenRetrySavesExactlyOne() async throws {
        let h = try StoreHarness(fail: [.sessionFinish: .times(1)])
        h.store.load()
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        try h.store.startReading(bookID: bookID, source: .home)
        h.advance(600)
        #expect(try h.store.finish() == .finishing)

        // 1回目：失敗。finishing のまま、記録は増えず、保存先の ActiveReading も残る。
        #expect(throws: StoreError.saveFailed(.sessionFinish)) { _ = try h.store.finishSession(endPage: 72, minutes: 10) }
        #expect(h.store.active?.state == .finishing)
        #expect(h.store.sessions(for: bookID).isEmpty)
        #expect(try h.count(ReadingSession.self) == 0)
        #expect(try h.count(ActiveReading.self) == 1)

        // 2回目（error.retry と同じ呼び出し）：通る。rollback の後の2回目の save が失敗しないこと。
        h.advance(30)
        let sessionID = try h.store.finishSession(endPage: 72, minutes: 10)
        #expect(h.store.active == nil)
        #expect(h.store.sessions(for: bookID).map(\.id) == [sessionID])
        #expect(h.store.sessions(for: bookID).first?.durationSeconds == 600)
        #expect(h.store.book(id: bookID)?.lastPage == 72)
        #expect(h.store.book(id: bookID)?.sessionCount == 1)
        #expect(try h.count(ReadingSession.self) == 1)
        #expect(try h.count(ActiveReading.self) == 0)
        let row = try #require(try h.container.mainContext.fetch(FetchDescriptor<Book>()).first)
        #expect(row.lastPage == 72)
        #expect(row.sessions.count == 1)
        let events = await h.events()
        #expect(events.filter { $0 == .saveFailed(operation: .sessionFinish) }.count == 1)
        #expect(events.filter { $0.name == "Reading Session Finished" }.count == 1)
    }

    @Test(
        "AC-35 の形：ファイルの保存先（記録2件、最後のページ40、経過10:00 の finishing）を読み、記録の保存が1回失敗 → もう一度保存で3件。開き直しても3件",
        arguments: [nil, 72] as [Int?])
    func finishFailureThenRetryOnDiskSeed(endPage: Int?) async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory.appending(
            path: "YomutokiTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }
        let storeURL = directory.appending(path: LibraryContainer.storeFileName, directoryHint: .notDirectory)
        let schema = Schema(versionedSchema: SchemaV1.self)
        func openStore() throws -> ModelContainer {
            let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            return try ModelContainer(
                for: schema, migrationPlan: LibraryMigrationPlan.self, configurations: configuration)
        }

        // seed と同じく、別の ModelContainer で書いてから閉じる（Debug/UITestHooks.swift の SeedWriter と同じ入れ方）。
        let bookID = UUID()
        do {
            let writer = try openStore()
            let context = writer.mainContext
            context.autosaveEnabled = false
            let book = Book(
                id: bookID, title: "坊っちゃん", totalPages: 300, lastPage: 40,
                addedAt: StoreHarness.base.addingTimeInterval(-7 * 86_400))
            context.insert(book)
            for (daysAgo, page) in [(2.0, 20), (1.0, 40)] {
                let startedAt = StoreHarness.base.addingTimeInterval(-daysAgo * 86_400)
                let session = ReadingSession(
                    startedAt: startedAt, durationSeconds: 1_200, endPage: page, pagesRead: 20,
                    savedAt: startedAt.addingTimeInterval(1_200))
                context.insert(session)
                session.book = book
            }
            let active = ActiveReading(
                state: ReadingState.finishing.rawValue, startedAt: StoreHarness.base.addingTimeInterval(-600),
                finishedAt: StoreHarness.base)
            context.insert(active)
            active.book = book
            try context.save()
        }

        let h = try StoreHarness(fail: [.sessionFinish: .times(1)], container: openStore())
        h.store.load()
        #expect(h.store.loadState == .loaded)
        #expect(h.store.active?.state == .finishing)
        #expect(h.store.active?.initialMinutes == 10)

        #expect(throws: StoreError.saveFailed(.sessionFinish)) {
            _ = try h.store.finishSession(endPage: endPage, minutes: 10)
        }
        #expect(h.store.active?.state == .finishing)
        #expect(h.store.sessions(for: bookID).count == 2)
        #expect(h.store.book(id: bookID)?.lastPage == 40)
        #expect(try h.count(ReadingSession.self) == 2)
        #expect(try h.count(ActiveReading.self) == 1)

        let sessionID = try h.store.finishSession(endPage: endPage, minutes: 10)
        #expect(h.store.active == nil)
        #expect(h.store.sessions(for: bookID).count == 3)
        let saved = h.store.sessions(for: bookID).filter { $0.id == sessionID }
        #expect(saved.count == 1)
        #expect(saved.first?.durationSeconds == 600)
        #expect(saved.first?.endPage == endPage)
        #expect(saved.first?.pagesRead == endPage.map { $0 - 40 })
        #expect(h.store.book(id: bookID)?.sessionCount == 3)
        #expect(h.store.book(id: bookID)?.lastPage == (endPage ?? 40))
        #expect(try h.count(ReadingSession.self) == 3)
        #expect(try h.count(ActiveReading.self) == 0)
        let events = await h.events()
        #expect(events.filter { $0 == .saveFailed(operation: .sessionFinish) }.count == 1)
        #expect(events.filter { $0.name == "Reading Session Finished" }.count == 1)

        // 起動し直したときと同じく、別の ModelContainer で開き直しても3件、ActiveReading は0件。
        let reader = try openStore()
        #expect(try reader.mainContext.fetchCount(FetchDescriptor<ReadingSession>()) == 3)
        #expect(try reader.mainContext.fetchCount(FetchDescriptor<ActiveReading>()) == 0)
        let book = try #require(try reader.mainContext.fetch(FetchDescriptor<Book>()).first)
        #expect(book.lastPage == (endPage ?? 40))
        #expect(book.sessions.count == 3)
        let relaunched = try StoreHarness(container: reader)
        relaunched.store.load()
        #expect(relaunched.store.loadState == .loaded)
        #expect(relaunched.store.active == nil)
        #expect(relaunched.store.sessions(for: bookID).count == 3)
    }

    @Test("本の追加の保存に失敗：本は増えない（AC-42）。記録を消す保存に失敗：記録は残る（AC-43）")
    func addAndDeleteFailures() throws {
        let h = try StoreHarness(fail: [.bookAdd: .times(1), .sessionDelete: .times(1)])
        h.store.load()
        #expect(throws: StoreError.saveFailed(.bookAdd)) { _ = try h.store.addBook(title: "坊っちゃん", totalPages: 300) }
        #expect(h.store.books.isEmpty)
        #expect(try h.count(Book.self) == 0)
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        try h.store.startReading(bookID: bookID, source: .home)
        h.advance(600)
        _ = try h.store.finish()
        let sessionID = try h.store.finishSession(endPage: 72, minutes: 10)
        #expect(throws: StoreError.saveFailed(.sessionDelete)) { try h.store.deleteSession(id: sessionID) }
        #expect(h.store.sessions(for: bookID).count == 1)
        #expect(try h.count(ReadingSession.self) == 1)
    }

    @Test("入力の範囲：空の題名、総ページ数 0 と 10000、総ページ数を超えるページは保存しない")
    func inputRanges() throws {
        let h = try StoreHarness()
        h.store.load()
        #expect(throws: StoreError.invalidInput) { _ = try h.store.addBook(title: " \u{3000}\n", totalPages: nil) }
        #expect(throws: StoreError.invalidInput) { _ = try h.store.addBook(title: "a", totalPages: 0) }
        #expect(throws: StoreError.invalidInput) { _ = try h.store.addBook(title: "a", totalPages: 10_000) }
        let bookID = try h.store.addBook(title: "a", totalPages: 9_999)
        try h.store.startReading(bookID: bookID, source: .home)
        h.advance(60)
        _ = try h.store.finish()
        #expect(throws: StoreError.invalidInput) { _ = try h.store.finishSession(endPage: 10_000, minutes: 1) }
        #expect(throws: StoreError.invalidInput) { _ = try h.store.finishSession(endPage: -1, minutes: 1) }
    }

    // MARK: 読み込みの失敗（AC-54、AC-55）

    @Test("ActiveReading が2件あれば読み込みの失敗。保存先の行は消さない")
    func twoActiveReadingsFailLoad() async throws {
        let container = try LibraryContainer.makeInMemory()
        let context = container.mainContext
        let book = Book(title: "坊っちゃん", totalPages: 300, addedAt: StoreHarness.base)
        context.insert(book)
        for _ in 0..<2 {
            let active = ActiveReading(state: "reading", startedAt: StoreHarness.base)
            context.insert(active)
            active.book = book
        }
        try context.save()
        let h = try StoreHarness(container: container)
        h.store.load()
        #expect(h.store.loadState == .failed)
        #expect(h.store.books.isEmpty)
        #expect(try h.count(ActiveReading.self) == 2)
        #expect(try h.count(Book.self) == 1)
        #expect(await h.events() == [.loadFailed])
    }

    @Test("ファイルの保存先に ActiveReading が2件あれば読み込みの失敗。ストアのファイルと行は残る（data-model.md:36）")
    func twoActiveReadingsOnDiskFailLoadAndKeepFile() async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory.appending(
            path: "YomutokiTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }
        let storeURL = directory.appending(path: LibraryContainer.storeFileName, directoryHint: .notDirectory)
        let schema = Schema(versionedSchema: SchemaV1.self)
        func openStore() throws -> ModelContainer {
            let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            return try ModelContainer(
                for: schema, migrationPlan: LibraryMigrationPlan.self, configurations: configuration)
        }

        // 壊れたストアを作る（保存の層は2件目を作らないので、ModelContext で直に入れる）。
        do {
            let writer = try openStore()
            let context = writer.mainContext
            let book = Book(title: "坊っちゃん", totalPages: 300, addedAt: StoreHarness.base)
            context.insert(book)
            for _ in 0..<2 {
                let active = ActiveReading(state: "reading", startedAt: StoreHarness.base)
                context.insert(active)
                active.book = book
            }
            try context.save()
        }

        // 起動し直したときと同じく、別の ModelContainer でファイルを開いて読む。
        let h = try StoreHarness(container: openStore())
        h.store.load()
        #expect(h.store.loadState == .failed)
        #expect(h.store.books.isEmpty)
        #expect(h.store.active == nil)
        #expect(await h.events() == [.loadFailed])

        // ファイルは消さず、どの行も直さない。
        #expect(fileManager.fileExists(atPath: storeURL.path(percentEncoded: false)))
        let reader = try openStore()
        let actives = try reader.mainContext.fetch(FetchDescriptor<ActiveReading>())
        #expect(actives.count == 2)
        #expect(actives.allSatisfy { $0.state == "reading" })
        #expect(try reader.mainContext.fetchCount(FetchDescriptor<Book>()) == 1)
    }

    @Test("state が知らない値なら読み込みの失敗")
    func unknownStateFailsLoad() throws {
        let container = try LibraryContainer.makeInMemory()
        let context = container.mainContext
        let book = Book(title: "坊っちゃん", totalPages: 300, addedAt: StoreHarness.base)
        context.insert(book)
        let active = ActiveReading(state: "unknown", startedAt: StoreHarness.base)
        context.insert(active)
        active.book = book
        try context.save()
        let h = try StoreHarness(container: container)
        h.store.load()
        #expect(h.store.loadState == .failed)
        #expect(try h.count(ActiveReading.self) == 1)
        #expect(throws: StoreError.notLoaded) { _ = try h.store.addBook(title: "こころ", totalPages: nil) }
    }

    @Test("読み込みの失敗の後の再試行で読める。進行中の読書があれば Restored を1件（AC-55）")
    func loadRetry() async throws {
        let container = try LibraryContainer.makeInMemory()
        let context = container.mainContext
        let book = Book(title: "坊っちゃん", totalPages: 300, addedAt: StoreHarness.base)
        context.insert(book)
        let active = ActiveReading(
            state: "paused", startedAt: StoreHarness.base, pausedAt: StoreHarness.base.addingTimeInterval(300),
            wasPaused: true)
        context.insert(active)
        active.book = book
        try context.save()
        let h = try StoreHarness(fail: [.load: .times(1)], container: container)
        h.store.load()
        #expect(h.store.loadState == .failed)
        h.store.retryLoad()
        #expect(h.store.loadState == .loaded)
        #expect(h.store.active?.state == .paused)
        #expect(h.store.active?.elapsedSeconds(now: h.clock.now()) == 300)
        #expect(await h.events() == [.loadFailed, .readingSessionRestored(state: .paused)])
    }
}
