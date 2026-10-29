import SwiftUI
import ReadingCore
import ReadingStore

public enum SessionResultSheetState: Equatable, Sendable {
    case standard(summaryText: String)
    case capped(summaryText: String, noticeText: String)
}

public struct SessionResultSheetView: View {
    @Bindable var model: ReadingAppModel
    public let previewState: SessionResultSheetState?
    @Environment(\.themePalette) private var palette

    public init(model: ReadingAppModel, previewState: SessionResultSheetState? = nil) {
        self.model = model
        self.previewState = previewState
    }

    private var resolvedState: SessionResultSheetState {
        if let previewState { return previewState }
        let summary = model.store.latestResultSummary ?? "15分"
        if model.store.activeNoticeKey == "session.capped" {
            return .capped(summaryText: summary, noticeText: BannerNoticeView.message(forKey: "session.capped"))
        }
        return .standard(summaryText: summary)
    }

    private static func humanReadableSummary(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "p.", with: "ページ")
            .replacingOccurrences(of: "→", with: "から")
            .replacingOccurrences(of: "　", with: "、")
    }

    public var body: some View {
        let book = model.store.currentBook
        let bookTitle = (book?.isTitlePending == true) ? AppL10n.pick("今の本", "Reading Now") : (book?.title ?? "")

        return VStack(spacing: 0) {
            SheetHeaderBar(title: AppL10n.pick("今夜の記録", "Tonight’s Reading"))

            VStack(spacing: ThemeSpace.s24) {
                BannerNoticeView(model: model, showCloseButton: false)

                Spacer()

                VStack(spacing: ThemeSpace.s16) {
                    if !bookTitle.isEmpty {
                        Text(bookTitle)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("result.title")
                    }

                    let summaryText: String = {
                        switch resolvedState {
                        case .standard(let text), .capped(let text, _):
                            return text
                        }
                    }()

                    Text(summaryText)
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("result.summary")
                        .accessibilityLabel(Self.humanReadableSummary(summaryText))
                        .accessibilityValue(summaryText)

                    Text(AppL10n.pick("記録しました。", "Saved."))
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("result.saved")
                }

                Spacer()
            }
            .padding(ThemeSpace.s24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                Button {
                    model.store.activeNoticeKey = nil
                    model.store.showWidgetGuide = false
                    model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
                    model.activeSheet = nil
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("閉じる", "Close"))
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("result.close")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.top, ThemeSpace.s12)
            .padding(.bottom, ThemeSpace.s24)
            .background(palette.bgPrimary)
        }
        .background(palette.bgPrimary.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.result")
        .onAppear {
            model.currentScreen = .sessionResult
            model.notifyHookChanged()
        }
    }
}

public enum WidgetGuideSheetState: Equatable, Sendable {
    case visible
}

public struct WidgetGuideSheetView: View {
    @Bindable var model: ReadingAppModel
    public let state: WidgetGuideSheetState
    @Environment(\.themePalette) private var palette

    public init(model: ReadingAppModel, state: WidgetGuideSheetState = .visible) {
        self.model = model
        self.state = state
    }

    public var body: some View {
        let book = model.store.currentBook
        let sampleLine = book?.lastSavedLine ?? "下人の行方は、誰も知らない。"
        let samplePage = InputValidator.formatProgressDisplay(
            unit: book?.progressUnit ?? .page,
            page: book?.currentPage ?? 61,
            location: book?.currentLocation,
            percent: book?.currentPercent.map(Double.init)
        ) ?? "p.61"
        let stepsText = AppL10n.pick(
            "1. ロック画面を長押しして「カスタマイズ」を選びます。\n2. 時計の下の枠をタップして「よむま」を選びます。\n3. 残した一行とページがロック画面に並びます。",
            "1. Touch and hold the Lock Screen and tap Customize.\n2. Tap the widget area below the clock and choose Yomuma.\n3. Your saved line and page will appear on the Lock Screen."
        )

        return VStack(spacing: 0) {
            SheetHeaderBar(title: AppL10n.pick("ロック画面に置く", "Add to Lock Screen"))

            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s24) {
                    Text(AppL10n.pick("ロック画面にしおりを置けます", "Place Your Bookmark on the Lock Screen"))
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("widgetGuide.title")

                    HStack {
                        Spacer()
                        lockWidgetPreview(line: sampleLine, progress: samplePage)
                        Spacer()
                    }

                    Text(stepsText)
                        .font(.body)
                        .foregroundStyle(palette.textPrimary)
                        .lineSpacing(ThemeSpace.s4)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("widgetGuide.steps")
                }
                .padding(ThemeSpace.s24)
            }

            VStack(spacing: 0) {
                Button {
                    model.store.showWidgetGuide = false
                    model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
                    model.activeSheet = nil
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("閉じる", "Close"))
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("widgetGuide.close")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.top, ThemeSpace.s12)
            .padding(.bottom, ThemeSpace.s24)
            .background(palette.bgPrimary)
        }
        .background(palette.bgPrimary.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("widgetGuide")
        .onAppear {
            model.currentScreen = .widgetGuide
            model.notifyHookChanged()
        }
    }

    private func lockWidgetPreview(line: String, progress: String) -> some View {
        let shortened = VerticalLineLayout.shortenForWidget(line).text
        let cells = VerticalLineLayout.layoutVerticalCells(text: shortened, maxColumns: 2, rowsPerColumn: 12)
        let grouped = Dictionary(grouping: cells, by: \.column)
        let cols = [1, 0].compactMap { grouped[$0] != nil ? $0 : nil }

        return HStack(alignment: .top, spacing: ThemeSpace.s8) {
            VStack(alignment: .leading) {
                Spacer(minLength: 0)
                Text(progress)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer(minLength: ThemeSpace.s4)
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
        }
        .padding(ThemeSpace.s12)
        .frame(minWidth: 172, maxWidth: 172, minHeight: 76, maxHeight: 76)
        .background(
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .fill(palette.groupedRow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .stroke(palette.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("widgetGuide.preview")
        .accessibilityLabel(AppL10n.pick("ロック画面ウィジェットの見本", "Lock Screen widget preview"))
    }
}

#Preview("S-4 Session Result Standard") {
    let model = ReadingAppModel()
    SessionResultSheetView(model: model, previewState: .standard(summaryText: "p.45 → p.62　25分"))
}

#Preview("S-4 Session Result Capped") {
    let model = ReadingAppModel()
    SessionResultSheetView(model: model, previewState: .capped(summaryText: "1440分", noticeText: "24時間を上限として記録しました。"))
}

#Preview("S-5 Widget Guide AX5 Dark") {
    let model = ReadingAppModel()
    WidgetGuideSheetView(model: model)
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}
