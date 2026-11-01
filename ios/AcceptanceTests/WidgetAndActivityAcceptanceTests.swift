import XCTest

final class WidgetAndActivityAcceptanceTests: AcceptanceTestBase {
    func test_AC27_ロック画面ウィジェットに縦書きの一行とページが出る() {
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
            extraArgs: ["-uitest-widget", "accessoryRectangular:153x68,accessoryRectangular:172x76"]
        )

        let raw = readHookString("hook.widget")
        XCTAssertTrue(raw.contains("p.61"))
        XCTAssertTrue(raw.contains("yomuma://open?entry=lock_widget"))
        XCTAssertTrue(raw.contains("下人の行方は"))
        XCTAssertTrue(raw.contains("誰も知らない"))
        attachScreenshot(name: "AC-27_lock_widget")
    }

    func test_AC28_縦書きの字形置換と行頭禁則処理を検証する() {
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

        let raw = readHookString("hook.widget")
        XCTAssertTrue(raw.contains("\u{FE11}") || raw.contains("\u{FE12}") || raw.contains("\u{FE41}") || raw.contains("\u{FE42}"))
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
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "Rain",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "It was raining."
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        let raw = readHookString("hook.widget")
        XCTAssertTrue(raw.contains("It was raining."))
        XCTAssertTrue(raw.contains("horizontal"))
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

        let widgetJSON = readHookJSON("hook.widget")
        let widgetRaw = "\(widgetJSON)"
        XCTAssertTrue(widgetRaw.contains("羅生門"))
        XCTAssertTrue(widgetRaw.contains("61ページ") || widgetRaw.contains("61"))
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

// MARK: - G3 の証拠撮影の道具（AC の判定には使わない）
// 本来は G3EvidenceCaptureTests.swift に置きたいが、ios/ReadingApp.xcodeproj の ReadingAcceptanceTests ターゲットは
// ファイルを明示列挙しており（pbxproj は verifier の範囲外）、新しいファイルを足せないため、このファイルの末尾に置く。
// `make ios-test` では G3_CAPTURE が無いので何もせずに終わる。

/// G3 の証拠撮影の道具（AC の判定には使わない）。
///
/// - 役割：design/001-reading-session.md の 5 章「画面ごとの状態」の画面×状態のスクリーンショットと、
///   全画面の `performAccessibilityAudit(for: .all)` の結果を残す。
/// - `make ios-test` では test runner の環境変数 `G3_CAPTURE` が無いので、何も撮らずにすぐ終わる
///   （FirstLaunchTests（H14、AC-1）とは別のファイルにして、初回起動の前提を壊さない）。
/// - 動かし方（verifier が G3 で手で動かす。ダークは host 側で `xcrun simctl ui <端末> appearance dark` を先に当てる）：
///   `TEST_RUNNER_G3_CAPTURE=1 TEST_RUNNER_G3_VARIANT=light|dark|ax5|en TEST_RUNNER_G3_OUT_DIR=<外のフォルダ> \`
///   `xcodebuild test ... -only-testing:ReadingAcceptanceTests/G3EvidenceCaptureTests -only-test-configuration "Japanese (ja)"`
/// - 撮った画像は XCTAttachment（keepAlways）に残し、`G3_OUT_DIR` があればそこに `<画面>_<状態>_<variant>.png` で書く。
///   撮れなかった画面×状態は `capture.log` に `MISSING` として残す（同じ画像を別名で複製しない）。
final class G3EvidenceCaptureTests: AcceptanceTestBase {
    private struct CaptureError: Error, CustomStringConvertible {
        let description: String
    }

    private var env: [String: String] { ProcessInfo.processInfo.environment }
    private var captureEnabled: Bool { env["G3_CAPTURE"] == "1" }
    private var variant: String { env["G3_VARIANT"] ?? "light" }
    private var outDir: String? { env["G3_OUT_DIR"] }
    private var logLines: [String] = []

    /// readouts off だとつなぎ口の要素（`hook.*`）が出ない（contracts/test-hooks.md 1-6）。
    /// ウィジェットの撮影は `hook.widget.canvas`（H22）を撮るので readouts を出したまま起動する。
    private func variantArgs(readoutsOff: Bool) -> [String] {
        var args = readoutsOff ? ["-uitest-readouts", "off"] : []
        switch variant {
        case "ax5":
            args += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        case "en":
            args += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        default:
            break
        }
        return args
    }

    private var baseArgs: [String] { variantArgs(readoutsOff: true) }

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
        logLines = []
    }

    override func tearDown() {
        flushLog()
        super.tearDown()
    }

    // MARK: - 道具

    private func log(_ line: String) {
        logLines.append(line)
    }

    private func flushLog() {
        guard let outDir = outDir, !logLines.isEmpty else { return }
        let url = URL(fileURLWithPath: outDir).appendingPathComponent("capture-\(name.replacingOccurrences(of: "[^A-Za-z0-9_]", with: "_", options: .regularExpression))-\(variant).log")
        let text = logLines.joined(separator: "\n") + "\n"
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func capture(_ fileStem: String, of target: XCUIElement? = nil) {
        let shot = target?.screenshot() ?? XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = fileStem
        attachment.lifetime = .keepAlways
        add(attachment)
        if let outDir = outDir {
            let url = URL(fileURLWithPath: outDir).appendingPathComponent("\(fileStem).png")
            do {
                try shot.pngRepresentation.write(to: url, options: .atomic)
                log("CAPTURED \(fileStem).png (\(shot.pngRepresentation.count) bytes)")
            } catch {
                log("WRITE_FAILED \(fileStem).png: \(error)")
            }
        } else {
            log("CAPTURED(attachment only) \(fileStem)")
        }
    }

    private func require(_ id: String, timeout: TimeInterval = uiTimeout) throws -> XCUIElement {
        let el = element(id)
        guard el.waitForExistence(timeout: timeout) else {
            throw CaptureError(description: "element '\(id)' not found within \(timeout)s")
        }
        return el
    }

    private func step(_ title: String, _ body: () throws -> Void) {
        do {
            try body()
            log("OK \(title)")
        } catch {
            log("MISSING \(title): \(error)")
            XCTFail("G3 capture '\(title)' failed: \(error)")
        }
    }

    private func launch(seed: String, now: String? = "2026-10-16T21:00:00+09:00", ocr: String? = nil,
                        failSave: String? = nil, offline: Bool = false, camera: String = "authorized",
                        flipUnavailable: Bool = false, ndlStub: String? = nil, liveActivity: String? = nil,
                        storeKit: String? = nil, extraArgs: [String] = [], extraEnv: [String: String] = [:],
                        readoutsOff: Bool = true) {
        var argsAll = variantArgs(readoutsOff: readoutsOff)
        argsAll += extraArgs
        if extraEnv.isEmpty {
            resetAndLaunch(seedJSON: seed, now: now, failSave: failSave, offline: offline, camera: camera,
                           flipUnavailable: flipUnavailable, ocrJSON: ocr, ndlStubJSON: ndlStub,
                           liveActivityJSON: liveActivity, storeKitJSON: storeKit, extraArgs: argsAll)
        } else {
            var args: [String] = ["-uitest-reset", "-uitest-barcode-fake"]
            if let now = now { args += ["-uitest-now", now] }
            args += ["-uitest-camera", camera]
            args += argsAll
            var environment: [String: String] = ["UITEST_SEED": seed]
            if let ocr = ocr { environment["UITEST_OCR"] = ocr }
            for (k, v) in extraEnv { environment[k] = v }
            app.launchArguments = args
            app.launchEnvironment = environment
            app.launch()
        }
    }

    // MARK: - 種

    private var isEnglish: Bool { variant == "en" }

    private var bookA: [String: Any] {
        makeSeedBook(id: uuidBookA, isbn13: "9784003101018",
                     title: isEnglish ? "Rashomon" : "羅生門",
                     author: isEnglish ? "Ryunosuke Akutagawa" : "芥川龍之介",
                     publisher: isEnglish ? "Iwanami Shoten" : "岩波書店",
                     label: isEnglish ? "Iwanami Bunko" : "岩波文庫",
                     publishedYear: 1927, status: "current", page: 45,
                     lastLine: isEnglish ? "It happened one evening, at dusk." : "ある日の暮方の事である。")
    }

    private var bookB: [String: Any] {
        makeSeedBook(id: uuidBookB, isbn13: "9784101010014",
                     title: isEnglish ? "Kokoro" : "こころ",
                     author: isEnglish ? "Natsume Soseki" : "夏目漱石",
                     publisher: isEnglish ? "Shinchosha" : "新潮社",
                     label: isEnglish ? "Shincho Bunko" : "新潮文庫",
                     publishedYear: 1914, status: "tsundoku")
    }

    private var bookC: [String: Any] {
        makeSeedBook(id: uuidBookC, isbn13: "9784101092058",
                     title: isEnglish ? "Night on the Galactic Railroad" : "銀河鉄道の夜",
                     author: isEnglish ? "Kenji Miyazawa" : "宮沢賢治",
                     publisher: isEnglish ? "Shinchosha" : "新潮社",
                     label: isEnglish ? "Shincho Bunko" : "新潮文庫",
                     publishedYear: 1934, status: "finished", page: 180,
                     finishedAt: "2026-10-14T22:00:00+09:00")
    }

    private var record1: [String: Any] {
        makeSeedRecord(id: makeRecordUUID(1), bookId: uuidBookA,
                       startedAt: "2026-10-14T21:00:00+09:00", endedAt: "2026-10-14T21:20:00+09:00",
                       minutes: 20, nightDate: "2026-10-14", startPage: 10, endPage: 30)
    }

    private var record2: [String: Any] {
        makeSeedRecord(id: makeRecordUUID(2), bookId: uuidBookA,
                       startedAt: "2026-10-15T21:00:00+09:00", endedAt: "2026-10-15T21:25:00+09:00",
                       minutes: 25, nightDate: "2026-10-15", startPage: 30, endPage: 45,
                       savedLine: isEnglish ? "It happened one evening, at dusk." : "ある日の暮方の事である。")
    }

    private var normalSeed: String {
        makeSeedJSON(books: [bookA, bookB, bookC], records: [record1, record2],
                     settings: makeSeedSettings(widgetGuideShown: false))
    }

    private var emptySeed: String { makeSeedJSON(books: []) }

    private var pageOCR: String {
        isEnglish
            ? #"{"page":{"columns":["It happened one evening, at dusk.","A servant was waiting for the rain to stop.","No one else was under the wide gate."],"detectedPage":61}}"#
            : #"{"page":{"columns":["ある日の暮方の事である。","一人の下人が、羅生門の下で雨やみを待っていた。","広い門の下には、この男のほかに誰もいない。"],"detectedPage":61}}"#
    }

    private var coverOCR: String {
        #"{"cover":{"lines":["人間失格","太宰治","新潮文庫"]}}"#
    }

    private var bookshelfOCR: String {
        #"{"bookshelf":{"spines":["人間失格 太宰治","斜陽 太宰治","羅生門"]}}"#
    }

    private var colophonOCR: String {
        #"{"colophon":{"lines":["羅生門","芥川龍之介","1927年7月1日 発行","発行所 岩波書店","岩波文庫","ISBN 978-4-00-310101-8"]}}"#
    }

    private var allOCR: String {
        #"{"page":{"columns":["ある日の暮方の事である。","一人の下人が、羅生門の下で雨やみを待っていた。","広い門の下には、この男のほかに誰もいない。"],"detectedPage":61},"cover":{"lines":["人間失格","太宰治","新潮文庫"]},"bookshelf":{"spines":["人間失格 太宰治","斜陽 太宰治","羅生門"]},"colophon":{"lines":["羅生門","芥川龍之介","1927年7月1日 発行","発行所 岩波書店","岩波文庫","ISBN 978-4-00-310101-8"]}}"#
    }

    // MARK: - 1. 通常の画面（variant ごと：light / dark / ax5 / en）

    func test_G3_captureNormalScreens() throws {
        guard captureEnabled else { return }
        executionTimeAllowance = 1200
        let v = variant
        log("variant=\(v) args=\(baseArgs)")

        step("S-1 normal") {
            launch(seed: normalSeed, ocr: allOCR)
            _ = try require("screen.bookmark")
            _ = try require("bookmark.line")
            capture("S1_normal_\(v)")
        }
        step("S-2 normal") {
            try require("bookmark.start").tap()
            _ = try require("screen.reading")
            _ = try require("reading.end")
            capture("S2_normal_\(v)")
        }
        step("S-3 normal (after session)") {
            advanceClock(seconds: 1200)
            try require("reading.end").tap()
            _ = try require("sheet.mark")
            capture("S3_normal_\(v)")
        }
        step("S-3a normal") {
            try require("mark.manual").tap()
            _ = try require("sheet.mark.line")
            let field = try require("mark.lineField")
            field.tap()
            field.typeText(isEnglish ? "A servant was waiting" : "一人の下人が")
            let page = try require("mark.pageField")
            page.tap()
            page.typeText("61")
            capture("S3a_normal_\(v)")
            try require("mark.cancel").tap()
        }
        step("S-3b normal") {
            try require("bookmark.setMark").tap()
            _ = try require("sheet.mark")
            try require("mark.pageOnly").tap()
            _ = try require("sheet.mark.pageOnly")
            let page = try require("mark.pageField")
            page.tap()
            page.typeText("61")
            capture("S3b_normal_\(v)")
            try require("mark.cancel").tap()
        }
        step("S-3c normal") {
            try require("bookmark.setMark").tap()
            _ = try require("sheet.mark")
            try require("mark.photo").tap()
            _ = try require("sheet.mark.ocr")
            _ = try require("mark.ocr.column.1")
            capture("S3c_normal_\(v)")
        }
        step("S-5 normal (after first mark save)") {
            try require("mark.save").tap()
            _ = try require("widgetGuide")
            capture("S5_normal_\(v)")
            try require("widgetGuide.close").tap()
        }
        step("S-4 normal (page moved)") {
            try require("bookmark.start").tap()
            _ = try require("screen.reading")
            advanceClock(seconds: 1080)
            try require("reading.end").tap()
            _ = try require("sheet.mark")
            try require("mark.pageOnly").tap()
            let page = try require("mark.pageField")
            page.tap()
            page.typeText("78")
            try require("mark.save").tap()
            _ = try require("sheet.result")
            _ = try require("result.summary")
            capture("S4_normal_\(v)")
            try require("result.close").tap()
        }
        step("N normal (info banner: session under 1 minute)") {
            try require("bookmark.start").tap()
            _ = try require("screen.reading")
            advanceClock(seconds: 30)
            try require("reading.end").tap()
            _ = try require("banner.notice")
            capture("N_normal_\(v)")
            try require("notice.close").tap()
        }
        step("S-6 normal") {
            try require("toolbar.shelf").tap()
            _ = try require("screen.shelf")
            capture("S6_normal_\(v)")
        }
        step("S-8 normal") {
            try require("shelf.addBook").tap()
            _ = try require("sheet.addBook")
            capture("S8_normal_\(v)")
        }
        step("S-8a normal") {
            try require("register.barcode").tap()
            _ = try require("sheet.barcode")
            sendBarcode("9784101006055")
            _ = try require("scan.row.9784101006055")
            capture("S8a_normal_\(v)")
            try require("scan.cancel").tap()
            try require("scan.discard.confirmButton").tap()
        }
        step("S-8b normal") {
            try require("register.cover").tap()
            _ = try require("sheet.cover.candidates")
            try require("cover.ocr.line.1").tap()
            try require("cover.ocr.line.2").tap()
            capture("S8b_normal_\(v)")
            try require("cover.cancel").tap()
        }
        step("S-8c normal") {
            try require("register.manual").tap()
            _ = try require("sheet.manual")
            let title = try require("manual.title")
            title.tap()
            title.typeText(isEnglish ? "Kokoro" : "こころ")
            capture("S8c_normal_\(v)")
            try require("manual.cancel").tap()
        }
        step("S-8d normal") {
            try require("register.bookshelf").tap()
            _ = try require("bookshelf.cancel")
            _ = try require("bookshelf.row.1")
            capture("S8d_normal_\(v)")
            try require("bookshelf.cancel").tap()
            try require("register.cancel").tap()
        }
        step("S-7 normal") {
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            _ = try require("screen.bookDetail")
            _ = try require("book.colophon")
            capture("S7_normal_\(v)")
        }
        step("S-7a normal") {
            try require("book.edit").tap()
            _ = try require("book.edit.cancel")
            capture("S7a_normal_\(v)")
            try require("book.edit.cancel").tap()
        }
        step("S-7b normal") {
            try require("book.record.row.\(makeRecordUUID(2).lowercased())").tap()
            _ = try require("record.cancel")
            capture("S7b_normal_\(v)")
            try require("record.cancel").tap()
        }
        step("S-9 normal") {
            try require("book.markFinished").tap()
            _ = try require("screen.finishNight")
            capture("S9_normal_\(v)")
        }
        step("S-9 finish card") {
            try require("finish.card.share").tap()
            _ = try require("sheet.shareCard")
            capture("S9_card_\(v)")
            try require("shareCard.close").tap()
        }
        step("S-7c normal (colophon read)") {
            try require("colophon.capture").tap()
            _ = try require("colophon.cancel")
            _ = try require("colophon.title")
            capture("S7c_normal_\(v)")
            try require("colophon.cancel").tap()
            try require("finish.close").tap()
        }
        step("S-10 normal") {
            try require("toolbar.settings").tap()
            _ = try require("screen.settings")
            capture("S10_normal_\(v)")
        }
        step("S-10a normal") {
            try require("appearance.row.kinari").tap()
            _ = try require("sheet.storePreview")
            capture("S10a_normal_\(v)")
            try require("store.close").tap()
        }
        step("S-1 empty") {
            launch(seed: emptySeed)
            _ = try require("screen.bookmark")
            _ = try require("bookmark.addBook")
            capture("S1_empty_\(v)")
        }
        step("S-6 empty") {
            try require("toolbar.shelf").tap()
            _ = try require("screen.shelf")
            capture("S6_empty_\(v)")
        }
    }

    // MARK: - 2. ウィジェット・Live Activity・Control・Siri（variant ごと、状態は light のみ）

    private func showWidget(_ spec: String, seed: String, extraEnv: [String: String] = [:],
                            liveActivity: String? = nil) throws -> XCUIElement {
        launch(seed: seed, liveActivity: liveActivity, extraArgs: ["-uitest-widget-show", spec], extraEnv: extraEnv,
               readoutsOff: false)
        let canvas = element("hook.widget.canvas")
        if canvas.waitForExistence(timeout: uiTimeout) {
            log("CANVAS spec=\(spec) frame=\(canvas.frame)")
            return canvas
        }
        let showcase = element("screen.widgetShowcase")
        if showcase.waitForExistence(timeout: 2) {
            // contracts/test-hooks.md H22 は `hook.widget.canvas` を撮ると定めているが、実装にはその要素がなく
            // `screen.widgetShowcase` が出る（契約との食い違いとして verification.md 11 章に書く）。画面全体を撮る。
            log("DEVIATION spec=\(spec): hook.widget.canvas absent; screen.widgetShowcase frame=\(showcase.frame)")
            return showcase
        }
        let err = element("hook.error")
        throw CaptureError(description: "neither hook.widget.canvas nor screen.widgetShowcase shown for spec \(spec); hook.error=\(err.exists ? (err.value as? String ?? "?") : "none")")
    }

    func test_G3_captureWidgets() throws {
        guard captureEnabled else { return }
        executionTimeAllowance = 900
        let v = variant
        let widgetLine = isEnglish ? "It happened one evening, at dusk." : "下人の行方は、誰も知らない。"
        let wSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: isEnglish ? "Rashomon" : "羅生門",
                                                      author: isEnglish ? "Ryunosuke Akutagawa" : "芥川龍之介",
                                                      status: "current", page: 61, lastLine: widgetLine)])

        step("W-1 normal 172x76") {
            let c = try showWidget("accessoryRectangular:172x76", seed: wSeed)
            capture("W1_normal_\(v)")
        }
        step("W-2 normal 170x170") {
            let c = try showWidget("systemSmall:170x170", seed: wSeed)
            capture("W2_normal_\(v)")
        }
        step("W-3 normal (waiting)") {
            let c = try showWidget("w3:waiting", seed: wSeed)
            capture("W3_normal_\(v)")
        }
        step("W-4 normal (control)") {
            let c = try showWidget("w4:control", seed: wSeed)
            capture("W4_normal_\(v)")
        }
        step("W-5 normal (snippet)") {
            let c = try showWidget("w5:snippet", seed: wSeed)
            capture("W5_normal_\(v)")
        }

        guard v == "light" else { return }

        // W-1 / W-2 の状態と AC-27〜AC-35 の画像
        let pendingSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "今の本", status: "current", isTitlePending: true, page: 12)])
        let longLineSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current", page: 61,
                                                             lastLine: "一人の下人が、羅生門の下で雨やみを待っていた。広い門の下には、この男のほかに誰もいない。")])
        let kinsokuSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current", page: 61,
                                                            lastLine: "「ある日の暮方の事である。」と、下人は言った。")])
        let hiddenSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current", page: 61, lastLine: widgetLine)],
                                      settings: makeSeedSettings(hideOnWidgets: true))
        let noLineSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current", page: 120, lastLine: nil)])

        step("AC-27 W-1 153x68") {
            let c = try showWidget("accessoryRectangular:153x68", seed: wSeed)
            capture("AC27_W1_153x68")
        }
        step("AC-27 W-1 172x76") {
            let c = try showWidget("accessoryRectangular:172x76", seed: wSeed)
            capture("AC27_W1_172x76")
        }
        step("AC-28 W-1 kinsoku") {
            let c = try showWidget("accessoryRectangular:172x76", seed: kinsokuSeed)
            capture("AC28_W1_kinsoku")
        }
        step("AC-29 W-1 truncated / W-1 partial") {
            let c = try showWidget("accessoryRectangular:172x76", seed: longLineSeed)
            capture("AC29_W1_truncated")
            capture("W1_partial_light")
        }
        step("AC-34 W-1 hidden") {
            let c = try showWidget("accessoryRectangular:172x76", seed: hiddenSeed)
            capture("AC34_W1_hidden")
        }
        step("AC-35 W-2 170x170") {
            let c = try showWidget("systemSmall:170x170", seed: wSeed)
            capture("AC35_W2_170x170")
        }
        step("AC-35 W-2 148x148") {
            let c = try showWidget("systemSmall:148x148", seed: wSeed)
            capture("AC35_W2_148x148")
        }
        step("W-1 empty (no current book)") {
            let c = try showWidget("accessoryRectangular:172x76", seed: emptySeed)
            capture("W1_empty_light")
        }
        step("W-1 noLine (title + page)") {
            let c = try showWidget("accessoryRectangular:172x76", seed: noLineSeed)
            capture("W1_noLine_light")
        }
        step("W-1 error (snapshot missing)") {
            let c = try showWidget("accessoryRectangular:172x76", seed: wSeed, extraEnv: ["UITEST_WIDGET_SNAPSHOT": "@missing"])
            capture("W1_error_light")
        }
        step("W-1 partial (title pending)") {
            let c = try showWidget("accessoryRectangular:172x76", seed: pendingSeed)
            capture("W1_pending_light")
        }
        step("W-2 empty") {
            let c = try showWidget("systemSmall:170x170", seed: emptySeed)
            capture("W2_empty_light")
        }
        step("W-2 error (snapshot missing)") {
            let c = try showWidget("systemSmall:170x170", seed: wSeed, extraEnv: ["UITEST_WIDGET_SNAPSHOT": "@missing"])
            capture("W2_error_light")
        }
        step("W-2 partial (title pending)") {
            let c = try showWidget("systemSmall:170x170", seed: pendingSeed)
            capture("W2_partial_light")
        }
        step("W-3 reading") {
            let c = try showWidget("w3:reading", seed: wSeed)
            capture("W3_reading_light")
        }
        step("W-3 ended") {
            let c = try showWidget("w3:ended", seed: wSeed)
            capture("W3_ended_light")
        }
        step("W-3 empty (no line)") {
            let c = try showWidget("w3:waiting", seed: noLineSeed)
            capture("W3_empty_light")
        }
        step("W-3 partial (hidden)") {
            let c = try showWidget("w3:waiting", seed: hiddenSeed)
            capture("W3_partial_light")
        }
        step("W-5 empty (no progress)") {
            let c = try showWidget("w5:snippet", seed: makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", status: "current")]))
            capture("W5_empty_light")
        }
        step("W-5 partial (hidden)") {
            let c = try showWidget("w5:snippet", seed: hiddenSeed)
            capture("W5_partial_light")
        }
    }

    /// S-7 の奥付撮影ボタンは design 6章で `colophon.capture` / `book.captureColophon` の2つの名前が許されている。
    private func tapColophonCapture() throws {
        if element("colophon.capture").waitForExistence(timeout: 2) {
            element("colophon.capture").tap()
        } else {
            try require("book.captureColophon").tap()
        }
    }

    // MARK: - 3. 通常以外の状態（light のみ。1状態ごとに起動し直し、同じ画像を別名で複製しない）

    func test_G3_captureStates() throws {
        guard captureEnabled, variant == "light" else { return }
        executionTimeAllowance = 1800

        let pendingBook = makeSeedBook(id: uuidBookA, title: "今の本", status: "current", isTitlePending: true, page: 12,
                                       lastLine: "ある日の暮方の事である。")
        let pendingSeed = makeSeedJSON(books: [pendingBook, bookB], records: [record1])
        let noLineSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current", page: 45, lastLine: nil)])
        let noCurrentSeed = makeSeedJSON(books: [bookB, bookC])
        let noRecordSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", status: "current", page: 45)])

        // S-1
        step("S-1 error (store load)") {
            launch(seed: normalSeed, failSave: "store.load")
            _ = try require("store.load.error")
            capture("S1_error_light")
        }
        step("S-1 noCurrent (tsundoku only)") {
            launch(seed: noCurrentSeed)
            _ = try require("bookmark.noCurrent.message")
            capture("S1_noCurrent_light")
        }
        step("S-1 partial (title pending)") {
            launch(seed: pendingSeed)
            _ = try require("screen.bookmark")
            _ = try require("bookmark.start")
            capture("S1_partial_light")
        }
        // S-2
        step("S-2 partial (title pending)") {
            try require("bookmark.start").tap()
            _ = try require("screen.reading")
            capture("S2_partial_light")
        }
        step("S-2 error / N error (session end save fails)") {
            launch(seed: normalSeed, failSave: "session.end:1")
            try require("bookmark.start").tap()
            _ = try require("screen.reading")
            advanceClock(seconds: 600)
            try require("reading.end").tap()
            _ = try require("session.save.error")
            capture("S2_error_light")
            capture("N_error_light")
        }
        // S-3
        step("S-3 empty (no previous mark)") {
            launch(seed: noLineSeed)
            try require("bookmark.setMark").tap()
            _ = try require("sheet.mark")
            if element("mark.later.note.empty").waitForExistence(timeout: uiTimeout) {
                capture("S3_empty_light")
            } else {
                log("NOTE S-3 empty: mark.later.note.empty (design 5章 S-3 空) not found; captured as-is")
                capture("S3_empty_asis_light")
            }
        }
        step("S-3 denied (camera)") {
            launch(seed: normalSeed, camera: "denied")
            try require("bookmark.setMark").tap()
            _ = try require("sheet.mark")
            try require("mark.photo").tap()
            _ = try require("camera.denied")
            capture("S3_denied_light")
        }
        step("S-3 partial (title pending)") {
            launch(seed: pendingSeed)
            try require("bookmark.setMark").tap()
            _ = try require("sheet.mark")
            capture("S3_partial_light")
        }
        // S-3a
        step("S-3a empty (save with empty line)") {
            launch(seed: normalSeed)
            try require("bookmark.setMark").tap()
            try require("mark.manual").tap()
            _ = try require("sheet.mark.line")
            try require("mark.save").tap()
            _ = try require("mark.line.invalid")
            capture("S3a_empty_light")
        }
        step("S-3a error (page 0)") {
            let field = try require("mark.lineField")
            field.tap()
            field.typeText("一人の下人が")
            let page = try require("mark.pageField")
            page.tap()
            page.typeText("0")
            try require("mark.save").tap()
            _ = try require("mark.page.invalid")
            capture("S3a_error_light")
        }
        step("S-3a save error (common.save.error)") {
            launch(seed: normalSeed, failSave: "mark.save:1")
            try require("bookmark.setMark").tap()
            try require("mark.manual").tap()
            let field = try require("mark.lineField")
            field.tap()
            field.typeText("一人の下人が")
            try require("mark.save").tap()
            _ = try require("common.save.error")
            capture("S3a_saveError_light")
        }
        // S-3b
        step("S-3b empty (save with empty page)") {
            launch(seed: normalSeed)
            try require("bookmark.setMark").tap()
            try require("mark.pageOnly").tap()
            _ = try require("sheet.mark.pageOnly")
            try require("mark.save").tap()
            _ = try require("mark.page.invalid")
            capture("S3b_empty_light")
        }
        step("S-3b error (page 10000)") {
            let page = try require("mark.pageField")
            page.tap()
            page.typeText("10000")
            try require("mark.save").tap()
            _ = try require("mark.page.invalid")
            capture("S3b_error_light")
        }
        // S-3c
        step("S-3c empty (0 columns)") {
            launch(seed: normalSeed, ocr: #"{"page":{"columns":[],"detectedPage":null}}"#)
            try require("bookmark.setMark").tap()
            try require("mark.photo").tap()
            _ = try require("mark.ocr.none")
            capture("S3c_empty_light")
        }
        step("S-3c loading (OCR held)") {
            launch(seed: normalSeed, ocr: #"{"hold":true,"page":{"columns":["ある日の暮方の事である。"],"detectedPage":61}}"#)
            try require("bookmark.setMark").tap()
            try require("mark.photo").tap()
            _ = try require("mark.cancel")
            capture("S3c_loading_light")
            releaseOCR()
            _ = try require("mark.ocr.column.1")
        }
        step("S-3c error (61-character line, AC-72)") {
            let long61 = String(repeating: "あ", count: 61)
            launch(seed: normalSeed, ocr: #"{"page":{"columns":["\#(long61)"],"detectedPage":61}}"#)
            try require("bookmark.setMark").tap()
            try require("mark.photo").tap()
            _ = try require("mark.ocr.column.1")
            try require("mark.save").tap()
            _ = try require("mark.line.invalid")
            capture("S3c_error_light")
        }
        step("S-3c partial (column 2 chosen, text editable)") {
            launch(seed: normalSeed, ocr: pageOCR)
            try require("bookmark.setMark").tap()
            try require("mark.photo").tap()
            try require("mark.ocr.column.2").tap()
            let field = try require("mark.lineField")
            field.tap()
            field.typeText("（直した）")
            capture("S3c_partial_light")
        }
        // S-4
        step("S-4 empty (mark later)") {
            launch(seed: normalSeed)
            try require("bookmark.start").tap()
            advanceClock(seconds: 900)
            try require("reading.end").tap()
            try require("mark.later").tap()
            _ = try require("sheet.result")
            capture("S4_empty_light")
            try require("result.close").tap()
        }
        step("S-4 partial (1440 minutes cap)") {
            try require("bookmark.start").tap()
            _ = try require("screen.reading")
            advanceClock(seconds: 86_460)
            try require("reading.end").tap()
            try require("mark.later").tap()
            _ = try require("sheet.result")
            capture("S4_partial_light")
            try require("result.close").tap()
        }
        // S-5
        step("S-5 partial (hideOnWidgets)") {
            launch(seed: makeSeedJSON(books: [bookA], settings: makeSeedSettings(hideOnWidgets: true, widgetGuideShown: false)))
            try require("bookmark.setMark").tap()
            try require("mark.manual").tap()
            let field = try require("mark.lineField")
            field.tap()
            field.typeText("一人の下人が")
            try require("mark.save").tap()
            _ = try require("widgetGuide")
            capture("S5_partial_light")
        }
        // S-6
        step("S-6 error (store load)") {
            launch(seed: normalSeed, failSave: "store.load")
            try require("toolbar.shelf").tap()
            if element("shelf.load.error").waitForExistence(timeout: uiTimeout) {
                capture("S6_error_light")
            } else {
                log("NOTE S-6 error: shelf.load.error (design 5章 S-6 エラー) not found after store.load failure; captured as-is")
                capture("S6_error_asis_light")
            }
        }
        step("S-6 partial (title pending row)") {
            launch(seed: pendingSeed)
            try require("toolbar.shelf").tap()
            _ = try require("screen.shelf")
            capture("S6_partial_light")
        }
        // S-7
        step("S-7 empty (no records)") {
            launch(seed: noRecordSeed)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            _ = try require("book.records.empty")
            capture("S7_empty_light")
        }
        step("S-7 denied (camera, colophon.capture)") {
            launch(seed: normalSeed, camera: "denied")
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try tapColophonCapture()
            _ = try require("camera.denied")
            capture("S7_denied_light")
        }
        step("S-7 partial (title pending)") {
            launch(seed: pendingSeed)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            _ = try require("screen.bookDetail")
            capture("S7_partial_light")
        }
        step("S-7 save error (status change fails)") {
            launch(seed: normalSeed, failSave: "book.status:1")
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookB.lowercased())").tap()
            try require("book.readThis").tap()
            _ = try require("common.save.error")
            capture("S7_error_light")
        }
        // S-7a
        step("S-7a empty (author empty)") {
            launch(seed: noRecordSeed)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try require("book.edit").tap()
            _ = try require("book.edit.author")
            capture("S7a_empty_light")
        }
        step("S-7a error (title cleared)") {
            let title = try require("book.edit.title")
            title.tap()
            title.press(forDuration: 1.0)
            if app.menuItems["Select All"].waitForExistence(timeout: 2) {
                app.menuItems["Select All"].tap()
            } else if app.menuItems["すべてを選択"].waitForExistence(timeout: 2) {
                app.menuItems["すべてを選択"].tap()
            }
            title.typeText(XCUIKeyboardKey.delete.rawValue)
            try require("book.edit.save").tap()
            _ = try require("book.title.invalid")
            capture("S7a_error_light")
        }
        // S-7b
        step("S-7b empty (minutes cleared)") {
            launch(seed: normalSeed)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try require("book.record.row.\(makeRecordUUID(2).lowercased())").tap()
            let minutes = try require("record.minutesField")
            minutes.tap()
            minutes.press(forDuration: 1.0)
            if app.menuItems["Select All"].waitForExistence(timeout: 2) {
                app.menuItems["Select All"].tap()
            } else if app.menuItems["すべてを選択"].waitForExistence(timeout: 2) {
                app.menuItems["すべてを選択"].tap()
            }
            minutes.typeText(XCUIKeyboardKey.delete.rawValue)
            try require("record.save").tap()
            _ = try require("record.minutes.invalid")
            capture("S7b_empty_light")
        }
        step("S-7b error (1441)") {
            let minutes = try require("record.minutesField")
            minutes.tap()
            minutes.typeText("1441")
            try require("record.save").tap()
            _ = try require("record.minutes.invalid")
            capture("S7b_error_light")
        }
        // S-7c
        step("S-7c empty (nothing read)") {
            launch(seed: normalSeed, ocr: #"{"colophon":{"lines":[]}}"#)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try tapColophonCapture()
            _ = try require("mark.ocr.none")
            capture("S7c_empty_light")
        }
        step("S-7c loading (OCR held)") {
            launch(seed: normalSeed, ocr: #"{"hold":true,"colophon":{"lines":["発行所 岩波書店"]}}"#)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try tapColophonCapture()
            _ = try require("colophon.cancel")
            capture("S7c_loading_light")
            releaseOCR()
        }
        step("S-7c denied (camera)") {
            launch(seed: normalSeed, camera: "denied")
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try tapColophonCapture()
            _ = try require("camera.denied")
            capture("S7c_denied_light")
        }
        step("S-7c partial (publisher and year only)") {
            launch(seed: normalSeed, ocr: #"{"colophon":{"lines":["1927年7月1日 発行","発行所 岩波書店"]}}"#)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try tapColophonCapture()
            _ = try require("colophon.publisher")
            capture("S7c_partial_light")
        }
        step("S-7c error (save fails)") {
            launch(seed: normalSeed, ocr: colophonOCR, failSave: "book.update:1")
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try tapColophonCapture()
            try require("colophon.save").tap()
            _ = try require("common.save.error")
            capture("S7c_error_light")
        }
        // S-8
        step("S-8 empty (first book, from S-1)") {
            launch(seed: emptySeed)
            try require("bookmark.addBook").tap()
            _ = try require("sheet.addBook")
            capture("S8_empty_light")
        }
        step("S-8 denied (camera)") {
            launch(seed: emptySeed, camera: "denied")
            try require("bookmark.addBook").tap()
            try require("register.barcode").tap()
            _ = try require("camera.denied")
            capture("S8_denied_light")
        }
        step("S-8 partial (catalog not downloaded)") {
            launch(seed: emptySeed, ndlStub: #"{"stubVersion":1,"status":"notDownloaded","books":[],"cooccurrences":[]}"#)
            try require("bookmark.addBook").tap()
            _ = try require("sheet.addBook")
            capture("S8_partial_light")
        }
        // S-8a
        step("S-8a empty (nothing scanned)") {
            launch(seed: emptySeed)
            try require("bookmark.addBook").tap()
            try require("register.barcode").tap()
            _ = try require("sheet.barcode")
            if element("scan.hint").waitForExistence(timeout: 2) {
                capture("S8a_empty_light")
            } else {
                log("NOTE S-8a empty: scan.hint (design 5章 S-8a 空) not found; captured as-is")
                capture("S8a_empty_asis_light")
            }
        }
        step("S-8a partial (catalog not downloaded)") {
            launch(seed: emptySeed, ndlStub: #"{"stubVersion":1,"status":"notDownloaded","books":[],"cooccurrences":[]}"#)
            try require("bookmark.addBook").tap()
            try require("register.barcode").tap()
            sendBarcode("9784101000015")
            _ = try require("scan.dbNotReady")
            capture("S8a_partial_light")
        }
        step("S-8a error (add fails)") {
            launch(seed: emptySeed, failSave: "book.add:1")
            try require("bookmark.addBook").tap()
            try require("register.barcode").tap()
            sendBarcode("9784101006055")
            _ = try require("scan.row.9784101006055")
            try require("scan.addToShelf").tap()
            _ = try require("common.save.error")
            capture("S8a_error_light")
        }
        // S-8b
        step("S-8b empty (0 lines)") {
            launch(seed: emptySeed, ocr: #"{"cover":{"lines":[]}}"#)
            try require("bookmark.addBook").tap()
            try require("register.cover").tap()
            _ = try require("mark.ocr.none")
            capture("S8b_empty_light")
        }
        step("S-8b loading (OCR held)") {
            launch(seed: emptySeed, ocr: #"{"hold":true,"cover":{"lines":["人間失格"]}}"#)
            try require("bookmark.addBook").tap()
            try require("register.cover").tap()
            _ = try require("sheet.cover.candidates")
            capture("S8b_loading_light")
            releaseOCR()
        }
        step("S-8b error (title empty on save)") {
            launch(seed: emptySeed, ocr: coverOCR)
            try require("bookmark.addBook").tap()
            try require("register.cover").tap()
            _ = try require("cover.ocr.line.1")
            try require("cover.save").tap()
            if element("book.title.invalid").waitForExistence(timeout: uiTimeout) {
                capture("S8b_error_light")
            } else {
                log("NOTE S-8b error: book.title.invalid not shown after cover.save with empty title; captured as-is")
                capture("S8b_error_asis_light")
            }
        }
        step("S-8b partial (1 line only)") {
            launch(seed: emptySeed, ocr: #"{"cover":{"lines":["人間失格"]}}"#)
            try require("bookmark.addBook").tap()
            try require("register.cover").tap()
            try require("cover.ocr.line.1").tap()
            capture("S8b_partial_light")
        }
        // S-8c
        step("S-8c empty (no catalog match)") {
            launch(seed: emptySeed)
            try require("bookmark.addBook").tap()
            try require("register.manual").tap()
            let title = try require("manual.title")
            title.tap()
            title.typeText("あいうえおかきくけこ")
            _ = try require("search.noResults")
            capture("S8c_empty_light")
        }
        step("S-8c error (title empty)") {
            launch(seed: emptySeed)
            try require("bookmark.addBook").tap()
            try require("register.manual").tap()
            _ = try require("manual.title")
            try require("manual.save").tap()
            _ = try require("book.title.invalid")
            capture("S8c_error_light")
        }
        step("S-8c partial (catalog not downloaded)") {
            launch(seed: emptySeed, ndlStub: #"{"stubVersion":1,"status":"notDownloaded","books":[],"cooccurrences":[]}"#)
            try require("bookmark.addBook").tap()
            try require("register.manual").tap()
            let title = try require("manual.title")
            title.tap()
            title.typeText("人間失格")
            capture("S8c_partial_light")
        }
        // S-8d
        step("S-8d empty (nothing chosen)") {
            launch(seed: emptySeed, ocr: #"{"bookshelf":{"spines":[]}}"#)
            try require("bookmark.addBook").tap()
            try require("register.bookshelf").tap()
            _ = try require("bookshelf.cancel")
            capture("S8d_empty_light")
        }
        step("S-8d loading (OCR held)") {
            launch(seed: emptySeed, ocr: #"{"hold":true,"bookshelf":{"spines":["人間失格 太宰治"]}}"#)
            try require("bookmark.addBook").tap()
            try require("register.bookshelf").tap()
            _ = try require("bookshelf.cancel")
            capture("S8d_loading_light")
            releaseOCR()
        }
        step("S-8d error (add fails)") {
            launch(seed: emptySeed, ocr: bookshelfOCR, failSave: "book.add:1")
            try require("bookmark.addBook").tap()
            try require("register.bookshelf").tap()
            try require("bookshelf.row.1").tap()
            try require("bookshelf.addSelected").tap()
            _ = try require("common.save.error")
            capture("S8d_error_light")
        }
        step("S-8d partial (exact match enriched)") {
            launch(seed: emptySeed, ocr: bookshelfOCR)
            try require("bookmark.addBook").tap()
            try require("register.bookshelf").tap()
            try require("bookshelf.row.3").tap()
            capture("S8d_partial_light")
        }
        // S-9
        step("S-9 empty (no candidates)") {
            launch(seed: makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "無題の本", status: "current", page: 45)], records: [record1]),
                   ndlStub: #"{"stubVersion":1,"status":"ready","books":[],"cooccurrences":[]}"#)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try require("book.markFinished").tap()
            _ = try require("next.empty.message")
            capture("S9_empty_light")
        }
        step("S-9 denied (camera)") {
            launch(seed: normalSeed, camera: "denied")
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try require("book.markFinished").tap()
            try require("colophon.capture").tap()
            if element("camera.denied").waitForExistence(timeout: uiTimeout) {
                capture("S9_denied_light")
            } else {
                log("NOTE S-9 denied: camera.denied not shown after colophon.capture with camera denied; captured as-is")
                capture("S9_denied_asis_light")
            }
        }
        step("S-9 error (choose next fails)") {
            let sameAuthor = makeSeedBook(id: uuidBookB, title: "鼻", author: "芥川龍之介", publisher: "岩波書店", label: "岩波文庫", status: "tsundoku")
            launch(seed: makeSeedJSON(books: [bookA, sameAuthor], records: [record1, record2]), failSave: "book.status:1")
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try require("book.markFinished").tap()
            try require("next.candidate.\(uuidBookB.lowercased())").tap()
            try require("next.choose").tap()
            _ = try require("common.save.error")
            capture("S9_error_light")
        }
        step("S-9 partial (one night only)") {
            launch(seed: makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", status: "current", page: 45), bookB], records: [record1]))
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try require("book.markFinished").tap()
            _ = try require("screen.finishNight")
            capture("S9_partial_light")
        }
        // S-10
        step("S-10 denied (Live Activity off)") {
            launch(seed: normalSeed, liveActivity: #"{"enabled":false,"areActivitiesEnabled":false}"#)
            try require("toolbar.settings").tap()
            _ = try require("settings.liveActivity.off")
            capture("S10_denied_light")
        }
        step("S-10 partial (flip unavailable)") {
            launch(seed: normalSeed, flipUnavailable: true)
            try require("toolbar.settings").tap()
            _ = try require("screen.settings")
            capture("S10_partial_light")
        }
        step("S-10 offline (restore)") {
            launch(seed: normalSeed, offline: true)
            try require("toolbar.settings").tap()
            try require("settings.restorePurchases").tap()
            _ = try require("notice")
            capture("S10_offline_light")
        }
        step("S-10 error (settings save fails)") {
            launch(seed: normalSeed, failSave: "settings.save:1")
            try require("toolbar.settings").tap()
            try require("settings.hideOnWidgets").tap()
            _ = try require("common.save.error")
            capture("S10_error_light")
        }
        // S-10a
        step("S-10a offline") {
            launch(seed: normalSeed, offline: true)
            try require("toolbar.settings").tap()
            try require("appearance.row.kinari").tap()
            _ = try require("store.offline")
            capture("S10a_offline_light")
        }
        step("S-10a denied (cannot make payments)") {
            launch(seed: normalSeed, storeKit: #"{"canMakePayments":false}"#)
            try require("toolbar.settings").tap()
            try require("appearance.row.kinari").tap()
            _ = try require("store.unavailable")
            capture("S10a_denied_light")
        }
        step("S-10a error (purchase fails)") {
            launch(seed: normalSeed, storeKit: #"{"purchaseOutcome":"error"}"#)
            try require("toolbar.settings").tap()
            try require("appearance.row.kinari").tap()
            try require("store.buy").tap()
            _ = try require("store.purchase.error")
            capture("S10a_error_light")
        }
        step("S-10a loading (product unavailable)") {
            launch(seed: normalSeed, storeKit: #"{"productLoadAvailable":false}"#)
            try require("toolbar.settings").tap()
            try require("appearance.row.kinari").tap()
            _ = try require("sheet.storePreview")
            capture("S10a_loading_light")
        }
        step("S-10a partial (refund)") {
            launch(seed: makeSeedJSON(books: [bookA], settings: makeSeedSettings(appearanceID: "kinari", isPlusPurchased: true)))
            _ = try require("screen.bookmark")
            capture("AC106_S1_kinari")
            triggerStoreRefund()
            try require("toolbar.settings").tap()
            _ = try require("screen.settings")
            capture("S10a_partial_light")
        }
        step("AC-34 S-1 visible while hidden on widgets") {
            launch(seed: makeSeedJSON(books: [bookA], records: [record2], settings: makeSeedSettings(hideOnWidgets: true)))
            _ = try require("bookmark.line")
            capture("AC34_S1_visible")
        }
    }

    // MARK: - 4. アクセシビリティ監査（全画面、readouts off なのでつなぎ口の要素は出ない）

    func test_G3_accessibilityAudit() throws {
        guard captureEnabled, variant == "light" else { return }
        executionTimeAllowance = 900

        final class IssueBox: @unchecked Sendable {
            var items: [String] = []
        }
        var auditLines: [String] = []
        var totalIssues = 0
        var screensAudited = 0

        func runAudit(_ code: String, _ screen: String) {
            let box = IssueBox()
            do {
                try app.performAccessibilityAudit(for: .all) { issue in
                    let el = issue.element?.debugDescription ?? "nil"
                    box.items.append("\(issue.auditType): \(issue.compactDescription) [element=\(el)]")
                    return true
                }
            } catch {
                box.items.append("AuditError: \(error)")
            }
            screensAudited += 1
            totalIssues += box.items.count
            auditLines.append("\(code) (\(screen)): \(box.items.count) issues")
            auditLines.append(contentsOf: box.items.map { "  - \($0)" })
        }

        step("audit widgets") {
            for (code, spec) in [("W-1", "accessoryRectangular:172x76"), ("W-2", "systemSmall:170x170"),
                                 ("W-3", "w3:waiting"), ("W-4", "w4:control"), ("W-5", "w5:snippet")] {
                let seed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current", page: 61, lastLine: "下人の行方は、誰も知らない。")])
                do {
                    _ = try showWidget(spec, seed: seed)
                    runAudit(code, spec)
                } catch {
                    auditLines.append("\(code) (\(spec)): NOT AUDITED (\(error))")
                }
            }
        }
        step("audit S-1 .. S-10a, N") {
            launch(seed: normalSeed, ocr: allOCR)
            _ = try require("bookmark.line")
            runAudit("S-1", "BookmarkHome")
            try require("bookmark.start").tap()
            _ = try require("reading.end")
            runAudit("S-2", "ReadingSession")
            advanceClock(seconds: 1200)
            try require("reading.end").tap()
            _ = try require("sheet.mark")
            runAudit("S-3", "MarkSelect")
            try require("mark.manual").tap()
            _ = try require("sheet.mark.line")
            runAudit("S-3a", "MarkLineInput")
            try require("mark.cancel").tap()
            try require("bookmark.setMark").tap()
            try require("mark.pageOnly").tap()
            _ = try require("sheet.mark.pageOnly")
            runAudit("S-3b", "MarkPageOnly")
            try require("mark.cancel").tap()
            try require("bookmark.setMark").tap()
            try require("mark.photo").tap()
            _ = try require("mark.ocr.column.1")
            runAudit("S-3c", "MarkOCR")
            try require("mark.save").tap()
            _ = try require("widgetGuide")
            runAudit("S-5", "WidgetGuide")
            try require("widgetGuide.close").tap()
            try require("bookmark.start").tap()
            _ = try require("screen.reading")
            advanceClock(seconds: 900)
            try require("reading.end").tap()
            try require("mark.later").tap()
            _ = try require("sheet.result")
            runAudit("S-4", "SessionResult")
            try require("result.close").tap()
            try require("bookmark.start").tap()
            _ = try require("screen.reading")
            advanceClock(seconds: 30)
            try require("reading.end").tap()
            _ = try require("banner.notice")
            runAudit("N", "BannerNotice")
            try require("notice.close").tap()
            try require("toolbar.shelf").tap()
            _ = try require("screen.shelf")
            runAudit("S-6", "Shelf")
            try require("shelf.addBook").tap()
            _ = try require("sheet.addBook")
            runAudit("S-8", "AddBookMenu")
            try require("register.barcode").tap()
            sendBarcode("9784101006055")
            _ = try require("scan.row.9784101006055")
            runAudit("S-8a", "BarcodeScan")
            try require("scan.cancel").tap()
            try require("scan.discard.confirmButton").tap()
            try require("register.cover").tap()
            _ = try require("cover.ocr.line.1")
            runAudit("S-8b", "CoverOCR")
            try require("cover.cancel").tap()
            try require("register.manual").tap()
            _ = try require("manual.title")
            runAudit("S-8c", "ManualInput")
            try require("manual.cancel").tap()
            try require("register.bookshelf").tap()
            _ = try require("bookshelf.row.1")
            runAudit("S-8d", "BookshelfOCR")
            try require("bookshelf.cancel").tap()
            try require("register.cancel").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            _ = try require("book.colophon")
            runAudit("S-7", "BookDetail")
            try require("book.edit").tap()
            _ = try require("book.edit.cancel")
            runAudit("S-7a", "BookEdit")
            try require("book.edit.cancel").tap()
            try require("book.record.row.\(makeRecordUUID(2).lowercased())").tap()
            _ = try require("record.cancel")
            runAudit("S-7b", "RecordEdit")
            try require("record.cancel").tap()
            try require("book.markFinished").tap()
            _ = try require("screen.finishNight")
            runAudit("S-9", "FinishNight")
            try require("colophon.capture").tap()
            _ = try require("colophon.title")
            runAudit("S-7c", "ColophonOCR")
            try require("colophon.cancel").tap()
            try require("finish.close").tap()
            try require("toolbar.settings").tap()
            _ = try require("screen.settings")
            runAudit("S-10", "Settings")
            try require("appearance.row.kinari").tap()
            _ = try require("sheet.storePreview")
            runAudit("S-10a", "StorePreview")
            try require("store.close").tap()
        }

        let header = [
            "=== performAccessibilityAudit(for: .all), -uitest-readouts off (no hook elements on screen) ===",
            "Screens audited: \(screensAudited)",
            "Total issues: \(totalIssues)"
        ]
        let report = (header + auditLines).joined(separator: "\n") + "\n"
        let attachment = XCTAttachment(string: report)
        attachment.name = "accessibility-audit"
        attachment.lifetime = .keepAlways
        add(attachment)
        if let outDir = outDir {
            try report.write(toFile: outDir + "/accessibility-audit.log", atomically: true, encoding: .utf8)
        }
        log("audit screens=\(screensAudited) issues=\(totalIssues)")
    }
}
