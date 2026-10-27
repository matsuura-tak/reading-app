import XCTest

final class BookmarkAcceptanceTests: AcceptanceTestBase {

    private var currentBookSeed: String {
        makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                author: "芥川龍之介",
                status: "current",
                progressUnit: "page",
                page: 43,
                lastLine: "ある日の暮方の事である。"
            )
        ])
    }

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
        let seedNoMark = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                author: "芥川龍之介",
                status: "current"
            )
        ])
        resetAndLaunch(
            seedJSON: seedNoMark,
            now: "2026-10-18T21:00:00+09:00",
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )
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
        XCTAssertEqual(readStoreRecords().count, 0)
        XCTAssertEqual(readHookState()["state"], "idle")
        XCTAssertEqual(matchingCount("result.summary"), 0)

        let widgetRaw = readHookString("hook.widget")
        XCTAssertTrue(widgetRaw.contains("下人は、雨やみを待っていた。"))
        XCTAssertTrue(widgetRaw.contains("p.12"))
    }

    func test_AC65_ページ写真OCRで一番左の列が初期選択され保存できる() {
        let ocrStub = #"{"page":{"columns":["ある日の暮方の事である。","一人の下人が","羅生門の下で","雨やみを待っていた。","広い門の下には","ほかには誰もいない。"],"detectedPage":null}}"#
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
        let books = readStoreBooks()
        XCTAssertEqual(books.first?["lastLine"] as? String, "ほかには誰もいない。")
        XCTAssertEqual(books.first?["page"] as? Int, 61)

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        XCTAssertEqual(booksAfter.first?["lastLine"] as? String, "ほかには誰もいない。")
        XCTAssertEqual(booksAfter.first?["page"] as? Int, 61)
    }

    func test_AC66_OCR結果の別の列を選び直して保存できる() {
        let ocrStub = #"{"page":{"columns":["列1","列2","羅生門の下で","列4","列5","ほかには誰もいない。"],"detectedPage":61}}"#
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
        let books = readStoreBooks()
        XCTAssertEqual(books.first?["lastLine"] as? String, "羅生門の下で")

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        XCTAssertEqual(booksAfter.first?["lastLine"] as? String, "羅生門の下で")
    }

    func test_AC67_OCRの誤字を入力欄で手直しして保存できる() {
        let ocrStub = #"{"page":{"columns":["列1","列2","列3","列4","列5","羅生際の下で雨やみを待っていた。"],"detectedPage":61}}"#
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

        let books = readStoreBooks()
        let savedLine = books.first?["lastLine"] as? String ?? ""
        XCTAssertEqual(savedLine, "羅生門の下で雨やみを待っていた。")
        XCTAssertFalse(savedLine.contains("羅生際"))

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        XCTAssertEqual(booksAfter.first?["lastLine"] as? String, "羅生門の下で雨やみを待っていた。")
    }

    func test_AC68_文字が1行も読み取れないときに撮り直しと手入力が出る() {
        let emptyOcr = #"{"page":{"columns":[],"detectedPage":null}}"#
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", ocrJSON: emptyOcr)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.photo").tap()

        XCTAssertTrue(element("mark.ocr.none").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("mark.retake").exists)
        XCTAssertTrue(element("mark.manual").exists)
        let books = readStoreBooks()
        XCTAssertEqual(books.first?["lastLine"] as? String, "ある日の暮方の事である。")
        XCTAssertEqual(books.first?["page"] as? Int, 43)
    }

    func test_AC69_撮影したページ画像と未選択列の文字を一切残さない() {
        let ocrStub = #"{"page":{"columns":["未選択1","未選択2","未選択3","未選択4","未選択5","選んだ一行"],"detectedPage":61}}"#

        // (1) 撮って mark.save で保存するケース
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", ocrJSON: ocrStub)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.photo").tap()
        XCTAssertTrue(element("mark.ocr.column.6").waitForExistence(timeout: uiTimeout))
        element("mark.save").tap()

        let media1 = readHookJSON("hook.mediaAudit")
        XCTAssertEqual(media1["savedImageFileCount"] as? Int, 0)
        XCTAssertEqual(media1["photoLibraryWriteCount"] as? Int, 0)
        let storeRaw1 = readHookString("hook.store")
        for i in 1...5 {
            XCTAssertFalse(storeRaw1.contains("未選択\(i)"))
        }

        // (2) 撮ってから保存せずに mark.later で閉じるケース
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", ocrJSON: ocrStub)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.photo").tap()
        XCTAssertTrue(element("mark.ocr.column.6").waitForExistence(timeout: uiTimeout))
        navigateBackToBookmark()
        let laterBtn = element("mark.later")
        if laterBtn.waitForExistence(timeout: uiTimeout) {
            laterBtn.tap()
        }

        let media2 = readHookJSON("hook.mediaAudit")
        XCTAssertEqual(media2["savedImageFileCount"] as? Int, 0)
        XCTAssertEqual(media2["photoLibraryWriteCount"] as? Int, 0)
        let storeRaw2 = readHookString("hook.store")
        for i in 1...5 {
            XCTAssertFalse(storeRaw2.contains("未選択\(i)"))
        }
        XCTAssertFalse(storeRaw2.contains("選んだ一行"))
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

        let books = readStoreBooks()
        XCTAssertEqual(books.first?["lastLine"] as? String, "下人の行方は、誰も知らない。")
        XCTAssertEqual(books.first?["page"] as? Int, 61)

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        XCTAssertEqual(booksAfter.first?["lastLine"] as? String, "下人の行方は、誰も知らない。")
        XCTAssertEqual(booksAfter.first?["page"] as? Int, 61)
    }

    func test_AC72_一行の1字から60字までの境界値を検証する() {
        let invalidLines = ["", "　　", String(repeating: "あ", count: 61)]
        for invalid in invalidLines {
            resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
            element("bookmark.setMark").tap()
            element("mark.manual").tap()
            let lineField = element("mark.lineField")
            XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
            if !invalid.isEmpty {
                lineField.tap()
                lineField.typeText(invalid)
            }
            let pageField = element("mark.pageField")
            pageField.tap()
            pageField.typeText("61")
            element("mark.save").tap()
            XCTAssertEqual(matchingCount("mark.line.invalid"), 1)
            let books = readStoreBooks()
            XCTAssertEqual(books.first?["lastLine"] as? String, "ある日の暮方の事である。")
            XCTAssertEqual(books.first?["page"] as? Int, 43)
        }

        let str60 = String(repeating: "あ", count: 60)
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.setMark").tap()
        element("mark.manual").tap()
        let lineField = element("mark.lineField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        lineField.tap()
        lineField.typeText(str60)
        let pageField = element("mark.pageField")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        let books = readStoreBooks()
        XCTAssertEqual(books.first?["lastLine"] as? String, str60)
        XCTAssertEqual(books.first?["page"] as? Int, 61)
    }

    func test_AC73_ページ数だけ入れると一行が空になりウィジェットも書名とページになる() {
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )
        element("bookmark.setMark").tap()
        element("mark.pageOnly").tap()

        let pageField = element("mark.pageField")
        XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        let books = readStoreBooks()
        XCTAssertEqual(books.first?["page"] as? Int, 61)
        XCTAssertNil(books.first?["lastLine"] as? String)

        let widgetJSON = readHookJSON("hook.widget")
        let renders = widgetJSON["renders"] as? [[String: Any]] ?? []
        let firstRender = renders.first ?? [:]
        XCTAssertEqual(firstRender["state"] as? String, "noLine")
        let texts = firstRender["texts"] as? [String: Any] ?? [:]
        XCTAssertEqual(texts["widget.title"] as? String, "羅生門")
        XCTAssertEqual(texts["widget.page"] as? String, "p.61")
        XCTAssertNil(texts["widget.line"])

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        XCTAssertEqual(booksAfter.first?["page"] as? Int, 61)
        XCTAssertNil(booksAfter.first?["lastLine"] as? String)
    }

    func test_AC74_ページ番号の1から9999までの境界値と全角数字を検証する() {
        for invalid in ["0", "10000", "", "61.5"] {
            resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
            element("bookmark.setMark").tap()
            element("mark.pageOnly").tap()
            let pageField = element("mark.pageField")
            XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
            if !invalid.isEmpty {
                pageField.tap()
                pageField.typeText(invalid)
            }
            element("mark.save").tap()
            XCTAssertEqual(matchingCount("mark.page.invalid"), 1)
            XCTAssertEqual(readStoreBooks().first?["page"] as? Int, 43)
        }

        let validCases: [(String, Int)] = [("６１", 61), ("1", 1), ("9999", 9999)]
        for (inputStr, expectedPage) in validCases {
            resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
            element("bookmark.setMark").tap()
            element("mark.pageOnly").tap()
            let pageField = element("mark.pageField")
            XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
            pageField.tap()
            pageField.typeText(inputStr)
            element("mark.save").tap()
            XCTAssertEqual(readStoreBooks().first?["page"] as? Int, expectedPage)
        }
    }

    func test_AC75_あとでを選ぶと前のしおりを保ち結果画面に分数だけが出る() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 1080)
        element("reading.end").tap()
        element("mark.later").tap()

        XCTAssertEqual(readHookString("result.summary"), "18分")
        let books = readStoreBooks()
        XCTAssertEqual(books.first?["lastLine"] as? String, "ある日の暮方の事である。")
        XCTAssertEqual(books.first?["page"] as? Int, 43)
    }

    func test_AC76_結果画面に前回ページからの遷移と分数が出て1タップで閉じる() {
        // (1) 前回 p.43 あり（「p.43 → p.61　18分」）
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 1080)
        element("reading.end").tap()
        element("mark.pageOnly").tap()
        let pageField1 = element("mark.pageField")
        XCTAssertTrue(pageField1.waitForExistence(timeout: uiTimeout))
        pageField1.tap()
        pageField1.typeText("61")
        element("mark.save").tap()

        XCTAssertEqual(readHookString("result.summary"), "p.43 → p.61　18分")
        element("result.close").tap()
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))

        // (2) 前回ページなし（「p.61　18分」）
        let noPageSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                author: "芥川龍之介",
                status: "current"
            )
        ])
        resetAndLaunch(seedJSON: noPageSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 1080)
        element("reading.end").tap()
        element("mark.pageOnly").tap()
        let pageField2 = element("mark.pageField")
        XCTAssertTrue(pageField2.waitForExistence(timeout: uiTimeout))
        pageField2.tap()
        pageField2.typeText("61")
        element("mark.save").tap()

        let summary2 = readHookString("result.summary")
        XCTAssertTrue(summary2.contains("p.61"))
        XCTAssertTrue(summary2.contains("18分"))
        XCTAssertFalse(summary2.contains("→"))
        element("result.close").tap()
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
    }

    func test_AC94_OCR待ちの間も1秒以内に手入力やページ入力に移り後から結果が返っても上書きされない() {
        let holdOcr = #"{"hold":true,"page":{"columns":["遅れて返る文字列"],"detectedPage":99}}"#

        // (1) mark.manual に移るケース
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", ocrJSON: holdOcr)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.photo").tap()

        let manualBtn = element("mark.manual")
        XCTAssertTrue(manualBtn.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(manualBtn.isEnabled)
        manualBtn.tap()

        let lineField = element("mark.lineField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        let state1 = readHookState()
        let rawWait1 = state1["lat.markWait"] ?? state1["prevLat.markWait"] ?? "9999"
        let markWaitMs1 = Double(rawWait1.split(separator: ",").first ?? "9999") ?? 9999.0
        XCTAssertLessThanOrEqual(markWaitMs1, 1000.0)

        lineField.tap()
        lineField.typeText("下人の")
        releaseOCR()

        XCTAssertEqual(readHookString("mark.lineField"), "下人の")
        XCTAssertEqual(matchingCount("mark.ocr.column.1"), 0)

        // (2) mark.pageOnly に移るケース
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", ocrJSON: holdOcr)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.photo").tap()

        let pageOnlyBtn = element("mark.pageOnly")
        XCTAssertTrue(pageOnlyBtn.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(pageOnlyBtn.isEnabled)
        pageOnlyBtn.tap()

        let pageField = element("mark.pageField")
        XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
        let state2 = readHookState()
        let rawWait2 = state2["lat.markWait"] ?? state2["prevLat.markWait"] ?? "9999"
        let markWaitMs2 = Double(rawWait2.split(separator: ",").first ?? "9999") ?? 9999.0
        XCTAssertLessThanOrEqual(markWaitMs2, 1000.0)

        pageField.tap()
        pageField.typeText("61")
        releaseOCR()

        XCTAssertEqual(readHookString("mark.pageField"), "61")
        XCTAssertEqual(matchingCount("mark.ocr.column.1"), 0)
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
        lineField.typeText("下人の行方は、誰も知らない。")
        let pageField = element("mark.pageField")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        XCTAssertTrue(element("common.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookString("mark.lineField"), "下人の行方は、誰も知らない。")
        XCTAssertEqual(readStoreRecords().count, 1)
        XCTAssertEqual(readStoreBooks().first?["lastLine"] as? String, "ある日の暮方の事である。")
        XCTAssertEqual(readStoreBooks().first?["page"] as? Int, 43)

        element("mark.save").tap()
        XCTAssertTrue(element("result.summary").waitForExistence(timeout: uiTimeout))
        let books = readStoreBooks()
        XCTAssertEqual(books.first?["lastLine"] as? String, "下人の行方は、誰も知らない。")
        XCTAssertEqual(books.first?["page"] as? Int, 61)
        XCTAssertEqual(readStoreRecords().count, 1)
    }

    func test_AC141_電子書籍の位置番号とパーセントのしおり保存と境界値を検証する() {
        // (1) location 1200 -> 1450
        let ebookLocSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                author: "芥川龍之介",
                status: "current",
                isEbook: true,
                progressUnit: "location",
                location: 1200
            )
        ])
        resetAndLaunch(
            seedJSON: ebookLocSeed,
            now: "2026-10-18T21:00:00+09:00",
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )
        element("bookmark.start").tap()
        advanceClock(seconds: 1080)
        element("reading.end").tap()
        element("mark.pageOnly").tap()

        let pageField1 = element("mark.pageField")
        XCTAssertTrue(pageField1.waitForExistence(timeout: uiTimeout))
        pageField1.tap()
        pageField1.typeText("1450")
        element("mark.save").tap()

        XCTAssertEqual(readHookString("result.summary"), "位置1200 → 位置1450　18分")
        element("result.close").tap()
        XCTAssertEqual(readHookString("bookmark.page"), "位置1450")
        XCTAssertTrue(readHookString("hook.widget").contains("位置1450"))
        relaunchPreservingStore()
        XCTAssertEqual(readStoreBooks().first?["location"] as? Int, 1450)

        // (2) percent 34 -> 52
        let ebookPctSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                author: "芥川龍之介",
                status: "current",
                isEbook: true,
                progressUnit: "percent",
                percent: 34
            )
        ])
        resetAndLaunch(
            seedJSON: ebookPctSeed,
            now: "2026-10-18T21:00:00+09:00",
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )
        element("bookmark.start").tap()
        advanceClock(seconds: 1080)
        element("reading.end").tap()
        element("mark.pageOnly").tap()

        let pageField2 = element("mark.pageField")
        XCTAssertTrue(pageField2.waitForExistence(timeout: uiTimeout))
        pageField2.tap()
        pageField2.typeText("52")
        element("mark.save").tap()

        XCTAssertEqual(readHookString("result.summary"), "34% → 52%　18分")
        element("result.close").tap()
        XCTAssertEqual(readHookString("bookmark.page"), "52%")
        XCTAssertTrue(readHookString("hook.widget").contains("52%"))
        relaunchPreservingStore()
        XCTAssertEqual(readStoreBooks().first?["percent"] as? Int, 52)

        // (3) 境界値（location 0 と 1000000、percent -1 と 101 で mark.page.invalid、percent 0 と 100 は保存される）
        for invalidLoc in ["0", "1000000"] {
            resetAndLaunch(seedJSON: ebookLocSeed, now: "2026-10-18T21:00:00+09:00")
            element("bookmark.setMark").tap()
            element("mark.pageOnly").tap()
            let pf = element("mark.pageField")
            XCTAssertTrue(pf.waitForExistence(timeout: uiTimeout))
            pf.tap()
            pf.typeText(invalidLoc)
            element("mark.save").tap()
            XCTAssertEqual(matchingCount("mark.page.invalid"), 1)
            XCTAssertEqual(readStoreBooks().first?["location"] as? Int, 1200)
        }

        for invalidPct in ["-1", "101"] {
            resetAndLaunch(seedJSON: ebookPctSeed, now: "2026-10-18T21:00:00+09:00")
            element("bookmark.setMark").tap()
            element("mark.pageOnly").tap()
            let pf = element("mark.pageField")
            XCTAssertTrue(pf.waitForExistence(timeout: uiTimeout))
            pf.tap()
            pf.typeText(invalidPct)
            element("mark.save").tap()
            XCTAssertEqual(matchingCount("mark.page.invalid"), 1)
            XCTAssertEqual(readStoreBooks().first?["percent"] as? Int, 34)
        }

        for validPct in [0, 100] {
            resetAndLaunch(seedJSON: ebookPctSeed, now: "2026-10-18T21:00:00+09:00")
            element("bookmark.setMark").tap()
            element("mark.pageOnly").tap()
            let pf = element("mark.pageField")
            XCTAssertTrue(pf.waitForExistence(timeout: uiTimeout))
            pf.tap()
            pf.typeText("\(validPct)")
            element("mark.save").tap()
            XCTAssertEqual(readStoreBooks().first?["percent"] as? Int, validPct)
            XCTAssertEqual(readHookString("bookmark.page"), "\(validPct)%")
        }
    }

    func test_AC142_カメラ拒否でもスクリーンショットから一行を選んで保存でき画像を残さない() {
        let ocrStub = #"{"page":{"columns":["列1","列2","列3","下人の行方は、誰も知らない。"],"detectedPage":null}}"#
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", camera: "denied", ocrJSON: ocrStub)
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.screenshot").tap()

        XCTAssertEqual(app.alerts.count, 0)
        let col4 = element("mark.ocr.column.4")
        XCTAssertTrue(col4.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(col4.isSelected)
        XCTAssertEqual(readHookString("mark.lineField"), "下人の行方は、誰も知らない。")

        let pageField = element("mark.pageField")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        let books = readStoreBooks()
        XCTAssertEqual(books.first?["lastLine"] as? String, "下人の行方は、誰も知らない。")
        XCTAssertEqual(books.first?["page"] as? Int, 61)
        let media = readHookJSON("hook.mediaAudit")
        XCTAssertEqual(media["savedImageFileCount"] as? Int, 0)
        XCTAssertEqual(media["photoLibraryWriteCount"] as? Int, 0)

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        XCTAssertEqual(booksAfter.first?["lastLine"] as? String, "下人の行方は、誰も知らない。")
        XCTAssertEqual(booksAfter.first?["page"] as? Int, 61)
    }
}
