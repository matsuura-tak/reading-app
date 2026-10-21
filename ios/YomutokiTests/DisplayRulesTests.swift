import Foundation
import Testing

@testable import Yomutoki

/// design 7 の「入力の決まり」と「経過の表示と読み上げ」の表（見える文字）。
struct DisplayRulesTests {
    // MARK: 数字の欄（D-13）

    @Test(
        "前後の空白を除き、全角の数字は半角として読む",
        arguments: [
            ("72", 72), (" 72 ", 72), ("\u{3000}72\t", 72), ("７２", 72), ("0", 0), ("０", 0), ("9999", 9_999),
            ("10000", 10_000), ("007", 7),
        ])
    func parsesDigits(text: String, expected: Int) {
        #expect(NumberInput.parse(text) == .number(expected))
    }

    @Test("空と空白だけは empty", arguments: ["", " ", "\u{3000}", "\t\n"])
    func parsesEmpty(text: String) {
        #expect(NumberInput.parse(text) == .empty)
    }

    @Test(
        "桁区切り、小数点、符号、文字、中の空白は範囲の外と同じ誤り",
        arguments: ["1,000", "1.5", "-1", "+1", "abc", "7 2", "１，０００", "72ページ"])
    func rejectsNonDigits(text: String) {
        #expect(NumberInput.parse(text) == .invalid)
    }

    @Test("とても長い数字でも落ちず、範囲の外として扱う")
    func rejectsHugeNumbers() {
        #expect(NumberInput.parse(String(repeating: "9", count: 400)) == .invalid)
        #expect(NumberInput.parse("1000001") == .invalid)
        #expect(NumberInput.parse("1000000") == .number(1_000_000))
    }

    @Test("範囲の中の値だけを返す（総ページ数 1〜9999、今のページ 0〜300、分 1〜180）")
    func valueInRange() {
        #expect(NumberInput.value("0", in: ReadingMath.totalPagesRange) == nil)
        #expect(NumberInput.value("1", in: ReadingMath.totalPagesRange) == 1)
        #expect(NumberInput.value("9999", in: ReadingMath.totalPagesRange) == 9_999)
        #expect(NumberInput.value("10000", in: ReadingMath.totalPagesRange) == nil)
        #expect(NumberInput.value("301", in: 0...300) == nil)
        #expect(NumberInput.value("", in: 0...300) == nil)
        #expect(NumberInput.value("0", in: 1...180) == nil)
        #expect(NumberInput.value("181", in: 1...180) == nil)
        #expect(NumberInput.value("45", in: 1...180) == 45)
    }

    // MARK: 経過の見える文字（design 7 の経過の表）

    @Test(
        "経過の表の見える文字",
        arguments: [
            (0, "0:00"), (1, "0:01"), (61, "1:01"), (300, "5:00"), (750, "12:30"), (665, "11:05"), (3_599, "59:59"),
            (3_600, "1:00:00"), (3_723, "1:02:03"), (7_384, "2:03:04"), (108_000, "30:00:00"),
        ])
    func clockText(seconds: Int, expected: String) {
        #expect(ElapsedFormat.clock(seconds) == expected)
    }

    @Test("負の経過は 0:00（AC-41）")
    func negativeElapsed() {
        #expect(ElapsedFormat.clock(-30) == "0:00")
        #expect(ElapsedFormat.parts(-30) == ElapsedFormat.Parts(hours: 0, minutes: 0, seconds: 0))
    }

    @Test("読み上げのキーは60分未満で reading.elapsed.ms、60分以上で reading.elapsed.hms")
    func readingKeyBoundary() {
        #expect(ElapsedFormat.isUnderOneHour(3_599))
        #expect(!ElapsedFormat.isUnderOneHour(3_600))
        #expect(ElapsedFormat.parts(3_723) == ElapsedFormat.Parts(hours: 1, minutes: 2, seconds: 3))
        #expect(ElapsedFormat.parts(750) == ElapsedFormat.Parts(hours: 0, minutes: 12, seconds: 30))
    }
}
