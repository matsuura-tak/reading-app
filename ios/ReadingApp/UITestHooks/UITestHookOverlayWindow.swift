#if UITEST_HOOKS
import SwiftUI
import UIKit
import ReadingCore
import ReadingStore

public struct UITestHookOverlayView: View {
    @Bindable var model: ReadingAppModel
    @Bindable var coordinator: UITestHookCoordinator

    public init(model: ReadingAppModel, coordinator: UITestHookCoordinator = .shared) {
        self.model = model
        self.coordinator = coordinator
    }

    public var body: some View {
        if coordinator.areReadoutsEnabled {
            let _ = model.hookGeneration
            let _ = model.store.books.count
            let _ = model.store.records.count
            let _ = model.store.books.first?.title
            let _ = model.store.books.first?.isTitlePending
            let _ = model.store.books.first?.currentPage
            let _ = model.store.books.first?.lastSavedLine
            let _ = model.store.sessionState
            let _ = model.store.hapticCount
            let _ = model.store.activeErrorKey
            let _ = model.store.activeNoticeKey
            let _ = model.store.storeStatusMessageKey
            let _ = model.store.settings.isPlusPurchased
            let _ = model.store.settings.appearanceID
            let _ = model.store.openedURLs.count
            let _ = model.store.shareCards.count
            let _ = model.store.intentInvocations.count
            let stateStr = UITestHookReadoutBuilder.stateJSON(model: model)
            let storeStr = UITestHookReadoutBuilder.storeJSON(model: model)
            let widgetStr = UITestHookReadoutBuilder.widgetJSON(model: model)
            let outboundStr = UITestHookReadoutBuilder.outboundJSON(model: model)
            let liveActivityStr = UITestHookReadoutBuilder.liveActivityJSON(model: model)
            let storekitStr = UITestHookReadoutBuilder.storekitJSON(model: model)
            let intentsStr = UITestHookReadoutBuilder.intentsJSON(model: model)
            let shareCardStr = UITestHookReadoutBuilder.shareCardJSON(model: model)
            let awardsStr = UITestHookReadoutBuilder.awardsJSON(model: model)
            let mediaAuditStr = UITestHookReadoutBuilder.mediaAuditJSON(model: model)

            ZStack(alignment: .topLeading) {
                readoutElement(id: "hook.state", value: stateStr)
                readoutElement(id: "hook.store", value: storeStr)
                readoutElement(id: "hook.widget", value: widgetStr)
                readoutElement(id: "hook.outbound", value: outboundStr)
                readoutElement(id: "hook.liveActivity", value: liveActivityStr)
                readoutElement(id: "hook.storekit", value: storekitStr)
                readoutElement(id: "hook.intents", value: intentsStr)
                readoutElement(id: "hook.shareCard", value: shareCardStr)
                readoutElement(id: "hook.awards", value: awardsStr)
                readoutElement(id: "hook.mediaAudit", value: mediaAuditStr)
            }
            .allowsHitTesting(false)
        }
    }

    private func readoutElement(id: String, value: String) -> some View {
        HookReadoutAccessibleView(id: id, value: value)
            .frame(minWidth: 44, maxWidth: 44, minHeight: 44, maxHeight: 44)
    }
}

private struct HookReadoutAccessibleView: UIViewRepresentable {
    let id: String
    let value: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = true
        view.accessibilityTraits = .none
        view.accessibilityIdentifier = id
        view.accessibilityLabel = id
        view.accessibilityValue = value
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.accessibilityIdentifier = id
        uiView.accessibilityLabel = id
        uiView.accessibilityValue = value
    }
}

public struct WidgetShowcaseHarnessView: View {
    @Bindable var model: ReadingAppModel
    public let spec: String
    @Environment(\.themePalette) private var palette

    public init(model: ReadingAppModel, spec: String) {
        self.model = model
        self.spec = spec
    }

