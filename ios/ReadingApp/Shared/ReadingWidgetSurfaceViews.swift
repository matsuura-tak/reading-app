import SwiftUI
import WidgetKit
import ReadingCore

// W-1〜W-5 の View。アプリ（H22 の撮影用の見本）と拡張（ReadingWidgetExtension）の両方のターゲットに入る。
// View は @Environment(\.widgetFamily) や ActivityViewContext を読まず、ファミリー、写し、大きさ、
// Live Activity の属性と状態を引数で受ける（contracts/test-hooks.md H22「撮影用の見本」）。

// MARK: - 共有の値

public enum ReadingWidgetMetrics {
    /// W-1 の内側の余白（design/001-reading-session/screens.md W-1「内側の余白は 0（contentMarginsDisabled）」）。
    public static let lockScreenContentMargins = EdgeInsets()
    /// W-2 の内側の余白（screens.md W-2「内側 16pt（contentMarginsDisabled で自分で付ける）」）。
    public static let homeSmallContentMargins = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    /// W-1 の左端の場所の帯の幅（screens.md W-1、ADR 0003 の実測）。
    public static let lockScreenPlaceBandWidth: CGFloat = 43
    /// 帯と列の間（space.4）。
    public static let bandGap: CGFloat = 4
    /// 列の間は字の大きさの 0.25 倍（type.book.line.columnGap）。
    public static let columnGapRatio: CGFloat = 0.25
    /// W-2 の場所の行の高さ（13pt 固定、行の高さ 16pt）と、列の場所との間（space.4）。
    public static let homeSmallPlaceRowHeight: CGFloat = 16
}

/// 拡張と見本が同じ文を出すための、文言キーを通した文。
public enum ReadingWidgetStrings {
    public static var hidden: String { String(localized: "widget.hidden") }
    public static var empty: String { String(localized: "widget.empty") }
    public static var currentBookAsTitle: String { String(localized: "widget.currentBookAsTitle") }
    public static var controlStartReading: String { String(localized: "control.startReading") }
    public static var endButtonTitle: String { String(localized: "reading.end") }
    public static var endButtonLabel: String { String(localized: "liveActivity.end.label") }

    /// W-1〜W-3 の読み上げの文（design/ 6、design/ 7 の `widget.spoken*`、`page.spoken` など。AC-99）。
    public static var spoken: WidgetSpokenStrings {
        WidgetSpokenStrings(
            empty: empty,
            unavailable: String(localized: "widget.unavailable"),
            hidden: hidden,
            currentBookAsTitle: currentBookAsTitle,
            pageFormat: String(localized: "page.spoken"),
            locationFormat: String(localized: "location.spoken"),
            percentFormat: String(localized: "percent.spoken"),
            spokenFormat: String(localized: "widget.spoken"),
            spokenNoPageFormat: String(localized: "widget.spoken.noPage"),
            spokenNoLineFormat: String(localized: "widget.spoken.noLine")
        )
    }

    /// W-1・W-2 の全体の読み上げ（書名、場所、一行。著者なし）。拡張、H22、アプリの中の見本（S-5、S-10a）が同じ文を使う。
    public static func widgetLabel(for snapshot: WidgetSnapshot) -> String {
        VerticalLineLayout.buildWidgetAccessibilityLabel(snapshot: snapshot, strings: spoken)
    }

    /// W-3 の読み上げ（design/ 6 の W-3）。待つ状態「書名、61ページ。一行」、読書中「書名、22:00 から読書中」、
    /// 終えた直後「書名、10分、61ページ」。隠す設定では書名の所が「しおり」で一行を読まない。
    public static func liveActivityLabel(
        attributes: ReadingActivityAttributes,
        state: ReadingActivityAttributes.ContentState
    ) -> String {
        let strings = spoken
        let title = state.hideOnWidgets ? hidden : state.title
        let place = strings.spokenProgress(unit: nil, display: state.progressText)
        switch state.mode {
        case "reading":
            guard let startedAt = attributes.startedAt else { return title }
            return strings.spokenLabel(title: title, place: readingSince(startedAt), line: nil)
        case "ended":
            // summaryText は「10分 · p.61」（ReadingLiveActivityStateFactory.ended）。先頭の分数だけを取り、場所は読み上げの形にする。
            let minutesText = state.summaryText?.components(separatedBy: " · ").first
            guard let minutes = minutesText, !minutes.isEmpty, minutes != state.progressText else {
                return strings.spokenLabel(title: title, place: place, line: nil)
            }
            let titleAndMinutes = strings.spokenLabel(title: title, place: minutes, line: nil)
            return strings.spokenLabel(title: titleAndMinutes, place: place, line: nil)
        default:
            var line: String?
            if !state.hideOnWidgets, let raw = state.line {
                let stripped = VerticalLineLayout.stripVerticalPresentationForms(raw)
                line = stripped.isEmpty ? nil : stripped
            }
            return strings.spokenLabel(title: title, place: place, line: line)
        }
    }

