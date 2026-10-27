import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents
import ReadingCore
import ReadingStore

public struct ReadingWidgetTimelineEntry: TimelineEntry, Sendable {
    public let date: Date
    public let snapshot: WidgetSnapshot

    public init(date: Date, snapshot: WidgetSnapshot) {
        self.date = date
        self.snapshot = snapshot
    }
}

public struct ReadingWidgetTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> ReadingWidgetTimelineEntry {
        ReadingWidgetTimelineEntry(
            date: Date(),
            snapshot: WidgetSnapshot(
                version: 1,
                updatedAt: "1970-01-01T00:00:00Z",
                appearanceID: .default,
                hideOnWidgets: false,
                currentBook: nil
            )
        )
    }

    public func getSnapshot(in context: Context, completion: @escaping @Sendable (ReadingWidgetTimelineEntry) -> Void) {
        let snapshot = ReadingSharedContainer.loadWidgetSnapshot()
        completion(ReadingWidgetTimelineEntry(date: Date(), snapshot: snapshot))
    }

    public func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<ReadingWidgetTimelineEntry>) -> Void) {
        let snapshot = ReadingSharedContainer.loadWidgetSnapshot()
        let entry = ReadingWidgetTimelineEntry(date: Date(), snapshot: snapshot)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

// MARK: - Vertical Text Grid for Widget (W-1)

struct VerticalQuoteWidgetGridView: View {
    let cells: [H22GlyphCell]
    let columnCount: Int
    let rowsPerColumn: Int
    let textPrimary: Color

    var body: some View {
        let maxCol = max(columnCount, 1)
        let maxRow = max(rowsPerColumn, 1)
        HStack(alignment: .top, spacing: 6) {
            ForEach((1...maxCol).reversed(), id: \.self) { col in
                VStack(alignment: .center, spacing: 2) {
                    ForEach(1...maxRow, id: \.self) { row in
                        if let cell = cells.first(where: { $0.column == col && $0.row == row }) {
                            Text(cell.display)
                                .font(.custom("Hiragino Mincho ProN", size: 15, relativeTo: .subheadline))
                                .foregroundStyle(textPrimary)
                                .rotationEffect(.degrees(Double(cell.rotation)))
                                .offset(x: cell.dx * 15.0, y: cell.dy * 15.0)
                        } else {
                            Text("　")
                                .font(.custom("Hiragino Mincho ProN", size: 15, relativeTo: .subheadline))
                                .opacity(0)
                        }
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - W-2: Home Small Widget (.systemSmall)

struct ReadingHomeSmallWidgetView: View {
    let entry: ReadingWidgetTimelineEntry

    private var palette: ThemePalette {
        ThemePalette(appearanceID: entry.snapshot.appearanceID)
    }

    private var composition: H22WidgetComposition {
        VerticalLineLayout.composeWidget(snapshot: entry.snapshot)
    }

    private var destinationURL: URL {
        URL(string: "yomuma://open?entry=small_widget") ?? URL(fileURLWithPath: "/")
    }

    var body: some View {
        let comp = composition
        VStack(alignment: .leading, spacing: 6) {
            if let book = entry.snapshot.currentBook {
                if entry.snapshot.hideOnWidgets {
                    Text("しおり")
                        .font(.custom("Hiragino Mincho ProN", size: 15, relativeTo: .subheadline))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                        .accessibilityIdentifier("widget.hidden")
                    Spacer(minLength: 4)
                    if let progress = book.progressDisplay, !progress.isEmpty {
                        Text(progress)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(palette.accent)
                            .lineLimit(1)
                            .accessibilityIdentifier("widget.page")
                    }
                } else {
                    if comp.orientation == .vertical && !comp.cells.isEmpty {
                        HStack {
                            Spacer(minLength: 0)
                            VerticalQuoteWidgetGridView(
                                cells: comp.cells,
                                columnCount: comp.columnCount,
                                rowsPerColumn: max(comp.rowsPerColumn, 1),
                                textPrimary: palette.textPrimary
                            )
                        }
                    } else if let line = comp.displayedLine, !line.isEmpty {
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(palette.textPrimary)
                            .lineLimit(3)
                    } else {
                        Text(book.isTitlePending ? "しおり" : (book.title ?? "しおり"))
                            .font(.custom("Hiragino Mincho ProN", size: 15, relativeTo: .subheadline))
                            .foregroundStyle(palette.textPrimary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 4)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.isTitlePending ? "しおり" : (book.title ?? "しおり"))
                            .font(.caption2)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(1)
                        if let progress = book.progressDisplay, !progress.isEmpty {
                            Text(progress)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(palette.accent)
                                .lineLimit(1)
                        }
                    }
                }
            } else {
                Spacer(minLength: 0)
                Text("いま読んでいる本はありません")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(destinationURL)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(comp.accessibilityLabel))
        .containerBackground(palette.bgPrimary, for: .widget)
    }
}

public struct ReadingHomeSmallWidget: Widget {
    public let kind: String = "ReadingHomeSmallWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingWidgetTimelineProvider()) { entry in
            ReadingHomeSmallWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.small.name"))
        .description(Text("widget.gallery.small.description"))
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - W-1: Lock Screen Widgets (.accessoryRectangular)

struct ReadingLockScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ReadingWidgetTimelineEntry

    private var composition: H22WidgetComposition {
        VerticalLineLayout.composeWidget(snapshot: entry.snapshot)
    }

    private var destinationURL: URL {
        URL(string: "yomuma://open?entry=lock_widget") ?? URL(fileURLWithPath: "/")
    }

    var body: some View {
        let comp = composition
        Group {
            switch family {
            case .accessoryInline:
                if let book = entry.snapshot.currentBook {
                    let titleText = entry.snapshot.hideOnWidgets
                        ? "しおり"
                        : (book.isTitlePending ? "しおり" : (book.title ?? "しおり"))
                    if let progress = book.progressDisplay, !progress.isEmpty {
                        Text("📖 \(titleText) \(progress)")
                    } else {
                        Text("📖 \(titleText)")
                    }
                } else {
                    Text("いま読んでいる本はありません")
                }
            case .accessoryCircular:
                VStack(spacing: 2) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                    if let book = entry.snapshot.currentBook, let progress = book.progressDisplay, !progress.isEmpty {
                        Text(progress)
                            .font(.caption2.monospacedDigit())
                            .lineLimit(1)
                    } else {
                        Text("しおり")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            default:
                if let book = entry.snapshot.currentBook {
                    if entry.snapshot.hideOnWidgets {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("しおり")
                                .font(.headline)
                                .lineLimit(1)
                                .accessibilityIdentifier("widget.hidden")
                            if let progress = book.progressDisplay, !progress.isEmpty {
                                Text(progress)
                                    .font(.caption.monospacedDigit())
                                    .lineLimit(1)
                                    .accessibilityIdentifier("widget.page")
                            }
                        }
                    } else if comp.orientation == .vertical && !comp.cells.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.isTitlePending ? "しおり" : (book.title ?? "しおり"))
                                    .font(.caption2)
                                    .lineLimit(1)
                                if let progress = book.progressDisplay, !progress.isEmpty {
                                    Text(progress)
                                        .font(.caption2.monospacedDigit())
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 0)
                            VerticalQuoteWidgetGridView(
                                cells: comp.cells,
                                columnCount: comp.columnCount,
                                rowsPerColumn: max(comp.rowsPerColumn, 1),
                                textPrimary: .primary
                            )
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.isTitlePending ? "しおり" : (book.title ?? "しおり"))
                                .font(.headline)
                                .lineLimit(1)
                            if let progress = book.progressDisplay, !progress.isEmpty {
                                Text(progress)
                                    .font(.caption.monospacedDigit())
                                    .lineLimit(1)
                            }
                            if let line = comp.displayedLine, !line.isEmpty {
                                Text(line)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("いま読んでいる本はありません")
                            .font(.caption)
                    }
                }
            }
        }
        .widgetURL(destinationURL)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(comp.accessibilityLabel))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

public struct ReadingLockScreenWidget: Widget {
    public let kind: String = "ReadingLockScreenWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingWidgetTimelineProvider()) { entry in
            ReadingLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.lock.name"))
        .description(Text("widget.gallery.lock.description"))
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

// MARK: - W-4: Control Widget

public struct ReadingControlWidget: ControlWidget {
    public let kind: String = "ReadingControlWidget"

    public init() {}

    public var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: StartReadingIntent()) {
                Label("今夜の読書を始める", systemImage: "book.fill")
            }
        }
        .displayName("今夜の読書を始める")
        .description("しおりの続きから今夜の読書を始めます。")
    }
}

// MARK: - W-3: Live Activity (Dynamic Island & Lock Screen Banner)

public struct ReadingLiveActivityWidget: Widget {
    public init() {}

    private var liveActivityURL: URL {
        URL(string: "yomuma://open?entry=live_activity") ?? URL(fileURLWithPath: "/")
    }

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingActivityAttributes.self) { context in
            let displayTitle = context.state.hideOnWidgets ? "しおり" : context.state.title
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    if context.state.mode == "ended", let summary = context.state.summaryText, !summary.isEmpty {
                        Text(summary)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else if context.state.mode != "reading" {
                        if !context.state.hideOnWidgets, let line = context.state.line, !line.isEmpty {
                            Text(line)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        if let progress = context.state.progressText, !progress.isEmpty {
                            Text(progress)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer(minLength: 8)
                if context.state.mode == "reading" {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("読書中")
                            .font(.caption.weight(.medium))
                        Button(intent: EndReadingFromActivityIntent()) {
                            Text("終える")
                                .font(.caption.weight(.semibold))
                        }
                        .accessibilityIdentifier("liveActivity.end")
                    }
                } else if context.state.mode == "ended" {
                    Text("おやすみなさい")
                        .font(.caption.weight(.medium))
                } else {
                    Text("今夜の読書を始める")
                        .font(.caption.weight(.semibold))
                }
            }
            .padding(16)
            .widgetURL(liveActivityURL)
            .activityBackgroundTint(Color("DefaultBgSecondary"))
        } dynamicIsland: { context in
            let displayTitle = context.state.hideOnWidgets ? "しおり" : context.state.title
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.mode == "reading" ? "読書中" : displayTitle, systemImage: "book.fill")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.mode == "reading" {
                        Button(intent: EndReadingFromActivityIntent()) {
                            Text("終える")
                                .font(.caption.weight(.semibold))
                        }
                        .accessibilityIdentifier("liveActivity.end")
                    } else if let progress = context.state.progressText {
                        Text(progress)
                            .font(.caption.monospacedDigit())
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(displayTitle)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: "book.fill")
            } compactTrailing: {
                Text(context.state.progressText ?? "")
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "book.fill")
            }
            .widgetURL(liveActivityURL)
        }
    }
}

@main
struct ReadingWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ReadingHomeSmallWidget()
        ReadingLockScreenWidget()
        ReadingControlWidget()
        ReadingLiveActivityWidget()
    }
}
