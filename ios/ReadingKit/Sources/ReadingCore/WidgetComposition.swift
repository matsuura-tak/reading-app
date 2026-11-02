import Foundation

// W-1・W-2 の一行の組み方（contracts/test-hooks.md「H22 の組み方」「横書きの一行」、ADR 0003 の 2026-11-02 の追記）。
// 拡張の View、アプリの中の見本、H22 の読み出し（SnapshotStore）が、同じ枠でこの関数を呼ぶ。
// SwiftUI と WidgetKit は import しない。

/// W-1（`accessoryRectangular`）と W-2（`systemSmall`）。
public enum WidgetSurfaceFamily: String, Sendable, Equatable, Codable, CaseIterable {
    case accessoryRectangular
    case systemSmall
}

/// 記号の値（pt）。契約の「記号の値」の表の写しで、ここの1か所だけに置く。
public struct WidgetCompositionConstants: Sendable, Equatable {
    /// 内側の余白（四方）。
    public let i: Double
    /// 左端の場所の帯の幅。
    public let B: Double
    /// 帯と列の場所の間。
    public let g: Double
    /// 列の場所の下の、場所の行（行の高さ 16 と space.4）。
    public let R: Double
    /// 字の大きさの始めの値。
    public let maxFontSize: Double
    /// 字の大きさの下限。
    public let minFontSize: Double

    /// 列の間は字の大きさの 0.25 倍。
    public static let columnGapRatio: Double = 0.25
    /// 場所の文字の行の高さ（`page.y`＝H−i−16）。
    public static let pageRowHeight: Double = 16

    public nonisolated static func of(_ family: WidgetSurfaceFamily) -> WidgetCompositionConstants {
        switch family {
        case .accessoryRectangular:
            return WidgetCompositionConstants(i: 0, B: 43, g: 4, R: 0, maxFontSize: 17, minFontSize: 13)
        case .systemSmall:
            return WidgetCompositionConstants(i: 16, B: 0, g: 0, R: 20, maxFontSize: 20, minFontSize: 13)
        }
    }
}

public enum WidgetLineOrientation: String, Sendable, Equatable, Codable {
    case vertical
    case horizontal
}

/// `composition.frame`。
public struct WidgetCompositionFrame: Sendable, Equatable, Codable {
    public var W: Double
    public var H: Double
    public var i: Double
    public var B: Double
    public var g: Double
    public var R: Double
}

/// `composition.slack`。
public struct WidgetCompositionSlack: Sendable, Equatable, Codable {
    public var horizontal: Double
    public var vertical: Double
}

/// `composition.cells[]`。座標は枠の左上を原点とする pt（升目の左上）。
public struct WidgetCompositionCell: Sendable, Equatable, Codable {
    public var source: String
    public var display: String
    public var rotation: Int
    public var dx: Double
    public var dy: Double
    public var column: Int
    public var row: Int
    public var x: Double
    public var y: Double
}

/// `composition.page`。場所の文字の左上の名目の位置。
public struct WidgetCompositionPage: Sendable, Equatable, Codable {
    public var text: String
    public var x: Double
    public var y: Double
}

/// 縦書きの升目の値（`orientation` が `vertical` のときだけ）。
public struct WidgetVerticalGrid: Sendable, Equatable {
    public var frame: WidgetCompositionFrame
    public var fontSize: Double
    public var L: Int
    public var referenceL: Int
    public var columnCount: Int
    public var feedCount: Int
    public var kinsokuRelaxed: Bool
    public var slack: WidgetCompositionSlack
    public var cells: [WidgetCompositionCell]
}

/// `renders[].composition`。横書きのときは升目の9項目をキーごと書かない。
public struct WidgetLineComposition: Sendable, Equatable, Encodable {
    public var orientation: WidgetLineOrientation
    public var displayedLine: String
    public var shortened: Bool
    public var page: WidgetCompositionPage?
    public var grid: WidgetVerticalGrid?

