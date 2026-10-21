#if DEBUG
// テストのつなぎ口の2ファイルの片方（ADR 0005、contracts/test-hooks.md の T1〜T5、T15〜T17、T21、T22）。
// ファイル全体が Debug ビルドだけにある。起動の引数に -UITest があるときだけ読む。
// 知らない名前、形の合わない値、契約に合わない seed は、黙って無視せずに起動の直後に止める（fatalError に名前と理由）。
import Foundation
import Observation
import os
import SwiftData
import SwiftUI

/// つなぎ口の名前（この2ファイルの外に UITEST_ の文字を書かない。単体テストもここから引く）。
nonisolated enum UITestKey {
    static let launchArgument = "-UITest"
    static let prefix = "UITEST_"
    static let reset = "UITEST_RESET"
    static let seed = "UITEST_SEED"
    static let seedBulk = "UITEST_SEED_BULK"
    static let now = "UITEST_NOW"
    static let clockFrozen = "UITEST_CLOCK_FROZEN"
    static let timeZone = "UITEST_TIME_ZONE"
    static let locale = "UITEST_LOCALE"
    static let firstWeekday = "UITEST_FIRST_WEEKDAY"
    static let fail = "UITEST_FAIL"
    static let telemetryURL = "UITEST_TELEMETRY_URL"
    static let telemetryControlURL = "UITEST_TELEMETRY_CONTROL_URL"
    static let telemetryTimeout = "UITEST_TELEMETRY_TIMEOUT"
    static let telemetryLog = "UITEST_TELEMETRY_LOG"
    static let all: Set<String> = [
        reset, seed, seedBulk, now, clockFrozen, timeZone, locale, firstWeekday, fail, telemetryURL,
        telemetryControlURL, telemetryTimeout, telemetryLog,
    ]
    /// T4 の UITEST_LOCALE に渡せる値。
    static let allowedLocales: Set<String> = ["ja_JP", "en_US"]
    /// T16 の URL scheme（Debug の Info.plist にだけある）。
    static let urlScheme = "readingapp-uitest"
    static let clockHost = "clock"
    /// -UITest のときだけ出す 1pt の要素の識別子。
    static let clockAppliedIdentifier = "uitest.clock.applied"
    static let telemetryLogIdentifier = "uitest.telemetry.log"
}

/// つなぎ口の値が契約に合わないこと。起動では fatalError にし、単体テストでは投げられたことを確かめる。
nonisolated struct UITestConfigError: Error, Equatable, Sendable, CustomStringConvertible {
    let name: String
    let reason: String

    var description: String { "\(name): \(reason)" }
}

/// 壁時計の時刻（YYYY-MM-DDTHH:MM:SS、オフセットなし）を、決めた時間帯で読む。日付の繰り上がりを許さない。
nonisolated final class WallClockParser {
    private let formatter: DateFormatter

    init(timeZone: TimeZone) {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.isLenient = false
        self.formatter = formatter
    }

    func date(from text: String) -> Date? {
        guard text.count == 19, let date = formatter.date(from: text), formatter.string(from: date) == text else {
            return nil
        }
        return date
    }

    func text(from date: Date) -> String {
        formatter.string(from: date)
    }
}

// MARK: T5 保存の失敗

/// 失敗させる回数（1〜99 か、毎回）。
nonisolated enum FailureBudget: Equatable, Sendable {
    case times(Int)
    case always
}

/// つなぎ口が入れた失敗。保存の層は本物の失敗と同じ道（rollback、Save Failed、画面のエラー）を通す。
nonisolated struct InjectedSaveFailure: Error, Equatable, Sendable {
    let operation: StoreOperation
}