    /// 書名の所に出す文（隠す設定、名無しの今の本を含む。design/ 5 の W-1〜W-3）。
    public static func displayTitle(for book: WidgetSnapshotBook, hideOnWidgets: Bool) -> String {
        if hideOnWidgets { return hidden }
        if book.isTitlePending { return currentBookAsTitle }
        if let title = book.title, !title.isEmpty { return title }
        return hidden
    }

    public static func readingSince(_ startedAt: Date) -> String {
        let time = startedAt.formatted(date: .omitted, time: .shortened)
        return String(format: String(localized: "liveActivity.readingSince"), time)
    }
}

/// 縦書きの一行を、枠の大きさに合わせて組む（ADR 0003 の式。1列の字数＝⌊内側の高さ÷字の大きさ⌋、
/// 列の数×字の大きさ＋(列の数−1)×列の間 ≤ 列の場所の幅）。字は1pt ずつ下げ、下限で止める。
public struct ReadingVerticalFit: Equatable, Sendable {
    public let fontSize: CGFloat
    public let rowsPerColumn: Int
    public let maxColumns: Int

    public static func fit(
        characterCount: Int,
        areaWidth: CGFloat,
        areaHeight: CGFloat,
        maxFontSize: CGFloat,
        minFontSize: CGFloat
    ) -> ReadingVerticalFit {
        let count = max(characterCount, 1)
        var size = maxFontSize
        while size >= minFontSize {
            let rows = max(Int((areaHeight / size).rounded(.down)), 1)
            let columns = Int((Double(count) / Double(rows)).rounded(.up))
            let needed = CGFloat(columns) * size + CGFloat(max(columns - 1, 0)) * size * ReadingWidgetMetrics.columnGapRatio
            if needed <= areaWidth {
                let capacity = max(Int(((areaWidth + size * ReadingWidgetMetrics.columnGapRatio) / (size * (1 + ReadingWidgetMetrics.columnGapRatio))).rounded(.down)), columns)
                return ReadingVerticalFit(fontSize: size, rowsPerColumn: rows, maxColumns: capacity)
            }
            size -= 1
        }
        let rows = max(Int((areaHeight / minFontSize).rounded(.down)), 1)
        let columns = Int((Double(count) / Double(rows)).rounded(.up))
        return ReadingVerticalFit(fontSize: minFontSize, rowsPerColumn: rows, maxColumns: max(columns, 1))
    }
}

/// 縦書きの格子。字は字の大きさの正方形の枠に置き、列は右から左へ、上にそろえる。
struct ReadingVerticalGlyphGrid: View {
    let composition: H22WidgetComposition
    let fontSize: CGFloat

    var body: some View {
        let columns = max(composition.columnCount, 1)
        let rows = max(composition.rowsPerColumn, 1)
        let lookup = Dictionary(composition.cells.map { ("\($0.column)-\($0.row)", $0) }, uniquingKeysWith: { first, _ in first })
        HStack(alignment: .top, spacing: fontSize * ReadingWidgetMetrics.columnGapRatio) {
            ForEach((1...columns).reversed(), id: \.self) { column in
                VStack(spacing: 0) {
                    ForEach(1...rows, id: \.self) { row in
                        if let cell = lookup["\(column)-\(row)"] {
                            Text(verbatim: cell.display)
                                .font(ThemeTypography.widgetLineFixed(size: fontSize))
                                .rotationEffect(.degrees(Double(cell.rotation)))
                                .offset(x: cell.dx * fontSize, y: cell.dy * fontSize)
                                .frame(width: fontSize, height: fontSize)
                        } else {
                            Color.clear.frame(width: fontSize, height: fontSize)
                        }
                    }
                }
            }
        }
        .fixedSize()
        .accessibilityHidden(true)
    }
}

