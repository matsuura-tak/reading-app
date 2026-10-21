import XCTest

/// S4 読書中の画面：一時停止で強制終了、経過の読み上げ、時計の戻し、一時停止・再開・「終える」・60秒未満で終える保存の失敗と再試行
/// （AC-33、AC-40、AC-41、AC-58〜AC-63、AC-66、AC-67）。
/// 時計は UITEST_NOW と UITEST_CLOCK_FROZEN で止め、T16 で決まった秒だけ進める（実時間で待たない）。
final class ReadingScreenAcceptanceTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 経過5:00で一時停止した paused（止めたのは今。AC-33、AC-60、AC-62 (b)）。
    private var pausedAtFive: SeedActive { Fixture.paused(Fixture.botchanId, elapsedAtPause: 300, pausedFor: 0) }

    /// 記録1件の「坊っちゃん」に active を付けて起動する。fail は UITEST_FAIL（T5）。
    @MainActor
    private func launch(active: SeedActive, fail: String? = nil) -> AppSession {
        var config = LaunchConfig.seeded(Seeds.botchanOneSession(lastPage: 40, active: active))
        config.fail = fail
        return AppSession.launch(config)
    }

    @MainActor
    private func expectElapsed(
        _ s: AppSession, _ seconds: ClosedRange<Int>, _ what: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        Wait.label(s.el("reading.elapsed"), in: L10n.elapsedLabels(seconds), what, file: file, line: line)
    }

    // MARK: AC-33

    /// AC-33：経過5:00で一時停止した paused のときに強制終了し、5分後に起動すると、「坊っちゃん」の読書中の画面が paused で戻り、
    /// 経過は「5分0秒」のまま（止めていた5分は足されない）。contracts/examples/seed-ac33.json と同じ形。
    @MainActor
    func test_AC33_pausedIsRestoredAfterForceQuit() throws {
        let s = launch(active: pausedAtFive)
        s.expectState(.paused)
        expectElapsed(s, 300...300, "前提：経過 5:00")

        s.relaunch(now: Fixture.now.adding(minutes: 5))
        s.expectState(.paused)
        Wait.label(s.el("reading.title"), equals: Fixture.botchan, "戻った読書中の画面の題名")
        expectElapsed(s, 300...300, "起動し直した後の経過（5:00 のまま）")
        s.shot("AC33_起動し直した後", self)
    }

    // MARK: AC-40

    /// AC-40：reading で経過12:30（時計を止める）。reading.elapsed の label は ja「12分30秒」、en「12 minutes, 30 seconds」。
    @MainActor
    func test_AC40_elapsedLabelReadsMinutesAndSeconds() throws {
        let s = launch(active: Fixture.reading(Fixture.botchanId, elapsed: 750))
        s.expectState(.reading)
        Wait.label(s.el("reading.elapsed"), equals: L10n.pick("12分30秒", "12 minutes, 30 seconds"), "経過の読み上げ")
        s.shot("AC40_経過12分30秒", self)
    }

    // MARK: AC-41

    /// AC-41：reading で経過5:00（読み始め 21:25、今 21:30）。時計を読み始めの10分前（21:15:00）に戻すと、経過は「0分0秒」、
    /// 「-」で始まる表示は0個、状態は reading のまま。
    @MainActor
    func test_AC41_clockSetBackShowsZeroNotNegative() throws {
        let s = launch(active: Fixture.reading(Fixture.botchanId, elapsed: 300))
        s.expectState(.reading)
        expectElapsed(s, 300...300, "前提：経過 5:00")

        s.setClock(WallClock("2026-10-21T21:15:00"))
        expectElapsed(s, 0...0, "時計を戻した後の経過")
        // 「-」（U+002D）と、数の書式が使うことのある負の記号（U+2212）の両方を数える。
        let negative = s.app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@", "-", "\u{2212}"))
        XCTAssertEqual(negative.count, 0, "「-」で始まる表示は0個")
        s.expectState(.reading)
        s.shot("AC41_時計を戻した後", self)
    }

    // MARK: AC-58、AC-59

    /// AC-58 と AC-59 の共通の前半：経過10:00の reading、一時停止の保存が1回だけ失敗する（session_pause:1）。一時停止して60秒たつ。
    @MainActor
    private func failPause(file: StaticString = #filePath, line: UInt = #line) -> AppSession {
        let s = launch(active: Fixture.reading(Fixture.botchanId, elapsed: 600), fail: "session_pause:1")
        s.expectState(.reading, file: file, line: line)
        s.tap("reading.pause", file: file, line: line)
        s.expectSaveFailed("一時停止の保存の失敗", file: file, line: line)
        s.noteRetryLabel(L10n.errorRetryPause, "AC58_一時停止")  // design 6 の文。AC の Then の外なので、違っても AC の判定に数えない（L10n.swift の noteRetryLabel）
        s.advance(seconds: 60, file: file, line: line)
        return s
    }

    /// AC-58：一時停止の保存の失敗の60秒後、error.saveFailed と error.retry が1個ずつ、reading のまま、
    /// 経過は「11分0秒」か「11分1秒」、記録は1件のまま。
    @MainActor
    func test_AC58_pauseFailureKeepsReading() throws {
        let s = failPause()
        s.expectSaveFailed("60秒後")
        s.expectState(.reading)
        expectElapsed(s, 660...661, "60秒後の経過（11:00 か 11:01）")
        s.shot("AC58_一時停止の失敗", self)
        s.expectSessionCount(1, bookId: Fixture.botchanId, "記録は1件のまま")
    }

    /// AC-59：AC-58 の後に error.retry を押し、さらに60秒たつと、paused、経過は「11分0秒」か「11分1秒」のまま、
    /// error.saveFailed は0個、記録は1件のまま。
    @MainActor
    func test_AC59_pauseRetryStopsAtRetryTime() throws {
        let s = failPause()
        s.tap("error.retry")
        s.expectState(.paused)
        s.advance(seconds: 60)
        s.expectState(.paused)
        expectElapsed(s, 660...661, "再試行の60秒後の経過（11:00 か 11:01 のまま）")
        s.expectNoSaveFailed("再試行の後")
        s.shot("AC59_一時停止の再試行の後", self)
        s.expectSessionCount(1, bookId: Fixture.botchanId, "記録は1件のまま")
    }

    // MARK: AC-60、AC-61

    /// AC-60 と AC-61 の共通の前半：経過5:00の paused、再開の保存が1回だけ失敗する（session_resume:1）。再開して60秒たつ。
    @MainActor
    private func failResume(file: StaticString = #filePath, line: UInt = #line) -> AppSession {
        let s = launch(active: pausedAtFive, fail: "session_resume:1")
        s.expectState(.paused, file: file, line: line)
        s.tap("reading.resume", file: file, line: line)
        s.expectSaveFailed("再開の保存の失敗", file: file, line: line)
        s.noteRetryLabel(L10n.errorRetryResume, "AC60_再開")  // design 6 の文。AC の Then の外なので、違っても AC の判定に数えない（L10n.swift の noteRetryLabel）
        s.advance(seconds: 60, file: file, line: line)
        return s
    }

    /// AC-60：再開の保存の失敗の60秒後、error.saveFailed と error.retry が1個ずつ、paused のまま、経過は「5分0秒」のまま、記録は1件のまま。
    @MainActor
    func test_AC60_resumeFailureKeepsPaused() throws {
        let s = failResume()
        s.expectSaveFailed("60秒後")
        s.expectState(.paused)
        expectElapsed(s, 300...300, "60秒後の経過（5:00 のまま）")
        s.shot("AC60_再開の失敗", self)
        s.expectSessionCount(1, bookId: Fixture.botchanId, "記録は1件のまま")
    }

    /// AC-61：AC-60 の後に error.retry を押し、さらに60秒たつと、reading、経過は「6分0秒」か「6分1秒」
    /// （失敗から再試行までの60秒は足されない）、error.saveFailed は0個、記録は1件のまま。
    @MainActor
    func test_AC61_resumeRetryStartsAtRetryTime() throws {
        let s = failResume()
        s.tap("error.retry")
        s.expectState(.reading)
        s.advance(seconds: 60)
        expectElapsed(s, 360...361, "再試行の60秒後の経過（6:00 か 6:01）")
        s.expectNoSaveFailed("再試行の後")
        s.shot("AC61_再開の再試行の後", self)
        s.expectSessionCount(1, bookId: Fixture.botchanId, "記録は1件のまま")
    }

    // MARK: AC-62、AC-63

    /// AC-62 と AC-63 の共通の前半：「終える」の保存が1回だけ失敗する（session_begin_finish:1）。
    /// (a) 経過10:00の reading、(b) 経過5:00の paused。終えて60秒たつ。
    @MainActor
    private func failBeginFinish(paused: Bool, file: StaticString = #filePath, line: UInt = #line) -> AppSession {
        let active = paused ? pausedAtFive : Fixture.reading(Fixture.botchanId, elapsed: 600)
        let s = launch(active: active, fail: "session_begin_finish:1")
        s.expectState(paused ? .paused : .reading, file: file, line: line)
        s.tap("reading.finish", file: file, line: line)
        s.expectSaveFailed("「終える」の保存の失敗", file: file, line: line)
        s.noteRetryLabel(L10n.errorRetryFinish, paused ? "AC62_終える_一時停止中" : "AC62_終える_読書中")  // design 6 の文。AC の Then の外なので、違っても AC の判定に数えない（L10n.swift の noteRetryLabel）
        s.advance(seconds: 60, file: file, line: line)
        return s
    }

    /// AC-62 の Then（(a) と (b) で共通の所と、状態と経過）。
    @MainActor
    private func assertAC62(paused: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let s = failBeginFinish(paused: paused, file: file, line: line)
        let name = paused ? "paused" : "reading"
        s.expectSaveFailed("\(name)：60秒後", file: file, line: line)
        XCTAssertEqual(s.count("session.finish.save"), 0, "\(name)：session.finish.save は0個", file: file, line: line)
        XCTAssertEqual(s.count("session.state.finishing"), 0, "\(name)：session.state.finishing は0個", file: file, line: line)
        if paused {
            s.expectState(.paused, file: file, line: line)
            expectElapsed(s, 300...300, "paused：60秒後の経過（5:00 のまま）", file: file, line: line)
        } else {
            s.expectState(.reading, file: file, line: line)
            expectElapsed(s, 660...661, "reading：60秒後の経過（11:00 か 11:01）", file: file, line: line)
        }
        s.shot("AC62_\(name)_終えるの失敗", self)
        s.expectSessionCount(1, bookId: Fixture.botchanId, "\(name)：記録は1件のまま", file: file, line: line)
    }

    /// AC-62 (a)：reading（経過10:00）で「終える」の保存に失敗。
    @MainActor
    func test_AC62_beginFinishFailureWhileReading() throws {
        assertAC62(paused: false)
    }

    /// AC-62 (b)：paused（経過5:00）で「終える」の保存に失敗。
    @MainActor
    func test_AC62_beginFinishFailureWhilePaused() throws {
        assertAC62(paused: true)
    }

    /// AC-63 の Then：error.retry を押し、さらに60秒たつと、finishing、session.finish.save が1個、
    /// session.finish.minutes の value は (a)「11」（「10」でも「12」でもない）、(b)「5」。error.saveFailed は0個、記録は1件のまま。
    @MainActor
    private func assertAC63(paused: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let s = failBeginFinish(paused: paused, file: file, line: line)
        let name = paused ? "paused" : "reading"
        s.tap("error.retry", file: file, line: line)
        Wait.exists(s.el("session.finish.save"), "\(name)：終える入力", file: file, line: line)
        s.advance(seconds: 60, file: file, line: line)
        s.expectState(.finishing, file: file, line: line)
        XCTAssertEqual(s.count("session.finish.save"), 1, "\(name)：session.finish.save は1個", file: file, line: line)
        Wait.value(s.el("session.finish.minutes"), equals: paused ? "5" : "11", "\(name)：読んだ時間の欄", file: file, line: line)
        s.expectNoSaveFailed("\(name)：再試行の後", file: file, line: line)
        s.shot("AC63_\(name)_終えるの再試行の後", self)
        s.expectSessionCount(1, bookId: Fixture.botchanId, "\(name)：記録は1件のまま", file: file, line: line)
    }

    /// AC-63 (a)
    @MainActor
    func test_AC63_beginFinishRetryWhileReading() throws {
        assertAC63(paused: false)
    }

    /// AC-63 (b)
    @MainActor
    func test_AC63_beginFinishRetryWhilePaused() throws {
        assertAC63(paused: true)
    }

    // MARK: AC-66、AC-67

    /// AC-66 と AC-67 の共通の前半：経過0:30の reading、60秒未満で終える保存が1回だけ失敗する（session_discard:1）。終えて10秒たつ。
    @MainActor
    private func failDiscard(file: StaticString = #filePath, line: UInt = #line) -> AppSession {
        let s = launch(active: Fixture.reading(Fixture.botchanId, elapsed: 30), fail: "session_discard:1")
        s.expectState(.reading, file: file, line: line)
        expectElapsed(s, 30...30, "前提：経過 0:30", file: file, line: line)
        s.tap("reading.finish", file: file, line: line)
        s.expectSaveFailed("60秒未満で終える保存の失敗", file: file, line: line)
        s.noteRetryLabel(L10n.errorRetryFinish, "AC66_60秒未満で終える")  // design 6 の文。AC の Then の外なので、違っても AC の判定に数えない（L10n.swift の noteRetryLabel）
        s.advance(seconds: 10, file: file, line: line)
        return s
    }

    /// AC-66：60秒未満で終える保存の失敗の10秒後、error.saveFailed と error.retry が1個ずつ、reading のまま、
    /// 経過は「0分40秒」か「0分41秒」、session.finish.tooShort と session.finish.save は0個、記録は1件のまま。
    @MainActor
    func test_AC66_discardFailureKeepsReading() throws {
        let s = failDiscard()
        s.expectSaveFailed("10秒後")
        s.expectState(.reading)
        expectElapsed(s, 40...41, "10秒後の経過（0:40 か 0:41）")
        XCTAssertEqual(s.count("session.finish.tooShort"), 0, "session.finish.tooShort は0個")
        XCTAssertEqual(s.count("session.finish.save"), 0, "session.finish.save は0個")
        s.shot("AC66_60秒未満で終える失敗", self)
        s.expectSessionCount(1, bookId: Fixture.botchanId, "記録は1件のまま")
    }

    /// AC-67：AC-66 の後（経過0:40）に error.retry を押すと、idle、book.title が「坊っちゃん」の詳細、session.finish.tooShort が1個、
    /// 「記録 1件」のまま、reading.elapsed と error.saveFailed は0個、アラートは0個。
    /// 40秒で押すので、再試行は session_discard の2回目の保存になり通る（T5 の備考）。
    @MainActor
    func test_AC67_discardRetryShowsNoticeWithoutRecord() throws {
        let s = failDiscard()
        s.tap("error.retry")

        Wait.label(s.el("book.title"), equals: Fixture.botchan, "再試行の後の本の詳細")
        s.expectState(.idle)
        Wait.label(s.el("session.finish.tooShort"), equals: L10n.sessionFinishTooShort, "session.finish.tooShort")
        XCTAssertEqual(s.count("session.finish.tooShort"), 1, "session.finish.tooShort は1個")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "記録は1件のまま")
        Wait.gone(s.el("reading.elapsed"), "reading.elapsed")
        XCTAssertEqual(s.count("reading.elapsed"), 0, "reading.elapsed は0個")
        s.expectNoSaveFailed("再試行の後")
        XCTAssertEqual(s.app.alerts.count, 0, "アラートは0個")
        s.shot("AC67_60秒未満の再試行の後", self)
    }
}
