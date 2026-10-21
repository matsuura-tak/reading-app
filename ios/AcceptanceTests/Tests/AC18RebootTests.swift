import XCTest

/// AC-18：端末（シミュレーター）を再起動しても、本と記録が残る（T11）。
/// この2つは Acceptance.xctestplan の skippedTests に入れ、ac18-reboot.sh が AC18Reboot.xctestplan で順に動かす：
/// 1 を動かす → xcrun simctl shutdown と boot → 2 を動かす。1つだけで動かしても意味がないので、通常の実行には入れない。
final class AC18RebootTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// AC-18 の前半（データを作る実行）：「坊っちゃん」に記録3件（10分、20分、30分）、「こころ」に記録2件（15分、25分）を入れ、
    /// 保存先に入ったことをホームの冊数で見てから終える。
    @MainActor
    func test_AC18_1_seedLibraryBeforeReboot() throws {
        let s = AppSession.launch(.seeded(Seeds.libraryOfFive()))
        Wait.label(s.el("home.bookCount"), equals: L10n.bookCount(2), "前提：本は2冊")
        s.openBook(id: Fixture.botchanId)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(3), "前提：「坊っちゃん」の記録は3件")
        s.app.terminate()
    }

    /// AC-18 の後半（確かめる実行。再起動の後、UITEST_RESET も UITEST_SEED も渡さない）：本が2冊、記録が5件で、
    /// 「坊っちゃん」の合計は「60分」、「こころ」の合計は「40分」。
    @MainActor
    func test_AC18_2_libraryRemainsAfterReboot() throws {
        let s = AppSession.launch(LaunchConfig())
        Wait.label(s.el("home.bookCount"), equals: L10n.bookCount(2), "再起動の後の冊数")
        XCTAssertEqual(s.count("library.book.\(Fixture.botchanId)"), 1, "「坊っちゃん」の行")
        XCTAssertEqual(s.count("library.book.\(Fixture.kokoroId)"), 1, "「こころ」の行")
        s.shot("AC18_再起動の後のホーム", self)

        s.openBook(id: Fixture.botchanId)
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(60), "「坊っちゃん」の合計")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(3), "「坊っちゃん」の記録の数")
        s.goBack()

        s.openBook(id: Fixture.kokoroId)
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(40), "「こころ」の合計")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "「こころ」の記録の数（合わせて5件）")
    }
}
