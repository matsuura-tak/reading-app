import XCTest

final class PerformanceTests: AcceptanceTestBase {

    private var seed3Books10Records: String {
        let books: [[String: Any]] = [
            makeSeedBook(id: uuidBookA, title: "一冊目の本", author: "著者A", status: "current", page: 45),
            makeSeedBook(id: uuidBookB, title: "二冊目の本", author: "著者B", status: "tsundoku"),
            makeSeedBook(id: uuidBookC, title: "三冊目の本", author: "著者C", status: "finished")
        ]
        let records: [[String: Any]] = (1...10).map { idx in
            let day = String(format: "%02d", idx)
            return makeSeedRecord(
                id: String(format: "00000000-0000-4000-9000-%012d", idx),
                bookId: uuidBookA,
                startedAt: "2026-10-\(day)T21:00:00+09:00",
                endedAt: "2026-10-\(day)T21:15:00+09:00",
                minutes: 15,
                nightDate: "2026-10-\(day)"
            )
        }
        return makeSeedJSON(books: books, records: records)
    }

    private var ndlStubJSON: String {
        return """
        {
          "stubVersion": 1,
          "status": "ready",
          "books": [
            {
              "isbn": "9784101000015",
              "title": "こころ",
              "author": "夏目漱石",
              "publisher": "新潮社",
              "label": "新潮文庫",
              "publishedYear": 2004,
              "ndc": "913.6"
            },
            {
              "isbn": "9784101000046",
              "title": "人間失格",
              "author": "太宰治",
              "publisher": "新潮社",
              "label": "新潮文庫",
              "publishedYear": 1952,
              "ndc": "913.6"
            }
          ],
          "cooccurrences": []
        }
        """
    }

