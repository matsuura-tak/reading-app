import Foundation
import Testing
@testable import ReadingCore

/// contracts/test-hooks.md「H22 の組み方」「横書きの一行」の検算と同じ値になること。
@Suite("WidgetLineComposer（H22 の組み方）")
struct WidgetCompositionTests {
    struct Row: Sendable, CustomTestStringConvertible {
        let family: WidgetSurfaceFamily
        let width: Double
        let height: Double
        let line: String
        let s: Double
        let L: Int
        let C: Int
        let feed: Int
        let referenceL: Int
        let slackHorizontal: Double

        var testDescription: String { "\(family.rawValue) \(Int(width))x\(Int(height)) \(line.prefix(6))" }
    }

    static let ac27 = "下人は、雨やみを待っていた。"
    static let kana25 = String(repeating: "あ", count: 25)
    static let hokosai = "歩行祭は、いつも同じ道を歩く。"

    /// 契約の表の9行。
    static let table: [Row] = [
        Row(family: .accessoryRectangular, width: 172, height: 76, line: ac27, s: 17, L: 4, C: 4, feed: 0, referenceL: 5, slackHorizontal: 44.25),
        Row(family: .accessoryRectangular, width: 153, height: 68, line: ac27, s: 17, L: 4, C: 4, feed: 0, referenceL: 5, slackHorizontal: 25.25),
        Row(family: .accessoryRectangular, width: 172, height: 76, line: kana25, s: 15, L: 5, C: 5, feed: 0, referenceL: 5, slackHorizontal: 35.0),
        Row(family: .accessoryRectangular, width: 153, height: 68, line: kana25, s: 13, L: 5, C: 5, feed: 0, referenceL: 5, slackHorizontal: 28.0),
        Row(family: .accessoryRectangular, width: 172, height: 76, line: hokosai, s: 17, L: 4, C: 4, feed: 1, referenceL: 5, slackHorizontal: 44.25),
        Row(family: .systemSmall, width: 170, height: 170, line: ac27, s: 20, L: 5, C: 3, feed: 0, referenceL: 5, slackHorizontal: 68.0),
        Row(family: .systemSmall, width: 148, height: 148, line: ac27, s: 20, L: 4, C: 4, feed: 0, referenceL: 5, slackHorizontal: 21.0),
        Row(family: .systemSmall, width: 170, height: 170, line: kana25, s: 20, L: 5, C: 5, feed: 0, referenceL: 5, slackHorizontal: 18.0),
        Row(family: .systemSmall, width: 148, height: 148, line: kana25, s: 19, L: 5, C: 5, feed: 0, referenceL: 5, slackHorizontal: 2.0)
    ]

    @Test("契約の表の9行で s、L、C、送り、referenceL、slack.horizontal が合う", arguments: table)
    func contractTable(_ row: Row) throws {
        let comp = WidgetLineComposer.compose(family: row.family, width: row.width, height: row.height, rawLine: row.line, pageText: "p.61")
        #expect(comp.orientation == .vertical)
        let grid = try #require(comp.grid)
        #expect(grid.fontSize == row.s)
        #expect(grid.L == row.L)
        #expect(grid.columnCount == row.C)
        #expect(grid.feedCount == row.feed)
        #expect(grid.referenceL == row.referenceL)
        #expect(abs(grid.slack.horizontal - row.slackHorizontal) < 0.0001)
        #expect(grid.kinsokuRelaxed == false)
        // 欠け0字：cells の字を並べると displayedLine と同じ
        #expect(grid.cells.map(\.source).joined() == comp.displayedLine)
        #expect(grid.cells.count == comp.displayedLine.count)
    }

    @Test("W-1 172x76 の AC-27 の14字は、スキーマの1つ目の例と同じ升目と位置")
    func schemaExampleCells() throws {
        let comp = WidgetLineComposer.compose(family: .accessoryRectangular, width: 172, height: 76, rawLine: Self.ac27, pageText: "p.61")
        let grid = try #require(comp.grid)
        #expect(grid.frame == WidgetCompositionFrame(W: 172, H: 76, i: 0, B: 43, g: 4, R: 0))
        #expect(grid.slack.vertical == 8)
        let first = try #require(grid.cells.first)
        #expect(first.source == "下" && first.column == 1 && first.row == 1 && first.x == 155 && first.y == 0)
        let comma = try #require(grid.cells.first { $0.source == "、" })
        #expect(comma.display == "\u{FE11}" && comma.column == 1 && comma.row == 4 && comma.x == 155 && comma.y == 51)
        let ame = try #require(grid.cells.first { $0.source == "雨" })
        #expect(ame.column == 2 && ame.row == 1 && ame.x == 133.75 && ame.y == 0)
        #expect(comp.page == WidgetCompositionPage(text: "p.61", x: 0, y: 60))
    }

