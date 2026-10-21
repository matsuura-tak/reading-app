import Foundation
import SwiftData
import Testing

@testable import Yomutoki

// つなぎ口（Debug/UITestHooks.swift）の単体テスト。つなぎ口の名前の文字はこのファイルに書かず、UITestKey から引く。

/// 起動の引数と環境変数の読み方（contracts/test-hooks.md の共通の決まりと表）。
struct UITestConfigurationTests {
    let launch = [UITestKey.launchArgument]

    @Test("-UITest がなければ何も読まない")
    func ignoredWithoutLaunchArgument() throws {
        let configuration = try UITestConfiguration.parse(
            arguments: [], environment: [UITestKey.reset: "1", UITestKey.prefix + "UNKNOWN": "x"])
        #expect(configuration == nil)
    }

    @Test("知らない名前は止める")
    func unknownNameStops() {
        #expect(throws: UITestConfigError.self) {
            _ = try UITestConfiguration.parse(arguments: launch, environment: [UITestKey.prefix + "UNKNOWN": "1"])
        }
    }

    @Test(
        "形の合わない値は止める",
        arguments: [
            [UITestKey.reset: "true"],
            [UITestKey.clockFrozen: "0"],
            [UITestKey.timeZone: "Mars/Olympus"],
            [UITestKey.locale: "fr_FR"],
            [UITestKey.firstWeekday: "8"],
            [UITestKey.firstWeekday: "02"],
            [UITestKey.now: "2026-10-21 21:30:00"],
            [UITestKey.now: "2026-02-30T21:30:00"],
            [UITestKey.fail: "session_finishing:1"],
            [UITestKey.fail: "book_add:0"],
            [UITestKey.fail: "book_add:100"],
            [UITestKey.fail: "book_add:1,book_add:2"],
            [UITestKey.telemetryURL: "http://127.0.0.1:8765"],
            [UITestKey.telemetryURL: "http://localhost:8765/"],
            [UITestKey.telemetryURL: "http://localhost"],
            [UITestKey.telemetryTimeout: "61"],
            [UITestKey.seedBulk: "books=601,sessions=0"],
            [UITestKey.seedBulk: "books=1"],
            [UITestKey.seed: "{\"version\":1,\"books\":[]}", UITestKey.seedBulk: "books=1,sessions=0"],
        ])
    func invalidValuesStop(environment: [String: String]) {
        #expect(throws: UITestConfigError.self) {
            _ = try UITestConfiguration.parse(arguments: launch, environment: environment)
        }
    }

    @Test("契約の例の値を読める")
    func readsContractExamples() throws {
        let configuration = try #require(
            try UITestConfiguration.parse(
                arguments: launch,
                environment: [
                    UITestKey.reset: "1",
                    UITestKey.now: "2026-10-21T21:30:00",
                    UITestKey.clockFrozen: "1",
                    UITestKey.timeZone: "Asia/Tokyo",
                    UITestKey.locale: "en_US",
                    UITestKey.firstWeekday: "2",
                    UITestKey.fail: "load:1,book_add:2,session_start:*",
                    UITestKey.telemetryURL: "http://localhost:8765",
                    UITestKey.telemetryControlURL: "http://localhost:8766",
                    UITestKey.telemetryTimeout: "3",
                    UITestKey.telemetryLog: "1",
                    UITestKey.seedBulk: "books=500,sessions=10000",
                ]))
        #expect(configuration.reset)
        #expect(configuration.clockFrozen)
        #expect(configuration.now == Date(timeIntervalSince1970: 1_792_585_800))
        #expect(configuration.locale?.identifier == "en_US")
        #expect(configuration.firstWeekday == 2)
        #expect(configuration.failures == [.load: .times(1), .bookAdd: .times(2), .sessionStart: .always])
        #expect(configuration.telemetryURL?.absoluteString == "http://localhost:8765")
        #expect(configuration.telemetryTimeout == 3)
        #expect(configuration.telemetryLog)
        #expect(configuration.bulk == BulkSpec(books: 500, sessions: 10_000))
    }
}

/// 時計の差し替え（T3、T16）。
struct ClockControllerTests {
    let start = Date(timeIntervalSince1970: 1_792_585_800)

    @Test("止めた時計は advance と set でだけ動く。freeze=0 で実時間に戻る")
    func frozenClock() {
        let controller = ClockController(start: start, frozen: true)
        #expect(controller.now() == start)
        controller.apply(.advance(600))
        #expect(controller.now() == start.addingTimeInterval(600))
        controller.apply(.advance(-86_400))
        #expect(controller.now() == start.addingTimeInterval(600 - 86_400))
        controller.apply(.set(start))
        #expect(controller.now() == start)
        controller.apply(.freeze(false))
        #expect(controller.now() >= start)
    }

