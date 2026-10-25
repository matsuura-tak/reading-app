import XCTest

final class FirstLaunchTests: AcceptanceTestBase {
    func test_AC1_初回起動で空のしおり画面が出て許可ダイアログが出ない() {
        resetAndLaunch(camera: "notDetermined:granted")

        XCTAssertTrue(element("bookmark.empty.message").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("bookmark.addBook").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("bookmark.start"), 0)
        XCTAssertEqual(app.alerts.count, 0)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertEqual(springboard.alerts.count, 0)

        let stateStr = readHookString("hook.state")
        XCTAssertTrue(stateStr.contains("state=idle") || stateStr.contains("\"state\":\"idle\""))

        let books = readStoreBooks()
        XCTAssertEqual(books.count, 0)

        attachScreenshot(name: "AC-1_first_launch")
    }
}
