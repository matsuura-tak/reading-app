import SwiftUI
import WidgetKit
import ReadingCore

// W-1〜W-5 の View。アプリ（H22 の撮影用の見本）と拡張（ReadingWidgetExtension）の両方のターゲットに入る。
// View は @Environment(\.widgetFamily) や ActivityViewContext を読まず、ファミリー、写し、大きさ、
// Live Activity の属性と状態を引数で受ける（contracts/test-hooks.md H22「撮影用の見本」）。

// MARK: - 共有の値

public enum ReadingWidgetMetrics {
    // 値は ReadingCore の WidgetCompositionConstants（組み方の関数の側の1か所）にあり、ここでは SwiftUI の型に直すだけ。
    private static let lock = WidgetCompositionConstants.of(.accessoryRectangular)
    private static let small = WidgetCompositionConstants.of(.systemSmall)

    /// W-1 の内側の余白（screens.md W-1「内側の余白は 0（contentMarginsDisabled）」）。
    public static let lockScreenContentMargins = EdgeInsets(
        top: CGFloat(lock.i), leading: CGFloat(lock.i), bottom: CGFloat(lock.i), trailing: CGFloat(lock.i)
    )
    /// W-2 の内側の余白（screens.md W-2「内側 16pt（contentMarginsDisabled で自分で付ける）」）。
    public static let homeSmallContentMargins = EdgeInsets(
        top: CGFloat(small.i), leading: CGFloat(small.i), bottom: CGFloat(small.i), trailing: CGFloat(small.i)
    )
    /// W-1 の左端の場所の帯の幅。
    public static let lockScreenPlaceBandWidth = CGFloat(lock.B)
    /// 帯と列の間（space.4）。
    public static let bandGap = CGFloat(lock.g)
    /// W-2 の場所の行の高さ（行の高さ 16pt）。
    public static let homeSmallPlaceRowHeight = CGFloat(WidgetCompositionConstants.pageRowHeight)
    /// W-2 の列の場所と場所の行の間（R − 場所の行の高さ）。
    public static let homeSmallPlaceRowGap = CGFloat(small.R - WidgetCompositionConstants.pageRowHeight)
}

/// 拡張と見本が同じ文を出すための、文言キーを通した文。
public enum ReadingWidgetStrings {
    public static var hidden: String { String(localized: "widget.hidden") }
    public static var empty: String { String(localized: "widget.empty") }
    public static var unavailable: String { String(localized: "widget.unavailable") }
    public static var currentBookAsTitle: String { String(localized: "widget.currentBookAsTitle") }
    public static var controlStartReading: String { String(localized: "control.startReading") }
    public static var endButtonTitle: String { String(localized: "reading.end") }
    public static var endButtonLabel: String { String(localized: "liveActivity.end.label") }

    /// W-1〜W-3 の読み上げの文（design/ 6、design/ 7 の `widget.spoken*`、`page.spoken` など。AC-99）。
    public static var spoken: WidgetSpokenStrings {
        WidgetSpokenStrings(
            empty: empty,
            unavailable: unavailable,
            hidden: hidden,
            currentBookAsTitle: currentBookAsTitle,
            pageFormat: String(localized: "page.spoken"),
            locationFormat: String(localized: "location.spoken"),
            percentFormat: String(localized: "percent.spoken"),
            spokenFormat: String(localized: "widget.spoken"),
            spokenNoPageFormat: String(localized: "widget.spoken.noPage"),
            spokenNoLineFormat: String(localized: "widget.spoken.noLine"),
            pageShortFormat: String(localized: "page.short"),
            locationShortFormat: String(localized: "location.short"),
            percentShortFormat: String(localized: "percent.short")
        )
    }

    /// 進み具合の短い形（design/ 7 の `page.short`、`location.short`、`percent.short`。AC-141）。なければ nil。
    public static func progressText(for book: WidgetSnapshotBook?) -> String? {
        spoken.progressText(book?.progress)
    }

