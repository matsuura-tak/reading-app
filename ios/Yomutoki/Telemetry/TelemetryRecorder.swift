import Foundation

/// 計測の印のキー（contracts/data-model.md の「計測の印」。UserDefaults に置き、SwiftData に入れない）。
nonisolated enum TelemetryFlagKey {
    /// テストのつなぎ口の T1 は、この文字で始まるキーを全部消す。
    static let prefix = "telemetry."
    static let firstOpenedAt = "telemetry.firstOpenedAt"
    static let firstSessionStarted = "telemetry.firstSessionStarted"
    static let first5minDone = "telemetry.first5minDone"
    static let weekReachedWeekStart = "telemetry.weekReachedWeekStart"
    static let localCounts = "telemetry.localCounts"
}

/// いつ何を1回送るかを決める（contracts/telemetry.md の「出すとき」と区間の決め方）。
/// 保存の層が、保存が通ったとき（失敗は Save Failed）に呼ぶ。送る順は呼んだ順（前の送信に渡し終えてから次を渡す）。
@MainActor
final class TelemetryRecorder {
    private let sink: any TelemetrySink
    private let defaults: UserDefaults
    private let clock: AppClock
    private let calendar: Calendar
    private var delivery: Task<Void, Never>?
    private var restoredSentThisLaunch = false

    init(sink: any TelemetrySink, defaults: UserDefaults, clock: AppClock, calendar: Calendar) {
        self.sink = sink
        self.defaults = defaults
        self.clock = clock
        self.calendar = calendar
    }

    /// 前に渡したイベントの後に、送り先へ渡す。画面は待たない。
    @discardableResult
    func emit(_ event: TelemetryEvent) -> TelemetryEvent {
        let previous = delivery
        let sink = self.sink
        delivery = Task {
            await previous?.value
            await sink.send(event)
        }
        return event
    }

    /// ここまでに出したイベントを、送り先に渡し終えるまで待つ（単体テスト用）。
    func waitForDelivery() async {
        await delivery?.value
    }

    /// App First Opened：計測の印 telemetry.firstOpenedAt がなければ出して、今の時刻を入れる。保存先の読み込みより前に呼ぶ。
    @discardableResult
    func appLaunched() -> TelemetryEvent? {
        guard defaults.object(forKey: TelemetryFlagKey.firstOpenedAt) == nil else { return nil }
        defaults.set(clock.now(), forKey: TelemetryFlagKey.firstOpenedAt)
        return emit(.appFirstOpened)
    }

    /// Book Added：本の追加の保存が通ったとき。冊数は追加した後の数。
    @discardableResult
    func bookAdded(bookCount: Int, hasTotalPages: Bool) -> TelemetryEvent {
        emit(.bookAdded(hasTotalPages: hasTotalPages, bookCount: BookCountBucket(count: bookCount)))
    }

    /// Reading Session Started：読み始めの保存が通ったときだけ（失敗した回は出さない）。
    @discardableResult
    func sessionStarted(source: StartSource) -> TelemetryEvent {
        let isFirstSession = !defaults.bool(forKey: TelemetryFlagKey.firstSessionStarted)
        if isFirstSession {
            defaults.set(true, forKey: TelemetryFlagKey.firstSessionStarted)
        }
        return emit(.readingSessionStarted(isFirstSession: isFirstSession, startSource: source))
    }

    /// Reading Session Finished：記録の保存が通ったとき。
    @discardableResult
    func sessionFinished(
        durationSeconds: Int, pagesRead: Int?, minutesEdited: Bool, wasPaused: Bool, savedAt: Date
    ) -> TelemetryEvent {
        let isFirst5min = durationSeconds >= 300 && !defaults.bool(forKey: TelemetryFlagKey.first5minDone)
        if isFirst5min {
            defaults.set(true, forKey: TelemetryFlagKey.first5minDone)
        }
        let firstOpenedAt = defaults.object(forKey: TelemetryFlagKey.firstOpenedAt) as? Date
        let sinceFirstOpen = firstOpenedAt.map { savedAt.timeIntervalSince($0) } ?? 0
        let properties = SessionFinishedProperties(
            duration: DurationBucket(seconds: durationSeconds),
            pages: pagesRead.map { PagesBucket(pagesRead: $0) },
            minutesEdited: minutesEdited,
            wasPaused: wasPaused,
            isFirst5min: isFirst5min,
            sinceFirstOpen: SinceFirstOpenBucket(seconds: sinceFirstOpen))
        return emit(.readingSessionFinished(properties))
    }

    /// Reading Week Reached：記録の保存が通った後、その記録の startedAt の週の合計が3,600秒以上で、
    /// telemetry.weekReachedWeekStart がその週の始まりより前（かない）とき。出したら印をその週の始まりにする（同じ週に2回出さない）。
    @discardableResult
    func weekProgress(sessionStartedAt: Date, weekTotalSeconds: Int) -> TelemetryEvent? {
        guard weekTotalSeconds >= ReadingMath.weekThresholdSeconds,
            let week = ReadingMath.week(containing: sessionStartedAt, calendar: calendar)
        else { return nil }
        if let reached = defaults.object(forKey: TelemetryFlagKey.weekReachedWeekStart) as? Date, reached >= week.start {
            return nil
        }
        defaults.set(week.start, forKey: TelemetryFlagKey.weekReachedWeekStart)
        return emit(.readingWeekReached)
    }

    /// Reading Session Restored：読み込みが通り、進行中の読書があったとき。起動ごとに1件。
    @discardableResult
    func sessionRestored(state: ReadingState) -> TelemetryEvent? {
        guard !restoredSentThisLaunch else { return nil }
        restoredSentThisLaunch = true
        return emit(.readingSessionRestored(state: RestoredState(state)))
    }

    /// Reading Session Discarded：60秒未満で終える保存が通ったとき（再試行で通ったときを含む）。
    @discardableResult
    func sessionDiscarded() -> TelemetryEvent {
        emit(.readingSessionDiscarded)
    }

    /// Save Failed：保存が失敗するたびに1件（再試行の失敗も1件ずつ）。
    @discardableResult
    func saveFailed(_ operation: SaveOperation) -> TelemetryEvent {
        emit(.saveFailed(operation: operation))
    }

    /// Load Failed：読み込みが失敗するたびに1件。
    @discardableResult
    func loadFailed() -> TelemetryEvent {
        emit(.loadFailed)
    }
}
