import Foundation
import Observation
import OSLog
import SwiftData

/// 保存の層の操作の名前（contracts/data-model.md の保存の操作、test-hooks.md の T5 の名前と同じ文字）。
nonisolated enum StoreOperation: String, Sendable, CaseIterable {
    case load
    case bookAdd = "book_add"
    case sessionStart = "session_start"
    case sessionPause = "session_pause"
    case sessionResume = "session_resume"
    case sessionBeginFinish = "session_begin_finish"
    case sessionCancelFinish = "session_cancel_finish"
    case sessionDiscard = "session_discard"
    case sessionFinish = "session_finish"
    case sessionDelete = "session_delete"

    /// 計測の Save Failed の operation。load は Load Failed なので nil。
    var saveOperation: SaveOperation? {
        SaveOperation(rawValue: rawValue)
    }
}

/// 操作が通らなかった理由。saveFailed のときは画面に error.saveFailed と error.retry を出す（PRD 10）。
nonisolated enum StoreError: Error, Equatable, Sendable {
    /// 読み込みが通る前に操作した。
    case notLoaded
    /// 入力が範囲の外（題名が空、ページや分が範囲の外）。
    case invalidInput
    /// 今の状態ではできない操作（例：reading でないのに一時停止）。
    case invalidState
    case notFound
    /// 保存に失敗し、rollback した。状態は前のまま。
    case saveFailed(StoreOperation)
}

/// 読み込みの失敗の理由（どれも AC-54 と同じ表示。保存先は消さず、どの行も直さない）。
nonisolated enum LibraryLoadError: Error, Equatable, Sendable {
    case tooManyActiveReadings(Int)
    case unknownState
    case activeReadingWithoutBook
}

/// 読み込みの3つの状態（design 5 の S1：読み込み中、読めた、エラー）。
nonisolated enum LibraryLoadState: Equatable, Sendable {
    case loading
    case loaded
    case failed
}

/// 保存の層（ADR 0001、contracts/data-model.md）。
/// - 画面は @Query を使わず、ここが読んだ値（〜Snapshot）を見る。
/// - 1つの操作は1回の save。失敗したら rollback し、画面とメモリの値を変えない（保存が通ってから変える）。
/// - 操作の時刻は、その操作の保存を試した回の時刻（再試行ならその時刻）。
@MainActor
@Observable
final class LibraryStore {
    private(set) var loadState: LibraryLoadState = .loading
    /// 本の一覧の順（D-31）：前の本を先頭に、ほかは最後の記録の savedAt（なければ addedAt）の新しい順（ordered）。
    private(set) var books: [BookSnapshot] = []
    /// 本ごとの記録（読み始めた時刻の新しい順。D-32）。
    private(set) var sessionsByBook: [UUID: [SessionSnapshot]] = [:]
    private(set) var active: ActiveSnapshot?

    let clock: AppClock
    @ObservationIgnored var calendar: Calendar
    /// 保存と読み込みの直前に呼ぶ関数。既定は何もしない。Debug のテストのつなぎ口（T5）だけが失敗を入れる（設計メモ 3）。
    @ObservationIgnored var beforeSave: @MainActor (StoreOperation) throws -> Void = { _ in }

    private let telemetry: TelemetryRecorder?
    private let openContainer: @MainActor () throws -> ModelContainer
    @ObservationIgnored private var container: ModelContainer?
    @ObservationIgnored private var bookModels: [UUID: Book] = [:]
    @ObservationIgnored private var sessionModels: [UUID: ReadingSession] = [:]
    @ObservationIgnored private var activeModel: ActiveReading?
    private let logger = Logger(subsystem: LibraryStore.logSubsystem, category: "store")

    nonisolated static let logSubsystem = Bundle.main.bundleIdentifier ?? "com.example.yomutoki"

    init(
        clock: AppClock, calendar: Calendar, telemetry: TelemetryRecorder?,
        openContainer: @escaping @MainActor () throws -> ModelContainer
    ) {
        self.clock = clock
        self.calendar = calendar
        self.telemetry = telemetry
        self.openContainer = openContainer
    }

    // MARK: 読み込み