    public var body: some View {
        let book = model.store.currentBook
        let hideOnWidgets = model.store.settings.hideOnWidgets
        let rawLine = hideOnWidgets ? nil : book?.lastSavedLine
        let rawTitle = hideOnWidgets ? AppL10n.pick("しおり", "Bookmark") : ((book?.isTitlePending == true) ? AppL10n.pick("今の本", "Reading Now") : (book?.title ?? AppL10n.pick("しおり", "Bookmark")))
        let progressText: String = {
            guard let book else { return "" }
            return InputValidator.formatProgressDisplay(
                unit: book.progressUnit,
                page: book.currentPage,
                location: book.currentLocation,
                percent: book.currentPercent.map(Double.init)
            ) ?? ""
        }()
        let lower = spec.lowercased()

        VStack(spacing: ThemeSpace.s24) {
            Spacer()

            if lower.contains("w-1") || lower.contains("w1") || lower.contains("accessoryrectangular") {
                let isCompact = lower.contains("153x68")
                let width: CGFloat = isCompact ? 153 : 172
                let height: CGFloat = isCompact ? 68 : 76
                lockWidgetCard(
                    line: rawLine,
                    title: rawTitle,
                    progress: progressText,
                    hasBook: book != nil,
                    width: width,
                    height: height
                )
            } else if lower.contains("w-2") || lower.contains("w2") || lower.contains("systemsmall") {
                let isCompact = lower.contains("148x148")
                let side: CGFloat = isCompact ? 148 : 170
                smallWidgetCard(
                    line: rawLine,
                    title: rawTitle,
                    progress: progressText,
                    hasBook: book != nil,
                    side: side
                )
            } else if lower.contains("w-3") || lower.contains("w3") || lower.contains("liveactivity") {
                liveActivityShowcase(
                    line: rawLine,
                    title: rawTitle,
                    progress: progressText,
                    mode: lower
                )
            } else if lower.contains("w-4") || lower.contains("w4") || lower.contains("control") {
                controlCenterShowcase(title: rawTitle)
            } else {
                siriSnippetShowcase(progress: progressText.isEmpty ? "p.61" : progressText)
            }

            Spacer()
        }
        .padding(ThemeSpace.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.bgPrimary)
        .accessibilityIdentifier("screen.widgetShowcase")
    }

    private func lockWidgetCard(
        line: String?,
        title: String,
        progress: String,
        hasBook: Bool,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let shortened = line.map { VerticalLineLayout.shortenForWidget($0).text }
        return ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .fill(palette.groupedRow)
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                        .stroke(palette.hairline, lineWidth: 1)
                )

