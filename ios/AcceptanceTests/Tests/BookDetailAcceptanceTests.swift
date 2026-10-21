import XCTest

/// S1 の今週の合計（0件、週をまたぐ記録）と S3 本の詳細：記録0件、消す確認の取り消し、削除の失敗、60秒未満の知らせ、
/// 読書中の主操作、読み始めの保存の失敗と再試行（AC-36〜AC-38、AC-43、AC-44、AC-51、AC-52、AC-56、AC-57）。
final class BookDetailAcceptanceTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 「坊っちゃん」（300、最後のページ72）に記録2件（101 が20分、102 が30分。AC-38、AC-43）。
    private var botchanTwentyAndThirty: Seed {
        Seed(
            books: [Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 72)],
            sessions: [
                Fixture.session(101, book: Fixture.botchanId, startedAt: WallClock("2026-10-19T21:00:00"), seconds: 1200, endPage: 40, pagesRead: 40),
                Fixture.session(102, book: Fixture.botchanId, startedAt: WallClock("2026-10-20T21:00:00"), seconds: 1800, endPage: 72, pagesRead: 32),
            ])
    }

    // MARK: AC-36

    /// AC-36：週の始めは月曜（UITEST_FIRST_WEEKDAY=2）、今日は 2026-10-21（水）。今週の記録は0件で、先週（10-18 日）に40分。
    /// ホームの home.weekTotal は「0分」。
    @MainActor
    func test_AC36_weekTotalIsZeroWithoutSessionsThisWeek() throws {
        let seed = Seed(
            books: [Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 40)],
            sessions: [
                Fixture.session(111, book: Fixture.botchanId, startedAt: WallClock("2026-10-18T22:00:00"), seconds: 2400, endPage: 40, pagesRead: 40)
            ])
        var config = LaunchConfig.seeded(seed)
        config.firstWeekday = 2
        let s = AppSession.launch(config)
        Wait.value(s.el("home.weekTotal"), equals: L10n.minutes(0), "今週の合計")
        s.shot("AC36_今週0分", self)
    }

    // MARK: AC-37

    /// AC-37：「坊っちゃん」（300、最後のページ0）に記録0件。詳細に合計「0分」、「記録 0件」、進み具合「0%」、
    /// book.sessions.empty（「まだ記録はありません。読書を終えると、ここに残ります。」）が出て、book.startReading は有効。
    @MainActor
    func test_AC37_bookWithoutSessionsShowsEmptyState() throws {
        let s = AppSession.launch(.seeded(Seed(books: [Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 0)])))
        s.openBook(id: Fixture.botchanId)
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(0), "合計時間")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(0), "記録の数")
        Wait.value(s.el("book.progress"), equals: L10n.percent(0), "進み具合")
        Wait.label(s.el("book.sessions.empty"), equals: L10n.bookSessionsEmpty, "book.sessions.empty")
        XCTAssertEqual(s.elements(prefixed: "session.row.id.").count, 0, "記録の行は0個")
        Wait.enabled(s.el("book.startReading"), true, "book.startReading")
        s.shot("AC37_記録0件の詳細", self)
    }

    // MARK: AC-38

    /// AC-38：「坊っちゃん」に記録2件（20分、30分）。30分の記録を消そうとし、S6 で「キャンセル」（session.delete.cancel。
    /// 識別子が付かなければ 7 の文字）を選ぶと、記録は「2件」のままで、合計は「50分」。
    @MainActor
    func test_AC38_cancelDeleteKeepsSession() throws {
        let s = AppSession.launch(.seeded(botchanTwentyAndThirty))
        s.openBook(id: Fixture.botchanId)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "前提：記録は2件")

        s.beginDeleteSession(id: Fixture.id(102))
        let cancel = s.systemButton(id: "session.delete.cancel", text: L10n.commonCancel)
        Wait.exists(cancel, "S6 の「キャンセル」")
        s.shot("AC38_消す確認", self)
        cancel.tap()
        Wait.gone(cancel, "S6")

        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "記録は2件のまま")
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(50), "合計時間は50分のまま")
        XCTAssertTrue(s.el("session.row.id.\(Fixture.id(102))").exists, "30分の記録の行は残る")
    }

    // MARK: AC-43

    /// AC-43：記録の削除の保存が毎回失敗する（UITEST_FAIL=session_delete:*）、記録2件（20分、30分）。30分の記録を消して確認で消すと、
    /// S7 に error.saveFailed（「変更を保存できませんでした」）が出て、「OK」の後も記録は「2件」、合計は「50分」。起動し直しても同じ。
    /// S7 は alert なので、題は識別子か 7 の文字で、「OK」は 7 の文字で探す（design 6 の (b)）。
    @MainActor
    func test_AC43_deleteFailureKeepsSession() throws {
        var config = LaunchConfig.seeded(botchanTwentyAndThirty)
        config.fail = "session_delete:*"
        let s = AppSession.launch(config)
        s.openBook(id: Fixture.botchanId)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "前提：記録は2件")

        s.beginDeleteSession(id: Fixture.id(102))
        let confirm = s.systemButton(id: "session.delete.confirm", text: L10n.sessionDeleteConfirm)
        Wait.exists(confirm, "S6 の「記録を消す」")
        confirm.tap()

        let alert = s.app.alerts.firstMatch
        Wait.exists(alert, "S7（記録を消せなかった知らせ）")
        let title = alert.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == %@ OR label == %@", "error.saveFailed", L10n.errorSaveFailed)).firstMatch
        Wait.exists(title, "S7 の題 error.saveFailed（「\(L10n.errorSaveFailed)」）")
        s.shot("AC43_削除の失敗", self)
        let ok = alert.buttons.matching(NSPredicate(format: "label == %@", L10n.commonOK)).firstMatch
        Wait.exists(ok, "S7 の「\(L10n.commonOK)」")
        ok.tap()
        Wait.gone(alert, "S7")

        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "記録は2件のまま")
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(50), "合計時間は50分のまま")
        XCTAssertTrue(s.el("session.row.id.\(Fixture.id(102))").exists, "30分の記録の行は残る")

        s.relaunch(now: Fixture.now)
        s.openBook(id: Fixture.botchanId)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "起動し直した後も記録は2件")
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(50), "起動し直した後も合計時間は50分")
    }

    // MARK: AC-44

    /// AC-44：週の始めは日曜（UITEST_FIRST_WEEKDAY=1）、今日は 2026-10-25（日）21:30。土曜 23:50 に始めて日曜 0:20 に終えた30分の記録と、
    /// 日曜 9:00 に始めた20分の記録。ホームの home.weekTotal は「20分」（30分の記録は始めた土曜の週に数える）。
    @MainActor
    func test_AC44_sessionAcrossWeekBoundaryCountsInStartWeek() throws {
        let sunday = WallClock("2026-10-25T21:30:00")
        let seed = Seed(
            books: [Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 40)],
            sessions: [
                Fixture.session(121, book: Fixture.botchanId, startedAt: WallClock("2026-10-24T23:50:00"), seconds: 1800, endPage: 20, pagesRead: 20),
                Fixture.session(122, book: Fixture.botchanId, startedAt: WallClock("2026-10-25T09:00:00"), seconds: 1200, endPage: 40, pagesRead: 20),
            ])
        var config = LaunchConfig.seeded(seed)
        config.now = sunday
        config.firstWeekday = 1
        let s = AppSession.launch(config)
        Wait.value(s.el("home.weekTotal"), equals: L10n.minutes(20), "今週の合計")
        s.shot("AC44_週をまたぐ記録", self)
    }

    // MARK: AC-51

    /// AC-51：記録1件の「坊っちゃん」を home.startReading で読み始め、経過0:59で終えると、終える入力は出ず（session.finish.save は0個）、
    /// book.title が「坊っちゃん」の詳細に session.finish.tooShort が1個、「記録 1件」のまま、アラートは0個、状態は idle。
    @MainActor
    func test_AC51_tooShortShowsNoticeOnBookDetail() throws {
        let s = AppSession.launch(.seeded(Seeds.botchanOneSession(lastPage: 40)))
        s.tap("home.startReading")
        s.expectState(.reading)
        s.advance(seconds: 59)
        Wait.label(s.el("reading.elapsed"), equals: L10n.elapsedLabel(59), "前提：経過 0:59")

        s.tap("reading.finish")
        Wait.label(s.el("book.title"), equals: Fixture.botchan, "終えた後の本の詳細")
        XCTAssertEqual(s.count("session.finish.save"), 0, "終える入力は出ない")
        Wait.label(s.el("session.finish.tooShort"), equals: L10n.sessionFinishTooShort, "session.finish.tooShort")
        XCTAssertEqual(s.count("session.finish.tooShort"), 1, "session.finish.tooShort は1個")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "記録は1件のまま")
        XCTAssertEqual(s.app.alerts.count, 0, "アラートは0個")
        s.expectState(.idle)
        s.shot("AC51_1分未満の知らせ", self)
    }

    // MARK: AC-52

    /// AC-52（reading）：「坊っちゃん」の詳細の book.resumeReading が1個で有効、label「読書に戻る」、book.startReading と book.start.busy は0個。
    @MainActor
    func test_AC52_bookDetailOffersResumeWhileReading() throws {
        assertAC52(state: "reading")
    }

    /// AC-52（paused）：label は「一時停止中の読書に戻る」。
    @MainActor
    func test_AC52_bookDetailOffersResumeWhilePaused() throws {
        assertAC52(state: "paused")
    }

    /// AC-52（finishing。終える入力をやめてから開く。やめると reading になり、label は「読書に戻る」）。
    @MainActor
    func test_AC52_bookDetailOffersResumeAfterCancellingFinish() throws {
        assertAC52(state: "finishing")
    }

    @MainActor
    private func assertAC52(state: String, file: StaticString = #filePath, line: UInt = #line) {
        let s = AppSession.launch(.seeded(Seeds.botchanOneSession(lastPage: 40, active: Fixture.active(state, book: Fixture.botchanId))))
        if state == "finishing" {
            s.expectState(.finishing, file: file, line: line)
            s.tap("session.finish.cancel", file: file, line: line)
            Wait.gone(s.el("session.finish.save"), "終える入力", file: file, line: line)
        }
        let paused = state == "paused"
        s.expectState(paused ? .paused : .reading, file: file, line: line)
        s.goBack(file: file, line: line)
        s.openBook(id: Fixture.botchanId, file: file, line: line)

        let resume = s.el("book.resumeReading")
        Wait.exists(resume, "\(state)：book.resumeReading", file: file, line: line)
        XCTAssertEqual(s.count("book.resumeReading"), 1, "\(state)：book.resumeReading は1個", file: file, line: line)
        Wait.enabled(resume, true, "\(state)：book.resumeReading", file: file, line: line)
        Wait.label(resume, equals: paused ? L10n.actionResumePaused : L10n.actionResume, "\(state)：book.resumeReading の label", file: file, line: line)
        XCTAssertEqual(s.count("book.startReading"), 0, "\(state)：book.startReading は0個", file: file, line: line)
        XCTAssertEqual(s.count("book.start.busy"), 0, "\(state)：book.start.busy は0個", file: file, line: line)
        s.shot("AC52_\(state)_本の詳細", self)
    }

    // MARK: AC-56、AC-57

    /// AC-56 と AC-57 の共通の前半：記録1件の「坊っちゃん」、idle、読み始めの保存が1回だけ失敗する（session_start:1）。
    /// fromHome なら home.startReading、そうでなければ詳細の book.startReading を押す。
    @MainActor
    private func failStart(fromHome: Bool, file: StaticString = #filePath, line: UInt = #line) -> AppSession {
        var config = LaunchConfig.seeded(Seeds.botchanOneSession(lastPage: 40))
        config.fail = "session_start:1"
        let s = AppSession.launch(config)
        s.expectState(.idle, file: file, line: line)
        if fromHome {
            s.tap("home.startReading", file: file, line: line)
        } else {
            s.openBook(id: Fixture.botchanId, file: file, line: line)
            s.tap("book.startReading", file: file, line: line)
        }
        s.expectSaveFailed(fromHome ? "ホームで読み始めの失敗" : "本の詳細で読み始めの失敗", file: file, line: line)
        s.noteRetryLabel(fromHome ? L10n.homePrimary(Fixture.botchan, L10n.errorRetryStart) : L10n.errorRetryStart, fromHome ? "AC56_ホーム" : "AC56_本の詳細")  // design 6 の文。AC の Then の外なので、違っても AC の判定に数えない（L10n.swift の noteRetryLabel）
        return s
    }

    /// AC-56 の Then：操作した画面に error.saveFailed と error.retry が1個ずつ、session.state.idle が1個、reading.elapsed は0個、
    /// 「坊っちゃん」の記録は1件のまま。
    @MainActor
    private func assertAC56(fromHome: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let s = failStart(fromHome: fromHome, file: file, line: line)
        let name = fromHome ? "ホーム" : "本の詳細"
        if fromHome {
            Wait.exists(s.el("home.bookCount"), "\(name)：ホームのまま", file: file, line: line)
        } else {
            Wait.label(s.el("book.title"), equals: Fixture.botchan, "\(name)：本の詳細のまま", file: file, line: line)
        }
        s.expectState(.idle, file: file, line: line)
        XCTAssertEqual(s.count("session.state.idle"), 1, "\(name)：session.state.idle は1個", file: file, line: line)
        XCTAssertEqual(s.count("reading.elapsed"), 0, "\(name)：reading.elapsed は0個", file: file, line: line)
        s.shot("AC56_\(name)_読み始めの失敗", self)
        if fromHome {
            s.openBook(id: Fixture.botchanId, file: file, line: line)
        }
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "\(name)：記録は1件のまま", file: file, line: line)
    }

    @MainActor
    func test_AC56_startFailureFromHomeKeepsIdle() throws {
        assertAC56(fromHome: true)
    }

    @MainActor
    func test_AC56_startFailureFromBookDetailKeepsIdle() throws {
        assertAC56(fromHome: false)
    }

    /// AC-57 の Then：失敗の60秒後に error.retry を押すと、reading、reading.title「坊っちゃん」、経過は「0分0秒」か「0分1秒」
    /// （失敗から再試行までの60秒は数えない）、error.saveFailed は0個、記録は1件のまま。
    @MainActor
    private func assertAC57(fromHome: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let s = failStart(fromHome: fromHome, file: file, line: line)
        let name = fromHome ? "ホーム" : "本の詳細"
        s.advance(seconds: 60, file: file, line: line)
        s.tap("error.retry", file: file, line: line)

        s.expectState(.reading, file: file, line: line)
        Wait.label(s.el("reading.title"), equals: Fixture.botchan, "\(name)：読書中の本の題名", file: file, line: line)
        Wait.label(s.el("reading.elapsed"), in: L10n.elapsedLabels(0...1), "\(name)：再試行の直後の経過（0:00 か 0:01）", file: file, line: line)
        s.expectNoSaveFailed("\(name)：再試行の後", file: file, line: line)
        s.shot("AC57_\(name)_読み始めの再試行の後", self)

        // 記録の数：S4 から戻る。ホームから始めたなら S1 > S4 なのでホームに、本の詳細から始めたなら S1 > S3 > S4 なので S3 に戻る（design 1）。
        if fromHome {
            s.goBack(file: file, line: line)
            s.openBook(id: Fixture.botchanId, file: file, line: line)
        } else {
            s.goBack(toBookTitled: Fixture.botchan, file: file, line: line)
        }
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "\(name)：記録は1件のまま", file: file, line: line)
    }

    @MainActor
    func test_AC57_startRetryFromHomeStartsAtRetryTime() throws {
        assertAC57(fromHome: true)
    }

    @MainActor
    func test_AC57_startRetryFromBookDetailStartsAtRetryTime() throws {
        assertAC57(fromHome: false)
    }
}
