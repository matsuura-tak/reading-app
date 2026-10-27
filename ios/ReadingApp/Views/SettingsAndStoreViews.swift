import SwiftUI
import ReadingCore
import ReadingStore

public enum SettingsViewState: Equatable, Sendable {
    case standard(settings: SettingsSnapshot, isFlipAvailable: Bool, areActivitiesEnabled: Bool)
}

public struct SettingsView: View {
    @Bindable var model: ReadingAppModel
    @State private var showEntryTimePicker = false
    @State private var entryTimeInput: String = ""

    public init(model: ReadingAppModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BannerNoticeView(model: model)

                readingSettingsSection
                liveActivitySection
                appearanceSection
                storeStatusAndRestoreSection
                aboutAndLicensesSection
            }
            .padding(20)
        }
        .accessibilityIdentifier("screen.settings")
        .navigationTitle("設定")
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

    private var readingSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("読書とプライバシー")
                .font(.headline)

            if model.store.isFlipAvailable {
                HStack {
                    Text("伏せて読み始める")
                        .font(.body)
                    Spacer()
                    Toggle("伏せて読み始める", isOn: Binding(
                        get: { model.store.settings.flipToStartEnabled },
                        set: { newVal in
                            model.store.setFlipToStartEnabled(newVal)
                            model.notifyHookChanged()
                        }
                    ))
                    .labelsHidden()
                    .accessibilityIdentifier("settings.flipToStart")
                }
            } else {
                Text("この端末では伏せて開始を利用できません")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("settings.flipUnavailable")
            }

            HStack {
                Text("ロック画面で書名を隠す")
                    .font(.body)
                Spacer()
                Toggle("ロック画面で書名を隠す", isOn: Binding(
                    get: { model.store.settings.hideOnWidgets },
                    set: { newVal in
                        model.store.setHideOnWidgets(newVal)
                        model.notifyHookChanged()
                    }
                ))
                .labelsHidden()
                .accessibilityIdentifier("settings.hideOnWidgets")
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var liveActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("夜の入口（ライブアクティビティ）")
                .font(.headline)

            if !model.store.areActivitiesEnabled {
                Text("ライブアクティビティがオフになっています")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("settings.liveActivity.off")
            }

            HStack {
                Text("夜の入口の時刻")
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    entryTimeInput = model.store.settings.entryTime
                    showEntryTimePicker.toggle()
                    model.notifyHookChanged()
                } label: {
                    Text(model.store.settings.entryTime)
                        .font(.body.monospacedDigit())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("settings.entryTime")
                .accessibilityValue(model.store.settings.entryTime)
            }

            if showEntryTimePicker {
                let presets = (72..<96).map { idx -> String in
                    let h = idx / 4
                    let m = (idx % 4) * 15
                    return String(format: "%02d:%02d", h, m)
                }
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<6, id: \.self) { col in
                                let preset = presets[row * 6 + col]
                                Button(preset) {
                                    model.store.setEntryTime(preset)
                                    entryTimeInput = preset
                                    showEntryTimePicker = false
                                    model.notifyHookChanged()
                                }
                                .buttonStyle(.bordered)
                                .font(.caption2.monospacedDigit())
                                .accessibilityIdentifier("settings.entryTime.\(preset)")
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("しおりの佇まい")
                .font(.headline)

            ForEach(AppearanceID.allCases, id: \.self) { appID in
                let isSelected = (model.store.settings.appearanceID == appID)
                let isLocked = (appID.isPlusTheme && !model.store.settings.isPlusPurchased)
                Button {
                    model.store.selectAppearance(appID)
                    if model.store.previewAppearanceID != nil {
                        model.currentScreen = .storePurchasePreview
                    }
                    model.notifyHookChanged()
                } label: {
                    HStack {
                        Text(Self.appearanceDisplayName(appID))
                            .font(.body.weight(isSelected ? .semibold : .regular))
                            .foregroundStyle(.primary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        } else if isLocked {
                            Text("よむま プラス")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(
                        isSelected ? Color.accentColor.opacity(0.12) : Color(uiColor: .tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.appearance.\(appID.rawValue)")
                .accessibilityLabel(Self.appearanceDisplayName(appID))
                .accessibilityValue(isSelected ? "selected" : (isLocked ? "locked" : "unlocked"))
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var storeStatusAndRestoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.store.settings.isPlusPurchased {
                Text("購入済み")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("store.purchasedBadge")
            }

            Button {
                _ = model.store.restorePurchases()
                model.notifyHookChanged()
            } label: {
                Text("購入を復元")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("settings.restorePurchases")

            if let msgKey = model.store.storeStatusMessageKey {
                let msgText = BannerNoticeView.message(forKey: msgKey)
                Text(msgText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier(msgKey)
                    .accessibilityLabel(msgText)
                    .accessibilityValue(msgText)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var aboutAndLicensesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("書誌データ・謝辞")
                .font(.headline)
            Text("国立国会図書館サーチの書誌データ（CC BY 4.0）を加工して内蔵しています。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("settings.ndlAttribution")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    public static func appearanceDisplayName(_ id: AppearanceID) -> String {
        switch id {
        case .default: return "端末に合わせる"
        case .dark: return "夜（ダーク）"
        case .light: return "昼（ライト）"
        case .kinari: return "生成り"
        case .sumi: return "墨"
        case .shu: return "朱"
        }
    }
}

public struct StorePurchasePreviewSheetView: View {
    @Bindable var model: ReadingAppModel
    public let previewAppearanceID: AppearanceID

    public init(model: ReadingAppModel, previewAppearanceID: AppearanceID) {
        self.model = model
        self.previewAppearanceID = previewAppearanceID
    }

    public var body: some View {
        let canBuy = model.store.storeCanMakePayments && model.store.storeProductLoadAvailable
        let name = SettingsView.appearanceDisplayName(previewAppearanceID)

        return NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text(name)
                        .font(.title3.bold())
                    Text("ある日の暮方の事である。")
                        .font(.system(.body, design: .serif))
                        .padding(.vertical, 16)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("store.preview.card")

                Text("よむま プラス（買い切り・¥600）")
                    .font(.headline)
                    .accessibilityIdentifier("store.product.title")

                if let msgKey = model.store.storeStatusMessageKey {
                    let msgText = BannerNoticeView.message(forKey: msgKey)
                    Text(msgText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier(msgKey)
                        .accessibilityLabel(msgText)
                        .accessibilityValue(msgText)
                }

                Spacer()

                Button {
                    let res = model.store.purchasePlus()
                    if res == .success {
                        model.currentScreen = .settingsMain
                    }
                    model.notifyHookChanged()
                } label: {
                    Text("購入する（¥600）")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canBuy)
                .accessibilityIdentifier("store.purchase")

                Button {
                    let res = model.store.restorePurchases()
                    if res == .restored {
                        model.currentScreen = .settingsMain
                    }
                    model.notifyHookChanged()
                } label: {
                    Text("購入を復元")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("store.restore")

                Button {
                    model.store.closeStorePreview()
                    model.currentScreen = .settingsMain
                    model.notifyHookChanged()
                } label: {
                    Text("いまはしない")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("store.preview.close")
            }
            .padding(24)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("sheet.storePreview")
            .navigationTitle("しおりの佇まいを試す")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                model.currentScreen = .storePurchasePreview
                model.notifyHookChanged()
            }
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