    /// 保存先を開いて全部を読む。失敗したら保存先を消さず、読み込みの失敗にする（AC-54、AC-55）。
    func load() {
        loadState = .loading
        do {
            let context = try mainContext()
            try beforeSave(.load)
            let bookRows = try context.fetch(FetchDescriptor<Book>())
            let sessionRows = try context.fetch(FetchDescriptor<ReadingSession>())
            let activeRows = try context.fetch(FetchDescriptor<ActiveReading>())
            let activeSnapshot = try Self.validatedActive(activeRows)
            apply(books: bookRows, sessions: sessionRows, activeModel: activeRows.first, active: activeSnapshot)
            loadState = .loaded
            if let activeSnapshot {
                telemetry?.sessionRestored(state: activeSnapshot.state)
            }
        } catch {
            logger.error("load failed: \(String(describing: error), privacy: .private)")
            clearMemory()
            loadState = .failed
            telemetry?.loadFailed()
        }
    }

    /// error.loadFailed.retry（AC-55）。
    func retryLoad() {
        load()
    }

    // MARK: 読む値

    func book(id: UUID) -> BookSnapshot? {
        books.first { $0.id == id }
    }

    func sessions(for bookID: UUID) -> [SessionSnapshot] {
        sessionsByBook[bookID] ?? []
    }

    /// 前の本（PRD 10、data-model.md）：進行中の読書があればその本。なければ残っている記録のうち savedAt がいちばん新しい記録の本。
    /// 記録が0件なら addedAt がいちばん新しい本。保存せず、読むたびにこの順で出す。
    var previousBookID: UUID? {
        Self.previousBookID(in: books, activeBookID: active?.bookID)
    }

    /// 前の本の決め方（previousBookID と本の一覧の順で同じものを使う）。
    static func previousBookID(in books: [BookSnapshot], activeBookID: UUID?) -> UUID? {
        if let activeBookID { return activeBookID }
        var latestSaved: BookSnapshot?
        for book in books {
            guard let saved = book.lastSavedAt else { continue }
            if let current = latestSaved?.lastSavedAt, current >= saved { continue }
            latestSaved = book
        }
        if let latestSaved { return latestSaved.id }
        return books.max { $0.addedAt < $1.addedAt }?.id
    }

    /// その時刻を含む週（暦の設定の週の始め）に読み始めた記録の秒の合計。
    func weekTotalSeconds(containing date: Date) -> Int {
        guard let week = ReadingMath.week(containing: date, calendar: calendar) else { return 0 }
        var total = 0
        for list in sessionsByBook.values {
            for session in list where ReadingMath.contains(week, session.startedAt) {
                total += session.durationSeconds
            }
        }
        return total
    }

    /// 今週の合計（分、切り捨て。秒で足してから分にする）。
    func weekTotalMinutes(now: Date) -> Int {
        ReadingMath.wholeMinutes(seconds: weekTotalSeconds(containing: now))
    }

    // MARK: 操作（どれも1回の save。失敗したら rollback して StoreError.saveFailed を投げる）

    /// 本を追加する（AC-2、AC-3、AC-31、AC-42）。題名は形B で整えてから保存する。
    @discardableResult
    func addBook(title rawTitle: String, totalPages: Int?) throws -> UUID {
        let context = try loadedContext()
        let title = TitleRules.stored(rawTitle)
        guard !title.isEmpty else { throw StoreError.invalidInput }
        if let totalPages, !ReadingMath.totalPagesRange.contains(totalPages) { throw StoreError.invalidInput }
        let book = Book(title: title, totalPages: totalPages, addedAt: clock.now())
        context.insert(book)
        try commit(.bookAdd, context: context)
        bookModels[book.id] = book
        books = Self.ordered(books + [Self.snapshot(of: book, sessions: [])], activeBookID: active?.bookID)
        telemetry?.bookAdded(bookCount: books.count, hasTotalPages: totalPages != nil)
        return book.id
    }

    /// 読み始める（AC-4、AC-5、AC-56、AC-57）。startedAt は保存が通った回の時刻。
    func startReading(bookID: UUID, source: StartSource) throws {
        let context = try loadedContext()
        guard active == nil, activeModel == nil else { throw StoreError.invalidState }
        guard let book = bookModels[bookID] else { throw StoreError.notFound }
        let now = clock.now()
        let model = ActiveReading(state: ReadingState.reading.rawValue, startedAt: now)
        context.insert(model)
        model.book = book
        try commit(.sessionStart, context: context)
        activeModel = model
        active = ActiveSnapshot(
            bookID: bookID, state: .reading, startedAt: now, pausedTotalSeconds: 0, pausedAt: nil, finishedAt: nil,
            wasPaused: false)
        books = Self.ordered(books, activeBookID: bookID)
        telemetry?.sessionStarted(source: source)
    }