    enum CodingKeys: String, CodingKey {
        case orientation, displayedLine, shortened, page
        case frame, fontSize, L, referenceL, columnCount, feedCount, kinsokuRelaxed, slack, cells
    }

    public nonisolated func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(orientation, forKey: .orientation)
        try c.encode(displayedLine, forKey: .displayedLine)
        try c.encode(shortened, forKey: .shortened)
        try c.encodeIfPresent(page, forKey: .page)
        guard let grid else { return }
        try c.encode(grid.frame, forKey: .frame)
        try c.encode(grid.fontSize, forKey: .fontSize)
        try c.encode(grid.L, forKey: .L)
        try c.encode(grid.referenceL, forKey: .referenceL)
        try c.encode(grid.columnCount, forKey: .columnCount)
        try c.encode(grid.feedCount, forKey: .feedCount)
        try c.encode(grid.kinsokuRelaxed, forKey: .kinsokuRelaxed)
        try c.encode(grid.slack, forKey: .slack)
        try c.encode(grid.cells, forKey: .cells)
    }
}

public enum WidgetLineComposer {
    /// `referenceL` を求める一行（禁則の字のない25字）。
    public static let referenceLine: String = String(repeating: "あ", count: VerticalLineLayout.maxWidgetCharacters)

    /// 枠と縮める前の一行から、W-1・W-2 の一行の組みを決める（契約の手順1〜5）。
    /// - Parameters:
    ///   - family: W-1 は `.accessoryRectangular`、W-2 は `.systemSmall`。
    ///   - width: 枠の幅（pt）。
    ///   - height: 枠の高さ（pt）。
    ///   - rawLine: 縮める前の一行。
    ///   - pageText: 場所の短い表示（`p.61` など）。描かないときは nil。
    public nonisolated static func compose(
        family: WidgetSurfaceFamily,
        width: Double,
        height: Double,
        rawLine: String,
        pageText: String?
    ) -> WidgetLineComposition {
        let k = WidgetCompositionConstants.of(family)
        // 手順1：縮める（AC-29）。
        let shortened = VerticalLineLayout.shortenForWidget(rawLine)
        let page: WidgetCompositionPage? = pageText.flatMap { text in
            text.isEmpty ? nil : WidgetCompositionPage(
                text: text,
                x: k.i,
                y: height - k.i - WidgetCompositionConstants.pageRowHeight
            )
        }
        // 横書き（AC-30）：手順1だけ。
        guard VerticalLineLayout.containsJapaneseScript(shortened.text) else {
            return WidgetLineComposition(
                orientation: .horizontal,
                displayedLine: shortened.text,
                shortened: shortened.shortened,
                page: page,
                grid: nil
            )
        }
        let grid = layoutGrid(family: family, width: width, height: height, text: shortened.text)
        return WidgetLineComposition(
            orientation: .vertical,
            displayedLine: shortened.text,
            shortened: shortened.shortened,
            page: page,
            grid: grid
        )
    }

