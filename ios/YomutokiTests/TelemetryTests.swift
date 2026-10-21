import Foundation
import Testing

@testable import Yomutoki

/// テストのバンドル（契約の例のファイルを読む場所）。
final class TestBundleToken {}

/// JSON を形のまま比べるための値。
enum JSONValue: Decodable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    static func parse(_ data: Data) throws -> JSONValue {
        try JSONDecoder().decode(JSONValue.self, from: data)
    }
}

enum ContractFiles {
    /// project.yml が contracts/examples をフォルダのままテストのバンドルに写す。
    static func example(_ name: String) throws -> Data {
        let bundle = Bundle(for: TestBundleToken.self)
        let url = try #require(bundle.url(forResource: name, withExtension: "json", subdirectory: "examples"))
        return try Data(contentsOf: url)
    }

    /// contracts/seed.example.json。
    static func seedExample() throws -> Data {
        let bundle = Bundle(for: TestBundleToken.self)
        let url = try #require(bundle.url(forResource: "seed.example", withExtension: "json"))
        return try Data(contentsOf: url)
    }
}

/// 区間の境目（contracts/telemetry.md の区間の決め方。境目は下の値を含み、上の値を含まない）。
struct TelemetryBucketTests {
    @Test(
        "duration_bucket は分（切り捨て）で分ける",
        arguments: zip(
            [60, 299, 300, 899, 900, 1_799, 1_800, 3_599, 3_600, 7_199, 7_200, 36_000],
            [
                DurationBucket.m1to4, .m1to4, .m5to14, .m5to14, .m15to29, .m15to29, .m30to59, .m30to59, .m60to119,
                .m60to119, .m120OrMore, .m120OrMore,
            ]))
    func duration(seconds: Int, expected: DurationBucket) {
        #expect(DurationBucket(seconds: seconds) == expected)
    }

    @Test(
        "pages_bucket",
        arguments: zip(
            [0, 1, 9, 10, 29, 30, 99, 100, 9_999],
            [PagesBucket.zero, .p1to9, .p1to9, .p10to29, .p10to29, .p30to99, .p30to99, .p100OrMore, .p100OrMore]))
    func pages(pagesRead: Int, expected: PagesBucket) {
        #expect(PagesBucket(pagesRead: pagesRead) == expected)
    }

    @Test(
        "book_count_bucket は追加した後の冊数",
        arguments: zip(
            [1, 2, 5, 6, 20, 21, 500],
            [
                BookCountBucket.one, .twoToFive, .twoToFive, .sixToTwenty, .sixToTwenty, .twentyOneOrMore,
                .twentyOneOrMore,
            ]))
    func bookCount(count: Int, expected: BookCountBucket) {
        #expect(BookCountBucket(count: count) == expected)
    }

    @Test(
        "since_first_open（負のときも 0-24h）",
        arguments: zip(
            [-5.0, 0, 86_399, 86_400, 691_199, 691_200],
            [
                SinceFirstOpenBucket.within24h, .within24h, .within24h, .days1to7, .days1to7, .days8OrMore,
            ]))
    func sinceFirstOpen(seconds: Double, expected: SinceFirstOpenBucket) {
        #expect(SinceFirstOpenBucket(seconds: seconds) == expected)
    }
}

/// イベントの名前とプロパティが contracts/examples/telemetry-*.json と同じ（contracts/README.md の6）。
struct TelemetrySerializationTests {
    @Test(
        "契約の例と同じ JSON になる",
        arguments: zip(
            [
                "telemetry-app-first-opened",
                "telemetry-book-added",
                "telemetry-load-failed",
                "telemetry-reading-session-discarded",
                "telemetry-reading-session-finished",
                "telemetry-reading-session-restored",
                "telemetry-reading-session-started",
                "telemetry-reading-week-reached",
                "telemetry-save-failed-session-discard",
                "telemetry-save-failed",
            ],
            [
                TelemetryEvent.appFirstOpened,
                .bookAdded(hasTotalPages: false, bookCount: .one),
                .loadFailed,
                .readingSessionDiscarded,
                .readingSessionFinished(
                    SessionFinishedProperties(
                        duration: .m5to14, pages: .p30to99, minutesEdited: false, wasPaused: false, isFirst5min: true,
                        sinceFirstOpen: .within24h)),
                .readingSessionRestored(state: .paused),
                .readingSessionStarted(isFirstSession: true, startSource: .afterAdd),
                .readingWeekReached,
                .saveFailed(operation: .sessionDiscard),
                .saveFailed(operation: .sessionStart),
            ]))
    func matchesContractExample(file: String, event: TelemetryEvent) throws {
        let expected = try JSONValue.parse(ContractFiles.example(file))
        let actual = try JSONValue.parse(event.jsonData())
        #expect(actual == expected)
    }

    @Test("ページを入れなければ page_entered は false で pages_bucket を送らない")
    func finishedWithoutPages() throws {
        let event = TelemetryEvent.readingSessionFinished(
            SessionFinishedProperties(
                duration: .m1to4, pages: nil, minutesEdited: true, wasPaused: true, isFirst5min: false,
                sinceFirstOpen: .days8OrMore))
        #expect(event.properties["page_entered"] == .bool(false))
        #expect(event.properties["pages_bucket"] == nil)
        #expect(event.properties.count == 6)
    }