    /// 一時停止（AC-6、AC-58、AC-59）。
    func pause() throws {
        let context = try loadedContext()
        guard let model = activeModel, var next = active, next.state == .reading else { throw StoreError.invalidState }
        let now = clock.now()
        model.state = ReadingState.paused.rawValue
        model.pausedAt = now
        model.wasPaused = true
        try commit(.sessionPause, context: context)
        next.state = .paused
        next.pausedAt = now
        next.wasPaused = true
        active = next
    }

    /// 再開（AC-60、AC-61）。止めていた時間を pausedTotalSeconds に足す。
    func resume() throws {
        let context = try loadedContext()
        guard let model = activeModel, var next = active, next.state == .paused, let pausedAt = next.pausedAt else {
            throw StoreError.invalidState
        }
        let added = max(0, clock.now().timeIntervalSince(pausedAt))
        model.pausedTotalSeconds = next.pausedTotalSeconds + added
        model.pausedAt = nil
        model.state = ReadingState.reading.rawValue
        try commit(.sessionResume, context: context)
        next.pausedTotalSeconds += added
        next.pausedAt = nil
        next.state = .reading
        active = next
    }

    /// 「終える」（reading か paused で押す）。押した時点の経過で分ける（D-59、PRD 18 の 6 の A）：
    /// 60秒未満なら読書を消す保存（session_discard）、60秒以上なら finishing へ移る保存（session_begin_finish）。
    func finish() throws -> FinishOutcome {
        guard let current = active, current.state != .finishing else { throw StoreError.invalidState }
        if current.elapsedSeconds(now: clock.now()) < ReadingMath.minimumSessionSeconds {
            let bookID = try discardTooShort()
            return .discarded(bookID: bookID)
        }
        try beginFinish()
        return .finishing
    }

    /// 終える（経過60秒以上）：finishedAt＝今、state を finishing（AC-45、AC-62、AC-63）。
    func beginFinish() throws {
        let context = try loadedContext()
        guard let model = activeModel, var next = active, next.state != .finishing else { throw StoreError.invalidState }
        let now = clock.now()
        guard next.elapsedSeconds(now: now) >= ReadingMath.minimumSessionSeconds else { throw StoreError.invalidState }
        if next.state == .paused, let pausedAt = next.pausedAt {
            next.pausedTotalSeconds += max(0, now.timeIntervalSince(pausedAt))
        }
        next.pausedAt = nil
        next.finishedAt = now
        next.state = .finishing
        model.pausedTotalSeconds = next.pausedTotalSeconds
        model.pausedAt = nil
        model.finishedAt = now
        model.state = ReadingState.finishing.rawValue
        try commit(.sessionBeginFinish, context: context)
        active = next
    }

    /// 終える（経過60秒未満）：記録せずに進行中の読書を消す（AC-13、AC-51、AC-66、AC-67）。消した本の ID を返す。
    @discardableResult
    func discardTooShort() throws -> UUID {
        let context = try loadedContext()
        guard let model = activeModel, let current = active, current.state != .finishing else {
            throw StoreError.invalidState
        }
        guard current.elapsedSeconds(now: clock.now()) < ReadingMath.minimumSessionSeconds else {
            throw StoreError.invalidState
        }
        context.delete(model)
        try commit(.sessionDiscard, context: context)
        activeModel = nil
        active = nil
        books = Self.ordered(books, activeBookID: nil)
        telemetry?.sessionDiscarded()
        return current.bookID
    }