    @Test("「あ、」×12＋「あ」は字が落ちない（W-1・W-2 の4つの枠）", arguments: [
        (WidgetSurfaceFamily.accessoryRectangular, 172.0, 76.0),
        (WidgetSurfaceFamily.accessoryRectangular, 153.0, 68.0),
        (WidgetSurfaceFamily.systemSmall, 170.0, 170.0),
        (WidgetSurfaceFamily.systemSmall, 148.0, 148.0)
    ])
    func manyCommasKeepAllCharacters(_ family: WidgetSurfaceFamily, _ width: Double, _ height: Double) throws {
        let line = String(repeating: "あ、", count: 12) + "あ"
        #expect(line.count == 25)
        let comp = WidgetLineComposer.compose(family: family, width: width, height: height, rawLine: line, pageText: nil)
        let grid = try #require(comp.grid)
        #expect(grid.cells.count == line.count)
        #expect(grid.cells.map(\.source).joined() == line)
        // 入るかは送ったあとの列の数で見ている
        let used = Double(grid.columnCount) * grid.fontSize + Double(grid.columnCount - 1) * 0.25 * grid.fontSize
        if !grid.kinsokuRelaxed {
            #expect(used <= width - 2 * grid.frame.i - grid.frame.B - grid.frame.g)
        }
    }

    @Test("「あ」＋「ー」×24 は W-1 の両方の枠で relaxed 真、13pt、L 5、C 5、cells 25個", arguments: [
        (172.0, 76.0),
        (153.0, 68.0)
    ])
    func longVowelRunRelaxes(_ width: Double, _ height: Double) throws {
        let line = "あ" + String(repeating: "ー", count: 24)
        let comp = WidgetLineComposer.compose(family: .accessoryRectangular, width: width, height: height, rawLine: line, pageText: nil)
        let grid = try #require(comp.grid)
        #expect(grid.kinsokuRelaxed == true)
        #expect(grid.fontSize == 13)
        #expect(grid.L == 5)
        #expect(grid.columnCount == 5)
        #expect(grid.feedCount == 0)
        #expect(grid.cells.count == 25)
    }

    @Test("「そして」＋「…」×6 は 172x76 で 17pt、C 5、feed 11、relaxed 偽")
    func ellipsisFeedCount() throws {
        let line = "そして" + String(repeating: "…", count: 6)
        let comp = WidgetLineComposer.compose(family: .accessoryRectangular, width: 172, height: 76, rawLine: line, pageText: nil)
        let grid = try #require(comp.grid)
        #expect(grid.fontSize == 17)
        #expect(grid.columnCount == 5)
        #expect(grid.feedCount == 11)
        #expect(grid.kinsokuRelaxed == false)
        #expect(grid.cells.count == line.count)
    }

    @Test("「あいうーーーー」のくり返し25字は 153x68 で relaxed 真、172x76 は 14pt・C 7 で入る")
    func repeatedPatternEdge() throws {
        let unit = "あいうーーーー"
        let line = String(String(repeating: unit, count: 4).prefix(25))
        let small = try #require(WidgetLineComposer.compose(family: .accessoryRectangular, width: 153, height: 68, rawLine: line, pageText: nil).grid)
        #expect(small.kinsokuRelaxed == true)
        #expect(small.cells.count == 25)
        let large = try #require(WidgetLineComposer.compose(family: .accessoryRectangular, width: 172, height: 76, rawLine: line, pageText: nil).grid)
        #expect(large.kinsokuRelaxed == false)
        #expect(large.fontSize == 14)
        #expect(large.columnCount == 7)
        #expect(large.cells.count == 25)
    }

    @Test("横書き（AC-30）の composition のキーは orientation、displayedLine、shortened、page だけ")
    func horizontalKeys() throws {
        let comp = WidgetLineComposer.compose(family: .accessoryRectangular, width: 172, height: 76, rawLine: "It was raining.", pageText: "p.61")
        #expect(comp.orientation == .horizontal)
        #expect(comp.grid == nil)
        let data = try JSONEncoder().encode(comp)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["orientation", "displayedLine", "shortened", "page"])
        #expect(object["displayedLine"] as? String == "It was raining.")
        let page = try #require(object["page"] as? [String: Any])
        #expect(page["text"] as? String == "p.61")
        #expect(page["y"] as? Double == 60)

