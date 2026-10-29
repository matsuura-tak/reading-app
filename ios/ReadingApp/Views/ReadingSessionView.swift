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
        let title = (book?.isTitlePending == true) ? AppL10n.pick("今の本", "Reading Now") : (book?.title ?? AppL10n.pick("今の本", "Reading Now"))
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

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let comps = cal.dateComponents([.month, .day, .hour, .minute], from: startDate)
        let hhmm = String(format: "%02d:%02d", comps.hour ?? 21, comps.minute ?? 0)

        let startNight = NightDateCalculator.nightDate(for: startDate, timeZoneID: tzID)
        let nowNight = NightDateCalculator.nightDate(for: nowDate, timeZoneID: tzID)

        if startNight != nowNight, let m = comps.month, let d = comps.day {
            return AppL10n.pick(
                "\(m)月\(d)日 \(hhmm) から数えています。",
                "Counting since \(m)/\(d) \(hhmm)."
            )
        }
        return AppL10n.pick(
            "\(hhmm) から数えています。",
            "Counting since \(hhmm)."
        )
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

                let noteText = AppL10n.pick(
                    "伏せても、ロックしても、ほかのアプリを使っても数え続けます。",
                    "Keeps counting when face down, locked, or in another app."
                )
                Text(noteText)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("reading.note")
                    .accessibilityLabel(noteText)

                if model.store.currentBook?.isEbook == true {
                    let ebookText = AppL10n.pick(
                        "このまま電子書籍アプリへ移って読めます。終えるときはロック画面の『終える』を押してください。",
                        "Switch to your e-book app to read. Tap End Reading on the Lock Screen when done."
                    )
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
                    Text(AppL10n.pick("終える", "End Reading"))
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
