import UIKit
import XCTest

/// 待ち方。sleep は使わず、要素や値の変化を XCTNSPredicateExpectation（A27）と waitForExistence で待つ。
/// 待ち時間はこの型の定数だけ。
@MainActor
enum Wait {
    /// 画面の変化を待つ上限。
    static let timeout: TimeInterval = 10
    /// 決まっていない画面の動き（design/ が決めていない確認の有無など）を見分けるための短い上限。
    static let optional: TimeInterval = 2
    /// 計測の送り終わり（T13、T22）を待つ上限。応答しない受け口は UITEST_TELEMETRY_TIMEOUT 秒ずつ待つ。
    static let telemetry: TimeInterval = 60

    @discardableResult
    static func until(_ predicate: NSPredicate, _ object: Any?, timeout: TimeInterval = timeout) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: object)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    static func exists(
        _ element: XCUIElement, _ what: String, timeout: TimeInterval = timeout,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(what) が出ない", file: file, line: line)
    }

    static func gone(_ element: XCUIElement, _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(until(NSPredicate(format: "exists == false"), element), "\(what) が消えない", file: file, line: line)
    }

    static func label(
        _ element: XCUIElement, equals expected: String, _ what: String,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        if !until(NSPredicate(format: "label == %@", expected), element) {
            XCTFail("\(what)：label が「\(expected)」にならない（今は「\(currentLabel(element))」）", file: file, line: line)
        }
    }

    static func label(
        _ element: XCUIElement, in expected: [String], _ what: String,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        if !until(NSPredicate(format: "label IN %@", expected), element) {
            XCTFail("\(what)：label が \(expected) のどれにもならない（今は「\(currentLabel(element))」）", file: file, line: line)
        }
    }

    static func value(
        _ element: XCUIElement, equals expected: String, _ what: String,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        if !until(NSPredicate(format: "value == %@", expected), element) {
            let now = element.exists ? String(describing: element.value ?? "nil") : "要素なし"
            XCTFail("\(what)：value が「\(expected)」にならない（今は「\(now)」）", file: file, line: line)
        }
    }

    private static func currentLabel(_ element: XCUIElement) -> String {
        element.exists ? element.label : "要素なし"
    }
}

/// 状態の名前（T8。design 6 の session.state.*）。
enum SessionState: String, CaseIterable {
    case idle, reading, paused, finishing
}

