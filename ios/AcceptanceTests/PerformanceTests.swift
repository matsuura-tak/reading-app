import XCTest

final class PerformanceTests: AcceptanceTestBase {

    func test_AC100_本3冊記録10件での起動から操作可能までの平均が1秒以内() {
        let seed3Books10Records = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current","savedLine":"ある日の暮方の事である。","savedPage":43},{"id":"book-b","title":"銀河鉄道の夜","author":"宮沢賢治","status":"tsundoku"},{"id":"book-c","title":"こころ","author":"夏目漱石","status":"finished"}],"records":[{"id":"r1","bookID":"book-a","nightDate":"2026-10-09","minutes":15},{"id":"r2","bookID":"book-a","nightDate":"2026-10-10","minutes":20},{"id":"r3","bookID":"book-a","nightDate":"2026-10-11","minutes":25},{"id":"r4","bookID":"book-a","nightDate":"2026-10-12","minutes":30},{"id":"r5","bookID":"book-a","nightDate":"2026-10-13","minutes":15},{"id":"r6","bookID":"book-a","nightDate":"2026-10-14","minutes":20},{"id":"r7","bookID":"book-c","nightDate":"2026-10-15","minutes":35},{"id":"r8","bookID":"book-c","nightDate":"2026-10-16","minutes":40},{"id":"r9","bookID":"book-c","nightDate":"2026-10-17","minutes":25},{"id":"r10","bookID":"book-a","nightDate":"2026-10-18","minutes":18}]}"#
        var totalLaunchMs = 0.0
        for _ in 0..<5 {
            resetAndLaunch(seedJSON: seed3Books10Records, now: "2026-10-18T21:00:00+09:00")
            XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
            let perf = readHookJSON("hook.perf")
            totalLaunchMs += (perf["launchResponsiveMs"] as? Double ?? 9999.0)
        }
        let averageLaunchMs = totalLaunchMs / 5.0
        XCTAssertLessThanOrEqual(averageLaunchMs, 1000.0)
    }

    func test_AC101_本500冊記録5000件での本棚と本の画面の表示平均が1秒以内() {
        resetAndLaunch(now: "2026-10-18T21:00:00+09:00", extraArgs: ["-uitest-seed-preset", "perf500"])
        var totalShelfOpenMs = 0.0
        var totalBookOpenMs = 0.0

        for _ in 0..<5 {
            element("tab.shelf").tap()
            let row = element("shelf.row.book-a")
            XCTAssertTrue(row.waitForExistence(timeout: uiTimeout))
            totalShelfOpenMs += (readHookJSON("hook.perf")["shelfOpen"] as? Double ?? 9999.0)

            row.tap()
            XCTAssertTrue(element("colophon.title").waitForExistence(timeout: uiTimeout))
            totalBookOpenMs += (readHookJSON("hook.perf")["bookOpen"] as? Double ?? 9999.0)

            element("tab.bookmark").tap()
        }

        XCTAssertLessThanOrEqual(totalShelfOpenMs / 5.0, 1000.0)
        XCTAssertLessThanOrEqual(totalBookOpenMs / 5.0, 1000.0)
    }

    func test_AC102_ウィジェット2種類のタイムライン生成平均が500ミリ秒以内() {
        let seed25Chars = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current","savedLine":"ある日の暮方の事である。一人の下人が、羅生門の下で","savedPage":61}],"records":[]}"#
        resetAndLaunch(seedJSON: seed25Chars, now: "2026-10-18T21:00:00+09:00")

        let widgetHook = readHookJSON("hook.widgets")
        let rectAvgMs = widgetHook["accessoryRectangularAvgMs"] as? Double ?? 9999.0
        let smallAvgMs = widgetHook["systemSmallAvgMs"] as? Double ?? 9999.0
        XCTAssertLessThanOrEqual(rectAvgMs, 500.0)
        XCTAssertLessThanOrEqual(smallAvgMs, 500.0)
    }

    func test_AC149_端末内書誌DBのISBN検索と書名検索の5回平均が300ミリ秒以内() {
        resetAndLaunch(seedJSON: #"{"books":[],"records":[]}"#, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.addBook").tap()

        var barcodeTotalMs = 0.0
        var titleSearchTotalMs = 0.0

        for _ in 0..<5 {
            sendBarcode("9784101010014")
            XCTAssertTrue(element("scan.row.9784101010014").waitForExistence(timeout: uiTimeout))
            barcodeTotalMs += (readHookJSON("hook.perf")["barcodeLookup"] as? Double ?? 9999.0)
        }

        element("register.manual").tap()
        let titleField = element("manual.title")
        XCTAssertTrue(titleField.waitForExistence(timeout: uiTimeout))

        for _ in 0..<5 {
            titleField.tap()
            titleField.typeText("人間失格")
            XCTAssertTrue(element("search.row.0").waitForExistence(timeout: uiTimeout))
            titleSearchTotalMs += (readHookJSON("hook.perf")["titleSearch"] as? Double ?? 9999.0)
        }

        XCTAssertLessThanOrEqual(barcodeTotalMs / 5.0, 300.0)
        XCTAssertLessThanOrEqual(titleSearchTotalMs / 5.0, 300.0)
    }
}
