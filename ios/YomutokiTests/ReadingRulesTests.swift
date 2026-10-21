import Foundation
import Testing

@testable import Yomutoki

/// 題名の整え方（PRD 10、data-model.md の Book.title、設計メモ 11 の 4 の例）。
struct TitleRulesTests {
    @Test(
        "前後の空白4種を除き、中の改行を1つずつ半角空白にする",
        arguments: zip(
            [
                "  坊っちゃん  ",
                "\u{3000}こころ\u{3000}",
                "\t題\t",
                "\n\r\n題\u{2028}\u{2029}",
                "上\r\n下",
                "a\nb\rc\u{2028}d\u{2029}e",
                "a\n\nb",
                "a\tb",
                "a \u{3000} b",
            ],
            [
                "坊っちゃん",
                "こころ",
                "題",
                "題",
                "上 下",
                "a b c d e",
                "a  b",
                "a\tb",
                "a \u{3000} b",
            ]))
    func normalizes(raw: String, expected: String) {
        #expect(TitleRules.normalized(raw) == expected)
        #expect(TitleRules.stored(raw) == expected)
    }

    @Test("空白と改行だけの題名は保存できない（AC-3）")
    func emptyAfterTrimIsInvalid() {
        #expect(!TitleRules.isValid(" \u{3000}\t\n\r\n\u{2028}\u{2029}"))
        #expect(TitleRules.stored("\u{3000}\u{3000}").isEmpty)
        #expect(TitleRules.isValid(" a "))
    }

    @Test("100字はそのまま、101字は先頭の100字（書記素で数える）")
    func cutsAtHundredCharacters() {
        let hundred = String(repeating: "あ", count: 100)
        #expect(TitleRules.stored(hundred) == hundred)
        #expect(!TitleRules.exceedsLimit(hundred))
        let hundredOne = hundred + "い"
        #expect(TitleRules.stored(hundredOne) == hundred)
        #expect(TitleRules.exceedsLimit(hundredOne))
    }

    @Test("結合した絵文字は1字（101個は100個に切る）")
    func countsGraphemeClusters() {
        let family = "👨‍👩‍👧"
        let stored = TitleRules.stored(String(repeating: family, count: 101))
        #expect(stored.count == 100)
        #expect(stored == String(repeating: family, count: 100))
    }

    @Test("切った後に末尾の空白を除く（99字＋U+3000＋1字は99字）")
    func trimsAfterCut() {
        let ninetyNine = String(repeating: "あ", count: 99)
        let raw = ninetyNine + "\u{3000}" + "い"
        #expect(TitleRules.normalized(raw).count == 101)
        #expect(TitleRules.stored(raw) == ninetyNine)
    }

    @Test("CRLF は1つの改行として空白1つになる")
    func crlfIsOneLineBreak() {
        #expect(TitleRules.stored("a\r\nb") == "a b")
        #expect(TitleRules.stored("a\r\n\r\nb") == "a  b")
    }

    @Test("10万字の貼り付けでも落ちず100字になる")
    func hugePaste() {
        let raw = String(repeating: "本", count: 100_000)
        #expect(TitleRules.stored(raw).count == 100)
    }
}

/// 経過と丸め（data-model.md の「計算する値」、PRD 10 の丸め）。
struct ReadingMathTests {
    let start = Date(timeIntervalSince1970: 1_792_585_800)

    @Test("経過 = 今 − 開始 − 止めていた合計（一時停止を除く）")
    func elapsedExcludesPauses() {
        let active = ActiveSnapshot(
            bookID: UUID(), state: .reading, startedAt: start, pausedTotalSeconds: 50, pausedAt: nil, finishedAt: nil,
            wasPaused: true)
        #expect(active.elapsedSeconds(now: start.addingTimeInterval(180)) == 130)
    }