/// 要素は design/ の 6 の accessibilityIdentifier で探す。
@MainActor
extension AppSession {
    func el(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    func count(_ id: String) -> Int {
        app.descendants(matching: .any).matching(identifier: id).count
    }

    /// 識別子が prefix で始まる要素（library.book.、session.row.id.、error. など）。
    func elements(prefixed prefix: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
    }

    /// システムが作る部品（alert のボタン、確認のダイアログ、スワイプの削除）。識別子か、design 7 の文字で探す（design 6 の (b)）。
    func systemButton(id: String, text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier == %@ OR label == %@", id, text)).firstMatch
    }

    func tap(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        let element = el(id)
        Wait.exists(element, id, file: file, line: line)
        element.tap()
    }

    func fieldText(_ id: String) -> String {
        (el(id).value as? String) ?? ""
    }

    /// 欄の文字を全部消してから入れる（欄の右端をタップして、カーソルを末尾に置く）。
    func replaceText(_ id: String, with text: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = el(id)
        Wait.exists(field, id, file: file, line: line)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        let current = fieldText(id)
        if !current.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        if !text.isEmpty { field.typeText(text) }
    }

    /// 改行とタブを1行の欄に入れるため、貼り付けで入れる（G0 r2 の AC-3 の条件）。編集メニューの「ペースト」はシステムの文字で探す。
    func paste(_ text: String, into id: String, file: StaticString = #filePath, line: UInt = #line) {
        UIPasteboard.general.string = text
        let field = el(id)
        Wait.exists(field, id, file: file, line: line)
        field.tap()
        field.press(forDuration: 1.2)
        let item = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", L10n.systemPaste)).firstMatch
        Wait.exists(item, "編集メニューの「\(L10n.systemPaste)」", file: file, line: line)
        item.tap()
    }

    /// 状態が name であること（ほかの3つの session.state.* は消える）。
    func expectState(_ state: SessionState, file: StaticString = #filePath, line: UInt = #line) {
        Wait.exists(el("session.state.\(state.rawValue)"), "session.state.\(state.rawValue)", file: file, line: line)
        for other in SessionState.allCases where other != state {
            Wait.gone(el("session.state.\(other.rawValue)"), "session.state.\(other.rawValue)", file: file, line: line)
        }
    }

    /// アラートとシートが0個、識別子が error. で始まる要素が0個（AC-20、AC-22 の Then）。
    func expectNoAlertSheetOrError(_ step: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(app.alerts.count, 0, "\(step)：アラート", file: file, line: line)
        XCTAssertEqual(app.sheets.count, 0, "\(step)：シート", file: file, line: line)
        XCTAssertEqual(elements(prefixed: "error.").count, 0, "\(step)：error. で始まる要素", file: file, line: line)
    }

    // MARK: 画面の移り方（design/ の 1 の流れ）

    /// 戻るボタン（システムの部品。design 6 の (b) により文字で探す）。
    func goBack(file: StaticString = #filePath, line: UInt = #line) {
        let back = app.navigationBars.buttons.matching(NSPredicate(format: "label IN %@", L10n.backButtonLabels)).firstMatch
        Wait.exists(back, "戻るボタン", file: file, line: line)
        back.tap()
    }

    /// S1 の本の行（library.book.<小文字の UUID>）から S3 を開く。
    func openBook(id: String, file: StaticString = #filePath, line: UInt = #line) {
        tap("library.book.\(id)", file: file, line: line)
        Wait.exists(el("book.title"), "book.title", file: file, line: line)
    }

    /// S1 の本の行（題名が title のもの）から S3 を開く。UI で追加した本は UUID を知らないので、label で選ぶ。
    func openBook(titled title: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = bookRows(titled: title).firstMatch
        Wait.exists(row, "本の行「\(title)」", file: file, line: line)
        row.tap()
        Wait.label(el("book.title"), equals: title, "book.title", file: file, line: line)
    }

    func bookRows(titled title: String? = nil) -> XCUIElementQuery {
        guard let title else { return elements(prefixed: "library.book.") }
        return app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND label == %@", "library.book.", title))
    }

    /// S4 か S5 から、その本の S3 へ行く（確かめの最後の手順で使う。S5 なら「キャンセル」で reading に戻してから）。
    func goToBookDetail(id: String, file: StaticString = #filePath, line: UInt = #line) {
        if el("session.finish.cancel").exists {
            tap("session.finish.cancel", file: file, line: line)
            Wait.gone(el("session.finish.save"), "session.finish.save", file: file, line: line)
        }
        if el("reading.title").exists {
            goBack(file: file, line: line)
        }
        openBook(id: id, file: file, line: line)
    }

    /// S2 を開いて題名（と総ページ数）を入れ、「追加」を押す。追加した本の S3 が出るまで待つ（AC-49）。
    func addBook(title: String, totalPages: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        tap("library.addBook", file: file, line: line)
        let field = el("book.add.title")
        Wait.exists(field, "book.add.title", file: file, line: line)
        field.tap()
        field.typeText(title)
        if let totalPages {
            let pages = el("book.add.totalPages")
            pages.tap()
            pages.typeText(totalPages)
        }
        tap("book.save", file: file, line: line)
        Wait.label(el("book.title"), equals: title, "追加した本の詳細", file: file, line: line)
    }

    /// S2 を「キャンセル」で閉じる。入力があれば出る確認（book.add.discard.confirm）で追加せずに閉じる。
    /// 空白だけの入力で確認が出るかは design/ が決めていないので、出たときだけ押す。
    func cancelAddBook(file: StaticString = #filePath, line: UInt = #line) {
        tap("book.add.cancel", file: file, line: line)
        let confirm = systemButton(id: "book.add.discard.confirm", text: L10n.bookAddDiscardConfirm)
        if confirm.waitForExistence(timeout: Wait.optional) { confirm.tap() }
        Wait.gone(el("book.add.title"), "book.add.title", file: file, line: line)
    }

    /// S4 で「終える」を押し、S5 で今のページと分を入れて保存する。保存の後はその本の S3（AC-50）。
    func finishAndSave(
        title: String, page: String? = nil, minutes: String? = nil,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        tap("reading.finish", file: file, line: line)
        Wait.exists(el("session.finish.save"), "session.finish.save", file: file, line: line)
        if let page { replaceText("session.finish.page", with: page, file: file, line: line) }
        if let minutes { replaceText("session.finish.minutes", with: minutes, file: file, line: line) }
        tap("session.finish.save", file: file, line: line)
        Wait.label(el("book.title"), equals: title, "保存の後の本の詳細", file: file, line: line)
    }

    /// S3 の記録の行のうち、seed で入れていない行（新しい記録）。
    func newSessionRows(excluding seeded: [String]) -> [XCUIElement] {
        let known = Set(seeded.map { "session.row.id.\($0)" })
        let rows = elements(prefixed: "session.row.id.")
        Wait.exists(rows.firstMatch, "記録の行")
        return rows.allElementsBoundByIndex.filter { !known.contains($0.identifier) }
    }

    /// 1件だけの新しい記録の行。
    func singleNewSessionRow(excluding seeded: [String], file: StaticString = #filePath, line: UInt = #line) -> XCUIElement? {
        let rows = newSessionRows(excluding: seeded)
        XCTAssertEqual(rows.count, 1, "新しい記録の行は1つ", file: file, line: line)
        return rows.first
    }
}

// MARK: 後半（AC-31〜AC-67）で足した部品

@MainActor
extension Wait {
    /// isEnabled が expected になるのを待つ（AC-31、AC-37、AC-52。押せるかの変化は入力の後に遅れて来ることがある）。
    static func enabled(
        _ element: XCUIElement, _ expected: Bool, _ what: String,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "exists == true AND isEnabled == %@", NSNumber(value: expected))
        if !until(predicate, element) {
            let now = element.exists ? String(element.isEnabled) : "要素なし"
            XCTFail("\(what)：isEnabled が \(expected) にならない（今は \(now)）", file: file, line: line)
        }
    }
}