/// UITEST_FAIL の `<操作>:<回数>` をカンマで並べた文字を読む。
nonisolated enum FailurePlanParser {
    static func parse(_ text: String) throws -> [StoreOperation: FailureBudget] {
        var plan: [StoreOperation: FailureBudget] = [:]
        for entry in text.split(separator: ",", omittingEmptySubsequences: false) {
            let parts = entry.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count == 2, let operation = StoreOperation(rawValue: String(parts[0])) else {
                throw UITestConfigError(name: UITestKey.fail, reason: "操作の名前が契約にない、または <操作>:<回数> の形ではない")
            }
            guard plan[operation] == nil else {
                throw UITestConfigError(name: UITestKey.fail, reason: "同じ操作を2回書いた（\(operation.rawValue)）")
            }
            let countText = String(parts[1])
            if countText == "*" {
                plan[operation] = .always
            } else if let count = Int(countText), (1...99).contains(count), String(count) == countText {
                plan[operation] = .times(count)
            } else {
                throw UITestConfigError(name: UITestKey.fail, reason: "回数は 1〜99 か *")
            }
        }
        return plan
    }
}

/// 保存の層の入口（save と読み込みの直前）で呼ばれ、決めた回数だけ失敗させる。数は起動ごと。
@MainActor
final class FailureInjector {
    private var remaining: [StoreOperation: FailureBudget]

    init(_ plan: [StoreOperation: FailureBudget] = [:]) {
        remaining = plan
    }

    func check(_ operation: StoreOperation) throws {
        guard let budget = remaining[operation] else { return }
        switch budget {
        case .always:
            break
        case .times(let count):
            remaining[operation] = count > 1 ? .times(count - 1) : nil
        }
        throw InjectedSaveFailure(operation: operation)
    }
}

// MARK: T3、T16 時計

/// T16 の1つの URL の1つの操作。
nonisolated enum ClockCommand: Equatable, Sendable {
    /// -86,400〜86,400 秒。負は戻す。
    case advance(Int)
    /// true は今の値で止める、false は今の値から実時間で進める。
    case freeze(Bool)
    /// 壁時計の時刻にする（止めているかは変えない）。
    case set(Date)

    init(url: URL, timeZone: TimeZone) throws {
        let name = "\(UITestKey.urlScheme)://\(UITestKey.clockHost)"
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.scheme == UITestKey.urlScheme, components.host == UITestKey.clockHost,
            let items = components.queryItems, items.count == 1, let value = items[0].value
        else {
            throw UITestConfigError(name: name, reason: "1つの URL に1つの操作（advance、freeze、set）")
        }
        switch items[0].name {
        case "advance":
            guard let seconds = Int(value), (-86_400...86_400).contains(seconds) else {
                throw UITestConfigError(name: name, reason: "advance は -86400〜86400 の整数")
            }
            self = .advance(seconds)
        case "freeze":
            guard value == "0" || value == "1" else {
                throw UITestConfigError(name: name, reason: "freeze は 0 か 1")
            }
            self = .freeze(value == "1")
        case "set":
            guard let date = WallClockParser(timeZone: timeZone).date(from: value) else {
                throw UITestConfigError(name: name, reason: "set は壁時計の時刻")
            }
            self = .set(date)
        default:
            throw UITestConfigError(name: name, reason: "知らない操作")
        }
    }
}

/// 差し替えた時計（T3、T16）。起動のときの「今」から実時間で進むか、止めたまま。どの分離からでも読める。
nonisolated final class ClockController: Sendable {
    private struct State: Sendable {
        var wallAnchor: Date
        var realAnchor: Date
        var frozen: Bool
    }

    private let state: OSAllocatedUnfairLock<State>

    /// start が nil なら端末の時計の今から始める。
    init(start: Date?, frozen: Bool) {
        let real = Date()
        state = OSAllocatedUnfairLock(initialState: State(wallAnchor: start ?? real, realAnchor: real, frozen: frozen))
    }

    func now() -> Date {
        let real = Date()
        return state.withLock { ClockController.current($0, real: real) }
    }

    func apply(_ command: ClockCommand) {
        let real = Date()
        state.withLock { state in
            let current = ClockController.current(state, real: real)
            switch command {
            case .advance(let seconds):
                state.wallAnchor = current.addingTimeInterval(TimeInterval(seconds))
            case .freeze(let frozen):
                state.wallAnchor = current
                state.frozen = frozen
            case .set(let date):
                state.wallAnchor = date
            }
            state.realAnchor = real
        }
    }

    var clock: AppClock {
        AppClock(now: { [self] in self.now() })
    }

    private static func current(_ state: State, real: Date) -> Date {
        state.frozen ? state.wallAnchor : state.wallAnchor.addingTimeInterval(real.timeIntervalSince(state.realAnchor))
    }
}

