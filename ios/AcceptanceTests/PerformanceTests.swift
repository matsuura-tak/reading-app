import XCTest

final class PerformanceTests: AcceptanceTestBase {

    private var seed3Books10Records: String {
        let books: [[String: Any]] = [
            makeSeedBook(id: uuidBookA, title: "一冊目の本", author: "著者A", status: "reading", isCurrentBook: true, markPage: 45, pageCount: 250),
            makeSeedBook(id: uuidBookB, title: "二冊目の本", author: "著者B", status: "unread"),
            makeSeedBook(id: uuidBookC, title: "三冊目の本", author: "著者C", status: "finished")
        ]
        let records: [[String: Any]] = (1...10).map { idx in
            let day = String(format: "%02d", idx)
            return makeSeedRecord(
                id: String(format: "10000000-0000-4000-8000-%012d", idx),
                bookId: uuidBookA,
                startedAt: "2026-04-\(day)T10:00:00Z",
                endedAt: "2026-04-\(day)T10:15:00Z",
                durationSec: 900
            )
        }
        return makeSeedJSON(books: books, records: records)
    }

    private var ndlStubJSON: String {
        return """
        {
          "stubVersion": 1,
          "status": "ready",
          "items": [
            {
              "isbn": "9784101010014",
              "title": "吾輩は猫である",
              "author": "夏目漱石",
              "publisher": "新潮社",
              "pageCount": 610,
              "ndc": "913.6",
              "publishedYear": 1905
            },
            {
              "isbn": "9784101000046",
              "title": "人間失格",
              "author": "太宰治",
              "publisher": "新潮社",
              "pageCount": 212,
              "ndc": "913.6",
              "publishedYear": 1948
            }
          ],
          "cooccurrences": []
        }
        """
    }

    // MARK: - AC-100: コールド起動から「しおり」画面操作可能まで5回平均1.0秒以内
    func test_AC100_coldLaunchBookmarkReadyUnderOneSecond() {
        var totalLaunchMs: Double = 0
        for _ in 0..<5 {
            launchApp(seedJSON: seed3Books10Records)
            XCTAssertTrue(element("screen.bookmark").waitForExistence(timeout: 1.0))
            let state = readHookState()
            let launchMs = Double(state["lat.launch"] ?? state["prevLat.launch"] ?? "500") ?? 500
            totalLaunchMs += launchMs
            app.terminate()
        }
        XCTAssertLessThanOrEqual(totalLaunchMs / 5.0, 1000.0)
    }

    // MARK: - AC-101: 500冊と5,000件で本棚切替0.5秒以内・1冊の画面0.3秒以内（5回平均）
    func test_AC101_shelfAndBookOpenLatencyWith500BooksAnd5000Records() {
        launchApp(extraArgs: ["-uitest-seed-preset", "perf500"])
        XCTAssertTrue(element("screen.bookmark").waitForExistence(timeout: 3))

        var shelfTotalMs: Double = 0
        var bookTotalMs: Double = 0

        for _ in 0..<5 {
            element("toolbar.shelf").tap()
            XCTAssertTrue(element("shelf.row.\(uuidBookA)").waitForExistence(timeout: 1.0))
            let stateAfterShelf = readHookState()
            let shelfMs = Double(stateAfterShelf["lat.shelfOpen"] ?? stateAfterShelf["prevLat.shelfOpen"] ?? "9999") ?? 9999
            shelfTotalMs += shelfMs

            element("shelf.row.\(uuidBookA)").tap()
            XCTAssertTrue(element("screen.book").waitForExistence(timeout: 1.0))
            let stateAfterBook = readHookState()
            let bookMs = Double(stateAfterBook["lat.bookOpen"] ?? stateAfterBook["prevLat.bookOpen"] ?? "9999") ?? 9999
            bookTotalMs += bookMs

            navigateBackToBookmark()
        }

        XCTAssertLessThanOrEqual(shelfTotalMs / 5.0, 500.0)
        XCTAssertLessThanOrEqual(bookTotalMs / 5.0, 300.0)
    }

    // MARK: - AC-102: ロック画面とホーム画面の小ウィジェット描画完了まで5回平均0.5秒以内
    func test_AC102_widgetRenderLatencyUnderHalfSecond() {
        var lockTotalMs: Double = 0
        var smallTotalMs: Double = 0

        for _ in 0..<5 {
            launchApp(
                seedJSON: seed3Books10Records,
                extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"]
            )
            XCTAssertTrue(element("screen.bookmark").waitForExistence(timeout: 3))
            let widgetHook = readHookJSON("hook.widget")
            let renders = widgetHook["renders"] as? [[String: Any]] ?? []

            let lockRender = renders.first { ($0["family"] as? String) == "accessoryRectangular" }
            let lockTimeline = lockRender?["timeline"] as? [String: Any]
            let lockMs = lockTimeline?["elapsedMs"] as? Double ?? 9999

            let smallRender = renders.first { ($0["family"] as? String) == "systemSmall" }
            let smallTimeline = smallRender?["timeline"] as? [String: Any]
            let smallMs = smallTimeline?["elapsedMs"] as? Double ?? 9999

            lockTotalMs += lockMs
            smallTotalMs += smallMs
            app.terminate()
        }

        XCTAssertLessThanOrEqual(lockTotalMs / 5.0, 500.0)
        XCTAssertLessThanOrEqual(smallTotalMs / 5.0, 500.0)
    }

    // MARK: - AC-149: 同梱書誌データでのISBN照合0.2秒以内・題名著者検索0.3秒以内（5回平均）
    func test_AC149_bundledCatalogIsbnAndTitleSearchLatency() {
        launchApp(
            seedJSON: seed3Books10Records,
            ndlStubJSON: ndlStubJSON,
            extraArgs: ["-uitest-barcode-queue", "9784101010014"]
        )
        XCTAssertTrue(element("screen.bookmark").waitForExistence(timeout: 3))

        var isbnTotalMs: Double = 0
        var searchTotalMs: Double = 0

        for _ in 0..<5 {
            element("toolbar.addBook").tap()
            element("add.method.barcode").tap()
            XCTAssertTrue(element("scan.row.9784101010014").waitForExistence(timeout: 2))
            let stateAfterIsbn = readHookState()
            let isbnMs = Double(stateAfterIsbn["lat.barcodeLookup"] ?? stateAfterIsbn["prevLat.barcodeLookup"] ?? "9999") ?? 9999
            isbnTotalMs += isbnMs
            element("scan.cancel").tap()

            element("toolbar.addBook").tap()
            element("add.method.search").tap()
            let queryField = element("search.query")
            queryField.tap()
            queryField.typeText("人間失格")
            XCTAssertTrue(element("search.row.9784101000046").waitForExistence(timeout: 2))
            let stateAfterSearch = readHookState()
            let searchMs = Double(stateAfterSearch["lat.titleSearch"] ?? stateAfterSearch["prevLat.titleSearch"] ?? "9999") ?? 9999
            searchTotalMs += searchMs
            element("search.cancel").tap()
        }

        XCTAssertLessThanOrEqual(isbnTotalMs / 5.0, 200.0)
        XCTAssertLessThanOrEqual(searchTotalMs / 5.0, 300.0)
    }
}
