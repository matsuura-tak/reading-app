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
    /// 復元の進行中の印（H33：`Task` を作る前に同期で立て、本物の処理が終わったら下ろす。2度押しを弾く）。
    @State private var restoreInFlight = false

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
        .navigationTitle(String(localized: "settings.navTitle"))
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
            Text(String(localized: "settings.section.start"))
                .font(.subheadline.bold())
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ThemeSpace.s4)

            VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                if model.store.isFlipAvailable {
                    HStack {
                        Text(String(localized: "settings.flipToStart"))
                            .font(.body)
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        Toggle(String(localized: "settings.flipToStart"), isOn: Binding(
                            get: { model.store.settings.flipToStartEnabled },
                            set: { newVal in
                                model.store.setFlipToStartEnabled(newVal)
                                model.notifyHookChanged()
                            }
                        ))
                        .labelsHidden()
                        .tint(palette.actionTint)
                        .accessibilityIdentifier("settings.flipToStart")
                        .accessibilityLabel(String(localized: "settings.flipToStart"))
                    }
                    .frame(minHeight: 44)
                } else {
                    Text(String(localized: "settings.flipToStart.unavailable"))
                        .font(.footnote)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("settings.flipUnavailable")
                }

                Rectangle()
                    .fill(palette.hairline)
                    .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)

                HStack {
                    Text(String(localized: "settings.entryTime"))
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
                    .accessibilityLabel(String(localized: "settings.entryTime"))
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
                    Text(String(localized: "settings.liveActivity.off"))
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
            if model.store.settingsSaveErrorSection == "reading" {
                settingsSaveErrorText
            }
        }
    }

    /// design/ 5 の S-10：設定の保存に失敗したら、切り替えを前の値に戻し、節の下に common.save.error を出す。
    private var settingsSaveErrorText: some View {
        Text("common.save.error")
            .font(.footnote)
            .foregroundStyle(Color("SemanticError"))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, ThemeSpace.s4)
            .accessibilityIdentifier("common.save.error")
    }

    private var lockScreenSection: some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s8) {
            Text(String(localized: "settings.section.lockScreen"))
                .font(.subheadline.bold())
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ThemeSpace.s4)

            HStack {
                Text(String(localized: "settings.hideOnWidgets"))
                    .font(.body)
                    .foregroundStyle(palette.textPrimary)
                Spacer()
                Toggle(String(localized: "settings.hideOnWidgets"), isOn: Binding(
                    get: { model.store.settings.hideOnWidgets },
                    set: { newVal in
                        model.store.setHideOnWidgets(newVal)
                        model.notifyHookChanged()
                    }
                ))
                .labelsHidden()
                .tint(palette.actionTint)
                .accessibilityIdentifier("settings.hideOnWidgets")
                .accessibilityLabel(String(localized: "settings.hideOnWidgets"))
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
            if model.store.settingsSaveErrorSection == "lockScreen" {
                settingsSaveErrorText
            }
        }
    }

    private var appearanceAndPurchaseSection: some View {
        let supportedAppearances: [AppearanceID] = [.default, .kinari, .sumi, .shu]
        return VStack(alignment: .leading, spacing: ThemeSpace.s8) {
            Text(String(localized: "settings.section.appearance"))
                .font(.subheadline.bold())
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ThemeSpace.s4)

            VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                Button {
                    model.notifyHookChanged()
                } label: {
                    HStack {
                        Text(String(localized: "settings.appearance"))
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

                // 間は ProgressView の側で取る（出していない間にボタンの幅を削らない）。
                HStack(spacing: 0) {
                    Button {
                        guard !restoreInFlight else { return }
                        restoreInFlight = true
                        Task {
                            await model.store.loadGate.pass(.storekitRestore)
                            _ = model.store.restorePurchases()
                            restoreInFlight = false
                            model.notifyHookChanged()
                        }
                    } label: {
                        Text(String(localized: "settings.restorePurchases"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                    .accessibilityIdentifier("settings.restorePurchases")
                    // design/ 5 の S-10：購入の復元が 0.3秒を超えたら settings.restorePurchases の横に ProgressView を出す（H33）。
                    HeldLoadProgressView(gate: model.store.loadGate, point: .storekitRestore, progressLeadingPadding: ThemeSpace.s8) {
                        EmptyView()
                    }
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

    private var catalogSection: some View {
        let isReady = (model.store.catalogDB.status == .ready)
        let statusCopy = isReady
            ? String(format: String(localized: "catalog.status.ready"), model.store.catalogDB.metadata.version)
            : String(localized: "catalog.status.notDownloaded")
        return VStack(alignment: .leading, spacing: ThemeSpace.s8) {
            Text(String(localized: "settings.section.catalog"))
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
                        Text(String(localized: "catalog.retry"))
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
        // design/ 7 の `settings.dataSources`（%1$@ は書誌データの版。design/ 7 の文のとおり1つの引数で入れる）。
        let attributionDisplay = String(format: String(localized: "settings.dataSources"), model.store.catalogDB.metadata.version)
        return VStack(alignment: .leading, spacing: ThemeSpace.s8) {
            Text(String(localized: "settings.section.info"))
                .font(.subheadline.bold())
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, ThemeSpace.s4)

            VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                Button {
                    let urlString = (Bundle.main.object(forInfoDictionaryKey: "PrivacyPolicyURL") as? String) ?? "https://yomuma.jp/privacy"
                    model.store.openExternalURL(urlString)
                    model.notifyHookChanged()
                } label: {
                    Text(String(localized: "settings.privacyPolicy"))
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
                    .accessibilityValue(attributionDisplay)

                Button {
                    model.store.openExternalURL("https://creativecommons.org/licenses/by/4.0/deed.ja")
                    model.notifyHookChanged()
                } label: {
                    Text(String(localized: "settings.dataSources.license"))
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
        case .default: return String(localized: "appearance.default")
        case .dark: return AppL10n.pick("夜（ダーク）", "Dark")
        case .light: return AppL10n.pick("昼（ライト）", "Light")
        case .kinari: return String(localized: "appearance.kinari")
        case .sumi: return String(localized: "appearance.sumi")
        case .shu: return String(localized: "appearance.shu")
        }
    }
}

public struct StorePurchasePreviewSheetView: View {
    @Bindable var model: ReadingAppModel
    public let previewAppearanceID: AppearanceID
    @Environment(\.themePalette) private var palette
    @State private var selectedPreviewID: AppearanceID
    /// 購入の進行中の印（H33：`Task` を作る前に同期で立て、本物の処理が終わったら下ろす。2度押しを弾く）。
    @State private var purchaseInFlight = false

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
                percent: book.currentPercent.map(Double.init),
                strings: ReadingWidgetStrings.spoken
            ) ?? "p.61"
        }()
        let supportedAppearances: [AppearanceID] = [.default, .kinari, .sumi, .shu]

        return VStack(spacing: 0) {
            SheetHeaderBar(
                title: AppL10n.pick("よむま＋", "Yomuma+"),
                leftTitle: String(localized: "store.close"),
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

                        // W-1 の縮小見本：拡張と同じ ReadingLockScreenWidgetView を 172×76 pt の枠で描く（design/ 3 の S-10a）。
                        let previewSnapshot = WidgetSnapshot(
                            appearanceID: selectedPreviewID,
                            hideOnWidgets: false,
                            currentBook: WidgetSnapshotBook(
                                title: previewBookTitle,
                                line: previewLine,
                                progress: model.store.currentBook.flatMap {
                                    WidgetSnapshotProgress.make(unit: $0.progressUnit, page: $0.currentPage, location: $0.currentLocation, percent: $0.currentPercent)
                                } ?? (model.store.currentBook == nil ? WidgetSnapshotProgress(unit: .page, value: 61) : nil)
                            )
                        )
                        ReadingLockScreenWidgetView(
                            family: .accessoryRectangular,
                            snapshot: previewSnapshot,
                            size: CGSize(width: 172, height: 76),
                            contentMargins: ReadingWidgetMetrics.lockScreenContentMargins
                        )
                        .foregroundStyle(previewPalette.textPrimary)
                        .frame(width: 172, height: 76)
                        .padding(ThemeSpace.s8)
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
                        Text(String(localized: "store.product.title"))
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("store.product.title")

                        Text(String(localized: "store.product.description"))
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
                    // H33 storekit.products：商品の情報を取るまで、ボタンの位置に ProgressView（design 5 の S-10a）。
                    GatedLoadView(gate: model.store.loadGate, point: .storekitProducts) {
                        // H33 storekit.purchase：購入の処理が 0.3秒を超えたら、ボタンの位置に ProgressView。
                        HeldLoadProgressView(gate: model.store.loadGate, point: .storekitPurchase, progressMinHeight: 44) {
                            Button {
                                guard !purchaseInFlight else { return }
                                purchaseInFlight = true
                                Task {
                                    await model.store.loadGate.pass(.storekitPurchase)
                                    let res = model.store.purchasePlus()
                                    purchaseInFlight = false
                                    if res == .success {
                                        model.currentScreen = .settingsMain
                                    }
                                    model.notifyHookChanged()
                                }
                            } label: {
                                Text(String(localized: "store.buy"))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                            .accessibilityIdentifier("store.buy")
                        }
                    } placeholder: {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }

                Button {
                    let res = model.store.restorePurchases()
                    if res == .restored {
                        model.currentScreen = .settingsMain
                    }
                    model.notifyHookChanged()
                } label: {
                    Text(String(localized: "store.restore"))
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