// MARK: T2、T17、T21 データ

/// UITEST_SEED の JSON（contracts/seed.schema.json）。
nonisolated struct SeedDocument: Decodable, Sendable {
    struct BookEntry: Decodable, Sendable {
        let id: String
        let title: String
        let totalPages: Int?
        let lastPage: Int
        let addedAt: String
    }

    struct SessionEntry: Decodable, Sendable {
        let id: String
        let bookId: String
        let startedAt: String
        let durationSeconds: Int
        let endPage: Int?
        let pagesRead: Int?
        let savedAt: String
    }

    struct ActiveEntry: Decodable, Sendable {
        let bookId: String
        let state: String
        let startedAt: String
        let pausedTotalSeconds: Double
        let pausedAt: String?
        let finishedAt: String?
        let wasPaused: Bool
    }

    struct FlagsEntry: Decodable, Sendable {
        let firstOpenedAt: String?
        let firstSessionStarted: Bool?
        let first5minDone: Bool?
        let weekReachedWeekStart: String?
    }

    let version: Int
    let books: [BookEntry]
    let sessions: [SessionEntry]?
    let active: ActiveEntry?
    let flags: FlagsEntry?
}

/// 確かめ終えた、保存先に入れるデータ。
nonisolated struct ValidatedSeed: Sendable {
    struct BookRow: Equatable, Sendable {
        let id: UUID
        let title: String
        let totalPages: Int?
        let lastPage: Int
        let addedAt: Date
    }

    struct SessionRow: Equatable, Sendable {
        let id: UUID
        let bookID: UUID
        let startedAt: Date
        let durationSeconds: Int
        let endPage: Int?
        let pagesRead: Int?
        let savedAt: Date
    }

    struct ActiveRow: Equatable, Sendable {
        let bookID: UUID
        let state: ReadingState
        let startedAt: Date
        let pausedTotalSeconds: Double
        let pausedAt: Date?
        let finishedAt: Date?
        let wasPaused: Bool
    }

    struct FlagRows: Equatable, Sendable {
        var firstOpenedAt: Date?
        var firstSessionStarted = false
        var first5minDone = false
        var weekReachedWeekStart: Date?
    }

    var books: [BookRow] = []
    var sessions: [SessionRow] = []
    var active: ActiveRow?
    var flags: FlagRows?
}

