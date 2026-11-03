import XCTest

final class WidgetAndActivityAcceptanceTests: AcceptanceTestBase {
    /// PRD AC-28 の行頭禁則の字（「、」「。」「」」「』」「）」「ー」）と、その縦書き用の字（U+FE11、U+FE12、U+FE42、U+FE44、U+FE5A）。
    private let prohibitedLineStart: Set<String> = [
        "、", "。", "」", "』", "）", "ー",
        "\u{FE11}", "\u{FE12}", "\u{FE42}", "\u{FE44}", "\u{FE5A}"
    ]

    /// `renders[]` の1つから `composition` を取り、縦書きの升目（`cells`）の字を並べて返す。
    private func verticalCells(_ render: [String: Any]) -> (composition: [String: Any], cells: [[String: Any]]) {
        let comp = render["composition"] as? [String: Any] ?? [:]
        let cells = comp["cells"] as? [[String: Any]] ?? []
        return (comp, cells)
    }

    func test_AC27_ロック画面ウィジェットに縦書きの一行とページが出る() {
        let line = "下人の行方は、誰も知らない。"
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: line
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:153x68,accessoryRectangular:172x76"]
        )

        // PRD AC-27 Then：どちらの枠でも一行の字がすべて出て（欠け0字）、p.61 と押したときの URL が入る。
        let renders = readHookJSON("hook.widget")["renders"] as? [[String: Any]] ?? []
        XCTAssertEqual(renders.count, 2, "renders: \(renders)")
        for render in renders {
            let request = render["request"] as? [String: Any] ?? [:]
            XCTAssertEqual(request["family"] as? String, "accessoryRectangular")
            XCTAssertEqual(render["state"] as? String, "normal", "render: \(render)")
            XCTAssertEqual(render["url"] as? String, "yomuma://open?entry=lock_widget")
            let texts = render["texts"] as? [String: Any] ?? [:]
            XCTAssertEqual(texts["widget.line"] as? String, line)
            XCTAssertEqual(texts["widget.page"] as? String, "p.61")
            let (comp, cells) = verticalCells(render)
            XCTAssertEqual(comp["orientation"] as? String, "vertical")
            XCTAssertEqual(comp["displayedLine"] as? String, line)
            XCTAssertEqual(comp["shortened"] as? Bool, false)
            let joined = cells.compactMap { $0["source"] as? String }.joined()
            XCTAssertEqual(joined, line, "欠け0字（枠 \(request)）")
        }
        attachScreenshot(name: "AC-27_lock_widget")
    }

    func test_AC28_縦書きの字形置換と行頭禁則処理を検証する() {
        // PRD AC-28 Given：(1)〜(3) は PRD の一行。(4)〜(6) は L+1 字目（L＝referenceL＝5。contracts/test-hooks.md「H22 の組み方」の表）が
        // 「、」「」」「ー」の25字の一行（25字なら L が referenceL と同じになる。禁則の字が多く送りで列が増える並びにしない）。
        let kana19 = String(repeating: "あ", count: 19)
        let cases: [(name: String, line: String, isLPlusOne: Bool)] = [
            ("(1)", "下人は、雨やみを待っていた。", false),
            ("(2)", "「あ」と言った。", false),
            ("(3)", "ルーペを手に取った。", false),
            ("(4) L+1 字目が「、」", "あいうえお、" + kana19, true),
            ("(5) L+1 字目が「」」", "「あいうえ」" + kana19, true),
            ("(6) L+1 字目が「ー」", "あいうえおー" + kana19, true)
        ]
        let expectedDisplay: [String: String] = ["、": "\u{FE11}", "。": "\u{FE12}", "「": "\u{FE41}", "」": "\u{FE42}"]

        for c in cases {
            XCTAssertLessThanOrEqual(c.line.count, 25, c.name)
            let seed = makeSeedJSON(books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    status: "current",
                    progressUnit: "page",
                    page: 61,
                    lastLine: c.line
                )
            ])
            resetAndLaunch(
                seedJSON: seed,
                extraArgs: ["-uitest-widget", "accessoryRectangular:153x68,accessoryRectangular:172x76"]
            )

            // When：いちばん小さい枠といちばん大きい枠の組み方の結果（列ごとの字と字の向き）を読む（H22）。
            let renders = readHookJSON("hook.widget")["renders"] as? [[String: Any]] ?? []
            XCTAssertEqual(renders.count, 2, "\(c.name) renders: \(renders)")
            for render in renders {
                let request = render["request"] as? [String: Any] ?? [:]
                let frameName = "\(c.name) \(request["width"] ?? "?")x\(request["height"] ?? "?")"
                let (comp, cells) = verticalCells(render)
                XCTAssertEqual(comp["orientation"] as? String, "vertical", frameName)
                XCTAssertEqual(comp["displayedLine"] as? String, c.line, frameName)
                XCTAssertFalse(cells.isEmpty, "\(frameName) composition: \(comp)")

                // Then：組み方の結果の字を並べると一行の字がすべてそろう。
                let joined = cells.compactMap { $0["source"] as? String }.joined()
                XCTAssertEqual(joined, c.line, "\(frameName) 欠けなく並ぶ")

                // L は、その枠で禁則の字のない25字を組んだときの1列の字数（referenceL）。(4)〜(6) は25字なので L＝referenceL。
                let referenceL = comp["referenceL"] as? Int ?? -1
                XCTAssertEqual(referenceL, 5, "\(frameName) referenceL（契約の表は W-1 の両方の枠で5）")
                if c.isLPlusOne {
                    XCTAssertEqual(comp["L"] as? Int, referenceL, "\(frameName) L＝referenceL のとき L+1 字目が列の先頭に来る")
                }

                // 列は右から左へ並ぶ（column が増えるほど x が小さい）。
                var xByColumn: [Int: Double] = [:]
                for cell in cells {
                    if let col = cell["column"] as? Int, let x = cell["x"] as? Double, xByColumn[col] == nil {
                        xByColumn[col] = x
                    }
                }
                let columns = xByColumn.keys.sorted()
                XCTAssertEqual(columns.first, 1, frameName)
                XCTAssertEqual(columns.count, comp["columnCount"] as? Int, frameName)
                for (a, b) in zip(columns, columns.dropFirst()) {
                    XCTAssertGreaterThan(xByColumn[a] ?? 0, xByColumn[b] ?? 0, "\(frameName) 列 \(a) は列 \(b) の右")
                }

                for cell in cells {
                    let source = cell["source"] as? String ?? ""
                    let display = cell["display"] as? String ?? ""
                    let rotation = cell["rotation"] as? Int ?? -1
                    let column = cell["column"] as? Int ?? 0
                    let row = cell["row"] as? Int ?? 0
                    // どの列も、先頭の字が禁則の字（とその縦書き用の字）のどれでもない。
                    if row == 1 {
                        XCTAssertFalse(prohibitedLineStart.contains(source), "\(frameName) 列 \(column) の先頭が「\(source)」")
                        XCTAssertFalse(prohibitedLineStart.contains(display), "\(frameName) 列 \(column) の先頭が「\(display)」")
                    }
                    // 「、」「。」「「」「」」は U+FE11、U+FE12、U+FE41、U+FE42 で出て、「ー」には90度回す印が付く。
                    if let expected = expectedDisplay[source] {
                        XCTAssertEqual(display, expected, "\(frameName) 「\(source)」の縦書き用の字")
                    }
                    if source == "ー" {
                        XCTAssertEqual(rotation, 90, "\(frameName) 「ー」を90度回す")
                    } else {
                        XCTAssertEqual(rotation, 0, "\(frameName) 「\(source)」は回さない")
                    }
                }
            }
            if c.name == "(1)" {
                attachScreenshot(name: "AC-28_kinsoku_1")
            }
        }
    }

    func test_AC29_26字以上の一行の句読点位置による縮め方を検証する() {
        let cases: [(lineText: String, expected: String)] = [
            (
                String(repeating: "あ", count: 25),
                String(repeating: "あ", count: 25)
            ),
            (
                String(repeating: "あ", count: 17) + "、" + String(repeating: "い", count: 13),
                String(repeating: "あ", count: 17) + "、"
            ),
            (
                String(repeating: "あ", count: 9) + "、" + String(repeating: "い", count: 21),
                String(repeating: "あ", count: 9) + "、" + String(repeating: "い", count: 14) + "…"
            ),
            (
                String(repeating: "あ", count: 12) + "、" + String(repeating: "い", count: 18),
                String(repeating: "あ", count: 12) + "、"
            ),
            (
                String(repeating: "あ", count: 11) + "、" + String(repeating: "い", count: 19),
                String(repeating: "あ", count: 11) + "、" + String(repeating: "い", count: 12) + "…"
            ),
            (
                String(repeating: "あ", count: 7) + "、" + String(repeating: "い", count: 11) + "。" + String(repeating: "う", count: 11),
                String(repeating: "あ", count: 7) + "、" + String(repeating: "い", count: 11) + "。"
            )
        ]

        for c in cases {
            let seed = makeSeedJSON(books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    status: "current",
                    progressUnit: "page",
                    page: 61,
                    lastLine: c.lineText
                )
            ])
            resetAndLaunch(
                seedJSON: seed,
                extraArgs: ["-uitest-widget", "accessoryRectangular:153x68,accessoryRectangular:172x76"]
            )
            let bmLine = element("bookmark.line")
            XCTAssertTrue(bmLine.waitForExistence(timeout: uiTimeout))
            XCTAssertEqual(bmLine.label, c.lineText)

            let widgetHook = readHookJSON("hook.widget")
            let renders = widgetHook["renders"] as? [[String: Any]] ?? []
            XCTAssertFalse(renders.isEmpty)
            for render in renders {
                let texts = render["texts"] as? [String: Any] ?? [:]
                let comp = render["composition"] as? [String: Any] ?? [:]
                let displayedLine = (texts["widget.line"] as? String) ?? (comp["displayedLine"] as? String) ?? ""
                XCTAssertEqual(displayedLine, c.expected)
            }
        }
    }

    func test_AC30_欧文のみの一行は横書き1行で出る() {
        let line = "It was raining."
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "Rain",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: line
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        // PRD AC-30 Then：列に分けず、横書きの1行で「It was raining.」が出る。
        // 横書きの composition は orientation・displayedLine・shortened（と page）だけで、縦書きの升目の項目は書かない（契約「横書きの一行」）。
        let renders = readHookJSON("hook.widget")["renders"] as? [[String: Any]] ?? []
        XCTAssertEqual(renders.count, 1, "renders: \(renders)")
        let render = renders.first ?? [:]
        XCTAssertEqual(render["state"] as? String, "normal", "render: \(render)")
        let texts = render["texts"] as? [String: Any] ?? [:]
        XCTAssertEqual(texts["widget.line"] as? String, line)
        let comp = render["composition"] as? [String: Any] ?? [:]
        XCTAssertEqual(comp["orientation"] as? String, "horizontal", "composition: \(comp)")
        XCTAssertEqual(comp["displayedLine"] as? String, line)
        XCTAssertEqual(comp["shortened"] as? Bool, false)
        for verticalKey in ["cells", "columnCount", "L", "referenceL", "fontSize", "frame", "feedCount", "kinsokuRelaxed", "slack"] {
            XCTAssertNil(comp[verticalKey], "横書きでは \(verticalKey) を書かない: \(comp)")
        }
    }

    func test_AC31_一行がないときは書名とページをウィジェットに出す() {
        let seedWithPage = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookB,
                title: "檸檬",
                status: "current",
                progressUnit: "page",
                page: 120
            )
        ])
        resetAndLaunch(
            seedJSON: seedWithPage,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"]
        )
        let raw1 = readHookString("hook.widget")
        XCTAssertTrue(raw1.contains("檸檬"))
        XCTAssertTrue(raw1.contains("p.120"))

        let seedNoPage = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookB,
                title: "檸檬",
                status: "current"
            )
        ])
        resetAndLaunch(
            seedJSON: seedNoPage,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"]
        )
        let raw2 = readHookString("hook.widget")
        XCTAssertTrue(raw2.contains("檸檬"))
        XCTAssertFalse(raw2.contains("p.120"))
    }

    func test_AC32_今の本がないときはウィジェットに空の文言が出る() {
        resetAndLaunch(extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"])
        let raw1 = readHookString("hook.widget")
        XCTAssertTrue(raw1.contains("empty") || raw1.contains("widget.empty"))

        let seedTsundokuOnly = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookB,
                title: "檸檬",
                status: "tsundoku"
            )
        ])
        resetAndLaunch(
            seedJSON: seedTsundokuOnly,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"]
        )
        let raw2 = readHookString("hook.widget")
        XCTAssertTrue(raw2.contains("empty") || raw2.contains("widget.empty"))
    }

    func test_AC33_しおり保存でウィジェットが1回だけ再読み込みされる() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 43,
                lastLine: "旧の一行"
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            now: "2026-10-18T21:00:00+09:00",
            timezone: "Asia/Tokyo",
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()

        element("mark.manual").tap()
        let lineField = element("mark.lineField")
        let pageField = element("mark.pageField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        lineField.tap()
        lineField.typeText("下人の行方は、誰も知らない。")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        let closeBtn = element("result.close")
        if closeBtn.waitForExistence(timeout: uiTimeout) {
            closeBtn.tap()
        }

        let hookState = readHookState()
        let reloadsRaw = hookState["widgetReloads"] ?? ""
        XCTAssertTrue(reloadsRaw.contains("mark.save:1"), "Expected mark.save:1 in widgetReloads, got: \(reloadsRaw)")

        let widgetJSON = readHookJSON("hook.widget")
        let reloadRequests = widgetJSON["reloadRequests"] as? [String: Any] ?? [:]
        let byCause = reloadRequests["byCause"] as? [String: Int] ?? [:]
        XCTAssertEqual(byCause["mark.save"], 1)

        let widgetRaw = readHookString("hook.widget")
        XCTAssertTrue(widgetRaw.contains("p.61"))
    }

    func test_AC34_隠す設定オンでウィジェットとLiveActivityから書名と一行を隠す() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    status: "current",
                    progressUnit: "page",
                    page: 61,
                    lastLine: "下人の行方は、誰も知らない。"
                )
            ],
            settings: makeSeedSettings(
                flipToStartEnabled: true,
                hideOnWidgets: true,
                entryTime: "21:00",
                widgetGuideShown: true
            )
        )
        resetAndLaunch(
            seedJSON: seed,
            now: "2026-10-18T20:00:00+09:00",
            timezone: "Asia/Tokyo",
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"]
        )

        let bmLine = element("bookmark.line")
        XCTAssertTrue(bmLine.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(bmLine.label, "下人の行方は、誰も知らない。")

        let widgetRaw = readHookString("hook.widget")
        XCTAssertFalse(widgetRaw.contains("羅生門"))
        XCTAssertFalse(widgetRaw.contains("下人の行方は"))
        XCTAssertTrue(widgetRaw.contains("p.61"))

        let laRaw = readHookString("hook.liveActivity")
        XCTAssertFalse(laRaw.contains("羅生門"))
        XCTAssertFalse(laRaw.contains("下人の行方は"))
    }

    func test_AC35_StandBy用の小ウィジェットに縦書きの一行とページが出る() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "下人の行方は、誰も知らない。"
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "systemSmall:148x148,systemSmall:170x170"]
        )

        let raw = readHookString("hook.widget")
        XCTAssertTrue(raw.contains("p.61"))
        XCTAssertTrue(raw.contains("yomuma://open?entry=small_widget"))
        XCTAssertTrue(raw.contains("下人の行方は"))
        attachScreenshot(name: "AC-35_small_widget")
    }

    func test_AC36_しおり保存で翌晩21時のLiveActivityが1件予約される() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    status: "current",
                    progressUnit: "page",
                    page: 43,
                    lastLine: "旧の一行"
                )
            ],
            settings: makeSeedSettings(
                flipToStartEnabled: true,
                hideOnWidgets: false,
                entryTime: "21:00",
                widgetGuideShown: true
            )
        )
        for startAt in ["2026-10-18T22:00:00+09:00", "2026-10-19T00:00:00+09:00"] {
            resetAndLaunch(seedJSON: seed, now: startAt, timezone: "Asia/Tokyo")

            element("bookmark.start").tap()
            advanceClock(seconds: 1800)
            element("reading.end").tap()

            element("mark.pageOnly").tap()
            let pageField = element("mark.pageField")
            XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
            pageField.tap()
            pageField.typeText("61")
            element("mark.save").tap()

            let la = readHookJSON("hook.liveActivity")
            let activities = la["activities"] as? [[String: Any]] ?? []
            XCTAssertEqual(activities.count, 1)
            let laRaw = readHookString("hook.liveActivity")
            XCTAssertTrue(laRaw.contains("2026-10-19"))
            XCTAssertTrue(laRaw.contains("p.61"))
        }
    }

    func test_AC37_LiveActivityオフ時は予約要求を出さず設定に案内を出す() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 43
            )
        ])
        let laConfig = """
        {
          "areActivitiesEnabled": false
        }
        """
        resetAndLaunch(
            seedJSON: seed,
            now: "2026-10-18T22:00:00+09:00",
            timezone: "Asia/Tokyo",
            liveActivityJSON: laConfig,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()

        element("mark.pageOnly").tap()
        element("mark.pageField").tap()
        element("mark.pageField").typeText("61")
        element("mark.save").tap()

        XCTAssertEqual(app.alerts.count, 0)
        let closeBtn = element("result.close")
        if closeBtn.waitForExistence(timeout: uiTimeout) {
            closeBtn.tap()
        }

        let la = readHookJSON("hook.liveActivity")
        let requests = la["requests"] as? [Any] ?? []
        XCTAssertEqual(requests.count, 0)

        let widgetRaw = readHookString("hook.widget")
        XCTAssertTrue(widgetRaw.contains("p.61"))

        element("toolbar.settings").tap()
        XCTAssertTrue(element("settings.liveActivity.off").waitForExistence(timeout: uiTimeout))
    }

    func test_AC38_夜の入口の時刻を15分刻みで変えると予約時刻が変わる() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 43
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            now: "2026-10-18T22:00:00+09:00",
            timezone: "Asia/Tokyo"
        )

        element("toolbar.settings").tap()
        let entryPicker = element("settings.entryTime")
        XCTAssertTrue(entryPicker.waitForExistence(timeout: uiTimeout))
        entryPicker.tap()

        let opt2245 = element("settings.entryTime.22:45")
        if opt2245.waitForExistence(timeout: uiTimeout) {
            opt2245.tap()
        }

        let settingsSnapshot = readStoreSettings()
        XCTAssertEqual(settingsSnapshot["entryTime"] as? String, "22:45")

        navigateBackToBookmark()
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.later").tap()

        let laRaw = readHookString("hook.liveActivity")
        XCTAssertTrue(laRaw.contains("22:45") || laRaw.contains("13:45:00"))
    }

    func test_AC39_予約がない晩でもアイコン起動でしおり画面が開き伏せ監視がオンになる() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "下人の行方は、誰も知らない。"
            )
        ])
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T22:30:00+09:00", timezone: "Asia/Tokyo")

        XCTAssertTrue(element("bookmark.line").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("bookmark.page").waitForExistence(timeout: uiTimeout))
        let startBtn = element("bookmark.start")
        XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(startBtn.isEnabled)
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertEqual(app.sheets.count, 0)

        let hookState = readHookState()
        XCTAssertEqual(hookState["flipMonitoring"], "on")
    }

    func test_AC40_入口のURLと300秒境界で記録の入口の印が決まる() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current"
            )
        ])

        // (1) lock_widget, (2) small_widget, (3) live_activity
        for entry in ["lock_widget", "small_widget", "live_activity"] {
            resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
            openEntryURL(entry)
            element("bookmark.start").tap()
            advanceClock(seconds: 120)
            element("reading.end").tap()
            element("mark.later").tap()
            let hookState = readHookState()
            XCTAssertEqual(hookState["entry"], entry)
        }

        // (4) アイコン起動 -> app
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readHookState()["entry"], "app")

        // (5) URL起動後バックグラウンド経由 -> app
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
        openEntryURL("lock_widget")
        XCUIDevice.shared.press(.home)
        app.activate()
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readHookState()["entry"], "app")

        // (6) 299秒後開始 -> lock_widget
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
        openEntryURL("lock_widget")
        advanceClock(seconds: 299)
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readHookState()["entry"], "lock_widget")

        // (7) 301秒後開始 -> app
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
        openEntryURL("lock_widget")
        advanceClock(seconds: 301)
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readHookState()["entry"], "app")
    }

    func test_AC41_表示中の予約LiveActivityが読書中から結果表示へ遷移する() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 43,
                lastLine: "下人の行方は、誰も知らない。"
            )
        ])
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T20:00:00+09:00", timezone: "Asia/Tokyo")
        transitionLiveActivity("started")

        element("bookmark.start").tap()
        let laDuring = readHookString("hook.liveActivity")
        XCTAssertTrue(laDuring.contains("reading"))
        XCTAssertTrue(laDuring.contains("liveActivity.end"))

        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.pageOnly").tap()
        element("mark.pageField").tap()
        element("mark.pageField").typeText("61")
        element("mark.save").tap()

        let laAfter = readHookString("hook.liveActivity")
        XCTAssertTrue(laAfter.contains("10") && laAfter.contains("p.61"))
    }

    func test_AC96_ウィジェットの置き方案内は最初の1回だけ出る() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    status: "current"
                )
            ],
            settings: makeSeedSettings(
                flipToStartEnabled: true,
                hideOnWidgets: false,
                entryTime: "21:00",
                widgetGuideShown: false
            )
        )
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")

        element("bookmark.setMark").tap()
        element("mark.manual").tap()
        element("mark.lineField").tap()
        element("mark.lineField").typeText("下人の行方は、誰も知らない。")
        element("mark.save").tap()

        let guide = element("widgetGuide")
        XCTAssertTrue(guide.waitForExistence(timeout: uiTimeout))
        let hookState1 = readHookState()
        XCTAssertTrue((hookState1["notice"] ?? "").contains("widgetGuide:1"))

        let closeGuide = element("widgetGuide.close")
        if closeGuide.waitForExistence(timeout: uiTimeout) {
            closeGuide.tap()
        }

        // 2回目
        element("bookmark.setMark").tap()
        element("mark.manual").tap()
        element("mark.lineField").tap()
        element("mark.lineField").typeText("二回目の一行。")
        element("mark.save").tap()
        XCTAssertEqual(matchingCount("widgetGuide"), 0)

        // 再起動後3回目
        relaunchPreservingStore()
        element("bookmark.setMark").tap()
        element("mark.manual").tap()
        element("mark.lineField").tap()
        element("mark.lineField").typeText("三回目の一行。")
        element("mark.save").tap()
        XCTAssertEqual(matchingCount("widgetGuide"), 0)
    }

    func test_AC97_LiveActivity予約失敗時はアラートを出さず次回前面復帰時に予約し直す() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current"
            )
        ])
        let laConfig = """
        {
          "areActivitiesEnabled": true,
          "failScheduleCount": 1
        }
        """
        resetAndLaunch(
            seedJSON: seed,
            now: "2026-10-18T22:00:00+09:00",
            timezone: "Asia/Tokyo",
            liveActivityJSON: laConfig,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.later").tap()

        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertTrue(element("result.summary").waitForExistence(timeout: uiTimeout))

        XCUIDevice.shared.press(.home)
        app.activate()

        let la = readHookJSON("hook.liveActivity")
        let activities = la["activities"] as? [[String: Any]] ?? []
        XCTAssertEqual(activities.count, 1)
        let laRaw = readHookString("hook.liveActivity")
        XCTAssertTrue(laRaw.contains("2026-10-19"))
    }

    func test_AC98_読まなかった晩のLiveActivityは翌朝前面復帰で終了し今夜分を予約する() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current"
            )
        ])
        resetAndLaunch(seedJSON: seed, now: "2026-10-19T20:00:00+09:00", timezone: "Asia/Tokyo")

        let laInitial = readHookString("hook.liveActivity")
        XCTAssertTrue(laInitial.contains("2026-10-20") || laInitial.contains("19:00:00"))

        transitionLiveActivity("started")

        XCUIDevice.shared.press(.home)
        advanceClock(seconds: 11 * 3600)
        app.activate()

        let laAfter = readHookString("hook.liveActivity")
        XCTAssertTrue(laAfter.contains("2026-10-20"))
    }

    func test_AC99_ウィジェットとしおり画面のVoiceOverラベルに縦書き用字形が含まれない() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "「下人の行方は、誰も知らなーい。」"
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        let bmLine = element("bookmark.line")
        XCTAssertTrue(bmLine.waitForExistence(timeout: uiTimeout))
        let label = bmLine.label
        XCTAssertEqual(label, "「下人の行方は、誰も知らなーい。」")
        for scalar in label.unicodeScalars {
            XCTAssertFalse((0xFE10...0xFE4F).contains(scalar.value))
        }

        // PRD AC-99 Then：読み上げのまとまりは1つ、ラベルは書名・p.61 の値・保存した一行を含み、縦書き用の字を含まない。
        // 読むのは contracts/hooks/h22-widget.schema.json の renders[].accessibility（label、groupCount）。
        let widgetJSON = readHookJSON("hook.widget")
        let renders = widgetJSON["renders"] as? [[String: Any]] ?? []
        XCTAssertEqual(renders.count, 1, "renders: \(renders)")
        let accessibility = renders.first?["accessibility"] as? [String: Any] ?? [:]
        let widgetLabel = accessibility["label"] as? String ?? ""
        XCTAssertEqual(accessibility["identifier"] as? String, "widget.rectangular")
        XCTAssertEqual(accessibility["groupCount"] as? Int, 1, "accessibility: \(accessibility)")
        XCTAssertTrue(widgetLabel.contains("羅生門"), widgetLabel)
        XCTAssertTrue(widgetLabel.contains("61"), widgetLabel)
        XCTAssertTrue(widgetLabel.contains("「下人の行方は、誰も知らなーい。」"), widgetLabel)
        for scalar in widgetLabel.unicodeScalars {
            XCTAssertFalse((0xFE10...0xFE4F).contains(scalar.value), widgetLabel)
        }
    }

    func test_AC130_入口時刻前の読書開始で今夜の予約を取り消し終了時に予約を見直す() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    status: "current"
                )
            ],
            settings: makeSeedSettings(
                flipToStartEnabled: true,
                hideOnWidgets: false,
                entryTime: "21:00",
                widgetGuideShown: true
            )
        )

        // (1) 20:30 開始 -> 背面復帰を挟み 21:05 (35分) で終了 -> 翌晩 2026-10-19 21:00 予約
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T20:30:00+09:00", timezone: "Asia/Tokyo")
        element("bookmark.start").tap()

        XCUIDevice.shared.press(.home)
        advanceClock(seconds: 2100)
        app.activate()

        element("reading.end").tap()
        element("mark.later").tap()

        let recs1 = readStoreRecords()
        XCTAssertEqual(recs1.count, 1)
        XCTAssertEqual(recs1.first?["minutes"] as? Int, 35)

        let la1 = readHookString("hook.liveActivity")
        XCTAssertTrue(la1.contains("2026-10-19"))

        // (2) 20:30 開始 -> 50秒（1分未満）で終了 -> session.tooShort + 今夜 2026-10-18 21:00 予約が戻る
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T20:30:00+09:00", timezone: "Asia/Tokyo")
        element("bookmark.start").tap()
        advanceClock(seconds: 50)
        element("reading.end").tap()

        XCTAssertTrue(element("session.tooShort").waitForExistence(timeout: uiTimeout))
        let la2 = readHookString("hook.liveActivity")
        XCTAssertTrue(la2.contains("2026-10-18"))
    }
}
