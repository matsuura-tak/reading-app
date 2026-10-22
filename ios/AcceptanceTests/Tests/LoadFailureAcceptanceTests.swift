import XCTest

/// S1 の読み込みの失敗と再試行（AC-54、AC-55）。データは contracts/seed.example.json と同じ5件（Seeds.libraryOfFive）。
/// 読み込みの失敗は UITEST_FAIL の load（T5）。seed を入れる保存は UITEST_FAIL の数に入らない（test-hooks.md の起動の順番の4）。
final class LoadFailureAcceptanceTests: AcceptanceTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(fail: String) -> AppSession {
        var config = LaunchConfig.seeded(Seeds.libraryOfFive())
        config.fail = fail
        return AppSession.launch(config)
    }

    // MARK: AC-54

    /// AC-54：「坊っちゃん」に記録3件、「こころ」に記録2件ある端末で、読み込みが毎回失敗する（UITEST_FAIL=load:*）。起動すると、
    /// error.loadFailed.title（「本と記録を読み込めませんでした」）、error.loadFailed.message、error.loadFailed.retry（「もう一度読み込む」）が
    /// 1個ずつ出て、library.empty.title、home.bookCount、home.weekTotal、home.startReading は0個。
    @MainActor
    func test_AC54_loadFailureShowsRetryInsteadOfEmpty() throws {
        let s = launch(fail: "load:*")
        Wait.label(s.el("error.loadFailed.title"), equals: L10n.errorLoadFailedTitle, "error.loadFailed.title")
        Wait.label(s.el("error.loadFailed.message"), equals: L10n.errorLoadFailedMessage, "error.loadFailed.message")
        Wait.label(s.el("error.loadFailed.retry"), equals: L10n.errorLoadFailedRetry, "error.loadFailed.retry")
        for id in ["error.loadFailed.title", "error.loadFailed.message", "error.loadFailed.retry"] {
            XCTAssertEqual(s.count(id), 1, "\(id) は1個")
        }
        for id in ["library.empty.title", "home.bookCount", "home.weekTotal", "home.startReading"] {
            XCTAssertEqual(s.count(id), 0, "\(id) は0個")
        }
        s.shot("AC54_読み込みの失敗", self)
    }

    // MARK: AC-55

    /// AC-55：同じ端末で、読み込みが1回だけ失敗する（UITEST_FAIL=load:1）。error.loadFailed.retry を1回押すと、
    /// error.loadFailed.title は0個、home.bookCount は「2冊」、「坊っちゃん」の book.totalTime は「60分」、「こころ」は「40分」（記録は計5件）。
    @MainActor
    func test_AC55_loadRetryRestoresLibrary() throws {
        let s = launch(fail: "load:1")
        Wait.exists(s.el("error.loadFailed.retry"), "前提：error.loadFailed.retry")
        s.tap("error.loadFailed.retry")

        Wait.gone(s.el("error.loadFailed.title"), "error.loadFailed.title")
        XCTAssertEqual(s.count("error.loadFailed.title"), 0, "error.loadFailed.title は0個")
        Wait.label(s.el("home.bookCount"), equals: L10n.bookCount(2), "本の数")
        s.shot("AC55_再試行の後", self)

        s.openBook(id: Fixture.botchanId)
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(60), "「坊っちゃん」の合計時間")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(3), "「坊っちゃん」の記録の数")
        s.goBack()
        s.openBook(id: Fixture.kokoroId)
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(40), "「こころ」の合計時間")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "「こころ」の記録の数（計5件）")
    }
}