/// UITEST_SEED を読み、seed.schema.json と data-model.md の最後の節の制約を確かめる。
nonisolated enum SeedParser {
    static let topRequired: Set<String> = ["version", "books"]
    static let topAllowed: Set<String> = ["version", "books", "sessions", "active", "flags"]
    static let bookKeys: Set<String> = ["id", "title", "totalPages", "lastPage", "addedAt"]
    static let sessionKeys: Set<String> = [
        "id", "bookId", "startedAt", "durationSeconds", "endPage", "pagesRead", "savedAt",
    ]
    static let activeKeys: Set<String> = [
        "bookId", "state", "startedAt", "pausedTotalSeconds", "pausedAt", "finishedAt", "wasPaused",
    ]
    static let flagKeys: Set<String> = ["firstOpenedAt", "firstSessionStarted", "first5minDone", "weekReachedWeekStart"]

    static func parse(_ text: String, timeZone: TimeZone) throws -> ValidatedSeed {
        let data = Data(text.utf8)
        try checkKeys(data)
        let document: SeedDocument
        do {
            document = try JSONDecoder().decode(SeedDocument.self, from: data)
        } catch {
            throw failure("seed.schema.json の型に合わない")
        }
        return try validate(document, timeZone: timeZone)
    }

    /// 項目の過不足（additionalProperties: false と required）。JSONDecoder は知らない項目を黙って捨てるので、先に数える。
    static func checkKeys(_ data: Data) throws {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw failure("JSON として読めない")
        }
        guard let root = object as? [String: Any] else { throw failure("最上位が object ではない") }
        try check(root, required: topRequired, allowed: topAllowed, at: "seed")
        try checkArray(root["books"], keys: bookKeys, at: "books")
        try checkArray(root["sessions"], keys: sessionKeys, at: "sessions")
        if let active = root["active"] as? [String: Any] {
            try check(active, required: activeKeys, allowed: activeKeys, at: "active")
        }
        if let flags = root["flags"] as? [String: Any] {
            try check(flags, required: [], allowed: flagKeys, at: "flags")
        }
    }

    static func validate(_ document: SeedDocument, timeZone: TimeZone) throws -> ValidatedSeed {
        guard document.version == 1 else { throw failure("version は 1 だけ") }
        let sessionEntries = document.sessions ?? []
        guard document.books.count <= 600, sessionEntries.count <= 12_000 else { throw failure("件数が上限を超える") }
        let wallClock = WallClockParser(timeZone: timeZone)
        var seed = ValidatedSeed()
        var booksByID: [UUID: ValidatedSeed.BookRow] = [:]

        for (index, entry) in document.books.enumerated() {
            let path = "books[\(index)]"
            let id = try uuid(entry.id, at: path)
            guard booksByID[id] == nil else { throw failure("\(path).id が重なる") }
            guard (1...TitleRules.maxLength).contains(entry.title.count) else { throw failure("\(path).title は1〜100字") }
            if let totalPages = entry.totalPages, !ReadingMath.totalPagesRange.contains(totalPages) {
                throw failure("\(path).totalPages は null か 1〜9999")
            }
            guard ReadingMath.pageRange.contains(entry.lastPage),
                entry.lastPage <= (entry.totalPages ?? ReadingMath.pageRange.upperBound)
            else { throw failure("\(path).lastPage は 0〜9999 で totalPages 以下") }
            let row = ValidatedSeed.BookRow(
                id: id, title: entry.title, totalPages: entry.totalPages, lastPage: entry.lastPage,
                addedAt: try date(entry.addedAt, at: "\(path).addedAt", wallClock))
            booksByID[id] = row
            seed.books.append(row)
        }

        var sessionIDs = Set<UUID>()
        for (index, entry) in sessionEntries.enumerated() {
            let path = "sessions[\(index)]"
            let id = try uuid(entry.id, at: path)
            guard sessionIDs.insert(id).inserted else { throw failure("\(path).id が重なる") }
            let bookID = try uuid(entry.bookId, at: "\(path).bookId")
            guard let book = booksByID[bookID] else { throw failure("\(path).bookId が books にない") }
            guard entry.durationSeconds >= ReadingMath.minimumSessionSeconds else {
                throw failure("\(path).durationSeconds は60以上")
            }
            if let endPage = entry.endPage {
                guard ReadingMath.pageRange.contains(endPage),
                    endPage <= (book.totalPages ?? ReadingMath.pageRange.upperBound)
                else { throw failure("\(path).endPage は 0〜9999 で totalPages 以下") }
                guard let pagesRead = entry.pagesRead, ReadingMath.pageRange.contains(pagesRead) else {
                    throw failure("\(path).pagesRead は endPage があれば 0〜9999")
                }
            } else if entry.pagesRead != nil {
                throw failure("\(path).pagesRead は endPage が null なら null")
            }
            seed.sessions.append(
                ValidatedSeed.SessionRow(
                    id: id, bookID: bookID, startedAt: try date(entry.startedAt, at: "\(path).startedAt", wallClock),
                    durationSeconds: entry.durationSeconds, endPage: entry.endPage, pagesRead: entry.pagesRead,
                    savedAt: try date(entry.savedAt, at: "\(path).savedAt", wallClock)))
        }

        if let entry = document.active {
            let bookID = try uuid(entry.bookId, at: "active.bookId")
            guard booksByID[bookID] != nil else { throw failure("active.bookId が books にない") }
            guard let state = ReadingState(rawValue: entry.state) else { throw failure("active.state が知らない値") }
            guard entry.pausedTotalSeconds.isFinite, entry.pausedTotalSeconds >= 0 else {
                throw failure("active.pausedTotalSeconds は0以上")
            }
            let pausedAt = try entry.pausedAt.map { try date($0, at: "active.pausedAt", wallClock) }
            let finishedAt = try entry.finishedAt.map { try date($0, at: "active.finishedAt", wallClock) }
            let consistent: Bool
            switch state {
            case .reading: consistent = pausedAt == nil && finishedAt == nil
            case .paused: consistent = pausedAt != nil && finishedAt == nil && entry.wasPaused
            case .finishing: consistent = pausedAt == nil && finishedAt != nil
            }
            guard consistent else { throw failure("active の state と pausedAt、finishedAt、wasPaused の組が合わない") }
            seed.active = ValidatedSeed.ActiveRow(
                bookID: bookID, state: state, startedAt: try date(entry.startedAt, at: "active.startedAt", wallClock),
                pausedTotalSeconds: entry.pausedTotalSeconds, pausedAt: pausedAt, finishedAt: finishedAt,
                wasPaused: entry.wasPaused)
        }

        if let entry = document.flags {
            seed.flags = ValidatedSeed.FlagRows(
                firstOpenedAt: try entry.firstOpenedAt.map { try date($0, at: "flags.firstOpenedAt", wallClock) },
                firstSessionStarted: entry.firstSessionStarted ?? false,
                first5minDone: entry.first5minDone ?? false,
                weekReachedWeekStart: try entry.weekReachedWeekStart.map {
                    try date($0, at: "flags.weekReachedWeekStart", wallClock)
                })
        }
        return seed
    }

    private static func failure(_ reason: String) -> UITestConfigError {
        UITestConfigError(name: UITestKey.seed, reason: reason)
    }

    private static func check(
        _ object: [String: Any], required: Set<String>, allowed: Set<String>, at path: String
    ) throws {
        let keys = Set(object.keys)
        if let missing = required.subtracting(keys).sorted().first {
            throw failure("\(path) に \(missing) がない")
        }
        if let extra = keys.subtracting(allowed).sorted().first {
            throw failure("\(path) に契約にない項目 \(extra)")
        }
    }

    private static func checkArray(_ value: Any?, keys: Set<String>, at path: String) throws {
        guard let value else { return }
        guard let items = value as? [Any] else { throw failure("\(path) が配列ではない") }
        for (index, item) in items.enumerated() {
            guard let object = item as? [String: Any] else { throw failure("\(path)[\(index)] が object ではない") }
            try check(object, required: keys, allowed: keys, at: "\(path)[\(index)]")
        }
    }

    private static func uuid(_ text: String, at path: String) throws -> UUID {
        guard text.count == 36, text == text.lowercased(), let id = UUID(uuidString: text) else {
            throw failure("\(path) が小文字の UUID ではない")
        }
        return id
    }

    private static func date(_ text: String, at path: String, _ wallClock: WallClockParser) throws -> Date {
        guard let value = wallClock.date(from: text) else { throw failure("\(path) が壁時計の形ではない") }
        return value
    }
}

