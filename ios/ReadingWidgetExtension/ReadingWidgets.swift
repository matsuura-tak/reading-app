import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents
import ReadingCore
import ReadingStore

public struct ReadingWidgetTimelineEntry: TimelineEntry, Sendable {
    public let date: Date
    public let snapshot: WidgetSnapshot
    /// 写しを読めなかったとき（widget.unavailable を出す）。
    public let unavailableReason: WidgetUnavailableReason?

    public init(date: Date, snapshot: WidgetSnapshot, unavailableReason: WidgetUnavailableReason? = nil) {
        self.date = date
        self.snapshot = snapshot
        self.unavailableReason = unavailableReason
    }

    /// 写しを読んだ結果から作る。読めないときの写しは空（今の本なし）で、描くのは unavailable。
    public init(date: Date, result: WidgetSnapshotReadResult) {
        self.date = date
        self.snapshot = result.snapshot ?? WidgetSnapshot(updatedAt: "1970-01-01T00:00:00Z")
        self.unavailableReason = result.unavailableReason
    }
}

public struct ReadingWidgetTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> ReadingWidgetTimelineEntry {
        ReadingWidgetTimelineEntry(date: Date(), snapshot: ReadingWidgetPlaceholder.snapshot)
    }

    public func getSnapshot(in context: Context, completion: @escaping @Sendable (ReadingWidgetTimelineEntry) -> Void) {
        completion(ReadingWidgetTimelineEntry(date: Date(), result: ReadingSharedContainer.readWidgetSnapshot()))
    }

    public func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<ReadingWidgetTimelineEntry>) -> Void) {
        // H22 の timeline と同じ決まり（ReadingCore の WidgetTimelinePlan）。
        let result = ReadingSharedContainer.readWidgetSnapshot()
        let plan = WidgetTimelinePlan.make(now: Date())
        let entries = plan.entryDates.map { ReadingWidgetTimelineEntry(date: $0, result: result) }
        let policy: TimelineReloadPolicy
        switch plan.policy {
        case .never: policy = .never
        case .atEnd: policy = .atEnd
        case .after(let date): policy = .after(date)
        }
        completion(Timeline(entries: entries, policy: policy))
    }
}

// MARK: - W-2: Home Small Widget (.systemSmall)
// View の本体は ios/ReadingApp/Shared/ReadingWidgetSurfaceViews.swift（アプリの H22 の見本と共有）。

struct ReadingHomeSmallWidgetEntryView: View {
    let entry: ReadingWidgetTimelineEntry

    var body: some View {
        GeometryReader { proxy in
            ReadingHomeSmallWidgetView(
                snapshot: entry.snapshot,
                unavailableReason: entry.unavailableReason,
                size: proxy.size,
                contentMargins: ReadingWidgetMetrics.homeSmallContentMargins
            )
        }
        .widgetURL(URL(string: "yomuma://open?entry=small_widget"))
        .containerBackground(ThemePalette(appearanceID: entry.snapshot.appearanceID).bgPrimary, for: .widget)
    }
}

public struct ReadingHomeSmallWidget: Widget {
    public let kind: String = "ReadingHomeSmallWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingWidgetTimelineProvider()) { entry in
            ReadingHomeSmallWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.small.name"))
        .description(Text("widget.gallery.small.description"))
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// MARK: - W-1: Lock Screen Widgets (.accessoryRectangular)

struct ReadingLockScreenWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var systemMargins
    let entry: ReadingWidgetTimelineEntry

    var body: some View {
        GeometryReader { proxy in
            ReadingLockScreenWidgetView(
                family: family,
                snapshot: entry.snapshot,
                unavailableReason: entry.unavailableReason,
                size: proxy.size,
                contentMargins: family == .accessoryRectangular ? ReadingWidgetMetrics.lockScreenContentMargins : systemMargins
            )
        }
        .widgetURL(URL(string: "yomuma://open?entry=lock_widget"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

public struct ReadingLockScreenWidget: Widget {
    public let kind: String = "ReadingLockScreenWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingWidgetTimelineProvider()) { entry in
            ReadingLockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(Text("widget.gallery.lock.name"))
        .description(Text("widget.gallery.lock.description"))
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
        .contentMarginsDisabled()
    }
}

// MARK: - W-4: Control Widget

public struct ReadingControlWidget: ControlWidget {
    public let kind: String = "ReadingControlWidget"

    public init() {}

    public var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: StartReadingIntent()) {
                ReadingControlLabelView()
            }
        }
        .displayName(LocalizedStringResource("control.startReading"))
    }
}

// MARK: - W-3: Live Activity (Dynamic Island & Lock Screen Banner)

public struct ReadingLiveActivityWidget: Widget {
    public init() {}

    private var liveActivityURL: URL? {
        URL(string: "yomuma://open?entry=live_activity")
    }

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingActivityAttributes.self) { context in
            ReadingLiveActivityLockScreenView(attributes: context.attributes, state: context.state) { label in
                Button(intent: EndReadingFromActivityIntent()) { label }
            }
            .widgetURL(liveActivityURL)
            .activityBackgroundTint(Color("DefaultBackgroundSecondary"))
        } dynamicIsland: { context in
            let displayTitle = context.state.hideOnWidgets ? ReadingWidgetStrings.hidden : context.state.title
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(displayTitle, systemImage: "book")
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.mode == "reading" {
                        Button(intent: EndReadingFromActivityIntent()) {
                            Text(ReadingWidgetStrings.endButtonTitle)
                        }
                        .accessibilityLabel(Text(ReadingWidgetStrings.endButtonLabel))
                        .accessibilityIdentifier("liveActivity.end")
                    } else if let progress = context.state.progressText {
                        Text(verbatim: progress)
                            .font(.caption.monospacedDigit())
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.mode == "reading", let startedAt = context.attributes.startedAt {
                        Text(ReadingWidgetStrings.readingSince(startedAt))
                            .font(.subheadline.monospacedDigit())
                    } else if !context.state.hideOnWidgets, let line = context.state.line, !line.isEmpty {
                        Text(verbatim: line)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Image(systemName: "book")
            } compactTrailing: {
                if context.state.mode == "reading", let startedAt = context.attributes.startedAt {
                    Text(startedAt, style: .time)
                        .font(.caption2.monospacedDigit())
                } else {
                    Text(verbatim: context.state.progressText ?? "")
                        .font(.caption2.monospacedDigit())
                }
            } minimal: {
                Image(systemName: "book")
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