private func hasSavedLine(_ snapshot: WidgetSnapshot) -> Bool {
    guard !snapshot.hideOnWidgets, let line = snapshot.currentBook?.latestLine else { return false }
    return !line.isEmpty
}

private func composeFitted(
    snapshot: WidgetSnapshot,
    areaWidth: CGFloat,
    areaHeight: CGFloat,
    maxFontSize: CGFloat,
    minFontSize: CGFloat
) -> (H22WidgetComposition, CGFloat) {
    let base = VerticalLineLayout.composeWidget(snapshot: snapshot)
    guard base.orientation == .vertical else { return (base, maxFontSize) }
    let fit = ReadingVerticalFit.fit(
        characterCount: base.cells.count,
        areaWidth: areaWidth,
        areaHeight: areaHeight,
        maxFontSize: maxFontSize,
        minFontSize: minFontSize
    )
    let fitted = VerticalLineLayout.composeWidget(
        snapshot: snapshot,
        maxColumns: fit.maxColumns,
        rowsPerColumn: fit.rowsPerColumn
    )
    return (fitted, fit.fontSize)
}

// MARK: - W-1 ロック画面のウィジェット

public struct ReadingLockScreenWidgetView: View {
    let family: WidgetFamily
    let snapshot: WidgetSnapshot
    let size: CGSize
    let contentMargins: EdgeInsets

    public init(family: WidgetFamily, snapshot: WidgetSnapshot, size: CGSize, contentMargins: EdgeInsets) {
        self.family = family
        self.snapshot = snapshot
        self.size = size
        self.contentMargins = contentMargins
    }