/// T21 UITEST_SEED_BULK（books=<1〜600>,sessions=<0〜12000>）。決まった形でアプリが作る。
nonisolated struct BulkSpec: Equatable, Sendable {
    let books: Int
    let sessions: Int

    static func parse(_ text: String) throws -> BulkSpec {
        var values: [String: Int] = [:]
        for part in text.split(separator: ",", omittingEmptySubsequences: false) {
            let pair = part.split(separator: "=", omittingEmptySubsequences: false)
            guard pair.count == 2, let number = Int(pair[1]), String(number) == String(pair[1]),
                values[String(pair[0])] == nil
            else { throw UITestConfigError(name: UITestKey.seedBulk, reason: "books=<数>,sessions=<数> の形ではない") }
            values[String(pair[0])] = number
        }
        guard values.count == 2, let books = values["books"], let sessions = values["sessions"],
            (1...600).contains(books), (0...12_000).contains(sessions)
        else { throw UITestConfigError(name: UITestKey.seedBulk, reason: "books は 1〜600、sessions は 0〜12000") }
        return BulkSpec(books: books, sessions: sessions)
    }

    /// 題名「本 001」〜、総ページ数300、最後のページ0。記録は本に順に配り、startedAt は now の前の365日に均等、長さ1,800秒、ページなし。
    func makeSeed(now: Date) -> ValidatedSeed {
        let day: TimeInterval = 86_400
        var seed = ValidatedSeed()
        let addedBase = now.addingTimeInterval(-366 * day)
        for index in 1...books {
            seed.books.append(
                ValidatedSeed.BookRow(
                    id: UUID(), title: String(format: "本 %03ld", index), totalPages: 300, lastPage: 0,
                    addedAt: addedBase.addingTimeInterval(TimeInterval(index))))
        }
        let span = 365 * day
        for index in 0..<sessions {
            let book = seed.books[index % seed.books.count]
            let startedAt = now.addingTimeInterval(-span + span * Double(index) / Double(sessions))
            seed.sessions.append(
                ValidatedSeed.SessionRow(
                    id: UUID(), bookID: book.id, startedAt: startedAt, durationSeconds: 1_800, endPage: nil,
                    pagesRead: nil, savedAt: startedAt.addingTimeInterval(1_800)))
        }
        return seed
    }
}