@MainActor
extension AppSession {
    /// 保存の失敗の区画（design 6：題 error.saveFailed と、再試行 error.retry）が1個ずつ出ていること（AC-42、AC-56〜AC-66 の Then）。
    func expectSaveFailed(_ step: String, file: StaticString = #filePath, line: UInt = #line) {
        Wait.label(el("error.saveFailed"), equals: L10n.errorSaveFailed, "\(step)：error.saveFailed", file: file, line: line)
        Wait.exists(el("error.retry"), "\(step)：error.retry", file: file, line: line)
        XCTAssertEqual(count("error.saveFailed"), 1, "\(step)：error.saveFailed は1個", file: file, line: line)
        XCTAssertEqual(count("error.retry"), 1, "\(step)：error.retry は1個", file: file, line: line)
    }

    /// 保存の失敗の区画が消えたこと（再試行が通った後。AC-35、AC-57〜AC-65、AC-67 の「error.saveFailed は0個」）。
    func expectNoSaveFailed(_ step: String, file: StaticString = #filePath, line: UInt = #line) {
        Wait.gone(el("error.saveFailed"), "\(step)：error.saveFailed", file: file, line: line)
        XCTAssertEqual(count("error.saveFailed"), 0, "\(step)：error.saveFailed は0個", file: file, line: line)
    }

    /// S4 か S5 から本の S3 へ行き、記録の数を見る（test-plan 2 の「件数を見る」。AppSession.goToBookDetail を使う）。
    func expectSessionCount(
        _ n: Int, bookId: String, _ step: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        goToBookDetail(id: bookId, file: file, line: line)
        Wait.label(el("book.sessionCount"), equals: L10n.sessionCount(n), "\(step)：book.sessionCount", file: file, line: line)
    }

    /// S3 の記録の行をスワイプして「削除」を押し、S6 を開く（AC-38、AC-43）。システムの部品は識別子か 7 の文字で探す（design 6 の (b)）。
    func beginDeleteSession(id: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = el("session.row.id.\(id)")
        Wait.exists(row, "記録の行 \(id)", file: file, line: line)
        row.swipeLeft()
        let delete = systemButton(id: "session.row.delete", text: L10n.sessionRowDelete)
        Wait.exists(delete, "行の「削除」", file: file, line: line)
        delete.tap()
    }
}

@MainActor
extension AppSession {
    /// S1 > S3 > S4 の S4 から S3 へ戻る（AC-57。design 1 の S3 からの読み始め）。戻るボタンの文字は S3 のナビゲーションバーの題名
    /// （本の題名。design 5 の長い題名）か、システムの「戻る」。システムの部品なので文字で探す（design 6 の (b)）。
    func goBack(toBookTitled title: String, file: StaticString = #filePath, line: UInt = #line) {
        let labels = [title] + L10n.backButtonLabels
        let back = app.navigationBars.buttons.matching(NSPredicate(format: "label IN %@", labels)).firstMatch
        Wait.exists(back, "S3 への戻るボタン", file: file, line: line)
        back.tap()
        Wait.label(el("book.title"), equals: title, "戻った本の詳細", file: file, line: line)
    }
}
