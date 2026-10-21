import XCTest

/// S2 本を追加：総ページ数の範囲、保存の失敗、保存の後の画面、追加をやめる（AC-31、AC-42、AC-49、AC-53）。
/// 期待する値は docs/verification/001-reading-session/test-plan.md の 2。文字は design/ の 7（Support/L10n.swift）。
final class AddBookAcceptanceTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 本が「坊っちゃん」1冊だけ（記録0件。AC-42、AC-53 の Given「本が1冊」）。
    private var oneBook: Seed {
        Seed(books: [Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 0)])
    }

    // MARK: AC-31

    /// AC-31：題名「坊っちゃん」で、総ページ数が 0 と 10000 なら book.save は無効で book.add.totalPagesOutOfRange
    /// （「1から9999までの数字で入れてください。」）が出る。1 と 9999 では book.save は有効。本の数は変わらない（0冊のまま）。
    /// 境界の外と中を交互に入れ、誤りの文が出ることと消えることの両方を見る。
    @MainActor
    func test_AC31_totalPagesOutsideOneTo9999AreRejected() throws {
        let s = AppSession.launch(.fresh)
        s.tap("library.addBook")
        let title = s.el("book.add.title")
        Wait.exists(title, "book.add.title")
        title.tap()
        title.typeText(Fixture.botchan)
        Wait.enabled(s.el("book.save"), true, "前提：題名だけなら book.save は有効")

        let values: [(text: String, accepted: Bool)] = [("0", false), ("1", true), ("9999", true), ("10000", false)]
        for (text, accepted) in values {
            s.replaceText("book.add.totalPages", with: text)
            XCTAssertEqual(s.fieldText("book.add.totalPages"), text, "前提：総ページ数の欄に \(text) が入った")
            if accepted {
                Wait.gone(s.el("book.add.totalPagesOutOfRange"), "\(text)：book.add.totalPagesOutOfRange")
                Wait.enabled(s.el("book.save"), true, "\(text)：book.save")
            } else {
                Wait.label(
                    s.el("book.add.totalPagesOutOfRange"), equals: L10n.bookAddTotalPagesOutOfRange,
                    "\(text)：book.add.totalPagesOutOfRange")
                Wait.enabled(s.el("book.save"), false, "\(text)：book.save")
                s.el("book.save").tap()
                XCTAssertTrue(s.el("book.add.title").exists, "\(text)：押しても保存されず、入力は開いたまま")
                s.shot("AC31_総ページ数\(text)", self)
            }
        }

        s.cancelAddBook()
        Wait.exists(s.el("library.empty.title"), "本は0冊のまま（空の状態）")
        XCTAssertEqual(s.bookRows().count, 0, "本の行は0個")
    }

    // MARK: AC-42

    /// AC-42：本の追加の保存が毎回失敗する（UITEST_FAIL=book_add:*）、本は1冊。題名「こころ」で保存すると、
    /// error.saveFailed（「変更を保存できませんでした」）と error.retry（「もう一度保存」）が出て、題名の欄は「こころ」のまま。
    /// 閉じた後の一覧の本は1冊のまま。
    @MainActor
    func test_AC42_bookAddFailureKeepsTitle() throws {
        var config = LaunchConfig.seeded(oneBook)
        config.fail = "book_add:*"
        let s = AppSession.launch(config)
        Wait.label(s.el("home.bookCount"), equals: L10n.bookCount(1), "前提：本は1冊")

        s.tap("library.addBook")
        let title = s.el("book.add.title")
        Wait.exists(title, "book.add.title")
        title.tap()
        title.typeText(Fixture.kokoro)
        s.tap("book.save")

        s.expectSaveFailed("本の追加の保存の失敗")
        Wait.label(s.el("error.retry"), equals: L10n.errorRetry, "error.retry の文（もう一度保存）")
        Wait.value(s.el("book.add.title"), equals: Fixture.kokoro, "題名の欄は「こころ」のまま")
        s.shot("AC42_本の追加の失敗", self)

        s.cancelAddBook()
        Wait.label(s.el("home.bookCount"), equals: L10n.bookCount(1), "閉じた後も本は1冊")
        XCTAssertEqual(s.bookRows(titled: Fixture.kokoro).count, 0, "「こころ」の行は0個")
    }

    // MARK: AC-49

    /// AC-49：「坊っちゃん」に記録1件（home.startReading は「坊っちゃん」を指す）、読書中はない。題名「こころ」で追加すると、
    /// 本を追加する入力は閉じ（book.add.title は0個）、book.title が「こころ」の詳細が出て、book.startReading が1個で押せる。
    @MainActor
    func test_AC49_afterAddShowsNewBookDetail() throws {
        let s = AppSession.launch(.seeded(Seeds.botchanOneSession(lastPage: 40)))
        s.expectState(.idle)
        Wait.exists(s.el("home.startReading"), "前提：home.startReading")

        s.addBook(title: Fixture.kokoro)
        Wait.gone(s.el("book.add.title"), "本を追加する入力")
        XCTAssertEqual(s.count("book.add.title"), 0, "book.add.title は0個")
        Wait.label(s.el("book.title"), equals: Fixture.kokoro, "追加した本の詳細の題名")
        let start = s.el("book.startReading")
        Wait.exists(start, "book.startReading")
        XCTAssertEqual(s.count("book.startReading"), 1, "book.startReading は1個")
        XCTAssertTrue(start.isHittable, "book.startReading が押せる")
        s.shot("AC49_追加した本の詳細", self)
    }

    // MARK: AC-53

    /// AC-53：本は「坊っちゃん」1冊。題名の欄に「こころ」を入れて book.add.cancel を押し、確認で「追加せずに閉じる」
    /// （book.add.discard.confirm。識別子が付かなければ 7 の文字）を選ぶと、入力は閉じ、home.bookCount は「1冊」のまま、
    /// label が「こころ」の本の行は0個。起動し直しても同じ。
    @MainActor
    func test_AC53_discardingAddKeepsBookCount() throws {
        let s = AppSession.launch(.seeded(oneBook))
        Wait.label(s.el("home.bookCount"), equals: L10n.bookCount(1), "前提：本は1冊")

        s.tap("library.addBook")
        let title = s.el("book.add.title")
        Wait.exists(title, "book.add.title")
        title.tap()
        title.typeText(Fixture.kokoro)
        s.tap("book.add.cancel")
        let confirm = s.systemButton(id: "book.add.discard.confirm", text: L10n.bookAddDiscardConfirm)
        Wait.exists(confirm, "確認の「追加せずに閉じる」")
        s.shot("AC53_追加をやめる確認", self)
        confirm.tap()

        Wait.gone(s.el("book.add.title"), "本を追加する入力")
        XCTAssertEqual(s.count("book.add.title"), 0, "book.add.title は0個")
        Wait.label(s.el("home.bookCount"), equals: L10n.bookCount(1), "本は1冊のまま")
        XCTAssertEqual(s.bookRows(titled: Fixture.kokoro).count, 0, "「こころ」の行は0個")

        s.relaunch(now: Fixture.now)
        Wait.label(s.el("home.bookCount"), equals: L10n.bookCount(1), "起動し直した後も本は1冊")
        XCTAssertEqual(s.bookRows(titled: Fixture.kokoro).count, 0, "起動し直した後も「こころ」の行は0個")
    }
}