    /// W-1・W-2 の全体の読み上げ（書名、場所、一行。著者なし）。拡張、H22、アプリの中の見本（S-5、S-10a）が同じ文を使う。
    public static func widgetLabel(for snapshot: WidgetSnapshot) -> String {
        VerticalLineLayout.buildWidgetAccessibilityLabel(snapshot: snapshot, strings: spoken)
    }

    /// 写しを読めないときは widget.unavailable の文（contracts/widget-snapshot.schema.json の読む側の決まり）。
    public static func widgetLabel(for snapshot: WidgetSnapshot, unavailableReason: WidgetUnavailableReason?) -> String {
        unavailableReason == nil ? widgetLabel(for: snapshot) : unavailable
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
            // 見える文字（liveActivity.ended.summary）を置き換えず、liveActivity.ended.spoken で組む（決定 53）。
            guard let minutes = state.minutes else {
                return strings.spokenLabel(title: title, place: place, line: nil)
            }
            let spokenMinutes = durationMinutesSpoken(minutes)
            guard let place else {
                return strings.spokenLabel(title: title, place: spokenMinutes, line: nil)
            }
            return String(format: String(localized: "liveActivity.ended.spoken"), title, spokenMinutes, place)
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
        if !book.isTitlePending, let title = book.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty { return title }
        // 書名の所は、title がなければ widget.currentBookAsTitle（contracts/widget-snapshot.schema.json の「出し方」）。
        return currentBookAsTitle
    }

    /// 分数の読み上げ（`duration.minutes.spoken`。英語は複数形 "1 minute" / "10 minutes"）。
    public static func durationMinutesSpoken(_ minutes: Int) -> String {
        String.localizedStringWithFormat(NSLocalizedString("duration.minutes.spoken", comment: ""), minutes)
    }

    /// 分数の見える文字（`duration.minutes`。60分以上も分のまま。決定 82）。
    public static func durationMinutes(_ minutes: Int) -> String {
        String(format: String(localized: "duration.minutes"), minutes)
    }

    public static func readingSince(_ startedAt: Date) -> String {
        let time = startedAt.formatted(date: .omitted, time: .shortened)
        return String(format: String(localized: "liveActivity.readingSince"), time)
    }
}

extension View {
    /// 契約 H22・AC-99：ウィジェットの全体を「書名、場所。一行」の1つの要素にまとめる。
    /// `.accessibilityElement(children: .ignore)` だけだと、縦書きの1字ずつの `Text` が XCUITest の木と
    /// アクセシビリティ監査に子として残った（G3 r3 の監査で W-1 16件・W-2 14件）。見える字の木は使わず、
    /// 読み上げの文1つだけの見えない表し方に置き換える。表し方を `Text` にすると、監査がその見えない文を
    /// 「Text clipped」と数えたため、文字を描かない要素（`Color.clear`）にラベルを付ける。
    func widgetSingleAccessibilityElement(label: String, identifier: String) -> some View {
        accessibilityRepresentation {
            Color.clear
                .accessibilityElement()
                .accessibilityLabel(Text(verbatim: label))
                .accessibilityIdentifier(identifier)
        }
    }
}

/// 縦書きの一行の字を、組み方の関数（`WidgetLineComposer`）が決めた位置にそのまま描く。
/// 座標は枠の左上を原点とする pt。この層は枠（W×H）と同じ大きさで、枠の左上に重ねる。
struct ReadingVerticalGlyphLayer: View {
    let grid: WidgetVerticalGrid