    /// 終える入力をやめる（「キャンセル」と下へのスワイプ。AC-46〜AC-48、AC-64、AC-65）。finishing にいた時間は数えない。
    func cancelFinish() throws {
        let context = try loadedContext()
        guard let model = activeModel, var next = active, next.state == .finishing, let finishedAt = next.finishedAt else {
            throw StoreError.invalidState
        }
        let added = max(0, clock.now().timeIntervalSince(finishedAt))
        model.pausedTotalSeconds = next.pausedTotalSeconds + added
        model.finishedAt = nil
        model.state = ReadingState.reading.rawValue
        try commit(.sessionCancelFinish, context: context)
        next.pausedTotalSeconds += added
        next.finishedAt = nil
        next.state = .reading
        active = next
    }

    /// 記録を保存する（AC-9〜AC-12、AC-19、AC-29、AC-30、AC-32、AC-35）。
    /// minutes は分の欄の値。初めの値（finishedAt での経過の分）と同じなら経過の秒を、違えば「分 × 60」を保存する。
    @discardableResult
    func finishSession(endPage: Int?, minutes: Int) throws -> UUID {
        let context = try loadedContext()
        guard let model = activeModel, let current = active, current.state == .finishing,
            let finishedAt = current.finishedAt, let book = bookModels[current.bookID]
        else { throw StoreError.invalidState }
        let elapsed = current.elapsedSeconds(now: finishedAt)
        let initialMinutes = ReadingMath.wholeMinutes(seconds: elapsed)
        guard initialMinutes >= 1, (1...initialMinutes).contains(minutes) else { throw StoreError.invalidInput }
        if let endPage {
            guard ReadingMath.pageRange.contains(endPage), endPage <= (book.totalPages ?? ReadingMath.pageRange.upperBound)
            else { throw StoreError.invalidInput }
        }
        let minutesEdited = minutes != initialMinutes
        let duration = minutesEdited ? minutes * 60 : elapsed
        let pagesRead = ReadingMath.pagesRead(endPage: endPage, previousLastPage: book.lastPage)
        let savedAt = clock.now()
        let session = ReadingSession(
            startedAt: current.startedAt, durationSeconds: duration, endPage: endPage, pagesRead: pagesRead,
            savedAt: savedAt)
        context.insert(session)
        session.book = book
        if let endPage {
            book.lastPage = endPage
        }
        context.delete(model)
        try commit(.sessionFinish, context: context)

        sessionModels[session.id] = session
        activeModel = nil
        active = nil
        var list = sessionsByBook[book.id] ?? []
        list.append(Self.snapshot(of: session, bookID: book.id))
        list.sort(by: SessionSnapshot.newestFirst)
        sessionsByBook[book.id] = list
        updateBook(book.id) { snapshot in
            if let endPage { snapshot.lastPage = endPage }
            snapshot.recount(list)
        }
        telemetry?.sessionFinished(
            durationSeconds: duration, pagesRead: pagesRead, minutesEdited: minutesEdited, wasPaused: current.wasPaused,
            savedAt: savedAt)
        telemetry?.weekProgress(
            sessionStartedAt: current.startedAt, weekTotalSeconds: weekTotalSeconds(containing: current.startedAt))
        return session.id
    }

    /// 記録を消す（AC-16、AC-43）。本の最後のページは変えない。前の本は変わりうる。
    func deleteSession(id: UUID) throws {
        let context = try loadedContext()
        guard let model = sessionModels[id], let bookID = model.book?.id else { throw StoreError.notFound }
        context.delete(model)
        try commit(.sessionDelete, context: context)
        sessionModels[id] = nil
        var list = sessionsByBook[bookID] ?? []
        list.removeAll { $0.id == id }
        sessionsByBook[bookID] = list
        updateBook(bookID) { $0.recount(list) }
    }

    // MARK: 中身

    private func mainContext() throws -> ModelContext {
        if let container { return container.mainContext }
        let made = try openContainer()
        made.mainContext.autosaveEnabled = false
        container = made
        return made.mainContext
    }

    private func loadedContext() throws -> ModelContext {
        guard loadState == .loaded, let container else { throw StoreError.notLoaded }
        return container.mainContext
    }

    /// 1回の save。失敗（つなぎ口の失敗を含む）は rollback して、計測の Save Failed を出し、StoreError.saveFailed を投げる。
    private func commit(_ operation: StoreOperation, context: ModelContext) throws {
        do {
            try beforeSave(operation)
            try context.save()
        } catch {
            context.rollback()
            logger.error("save failed: \(operation.rawValue, privacy: .public)")
            if let saveOperation = operation.saveOperation {
                telemetry?.saveFailed(saveOperation)
            }
            throw StoreError.saveFailed(operation)
        }
    }

