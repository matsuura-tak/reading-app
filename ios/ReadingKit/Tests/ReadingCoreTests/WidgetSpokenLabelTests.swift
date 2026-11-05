import Foundation
import Testing
@testable import ReadingCore

/// W-1・W-2 の読み上げ（design/ 6 の505行目、決まり 53、AC-99）の場合をすべて確かめる。
@Suite("Widget spoken label (AC-99)")
struct WidgetSpokenLabelTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let name: String
        let title: String?
        let isTitlePending: Bool
        let unit: ProgressUnit
        let progress: String?
        let line: String?
        let hide: Bool
        let ja: String
        let en: String
        var testDescription: String { name }
    }

    static let cases: [Case] = [
        Case(name: "page", title: "羅生門", isTitlePending: false, unit: .page, progress: "p.61",
             line: "下人は、雨やみを待っていた。", hide: false,
             ja: "羅生門、61ページ。下人は、雨やみを待っていた。",
             en: "羅生門, page 61. 下人は、雨やみを待っていた。"),
        Case(name: "location", title: "羅生門", isTitlePending: false, unit: .location, progress: "位置1450",
             line: "下人は、雨やみを待っていた。", hide: false,
             ja: "羅生門、位置1450。下人は、雨やみを待っていた。",
             en: "羅生門, location 1450. 下人は、雨やみを待っていた。"),
        Case(name: "percent", title: "羅生門", isTitlePending: false, unit: .percent, progress: "52%",
             line: "下人は、雨やみを待っていた。", hide: false,
             ja: "羅生門、52パーセント。下人は、雨やみを待っていた。",
             en: "羅生門, 52 percent. 下人は、雨やみを待っていた。"),
        Case(name: "noPage", title: "羅生門", isTitlePending: false, unit: .page, progress: nil,
             line: "下人は、雨やみを待っていた。", hide: false,
             ja: "羅生門。下人は、雨やみを待っていた。",
             en: "羅生門. 下人は、雨やみを待っていた。"),
        Case(name: "noLine", title: "檸檬", isTitlePending: false, unit: .page, progress: "p.120",
             line: nil, hide: false,
             ja: "檸檬、120ページ",
             en: "檸檬, page 120"),
        Case(name: "noLineNoPage", title: "檸檬", isTitlePending: false, unit: .page, progress: nil,
             line: nil, hide: false,
             ja: "檸檬",
             en: "檸檬"),
        Case(name: "hidden", title: "羅生門", isTitlePending: false, unit: .page, progress: "p.61",
             line: "下人は、雨やみを待っていた。", hide: true,
             ja: "しおり、61ページ",
             en: "Bookmark, page 61"),
        Case(name: "titlePending", title: nil, isTitlePending: true, unit: .page, progress: "p.61",
             line: "下人は、雨やみを待っていた。", hide: false,
             ja: "今の本、61ページ。下人は、雨やみを待っていた。",
             en: "Reading Now, page 61. 下人は、雨やみを待っていた。"),
        Case(name: "verticalForms", title: "羅生門", isTitlePending: false, unit: .page, progress: "p.61",
             line: "下人は\u{FE11}雨やみを待っていた\u{FE12}", hide: false,
             ja: "羅生門、61ページ。下人は、雨やみを待っていた。",
             en: "羅生門, page 61. 下人は、雨やみを待っていた。")
    ]

    private func snapshot(_ c: Case) -> WidgetSnapshot {
        // 写しは progress{unit,value}（契約）。表の場所の表示から値を取る。隠す設定の場合も、読み上げが書名と一行を読まないことを確かめるため渡す。
        let value = c.progress.flatMap { Int($0.filter(\.isNumber)) }
        return WidgetSnapshot(
            appearanceID: .default,
            hideOnWidgets: c.hide,
            currentBook: WidgetSnapshotBook(
                title: c.title,
                isTitlePending: c.isTitlePending,
                line: c.line,
                progress: value.map { WidgetSnapshotProgress(unit: c.unit, value: $0) }
            )
        )
    }

    @Test("design/ 6 の書式で読む（ja と en）", arguments: cases)
    func spokenLabel(_ c: Case) {
        let ja = VerticalLineLayout.buildWidgetAccessibilityLabel(snapshot: snapshot(c), strings: .japanese)
        let en = VerticalLineLayout.buildWidgetAccessibilityLabel(snapshot: snapshot(c), strings: .english)
        #expect(ja == c.ja)
        #expect(en == c.en)
        #expect(!ja.contains("芥川龍之介"))
        #expect(!ja.contains("p."))
        for scalar in ja.unicodeScalars {
            #expect(!(0xFE10...0xFE4F).contains(scalar.value))
        }
    }

    @Test("今の本なしは widget.empty の文")
    func emptyLabel() {
        let empty = WidgetSnapshot(appearanceID: .default, hideOnWidgets: false, currentBook: nil)
        #expect(VerticalLineLayout.buildWidgetAccessibilityLabel(snapshot: empty, strings: .japanese) == "今の本を選ぶと、ここに続きの一行が出ます。")
        #expect(VerticalLineLayout.buildWidgetAccessibilityLabel(snapshot: empty, strings: .english) == "Choose a book in Yomuma to see your place here.")
    }

    @Test("単位が分からない表示の形から場所の読み方を決める（Live Activity）", arguments: [
        ("p.61", "61ページ"), ("位置1450", "位置1450"), ("Loc 1450", "位置1450"), ("52%", "52パーセント")
    ])
    func spokenProgressFromDisplay(_ pair: (String, String)) {
        #expect(WidgetSpokenStrings.japanese.spokenProgress(unit: nil, display: pair.0) == pair.1)
    }
}