    @Test("paused は pausedAt、finishing は finishedAt で止まる")
    func elapsedStopsAtPauseAndFinish() {
        let paused = ActiveSnapshot(
            bookID: UUID(), state: .paused, startedAt: start, pausedTotalSeconds: 0,
            pausedAt: start.addingTimeInterval(300), finishedAt: nil, wasPaused: true)
        #expect(paused.elapsedSeconds(now: start.addingTimeInterval(9_999)) == 300)
        let finishing = ActiveSnapshot(
            bookID: UUID(), state: .finishing, startedAt: start, pausedTotalSeconds: 0, pausedAt: nil,
            finishedAt: start.addingTimeInterval(659), wasPaused: false)
        #expect(finishing.elapsedSeconds(now: start.addingTimeInterval(9_999)) == 659)
        #expect(finishing.initialMinutes == 10)
    }

    @Test("時刻が戻っても経過は負にならない（AC-41）")
    func elapsedNeverNegative() {
        let active = ActiveSnapshot(
            bookID: UUID(), state: .reading, startedAt: start, pausedTotalSeconds: 0, pausedAt: nil, finishedAt: nil,
            wasPaused: false)
        #expect(active.elapsedSeconds(now: start.addingTimeInterval(-3_600)) == 0)
        #expect(ReadingMath.wholeSeconds(-.infinity) == 0)
        #expect(ReadingMath.wholeSeconds(.nan) == 0)
        #expect(ReadingMath.wholeSeconds(.infinity) == 0)
    }

    @Test("秒は切り捨て（59.9秒は59秒）、秒から分も切り捨て（90秒は1分）")
    func floorsSecondsAndMinutes() {
        #expect(ReadingMath.wholeSeconds(59.9) == 59)
        #expect(ReadingMath.wholeMinutes(seconds: 90) == 1)
        #expect(ReadingMath.wholeMinutes(seconds: 59) == 0)
        #expect(ReadingMath.wholeMinutes(seconds: -30) == 0)
    }

    @Test("合計は秒で足してから分にする（90秒の記録3件は4分）")
    func totalsAddSecondsFirst() {
        #expect(ReadingMath.totalMinutes([90, 90, 90]) == 4)
    }

    @Test("進み具合は切り捨て（299/300 は99%）。総ページ数がなければ出さない")
    func progressFloors() {
        #expect(ReadingMath.progressPercent(lastPage: 299, totalPages: 300) == 99)
        #expect(ReadingMath.progressPercent(lastPage: 72, totalPages: 300) == 24)
        #expect(ReadingMath.progressPercent(lastPage: 300, totalPages: 300) == 100)
        #expect(ReadingMath.progressPercent(lastPage: 40, totalPages: nil) == nil)
    }

    @Test("読み返しは読んだページ0（AC-29）、ページを入れなければ nil")
    func pagesReadNeverNegative() {
        #expect(ReadingMath.pagesRead(endPage: 30, previousLastPage: 72) == 0)
        #expect(ReadingMath.pagesRead(endPage: 102, previousLastPage: 72) == 30)
        #expect(ReadingMath.pagesRead(endPage: nil, previousLastPage: 72) == nil)
    }

    @Test("週の始まりは暦の設定に従い、次の週の始まりは含めない（AC-15、AC-44）")
    func weekBoundaries() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        calendar.firstWeekday = 2
        // 2026-10-21T21:30:00+09:00 は水曜。月曜始まりの週は 2026-10-19T00:00 から。
        let week = try #require(ReadingMath.week(containing: start, calendar: calendar))
        let monday = start.addingTimeInterval(-(2 * 86_400 + 21 * 3_600 + 30 * 60))
        #expect(week.start == monday)
        #expect(ReadingMath.contains(week, monday))
        #expect(!ReadingMath.contains(week, monday.addingTimeInterval(-1)))
        #expect(!ReadingMath.contains(week, monday.addingTimeInterval(7 * 86_400)))
        calendar.firstWeekday = 1
        let sundayWeek = try #require(ReadingMath.week(containing: start, calendar: calendar))
        #expect(sundayWeek.start == monday.addingTimeInterval(-86_400))
    }
}