    private func clearMemory() {
        bookModels = [:]
        sessionModels = [:]
        activeModel = nil
        books = []
        sessionsByBook = [:]
        active = nil
    }

    private func apply(
        books bookRows: [Book], sessions sessionRows: [ReadingSession], activeModel: ActiveReading?,
        active: ActiveSnapshot?
    ) {
        var models: [UUID: Book] = [:]
        for book in bookRows where models[book.id] == nil {
            models[book.id] = book
        }
        var sessions: [UUID: ReadingSession] = [:]
        var grouped: [UUID: [SessionSnapshot]] = [:]
        for session in sessionRows {
            guard let bookID = session.book?.id else {
                logger.error("session without book skipped")
                continue
            }
            sessions[session.id] = session
            grouped[bookID, default: []].append(Self.snapshot(of: session, bookID: bookID))
        }
        for key in Array(grouped.keys) {
            grouped[key]?.sort(by: SessionSnapshot.newestFirst)
        }
        bookModels = models
        sessionModels = sessions
        self.activeModel = activeModel
        sessionsByBook = grouped
        self.active = active
        let snapshots = models.values.map { Self.snapshot(of: $0, sessions: grouped[$0.id] ?? []) }
        books = Self.ordered(snapshots, activeBookID: active?.bookID)
    }

    private func updateBook(_ id: UUID, _ change: (inout BookSnapshot) -> Void) {
        var updated = books
        if let index = updated.firstIndex(where: { $0.id == id }) {
            change(&updated[index])
        }
        books = Self.ordered(updated, activeBookID: active?.bookID)
    }

    /// ActiveReading が2件以上か、state が知らない値か、本がないなら読み込みの失敗（data-model.md）。
    static func validatedActive(_ rows: [ActiveReading]) throws -> ActiveSnapshot? {
        guard rows.count <= 1 else { throw LibraryLoadError.tooManyActiveReadings(rows.count) }
        guard let row = rows.first else { return nil }
        guard let state = ReadingState(rawValue: row.state) else { throw LibraryLoadError.unknownState }
        guard let book = row.book else { throw LibraryLoadError.activeReadingWithoutBook }
        return ActiveSnapshot(
            bookID: book.id, state: state, startedAt: row.startedAt, pausedTotalSeconds: max(0, row.pausedTotalSeconds),
            pausedAt: row.pausedAt, finishedAt: row.finishedAt, wasPaused: row.wasPaused)
    }

    /// 本の一覧の順（design D-31。指揮役の決定）：前の本（previousBookID と同じ決め方）を先頭に、
    /// ほかは最後の記録の savedAt（記録がなければ addedAt）の新しい順。
    static func ordered(_ books: [BookSnapshot], activeBookID: UUID?) -> [BookSnapshot] {
        let previous = previousBookID(in: books, activeBookID: activeBookID)
        return books.sorted { lhs, rhs in
            let lhsFirst = lhs.id == previous
            let rhsFirst = rhs.id == previous
            if lhsFirst != rhsFirst { return lhsFirst }
            let lhsKey = lhs.lastSavedAt ?? lhs.addedAt
            let rhsKey = rhs.lastSavedAt ?? rhs.addedAt
            if lhsKey != rhsKey { return lhsKey > rhsKey }
            if lhs.addedAt != rhs.addedAt { return lhs.addedAt > rhs.addedAt }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    private static func snapshot(of book: Book, sessions: [SessionSnapshot]) -> BookSnapshot {
        var snapshot = BookSnapshot(
            id: book.id, title: book.title, totalPages: book.totalPages, lastPage: book.lastPage, addedAt: book.addedAt,
            totalSeconds: 0, sessionCount: 0, lastSavedAt: nil)
        snapshot.recount(sessions)
        return snapshot
    }

    private static func snapshot(of session: ReadingSession, bookID: UUID) -> SessionSnapshot {
        SessionSnapshot(
            id: session.id, bookID: bookID, startedAt: session.startedAt, durationSeconds: session.durationSeconds,
            endPage: session.endPage, pagesRead: session.pagesRead, savedAt: session.savedAt)
    }
}
