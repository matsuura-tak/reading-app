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
    /// 手順の区切りの4か所で数えるのに加え、手順の途中に出た割り込みも addUIInterruptionMonitor で記録して落とす。
    @MainActor
    func test_AC21_noPermissionPromptsDuringFirstSession() throws {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let beforeLaunch = XCUIApplication()
        // 4つの case の名前は Apple の文書（XCUIAutomation の XCUIProtectedResource の一覧）で確かめた（2026-10-21）。
        // iOS 17 のシミュレーターでリセットが効くこと（userTracking を含む）は CI で確かめる。
        for resource in [XCUIProtectedResource.camera, .photos, .location, .userTracking] {
            beforeLaunch.resetAuthorizationStatus(for: resource)
        }
        // 割り込み（システムのダイアログ）が出たら、種類と label を記録して XCTFail する。true は「処理した」の印で、閉じはしない。
        // 閉包は MainActor のこの関数の中で作るので、element と interruptions は MainActor で読み書きする（CI でコンパイルを確かめる）。
        var interruptions: [String] = []
        let monitor = addUIInterruptionMonitor(withDescription: "AC-21：権限などのシステムのダイアログ") { element in
            let found = "type \(element.elementType.rawValue)「\(element.label)」"
            interruptions.append(found)
            XCTFail("AC-21：手順の途中でシステムのダイアログが出た：\(found)")
            return true
        }
        defer { removeUIInterruptionMonitor(monitor) }
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
        XCTAssertEqual(interruptions, [], "addUIInterruptionMonitor が記録した割り込み")
    }

    // MARK: AC-23

    /// AC-23：App First Opened は送り済み（T2 の flags）で本が0冊。題名「坊っちゃん」で追加し、読み始め、5分読んで、ページ72で終える。
    /// 15 の名前のイベントは Book Added、Reading Session Started、Reading Session Finished の3件。届いたものの全体に「坊っちゃん」が0回
    /// （UTF-8 のままと、パーセントエンコードした形の大文字と小文字）。JSON を読み直した events の全部の値にも0回
    /// （\uXXXX で書き出された題名は本文の文字では見つからないため）。プロパティの値で 72 と等しいものは0個。
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

        // パーセントエンコードの形は UTF-8 のバイト列から自分で作る。addingPercentEncoding(withAllowedCharacters: .alphanumerics) は
        // Unicode の L*、M*、N* を許すので、5文字とも Lo の「坊っちゃん」を変えずに返す（G2 r1 の重大1）。
        let encodedUpper = Fixture.botchan.utf8.map { String(format: "%%%02X", $0) }.joined()
        let encodedLower = encodedUpper.lowercased()
        XCTAssertNotEqual(encodedUpper, Fixture.botchan, "前提：パーセントエンコードの形は元の文字と違う")
        XCTAssertEqual(encodedUpper, "%E5%9D%8A%E3%81%A3%E3%81%A1%E3%82%83%E3%82%93", "前提：パーセントエンコード（大文字）の形")
        XCTAssertEqual(encodedLower, "%e5%9d%8a%e3%81%a3%e3%81%a1%e3%82%83%e3%82%93", "前提：パーセントエンコード（小文字）の形")
        let titleForms = [("UTF-8", Fixture.botchan), ("パーセントエンコード（大文字）", encodedUpper), ("パーセントエンコード（小文字）", encodedLower)]

        let everything = snapshot.rawTexts.joined(separator: "\n")
        for (form, text) in titleForms {
            XCTAssertEqual(everything.components(separatedBy: text).count - 1, 0, "届いたものの全体で \(form) の「坊っちゃん」の数")
        }

        // JSON を読み直した events の全部の値（キーと入れ子も）を見る。\uXXXX で書き出された題名は、読み直すと「坊っちゃん」に戻る。
        var titleFound: [String] = []
        func findTitle(_ value: Any, _ path: String) {
            switch value {
            case let object as [String: Any]:
                for (key, child) in object {
                    findTitle(key, "\(path).<key>")
                    findTitle(child, "\(path).\(key)")
                }
            case let array as [Any]:
                for (index, child) in array.enumerated() { findTitle(child, "\(path)[\(index)]") }
            case let text as String:
                for (form, title) in titleForms where text.contains(title) { titleFound.append("\(path)（\(form)）") }
            default:
                break
            }
        }
        for (index, event) in snapshot.events.enumerated() { findTitle(event, "events[\(index)]") }
        XCTAssertEqual(titleFound, [], "読み直した events の値に「坊っちゃん」が出た場所")

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
        XCTAssertEqual(threshold as? String, "60", "threshold_min は文字の \"60\"（contracts/telemetry.md）")
    }
}
