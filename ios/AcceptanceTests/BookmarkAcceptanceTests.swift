import XCTest

final class BookmarkAcceptanceTests: AcceptanceTestBase {

    private let currentBookSeed = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current","savedLine":"ある日の暮方の事である。","savedPage":43}],"records":[]}"#

    func test_AC63_しおりを挟む画面に5つの道がすべて押せる状態で出る() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 1080)
        element("reading.end").tap()

        let ids = ["mark.photo", "mark.screenshot", "mark.manual", "mark.pageOnly", "mark.later"]
        for id in ids {
            let el = element(id)
            XCTAssertTrue(el.waitForExistence(timeout: uiTimeout))
            XCTAssertEqual(matchingCount(id), 1)
            XCTAssertTrue(el.isEnabled)
        }
    }

    func test_AC64_読まずにしおりだけを挟むと記録を増やさず更新される() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let setMarkBtn = element("bookmark.setMark")
        XCTAssertTrue(setMarkBtn.waitForExistence(timeout: uiTimeout))
        setMarkBtn.tap()

        let manualBtn = element("mark.manual")
        XCTAssertTrue(manualBtn.waitForExistence(timeout: uiTimeout))
        manualBtn.tap()

        let lineField = element("mark.lineField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        lineField.tap()
        lineField.typeText("下人は、雨やみを待っていた。")

        let pageField = element("mark.pageField")
        pageField.tap()
        pageField.typeText("12")
        element("mark.save").tap()

        XCTAssertEqual(readHookString("bookmark.line"), "下人は、雨やみを待っていた。")
        XCTAssertEqual(readHookString("bookmark.page"), "p.12")
        XCTAssertEqual((readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []).count, 0)
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
        XCTAssertEqual(matchingCount("result.summary"), 0)
    }

    func test_AC65_ページ写真OCRで一番左の列が初期選択され保存できる() {
        let ocrStub = #"{"columns":[{"index":1,"text":"ある日の暮方の事である。"},{"index":2,"text":"一人の下人が"},{"index":3,"text":"羅生門の下で"},{"index":4,"text":"雨やみを待っていた。"},{"index":5,"text":"広い門の下には"},{"index":6,"text":"ほかには誰もいない。"}]}"#
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", ocrJSON: ocrStub)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()

        let photoBtn = element("mark.photo")
        XCTAssertTrue(photoBtn.waitForExistence(timeout: uiTimeout))
        photoBtn.tap()

        for i in 1...6 {
            XCTAssertTrue(element("mark.ocr.column.\(i)").waitForExistence(timeout: uiTimeout))
        }
        XCTAssertTrue(element("mark.ocr.column.6").isSelected)
        XCTAssertEqual(readHookString("mark.lineField"), "ほかには誰もいない。")

        let pageField = element("mark.pageField")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        XCTAssertTrue(element("result.summary").waitForExistence(timeout: uiTimeout))
        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.first?["savedLine"] as? String, "ほかには誰もいない。")
        XCTAssertEqual(books.first?["savedPage"] as? Int, 61)
    }

    func test_AC66_OCR結果の別の列を選び直して保存できる() {
        let ocrStub = #"{"columns":[{"index":1,"text":"列1"},{"index":2,"text":"列2"},{"index":3,"text":"羅生門の下で"},{"index":4,"text":"列4"},{"index":5,"text":"列5"},{"index":6,"text":"ほかには誰もいない。"}]}"#
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", ocrJSON: ocrStub)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.photo").tap()

        let col3 = element("mark.ocr.column.3")
        XCTAssertTrue(col3.waitForExistence(timeout: uiTimeout))
        col3.tap()

        XCTAssertEqual(readHookString("mark.lineField"), "羅生門の下で")
        XCTAssertTrue(col3.isSelected)
        XCTAssertFalse(element("mark.ocr.column.6").isSelected)

        element("mark.save").tap()
        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.first?["savedLine"] as? String, "羅生門の下で")
    }

    func test_AC67_OCRの誤字を入力欄で手直しして保存できる() {
        let ocrStub = #"{"columns":[{"index":6,"text":"羅生際の下で雨やみを待っていた。"}]}"#
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", ocrJSON: ocrStub)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.photo").tap()

        let lineField = element("mark.lineField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        lineField.tap()
        lineField.typeText("羅生門の下で雨やみを待っていた。")
        element("mark.save").tap()

        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        let savedLine = books.first?["savedLine"] as? String ?? ""
        XCTAssertEqual(savedLine, "羅生門の下で雨やみを待っていた。")
        XCTAssertFalse(savedLine.contains("羅生際"))
    }

    func test_AC68_文字が1行も読み取れないときに撮り直しと手入力が出る() {
        let emptyOcr = #"{"columns":[]}"#
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", ocrJSON: emptyOcr)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.photo").tap()

        XCTAssertTrue(element("mark.ocr.none").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("mark.retake").exists)
        XCTAssertTrue(element("mark.manual").exists)
        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.first?["savedLine"] as? String, "ある日の暮方の事である。")
        XCTAssertEqual(books.first?["savedPage"] as? Int, 43)
    }

    func test_AC69_撮影したページ画像と未選択列の文字を一切残さない() {
        let ocrStub = #"{"columns":[{"index":1,"text":"未選択1"},{"index":2,"text":"未選択2"},{"index":6,"text":"選んだ一行"}]}"#
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", ocrJSON: ocrStub)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.photo").tap()
        element("mark.save").tap()

        let media = readHookJSON("hook.media")
        XCTAssertEqual(media["savedImageFileCount"] as? Int, 0)
        XCTAssertEqual(media["photoLibraryWriteCount"] as? Int, 0)
        let storeRaw = readHookString("hook.store")
        XCTAssertFalse(storeRaw.contains("未選択1"))
        XCTAssertFalse(storeRaw.contains("未選択2"))
    }

    func test_AC70_しおり撮影でカメラ拒否時にスクショと手入力の導線が出る() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", camera: "denied")
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.photo").tap()

        XCTAssertTrue(element("camera.denied").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("camera.openSettings"), 1)
        XCTAssertEqual(matchingCount("mark.screenshot"), 1)
        XCTAssertEqual(matchingCount("mark.manual"), 1)
        XCTAssertEqual(matchingCount("mark.pageOnly"), 1)
    }

    func test_AC71_手入力の一行の前後空白を除いて保存する() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.setMark").tap()
        element("mark.manual").tap()

        let lineField = element("mark.lineField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        lineField.tap()
        lineField.typeText("　下人の行方は、誰も知らない。　")
        let pageField = element("mark.pageField")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.first?["savedLine"] as? String, "下人の行方は、誰も知らない。")
        XCTAssertEqual(books.first?["savedPage"] as? Int, 61)
    }

    func test_AC72_一行の1字から60字までの境界値を検証する() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.setMark").tap()
        element("mark.manual").tap()

        let lineField = element("mark.lineField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        element("mark.save").tap()
        XCTAssertEqual(matchingCount("mark.line.invalid"), 1)

        lineField.tap()
        lineField.typeText("　　")
        element("mark.save").tap()
        XCTAssertEqual(matchingCount("mark.line.invalid"), 1)

        let str61 = String(repeating: "あ", count: 61)
        lineField.typeText(str61)
        element("mark.save").tap()
        XCTAssertEqual(matchingCount("mark.line.invalid"), 1)

        let str60 = String(repeating: "あ", count: 60)
        lineField.typeText(str60)
        element("mark.save").tap()
        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.first?["savedLine"] as? String, str60)
    }

    func test_AC73_ページ数だけ入れると一行が空になりウィジェットも書名とページになる() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.setMark").tap()
        element("mark.pageOnly").tap()

        let pageField = element("mark.pageField")
        XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.first?["savedPage"] as? Int, 61)
        XCTAssertEqual(books.first?["savedLine"] as? String ?? "", "")
        let widget = readHookJSON("hook.widgets")
        XCTAssertEqual(widget["savedLine"] as? String ?? "", "")
    }

    func test_AC74_ページ番号の1から9999までの境界値と全角数字を検証する() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.setMark").tap()
        element("mark.pageOnly").tap()

        let pageField = element("mark.pageField")
        XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
        for invalid in ["0", "10000", "", "61.5"] {
            pageField.tap()
            pageField.typeText(invalid)
            element("mark.save").tap()
            XCTAssertEqual(matchingCount("mark.page.invalid"), 1)
        }

        pageField.tap()
        pageField.typeText("６１")
        element("mark.save").tap()
        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.first?["savedPage"] as? Int, 61)
    }

    func test_AC75_あとでを選ぶと前のしおりを保ち結果画面に分数だけが出る() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 1080)
        element("reading.end").tap()
        element("mark.later").tap()

        XCTAssertEqual(readHookString("result.summary"), "18分")
        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.first?["savedLine"] as? String, "ある日の暮方の事である。")
        XCTAssertEqual(books.first?["savedPage"] as? Int, 43)
    }

    func test_AC76_結果画面に前回ページからの遷移と分数が出て1タップで閉じる() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 1080)
        element("reading.end").tap()
        element("mark.pageOnly").tap()
        let pageField = element("mark.pageField")
        XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        XCTAssertEqual(readHookString("result.summary"), "p.43 → p.61　18分")
        element("result.close").tap()
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
    }

    func test_AC94_OCR待ちの間も1秒以内に手入力やページ入力に移り後から結果が返っても上書きされない() {
        let holdOcr = #"{"hold":true,"columns":[{"index":6,"text":"遅れて返る文字列"}]}"#
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", ocrJSON: holdOcr)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.photo").tap()

        element("mark.manual").tap()
        let lineField = element("mark.lineField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        let markWait = readHookJSON("hook.perf")["markWait"] as? Double ?? 9999.0
        XCTAssertLessThanOrEqual(markWait, 1000.0)

        lineField.tap()
        lineField.typeText("下人の")
        releaseOCR()

        XCTAssertEqual(readHookString("mark.lineField"), "下人の")
        XCTAssertEqual(matchingCount("mark.ocr.column.6"), 0)
    }

    func test_AC95_読後のしおり保存失敗時も記録は残り入力値を保ったまま再保存できる() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "mark.save:1")
        element("bookmark.start").tap()
        advanceClock(seconds: 1080)
        element("reading.end").tap()
        element("mark.manual").tap()

        let lineField = element("mark.lineField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        lineField.tap()
        lineField.typeText("新しい一行")
        element("mark.save").tap()

        XCTAssertTrue(element("common.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookString("mark.lineField"), "新しい一行")
        XCTAssertEqual((readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []).count, 1)

        element("mark.save").tap()
        XCTAssertTrue(element("result.summary").waitForExistence(timeout: uiTimeout))
        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.first?["savedLine"] as? String, "新しい一行")
    }

    func test_AC141_電子書籍の位置番号とパーセントのしおり保存と境界値を検証する() {
        let ebookSeed = #"{"books":[{"id":"book-e","title":"羅生門","author":"芥川龍之介","status":"current","isEbook":true,"savedPositionMode":"location","savedLocation":1200}],"records":[]}"#
        resetAndLaunch(seedJSON: ebookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 1080)
        element("reading.end").tap()
        element("mark.pageOnly").tap()

        let pageField = element("mark.pageField")
        XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
        pageField.tap()
        pageField.typeText("1450")
        element("mark.save").tap()

        XCTAssertEqual(readHookString("result.summary"), "位置1200 → 位置1450　18分")
    }

    func test_AC142_カメラ拒否でもスクリーンショットから一行を選んで保存でき画像を残さない() {
        let ocrStub = #"{"columns":[{"index":1,"text":"列1"},{"index":2,"text":"列2"},{"index":3,"text":"列3"},{"index":4,"text":"下人の行方は、誰も知らない。"}]}"#
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", camera: "denied", ocrJSON: ocrStub)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.screenshot").tap()

        XCTAssertEqual(app.alerts.count, 0)
        let col4 = element("mark.ocr.column.4")
        XCTAssertTrue(col4.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(col4.isSelected)

        let pageField = element("mark.pageField")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.first?["savedLine"] as? String, "下人の行方は、誰も知らない。")
        XCTAssertEqual(books.first?["savedPage"] as? Int, 61)
        XCTAssertEqual(readHookJSON("hook.media")["savedImageFileCount"] as? Int, 0)
    }
}
