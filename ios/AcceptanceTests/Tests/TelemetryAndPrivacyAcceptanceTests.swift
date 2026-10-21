import XCTest

/// 計測の送り先の失敗、権限、計測の中身（AC-20、AC-21、AC-23、AC-24）。
/// 受け口は TelemetryReceiver（localhost の HTTP。T6、T7、T13、T19）。届かないと CI で分かったら T22 に替える（TelemetryProbe）。
final class TelemetryAndPrivacyAcceptanceTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: AC-20

    /// AC-20（届かない先 http://localhost:9）
    @MainActor
    func test_AC20_allOperationsWorkWhenTelemetryIsUnreachable() throws {
        let probe = try TelemetryProbe(eventsMode: .ok, separateControl: true, test: self)
        try assertAC20(probe: probe, eventsURL: "http://localhost:9", name: "届かない先")
    }

    /// AC-20（500 を返す先）
    @MainActor
    func test_AC20_allOperationsWorkWhenTelemetryReturns500() throws {
        let probe = try TelemetryProbe(eventsMode: .status500, separateControl: true, test: self)
        try assertAC20(probe: probe, eventsURL: nil, name: "500")
    }

    /// AC-20（30秒応答しない先。受け口は30秒たってから閉じる。アプリの待ちは UITEST_TELEMETRY_TIMEOUT=3 に縮める。T19）
    @MainActor
    func test_AC20_allOperationsWorkWhenTelemetryHangs() throws {
        let probe = try TelemetryProbe(eventsMode: .hang, separateControl: true, test: self)
        try assertAC20(probe: probe, eventsURL: nil, name: "応答しない先")
    }

    /// 本を追加し、読み始め、終えて保存し、本の詳細を開く。各手順の後にアラートとシートが0個、error. で始まる要素が0個。
    /// 最後に記録が1件増えたこと（「記録 1件」）を見る。送り終わり（failed が4件に届く）を待ってからもう一度見る。
    @MainActor
    private func assertAC20(probe: TelemetryProbe, eventsURL: String?, name: String) throws {
        var config = LaunchConfig.fresh
        probe.apply(to: &config, eventsURL: eventsURL)
        config.telemetryTimeout = 3
        let s = AppSession.launch(config)

        s.addBook(title: Fixture.botchan)
        s.expectNoAlertSheetOrError("\(name)：本を追加した後")

        s.tap("book.startReading")
        s.expectState(.reading)
        s.expectNoAlertSheetOrError("\(name)：読み始めた後")

        s.advance(seconds: 300)
        s.finishAndSave(title: Fixture.botchan)
        s.expectState(.idle)
        s.expectNoAlertSheetOrError("\(name)：終えて保存した後")

        s.goBack()
        s.openBook(titled: Fixture.botchan)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "\(name)：記録が1件増えた")
        s.expectNoAlertSheetOrError("\(name)：本の詳細を開いた後")

        // App First Opened、Book Added、Reading Session Started、Reading Session Finished の4件の送信が終わるのを待つ
        let snapshot = probe.waitDrained(s, total: 4)
        XCTAssertEqual(snapshot.failed, snapshot.sent + snapshot.failed, "前提：\(name) への送信はすべて失敗した（sent \(snapshot.sent)、failed \(snapshot.failed)）")
        s.expectNoAlertSheetOrError("\(name)：送信が失敗し終わった後")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "\(name)：送信が失敗し終わった後も記録は1件")
        s.shot("AC20_\(name)", self)
    }

    // MARK: AC-21

    /// AC-21：初めて開いてから、本を追加し、読書を1回終えて保存するまでに、権限を求めるシステムのダイアログは0回。
    /// 権限は前もって未回答に戻しておく（T12。resetAuthorizationStatus は起動の前に呼ぶ）。
    @MainActor
    func test_AC21_noPermissionPromptsDuringFirstSession() throws {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let beforeLaunch = XCUIApplication()
        for resource in [XCUIProtectedResource.camera, .photos, .location] {
            beforeLaunch.resetAuthorizationStatus(for: resource)
        }
        let s = AppSession.launch(.fresh)
        func expectNoPrompt(_ step: String) {
            XCTAssertEqual(springboard.alerts.count, 0, "\(step)：システムのダイアログ")
            XCTAssertEqual(s.app.alerts.count, 0, "\(step)：アプリの上のアラート")
        }
        Wait.exists(s.el("library.addBook"), "library.addBook")
        expectNoPrompt("起動した直後")

        s.addBook(title: Fixture.botchan)
        expectNoPrompt("本を追加した後")
        s.tap("book.startReading")
        s.expectState(.reading)
        expectNoPrompt("読み始めた後")
        s.advance(seconds: 300)
        s.finishAndSave(title: Fixture.botchan)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "読書を1回終えて保存した")
        expectNoPrompt("終えて保存した後")
    }

    // MARK: AC-23

    /// AC-23：App First Opened は送り済み（T2 の flags）で本が0冊。題名「坊っちゃん」で追加し、読み始め、5分読んで、ページ72で終える。
    /// 15 の名前のイベントは Book Added、Reading Session Started、Reading Session Finished の3件。届いたものの全体に「坊っちゃん」が0回
    /// （UTF-8 のままと、パーセントエンコードした形）。プロパティの値で 72 と等しいものは0個。
    @MainActor
    func test_AC23_telemetryHasNoTitleOrPageValues() throws {
        let probe = try TelemetryProbe(eventsMode: .ok, separateControl: false, test: self)
        var config = LaunchConfig.seeded(Seed(books: []))
        probe.apply(to: &config)
        let s = AppSession.launch(config)

        s.addBook(title: Fixture.botchan)
        s.tap("book.startReading")
        s.expectState(.reading)
        s.advance(seconds: 300)
        s.finishAndSave(title: Fixture.botchan, page: "72")

        let snapshot = probe.waitDrained(s, total: 3)
        let named = snapshot.names.filter { TelemetrySnapshot.prdEventNames.contains($0) }
        XCTAssertEqual(
            named.sorted(), ["Book Added", "Reading Session Finished", "Reading Session Started"],
            "15 の名前のイベント（届いた順：\(snapshot.names)）")

        let everything = snapshot.rawTexts.joined(separator: "\n")
        let encodedUpper = Fixture.botchan.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        XCTAssertFalse(encodedUpper.isEmpty, "前提：パーセントエンコードの形を作れた")
        XCTAssertEqual(everything.components(separatedBy: Fixture.botchan).count - 1, 0, "UTF-8 の「坊っちゃん」の数")
        XCTAssertEqual(everything.components(separatedBy: encodedUpper).count - 1, 0, "パーセントエンコード（大文字）の数")
        XCTAssertEqual(everything.components(separatedBy: encodedUpper.lowercased()).count - 1, 0, "パーセントエンコード（小文字）の数")

        var equalTo72: [String] = []
        for event in snapshot.events {
            let properties = (event["properties"] as? [String: Any]) ?? [:]
            for (key, value) in properties {
                if let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(), number.intValue == 72, number.doubleValue == 72 {
                    equalTo72.append("\(event["name"] ?? "?").\(key)")
                } else if let text = value as? String, text.trimmingCharacters(in: .whitespaces) == "72" {
                    equalTo72.append("\(event["name"] ?? "?").\(key)")
                }
            }
        }
        XCTAssertEqual(equalTo72, [], "プロパティの値で 72 と等しいもの")
    }

    // MARK: AC-24

    /// AC-24：週の始めは月曜、今週の合計が50分で、今週の Reading Week Reached は未送信。15分の読書を終え、続けて10分の読書を終えると、
    /// 受け口が受け取った Reading Week Reached（threshold_min = 60）は今週ちょうど1件。
    @MainActor
    func test_AC24_weekReachedIsSentOncePerWeek() throws {
        let probe = try TelemetryProbe(eventsMode: .ok, separateControl: false, test: self)
        let seed = Seed(
            books: [Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 40)],
            sessions: [
                Fixture.session(101, book: Fixture.botchanId, startedAt: WallClock("2026-10-20T21:00:00"), seconds: 3000, endPage: 40, pagesRead: 40)
            ])
        var config = LaunchConfig.seeded(seed)
        config.firstWeekday = 2
        probe.apply(to: &config)
        let s = AppSession.launch(config)
        Wait.value(s.el("home.weekTotal"), equals: L10n.minutes(50), "前提：今週の合計は50分")

        s.tap("home.startReading")
        s.expectState(.reading)
        s.advance(seconds: 15 * 60)
        s.finishAndSave(title: Fixture.botchan)

        s.tap("book.startReading")
        s.expectState(.reading)
        s.advance(seconds: 10 * 60)
        s.finishAndSave(title: Fixture.botchan)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(3), "前提：読書を2回終えた")

        // Started、Finished、Week Reached、Started、Finished の5件の送信が終わるのを待つ
        let snapshot = probe.waitDrained(s, total: 5)
        let reached = snapshot.events.filter { ($0["name"] as? String) == "Reading Week Reached" }
        XCTAssertEqual(reached.count, 1, "Reading Week Reached の数（届いた順：\(snapshot.names)）")
        let threshold = (reached.first?["properties"] as? [String: Any])?["threshold_min"]
        XCTAssertEqual(threshold.map { "\($0)" }, "60", "threshold_min")
    }
}