/// 確かめたデータを保存先と計測の印に入れる。この保存は UITEST_FAIL の数に入れない（保存の層を通さない）。
@MainActor
enum SeedWriter {
    static func write(_ seed: ValidatedSeed, into container: ModelContainer, defaults: UserDefaults) throws {
        let context = container.mainContext
        context.autosaveEnabled = false
        var books: [UUID: Book] = [:]
        for row in seed.books {
            let book = Book(
                id: row.id, title: row.title, totalPages: row.totalPages, lastPage: row.lastPage, addedAt: row.addedAt)
            context.insert(book)
            books[row.id] = book
        }
        for row in seed.sessions {
            let session = ReadingSession(
                id: row.id, startedAt: row.startedAt, durationSeconds: row.durationSeconds, endPage: row.endPage,
                pagesRead: row.pagesRead, savedAt: row.savedAt)
            context.insert(session)
            session.book = books[row.bookID]
        }
        if let row = seed.active {
            let active = ActiveReading(
                state: row.state.rawValue, startedAt: row.startedAt, pausedTotalSeconds: row.pausedTotalSeconds,
                pausedAt: row.pausedAt, finishedAt: row.finishedAt, wasPaused: row.wasPaused)
            context.insert(active)
            active.book = books[row.bookID]
        }
        try context.save()
        if let flags = seed.flags {
            store(flags.firstOpenedAt, forKey: TelemetryFlagKey.firstOpenedAt, in: defaults)
            defaults.set(flags.firstSessionStarted, forKey: TelemetryFlagKey.firstSessionStarted)
            defaults.set(flags.first5minDone, forKey: TelemetryFlagKey.first5minDone)
            store(flags.weekReachedWeekStart, forKey: TelemetryFlagKey.weekReachedWeekStart, in: defaults)
        }
    }

