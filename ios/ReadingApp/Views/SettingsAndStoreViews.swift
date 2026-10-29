import SwiftUI
import ReadingCore
import ReadingStore

public enum SettingsViewState: Equatable, Sendable {
    case standard(settings: SettingsSnapshot, isFlipAvailable: Bool, areActivitiesEnabled: Bool)
}

public struct SettingsView: View {
    @Bindable var model: ReadingAppModel
    @Environment(\.themePalette) private var palette
    @State private var showEntryTimePicker = false
    @State private var entryTimeInput: String = ""

    public init(model: ReadingAppModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ThemeSpace.s24) {
                BannerNoticeView(model: model)

                readingAndEntrySection
                lockScreenSection
                appearanceAndPurchaseSection
                catalogSection
                aboutAndLicensesSection
            }
            .padding(.horizontal, ThemeSpace.s16)
            .padding(.vertical, ThemeSpace.s16)
        }
        .background(palette.bgGrouped.ignoresSafeArea())
        .accessibilityIdentifier("screen.settings")
        .navigationTitle(AppL10n.pick("設定", "Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { model.store.previewAppearanceID != nil },
            set: { isPresented in
                if !isPresented {
                    model.store.closeStorePreview()
                    model.currentScreen = .settingsMain
                    model.notifyHookChanged()
                }
            }
        )) {
            if let previewID = model.store.previewAppearanceID {
                StorePurchasePreviewSheetView(model: model, previewAppearanceID: previewID)
            }
        }
        .onAppear {
            model.activeTab = .settings
            model.currentScreen = .settingsMain
            entryTimeInput = model.store.settings.entryTime
            model.notifyHookChanged()
        }
    }

    private var readingAndEntrySection: some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s8) {
            Text(AppL10n.pick("読み始めと夜の入口", "Reading Start & Evening Entry"))
                .font(.subheadline.bold())
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ThemeSpace.s4)

            VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                if model.store.isFlipAvailable {
                    HStack {
                        Text(AppL10n.pick("伏せて読み始める", "Flip Face-Down to Start"))
                            .font(.body)
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        Toggle(AppL10n.pick("伏せて読み始める", "Flip Face-Down to Start"), isOn: Binding(
                            get: { model.store.settings.flipToStartEnabled },
                            set: { newVal in
                                model.store.setFlipToStartEnabled(newVal)
                                model.notifyHookChanged()
                            }
                        ))
                        .labelsHidden()
                        .tint(palette.actionTint)
                        .accessibilityIdentifier("settings.flipToStart")
                        .accessibilityLabel(AppL10n.pick("伏せて読み始める", "Flip Face-Down to Start"))
                    }
                    .frame(minHeight: 44)
                } else {
                    Text(AppL10n.pick("この端末では伏せて読み始めるを使えません。", "Flip Face-Down to Start is not available on this device."))
                        .font(.footnote)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("settings.flipUnavailable")
                }

                Rectangle()
                    .fill(palette.hairline)
                    .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)

                HStack {
                    Text(AppL10n.pick("夜の入口の時刻", "Evening Entry Time"))
                        .font(.body)
                        .foregroundStyle(palette.textPrimary)
                    Spacer()
                    Button {
                        entryTimeInput = model.store.settings.entryTime
                        showEntryTimePicker.toggle()
                        model.notifyHookChanged()
                    } label: {
                        Text(model.store.settings.entryTime)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(palette.actionTint)
                            .padding(.horizontal, ThemeSpace.s12)
                            .padding(.vertical, ThemeSpace.s8)
                            .frame(minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: ThemeRadius.control)
                                    .fill(palette.bgPrimary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: ThemeRadius.control)
                                    .strokeBorder(palette.hairline, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.entryTime")
                    .accessibilityLabel(AppL10n.pick("夜の入口の時刻", "Evening Entry Time"))
                    .accessibilityValue(model.store.settings.entryTime)
                }

                if showEntryTimePicker {
                    let presets = (72..<96).map { idx -> String in
                        let h = idx / 4
                        let m = (idx % 4) * 15
                        return String(format: "%02d:%02d", h, m)
                    }
                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        ForEach(0..<6, id: \.self) { row in
                            HStack(spacing: ThemeSpace.s8) {
                                ForEach(0..<4, id: \.self) { col in
                                    let preset = presets[row * 4 + col]
                                    let isChosen = (model.store.settings.entryTime == preset)
                                    Button {
                                        model.store.setEntryTime(preset)
                                        entryTimeInput = preset
                                        showEntryTimePicker = false
                                        model.notifyHookChanged()
                                    } label: {
                                        Text(preset)
                                            .font(.footnote.monospacedDigit())
                                            .foregroundStyle(isChosen ? palette.actionPrimaryLabel : palette.textPrimary)
                                            .frame(maxWidth: .infinity, minHeight: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: ThemeRadius.control)
                                                    .fill(isChosen ? palette.actionPrimaryBg : palette.bgPrimary)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: ThemeRadius.control)
                                                    .strokeBorder(palette.hairline, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("settings.entryTime.\(preset)")
                                }
                            }
                        }
                    }
                }

                if !model.store.areActivitiesEnabled {
                    Text(AppL10n.pick(
                        "端末の設定でライブアクティビティがオフになっています。設定アプリでオンにできます。",
                        "Live Activities are turned off in system settings. You can enable them in the Settings app."
                    ))
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("settings.liveActivity.off")
                }
            }
            .padding(ThemeSpace.s16)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .fill(palette.groupedRow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .strokeBorder(palette.hairline, lineWidth: 1)
            )
        }
    }

    private var lockScreenSection: some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s8) {
            Text(AppL10n.pick("ロック画面", "Lock Screen"))
                .font(.subheadline.bold())
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ThemeSpace.s4)

            HStack {
                Text(AppL10n.pick("ロック画面で書名と一行を隠す", "Hide Title & Line on Lock Screen"))
                    .font(.body)
                    .foregroundStyle(palette.textPrimary)
                Spacer()
                Toggle(AppL10n.pick("ロック画面で書名と一行を隠す", "Hide Title & Line on Lock Screen"), isOn: Binding(
                    get: { model.store.settings.hideOnWidgets },
                    set: { newVal in
                        model.store.setHideOnWidgets(newVal)
                        model.notifyHookChanged()
                    }
                ))
                .labelsHidden()
                .tint(palette.actionTint)
                .accessibilityIdentifier("settings.hideOnWidgets")
                .accessibilityLabel(AppL10n.pick("ロック画面で書名と一行を隠す", "Hide Title & Line on Lock Screen"))
            }
            .frame(minHeight: 44)
            .padding(ThemeSpace.s16)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .fill(palette.groupedRow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .strokeBorder(palette.hairline, lineWidth: 1)
            )
        }
    }

    private var appearanceAndPurchaseSection: some View {
        let supportedAppearances: [AppearanceID] = [.default, .kinari, .sumi, .shu]
        return VStack(alignment: .leading, spacing: ThemeSpace.s8) {
            Text(AppL10n.pick("見た目と購入", "Appearance & Purchase"))
                .font(.subheadline.bold())
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ThemeSpace.s4)

            VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                Button {
                    model.notifyHookChanged()
                } label: {
                    HStack {
                        Text(AppL10n.pick("見た目（しおりの佇まい）", "Appearance (Bookmark Theme)"))
                            .font(.body)
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        Text(Self.appearanceDisplayName(model.store.settings.appearanceID))
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.appearance")

                VStack(spacing: ThemeSpace.s8) {
                    ForEach(supportedAppearances, id: \.rawValue) { appID in
                        let isSelected = (model.store.settings.appearanceID == appID)
                        let isLocked = (appID.isPlusTheme && !model.store.settings.isPlusPurchased)
                        Button {
                            model.store.selectAppearance(appID)
                            if model.store.previewAppearanceID != nil {
                                model.currentScreen = .storePurchasePreview
                            }
                            model.notifyHookChanged()
                        } label: {
                            HStack(spacing: ThemeSpace.s8) {
                                Text(Self.appearanceDisplayName(appID))
                                    .font(.body.weight(isSelected ? .semibold : .regular))
                                    .foregroundStyle(palette.textPrimary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(palette.actionTint)
                                } else if isLocked {
                                    Image(systemName: "lock")
                                        .font(.subheadline)
                                        .foregroundStyle(palette.textSecondary)
                                }
                            }
                            .padding(.horizontal, ThemeSpace.s12)
                            .padding(.vertical, ThemeSpace.s8)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: ThemeRadius.control)
                                    .fill(palette.bgPrimary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: ThemeRadius.control)
                                    .strokeBorder(isSelected ? palette.actionTint : palette.hairline, lineWidth: isSelected ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("appearance.row.\(appID.rawValue)")
                        .accessibilityLabel(Self.appearanceDisplayName(appID))
                        .accessibilityValue(isSelected ? "selected" : (isLocked ? "locked" : "unlocked"))
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }

                if model.store.settings.isPlusPurchased {
                    Text(AppL10n.pick("よむま＋ 購入済み", "Yomuma+ Purchased"))
                        .font(.footnote.bold())
                        .foregroundStyle(palette.textSecondary)
                        .accessibilityIdentifier("store.purchasedBadge")
                }

                if let msgKey = model.store.storeStatusMessageKey, model.store.previewAppearanceID == nil {
                    let msgText = BannerNoticeView.message(forKey: msgKey)
                    Text(msgText)
                        .font(.footnote)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier(msgKey)
                        .accessibilityLabel(msgText)
                        .accessibilityValue(msgText)
                }

                Button {
                    _ = model.store.restorePurchases()
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("購入を復元", "Restore Purchases"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("settings.restorePurchases")
            }
            .padding(ThemeSpace.s16)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .fill(palette.groupedRow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .strokeBorder(palette.hairline, lineWidth: 1)
            )
        }
    }

    private var catalogSection: some View {
        let isReady = (model.store.catalogDB.status == .ready)
        let statusCopy = isReady
            ? AppL10n.pick("書誌データ（国立国会図書館サーチ・文学・端末内）：利用できます", "Catalog Data (NDL Search, Literature, On-Device): Ready")
            : AppL10n.pick("書誌データ：準備できていません（手入力・表紙撮影はいつでも使えます）", "Catalog Data: Not Ready (Manual entry and cover scan are always available)")
        return VStack(alignment: .leading, spacing: ThemeSpace.s8) {
            Text(AppL10n.pick("書誌データ", "Catalog Database"))
                .font(.subheadline.bold())
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ThemeSpace.s4)

            VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                Text(statusCopy)
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("catalog.status")

                if !isReady {
                    Button {
                        model.notifyHookChanged()
                    } label: {
                        Text(AppL10n.pick("書誌データの取得をやり直す", "Retry Catalog Download"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                    .accessibilityIdentifier("catalog.retry")
                }
            }
            .padding(ThemeSpace.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .fill(palette.groupedRow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .strokeBorder(palette.hairline, lineWidth: 1)
            )
        }
    }

    private var aboutAndLicensesSection: some View {
        let attributionJa = "書誌データは国立国会図書館サーチの書誌データ（CC BY 4.0）を加工して作成しています。オンラインAPIには接続せず、国立国会図書館とは無関係です。"
        let attributionDisplay = AppL10n.pick(
            attributionJa,
            "Bibliographic data is adapted from National Diet Library Search (CC BY 4.0). Does not connect to online APIs and is not affiliated with NDL."
        )
        return VStack(alignment: .leading, spacing: ThemeSpace.s8) {
            Text(AppL10n.pick("情報", "About"))
                .font(.subheadline.bold())
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ThemeSpace.s4)

            VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                Button {
                    let urlString = (Bundle.main.object(forInfoDictionaryKey: "PrivacyPolicyURL") as? String) ?? "https://yomuma.jp/privacy"
                    model.store.openExternalURL(urlString)
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("プライバシーポリシー", "Privacy Policy"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("settings.privacyPolicy")

                Text(attributionDisplay)
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("settings.dataSources")
                    .accessibilityLabel(attributionDisplay)
                    .accessibilityValue(attributionJa)

                Button {
                    model.store.openExternalURL("https://creativecommons.org/licenses/by/4.0/deed.ja")
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("CC BY 4.0 ライセンスを見る", "View CC BY 4.0 License"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("settings.dataSources.license")
            }
            .padding(ThemeSpace.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .fill(palette.groupedRow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .strokeBorder(palette.hairline, lineWidth: 1)
            )
        }
    }

    public static func appearanceDisplayName(_ id: AppearanceID) -> String {
        switch id {
        case .default: return AppL10n.pick("標準（夜と紙）", "Default (Night & Paper)")
        case .dark: return AppL10n.pick("夜（ダーク）", "Dark")
        case .light: return AppL10n.pick("昼（ライト）", "Light")
        case .kinari: return AppL10n.pick("生成り", "Kinari (Warm Paper)")
        case .sumi: return AppL10n.pick("墨", "Sumi (Ink)")
        case .shu: return AppL10n.pick("朱", "Shu (Vermilion)")
        }
    }
}

public struct StorePurchasePreviewSheetView: View {
    @Bindable var model: ReadingAppModel
    public let previewAppearanceID: AppearanceID
    @Environment(\.themePalette) private var palette
    @State private var selectedPreviewID: AppearanceID

    public init(model: ReadingAppModel, previewAppearanceID: AppearanceID) {
        self.model = model
        self.previewAppearanceID = previewAppearanceID
        _selectedPreviewID = State(initialValue: previewAppearanceID)
    }

    public var body: some View {
        let canBuy = model.store.storeCanMakePayments && model.store.storeProductLoadAvailable && !model.store.isOffline
        let previewPalette = ThemePalette.palette(for: selectedPreviewID)
        let previewBookTitle = model.store.currentBook?.title ?? AppL10n.pick("羅生門", "Rashomon")
        let previewBookAuthor = model.store.currentBook?.author ?? AppL10n.pick("芥川龍之介", "Ryunosuke Akutagawa")
        let previewLine = model.store.currentBook?.lastSavedLine ?? AppL10n.pick("ある日の暮方の事である。", "It happened one evening.")
        let previewPage: String = {
            guard let book = model.store.currentBook else { return "p.61" }
            return InputValidator.formatProgressDisplay(
                unit: book.progressUnit,
                page: book.currentPage,
                location: book.currentLocation,
                percent: book.currentPercent.map(Double.init)
            ) ?? "p.61"
        }()
        let supportedAppearances: [AppearanceID] = [.default, .kinari, .sumi, .shu]

        return VStack(spacing: 0) {
            SheetHeaderBar(
                title: AppL10n.pick("よむま＋", "Yomuma+"),
                leftTitle: AppL10n.pick("閉じる", "Close"),
                leftId: "store.close",
                onLeft: {
                    model.store.closeStorePreview()
                    model.currentScreen = .settingsMain
                    model.notifyHookChanged()
                }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s24) {
                    // S-1 & W-1 live theme preview card
                    VStack(spacing: ThemeSpace.s16) {
                        Text(SettingsView.appearanceDisplayName(selectedPreviewID))
                            .font(.subheadline.bold())
                            .foregroundStyle(previewPalette.textSecondary)

                        Text(previewLine)
                            .font(ThemeTypography.bookmarkLine(size: 22))
                            .foregroundStyle(previewPalette.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, ThemeSpace.s8)

                        HStack(spacing: ThemeSpace.s8) {
                            Text(previewBookTitle)
                                .font(.footnote.bold())
                                .foregroundStyle(previewPalette.textPrimary)
                            if !previewBookAuthor.isEmpty {
                                Text(previewBookAuthor)
                                    .font(.footnote)
                                    .foregroundStyle(previewPalette.textSecondary)
                            }
                            Text(previewPage)
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(previewPalette.textSecondary)
                        }

                        // W-1 Lock screen widget miniature preview (172x76)
                        VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                            Text(previewLine)
                                .font(ThemeTypography.widgetLine(size: 13))
                                .foregroundStyle(previewPalette.textPrimary)
                                .lineLimit(2)
                            HStack(spacing: ThemeSpace.s8) {
                                Text(previewPage)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(previewPalette.textSecondary)
                                Text(previewBookTitle)
                                    .font(.caption2)
                                    .foregroundStyle(previewPalette.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(ThemeSpace.s8)
                        .frame(minWidth: 172, maxWidth: 172, minHeight: 76, maxHeight: 76, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeRadius.control)
                                .fill(previewPalette.groupedRow)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ThemeRadius.control)
                                .strokeBorder(previewPalette.hairline, lineWidth: 1)
                        )
                    }
                    .padding(ThemeSpace.s24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: ThemeRadius.card)
                            .fill(previewPalette.bgPrimary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ThemeRadius.card)
                            .strokeBorder(previewPalette.hairline, lineWidth: 1)
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier("store.preview")
                    .accessibilityLabel(selectedPreviewID.rawValue)
                    .accessibilityValue(selectedPreviewID.rawValue)

                    // 4 appearance preview switcher buttons
                    HStack(spacing: ThemeSpace.s8) {
                        ForEach(supportedAppearances, id: \.rawValue) { appID in
                            let isChosen = (selectedPreviewID == appID)
                            Button {
                                selectedPreviewID = appID
                                model.store.previewAppearanceID = appID
                                model.notifyHookChanged()
                            } label: {
                                Text(SettingsView.appearanceDisplayName(appID))
                                    .font(.footnote.weight(isChosen ? .semibold : .regular))
                                    .foregroundStyle(isChosen ? palette.actionPrimaryLabel : palette.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .padding(.horizontal, ThemeSpace.s4)
                                    .background(
                                        RoundedRectangle(cornerRadius: ThemeRadius.control)
                                            .fill(isChosen ? palette.actionPrimaryBg : palette.groupedRow)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ThemeRadius.control)
                                            .strokeBorder(palette.hairline, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(AppL10n.pick("よむま＋（買い切り ¥980）", "Yomuma+ (One-time ¥980)"))
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("store.product.title")

                        Text(AppL10n.pick(
                            "しおりの紙色（生成り・墨・朱）を選べるようになります。記録・しおり・ウィジェット・次の1冊はすべて無料のまま使えます。",
                            "Unlock bookmark paper themes (Kinari, Sumi, Shu). All reading records, bookmarks, widgets, and recommendations remain completely free."
                        ))
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    if let msgKey = model.store.storeStatusMessageKey {
                        let msgText = BannerNoticeView.message(forKey: msgKey)
                        Text(msgText)
                            .font(.footnote)
                            .foregroundStyle(palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier(msgKey)
                            .accessibilityLabel(msgText)
                            .accessibilityValue(msgText)
                    }
                }
                .padding(.horizontal, ThemeSpace.s24)
                .padding(.vertical, ThemeSpace.s16)
            }

            VStack(spacing: ThemeSpace.s8) {
                if canBuy {
                    Button {
                        let res = model.store.purchasePlus()
                        if res == .success {
                            model.currentScreen = .settingsMain
                        }
                        model.notifyHookChanged()
                    } label: {
                        Text(AppL10n.pick("よむま＋を購入（¥980）", "Buy Yomuma+ (¥980)"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                    .accessibilityIdentifier("store.buy")
                }

                Button {
                    let res = model.store.restorePurchases()
                    if res == .restored {
                        model.currentScreen = .settingsMain
                    }
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("購入を復元", "Restore Purchases"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("store.restore")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.vertical, ThemeSpace.s12)
            .background(palette.bgPrimary)
        }
        .background(palette.bgPrimary.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.storePreview")
        .onChange(of: previewAppearanceID) { _, newValue in
            selectedPreviewID = newValue
        }
        .onAppear {
            model.currentScreen = .storePurchasePreview
            model.notifyHookChanged()
        }
    }
}

#Preview("S-10 Settings Standard") {
    let model = ReadingAppModel()
    NavigationStack {
        SettingsView(model: model)
    }
}

#Preview("S-10a Store Preview AX5 Dark") {
    let model = ReadingAppModel()
    StorePurchasePreviewSheetView(model: model, previewAppearanceID: .kinari)
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}