    @Test("readingapp-uitest://clock の URL を読む。1つの URL に1つの操作")
    func parsesClockURLs() throws {
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let scheme = UITestKey.urlScheme
        let advance = try #require(URL(string: "\(scheme)://clock?advance=600"))
        #expect(try ClockCommand(url: advance, timeZone: tokyo) == .advance(600))
        let freeze = try #require(URL(string: "\(scheme)://clock?freeze=1"))
        #expect(try ClockCommand(url: freeze, timeZone: tokyo) == .freeze(true))
        let set = try #require(URL(string: "\(scheme)://clock?set=2026-10-21T21:30:00"))
        #expect(try ClockCommand(url: set, timeZone: tokyo) == .set(Date(timeIntervalSince1970: 1_792_585_800)))
        let two = try #require(URL(string: "\(scheme)://clock?advance=1&freeze=1"))
        #expect(throws: UITestConfigError.self) { _ = try ClockCommand(url: two, timeZone: tokyo) }
        let tooFar = try #require(URL(string: "\(scheme)://clock?advance=86401"))
        #expect(throws: UITestConfigError.self) { _ = try ClockCommand(url: tooFar, timeZone: tokyo) }
    }
}

/// 保存の失敗の差し替え（T5）。
@MainActor
struct FailureInjectorTests {
    @Test("回数だけ失敗し、次から通る。* は毎回失敗。ほかの操作は通る")
    func budgets() throws {
        let injector = FailureInjector([.sessionFinish: .times(2), .load: .always])
        #expect(throws: InjectedSaveFailure(operation: .sessionFinish)) { try injector.check(.sessionFinish) }
        #expect(throws: InjectedSaveFailure(operation: .sessionFinish)) { try injector.check(.sessionFinish) }
        try injector.check(.sessionFinish)
        for _ in 0..<5 {
            #expect(throws: InjectedSaveFailure(operation: .load)) { try injector.check(.load) }
        }
        try injector.check(.bookAdd)
    }
}

/// T2 の seed（contracts/seed.schema.json、data-model.md の最後の節）。
@MainActor
struct SeedTests {
    let tokyo: TimeZone

    init() throws {
        tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
    }

    @Test("contracts/seed.example.json を読み、入れて、保存の層で読める（AC-14 の値）")
    func seedExampleRoundTrip() async throws {
        let text = String(decoding: try ContractFiles.seedExample(), as: UTF8.self)
        let seed = try SeedParser.parse(text, timeZone: tokyo)
        #expect(seed.books.count == 2)
        #expect(seed.sessions.count == 5)
        #expect(seed.active == nil)
        #expect(seed.flags?.firstSessionStarted == true)

        let container = try LibraryContainer.makeInMemory()
        let defaults = try #require(UserDefaults(suiteName: "YomutokiTests.\(UUID().uuidString)"))
        try SeedWriter.write(seed, into: container, defaults: defaults)
        #expect(defaults.object(forKey: TelemetryFlagKey.firstOpenedAt) is Date)
        #expect(defaults.object(forKey: TelemetryFlagKey.weekReachedWeekStart) == nil)

        let h = try StoreHarness(container: container)
        h.store.load()
        #expect(h.store.loadState == .loaded)
        let botchanID = try #require(UUID(uuidString: "00000000-0000-4000-8000-000000000001"))
        let kokoroID = try #require(UUID(uuidString: "00000000-0000-4000-8000-000000000002"))
        let botchan = try #require(h.store.book(id: botchanID))
        #expect(botchan.totalMinutes == 60)
        #expect(botchan.sessionCount == 3)
        #expect(botchan.lastPage == 72)
        #expect(botchan.progressPercent == 24)
        let kokoro = try #require(h.store.book(id: kokoroID))
        #expect(kokoro.totalMinutes == 40)
        #expect(kokoro.progressPercent == nil)
        // 最後に記録を保存したのは「坊っちゃん」（2026-10-20）。
        #expect(h.store.previousBookID == botchanID)
        #expect(h.store.books.map(\.id) == [botchanID, kokoroID])
    }

    @Test(
        "contracts/examples の seed（AC-15 の週の境目、AC-33 の一時停止中）を読める",
        arguments: ["seed-ac15", "seed-ac33"])
    func seedExamples(file: String) throws {
        let text = String(decoding: try ContractFiles.example(file), as: UTF8.self)
        let seed = try SeedParser.parse(text, timeZone: tokyo)
        #expect(!seed.books.isEmpty)
        if file == "seed-ac33" {
            #expect(seed.active?.state == .paused)
            #expect(seed.active?.pausedAt != nil)
        }
    }

