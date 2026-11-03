import XCTest
import notify

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

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = true
        logLines = []
    }

    override func tearDown() async throws {
        flushLog()
        try await super.tearDown()
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

    /// どの variant でも日本語の本のデータを使う（英語の端末で和文が□にならないことを目で確かめるため。r2i の未解決5）。
    private var bookA: [String: Any] {
        makeSeedBook(id: uuidBookA, isbn13: "9784003101018",
                     title: "羅生門", author: "芥川龍之介", publisher: "岩波書店", label: "岩波文庫",
                     publishedYear: 1927, status: "current", page: 45,
                     lastLine: "ある日の暮方の事である。")
    }

    private var bookB: [String: Any] {
        makeSeedBook(id: uuidBookB, isbn13: "9784101010014",
                     title: "こころ", author: "夏目漱石", publisher: "新潮社", label: "新潮文庫",
                     publishedYear: 1914, status: "tsundoku")
    }

    private var bookC: [String: Any] {
        makeSeedBook(id: uuidBookC, isbn13: "9784101092058",
                     title: "銀河鉄道の夜", author: "宮沢賢治", publisher: "新潮社", label: "新潮文庫",
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
                       savedLine: "ある日の暮方の事である。")
    }

    private var normalSeed: String {
        makeSeedJSON(books: [bookA, bookB, bookC], records: [record1, record2],
                     settings: makeSeedSettings(widgetGuideShown: false))
    }

    private var emptySeed: String { makeSeedJSON(books: []) }

    private var pageOCR: String {
        #"{"page":{"columns":["ある日の暮方の事である。","一人の下人が、羅生門の下で雨やみを待っていた。","広い門の下には、この男のほかに誰もいない。"],"detectedPage":61}}"#
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
            field.typeText("一人の下人が")
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
            title.typeText("こころ")
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
            // design/ 5 の S-7a：今の本の値をそのまま欄に出す。欄の value（入っている字）と placeholderValue を記録する（指揮役の 10）。
            for id in ["book.edit.title", "book.edit.author"] {
                let field = element(id)
                log("FIELD \(id) exists=\(field.exists) value=\(field.value.map { "\($0)" } ?? "nil") placeholder=\(field.placeholderValue ?? "nil") label=\(field.label)")
            }
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
            // 「3晩・83分」が見出しと文に二度出ていないかを記録する（指揮役の 10）。
            for id in ["finish.summary", "finish.reflection"] {
                let el = element(id)
                log("TEXT \(id) exists=\(el.exists) label=\(el.exists ? el.label : "-") value=\(el.exists ? (el.value.map { "\($0)" } ?? "nil") : "-")")
            }
            let nightTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }.filter { $0.contains("晩") || $0.lowercased().contains("night") }
            log("NIGHT_TEXTS count=\(nightTexts.count) \(nightTexts)")
            capture("S9_normal_\(v)")
        }
        step("S-9 finish card") {
            try require("finish.card.share").tap()
            _ = try require("sheet.shareCard")
            capture("S9_card_\(v)")
            try require("finish.card.close").tap()
        }
        step("S-7c normal (colophon read)") {
            try require("colophon.capture").tap()
            _ = try require("colophon.cancel")
            _ = try require("colophon.ocr.publisher")
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

    /// `-uitest-widget-show <面>:<幅>x<高さ>[:<種類>]`（contracts/test-hooks.md H22 の撮影用の見本）で起動し、`hook.widget.canvas` を返す。
    /// 契約の確かめ方どおり、`canvas.frame.size` が頼んだ幅×高さ（固定の面）か幅×`showcase.canvasHeight`（中身に合わせる面）と
    /// 0.5 pt 以内で同じことを確かめ、`showcase` と `renders` の `composition` を log に残す。
    @discardableResult
    private func showWidget(_ spec: String, seed: String, extraEnv: [String: String] = [:],
                            liveActivity: String? = nil) throws -> XCUIElement {
        var widgetArgs = ["-uitest-widget-show", spec]
        let parts0 = spec.split(separator: ":").map(String.init)
        if parts0.count >= 2, ["accessoryRectangular", "systemSmall"].contains(parts0[0]) {
            // 同じ起動で同じ面と大きさを -uitest-widget にも渡し、renders[].composition と画像を同じ枠で比べる（契約 H22 の確かめ方）
            widgetArgs += ["-uitest-widget", "\(parts0[0]):\(parts0[1])"]
        }
        launch(seed: seed, liveActivity: liveActivity, extraArgs: widgetArgs, extraEnv: extraEnv,
               readoutsOff: false)
        let canvas = element("hook.widget.canvas")
        guard canvas.waitForExistence(timeout: uiTimeout) else {
            let err = element("hook.error")
            throw CaptureError(description: "hook.widget.canvas not shown for spec \(spec); hook.error=\(err.exists ? (err.value as? String ?? "?") : "none")")
        }
        let parts = spec.split(separator: ":").map(String.init)
        let size = parts.count >= 2 ? parts[1].split(separator: "x").compactMap { Double($0) } : []
        let widget = readHookJSON("hook.widget")
        let showcase = widget["showcase"] as? [String: Any] ?? [:]
        let canvasHeight = showcase["canvasHeight"] as? Double ?? -1
        let overflow = showcase["contentOverflow"] as? Bool
        let frame = canvas.frame
        log("CANVAS spec=\(spec) frame=\(frame) showcase=\(showcase)")
        if size.count == 2 {
            let surface = parts[0]
            let fixedHeight = ["accessoryRectangular", "systemSmall", "control"].contains(surface)
            let expectedHeight = fixedHeight ? size[1] : canvasHeight
            XCTAssertEqual(frame.width, size[0], accuracy: 0.5, "spec=\(spec) canvas width")
            XCTAssertEqual(frame.height, expectedHeight, accuracy: 0.5, "spec=\(spec) canvas height (showcase.canvasHeight=\(canvasHeight))")
            if !fixedHeight {
                XCTAssertLessThanOrEqual(canvasHeight, size[1] + 0.5, "spec=\(spec) canvasHeight ≤ requested")
            }
        }
        if let renders = widget["renders"] as? [[String: Any]] {
            for render in renders {
                let request = render["request"] as? [String: Any] ?? [:]
                let comp = render["composition"] as? [String: Any] ?? [:]
                log("RENDER spec=\(spec) request=\(request) state=\(render["state"] ?? "?") fontSize=\(comp["fontSize"] ?? "-") L=\(comp["L"] ?? "-") columnCount=\(comp["columnCount"] ?? "-") displayedLine=\(comp["displayedLine"] ?? "-") contentOverflow=\(overflow.map { "\($0)" } ?? "-")")
            }
        }
        return canvas
    }

    /// `hook.widget` の値（JSON の文字列）をそのまま `<outDir>/h22/<name>.json` に保存する（contracts/test-hooks.md 7 の全体のスキーマ検査に使う）。
    private func saveHookWidgetJSON(_ name: String) {
        let raw = readHookString("hook.widget")
        let attachment = XCTAttachment(string: raw)
        attachment.name = "hook.widget-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        guard let outDir = outDir else {
            log("H22JSON(attachment only) \(name) bytes=\(raw.utf8.count)")
            return
        }
        let dir = URL(fileURLWithPath: outDir).appendingPathComponent("h22")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(name).json")
        do {
            try raw.write(to: url, atomically: true, encoding: .utf8)
            log("H22JSON \(name).json bytes=\(raw.utf8.count)")
        } catch {
            log("H22JSON_WRITE_FAILED \(name).json: \(error)")
        }
    }

    func test_G3_captureWidgets() throws {
        guard captureEnabled else { return }
        executionTimeAllowance = 900
        let v = variant
        let widgetLine = "下人の行方は、誰も知らない。"
        let wSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介",
                                                      status: "current", page: 61, lastLine: widgetLine)])

        step("W-1 normal 172x76") {
            try showWidget("accessoryRectangular:172x76", seed: wSeed)
            capture("W1_normal_\(v)")
        }
        step("W-2 normal 170x170") {
            try showWidget("systemSmall:170x170", seed: wSeed)
            capture("W2_normal_\(v)")
        }
        step("W-3 normal (waiting)") {
            try showWidget("liveActivity:370x160:waiting", seed: wSeed)
            capture("W3_normal_\(v)")
        }
        step("W-4 normal (control)") {
            try showWidget("control:160x72", seed: wSeed)
            capture("W4_normal_\(v)")
        }
        step("W-5 normal (snippet)") {
            try showWidget("snippet:360x200", seed: wSeed)
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
            try showWidget("accessoryRectangular:153x68", seed: wSeed)
            capture("AC27_W1_153x68")
        }
        step("AC-27 W-1 172x76") {
            try showWidget("accessoryRectangular:172x76", seed: wSeed)
            capture("AC27_W1_172x76")
        }
        step("AC-28 W-1 kinsoku") {
            try showWidget("accessoryRectangular:172x76", seed: kinsokuSeed)
            capture("AC28_W1_kinsoku")
        }
        step("AC-29 W-1 truncated / W-1 partial") {
            try showWidget("accessoryRectangular:172x76", seed: longLineSeed)
            capture("AC29_W1_truncated")
            capture("W1_partial_light")
        }
        step("AC-34 W-1 hidden") {
            try showWidget("accessoryRectangular:172x76", seed: hiddenSeed)
            capture("AC34_W1_hidden")
        }
        step("AC-35 W-2 170x170") {
            try showWidget("systemSmall:170x170", seed: wSeed)
            capture("AC35_W2_170x170")
        }
        step("AC-35 W-2 148x148") {
            try showWidget("systemSmall:148x148", seed: wSeed)
            capture("AC35_W2_148x148")
        }
        step("W-1 empty (no current book)") {
            try showWidget("accessoryRectangular:172x76", seed: emptySeed)
            capture("W1_empty_light")
        }
        step("W-1 noLine (title + page)") {
            try showWidget("accessoryRectangular:172x76", seed: noLineSeed)
            capture("W1_noLine_light")
        }
        step("W-1 error (snapshot missing)") {
            try showWidget("accessoryRectangular:172x76", seed: wSeed, extraEnv: ["UITEST_WIDGET_SNAPSHOT": "@missing"])
            capture("W1_error_light")
        }
        step("W-1 partial (title pending)") {
            try showWidget("accessoryRectangular:172x76", seed: pendingSeed)
            capture("W1_pending_light")
        }
        step("W-2 empty") {
            try showWidget("systemSmall:170x170", seed: emptySeed)
            capture("W2_empty_light")
        }
        step("W-2 error (snapshot missing)") {
            try showWidget("systemSmall:170x170", seed: wSeed, extraEnv: ["UITEST_WIDGET_SNAPSHOT": "@missing"])
            capture("W2_error_light")
        }
        step("W-2 partial (title pending)") {
            try showWidget("systemSmall:170x170", seed: pendingSeed)
            capture("W2_partial_light")
        }
        step("W-3 reading") {
            try showWidget("liveActivity:370x160:reading", seed: wSeed)
            capture("W3_reading_light")
        }
        step("W-3 ended") {
            // 契約 H22：ended は今の本のいちばん新しい記録から作る（記録がなければ hook.error）。記録つきの投入で描く。
            let endedSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current", page: 61, lastLine: widgetLine)],
                                         records: [makeSeedRecord(id: makeRecordUUID(1), bookId: uuidBookA, startedAt: "2026-10-15T21:00:00+09:00", endedAt: "2026-10-15T21:10:00+09:00", minutes: 10, nightDate: "2026-10-15", startPage: 43, endPage: 61)])
            try showWidget("liveActivity:370x160:ended", seed: endedSeed)
            capture("W3_ended_light")
        }
        step("W-3 empty (no line)") {
            try showWidget("liveActivity:370x160:waiting", seed: noLineSeed)
            capture("W3_empty_light")
        }
        step("W-3 partial (hidden)") {
            try showWidget("liveActivity:370x160:waiting", seed: hiddenSeed)
            capture("W3_partial_light")
        }
        step("W-5 empty (no progress)") {
            try showWidget("snippet:360x200", seed: makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", status: "current")]))
            capture("W5_empty_light")
        }
        step("W-5 partial (hidden)") {
            try showWidget("snippet:360x200", seed: hiddenSeed)
            capture("W5_partial_light")
        }
        // 読み込み中（H22 の placeholder。design/ 5 の W-1、W-2 の読み込み中）
        step("W-1 loading (placeholder)") {
            try showWidget("accessoryRectangular:172x76:placeholder", seed: wSeed)
            capture("W1_loading_light")
        }
        step("W-2 loading (placeholder)") {
            try showWidget("systemSmall:170x170:placeholder", seed: wSeed)
            capture("W2_loading_light")
        }
        // W-3 の読み込み中・オフラインは仕様上ない。W-3 のエラー・権限なし、W-4 の読み込み中・エラー・権限なしはアプリの側の画面で出る
        // （contracts/test-hooks.md 8 章）。W-4 の通常は上で撮った。

        // contracts/test-hooks.md 7：hook.widget の読み出し全体を h22-widget.schema.json に照らすため、W-1・W-2 の4つの枠で、
        // state が normal（縦書き・横書き）、noLine、noLineNoPage、hidden、empty、unavailable になる投入ごとに値を保存する。
        let fourFrames = "accessoryRectangular:153x68,accessoryRectangular:172x76,systemSmall:148x148,systemSmall:170x170"
        let horizontalSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "Rain", status: "current", page: 61, lastLine: "It was raining.")])
        let noLineNoPageSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current")])
        let h22Cases: [(name: String, seed: String, env: [String: String])] = [
            ("normal_vertical", wSeed, [:]),
            ("normal_horizontal", horizontalSeed, [:]),
            ("noLine", noLineSeed, [:]),
            ("noLineNoPage", noLineNoPageSeed, [:]),
            ("hidden", hiddenSeed, [:]),
            ("empty", emptySeed, [:]),
            ("unavailable", wSeed, ["UITEST_WIDGET_SNAPSHOT": "@missing"])
        ]
        for c in h22Cases {
            step("H22 readout \(c.name)") {
                launch(seed: c.seed, extraArgs: ["-uitest-widget", fourFrames], extraEnv: c.env, readoutsOff: false)
                let renders = readHookJSON("hook.widget")["renders"] as? [[String: Any]] ?? []
                log("H22 \(c.name) renders=\(renders.count) states=\(renders.map { "\($0["state"] ?? "?")" })")
                saveHookWidgetJSON(c.name)
            }
        }
        step("H22 readout with showcase") {
            try showWidget("accessoryRectangular:172x76", seed: wSeed, extraEnv: [:])
            saveHookWidgetJSON("showcase_w1_172x76")
        }
        step("H22 readout with showcase (horizontal)") {
            try showWidget("accessoryRectangular:172x76", seed: horizontalSeed)
            capture("AC30_W1_horizontal")
            saveHookWidgetJSON("showcase_w1_horizontal")
        }
    }

    /// H33：`hook.state` の `hold.<対象>` が `shown` になるのを待つ（sleep で待たない。値の変化を XCTNSPredicateExpectation で待つ）。
    private func waitForHold(_ target: String, timeout: TimeInterval = uiTimeout) throws {
        let stateEl = element("hook.state")
        guard stateEl.waitForExistence(timeout: timeout) else {
            throw CaptureError(description: "hook.state not found while waiting hold.\(target)")
        }
        let predicate = NSPredicate { object, _ in
            guard let el = object as? XCUIElement, let value = el.value as? String else { return false }
            return value.split(separator: ";").contains { $0 == "hold.\(target)=shown" }
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: stateEl)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        guard result == .completed else {
            throw CaptureError(description: "hold.\(target) did not reach shown within \(timeout)s; hook.state=\(stateEl.value as? String ?? "?")")
        }
        log("HOLD \(target)=shown")
    }

    /// H33：止めているものをすべて放す（`yomuma.uitest.load.release`、状態 0）。
    private func releaseHolds() {
        var token: Int32 = 0
        notify_register_check("yomuma.uitest.load.release", &token)
        notify_set_state(token, 0)
        notify_post("yomuma.uitest.load.release")
        notify_cancel(token)
        log("RELEASE holds")
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
        let noLineSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current", page: nil, lastLine: nil)])
        let noCurrentSeed = makeSeedJSON(books: [bookB, bookC])
        let noRecordSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", status: "current", page: 45)])
        // 奥付（出版社・出版年・ISBN）の足りない本。S-7 に `colophon.capture` / `book.captureColophon` が出る（design/ 5 の S-7）。
        let noColophonSeed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current", page: 45,
                                                                lastLine: "ある日の暮方の事である。")],
                                          records: [record1, record2])

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
            launch(seed: noColophonSeed, camera: "denied")
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
            launch(seed: noColophonSeed, ocr: #"{"colophon":{"lines":[]}}"#)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try tapColophonCapture()
            _ = try require("colophon.cancel")
            if element("mark.ocr.none").waitForExistence(timeout: uiTimeout) {
                capture("S7c_empty_light")
            } else {
                log("NOTE S-7c empty: mark.ocr.none (design 5章 S-7c 空) not found with colophon.lines=[]; elements: " + ["colophon.retake", "colophon.title", "colophon.author", "colophon.publisher", "colophon.save"].map { "\($0)=\(element($0).exists)" }.joined(separator: " ") + "; captured as-is")
                capture("S7c_empty_asis_light")
            }
        }
        step("S-7c loading (OCR held)") {
            launch(seed: noColophonSeed, ocr: #"{"hold":true,"colophon":{"lines":["発行所 岩波書店"]}}"#)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try tapColophonCapture()
            _ = try require("colophon.cancel")
            capture("S7c_loading_light")
            releaseOCR()
        }
        step("S-7c denied (camera)") {
            launch(seed: noColophonSeed, camera: "denied")
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try tapColophonCapture()
            _ = try require("camera.denied")
            capture("S7c_denied_light")
        }
        step("S-7c partial (publisher and year only)") {
            launch(seed: noColophonSeed, ocr: #"{"colophon":{"lines":["1927年7月1日 発行","発行所 岩波書店"]}}"#)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try tapColophonCapture()
            _ = try require("colophon.cancel")
            if element("colophon.ocr.publisher").waitForExistence(timeout: uiTimeout) {
                log("S-7c partial elements: " + ["colophon.ocr.title", "colophon.ocr.author", "colophon.ocr.publisher", "colophon.ocr.label", "colophon.ocr.year", "colophon.ocr.isbn", "colophon.save"].map { "\($0)=\(element($0).exists) value=\(element($0).exists ? (element($0).value.map { "\($0)" } ?? "nil") : "-")" }.joined(separator: " "))
                capture("S7c_partial_light")
            } else {
                log("NOTE S-7c partial: colophon.ocr.publisher not found; elements: " + ["mark.ocr.none", "colophon.retake", "colophon.ocr.title", "colophon.ocr.author", "colophon.save"].map { "\($0)=\(element($0).exists)" }.joined(separator: " ") + "; captured as-is")
                capture("S7c_partial_asis_light")
            }
        }
        step("S-7c error (save fails)") {
            launch(seed: noColophonSeed, ocr: colophonOCR, failSave: "book.update:1")
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
        step("S-9 error (add next to shelf fails)") {
            // H7 は「次の保存から N 回」なので、読み終える保存（book.status）は通し、未所有の同じ著者の候補の `next.addToShelf`（book.add）を失敗させる
            let stub = #"{"stubVersion":1,"status":"ready","books":[{"isbn":"9784101000053","title":"鼻","author":"芥川龍之介","publisher":"新潮社","label":"新潮文庫","publishedYear":2005}],"cooccurrences":[]}"#
            launch(seed: makeSeedJSON(books: [bookA], records: [record1, record2]), failSave: "book.add:1", ndlStub: stub)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try require("book.markFinished").tap()
            let cand = try require("next.candidate.9784101000053")
            cand.descendants(matching: .any).matching(identifier: "next.addToShelf").firstMatch.tap()
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
            // contracts/test-hooks.md 8 章：`-uitest-offline` で `settings.restorePurchases` を押すと `store.offline`
            launch(seed: normalSeed, offline: true)
            try require("toolbar.settings").tap()
            try require("settings.restorePurchases").tap()
            if element("store.offline").waitForExistence(timeout: uiTimeout) {
                capture("S10_offline_light")
            } else {
                log("NOTE S-10 offline: store.offline (contracts 8章) not found after settings.restorePurchases while offline; captured as-is")
                capture("S10_offline_asis_light")
            }
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
        step("S-10a unavailable (product load unavailable)") {
            launch(seed: normalSeed, storeKit: #"{"productLoadAvailable":false}"#)
            try require("toolbar.settings").tap()
            try require("appearance.row.kinari").tap()
            _ = try require("sheet.storePreview")
            capture("S10a_unavailable_light")
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
        // H33（contracts/test-hooks.md）：読み込みを止めて、`hook.state` の `hold.<対象>=shown` を待ってから撮る（readouts を出した起動）。
        step("S-1 loading (hold store.load)") {
            launch(seed: normalSeed, extraArgs: ["-uitest-hold-load", "store.load"], readoutsOff: false)
            try waitForHold("store.load")
            capture("S1_loading_light")
            releaseHolds()
            _ = try require("bookmark.line")
        }
        step("S-6 loading (hold shelf.load)") {
            launch(seed: normalSeed, extraArgs: ["-uitest-hold-load", "shelf.load"], readoutsOff: false)
            try require("toolbar.shelf").tap()
            try waitForHold("shelf.load")
            capture("S6_loading_light")
            releaseHolds()
            _ = try require("shelf.row.\(uuidBookA.lowercased())")
        }
        step("S-7 loading (hold book.load)") {
            launch(seed: normalSeed, extraArgs: ["-uitest-hold-load", "book.load"], readoutsOff: false)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try waitForHold("book.load")
            capture("S7_loading_light")
            releaseHolds()
            _ = try require("book.colophon")
        }
        step("S-9 loading (hold recommend.load)") {
            launch(seed: normalSeed, extraArgs: ["-uitest-hold-load", "recommend.load"], readoutsOff: false)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try require("book.markFinished").tap()
            try waitForHold("recommend.load")
            capture("S9_loading_light")
            releaseHolds()
            _ = try require("finish.colophon")
        }
        step("S-8a loading (hold catalog.lookup)") {
            launch(seed: emptySeed, extraArgs: ["-uitest-hold-load", "catalog.lookup"], readoutsOff: false)
            try require("bookmark.addBook").tap()
            try require("register.barcode").tap()
            _ = try require("sheet.barcode")
            sendBarcode("9784101006055")
            try waitForHold("catalog.lookup")
            capture("S8a_loading_light")
            releaseHolds()
            _ = try require("scan.row.9784101006055")
        }
        step("S-8c loading (hold catalog.lookup)") {
            launch(seed: emptySeed, extraArgs: ["-uitest-hold-load", "catalog.lookup"], readoutsOff: false)
            try require("bookmark.addBook").tap()
            try require("register.manual").tap()
            let title = try require("manual.title")
            title.tap()
            title.typeText("人間失格")
            try waitForHold("catalog.lookup")
            capture("S8c_loading_light")
            releaseHolds()
        }
        step("S-10 loading (hold storekit.restore)") {
            launch(seed: normalSeed, extraArgs: ["-uitest-hold-load", "storekit.restore"], readoutsOff: false)
            try require("toolbar.settings").tap()
            try require("settings.restorePurchases").tap()
            do {
                try waitForHold("storekit.restore")
                capture("S10_loading_light")
            } catch {
                log("NOTE S-10 loading: \(error); captured as-is (held but not shown)")
                capture("S10_loading_asis_light")
                releaseHolds()
                throw error
            }
            releaseHolds()
        }
        step("S-10a loading (hold storekit.products)") {
            launch(seed: normalSeed, extraArgs: ["-uitest-hold-load", "storekit.products"], readoutsOff: false)
            try require("toolbar.settings").tap()
            try require("appearance.row.kinari").tap()
            try waitForHold("storekit.products")
            capture("S10a_loading_light")
            releaseHolds()
            _ = try require("store.buy")
        }
        step("S-1 loading then error (hold store.load + fail store.load)") {
            launch(seed: normalSeed, failSave: "store.load:1", extraArgs: ["-uitest-hold-load", "store.load"], readoutsOff: false)
            try waitForHold("store.load")
            capture("S1_loading_error_light")
            releaseHolds()
            _ = try require("store.load.error")
            capture("S1_error_after_loading_light")
        }
        step("AC-34 S-1 visible while hidden on widgets") {
            launch(seed: makeSeedJSON(books: [bookA], records: [record2], settings: makeSeedSettings(hideOnWidgets: true)))
            _ = try require("bookmark.line")
            capture("AC34_S1_visible")
        }
    }

    // MARK: - 3b. 探索（test-plan 6 章のチャーター R1、R4、R6。使い捨て。手順ごとに画像と debugDescription を残す。AC の判定には使わない）

    /// 手順ごとに画面と app.debugDescription を残す。
    private func explore(_ title: String, _ body: () throws -> Void) {
        step(title) {
            try body()
            capture("X_\(title.replacingOccurrences(of: "[^A-Za-z0-9]+", with: "_", options: .regularExpression))")
            if let outDir = outDir {
                let url = URL(fileURLWithPath: outDir).appendingPathComponent("X_\(title.replacingOccurrences(of: "[^A-Za-z0-9]+", with: "_", options: .regularExpression)).tree.txt")
                try? app.debugDescription.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    func test_G3_exploratory() throws {
        guard captureEnabled, variant == "light" else { return }
        executionTimeAllowance = 1200

        // R6：S-7a（本の編集）の欄に今の値が入っているか。著者だけを直して保存したとき書名が消えないか。
        explore("R6 1 S-7a open fields") {
            launch(seed: normalSeed, readoutsOff: false)
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            try require("book.edit").tap()
            _ = try require("book.edit.cancel")
            for id in ["book.edit.title", "book.edit.author", "book.edit.publisher", "book.edit.label", "book.edit.year"] {
                let f = element(id)
                log("FIELD \(id) exists=\(f.exists) value=\(f.exists ? (f.value.map { "\($0)" } ?? "nil") : "-") placeholder=\(f.exists ? (f.placeholderValue ?? "nil") : "-")")
            }
        }
        explore("R6 2 S-7a save without change") {
            try require("book.edit.save").tap()
            let invalid = element("book.title.invalid").waitForExistence(timeout: 2)
            let books = readStoreBooks()
            let a = books.first { ($0["id"] as? String) == uuidBookA }
            log("RESULT save-without-change title.invalid=\(invalid) title=\(a?["title"] ?? "nil") author=\(a?["author"] ?? "nil") publisher=\(a?["publisher"] ?? "nil") year=\(a?["publishedYear"] ?? "nil")")
            if element("book.edit.cancel").exists { try require("book.edit.cancel").tap() }
        }
        explore("R6 3 S-7a edit author only") {
            try require("book.edit").tap()
            let author = try require("book.edit.author")
            author.tap()
            author.typeText("（改）")
            try require("book.edit.save").tap()
            let invalid = element("book.title.invalid").waitForExistence(timeout: 2)
            let books = readStoreBooks()
            let a = books.first { ($0["id"] as? String) == uuidBookA }
            log("RESULT edit-author-only title.invalid=\(invalid) title=\(a?["title"] ?? "nil") author=\(a?["author"] ?? "nil") publisher=\(a?["publisher"] ?? "nil") year=\(a?["publishedYear"] ?? "nil")")
            if element("book.edit.cancel").exists { try require("book.edit.cancel").tap() }
        }
        explore("R6 4 S-7 after edit") {
            _ = try require("book.colophon")
            log("COLOPHON label=\(element("book.colophon").label)")
        }

        // R4：隠す設定の切り替えと、禁則の多い一行で W-1 の読み出しに書名・一行が漏れないか、字が落ちないか。
        explore("R4 1 widget 25 chars kinsoku heavy") {
            let line = "「あ」と、「い」と、「う」と、「え」と、「お」と。"
            let seed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", status: "current", page: 61, lastLine: line)])
            launch(seed: seed, extraArgs: ["-uitest-widget", "accessoryRectangular:153x68,accessoryRectangular:172x76,systemSmall:148x148,systemSmall:170x170"], readoutsOff: false)
            let renders = readHookJSON("hook.widget")["renders"] as? [[String: Any]] ?? []
            for r in renders {
                let comp = r["composition"] as? [String: Any] ?? [:]
                let cells = comp["cells"] as? [[String: Any]] ?? []
                let joined = cells.compactMap { $0["source"] as? String }.joined()
                let heads = cells.filter { ($0["row"] as? Int) == 1 }.compactMap { $0["source"] as? String }
                log("R4 \(r["request"] ?? "?") s=\(comp["fontSize"] ?? "-") L=\(comp["L"] ?? "-") C=\(comp["columnCount"] ?? "-") feed=\(comp["feedCount"] ?? "-") relaxed=\(comp["kinsokuRelaxed"] ?? "-") joined==line:\(joined == (comp["displayedLine"] as? String ?? "")) heads=\(heads)")
            }
            saveHookWidgetJSON("explore_kinsoku_heavy")
        }
        explore("R4 2 toggle hideOnWidgets on") {
            launch(seed: normalSeed, extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"], readoutsOff: false)
            try require("toolbar.settings").tap()
            try require("settings.hideOnWidgets").tap()
            let raw = readHookString("hook.widget")
            log("R4 hidden: contains title=\(raw.contains("羅生門")) contains line=\(raw.contains("ある日の暮方")) state=\((readHookJSON("hook.widget")["renders"] as? [[String: Any]])?.first?["state"] ?? "?")")
            let la = readHookString("hook.liveActivity")
            log("R4 hidden liveActivity: contains title=\(la.contains("羅生門")) contains line=\(la.contains("ある日の暮方"))")
        }
        explore("R4 3 toggle hideOnWidgets off again") {
            try require("settings.hideOnWidgets").tap()
            let raw = readHookString("hook.widget")
            log("R4 shown again: contains title=\(raw.contains("羅生門")) contains line=\(raw.contains("ある日の暮方")) state=\((readHookJSON("hook.widget")["renders"] as? [[String: Any]])?.first?["state"] ?? "?")")
        }

        // R1：4:00 をまたぐ読書（03:50→04:10）が1つの晩に数えられ、晩の日付は前日か。
        explore("R1 1 read across 4am") {
            launch(seed: normalSeed, now: "2026-10-17T03:50:00+09:00", readoutsOff: false)
            try require("bookmark.start").tap()
            _ = try require("screen.reading")
            advanceClock(seconds: 1200)
            try require("reading.end").tap()
            try require("mark.later").tap()
            _ = try require("sheet.result")
            let records = readStoreRecords()
            let newest = records.max { ($0["startedAt"] as? String ?? "") < ($1["startedAt"] as? String ?? "") }
            log("R1 record nightDate=\(newest?["nightDate"] ?? "nil") minutes=\(newest?["minutes"] ?? "nil") count=\(records.count)")
            try require("result.close").tap()
        }
        explore("R1 2 book nights after 4am session") {
            try require("toolbar.shelf").tap()
            try require("shelf.row.\(uuidBookA.lowercased())").tap()
            _ = try require("book.nights")
            log("R1 nights=\(element("book.nights").label) total=\(element("book.total").label)")
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
            // contracts/test-hooks.md H22：監査は readouts を出さない起動で、根の `hook.widget.showcase` の画面に対して行う。
            for (code, spec) in [("W-1", "accessoryRectangular:172x76"), ("W-2", "systemSmall:170x170"),
                                 ("W-3", "liveActivity:370x160:waiting"), ("W-4", "control:160x72"), ("W-5", "snippet:360x200")] {
                let seed = makeSeedJSON(books: [makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current", page: 61, lastLine: "下人の行方は、誰も知らない。")])
                launch(seed: seed, extraArgs: ["-uitest-widget-show", spec], readoutsOff: true)
                if element("hook.widget.showcase").waitForExistence(timeout: uiTimeout), element("hook.widget.canvas").waitForExistence(timeout: uiTimeout) {
                    runAudit(code, spec)
                } else {
                    auditLines.append("\(code) (\(spec)): NOT AUDITED (hook.widget.showcase / hook.widget.canvas not shown)")
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
            _ = try require("colophon.ocr.publisher")
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