            if !hasBook {
                Text(AppL10n.pick("よむまで本を選ぶ", "Choose a book in Yomuma"))
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .accessibilityIdentifier("widget.empty")
            } else {
                HStack(alignment: .top, spacing: ThemeSpace.s8) {
                    VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                        Spacer(minLength: 0)
                        if !progress.isEmpty {
                            Text(progress)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(palette.textSecondary)
                                .accessibilityIdentifier("widget.page")
                        }
                    }

                    Spacer(minLength: ThemeSpace.s4)

                    if let shortened, !shortened.isEmpty {
                        if VerticalLineLayout.containsJapaneseScript(shortened) {
                            let cells = VerticalLineLayout.layoutVerticalCells(text: shortened, maxColumns: 2, rowsPerColumn: 12)
                            let grouped = Dictionary(grouping: cells, by: \.column)
                            let cols = [1, 0].compactMap { grouped[$0] != nil ? $0 : nil }
                            HStack(alignment: .top, spacing: ThemeSpace.s4) {
                                ForEach(cols, id: \.self) { colNum in
                                    let colCells = grouped[colNum] ?? []
                                    VStack(spacing: 0) {
                                        ForEach(Array(colCells.enumerated()), id: \.offset) { _, cell in
                                            Text(cell.display)
                                                .font(ThemeTypography.widgetLine(size: 11))
                                                .foregroundStyle(palette.textPrimary)
                                        }
                                    }
                                }
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityIdentifier("widget.line")
                            .accessibilityLabel(shortened)
                        } else {
                            Text(shortened)
                                .font(ThemeTypography.widgetLine(size: 12))
                                .foregroundStyle(palette.textPrimary)
                                .lineLimit(2)
                                .accessibilityIdentifier("widget.line")
                        }
                    } else {
                        Text(title)
                            .font(ThemeTypography.widgetLine(size: 13))
                            .foregroundStyle(palette.textPrimary)
                            .lineLimit(2)
                            .accessibilityIdentifier("widget.title")
                    }
                }
                .padding(ThemeSpace.s12)
            }
        }
        .frame(minWidth: width, maxWidth: width, minHeight: height, maxHeight: height)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("widget.accessoryRectangular")
    }

    private func smallWidgetCard(
        line: String?,
        title: String,
        progress: String,
        hasBook: Bool,
        side: CGFloat
    ) -> some View {
        let shortened = line.map { VerticalLineLayout.shortenForWidget($0).text }
        return ZStack {
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .fill(palette.bgPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                        .stroke(palette.hairline, lineWidth: 1)
                )

            if !hasBook {
                Text(AppL10n.pick("よむまで本を選ぶ", "Choose a book in Yomuma"))
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(ThemeSpace.s12)
                    .accessibilityIdentifier("widget.empty")
            } else {
                VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                    HStack(alignment: .top) {
                        Spacer()
                        if let shortened, !shortened.isEmpty {
                            if VerticalLineLayout.containsJapaneseScript(shortened) {
                                let cells = VerticalLineLayout.layoutVerticalCells(text: shortened, maxColumns: 2, rowsPerColumn: 12)
                                let grouped = Dictionary(grouping: cells, by: \.column)
                                let cols = [1, 0].compactMap { grouped[$0] != nil ? $0 : nil }
                                HStack(alignment: .top, spacing: ThemeSpace.s8) {
                                    ForEach(cols, id: \.self) { colNum in
                                        let colCells = grouped[colNum] ?? []
                                        VStack(spacing: 1) {
                                            ForEach(Array(colCells.enumerated()), id: \.offset) { _, cell in
                                                Text(cell.display)
                                                    .font(ThemeTypography.widgetLine(size: 14))
                                                    .foregroundStyle(palette.textPrimary)
                                            }
                                        }
                                    }
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityIdentifier("widget.line")
                                .accessibilityLabel(shortened)
                            } else {
                                Text(shortened)
                                    .font(ThemeTypography.widgetLine(size: 14))
                                    .foregroundStyle(palette.textPrimary)
                                    .lineLimit(3)
                                    .accessibilityIdentifier("widget.line")
                            }
                        } else {
                            Text(title)
                                .font(ThemeTypography.widgetLine(size: 16))
                                .foregroundStyle(palette.textPrimary)
                                .lineLimit(3)
                                .accessibilityIdentifier("widget.title")
                        }
                        Spacer()
                    }
                    Spacer(minLength: 0)
                    HStack {
                        if !progress.isEmpty {
                            Text(progress)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(palette.textSecondary)
                                .accessibilityIdentifier("widget.page")
                        }
                        Spacer()
                        Text(title)
                            .font(.caption2)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(ThemeSpace.s16)
            }
        }
        .frame(minWidth: side, maxWidth: side, minHeight: side, maxHeight: side)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("widget.systemSmall")
    }

    private func liveActivityShowcase(
        line: String?,
        title: String,
        progress: String,
        mode: String
    ) -> some View {
        let showSingleState = mode.contains("waiting") || mode.contains("reading") || mode.contains("ended")
        return VStack(spacing: ThemeSpace.s16) {
            if !showSingleState || mode.contains("waiting") {
                VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                    HStack {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        if !progress.isEmpty {
                            Text(progress)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(palette.textSecondary)
                        }
                    }
                    if let line, !line.isEmpty {
                        Text(line)
                            .font(ThemeTypography.widgetLine(size: 14))
                            .foregroundStyle(palette.textPrimary)
                            .lineLimit(1)
                    }
                    Text(AppL10n.pick("続きから読む", "Continue Reading"))
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                .padding(ThemeSpace.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.groupedRow, in: RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                        .stroke(palette.hairline, lineWidth: 1)
                )
                .accessibilityIdentifier("liveActivity.waiting")
            }

            if !showSingleState || mode.contains("reading") {
                HStack(spacing: ThemeSpace.s12) {
                    VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundStyle(palette.textPrimary)
                        Text(AppL10n.pick("21:04 から数えています。", "Counting since 21:04."))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(palette.textSecondary)
                    }
                    Spacer()
                    Button {} label: {
                        Text(AppL10n.pick("終える", "End Reading"))
                    }
                    .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                    .frame(minWidth: 112, maxWidth: 112)
                    .accessibilityIdentifier("liveActivity.end")
                }
                .padding(ThemeSpace.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.groupedRow, in: RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                        .stroke(palette.hairline, lineWidth: 1)
                )
                .accessibilityIdentifier("liveActivity.reading")
            }

            if !showSingleState || mode.contains("ended") {
                HStack {
                    Text(progress.isEmpty ? "18分" : "\(progress)　18分")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(palette.textPrimary)
                    Spacer()
                    Text(AppL10n.pick("記録しました。", "Saved."))
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                .padding(ThemeSpace.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.groupedRow, in: RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                        .stroke(palette.hairline, lineWidth: 1)
                )
                .accessibilityIdentifier("liveActivity.ended")
            }
        }
    }

    private func controlCenterShowcase(title: String) -> some View {
        HStack(spacing: ThemeSpace.s12) {
            Image(systemName: "book.fill")
                .font(.title3)
                .foregroundStyle(palette.actionPrimaryLabel)
            VStack(alignment: .leading, spacing: 2) {
                Text(AppL10n.pick("読書を始める", "Start Reading"))
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.actionPrimaryLabel)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(palette.actionPrimaryLabel)
            }
            Spacer()
        }
        .padding(ThemeSpace.s16)
        .frame(minWidth: 220, maxWidth: 220, minHeight: 72)
        .background(palette.actionPrimaryBg, in: RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("control.startReading")
    }

    private func siriSnippetShowcase(progress: String) -> some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s8) {
            Text(AppL10n.pick("しおりの位置", "Bookmark Position"))
                .font(.caption)
                .foregroundStyle(palette.textSecondary)
            Text(progress)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(palette.textPrimary)
                .accessibilityIdentifier("snippet.progress")
            Text(AppL10n.pick("61ページからです。", "You stopped at page 61."))
                .font(.subheadline)
                .foregroundStyle(palette.textPrimary)
        }
        .padding(ThemeSpace.s16)
        .frame(minWidth: 280, maxWidth: 280, alignment: .leading)
        .background(palette.groupedRow, in: RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .stroke(palette.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("snippet.whereStopped")
    }
}
#endif
