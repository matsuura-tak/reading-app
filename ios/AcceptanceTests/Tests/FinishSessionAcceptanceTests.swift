import XCTest

/// S5 読書を終える：ページ、分、範囲の外、保存の失敗（AC-9〜AC-12、AC-19、AC-29、AC-30）。
final class FinishSessionAcceptanceTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// seed の記録（Seeds.botchanOneSession の1件）。新しい記録の行を見分けるのに使う。
    private let seededSessions = [Fixture.id(101)]

    // MARK: AC-9

    /// AC-9：総ページ数300、最後のページ40で reading。終えて今のページ72を入れて保存すると、記録が1件増え、
    /// その行の読んだページは「32」、最後のページは「72」、進み具合は「24%」。終了して起動し直しても同じ。
    @MainActor
    func test_AC9_enteringPageRecordsProgress() throws {
        let seed = Seeds.botchanOneSession(lastPage: 40, active: Fixture.reading(Fixture.botchanId, elapsed: 600))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.reading)
        s.finishAndSave(title: Fixture.botchan, page: "72")

        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "記録は1件増えて2件")
        guard let row = s.singleNewSessionRow(excluding: seededSessions) else { return }
        Wait.label(row.descendants(matching: .any)["session.row.page"], equals: L10n.pagesRead(32), "その記録の行の読んだページ")
        Wait.value(s.el("book.lastPage"), equals: "72", "最後のページ")
        Wait.value(s.el("book.progress"), equals: L10n.percent(24), "進み具合")
        s.shot("AC9_本の詳細", self)

        s.relaunch(now: Fixture.now)
        s.openBook(id: Fixture.botchanId)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "起動し直した後の記録の数")
        Wait.value(s.el("book.lastPage"), equals: "72", "起動し直した後の最後のページ")
        Wait.value(s.el("book.progress"), equals: L10n.percent(24), "起動し直した後の進み具合")
    }

    // MARK: AC-10

    /// AC-10：最後のページ40、記録1件で reading。ページを入れずに保存すると、記録は「2件」、新しい行に session.row.page が0個、
    /// 最後のページは「40」のまま、状態は idle。
    @MainActor
    func test_AC10_finishWithoutPage() throws {
        let seed = Seeds.botchanOneSession(lastPage: 40, active: Fixture.reading(Fixture.botchanId, elapsed: 600))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.reading)
        s.finishAndSave(title: Fixture.botchan)

        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "記録は2件")
        guard let row = s.singleNewSessionRow(excluding: seededSessions) else { return }
        XCTAssertEqual(row.descendants(matching: .any).matching(identifier: "session.row.page").count, 0, "新しい行のページの表示は0個")
        Wait.value(s.el("book.lastPage"), equals: "40", "最後のページは40のまま")
        s.expectState(.idle)
    }

    // MARK: AC-11

    /// AC-11：総ページ数300で finishing。今のページ301で保存しようとすると、記録は増えず、
    /// session.finish.pageOutOfRange（「0から300までの数字で入れてください。」）が出て、finishing のまま。
    /// 境界の相手として、300 に直すと誤りは消え、保存できる形（session.finish.save が有効）になる。
    @MainActor
    func test_AC11_pageAboveTotalPagesIsRejected() throws {
        let seed = Seeds.botchanOneSession(lastPage: 40, active: Fixture.finishing(Fixture.botchanId, elapsed: 600))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.finishing)

        s.replaceText("session.finish.page", with: "301")
        s.el("session.finish.save").tap()
        Wait.label(s.el("session.finish.pageOutOfRange"), equals: L10n.sessionFinishPageOutOfRange(300), "session.finish.pageOutOfRange")
        s.expectState(.finishing)
        XCTAssertTrue(s.el("session.finish.save").exists, "終える入力は開いたまま")
        s.shot("AC11_ページが範囲の外", self)

        s.replaceText("session.finish.page", with: "300")
        Wait.gone(s.el("session.finish.pageOutOfRange"), "300 では誤りの文")
        XCTAssertTrue(s.el("session.finish.save").isEnabled, "300 なら保存できる")

        s.goToBookDetail(id: Fixture.botchanId)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "記録は増えていない")
    }

    // MARK: AC-12

    /// AC-12：経過180分で finishing。読んだ時間を45分に直して保存すると、その行は「45分」、本の合計は保存の前（15分）より45分増えて「60分」。
    @MainActor
    func test_AC12_editMinutesWhenFinishing() throws {
        var seed = Seeds.botchanOneSession(lastPage: 40, active: Fixture.finishing(Fixture.botchanId, elapsed: 180 * 60))
        seed.sessions = [
            Fixture.session(101, book: Fixture.botchanId, startedAt: WallClock("2026-10-20T21:00:00"), seconds: 900, endPage: 40, pagesRead: 40)
        ]
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.finishing)
        Wait.value(s.el("session.finish.minutes"), equals: "180", "前提：分の欄の初めの値は経過の180")

        s.replaceText("session.finish.minutes", with: "45")
        s.tap("session.finish.save")
        Wait.label(s.el("book.title"), equals: Fixture.botchan, "保存の後の本の詳細")
        guard let row = s.singleNewSessionRow(excluding: seededSessions) else { return }
        Wait.label(row.descendants(matching: .any)["session.row.minutes"], equals: L10n.minutes(45), "その記録の行の読んだ時間")
        Wait.value(s.el("book.totalTime"), equals: L10n.minutes(15 + 45), "本の合計時間（15分＋45分）")
        s.shot("AC12_分を直した記録", self)
    }

    // MARK: AC-19

    /// AC-19：記録の保存が毎回失敗する（UITEST_FAIL=session_finish:*）。経過 10:00 で終えた finishing で保存すると、
    /// error.saveFailed と error.retry が出て、finishing のまま、読んだ時間は「10分」のまま、記録の数は変わらない。
    @MainActor
    func test_AC19_saveFailureKeepsFinishingSession() throws {
        var config = LaunchConfig.seeded(Seeds.botchanOneSession(lastPage: 40, active: Fixture.finishing(Fixture.botchanId, elapsed: 600)))
        config.fail = "session_finish:*"
        let s = AppSession.launch(config)
        s.expectState(.finishing)
        Wait.value(s.el("session.finish.minutes"), equals: "10", "前提：読んだ時間は10分")

        s.tap("session.finish.save")
        Wait.label(s.el("error.saveFailed"), equals: L10n.errorSaveFailed, "error.saveFailed")
        Wait.exists(s.el("error.retry"), "error.retry")
        s.expectState(.finishing)
        Wait.value(s.el("session.finish.minutes"), equals: "10", "失敗の後も読んだ時間は10分")
        s.shot("AC19_保存の失敗", self)

        s.advance(seconds: 120)
        Wait.value(s.el("session.finish.minutes"), equals: "10", "2分たっても読んだ時間は10分（終えた時刻で止まっている）")
        s.expectState(.finishing)

        s.goToBookDetail(id: Fixture.botchanId)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "記録の数は変わらない")
    }

    // MARK: AC-29

    /// AC-29：総ページ数300、最後のページ72で reading。今のページ50で保存すると、記録が1件増え、その行の読んだページは「0」、
    /// 最後のページは「50」、進み具合は「16%」（16.66…% の切り捨て）。
    @MainActor
    func test_AC29_lowerPageMeansRereading() throws {
        let seed = Seeds.botchanOneSession(lastPage: 72, active: Fixture.reading(Fixture.botchanId, elapsed: 600))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.reading)
        s.finishAndSave(title: Fixture.botchan, page: "50")

        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(2), "記録は1件増えて2件")
        guard let row = s.singleNewSessionRow(excluding: seededSessions) else { return }
        Wait.label(row.descendants(matching: .any)["session.row.page"], equals: L10n.pagesRead(0), "その記録の行の読んだページ")
        Wait.value(s.el("book.lastPage"), equals: "50", "最後のページ")
        Wait.value(s.el("book.progress"), equals: L10n.percent(16), "進み具合")
        s.shot("AC29_読み返し", self)
    }

    // MARK: AC-30

    /// AC-30：経過180分で finishing。読んだ時間を0分、181分にして保存しようとすると、記録は増えず、
    /// session.finish.minutesOutOfRange（「1から180までの数字で入れてください。」）が出て、finishing のまま。
    /// 境界の相手として、1 と 180 では誤りは消え、session.finish.save は有効。
    @MainActor
    func test_AC30_minutesOutsideOneToElapsedAreRejected() throws {
        let seed = Seeds.botchanOneSession(lastPage: 40, active: Fixture.finishing(Fixture.botchanId, elapsed: 180 * 60))
        let s = AppSession.launch(.seeded(seed))
        s.expectState(.finishing)
        Wait.value(s.el("session.finish.minutes"), equals: "180", "前提：経過は180分")

        for rejected in ["0", "181"] {
            s.replaceText("session.finish.minutes", with: rejected)
            s.el("session.finish.save").tap()
            Wait.label(s.el("session.finish.minutesOutOfRange"), equals: L10n.sessionFinishMinutesOutOfRange(180), "\(rejected)分：session.finish.minutesOutOfRange")
            s.expectState(.finishing)
            XCTAssertTrue(s.el("session.finish.save").exists, "\(rejected)分：終える入力は開いたまま")
            s.shot("AC30_\(rejected)分", self)
        }
        for accepted in ["1", "180"] {
            s.replaceText("session.finish.minutes", with: accepted)
            Wait.gone(s.el("session.finish.minutesOutOfRange"), "\(accepted)分では誤りの文")
            XCTAssertTrue(s.el("session.finish.save").isEnabled, "\(accepted)分なら保存できる")
        }

        s.goToBookDetail(id: Fixture.botchanId)
        Wait.label(s.el("book.sessionCount"), equals: L10n.sessionCount(1), "記録は増えていない")
    }
}