    // MARK: - AC-100: コールド起動から「しおり」画面操作可能まで5回平均1.0秒以内
    func test_AC100_本3冊記録10件での起動から操作可能までの平均が1秒以内() {
        var totalLaunchMs: Double = 0
        for _ in 0..<5 {
            let start = Date()
            resetAndLaunch(seedJSON: seed3Books10Records)
            XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
            let elapsedMs = Date().timeIntervalSince(start) * 1000.0
            totalLaunchMs += elapsedMs
            app.terminate()
        }
        XCTAssertLessThanOrEqual(totalLaunchMs / 5.0, 1000.0)

        let options = XCTMeasureOptions()
        options.iterationCount = 5
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)], options: options) {
            resetAndLaunch(seedJSON: seed3Books10Records)
            XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
        }
    }

    // MARK: - AC-101: 500冊と5,000件で本棚と1冊の画面表示がそれぞれ1.0秒以内（5回平均）
    func test_AC101_本500冊記録5000件での本棚と本の画面の表示平均が1秒以内() {
        resetAndLaunch(extraArgs: ["-uitest-seed-preset", "perf500"])
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))

        var shelfTotalMs: Double = 0
        var bookTotalMs: Double = 0

        for _ in 0..<5 {
            element("toolbar.shelf").tap()
            let rowA = element("shelf.row.\(uuidBookA)")
            XCTAssertTrue(rowA.waitForExistence(timeout: uiTimeout))
            let stateAfterShelf = readHookState()
            let shelfMsStr = (stateAfterShelf["lat.shelfOpen"] ?? stateAfterShelf["prevLat.shelfOpen"] ?? "9999").split(separator: ",").last.map(String.init) ?? "9999"
            let shelfMs = Double(shelfMsStr) ?? 9999.0
            shelfTotalMs += shelfMs

            rowA.tap()
            XCTAssertTrue(element("book.colophon").waitForExistence(timeout: uiTimeout))
            let stateAfterBook = readHookState()
            let bookMsStr = (stateAfterBook["lat.bookOpen"] ?? stateAfterBook["prevLat.bookOpen"] ?? "9999").split(separator: ",").last.map(String.init) ?? "9999"
            let bookMs = Double(bookMsStr) ?? 9999.0
            bookTotalMs += bookMs

            navigateBackToBookmark()
            if !element("bookmark.start").exists {
                navigateBackToBookmark()
            }
            XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
        }

        XCTAssertLessThanOrEqual(shelfTotalMs / 5.0, 1000.0)
        XCTAssertLessThanOrEqual(bookTotalMs / 5.0, 1000.0)
    }

    // MARK: - AC-102: ロック画面とホーム画面の小ウィジェットのタイムライン生成平均0.5秒以内
    func test_AC102_ウィジェット2種類のタイムライン生成平均が500ミリ秒以内() {
        var lockTotalMs: Double = 0
        var smallTotalMs: Double = 0

        for _ in 0..<5 {
            resetAndLaunch(
                seedJSON: seed3Books10Records,
                extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"]
            )
            XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
            let widgetHook = readHookJSON("hook.widget")
            let renders = widgetHook["renders"] as? [[String: Any]] ?? []

            let lockRender = renders.first {
                (($0["request"] as? [String: Any])?["family"] as? String) == "accessoryRectangular"
            }
            let lockTimeline = lockRender?["timeline"] as? [String: Any]
            let lockMs = lockTimeline?["elapsedMs"] as? Double ?? 9999.0

            let smallRender = renders.first {
                (($0["request"] as? [String: Any])?["family"] as? String) == "systemSmall"
            }
            let smallTimeline = smallRender?["timeline"] as? [String: Any]
            let smallMs = smallTimeline?["elapsedMs"] as? Double ?? 9999.0

            lockTotalMs += lockMs
            smallTotalMs += smallMs
            app.terminate()
        }

        XCTAssertLessThanOrEqual(lockTotalMs / 5.0, 500.0)
        XCTAssertLessThanOrEqual(smallTotalMs / 5.0, 500.0)
    }

    // MARK: - AC-149: 端末内書誌DBでのISBN検索と書名検索の5回平均0.3秒以内
    func test_AC149_端末内書誌DBのISBN検索と書名検索の5回平均が300ミリ秒以内() {
        resetAndLaunch(ndlStubJSON: ndlStubJSON)
        XCTAssertTrue(element("bookmark.addBook").waitForExistence(timeout: uiTimeout))

        var isbnTotalMs: Double = 0
        var searchTotalMs: Double = 0

        for _ in 0..<5 {
            element("bookmark.addBook").tap()
            let barcodeBtn = element("register.barcode")
            XCTAssertTrue(barcodeBtn.waitForExistence(timeout: uiTimeout))
            barcodeBtn.tap()

            sendBarcode("9784101000015")
            XCTAssertTrue(element("scan.row.9784101000015").waitForExistence(timeout: uiTimeout))
            let stateAfterIsbn = readHookState()
            let isbnMsStr = (stateAfterIsbn["lat.barcodeLookup"] ?? stateAfterIsbn["prevLat.barcodeLookup"] ?? "9999").split(separator: ",").last.map(String.init) ?? "9999"
            let isbnMs = Double(isbnMsStr) ?? 9999.0
            isbnTotalMs += isbnMs

            element("scan.cancel").tap()
            let discardBtn = element("scan.discard.confirmButton")
            if discardBtn.waitForExistence(timeout: uiTimeout) {
                discardBtn.tap()
            }
            let regCancel1 = element("register.cancel")
            if regCancel1.waitForExistence(timeout: uiTimeout) {
                regCancel1.tap()
            }

            element("bookmark.addBook").tap()
            let manualBtn = element("register.manual")
            XCTAssertTrue(manualBtn.waitForExistence(timeout: uiTimeout))
            manualBtn.tap()

            let queryField = element("manual.title")
            XCTAssertTrue(queryField.waitForExistence(timeout: uiTimeout))
            queryField.tap()
            queryField.typeText("人間失格")
            XCTAssertTrue(element("search.row.9784101000046").waitForExistence(timeout: uiTimeout))
            let stateAfterSearch = readHookState()
            let searchMsStr = (stateAfterSearch["lat.titleSearch"] ?? stateAfterSearch["prevLat.titleSearch"] ?? "9999").split(separator: ",").last.map(String.init) ?? "9999"
            let searchMs = Double(searchMsStr) ?? 9999.0
            searchTotalMs += searchMs

            element("manual.cancel").tap()
            let regCancel2 = element("register.cancel")
            if regCancel2.waitForExistence(timeout: uiTimeout) {
                regCancel2.tap()
            }
        }

        XCTAssertLessThanOrEqual(isbnTotalMs / 5.0, 300.0)
        XCTAssertLessThanOrEqual(searchTotalMs / 5.0, 300.0)
    }
}
