import SwiftUI

@main
struct YomutokiApp: App {
    @State private var appEnvironment: AppEnvironment

    init() {
        _appEnvironment = State(initialValue: AppEnvironment.make())
    }

    var body: some Scene {
        WindowGroup {
            root
                .environment(appEnvironment.store)
                .environment(\.appClock, appEnvironment.clock)
                .environment(\.calendar, appEnvironment.calendar)
                .environment(\.timeZone, appEnvironment.calendar.timeZone)
                .environment(\.locale, appEnvironment.locale)
                .environment(\.telemetrySink, appEnvironment.sink)
                .task { appEnvironment.start() }
        }
    }

    @ViewBuilder
    private var root: some View {
        #if DEBUG
        if let hooks = appEnvironment.hooks {
            // -UITest のときだけ、T16 の URL の受け口と uitest.clock.applied、uitest.telemetry.log を根に付ける。
            // 状態（session.state.*）は RootView と FinishSessionView の根の識別子だけで出す（G2 の CI の裁定 1）。
            RootView().modifier(UITestOverlay(hooks: hooks))
        } else {
            RootView()
        }
        #else
        RootView()
        #endif
    }
}

/// 組み立ての場所（設計メモ 3）。時計、暦、Locale、送り先、保存の層をここで決めて画面の環境に入れる。
/// Debug で -UITest のときだけ、テストのつなぎ口（Debug/UITestHooks.swift）が先に差し替える（contracts/test-hooks.md の起動の順番）。
@MainActor
final class AppEnvironment {
    let clock: AppClock
    let calendar: Calendar
    let locale: Locale
    let sink: any TelemetrySink
    let telemetry: TelemetryRecorder
    let store: LibraryStore
    #if DEBUG
    private(set) var hooks: UITestHooks?
    #endif
    private var started = false

    init(clock: AppClock, calendar: Calendar, locale: Locale, sink: any TelemetrySink, defaults: UserDefaults) {
        self.clock = clock
        self.calendar = calendar
        self.locale = locale
        self.sink = sink
        let telemetry = TelemetryRecorder(sink: sink, defaults: defaults, clock: clock, calendar: calendar)
        self.telemetry = telemetry
        store = LibraryStore(
            clock: clock, calendar: calendar, telemetry: telemetry,
            openContainer: { try LibraryContainer.makeOnDisk() })
    }

    static func make() -> AppEnvironment {
        let defaults = UserDefaults.standard
        #if DEBUG
        if let hooks = UITestHooks.fromProcess() {
            // 起動の順番 2〜4：時計と暦と Locale と送り先を作り、保存先を消して seed を入れる。
            hooks.prepareStore(defaults: defaults)
            let environment = AppEnvironment(
                clock: hooks.clock,
                calendar: hooks.calendar(base: Calendar.autoupdatingCurrent),
                locale: hooks.locale ?? Locale.autoupdatingCurrent,
                sink: hooks.makeSink(fallback: LocalCountingTelemetrySink()),
                defaults: defaults)
            let injector = hooks.failureInjector
            environment.store.beforeSave = { operation in try injector.check(operation) }
            environment.hooks = hooks
            return environment
        }
        #endif
        return AppEnvironment(
            clock: .system, calendar: Calendar.autoupdatingCurrent, locale: Locale.autoupdatingCurrent,
            sink: LocalCountingTelemetrySink(), defaults: defaults)
    }

    /// 起動の順番 5、6：App First Opened（読み込みより前。失敗しても出す）、保存先の読み込み。1回だけ。
    func start() {
        guard !started else { return }
        started = true
        telemetry.appLaunched()
        store.load()
    }
}
