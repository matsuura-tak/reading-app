import XCTest

/// 起動の組み立て（contracts/test-hooks.md の共通の決まりと T1〜T6、T13、T15、T19、T22）。
/// テストごとに起動し直して状態を作り、テストの順番に頼らない。
struct LaunchConfig {
    /// T1 UITEST_RESET=1（UITEST_SEED を使わないテストだけ。SEED は RESET を兼ねる）
    var reset = false
    /// T2 UITEST_SEED
    var seed: Seed?
    /// T3 UITEST_NOW（nil なら端末の時計）
    var now: WallClock? = Fixture.now
    /// T3 UITEST_CLOCK_FROZEN=1。止めておき、T16 で決まった秒だけ進める（実時間で待たない）。
    var clockFrozen = true
    /// T4 UITEST_FIRST_WEEKDAY（1 が日曜、2 が月曜）
    var firstWeekday: Int?
    /// T5 UITEST_FAIL（例 "session_finish:1"）
    var fail: String?
    /// T6 UITEST_TELEMETRY_URL
    var telemetryURL: String?
    /// T13 UITEST_TELEMETRY_CONTROL_URL
    var telemetryControlURL: String?
    /// T19 UITEST_TELEMETRY_TIMEOUT（秒）
    var telemetryTimeout: Int?
    /// T22 UITEST_TELEMETRY_LOG=1
    var telemetryLog = false

    /// 何もない状態（T1）。
    static var fresh: LaunchConfig {
        var c = LaunchConfig()
        c.reset = true
        return c
    }

    /// 決まったデータを入れた状態（T2。RESET を兼ねる）。
    static func seeded(_ seed: Seed) -> LaunchConfig {
        var c = LaunchConfig()
        c.seed = seed
        return c
    }
}

/// 起動したアプリと、T16 の時計の操作の数。
@MainActor
final class AppSession {
    let app: XCUIApplication
    /// 起動してから送った時計の操作の数（uitest.clock.applied の label と比べる）。
    private(set) var clockApplied = 0

    private init(app: XCUIApplication) {
        self.app = app
    }

    static func launch(_ config: LaunchConfig) -> AppSession {
        let app = XCUIApplication()
        // -UITest がなければアプリはつなぎ口を読まない（共通の決まり）。言語は T4 の引数で渡す。
        app.launchArguments = ["-UITest", "-AppleLanguages", L10n.appleLanguages, "-AppleLocale", L10n.localeID]
        var env: [String: String] = [
            "UITEST_TIME_ZONE": WallClock.timeZoneID,
            "UITEST_LOCALE": L10n.localeID,
        ]
        if config.reset { env["UITEST_RESET"] = "1" }
        if let seed = config.seed { env["UITEST_SEED"] = seed.jsonString() }
        if let now = config.now {
            env["UITEST_NOW"] = now.text
            if config.clockFrozen { env["UITEST_CLOCK_FROZEN"] = "1" }
        }
        if let weekday = config.firstWeekday { env["UITEST_FIRST_WEEKDAY"] = String(weekday) }
        if let fail = config.fail { env["UITEST_FAIL"] = fail }
        if let url = config.telemetryURL { env["UITEST_TELEMETRY_URL"] = url }
        if let url = config.telemetryControlURL { env["UITEST_TELEMETRY_CONTROL_URL"] = url }
        if let timeout = config.telemetryTimeout { env["UITEST_TELEMETRY_TIMEOUT"] = String(timeout) }
        if config.telemetryLog { env["UITEST_TELEMETRY_LOG"] = "1" }
        app.launchEnvironment = env
        app.launch()
        return AppSession(app: app)
    }

    /// 強制終了して起動し直す。UITEST_SEED と UITEST_RESET は1回だけ入れるものなので消す（共通の決まり）。
    /// UITEST_FAIL の数は起動ごとなので、keepFail が false なら消す（T5）。次の起動の「今」は now（T3 の備考）。
    func relaunch(now: WallClock?, keepFail: Bool = false) {
        app.terminate()
        app.launchEnvironment["UITEST_SEED"] = nil
        app.launchEnvironment["UITEST_RESET"] = nil
        if !keepFail { app.launchEnvironment["UITEST_FAIL"] = nil }
        if let now {
            app.launchEnvironment["UITEST_NOW"] = now.text
        } else {
            app.launchEnvironment["UITEST_NOW"] = nil
            app.launchEnvironment["UITEST_CLOCK_FROZEN"] = nil
        }
        clockApplied = 0
        app.launch()
    }

    // MARK: 時計（T16 の URL scheme。効いたことを uitest.clock.applied で待つ）

    func advance(seconds: Int, file: StaticString = #filePath, line: UInt = #line) {
        sendClock("advance=\(seconds)", file: file, line: line)
    }

    func setClock(_ wall: WallClock, file: StaticString = #filePath, line: UInt = #line) {
        sendClock("set=\(wall.text)", file: file, line: line)
    }

    func freezeClock(_ frozen: Bool, file: StaticString = #filePath, line: UInt = #line) {
        sendClock("freeze=\(frozen ? 1 : 0)", file: file, line: line)
    }

    private func sendClock(_ query: String, file: StaticString, line: UInt) {
        guard let url = URL(string: "readingapp-uitest://clock?\(query)") else {
            XCTFail("時計の URL を作れない: \(query)", file: file, line: line)
            return
        }
        // CI 807f934（Xcode 26.6、iOS 26.5）で XCUIApplication.open(_:) はアプリを起動し直した（ログ：「Open … with URL」の下に
        // 「Launch」「Setting up automation session」。2回目の操作で uitest.clock.applied が「1」に戻った）。起動し直すと
        // UITEST_SEED と UITEST_RESET が入り直り、テストの中で作った状態（S5、保存の失敗の区画、読み始めた読書）が消える。
        // そこで、システムから URL を開き、動いているアプリの onOpenURL に渡す（XCUIDevice.system.open、iOS 16.4 以上）。
        XCUIDevice.shared.system.open(url)
        clockApplied += 1
        let marker = app.descendants(matching: .any)["uitest.clock.applied"]
        if !Wait.until(NSPredicate(format: "label == %@", String(clockApplied)), marker, timeout: Wait.optional) {
            confirmOpenIfAsked()
        }
        // 起動し直したら label は数え直しの値（1）になるので、2回目からの操作では起動し直しをここで見分けられる。
        Wait.label(marker, equals: String(clockApplied), "T16 の時計の操作（\(query)）が効いた", file: file, line: line)
    }

    /// システムが URL を開く前に確かめるダイアログ（「"Yomutoki"で開きますか？」）を出したときだけ「開く」を押す。
    /// システムの部品なので文字で探す（design 6 の (b)）。出るかは CI で未確認（contracts/test-hooks.md の T16 の備考）。
    private func confirmOpenIfAsked() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let open = springboard.buttons.matching(NSPredicate(format: "label IN %@", L10n.systemOpenLabels)).firstMatch
        if open.waitForExistence(timeout: Wait.optional) {
            print("[AT-DIAG] T16：システムの確かめのダイアログが出たので「\(open.label)」を押した")
            open.tap()
        }
    }

    // MARK: 証拠

    /// スクリーンショットを残す（名前は AC3_オフライン の形。lifetime は keepAlways）。
    func shot(_ name: String, _ test: XCTestCase) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        test.add(attachment)
        // 落ちたときに AcceptanceTestCase が「直前のスクリーンショット」として出す（ci-runs/807f934-acceptance-en.md の 5）。
        if let base = test as? AcceptanceTestCase {
            base.lastShotName = name
            base.shotCount += 1
        }
    }
}