    @Test(
        "契約に合わない seed は止める",
        arguments: [
            "{\"version\":2,\"books\":[]}",
            "{\"books\":[]}",
            "{\"version\":1,\"books\":[],\"extra\":1}",
            "{\"version\":1,\"books\":[{\"id\":\"00000000-0000-4000-8000-000000000001\",\"title\":\"a\",\"totalPages\":10,\"lastPage\":11,\"addedAt\":\"2026-10-01T20:00:00\"}]}",
            "{\"version\":1,\"books\":[{\"id\":\"00000000-0000-4000-8000-00000000000A\",\"title\":\"a\",\"totalPages\":null,\"lastPage\":0,\"addedAt\":\"2026-10-01T20:00:00\"}]}",
            "{\"version\":1,\"books\":[{\"id\":\"00000000-0000-4000-8000-000000000001\",\"title\":\"a\",\"totalPages\":null,\"lastPage\":0}]}",
            "{\"version\":1,\"books\":[],\"sessions\":[{\"id\":\"00000000-0000-4000-8000-000000000101\",\"bookId\":\"00000000-0000-4000-8000-000000000001\",\"startedAt\":\"2026-10-05T21:00:00\",\"durationSeconds\":600,\"endPage\":null,\"pagesRead\":null,\"savedAt\":\"2026-10-05T21:10:30\"}]}",
            "{\"version\":1,\"books\":[{\"id\":\"00000000-0000-4000-8000-000000000001\",\"title\":\"a\",\"totalPages\":null,\"lastPage\":0,\"addedAt\":\"2026-10-01T20:00:00\"}],\"active\":{\"bookId\":\"00000000-0000-4000-8000-000000000001\",\"state\":\"paused\",\"startedAt\":\"2026-10-21T21:00:00\",\"pausedTotalSeconds\":0,\"pausedAt\":null,\"finishedAt\":null,\"wasPaused\":true}}",
        ])
    func invalidSeedStops(json: String) {
        #expect(throws: UITestConfigError.self) { _ = try SeedParser.parse(json, timeZone: tokyo) }
    }

    @Test("101字の題名の seed は止める（書記素で数える）")
    func seedTitleLimit() {
        let title = String(repeating: "👨‍👩‍👧", count: 101)
        let json =
            "{\"version\":1,\"books\":[{\"id\":\"00000000-0000-4000-8000-000000000001\",\"title\":\"\(title)\",\"totalPages\":null,\"lastPage\":0,\"addedAt\":\"2026-10-01T20:00:00\"}]}"
        #expect(throws: UITestConfigError.self) { _ = try SeedParser.parse(json, timeZone: tokyo) }
    }

    @Test("T21 の大きなデータは決まった形で作る")
    func bulkSeed() {
        let now = Date(timeIntervalSince1970: 1_792_585_800)
        let seed = BulkSpec(books: 3, sessions: 7).makeSeed(now: now)
        #expect(seed.books.map(\.title) == ["本 001", "本 002", "本 003"])
        #expect(seed.books.allSatisfy { $0.totalPages == 300 && $0.lastPage == 0 })
        #expect(seed.sessions.count == 7)
        #expect(seed.sessions.allSatisfy { $0.durationSeconds == 1_800 && $0.endPage == nil })
        #expect(seed.sessions.allSatisfy { $0.startedAt < now && $0.startedAt >= now.addingTimeInterval(-365 * 86_400) })
        #expect(seed.sessions[3].bookID == seed.books[0].id)
    }
}

/// T22 の uitest.telemetry.log の中身。
@MainActor
struct TelemetryLogTests {
    @Test("events は渡した順に telemetry-events.schema.json の形で並び、sent と failed を持つ")
    func logJSON() async throws {
        let log = TelemetryLog()
        let inner = CapturingSink()
        let sink = RecordingTelemetrySink(log: log, inner: inner)
        await sink.send(.appFirstOpened)
        await sink.send(.saveFailed(operation: .sessionStart))
        log.update(TelemetryDeliveryCounts(sent: 1, failed: 1))
        let parsed = try JSONValue.parse(Data(log.json.utf8))
        let expected = try JSONValue.parse(
            Data(
                "{\"events\":[{\"name\":\"App First Opened\",\"properties\":{}},{\"name\":\"Save Failed\",\"properties\":{\"operation\":\"session_start\"}}],\"sent\":1,\"failed\":1}"
                    .utf8))
        #expect(parsed == expected)
        #expect(await inner.events.count == 2)
    }
}