    @Test("Save Failed の operation はどれも契約の9つのどれか。load は Save Failed にしない")
    func saveOperationsMatchContract() {
        let contract: Set<String> = [
            "book_add", "session_start", "session_pause", "session_resume", "session_finish", "session_delete",
            "session_begin_finish", "session_cancel_finish", "session_discard",
        ]
        #expect(Set(SaveOperation.allCases.map(\.rawValue)) == contract)
        #expect(StoreOperation.load.saveOperation == nil)
        for operation in StoreOperation.allCases where operation != .load {
            #expect(operation.saveOperation?.rawValue == operation.rawValue)
        }
    }
}

actor CapturingSink: TelemetrySink {
    private(set) var events: [TelemetryEvent] = []

    func send(_ event: TelemetryEvent) async {
        events.append(event)
    }
}

/// いつ何を1回送るか（contracts/telemetry.md の「出すとき」）。
@MainActor
struct TelemetryRecorderTests {
    let calendar: Calendar
    let base = Date(timeIntervalSince1970: 1_792_585_800)

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        calendar.firstWeekday = 2
        self.calendar = calendar
    }

    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "YomutokiTests.\(UUID().uuidString)"))
    }

    @Test("Reading Week Reached は同じ週に1回だけ、次の週にはまた出す（AC-24）")
    func weekReachedOncePerWeek() async throws {
        let sink = CapturingSink()
        let recorder = TelemetryRecorder(
            sink: sink, defaults: try makeDefaults(), clock: .fixed(base), calendar: calendar)
        #expect(recorder.weekProgress(sessionStartedAt: base, weekTotalSeconds: 3_599) == nil)
        #expect(recorder.weekProgress(sessionStartedAt: base, weekTotalSeconds: 3_600) == .readingWeekReached)
        #expect(recorder.weekProgress(sessionStartedAt: base, weekTotalSeconds: 7_200) == nil)
        let nextWeek = base.addingTimeInterval(7 * 86_400)
        #expect(recorder.weekProgress(sessionStartedAt: nextWeek, weekTotalSeconds: 3_600) == .readingWeekReached)
        await recorder.waitForDelivery()
        #expect(await sink.events == [.readingWeekReached, .readingWeekReached])
    }

    @Test("App First Opened は印がないときだけ出す")
    func firstOpenedOnce() async throws {
        let sink = CapturingSink()
        let defaults = try makeDefaults()
        let recorder = TelemetryRecorder(sink: sink, defaults: defaults, clock: .fixed(base), calendar: calendar)
        #expect(recorder.appLaunched() == .appFirstOpened)
        #expect(recorder.appLaunched() == nil)
        #expect(defaults.object(forKey: TelemetryFlagKey.firstOpenedAt) as? Date == base)
        await recorder.waitForDelivery()
        #expect(await sink.events == [.appFirstOpened])
    }

    @Test("is_first_session と is_first_5min は最初の1回だけ true、since_first_open は初めて開いた時刻から")
    func firstFlags() throws {
        let defaults = try makeDefaults()
        let recorder = TelemetryRecorder(
            sink: CapturingSink(), defaults: defaults, clock: .fixed(base), calendar: calendar)
        recorder.appLaunched()
        #expect(recorder.sessionStarted(source: .home) == .readingSessionStarted(isFirstSession: true, startSource: .home))
        #expect(
            recorder.sessionStarted(source: .bookDetail)
                == .readingSessionStarted(isFirstSession: false, startSource: .bookDetail))
        let short = recorder.sessionFinished(
            durationSeconds: 299, pagesRead: nil, minutesEdited: false, wasPaused: false,
            savedAt: base.addingTimeInterval(600))
        let first5 = recorder.sessionFinished(
            durationSeconds: 300, pagesRead: 30, minutesEdited: true, wasPaused: true,
            savedAt: base.addingTimeInterval(86_400))
        let second5 = recorder.sessionFinished(
            durationSeconds: 900, pagesRead: 0, minutesEdited: false, wasPaused: false,
            savedAt: base.addingTimeInterval(691_200))
        #expect(
            short
                == .readingSessionFinished(
                    SessionFinishedProperties(
                        duration: .m1to4, pages: nil, minutesEdited: false, wasPaused: false, isFirst5min: false,
                        sinceFirstOpen: .within24h)))
        #expect(
            first5
                == .readingSessionFinished(
                    SessionFinishedProperties(
                        duration: .m5to14, pages: .p30to99, minutesEdited: true, wasPaused: true, isFirst5min: true,
                        sinceFirstOpen: .days1to7)))
        #expect(
            second5
                == .readingSessionFinished(
                    SessionFinishedProperties(
                        duration: .m15to29, pages: .zero, minutesEdited: false, wasPaused: false, isFirst5min: false,
                        sinceFirstOpen: .days8OrMore)))
    }

    @Test("Reading Session Restored は起動ごとに1件")
    func restoredOncePerLaunch() throws {
        let recorder = TelemetryRecorder(
            sink: CapturingSink(), defaults: try makeDefaults(), clock: .fixed(base), calendar: calendar)
        #expect(recorder.sessionRestored(state: .finishing) == .readingSessionRestored(state: .finishing))
        #expect(recorder.sessionRestored(state: .finishing) == nil)
    }

    @Test("本番の送り先は端末の中でイベント名ごとに数えるだけ")
    func localCountingSink() async {
        let suite = "YomutokiTests.\(UUID().uuidString)"
        let sink = LocalCountingTelemetrySink(suiteName: suite)
        await sink.send(.appFirstOpened)
        await sink.send(.saveFailed(operation: .bookAdd))
        await sink.send(.saveFailed(operation: .sessionStart))
        #expect(await sink.counts() == ["App First Opened": 1, "Save Failed": 2])
    }
}
