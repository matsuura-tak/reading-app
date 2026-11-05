import SwiftUI
import ReadingCore
import ReadingStore

public enum ReadingSessionViewState: Equatable, Sendable {
    case active(title: String)
    case saveError(title: String, errorText: String)
}

public struct ReadingSessionView: View {
    @Bindable var model: ReadingAppModel
    public let previewState: ReadingSessionViewState?
    @Environment(\.themePalette) private var palette

    public init(model: ReadingAppModel, previewState: ReadingSessionViewState? = nil) {
        self.model = model
        self.previewState = previewState
    }

    private var resolvedState: ReadingSessionViewState {
        if let previewState { return previewState }
        let book = model.store.currentBook
        let title = (book?.isTitlePending == true) ? String(localized: "widget.currentBookAsTitle") : (book?.title ?? String(localized: "widget.currentBookAsTitle"))
        if let errKey = model.store.activeErrorKey {
            return .saveError(title: title, errorText: BannerNoticeView.message(forKey: errKey))
        }
        return .active(title: title)
    }

    private var startedAtDisplayText: String {
        let tz = model.store.clock.timeZone()
        let tzID = model.store.clock.timeZoneID()
        let nowDate = model.store.clock.now()
        let startDate: Date = {
            if let iso = model.store.activeSession?.startedAt,
               let parsed = NightDateCalculator.parseISO8601(iso) {
                return parsed
            }
            return nowDate
        }()

        // reading.startedAt（「21:04 から数えています。」）。時刻はシステムの短い書式で、手で「21時4分」と組まない（決定 83）。
        // 晩をまたいだときは、同じキーの %@ に月日つきの時刻を入れる（design/ 7 に別のキーはない）。
        let startNight = NightDateCalculator.nightDate(for: startDate, timeZoneID: tzID)
        let nowNight = NightDateCalculator.nightDate(for: nowDate, timeZoneID: tzID)
        var style = startNight == nowNight
            ? Date.FormatStyle(date: .omitted, time: .shortened)
            : Date.FormatStyle.dateTime.month(.defaultDigits).day().hour().minute()
        style.timeZone = tz
        return String(format: String(localized: "reading.startedAt"), startDate.formatted(style))
    }

    public var body: some View {
        VStack(spacing: ThemeSpace.s24) {
            if case .saveError = resolvedState {
                BannerNoticeView(model: model, showCloseButton: false)
            }

            Spacer()

            VStack(spacing: ThemeSpace.s16) {
                let titleText: String = {
                    switch resolvedState {
                    case .active(let title), .saveError(let title, _):
                        return title
                    }
                }()

                Text(titleText)
                    .font(.title2.bold())
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("reading.title")
                    .accessibilityLabel(titleText)
                    .accessibilityValue(titleText)

                let startedText = startedAtDisplayText
                Text(startedText)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("reading.startedAt")
                    .accessibilityLabel(startedText)
                    .accessibilityValue(startedText)

                let noteText = String(localized: "reading.note")
                Text(noteText)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("reading.note")
                    .accessibilityLabel(noteText)

                if model.store.currentBook?.isEbook == true {
                    let ebookText = String(localized: "reading.ebookNote")
                    Text(ebookText)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("reading.ebookNote")
                        .accessibilityLabel(ebookText)
                }
            }

            Spacer()

            VStack(spacing: 0) {
                Button {
                    #if UITEST_HOOKS
                    UITestHookCoordinator.shared.syncAllDarwinTokenStates()
                    #endif
                    let res = model.store.endReadingSession(source: "app")
                    switch res {
                    case .saved:
                        model.currentScreen = .bookmarkMarkSelect
                        model.activeSheet = .markFlow
                    case .discardedTooShort, .discardedInvalidTime:
                        model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
                    case .failedSave, .ignoredDuplicate:
                        break
                    }
                    model.notifyHookChanged()
                } label: {
                    Text(String(localized: "reading.end"))
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("reading.end")
            }
            .padding(.top, ThemeSpace.s12)
        }
        .padding(.horizontal, ThemeSpace.s24)
        .padding(.vertical, ThemeSpace.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.bgPrimary.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.reading")
        .onAppear {
            model.currentScreen = .sessionActive
            model.notifyHookChanged()
        }
    }
}

#Preview("S-2 Reading Session Active") {
    let model = ReadingAppModel()
    ReadingSessionView(model: model, previewState: .active(title: "羅生門"))
}

#Preview("S-2 Reading Session Save Error") {
    let model = ReadingAppModel()
    ReadingSessionView(model: model, previewState: .saveError(title: "羅生門", errorText: "記録を保存できませんでした。もう一度お試しください。"))
}

#Preview("S-2 Reading Session AX5 Dark") {
    let model = ReadingAppModel()
    ReadingSessionView(model: model, previewState: .active(title: "吾輩は猫である"))
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}
