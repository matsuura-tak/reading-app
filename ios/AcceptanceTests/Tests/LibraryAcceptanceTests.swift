import XCTest

/// S1 ホームと S2 本を追加（AC-1〜AC-4、AC-22）。期待する値は docs/verification/001-reading-session/test-plan.md の 2。
final class LibraryAcceptanceTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// AC-1：本が0冊、記録が0件で初めて開くと、空の状態の文言と library.addBook が1つだけ出て、読み始める操作は0個。
    @MainActor
    func test_AC1_emptyLibraryShowsEmptyStateAndOnlyAddBook() throws {
        let s = AppSession.launch(.fresh)
        Wait.label(s.el("library.empty.title"), equals: L10n.libraryEmptyTitle, "library.empty.title")
        Wait.label(s.el("library.empty.message"), equals: L10n.libraryEmptyMessage, "library.empty.message")
        XCTAssertEqual(s.count("library.addBook"), 1, "本を追加する操作は1つだけ")
        XCTAssertEqual(s.count("home.startReading"), 0, "home.startReading は0個")
        XCTAssertEqual(s.count("book.startReading"), 0, "book.startReading は0個")
        s.shot("AC1_空の状態", self)
    }

    /// AC-2：題名「坊っちゃん」だけで追加すると、一覧に1冊、詳細の最後のページは「0」、book.totalPages は0個。
    /// 保存の結果なので、終了して起動し直した後の一覧も見る。
    @MainActor
    func test_AC2_addBookWithTitleOnly() throws {
        let s = AppSession.launch(.fresh)
        s.tap("library.addBook")
        let title = s.el("book.add.title")
        Wait.exists(title, "book.add.title")
        title.tap()
        title.typeText(Fixture.botchan)
        XCTAssertEqual(s.fieldText("book.add.totalPages"), "", "前提：総ページ数は空のまま")
        s.tap("book.save")

        Wait.label(s.el("book.title"), equals: Fixture.botchan, "追加した本の詳細の題名")
        Wait.value(s.el("book.lastPage"), equals: "0", "最後のページ")
        XCTAssertEqual(s.count("book.totalPages"), 0, "総ページ数の表示は0個")
        s.shot("AC2_本の詳細", self)

        s.relaunch(now: Fixture.now)
        Wait.label(s.el("home.bookCount"), equals: L10n.bookCount(1), "一覧の冊数")
        XCTAssertEqual(s.bookRows().count, 1, "本の行は1つ")
        XCTAssertEqual(s.bookRows(titled: Fixture.botchan).count, 1, "「坊っちゃん」の行は1つ")
    }

    /// AC-3：題名が空か空白だけ（半角の空白、U+3000、改行、タブ、その組み合わせ）なら book.save は無効のままで、本は増えない。
    @MainActor
    func test_AC3_blankTitleCannotBeSaved() throws {
        // (入れる文字, 貼り付けで入れるか)。改行とタブは1行の欄にキーボードで入らないことがあるので貼り付ける（G0 r2）。
        let blanks: [(String, Bool)] = [
            ("", false),
            (" ", false),
            ("\u{3000}", false),
            ("\n", true),
            ("\t", true),
            (" \u{3000}\n\t", true),
            ("\u{3000}\t \r\n", true),
        ]
        let s = AppSession.launch(.fresh)
        for (index, (text, viaPaste)) in blanks.enumerated() {
            let name = "空白の例 \(index)（\(text.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " "))）"
            s.tap("library.addBook")
            let field = s.el("book.add.title")
            Wait.exists(field, "book.add.title")
            if viaPaste {
                s.paste(text, into: "book.add.title")
            } else if !text.isEmpty {
                field.tap()
                field.typeText(text)
                XCTAssertEqual(s.fieldText("book.add.title"), text, "前提：\(name) が欄に入った")
            }
            let save = s.el("book.save")
            Wait.exists(save, "book.save")
            XCTAssertFalse(save.isEnabled, "\(name)：book.save は無効")
            save.tap()
            XCTAssertFalse(save.isEnabled, "\(name)：押しても book.save は無効のまま")
            XCTAssertTrue(s.el("book.add.title").exists, "\(name)：保存されず、入力は開いたまま")
            s.cancelAddBook()
            Wait.exists(s.el("library.empty.title"), "\(name)：本は0冊のまま（空の状態）")
        }
        s.relaunch(now: Fixture.now)
        Wait.exists(s.el("library.empty.title"), "起動し直しても本は0冊")
        XCTAssertEqual(s.bookRows().count, 0, "本の行は0個")
    }

    /// AC-4：本が0冊から、題名の入力を除いて3回以下のタップで reading になり、題名は「坊っちゃん」。
    /// 題名の欄に入るタップとキーボードの操作は数えない（AC-4 の Then）。
    @MainActor
    func test_AC4_zeroBooksToReadingInThreeTapsOrFewer() throws {
        let s = AppSession.launch(.fresh)
        var taps = 0

        let add = s.el("library.addBook")
        Wait.exists(add, "library.addBook")
        add.tap()
        taps += 1

        let title = s.el("book.add.title")
        Wait.exists(title, "book.add.title")
        title.tap()  // 題名の入力に含める（数えない）
        title.typeText(Fixture.botchan)

        let save = s.el("book.save")
        Wait.exists(save, "book.save")
        save.tap()
        taps += 1

        let start = s.el("book.startReading")
        Wait.exists(start, "book.startReading")
        start.tap()
        taps += 1

        s.expectState(.reading)
        Wait.label(s.el("reading.title"), equals: Fixture.botchan, "読書中の本の題名")
        XCTAssertLessThanOrEqual(taps, 3, "題名の入力を除くタップの数")
        s.shot("AC4_読書中", self)
    }

    /// AC-22：本が20冊あるときに21冊目を追加しても、保存の後の画面にアラートとシートが0個で、一覧の本は21冊。
    @MainActor
    func test_AC22_twentyFirstBookHasNoLimitOrPaywall() throws {
        let books = (1...20).map { n in
            Fixture.book(n, String(format: "本 %02ld", n), totalPages: nil, lastPage: 0, addedAt: WallClock("2026-10-01T20:00:00").adding(minutes: n))
        }
        let s = AppSession.launch(.seeded(Seed(books: books)))
        Wait.label(s.el("home.bookCount"), equals: L10n.bookCount(20), "前提：本は20冊")

        s.addBook(title: Fixture.botchan)
        XCTAssertEqual(s.app.alerts.count, 0, "保存の後のアラート")
        XCTAssertEqual(s.app.sheets.count, 0, "保存の後のシート")
        XCTAssertEqual(s.count("book.add.title"), 0, "本を追加するシートは閉じた")
        let primary = s.el("book.startReading")
        Wait.exists(primary, "保存の後の画面の主操作（book.startReading）")
        XCTAssertTrue(primary.isHittable, "保存の後の画面の主操作が押せる（design 6 の保存の後の画面の目印）")
        s.shot("AC22_21冊目の後", self)

        s.goBack()
        Wait.label(s.el("home.bookCount"), equals: L10n.bookCount(21), "一覧の冊数")
    }
}