    var body: some View {
        let s = CGFloat(grid.fontSize)
        ZStack(alignment: .topLeading) {
            ForEach(Array(grid.cells.enumerated()), id: \.offset) { _, cell in
                Text(verbatim: cell.display)
                    .font(ThemeTypography.widgetLineFixed(size: s))
                    .rotationEffect(.degrees(Double(cell.rotation)))
                    .frame(width: s, height: s)
                    .offset(x: CGFloat(cell.x + cell.dx * grid.fontSize), y: CGFloat(cell.y + cell.dy * grid.fontSize))
            }
        }
        .frame(width: CGFloat(grid.frame.W), height: CGFloat(grid.frame.H), alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

/// 一行を描く状態（`normal`）のときの組み。枠は描く大きさ（拡張は GeometryReader、見本は枠の大きさ）。
private func lineComposition(
    family: WidgetSurfaceFamily,
    snapshot: WidgetSnapshot,
    unavailableReason: WidgetUnavailableReason?,
    size: CGSize
) -> WidgetLineComposition? {
    guard unavailableReason == nil,
          WidgetRenderStateResolver.state(for: snapshot) == .normal,
          let book = snapshot.currentBook,
          let line = book.line else { return nil }
    return WidgetLineComposer.compose(
        family: family,
        width: Double(size.width),
        height: Double(size.height),
        rawLine: line,
        pageText: ReadingWidgetStrings.progressText(for: book)
    )
}

// MARK: - W-1 ロック画面のウィジェット

public struct ReadingLockScreenWidgetView: View {
    let family: WidgetFamily
    let snapshot: WidgetSnapshot
    let unavailableReason: WidgetUnavailableReason?
    let size: CGSize
    let contentMargins: EdgeInsets

    /// - Parameter unavailableReason: 写しを読めなかったとき（拡張と H22 の見本が同じ読み方で決める）。
    public init(
        family: WidgetFamily,
        snapshot: WidgetSnapshot,
        unavailableReason: WidgetUnavailableReason? = nil,
        size: CGSize,
        contentMargins: EdgeInsets
    ) {
        self.family = family
        self.snapshot = snapshot
        self.unavailableReason = unavailableReason
        self.size = size
        self.contentMargins = contentMargins
    }

    private var state: WidgetRenderState {
        unavailableReason == nil ? WidgetRenderStateResolver.state(for: snapshot) : .unavailable
    }

    public var body: some View {
        let label = ReadingWidgetStrings.widgetLabel(for: snapshot, unavailableReason: unavailableReason)
        let composition = family == .accessoryRectangular
            ? lineComposition(family: .accessoryRectangular, snapshot: snapshot, unavailableReason: unavailableReason, size: size)
            : nil
        content(composition: composition)
            .padding(contentMargins)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .overlay(alignment: .topLeading) {
                if let grid = composition?.grid {
                    ReadingVerticalGlyphLayer(grid: grid)
                }
            }
            .widgetSingleAccessibilityElement(label: label, identifier: "widget.rectangular")
    }

    @ViewBuilder
    private func content(composition: WidgetLineComposition?) -> some View {
        switch family {
        case .accessoryInline:
            if unavailableReason != nil {
                Text(ReadingWidgetStrings.unavailable)
            } else if let book = snapshot.currentBook {
                let title = ReadingWidgetStrings.displayTitle(for: book, hideOnWidgets: snapshot.hideOnWidgets)
                if let progress = ReadingWidgetStrings.progressText(for: book) {
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
                Text(unavailableReason == nil ? (ReadingWidgetStrings.progressText(for: snapshot.currentBook) ?? ReadingWidgetStrings.hidden) : "—")
                    .font(.caption2.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            rectangularContent(composition: composition)
        }
    }

    @ViewBuilder
    private func placeBand(_ progress: String) -> some View {
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
    }

    @ViewBuilder
    private func rectangularContent(composition: WidgetLineComposition?) -> some View {
        switch state {
        case .unavailable, .empty:
            Text(state == .unavailable ? ReadingWidgetStrings.unavailable : ReadingWidgetStrings.empty)
                .font(.caption)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
        case .normal:
            let progress = ReadingWidgetStrings.progressText(for: snapshot.currentBook) ?? ""
            HStack(alignment: .top, spacing: ReadingWidgetMetrics.bandGap) {
                placeBand(progress)
                if let composition, composition.grid == nil {
                    // 横書き（AC-30）
                    Text(verbatim: composition.displayedLine)
                        .font(.headline)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    // 縦書きの字は overlay の ReadingVerticalGlyphLayer が組みの位置に描く。
                    Spacer(minLength: 0)
                }
            }
        case .hidden, .noLine, .noLineNoPage:
            if let book = snapshot.currentBook {
                let progress = ReadingWidgetStrings.progressText(for: book) ?? ""
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
        }
    }
}

// MARK: - W-2 小のウィジェット

public struct ReadingHomeSmallWidgetView: View {
    let snapshot: WidgetSnapshot
    let unavailableReason: WidgetUnavailableReason?
    let size: CGSize
    let contentMargins: EdgeInsets

    public init(
        snapshot: WidgetSnapshot,
        unavailableReason: WidgetUnavailableReason? = nil,
        size: CGSize,
        contentMargins: EdgeInsets
    ) {
        self.snapshot = snapshot
        self.unavailableReason = unavailableReason
        self.size = size
        self.contentMargins = contentMargins
    }

    private var palette: ThemePalette {
        ThemePalette(appearanceID: snapshot.appearanceID)
    }

    private var state: WidgetRenderState {
        unavailableReason == nil ? WidgetRenderStateResolver.state(for: snapshot) : .unavailable
    }

    public var body: some View {
        let label = ReadingWidgetStrings.widgetLabel(for: snapshot, unavailableReason: unavailableReason)
        let composition = lineComposition(family: .systemSmall, snapshot: snapshot, unavailableReason: unavailableReason, size: size)
        content(composition: composition)
            .foregroundStyle(palette.textPrimary)
            .padding(contentMargins)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .overlay(alignment: .topLeading) {
                if let grid = composition?.grid {
                    ReadingVerticalGlyphLayer(grid: grid)
                        .foregroundStyle(palette.textPrimary)
                }
            }
            .widgetSingleAccessibilityElement(label: label, identifier: "widget.small")
    }

    @ViewBuilder
    private func content(composition: WidgetLineComposition?) -> some View {
        switch state {
        case .unavailable, .empty:
            Text(state == .unavailable ? ReadingWidgetStrings.unavailable : ReadingWidgetStrings.empty)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .lineLimit(4)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        case .normal, .hidden, .noLine, .noLineNoPage:
            let book = snapshot.currentBook
            let progress = ReadingWidgetStrings.progressText(for: book) ?? ""
            VStack(alignment: .leading, spacing: ReadingWidgetMetrics.homeSmallPlaceRowGap) {
                if state == .normal {
                    if let composition, composition.grid == nil {
                        // 横書き（AC-30）
                        Text(verbatim: composition.displayedLine)
                            .font(.subheadline)
                            .lineLimit(4)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    } else {
                        // 縦書きの字は overlay の ReadingVerticalGlyphLayer が組みの位置に描く。
                        Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if let book {
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
            // 写しは全文を持つ。W-3 の一行はウィジェットと同じ25字に縮めたもの（G3 r2 までと同じ）。
            line: snapshot.hideOnWidgets ? nil : book.line.map { VerticalLineLayout.shortenForWidget($0).text },
            progressText: ReadingWidgetStrings.progressText(for: book),
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
        let duration = ReadingWidgetStrings.durationMinutes(minutes)
        let summary: String
        if let progressText, !progressText.isEmpty {
            summary = String(format: String(localized: "liveActivity.ended.summary"), duration, progressText)
        } else {
            summary = duration
        }
        return ReadingActivityAttributes.ContentState(
            mode: "ended",
            title: ReadingWidgetStrings.displayTitle(for: book, hideOnWidgets: snapshot.hideOnWidgets),
            line: nil,
            progressText: progressText,
            summaryText: summary,
            hideOnWidgets: snapshot.hideOnWidgets,
            minutes: minutes
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
        appearanceID: .default,
        hideOnWidgets: false,
        currentBook: WidgetSnapshotBook(
            title: String(repeating: "■", count: 4),
            line: String(repeating: "■", count: 14),
            progress: WidgetSnapshotProgress(unit: .page, value: 100)
        )
    )
}