    private static func store(_ date: Date?, forKey key: String, in defaults: UserDefaults) {
        if let date {
            defaults.set(date, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}

// MARK: 起動の設定

/// -UITest のときに読んだ、つなぎ口の値（contracts/test-hooks.md の表）。
nonisolated struct UITestConfiguration: Sendable {
    var reset = false
    var seed: ValidatedSeed?
    var bulk: BulkSpec?
    var now: Date?
    var clockFrozen = false
    var timeZone: TimeZone?
    var locale: Locale?
    var firstWeekday: Int?
    var failures: [StoreOperation: FailureBudget] = [:]
    var telemetryURL: URL?
    var telemetryControlURL: URL?
    var telemetryTimeout = 30
    var telemetryLog = false

    /// seed と UITEST_NOW と T16 の set を読む時間帯（T15。なければ端末の時間帯）。
    var wallClockTimeZone: TimeZone { timeZone ?? TimeZone.current }

    /// -UITest がなければ nil（UITEST_ の値があっても読まない）。
    static func parse(arguments: [String], environment: [String: String]) throws -> UITestConfiguration? {
        guard arguments.contains(UITestKey.launchArgument) else { return nil }
        let unknown = environment.keys.filter { $0.hasPrefix(UITestKey.prefix) && !UITestKey.all.contains($0) }
        if let name = unknown.sorted().first {
            throw UITestConfigError(name: name, reason: "契約（contracts/test-hooks.md）にない名前")
        }
        var configuration = UITestConfiguration()
        configuration.reset = try flag(environment, UITestKey.reset)
        configuration.clockFrozen = try flag(environment, UITestKey.clockFrozen)
        configuration.telemetryLog = try flag(environment, UITestKey.telemetryLog)
        if let text = environment[UITestKey.timeZone] {
            guard let timeZone = TimeZone(identifier: text) else {
                throw UITestConfigError(name: UITestKey.timeZone, reason: "IANA の時間帯の名前ではない")
            }
            configuration.timeZone = timeZone
        }
        if let text = environment[UITestKey.locale] {
            guard UITestKey.allowedLocales.contains(text) else {
                throw UITestConfigError(name: UITestKey.locale, reason: "ja_JP か en_US だけ")
            }
            configuration.locale = Locale(identifier: text)
        }
        if let text = environment[UITestKey.firstWeekday] {
            configuration.firstWeekday = try integer(text, in: 1...7, name: UITestKey.firstWeekday)
        }
        if let text = environment[UITestKey.now] {
            guard let date = WallClockParser(timeZone: configuration.wallClockTimeZone).date(from: text) else {
                throw UITestConfigError(name: UITestKey.now, reason: "壁時計の形（YYYY-MM-DDTHH:MM:SS）ではない")
            }
            configuration.now = date
        }
        if let text = environment[UITestKey.fail] {
            configuration.failures = try FailurePlanParser.parse(text)
        }
        if let text = environment[UITestKey.telemetryURL] {
            configuration.telemetryURL = try localURL(text, name: UITestKey.telemetryURL)
        }
        if let text = environment[UITestKey.telemetryControlURL] {
            configuration.telemetryControlURL = try localURL(text, name: UITestKey.telemetryControlURL)
        }
        if let text = environment[UITestKey.telemetryTimeout] {
            configuration.telemetryTimeout = try integer(text, in: 1...60, name: UITestKey.telemetryTimeout)
        }
        let seedText = environment[UITestKey.seed]
        let bulkText = environment[UITestKey.seedBulk]
        if seedText != nil, bulkText != nil {
            throw UITestConfigError(name: UITestKey.seedBulk, reason: "\(UITestKey.seed) と一緒に渡せない")
        }
        if let seedText {
            configuration.seed = try SeedParser.parse(seedText, timeZone: configuration.wallClockTimeZone)
        }
        if let bulkText {
            configuration.bulk = try BulkSpec.parse(bulkText)
        }
        return configuration
    }

    private static func flag(_ environment: [String: String], _ name: String) throws -> Bool {
        guard let value = environment[name] else { return false }
        guard value == "1" else { throw UITestConfigError(name: name, reason: "文字 \"1\" だけ") }
        return true
    }

    private static func integer(_ text: String, in range: ClosedRange<Int>, name: String) throws -> Int {
        guard let value = Int(text), String(value) == text, range.contains(value) else {
            throw UITestConfigError(name: name, reason: "\(range.lowerBound)〜\(range.upperBound) の整数")
        }
        return value
    }

    /// http://localhost:<ポート>（末尾の / なし）。127.0.0.1 は使わない（A48）。
    private static func localURL(_ text: String, name: String) throws -> URL {
        guard let components = URLComponents(string: text), components.scheme == "http",
            components.host == "localhost", components.port != nil, components.path.isEmpty,
            components.query == nil, components.fragment == nil, let url = components.url
        else { throw UITestConfigError(name: name, reason: "http://localhost:<ポート> の形ではない") }
        return url
    }
}

// MARK: 組み立ての場所で使うもの

/// -UITest で起動したときの差し替え（時計、暦と Locale、保存の失敗、送り先）と、1pt の要素の値。
@MainActor
@Observable
final class UITestHooks {
    let configuration: UITestConfiguration
    let clockController: ClockController
    let failureInjector: FailureInjector
    /// UITEST_TELEMETRY_LOG=1 のときだけある（T22）。
    let telemetryLog: TelemetryLog?
    /// uitest.clock.applied の label（起動してから効いた T16 の操作の数）。
    private(set) var clockApplied = 0

    init(configuration: UITestConfiguration) {
        self.configuration = configuration
        clockController = ClockController(start: configuration.now, frozen: configuration.clockFrozen)
        failureInjector = FailureInjector(configuration.failures)
        telemetryLog = configuration.telemetryLog ? TelemetryLog() : nil
    }

    /// 起動の引数と環境変数を読む。-UITest がなければ nil。契約に合わなければ止める。
    static func fromProcess() -> UITestHooks? {
        let process = ProcessInfo.processInfo
        do {
            guard
                let configuration = try UITestConfiguration.parse(
                    arguments: process.arguments, environment: process.environment)
            else { return nil }
            return UITestHooks(configuration: configuration)
        } catch {
            fatalError("UITest のつなぎ口: \(error)")
        }
    }

    var clock: AppClock { clockController.clock }

    var locale: Locale? { configuration.locale }

    /// 暦：Locale を入れてから時間帯、週の始まり（UITEST_FIRST_WEEKDAY が先）の順に差し替える。
    func calendar(base: Calendar) -> Calendar {
        var calendar = base
        if let locale = configuration.locale { calendar.locale = locale }
        if let timeZone = configuration.timeZone { calendar.timeZone = timeZone }
        if let firstWeekday = configuration.firstWeekday { calendar.firstWeekday = firstWeekday }
        return calendar
    }

    /// 送り先：UITEST_TELEMETRY_URL があれば HTTP（T6）、なければ本番と同じ端末の中で数える送り先。T22 なら前に覚える包みを挟む。
    func makeSink(fallback: any TelemetrySink) -> any TelemetrySink {
        let log = telemetryLog
        var sink = fallback
        if let url = configuration.telemetryURL {
            sink = HTTPTelemetrySink(
                baseURL: url, controlURL: configuration.telemetryControlURL,
                timeoutSeconds: configuration.telemetryTimeout,
                onCountsChanged: { counts in await log?.update(counts) })
        }
        if let log {
            sink = RecordingTelemetrySink(log: log, inner: sink)
        }
        return sink
    }

    /// T1、T2、T21：保存先のファイルと telemetry. の印を消し、seed があれば入れる。保存の層が保存先を開く前に呼ぶ。
    func prepareStore(defaults: UserDefaults) {
        guard configuration.reset || configuration.seed != nil || configuration.bulk != nil else { return }
        do {
            let directory = try LibraryContainer.storeDirectory()
            if (try? directory.checkResourceIsReachable()) == true {
                try FileManager.default.removeItem(at: directory)
            }
            for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(TelemetryFlagKey.prefix) {
                defaults.removeObject(forKey: key)
            }
            let seed = configuration.seed ?? configuration.bulk?.makeSeed(now: clockController.now())
            if let seed {
                let container = try LibraryContainer.makeOnDisk()
                try SeedWriter.write(seed, into: container, defaults: defaults)
            }
        } catch {
            fatalError("UITest のつなぎ口: 保存先を作り直せない（\(error)）")
        }
    }

    /// T16：readingapp-uitest://clock?advance=|freeze=|set= を受ける（13b の根の View の onOpenURL から呼ぶ）。
    func handle(url: URL) {
        do {
            let command = try ClockCommand(url: url, timeZone: configuration.wallClockTimeZone)
            clockController.apply(command)
            clockApplied += 1
        } catch {
            fatalError("UITest のつなぎ口: \(error)")
        }
    }
}

/// -UITest のときだけ置く 1pt の要素。XCUITest が label か value を読む（VoiceOver から隠さない）。
struct UITestMarker: View {
    let identifier: String
    let label: String
    let value: String

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: label))
            .accessibilityValue(Text(verbatim: value))
            .accessibilityIdentifier(identifier)
    }
}

/// 根の View に付ける：T16 の URL を受け、uitest.clock.applied と uitest.telemetry.log（T22 のときだけ）を置く。
struct UITestOverlay: ViewModifier {
    let hooks: UITestHooks

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in hooks.handle(url: url) }
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    UITestMarker(
                        identifier: UITestKey.clockAppliedIdentifier, label: String(hooks.clockApplied), value: "")
                    if let log = hooks.telemetryLog {
                        UITestMarker(identifier: UITestKey.telemetryLogIdentifier, label: "", value: log.json)
                    }
                }
                .allowsHitTesting(false)
            }
    }
}
#endif