    /// 手順2〜5（縮めたあとの縦書きの字の並びを、枠に入る字の大きさと列に分ける）。
    public nonisolated static func layoutGrid(
        family: WidgetSurfaceFamily,
        width: Double,
        height: Double,
        text: String
    ) -> WidgetVerticalGrid {
        let k = WidgetCompositionConstants.of(family)
        let frame = WidgetCompositionFrame(W: width, H: height, i: k.i, B: k.B, g: k.g, R: k.R)
        let areaWidth = width - 2 * k.i - k.B - k.g
        let areaHeight = height - 2 * k.i - k.R
        let chars = Array(text)
        let fit = fitColumns(chars: chars, areaWidth: areaWidth, areaHeight: areaHeight, constants: k)
        let referenceFit = fitColumns(
            chars: Array(referenceLine),
            areaWidth: areaWidth,
            areaHeight: areaHeight,
            constants: k
        )
        let s = fit.fontSize
        let columnCount = fit.columns.count
        var cells: [WidgetCompositionCell] = []
        cells.reserveCapacity(chars.count)
        for (columnIndex, column) in fit.columns.enumerated() {
            let x = (width - k.i) - Double(columnIndex) * (1 + WidgetCompositionConstants.columnGapRatio) * s - s
            for (rowIndex, ch) in column.enumerated() {
                let t = VerticalLineLayout.transformCharacter(ch)
                cells.append(WidgetCompositionCell(
                    source: String(ch),
                    display: t.display,
                    rotation: t.rotation,
                    dx: t.dx,
                    dy: t.dy,
                    column: columnIndex + 1,
                    row: rowIndex + 1,
                    x: x,
                    y: k.i + Double(rowIndex) * s
                ))
            }
        }
        let used = usedWidth(columnCount: columnCount, fontSize: s)
        return WidgetVerticalGrid(
            frame: frame,
            fontSize: s,
            L: fit.rowsPerColumn,
            referenceL: referenceFit.rowsPerColumn,
            columnCount: columnCount,
            feedCount: fit.feedCount,
            kinsokuRelaxed: fit.kinsokuRelaxed,
            slack: WidgetCompositionSlack(
                horizontal: areaWidth - used,
                vertical: areaHeight - Double(fit.rowsPerColumn) * s
            ),
            cells: cells
        )
    }

    struct Fit: Equatable {
        var fontSize: Double
        var rowsPerColumn: Int
        var columns: [[Character]]
        var feedCount: Int
        var kinsokuRelaxed: Bool
    }

    nonisolated static func usedWidth(columnCount: Int, fontSize s: Double) -> Double {
        Double(columnCount) * s + Double(max(columnCount - 1, 0)) * WidgetCompositionConstants.columnGapRatio * s
    }

    nonisolated static func rows(areaHeight: Double, fontSize s: Double) -> Int {
        max(Int((areaHeight / s).rounded(.down)), 1)
    }

    /// 手順2〜5。入るかは送ったあとの列の数で見る。列の数に上限を付けない（字を落とさない）。
    nonisolated static func fitColumns(
        chars: [Character],
        areaWidth: Double,
        areaHeight: Double,
        constants k: WidgetCompositionConstants
    ) -> Fit {
        var s = k.maxFontSize
        while s >= k.minFontSize {
            let L = rows(areaHeight: areaHeight, fontSize: s)
            let split = splitColumns(chars: chars, rowsPerColumn: L, feed: true)
            if usedWidth(columnCount: split.columns.count, fontSize: s) <= areaWidth {
                return Fit(fontSize: s, rowsPerColumn: L, columns: split.columns, feedCount: split.feedCount, kinsokuRelaxed: false)
            }
            s -= 1
        }
        // 手順5の終わり：下限の字の大きさで、送らずに L 字ずつ分ける。
        let L = rows(areaHeight: areaHeight, fontSize: k.minFontSize)
        let split = splitColumns(chars: chars, rowsPerColumn: L, feed: false)
        return Fit(fontSize: k.minFontSize, rowsPerColumn: L, columns: split.columns, feedCount: 0, kinsokuRelaxed: true)
    }

    /// 手順3：先頭から L 字ずつ列に分け、次の列の先頭が行頭禁則の字なら前の列の終わりの字を送る。
    /// 前の列が1字になっても満たせないときは、それ以上送らない。送った字は1字ごとに1と数える。
    nonisolated static func splitColumns(
        chars: [Character],
        rowsPerColumn L: Int,
        feed: Bool
    ) -> (columns: [[Character]], feedCount: Int) {
        var columns: [[Character]] = []
        var index = 0
        var feedCount = 0
        while index < chars.count {
            let take = min(L, chars.count - index)
            var column = Array(chars[index..<(index + take)])
            index += take
            if feed && index < chars.count {
                while column.count > 1 && VerticalLineLayout.prohibitedLineStartCharacters.contains(chars[index]) {
                    index -= 1
                    column.removeLast()
                    feedCount += 1
                }
            }
            columns.append(column)
        }
        return (columns, feedCount)
    }
}
