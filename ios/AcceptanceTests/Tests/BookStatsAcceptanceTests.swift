import XCTest

/// S3 本の詳細の合計と、S1 の今週の合計、記録を消す（AC-14〜AC-16、AC-28）。
final class BookStatsAcceptanceTests: AcceptanceTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: AC-14

    /// AC-14：「坊っちゃん」（300、最後のページ72）に記録3件（10分、20分、30分）。詳細に合計「60分」、記録「3件」、
    /// 最後のページ「72」、進み具合「24%」。
    @MainActor
    func test_AC14_bookTotalsAreShown() throws {
        let seed = Seed(
            books: [Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 72)],
            sessions: [
                Fixture.session(101, book: Fixture.botchanId, startedAt: WallClock("2026-10-05T21:00:00"), seconds: 600, endPage: 20, pagesRead: 20),
                Fixture.session(102, book: Fixture.botchanId, startedAt: WallClock("2026-10-12T21:00:00"), seconds: 1200, endPage: 45, pagesRead: 25),
                Fixture.session(103, book: Fixture.botchanId, startedAt: WallClock("2026-10-20T21:00:00"), seconds: 1800, endPage: 72, pagesRead: 27),
            ])
        let s = AppSession.launch(.seeded(seed))
        s.openBook(id: Fixture.botchanId)
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(60), "合計時間")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(3), "記録の数")
        Wait.value(s.el("book.lastPage"), equals: "72", "最後のページ")
        Wait.value(s.el("book.progress"), equals: L10n.percent(24), "進み具合")
        s.shot("AC14_本の詳細", self)
    }

    /// AC-14 の合計の境界（PRD 10 の丸め：合計は秒で足してから分にする）：90秒の記録3件は270秒で「4分」（分にしてから足すと3分）。
    @MainActor
    func test_AC14_totalAddsSecondsBeforeFlooring() throws {
        let seed = Seed(
            books: [Fixture.book(2, Fixture.kokoro, totalPages: nil, lastPage: 0)],
            sessions: [
                Fixture.session(201, book: Fixture.kokoroId, startedAt: WallClock("2026-10-18T21:00:00"), seconds: 90),
                Fixture.session(202, book: Fixture.kokoroId, startedAt: WallClock("2026-10-19T21:00:00"), seconds: 90),
                Fixture.session(203, book: Fixture.kokoroId, startedAt: WallClock("2026-10-20T21:00:00"), seconds: 90),
            ])
        let s = AppSession.launch(.seeded(seed))
        s.openBook(id: Fixture.kokoroId)
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(4), "合計時間（270秒）")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(3), "記録の数")
    }

    // MARK: AC-15

    /// AC-15：週の始めを月曜（UITEST_FIRST_WEEKDAY=2）、今日は 2026-10-21（水）。今週の記録 25分（10-19 月）と 35分（10-20 火）、
    /// 先週の記録 40分（10-18 日）。ホームの今週の合計は「60分」（日曜始まりなら「100分」になる。contracts/examples/seed-ac15.json と同じ）。
    @MainActor
    func test_AC15_weekTotalExcludesLastWeek() throws {
        let seed = Seed(
            books: [Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 72)],
            sessions: [
                Fixture.session(111, book: Fixture.botchanId, startedAt: WallClock("2026-10-18T22:00:00"), seconds: 2400),
                Fixture.session(112, book: Fixture.botchanId, startedAt: WallClock("2026-10-19T21:00:00"), seconds: 1500),
                Fixture.session(113, book: Fixture.botchanId, startedAt: WallClock("2026-10-20T21:00:00"), seconds: 2100, endPage: 72, pagesRead: 72),
            ])
        var config = LaunchConfig.seeded(seed)
        config.firstWeekday = 2
        let s = AppSession.launch(config)
        Wait.value(s.el("home.weekTotal"), equals: L10n.minutes(60), "今週の合計")
        s.shot("AC15_今週の合計", self)
    }

    // MARK: AC-16

    /// AC-16：「坊っちゃん」に記録2件（20分、30分）、最後のページ72。30分の記録を消して確認で消すと、記録は1件、
    /// 合計「20分」、最後のページは72のまま。終了して起動し直しても同じ。
    @MainActor
    func test_AC16_deleteSessionKeepsLastPage() throws {
        let seed = Seed(
            books: [Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 72)],
            sessions: [
                Fixture.session(101, book: Fixture.botchanId, startedAt: WallClock("2026-10-19T21:00:00"), seconds: 1200, endPage: 40, pagesRead: 40),
                Fixture.session(102, book: Fixture.botchanId, startedAt: WallClock("2026-10-20T21:00:00"), seconds: 1800, endPage: 72, pagesRead: 32),
            ])
        let s = AppSession.launch(.seeded(seed))
        s.openBook(id: Fixture.botchanId)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "前提：記録は2件")

        deleteSession(s, id: Fixture.id(102))
        Wait.gone(s.el("session.row.id.\(Fixture.id(102))"), "消した30分の記録の行")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "記録は1件")
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(20), "合計時間")
        Wait.value(s.el("book.lastPage"), equals: "72", "最後のページは72のまま")
        XCTAssertTrue(s.el("session.row.id.\(Fixture.id(101))").exists, "20分の記録は残る")
        s.shot("AC16_消した後", self)

        s.relaunch(now: Fixture.now)
        s.openBook(id: Fixture.botchanId)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "起動し直した後の記録の数")
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(20), "起動し直した後の合計時間")
        Wait.value(s.el("book.lastPage"), equals: "72", "起動し直した後の最後のページ")
    }

    /// 記録の行をスワイプして「削除」→ S6 の alert の「記録を消す」。システムの部品は識別子か 7 の文字で探す（design 6 の (b)）。
    @MainActor
    private func deleteSession(_ s: AppSession, id: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = s.el("session.row.id.\(id)")
        Wait.exists(row, "記録の行 \(id)", file: file, line: line)
        row.swipeLeft()
        let delete = s.systemButton(id: "session.row.delete", text: L10n.sessionRowDelete)
        Wait.exists(delete, "行の「削除」", file: file, line: line)
        delete.tap()
        let confirm = s.systemButton(id: "session.delete.confirm", text: L10n.sessionDeleteConfirm)
        Wait.exists(confirm, "S6 の「記録を消す」", file: file, line: line)
        confirm.tap()
    }

    // MARK: AC-28

    /// AC-28：総ページ数が未設定で最後のページ40、記録2件の「こころ」。詳細に最後のページ「40」が出て、book.progress は0個。
    @MainActor
    func test_AC28_noProgressWithoutTotalPages() throws {
        let seed = Seed(
            books: [Fixture.book(2, Fixture.kokoro, totalPages: nil, lastPage: 40)],
            sessions: [
                Fixture.session(201, book: Fixture.kokoroId, startedAt: WallClock("2026-10-03T22:00:00"), seconds: 900),
                Fixture.session(202, book: Fixture.kokoroId, startedAt: WallClock("2026-10-10T22:00:00"), seconds: 1500, endPage: 40, pagesRead: 40),
            ])
        let s = AppSession.launch(.seeded(seed))
        s.openBook(id: Fixture.kokoroId)
        Wait.value(s.el("book.lastPage"), equals: "40", "最後のページ")
        XCTAssertEqual(s.count("book.progress"), 0, "進み具合の要素は0個")
        s.shot("AC28_総ページ数なし", self)
    }
}
