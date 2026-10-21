import XCTest

/// S5 終える入力：ページの上限、強制終了からの戻り、再試行、入力中の時間、やめる、下へのスワイプ、保存の後の画面、
/// やめる保存の失敗と再試行（AC-32、AC-34、AC-35、AC-45〜AC-48、AC-50、AC-64、AC-65）。
/// 時計は UITEST_NOW と UITEST_CLOCK_FROZEN で止め、T16 で決まった秒だけ進める（実時間で待たない）。
final class FinishInputAcceptanceTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 「坊っちゃん」（300、最後のページ40）に記録2件（20分ずつ）。active は「坊っちゃん」に付ける（AC-35、AC-48）。
    private func botchanTwoSessions(active: SeedActive) -> Seed {
        Seed(
            books: [Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 40)],
            sessions: [
                Fixture.session(101, book: Fixture.botchanId, startedAt: WallClock("2026-10-19T21:00:00"), seconds: 1200, endPage: 20, pagesRead: 20),
                Fixture.session(102, book: Fixture.botchanId, startedAt: WallClock("2026-10-20T21:00:00"), seconds: 1200, endPage: 40, pagesRead: 20),
            ],
            active: active)
    }

    /// S4 で「終える」を押し、S5 が開くのを待つ。
    @MainActor
    private func openFinish(_ s: AppSession, file: StaticString = #filePath, line: UInt = #line) {
        s.tap("reading.finish", file: file, line: line)
        Wait.exists(s.el("session.finish.save"), "終える入力（session.finish.save）", file: file, line: line)
        s.expectState(.finishing, file: file, line: line)
    }

    // MARK: AC-32

    /// AC-32：総ページ数が未設定で最後のページ40の「こころ」、finishing（経過10:00）。今のページ10000で保存しようとすると、
    /// 記録は増えず、session.finish.pageOutOfRange（「0から9999までの数字で入れてください。」）が出て finishing のまま。
    /// 9999 なら保存でき、記録が1件増えて「記録 2件」、最後のページ「9999」、状態は idle（G0 r2 の読み）。
    @MainActor
    func test_AC32_pageAbove9999IsRejectedWithoutTotalPages() throws {
        let seed = Seed(
            books: [Fixture.book(2, Fixture.kokoro, totalPages: nil, lastPage: 40)],
            sessions: [
                Fixture.session(201, book: Fixture.kokoroId, startedAt: WallClock("2026-10-19T22:00:00"), seconds: 900, endPage: 40, pagesRead: 40)
            ],
            active: Fixture.finishing(Fixture.kokoroId, elapsed: 600))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.finishing)

        s.replaceText("session.finish.page", with: "10000")
        s.el("session.finish.save").tap()
        Wait.label(s.el("session.finish.pageOutOfRange"), equals: L10n.sessionFinishPageOutOfRange(9999), "10000：session.finish.pageOutOfRange")
        s.expectState(.finishing)
        XCTAssertTrue(s.el("session.finish.save").exists, "10000：終える入力は開いたまま")
        s.shot("AC32_ページ10000", self)

        s.replaceText("session.finish.page", with: "9999")
        Wait.gone(s.el("session.finish.pageOutOfRange"), "9999 では誤りの文")
        s.tap("session.finish.save")
        Wait.label(s.el("book.title"), equals: Fixture.kokoro, "保存の後の本の詳細")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "記録は1件だけ増えて2件")
        Wait.value(s.el("book.lastPage"), equals: "9999", "最後のページ")
        s.expectState(.idle)
    }

    // MARK: AC-34

    /// AC-34：経過10:00で終えた finishing のときに強制終了し、5分後に起動すると、finishing で戻り、読んだ時間は「10」
    /// （5分は足されない）、今のページの欄は空、記録の数は変わらない（1件）。
    /// 欄が空であることに意味を持たせるため、強制終了の前に今のページ72を入れておく（入れかけの値は保存しない。PRD 10）。
    @MainActor
    func test_AC34_finishingIsRestoredAfterForceQuit() throws {
        let seed = Seeds.botchanOneSession(lastPage: 40, active: Fixture.finishing(Fixture.botchanId, elapsed: 600))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.finishing)
        Wait.value(s.el("session.finish.minutes"), equals: "10", "前提：読んだ時間は10分")
        s.replaceText("session.finish.page", with: "72")

        s.relaunch(now: Fixture.now.adding(minutes: 5))
        s.expectState(.finishing)
        Wait.exists(s.el("session.finish.save"), "起動し直した後の終える入力")
        Wait.value(s.el("session.finish.minutes"), equals: "10", "起動し直した後の読んだ時間（5分は足されない）")
        XCTAssertEqual(s.fieldText("session.finish.page"), "", "今のページの欄は空")
        s.shot("AC34_起動し直した後", self)

        s.expectSessionCount(1, bookId: Fixture.botchanId, "記録の数は変わらない")
    }

    // MARK: AC-35

    /// AC-35：記録の保存が1回だけ失敗する（UITEST_FAIL=session_finish:1）、記録2件。経過10:00で終えた読書の保存に失敗し、
    /// error.retry を1回押すと、記録は「3件」、状態は idle、error.saveFailed は0個。起動し直しても「3件」（ちょうど1件増えた）。
    @MainActor
    func test_AC35_retryAfterOneFailureAddsExactlyOne() throws {
        var config = LaunchConfig.seeded(botchanTwoSessions(active: Fixture.finishing(Fixture.botchanId, elapsed: 600)))
        config.fail = "session_finish:1"
        let s = AppSession.launch(config)
        s.expectState(.finishing)

        s.tap("session.finish.save")
        s.expectSaveFailed("記録の保存の失敗")
        s.tap("error.retry")

        Wait.label(s.el("book.title"), equals: Fixture.botchan, "再試行の後の本の詳細")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(3), "記録は3件")
        s.expectState(.idle)
        s.expectNoSaveFailed("再試行の後")
        s.shot("AC35_再試行の後", self)

        s.relaunch(now: Fixture.now)
        s.openBook(id: Fixture.botchanId)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(3), "起動し直した後も記録は3件")
    }

    // MARK: AC-45

    /// AC-45：reading で経過2:00。終えて60秒たってから保存すると、その記録の行の読んだ時間は「2分」（60秒を含めると「3分」）。
    @MainActor
    func test_AC45_timeInFinishInputIsNotCounted() throws {
        let s = AppSession.launch(.seeded(Seeds.botchanOneSession(active: Fixture.reading(Fixture.botchanId, elapsed: 120))))
        s.expectState(.reading)
        Wait.label(s.el("reading.elapsed"), equals: L10n.elapsedLabel(120), "前提：経過 2:00")

        openFinish(s)
        s.advance(seconds: 60)
        s.tap("session.finish.save")
        Wait.label(s.el("book.title"), equals: Fixture.botchan, "保存の後の本の詳細")
        guard let row = s.singleNewSessionRow(excluding: [Fixture.id(101)]) else { return }
        Wait.label(row.descendants(matching: .any)["session.row.minutes"], equals: L10n.minutes(2), "その記録の行の読んだ時間")
        s.shot("AC45_記録の行", self)
    }

    // MARK: AC-46

    /// AC-46：経過10:00で終えて今のページに72を入れ、2分後に session.finish.cancel を押すと、reading に戻り、
    /// 経過は「10分0秒」か「10分1秒」、記録の数は変わらない。続けて終えると、今のページの欄は空。
    @MainActor
    func test_AC46_cancelFinishReturnsToReading() throws {
        let s = AppSession.launch(.seeded(Seeds.botchanOneSession(active: Fixture.reading(Fixture.botchanId, elapsed: 600))))
        s.expectState(.reading)
        openFinish(s)
        s.replaceText("session.finish.page", with: "72")
        s.advance(seconds: 120)

        s.tap("session.finish.cancel")
        Wait.gone(s.el("session.finish.save"), "終える入力")
        s.expectState(.reading)
        Wait.label(s.el("reading.elapsed"), in: L10n.elapsedLabels(600...601), "やめた後の経過（10:00 か 10:01）")
        s.shot("AC46_やめた後", self)

        openFinish(s)
        XCTAssertEqual(s.fieldText("session.finish.page"), "", "次の終える入力の今のページの欄は空")

        s.expectSessionCount(1, bookId: Fixture.botchanId, "記録の数は変わらない")
    }

    // MARK: AC-47

    /// AC-47：経過10:00で終え、分の欄を「10」から「5」に直してから、時計を進めずにやめる。5分後に終えると、finishing で、
    /// session.finish.minutes の value は「15」（直した「5」も、前の初めの値「10」も残らない）。
    @MainActor
    func test_AC47_cancelFinishResetsMinutesDraft() throws {
        let s = AppSession.launch(.seeded(Seeds.botchanOneSession(active: Fixture.reading(Fixture.botchanId, elapsed: 600))))
        s.expectState(.reading)
        openFinish(s)
        Wait.value(s.el("session.finish.minutes"), equals: "10", "前提：分の欄の初めの値は10")
        s.replaceText("session.finish.minutes", with: "5")
        XCTAssertEqual(s.fieldText("session.finish.minutes"), "5", "前提：分の欄を5に直した")

        s.tap("session.finish.cancel")
        Wait.gone(s.el("session.finish.save"), "終える入力")
        s.expectState(.reading)
        s.advance(seconds: 300)

        openFinish(s)
        Wait.value(s.el("session.finish.minutes"), equals: "15", "5分後に終えたときの分の欄の初めの値")
        s.shot("AC47_次の終える入力", self)
    }

    // MARK: AC-48

    /// AC-48：記録2件、経過10:00で終えて今のページに72を入れ、2分後に終える入力のシートを下へスワイプして閉じると、
    /// reading に戻り、経過は「10分0秒」か「10分1秒」、session.finish.save は0個、記録は「2件」のまま。
    /// スワイプは、欄の上でなく S5 のナビゲーションバー（session.finish.cancel を含むバー）に対して行う（design 6 の (d)）。
    @MainActor
    func test_AC48_swipeDownDismissEqualsCancel() throws {
        let s = AppSession.launch(.seeded(botchanTwoSessions(active: Fixture.reading(Fixture.botchanId, elapsed: 600))))
        s.expectState(.reading)
        openFinish(s)
        s.replaceText("session.finish.page", with: "72")
        s.advance(seconds: 120)

        let bar = s.app.navigationBars.containing(.any, identifier: "session.finish.cancel").firstMatch
        Wait.exists(bar, "S5 のナビゲーションバー（session.finish.cancel を含む）")
        bar.swipeDown()

        Wait.gone(s.el("session.finish.save"), "終える入力")
        XCTAssertEqual(s.count("session.finish.save"), 0, "session.finish.save は0個")
        s.expectState(.reading)
        Wait.label(s.el("reading.elapsed"), in: L10n.elapsedLabels(600...601), "閉じた後の経過（10:00 か 10:01）")
        s.shot("AC48_スワイプで閉じた後", self)

        s.expectSessionCount(2, bookId: Fixture.botchanId, "記録は2件のまま")
    }

    // MARK: AC-50

    /// AC-50：記録1件の「坊っちゃん」を home.startReading で読み始め、経過10:00で終えて保存すると、終える入力と読書中の画面は閉じ
    /// （session.finish.save と reading.finish は0個）、book.title が「坊っちゃん」の詳細が出て、「記録 2件」、状態は idle。
    @MainActor
    func test_AC50_afterSaveShowsBookDetail() throws {
        let s = AppSession.launch(.seeded(Seeds.botchanOneSession(lastPage: 40)))
        s.tap("home.startReading")
        s.expectState(.reading)
        s.advance(seconds: 600)
        Wait.label(s.el("reading.elapsed"), equals: L10n.elapsedLabel(600), "前提：経過 10:00")
        openFinish(s)

        s.tap("session.finish.save")
        Wait.label(s.el("book.title"), equals: Fixture.botchan, "保存の後の本の詳細")
        Wait.gone(s.el("session.finish.save"), "終える入力")
        Wait.gone(s.el("reading.finish"), "読書中の画面")
        XCTAssertEqual(s.count("session.finish.save"), 0, "session.finish.save は0個")
        XCTAssertEqual(s.count("reading.finish"), 0, "reading.finish は0個")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "記録は2件")
        s.expectState(.idle)
        s.shot("AC50_保存の後", self)
    }

    // MARK: AC-64、AC-65

    /// AC-64 と AC-65 の共通の前半：記録1件、経過10:00で終えて今のページに72を入れ、やめる保存が1回だけ失敗する
    /// （UITEST_FAIL=session_cancel_finish:1）状態で session.finish.cancel を押し、60秒たつ。
    @MainActor
    private func failCancelFinish(file: StaticString = #filePath, line: UInt = #line) -> AppSession {
        var config = LaunchConfig.seeded(Seeds.botchanOneSession(active: Fixture.reading(Fixture.botchanId, elapsed: 600)))
        config.fail = "session_cancel_finish:1"
        let s = AppSession.launch(config)
        s.expectState(.reading, file: file, line: line)
        openFinish(s, file: file, line: line)
        s.replaceText("session.finish.page", with: "72", file: file, line: line)
        s.tap("session.finish.cancel", file: file, line: line)
        s.expectSaveFailed("やめる保存の失敗", file: file, line: line)
        s.advance(seconds: 60, file: file, line: line)
        return s
    }

    /// AC-64：やめる保存の失敗の後、error.saveFailed と error.retry が1個ずつ、終える入力は閉じず（session.finish.save が1個）、
    /// finishing のまま（reading は0個）、今のページは「72」、分は「10」、記録は1件のまま。
    @MainActor
    func test_AC64_cancelFinishFailureKeepsInput() throws {
        let s = failCancelFinish()
        s.expectSaveFailed("60秒後")
        XCTAssertEqual(s.count("session.finish.save"), 1, "session.finish.save は1個")
        s.expectState(.finishing)
        XCTAssertEqual(s.count("session.state.reading"), 0, "session.state.reading は0個")
        Wait.value(s.el("session.finish.page"), equals: "72", "今のページは72のまま")
        Wait.value(s.el("session.finish.minutes"), equals: "10", "読んだ時間は10のまま")
        s.shot("AC64_やめる保存の失敗", self)

        s.expectSessionCount(1, bookId: Fixture.botchanId, "記録は1件のまま")
    }

    /// AC-65：AC-64 の後に error.retry を1回押すと、終える入力は閉じ（session.finish.save は0個）、reading、
    /// 経過は「10分0秒」か「10分1秒」（終える操作から再試行までの60秒は足されない）、error.saveFailed は0個、記録は1件のまま。
    @MainActor
    func test_AC65_cancelFinishRetryReturnsToReading() throws {
        let s = failCancelFinish()
        s.tap("error.retry")

        Wait.gone(s.el("session.finish.save"), "終える入力")
        XCTAssertEqual(s.count("session.finish.save"), 0, "session.finish.save は0個")
        s.expectState(.reading)
        Wait.label(s.el("reading.elapsed"), in: L10n.elapsedLabels(600...601), "再試行の後の経過（10:00 か 10:01）")
        s.expectNoSaveFailed("再試行の後")
        s.shot("AC65_やめる再試行の後", self)

        s.expectSessionCount(1, bookId: Fixture.botchanId, "記録は1件のまま")
    }
}