    public var body: some View {
        let label = ReadingWidgetStrings.widgetLabel(for: snapshot)
        content
            .padding(contentMargins)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: label))
            .accessibilityIdentifier("widget.rectangular")
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            if let book = snapshot.currentBook {
                let title = ReadingWidgetStrings.displayTitle(for: book, hideOnWidgets: snapshot.hideOnWidgets)
                if let progress = book.progressDisplay, !progress.isEmpty {
                    Label("\(title) \(progress)", systemImage: "book")
                } else {
                    Label(title, systemImage: "book")
                }
            } else {
                Text(ReadingWidgetStrings.empty)
            }
        case .accessoryCircular:
            VStack(spacing: 2) {
                Image(systemName: "bookmark.fill")
                    .font(.caption)
                Text(snapshot.currentBook?.progressDisplay ?? ReadingWidgetStrings.hidden)
                    .font(.caption2.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            rectangularContent
        }
    }

    @ViewBuilder
    private var rectangularContent: some View {
        let innerWidth = max(size.width - contentMargins.leading - contentMargins.trailing, 1)
        let innerHeight = max(size.height - contentMargins.top - contentMargins.bottom, 1)
        if let book = snapshot.currentBook {
            let progress = book.progressDisplay ?? ""
            if hasSavedLine(snapshot) {
                let areaWidth = max(innerWidth - ReadingWidgetMetrics.lockScreenPlaceBandWidth - ReadingWidgetMetrics.bandGap, 1)
                let (composition, fontSize) = composeFitted(
                    snapshot: snapshot,
                    areaWidth: areaWidth,
                    areaHeight: innerHeight,
                    maxFontSize: 17,
                    minFontSize: 13
                )
                HStack(alignment: .top, spacing: ReadingWidgetMetrics.bandGap) {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer(minLength: 0)
                        if !progress.isEmpty {
                            Text(verbatim: progress)
                                .font(.caption2.weight(.semibold).monospacedDigit())
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                    }
                    .frame(width: ReadingWidgetMetrics.lockScreenPlaceBandWidth, alignment: .leading)
                    .frame(maxHeight: .infinity)
                    Spacer(minLength: 0)
                    if composition.orientation == .vertical {
                        ReadingVerticalGlyphGrid(composition: composition, fontSize: fontSize)
                    } else {
                        Text(verbatim: composition.displayedLine ?? "")
                            .font(.headline)
                            .lineLimit(3)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ReadingWidgetStrings.displayTitle(for: book, hideOnWidgets: snapshot.hideOnWidgets))
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                    if !progress.isEmpty {
                        Text(verbatim: progress)
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .lineLimit(1)
                    }
                }
            }
        } else {
            Text(ReadingWidgetStrings.empty)
                .font(.caption)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - W-2 小のウィジェット

public struct ReadingHomeSmallWidgetView: View {
    let snapshot: WidgetSnapshot
    let size: CGSize
    let contentMargins: EdgeInsets

    public init(snapshot: WidgetSnapshot, size: CGSize, contentMargins: EdgeInsets) {
        self.snapshot = snapshot
        self.size = size
        self.contentMargins = contentMargins
    }

    private var palette: ThemePalette {
        ThemePalette(appearanceID: snapshot.appearanceID)
    }

    public var body: some View {
        let label = ReadingWidgetStrings.widgetLabel(for: snapshot)
        content
            .foregroundStyle(palette.textPrimary)
            .padding(contentMargins)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: label))
            .accessibilityIdentifier("widget.small")
    }

    @ViewBuilder
    private var content: some View {
        let innerWidth = max(size.width - contentMargins.leading - contentMargins.trailing, 1)
        let innerHeight = max(size.height - contentMargins.top - contentMargins.bottom, 1)
        if let book = snapshot.currentBook {
            let progress = book.progressDisplay ?? ""
            VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                if hasSavedLine(snapshot) {
                    let areaHeight = max(innerHeight - ReadingWidgetMetrics.homeSmallPlaceRowHeight - ThemeSpace.s4, 1)
                    let (composition, fontSize) = composeFitted(
                        snapshot: snapshot,
                        areaWidth: innerWidth,
                        areaHeight: areaHeight,
                        maxFontSize: 20,
                        minFontSize: 13
                    )
                    if composition.orientation == .vertical {
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            ReadingVerticalGlyphGrid(composition: composition, fontSize: fontSize)
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                    } else {
                        Text(verbatim: composition.displayedLine ?? "")
                            .font(.subheadline)
                            .lineLimit(4)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                } else {
                    Text(ReadingWidgetStrings.displayTitle(for: book, hideOnWidgets: snapshot.hideOnWidgets))
                        .font(.headline)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                if !progress.isEmpty {
                    Text(verbatim: progress)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(palette.accent)
                        .lineLimit(1)
                        .frame(height: ReadingWidgetMetrics.homeSmallPlaceRowHeight, alignment: .leading)
                }
            }
        } else {
            Text(ReadingWidgetStrings.empty)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .lineLimit(4)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - W-3 Live Activity（ロック画面のバナー）

public enum ReadingLiveActivityStateFactory {
    /// 予約（待つ状態）の ContentState を写しの今の本から作る。今の本がなければ nil（予約を作らない）。
    public static func waiting(from snapshot: WidgetSnapshot) -> ReadingActivityAttributes.ContentState? {
        guard let book = snapshot.currentBook else { return nil }
        return ReadingActivityAttributes.ContentState(
            mode: "waiting",
            title: ReadingWidgetStrings.displayTitle(for: book, hideOnWidgets: snapshot.hideOnWidgets),
            line: snapshot.hideOnWidgets ? nil : book.latestLine,
            progressText: book.progressDisplay,
            summaryText: nil,
            hideOnWidgets: snapshot.hideOnWidgets
        )
    }

    public static func reading(from snapshot: WidgetSnapshot) -> ReadingActivityAttributes.ContentState? {
        guard let book = snapshot.currentBook else { return nil }
        return ReadingActivityAttributes.ContentState(
            mode: "reading",
            title: ReadingWidgetStrings.displayTitle(for: book, hideOnWidgets: snapshot.hideOnWidgets),
            line: nil,
            progressText: nil,
            summaryText: nil,
            hideOnWidgets: snapshot.hideOnWidgets
        )
    }

    public static func ended(from snapshot: WidgetSnapshot, minutes: Int, progressText: String?) -> ReadingActivityAttributes.ContentState? {
        guard let book = snapshot.currentBook else { return nil }
        let duration = Duration.seconds(minutes * 60).formatted(.units(allowed: [.minutes], width: .abbreviated))
        let summary = [duration, progressText].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
        return ReadingActivityAttributes.ContentState(
            mode: "ended",
            title: ReadingWidgetStrings.displayTitle(for: book, hideOnWidgets: snapshot.hideOnWidgets),
            line: nil,
            progressText: progressText,
            summaryText: summary,
            hideOnWidgets: snapshot.hideOnWidgets
        )
    }
}

public struct ReadingLiveActivityLockScreenView<EndButton: View>: View {
    let attributes: ReadingActivityAttributes
    let state: ReadingActivityAttributes.ContentState
    let endButton: (Text) -> EndButton

    /// - Parameter endButton: 「終える」のラベルを受けてボタンを返す。拡張は `Button(intent:)`、見本は `Button(action: {})`。
    public init(
        attributes: ReadingActivityAttributes,
        state: ReadingActivityAttributes.ContentState,
        @ViewBuilder endButton: @escaping (Text) -> EndButton
    ) {
        self.attributes = attributes
        self.state = state
        self.endButton = endButton
    }

    private var title: String {
        state.hideOnWidgets ? ReadingWidgetStrings.hidden : state.title
    }

    public var body: some View {
        HStack(alignment: .center, spacing: ThemeSpace.s12) {
            summary
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: ReadingWidgetStrings.liveActivityLabel(attributes: attributes, state: state)))
            if state.mode == "reading" {
                endButton(Text(ReadingWidgetStrings.endButtonTitle))
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(Text(ReadingWidgetStrings.endButtonLabel))
                    .accessibilityIdentifier("liveActivity.end")
            }
        }
        .padding(ThemeSpace.s16)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("liveActivity.banner")
    }

    @ViewBuilder
    private var summary: some View {
        switch state.mode {
        case "reading":
            VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                Text(verbatim: title)
                    .font(.headline)
                    .lineLimit(1)
                if let startedAt = attributes.startedAt {
                    Text(ReadingWidgetStrings.readingSince(startedAt))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        case "ended":
            VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                Text(verbatim: title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(verbatim: state.summaryText ?? state.progressText ?? "")
                    .font(.headline.monospacedDigit())
            }
        default:
            VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                Text(verbatim: title)
                    .font(.headline)
                    .lineLimit(1)
                if !state.hideOnWidgets, let line = state.line, !line.isEmpty {
                    Text(verbatim: line)
                        .font(ThemeTypography.widgetLine(size: 16))
                        .lineLimit(2)
                }
                if let progress = state.progressText, !progress.isEmpty {
                    Text(verbatim: progress)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - W-4 Control のラベル

public struct ReadingControlLabelView: View {
    public init() {}

    public var body: some View {
        Label(ReadingWidgetStrings.controlStartReading, systemImage: "book")
    }
}

// MARK: - W-5 「どこまで読んだ？」の小窓

public struct WhereStoppedSnippetView: View {
    let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(verbatim: text)
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ThemeSpace.s16)
            .accessibilityIdentifier("intent.snippet")
    }
}

// MARK: - 読み込み中（placeholder）

public enum ReadingWidgetPlaceholder {
    /// TimelineProvider.placeholder(in:) の項目。描くときは .redacted(reason: .placeholder) で灰の帯にし、本の文を出さない
    /// （design/ 5 の W-1、W-2 の読み込み中）。文字は帯の形を作るためだけのもので、利用者の本の値ではない。
    public static let snapshot = WidgetSnapshot(
        version: 1,
        updatedAt: "1970-01-01T00:00:00Z",
        appearanceID: .default,
        hideOnWidgets: false,
        currentBook: WidgetSnapshotBook(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID(),
            title: String(repeating: "■", count: 4),
            author: nil,
            isTitlePending: false,
            progressUnit: .page,
            progressDisplay: "p.000",
            latestLine: String(repeating: "■", count: 14),
            latestLineId: nil
        )
    )
}