        let noPage = WidgetLineComposer.compose(family: .systemSmall, width: 170, height: 170, rawLine: "It was raining.", pageText: nil)
        let noPageObject = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(noPage)) as? [String: Any])
        #expect(Set(noPageObject.keys) == ["orientation", "displayedLine", "shortened"])
    }

    @Test("縦書きの composition は升目の9項目をすべて書く")
    func verticalKeys() throws {
        let comp = WidgetLineComposer.compose(family: .systemSmall, width: 170, height: 170, rawLine: Self.ac27, pageText: "p.61")
        let object = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(comp)) as? [String: Any])
        #expect(Set(object.keys) == [
            "orientation", "displayedLine", "shortened", "page",
            "frame", "fontSize", "L", "referenceL", "columnCount", "feedCount", "kinsokuRelaxed", "slack", "cells"
        ])
        let cells = try #require(object["cells"] as? [[String: Any]])
        #expect(Set(cells[0].keys) == ["source", "display", "rotation", "dx", "dy", "column", "row", "x", "y"])
    }

    @Test("26字以上は縮めてから組む（AC-29）")
    func shortensBeforeComposing() throws {
        let raw = String(repeating: "あ", count: 17) + "、" + String(repeating: "い", count: 13)
        let comp = WidgetLineComposer.compose(family: .accessoryRectangular, width: 153, height: 68, rawLine: raw, pageText: nil)
        #expect(comp.shortened == true)
        #expect(comp.displayedLine == String(repeating: "あ", count: 17) + "、")
        let grid = try #require(comp.grid)
        #expect(grid.cells.count == 18)
    }
}

@Suite("Widget の状態と写しの読み方")
struct WidgetRenderStateTests {
    static func snapshot(hide: Bool = false, line: String? = nil, page: String? = nil, book: Bool = true) -> WidgetSnapshot {
        WidgetSnapshot(
            updatedAt: "2026-11-02T12:00:00Z",
            hideOnWidgets: hide,
            currentBook: book ? WidgetSnapshotBook(
                id: UUID(),
                title: hide ? "しおり" : "羅生門",
                author: nil,
                isTitlePending: false,
                progressUnit: .page,
                progressDisplay: page,
                latestLine: line,
                latestLineId: line == nil ? nil : UUID()
            ) : nil
        )
    }

    @Test("状態の表（上から順に当てはまった最初の行）")
    func stateTable() {
        #expect(WidgetRenderStateResolver.state(for: .unavailable(.missing)) == .unavailable)
        #expect(WidgetRenderStateResolver.state(for: Self.snapshot(book: false)) == .empty)
        #expect(WidgetRenderStateResolver.state(for: Self.snapshot(hide: true, page: "p.61")) == .hidden)
        #expect(WidgetRenderStateResolver.state(for: Self.snapshot(line: "下人は、", page: "p.61")) == .normal)
        #expect(WidgetRenderStateResolver.state(for: Self.snapshot(page: "p.61")) == .noLine)
        #expect(WidgetRenderStateResolver.state(for: Self.snapshot()) == .noLineNoPage)
    }

    @Test("読めない写しの理由")
    func unreadableReasons() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        #expect(WidgetSnapshotReader.read(fileURL: dir.appendingPathComponent("none.json")) == .unavailable(.missing))
        #expect(WidgetSnapshotReader.read(data: Data("{".utf8)) == .unavailable(.malformed))
        #expect(WidgetSnapshotReader.read(data: Data(#"{"version":2,"updatedAt":"x","appearanceID":"default","hideOnWidgets":false}"#.utf8)) == .unavailable(.version))
        let hiddenWithLine = #"{"version":1,"updatedAt":"x","appearanceID":"default","hideOnWidgets":true,"currentBook":{"id":"00000000-0000-0000-0000-000000000001","title":"しおり","isTitlePending":false,"progressUnit":"page","latestLine":"一行"}}"#
        #expect(WidgetSnapshotReader.read(data: Data(hiddenWithLine.utf8)) == .unavailable(.hiddenConflict))
        let tooLong = #"{"version":1,"updatedAt":"x","appearanceID":"default","hideOnWidgets":false,"currentBook":{"id":"00000000-0000-0000-0000-000000000001","title":"羅生門","isTitlePending":false,"progressUnit":"page","progressDisplay":"012345678901234567890"}}"#
        #expect(WidgetSnapshotReader.read(data: Data(tooLong.utf8)) == .unavailable(.range))
        let encoded = try JSONEncoder().encode(Self.snapshot(line: "一行", page: "p.1"))
        #expect(WidgetSnapshotReader.read(data: encoded).snapshot != nil)
    }
}
