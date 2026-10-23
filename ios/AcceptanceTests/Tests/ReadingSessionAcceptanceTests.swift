import XCTest

/// 読み始め、経過、一時停止、裏と強制終了、前の本、読書中は1件（AC-5〜AC-8、AC-13、AC-17、AC-25〜AC-27）。
/// 時計は UITEST_NOW と UITEST_CLOCK_FROZEN で止め、T16 で決まった秒だけ進める（実時間で待たない）。
final class ReadingSessionAcceptanceTests: AcceptanceTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: AC-5

    /// AC-5：記録1件の「坊っちゃん」で、ホームの home.startReading を1回押すと reading になり、
    /// 経過は 0:00 か 0:01、3秒後に 0:02 以上 0:04 以下。
    @MainActor
    func test_AC5_previousBookStartsFromHomeInOneTap() throws {
        let s = AppSession.launch(.seeded(Seeds.botchanOneSession(lastPage: 72)))
        s.expectState(.idle)
        let start = s.el("home.startReading")
        Wait.exists(start, "home.startReading")
        start.tap()

        s.expectState(.reading)
        Wait.label(s.el("reading.title"), equals: Fixture.botchan, "読書中の本の題名")
        Wait.label(s.el("reading.elapsed"), in: L10n.elapsedLabels(0...1), "押した直後の経過（0:00 か 0:01）")
        s.shot("AC5_読み始めた直後", self)
        s.advance(seconds: 3)
        Wait.label(s.el("reading.elapsed"), in: L10n.elapsedLabels(2...4), "3秒後の経過（0:02〜0:04）")
    }

    /// AC-5 の「操作から0.5秒以内」：T20 の区間 FirstElapsedShown を XCTOSSignpostMetric（A50）で5回測る。
    /// XCTest の measure は基準値なしでは落ちないので、合否は G3 で xcresult の値（5回の平均 0.5秒以下）を読んで決める（test-plan の 2）。
    @MainActor
    func test_AC5_startToFirstElapsedMeasuredBySignpost() throws {
        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        options.iterationCount = 5
        let metric = XCTOSSignpostMetric(subsystem: "yomutoki", category: "perf", name: "FirstElapsedShown")
        measure(metrics: [metric], options: options) {
            let s = AppSession.launch(.seeded(Seeds.botchanOneSession(lastPage: 72)))
            let start = s.el("home.startReading")
            Wait.exists(start, "home.startReading")
            self.startMeasuring()
            start.tap()
            Wait.exists(s.el("reading.elapsed"), "reading.elapsed")
            self.stopMeasuring()
            s.app.terminate()
        }
    }

    // MARK: AC-6

    /// AC-6：経過 0:00 から60秒読んで一時停止、60秒後に再開、さらに60秒読んで終えて保存すると、その記録の行は「2分」。
    @MainActor
    func test_AC6_pausedTimeIsNotCounted() throws {
        let seed = Seeds.botchanOneSession(active: Fixture.reading(Fixture.botchanId, elapsed: 0))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.reading)
        Wait.label(s.el("reading.elapsed"), equals: L10n.elapsedLabel(0), "前提：経過 0:00")

        s.advance(seconds: 60)
        s.tap("reading.pause")
        s.expectState(.paused)
        s.advance(seconds: 60)
        Wait.label(s.el("reading.elapsed"), equals: L10n.elapsedLabel(60), "一時停止の間は 1:00 のまま")
        s.tap("reading.resume")
        s.expectState(.reading)
        s.advance(seconds: 60)
        Wait.label(s.el("reading.elapsed"), equals: L10n.elapsedLabel(120), "再開して60秒後は 2:00")

        s.finishAndSave(title: Fixture.botchan)
        guard let row = s.singleNewSessionRow(excluding: [Fixture.id(101)]) else { return }
        Wait.label(row.descendants(matching: .any)["session.row.minutes"], equals: L10n.minutes(2), "その記録の行の読んだ時間")
        s.shot("AC6_記録の行", self)
    }

    // MARK: AC-7

    /// AC-7：reading で経過 1:00 のとき、ホーム画面に戻ってアプリを裏に回し、10分後に開き直すと、
    /// reading のままで経過は 11:00 以上 11:05 以下。10分は T16 で裏の間に進める（前に出てから効く）。
    @MainActor
    func test_AC7_elapsedKeepsRunningInBackground() throws {
        let seed = Seeds.botchanOneSession(active: Fixture.reading(Fixture.botchanId, elapsed: 60))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.reading)
        Wait.label(s.el("reading.elapsed"), equals: L10n.elapsedLabel(60), "前提：経過 1:00")

        XCUIDevice.shared.press(.home)
        let foreground = Int(XCUIApplication.State.runningForeground.rawValue)
        XCTAssertTrue(Wait.until(NSPredicate(format: "state != %ld", foreground), s.app), "アプリが裏に回った")
        s.advance(seconds: 600)  // URL を開くとアプリが前に出て、時計が進む
        s.app.activate()

        s.expectState(.reading)
        Wait.label(s.el("reading.elapsed"), in: L10n.elapsedLabels(660...665), "開き直した後の経過（11:00〜11:05）")
        s.shot("AC7_開き直した後", self)
    }

    // MARK: AC-8

    /// AC-8：「坊っちゃん」で reading、経過 5:00 のときに強制終了し、5分後に起動すると、
    /// 読書中の画面が reading で戻り、経過は 10:00 以上 10:05 以下。
    @MainActor
    func test_AC8_forceQuitRestoresReadingAndElapsed() throws {
        let seed = Seeds.botchanOneSession(active: Fixture.reading(Fixture.botchanId, elapsed: 300))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.reading)
        Wait.label(s.el("reading.elapsed"), equals: L10n.elapsedLabel(300), "前提：経過 5:00")

        s.relaunch(now: Fixture.now.adding(minutes: 5))
        s.expectState(.reading)
        Wait.label(s.el("reading.title"), equals: Fixture.botchan, "戻った読書中の画面の題名")
        Wait.label(s.el("reading.elapsed"), in: L10n.elapsedLabels(600...605), "起動し直した後の経過（10:00〜10:05）")
        s.shot("AC8_起動し直した後", self)
    }

    // MARK: AC-13

    /// AC-13：経過 0:59 の reading で終えると、記録は増えず、session.finish.tooShort が出て、idle に戻る。
    @MainActor
    func test_AC13_underOneMinuteIsNotRecorded() throws {
        let seed = Seeds.botchanOneSession(active: Fixture.reading(Fixture.botchanId, elapsed: 59))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.reading)
        Wait.label(s.el("reading.elapsed"), equals: L10n.elapsedLabel(59), "前提：経過 0:59")

        s.tap("reading.finish")
        Wait.label(s.el("session.finish.tooShort"), equals: L10n.sessionFinishTooShort, "session.finish.tooShort")
        s.expectState(.idle)
        XCTAssertEqual(s.count("session.finish.save"), 0, "終える入力は出ない")
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "記録は1件のまま")
        s.shot("AC13_1分未満", self)
    }

    /// AC-13 の境界の相手：経過 1:00 ちょうどなら1分未満ではないので、終える入力（finishing）が開き、分の欄は「1」。
    @MainActor
    func test_AC13_boundarySixtySecondsOpensFinishInput() throws {
        let seed = Seeds.botchanOneSession(active: Fixture.reading(Fixture.botchanId, elapsed: 60))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.reading)
        s.tap("reading.finish")
        Wait.exists(s.el("session.finish.save"), "終える入力")
        s.expectState(.finishing)
        Wait.value(s.el("session.finish.minutes"), equals: "1", "分の欄の初めの値")
        XCTAssertEqual(s.count("session.finish.tooShort"), 0, "1分未満の知らせは出ない")
    }

    // MARK: AC-17

    /// AC-17（reading）：「坊っちゃん」が reading のとき、「こころ」の book.startReading は無効で、読書中は1件のまま。
    @MainActor
    func test_AC17_cannotStartAnotherBookWhileReading() throws {
        try assertAC17(state: "reading")
    }

    /// AC-17（paused）
    @MainActor
    func test_AC17_cannotStartAnotherBookWhilePaused() throws {
        try assertAC17(state: "paused")
    }

    /// AC-17（finishing。終える入力をやめてから「こころ」を開く。AC-46）
    @MainActor
    func test_AC17_cannotStartAnotherBookWhileFinishing() throws {
        try assertAC17(state: "finishing")
    }

    @MainActor
    private func assertAC17(state: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let s = AppSession.launch(.seeded(Seeds.twoBooks(active: Fixture.active(state, book: Fixture.botchanId))))
        let expected: SessionState = state == "paused" ? .paused : .reading
        if state == "finishing" {
            s.expectState(.finishing, file: file, line: line)
            s.tap("session.finish.cancel", file: file, line: line)
            Wait.gone(s.el("session.finish.save"), "終える入力", file: file, line: line)
        }
        s.expectState(expected, file: file, line: line)
        s.goBack(file: file, line: line)
        s.openBook(id: Fixture.kokoroId, file: file, line: line)
        Wait.label(s.el("book.title"), equals: Fixture.kokoro, "「こころ」の詳細", file: file, line: line)

        let start = s.el("book.startReading")
        Wait.exists(start, "「こころ」の book.startReading", file: file, line: line)
        XCTAssertFalse(start.isEnabled, "\(state)：「こころ」の book.startReading は無効", file: file, line: line)
        start.tap()
        s.expectState(expected, file: file, line: line)
        XCTAssertEqual(s.count("reading.title"), 0, "\(state)：「こころ」の読書中の画面は出ない", file: file, line: line)
        s.shot("AC17_\(state)_こころの詳細", self)

        // 読書中の読書は1件のまま：ホームの戻る操作は1つで、その題名は「坊っちゃん」
        s.goBack(file: file, line: line)
        let resume = s.el("home.resumeReading")
        Wait.exists(resume, "home.resumeReading", file: file, line: line)
        XCTAssertEqual(s.count("home.resumeReading"), 1, "\(state)：読書中の本に戻る操作は1つ", file: file, line: line)
        XCTAssertEqual(s.count("home.startReading"), 0, "\(state)：home.startReading は0個", file: file, line: line)
        XCTAssertTrue(resume.label.hasPrefix(Fixture.botchan), "\(state)：読書中の本は「坊っちゃん」（label は「\(resume.label)」）", file: file, line: line)
    }

    // MARK: AC-25、AC-26

    /// AC-25：「坊っちゃん」の最後の記録は2日前、「こころ」は1日前に保存。home.startReading で「こころ」が reading になる。
    /// 「最後に追加した本」で決める作りで通らないよう、「こころ」を先に、「坊っちゃん」を後に追加した形にする（T17 の備考）。
    @MainActor
    func test_AC25_previousBookIsTheLastSavedOne() throws {
        let seed = Seed(
            books: [
                Fixture.book(2, Fixture.kokoro, totalPages: nil, lastPage: 40, addedAt: WallClock("2026-10-01T20:00:00")),
                Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 72, addedAt: WallClock("2026-10-02T20:00:00")),
            ],
            sessions: [
                // 2日前に保存
                Fixture.session(101, book: Fixture.botchanId, startedAt: Fixture.now.adding(days: -2).adding(minutes: -31), seconds: 1800, endPage: 72, pagesRead: 72),
                // 1日前に保存
                Fixture.session(201, book: Fixture.kokoroId, startedAt: Fixture.now.adding(days: -1).adding(minutes: -31), seconds: 1800, endPage: 40, pagesRead: 40),
            ])
        let s = AppSession.launch(.seeded(seed))
        s.tap("home.startReading")
        s.expectState(.reading)
        Wait.label(s.el("reading.title"), equals: Fixture.kokoro, "読書中の本の題名")
    }

    /// AC-26：記録が0件で「坊っちゃん」の後に「こころ」を追加。home.startReading で「こころ」が reading になる。
    @MainActor
    func test_AC26_withoutSessionsPreviousBookIsTheLastAdded() throws {
        let seed = Seed(books: [
            Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 0, addedAt: WallClock("2026-10-01T20:00:00")),
            Fixture.book(2, Fixture.kokoro, totalPages: nil, lastPage: 0, addedAt: WallClock("2026-10-02T20:00:00")),
        ])
        let s = AppSession.launch(.seeded(seed))
        s.tap("home.startReading")
        s.expectState(.reading)
        Wait.label(s.el("reading.title"), equals: Fixture.kokoro, "読書中の本の題名")
    }

    // MARK: AC-27

    /// AC-27（reading）：ホームに home.startReading は0個、home.resumeReading が1個で、その題名は「坊っちゃん」。
    @MainActor
    func test_AC27_homeShowsOnlyResumeWhileReading() throws {
        try assertAC27(state: "reading")
    }

    /// AC-27（paused）
    @MainActor
    func test_AC27_homeShowsOnlyResumeWhilePaused() throws {
        try assertAC27(state: "paused")
    }

    /// AC-27（finishing。S5 が出ている間はホームへ行けないので、終える入力をやめてから。design 1）
    @MainActor
    func test_AC27_homeShowsOnlyResumeWhileFinishing() throws {
        try assertAC27(state: "finishing")
    }

    @MainActor
    private func assertAC27(state: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let s = AppSession.launch(.seeded(Seeds.twoBooks(active: Fixture.active(state, book: Fixture.botchanId))))
        if state == "finishing" {
            s.expectState(.finishing, file: file, line: line)
            s.tap("session.finish.cancel", file: file, line: line)
            Wait.gone(s.el("session.finish.save"), "終える入力", file: file, line: line)
        }
        s.expectState(state == "paused" ? .paused : .reading, file: file, line: line)
        s.goBack(file: file, line: line)

        let resume = s.el("home.resumeReading")
        Wait.exists(resume, "home.resumeReading", file: file, line: line)
        XCTAssertEqual(s.count("home.startReading"), 0, "\(state)：home.startReading は0個", file: file, line: line)
        XCTAssertEqual(s.count("home.resumeReading"), 1, "\(state)：home.resumeReading は1個", file: file, line: line)
        XCTAssertTrue(resume.label.hasPrefix(Fixture.botchan), "\(state)：題名は「坊っちゃん」（label は「\(resume.label)」）", file: file, line: line)
        s.shot("AC27_\(state)_ホーム", self)
    }
}
