import SwiftUI
import UIKit
import ReadingCore

public enum ReadingSharedContainer {
    public static let appGroupIdentifier = "group.com.takumamatsuura.readingapp"

    public nonisolated static func containerDirectoryURL() -> URL {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return groupURL
        }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }

    public nonisolated static func widgetSnapshotFileURL() -> URL {
        containerDirectoryURL()
            .appendingPathComponent("Shared", isDirectory: true)
            .appendingPathComponent("widget-snapshot.json", isDirectory: false)
    }

    public nonisolated static func loadWidgetSnapshot() -> WidgetSnapshot {
        let url = widgetSnapshotFileURL()
        if let data = try? Data(contentsOf: url) {
            return WidgetSnapshot.decodeForWidgetRenderer(from: data)
        }
        return WidgetSnapshot(
            version: 1,
            updatedAt: "1970-01-01T00:00:00Z",
            appearanceID: .default,
            hideOnWidgets: false,
            currentBook: nil
        )
    }
}

public enum AppL10n {
    public static var isEnglish: Bool {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-AppleLanguages"), idx + 1 < args.count {
            let val = args[idx + 1].lowercased()
            if val.contains("en") { return true }
            if val.contains("ja") { return false }
        }
        if let first = Locale.preferredLanguages.first?.lowercased() {
            return first.hasPrefix("en")
        }
        return false
    }

    public static func pick(_ ja: String, _ en: String) -> String {
        isEnglish ? en : ja
    }
}

public enum ThemeSpace {
    public static let s4: CGFloat = 4
    public static let s8: CGFloat = 8
    public static let s12: CGFloat = 12
    public static let s16: CGFloat = 16
    public static let s24: CGFloat = 24
    public static let s32: CGFloat = 32
}

public enum ThemeRadius {
    public static let ocrBox: CGFloat = 4
    public static let control: CGFloat = 12
    public static let card: CGFloat = 16
}

public enum ThemeTypography {
    public static func bookmarkLine(size: CGFloat = 28) -> Font {
        .custom("HiraMinProN-W3", size: size, relativeTo: .title)
    }

    public static func widgetLine(size: CGFloat) -> Font {
        .custom("HiraMinProN-W6", size: size, relativeTo: .body)
    }

    public static func finishCardTitle(size: CGFloat = 28) -> Font {
        .custom("HiraMinProN-W6", size: size, relativeTo: .title)
    }
}

public struct ThemePalette: Sendable {
    public let appearanceID: AppearanceID
    public let bgPrimary: Color
    public let bgSecondary: Color
    public let groupedRow: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let actionPrimaryBg: Color
    public let actionPrimaryLabel: Color
    public let actionTint: Color
    public let accent: Color
    public let hairline: Color
    public let stateError: Color
    public let destructive: Color
    public let ocrBoxOuter: Color
    public let ocrBoxInner: Color
    public let ocrBadgeBg: Color
    public let ocrBadgeLabel: Color

    public init(appearanceID: AppearanceID = .default) {
        self = Self.palette(for: appearanceID)
    }

    public init(
        appearanceID: AppearanceID,
        bgPrimary: Color,
        bgSecondary: Color,
        groupedRow: Color,
        textPrimary: Color,
        textSecondary: Color,
        actionPrimaryBg: Color,
        actionPrimaryLabel: Color,
        actionTint: Color,
        accent: Color,
        hairline: Color,
        stateError: Color,
        destructive: Color,
        ocrBoxOuter: Color,
        ocrBoxInner: Color,
        ocrBadgeBg: Color,
        ocrBadgeLabel: Color
    ) {
        self.appearanceID = appearanceID
        self.bgPrimary = bgPrimary
        self.bgSecondary = bgSecondary
        self.groupedRow = groupedRow
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.actionPrimaryBg = actionPrimaryBg
        self.actionPrimaryLabel = actionPrimaryLabel
        self.actionTint = actionTint
        self.accent = accent
        self.hairline = hairline
        self.stateError = stateError
        self.destructive = destructive
        self.ocrBoxOuter = ocrBoxOuter
        self.ocrBoxInner = ocrBoxInner
        self.ocrBadgeBg = ocrBadgeBg
        self.ocrBadgeLabel = ocrBadgeLabel
    }

    public static func palette(for id: AppearanceID) -> ThemePalette {
        let prefix: String
        switch id {
        case .default, .dark, .light:
            prefix = "Default"
        case .kinari:
            prefix = "Kinari"
        case .sumi:
            prefix = "Sumi"
        case .shu:
            prefix = "Shu"
        }

        let accentColor = Color("\(prefix)AccentPrimary")
        return ThemePalette(
            appearanceID: id,
            bgPrimary: Color("\(prefix)BackgroundPrimary"),
            bgSecondary: Color("\(prefix)BackgroundSecondary"),
            groupedRow: Color("\(prefix)GroupedRow"),
            textPrimary: Color("\(prefix)LabelPrimary"),
            textSecondary: Color("\(prefix)LabelSecondary"),
            actionPrimaryBg: accentColor,
            actionPrimaryLabel: Color("\(prefix)ActionPrimaryLabel"),
            actionTint: accentColor,
            accent: accentColor,
            hairline: Color("\(prefix)Separator"),
            stateError: Color("SemanticError"),
            destructive: Color("SemanticError"),
            ocrBoxOuter: Color("OCRBoxOuter"),
            ocrBoxInner: Color("OCRBoxInner"),
            ocrBadgeBg: Color("DefaultAccentPrimary"),
            ocrBadgeLabel: Color("DefaultActionPrimaryLabel")
        )
    }

    public var preferredColorScheme: ColorScheme? {
        switch appearanceID {
        case .dark:
            return .dark
        case .light:
            return .light
        case .default, .kinari, .sumi, .shu:
            return nil
        }
    }

    public var separator: Color {
        hairline
    }

    public var bgGrouped: Color {
        bgSecondary
    }
}

private struct ThemePaletteKey: EnvironmentKey {
    static let defaultValue: ThemePalette = .palette(for: .default)
}

public extension EnvironmentValues {
    var themePalette: ThemePalette {
        get { self[ThemePaletteKey.self] }
        set { self[ThemePaletteKey.self] = newValue }
    }
}

public struct ThemePrimaryButtonStyle: ButtonStyle {
    public let palette: ThemePalette
    @Environment(\.isEnabled) private var isEnabled

    public init(palette: ThemePalette) {
        self.palette = palette
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? palette.actionPrimaryLabel : palette.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, ThemeSpace.s16)
            .padding(.vertical, ThemeSpace.s12)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                    .fill(isEnabled ? palette.actionPrimaryBg : palette.groupedRow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                    .stroke(isEnabled ? Color.clear : palette.hairline, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .contentShape(Rectangle())
    }
}

public struct ThemeSecondaryButtonStyle: ButtonStyle {
    public let palette: ThemePalette
    public let fullWidth: Bool
    public let isDestructive: Bool
    @Environment(\.isEnabled) private var isEnabled

    public init(palette: ThemePalette, fullWidth: Bool = true, isDestructive: Bool = false) {
        self.palette = palette
        self.fullWidth = fullWidth
        self.isDestructive = isDestructive
    }

    public func makeBody(configuration: Configuration) -> some View {
        let fgColor: Color = {
            if !isEnabled { return palette.textSecondary }
            if isDestructive { return palette.textPrimary }
            return palette.actionTint
        }()

        return configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(fgColor)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, ThemeSpace.s16)
            .padding(.vertical, ThemeSpace.s12)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                    .fill(palette.groupedRow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                    .stroke(palette.hairline, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .contentShape(Rectangle())
    }
}

public struct ThemeFieldModifier: ViewModifier {
    public let palette: ThemePalette

    public func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundStyle(palette.textPrimary)
            .padding(.horizontal, ThemeSpace.s12)
            .padding(.vertical, ThemeSpace.s12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                    .fill(palette.groupedRow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                    .stroke(palette.hairline, lineWidth: 1)
            )
    }
}

public extension View {
    func themeField(_ palette: ThemePalette) -> some View {
        modifier(ThemeFieldModifier(palette: palette))
    }
}

public struct SheetHeaderBar: View {
    public let title: String
    public let cancelTitle: String?
    public let cancelIdentifier: String?
    public let onCancel: (() -> Void)?
    @Environment(\.themePalette) private var palette

    public init(
        title: String,
        cancelTitle: String? = nil,
        cancelIdentifier: String? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = title
        self.cancelTitle = cancelTitle
        self.cancelIdentifier = cancelIdentifier
        self.onCancel = onCancel
    }

    public init(
        title: String,
        leftTitle: String?,
        leftId: String?,
        onLeft: (() -> Void)?
    ) {
        self.title = title
        self.cancelTitle = leftTitle
        self.cancelIdentifier = leftId
        self.onCancel = onLeft
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 88)

                HStack {
                    if let cancelTitle, let onCancel {
                        Button(action: onCancel) {
                            Text(cancelTitle)
                                .font(.body)
                                .foregroundStyle(palette.actionTint)
                                .padding(.horizontal, ThemeSpace.s8)
                                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(cancelIdentifier ?? "sheet.cancel")
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, ThemeSpace.s16)
            .padding(.vertical, ThemeSpace.s8)
            .background(palette.bgPrimary)

            Rectangle()
                .fill(palette.hairline)
                .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                .accessibilityHidden(true)
        }
    }
}

public struct InvisibleAccessibleButtonRepresentable: UIViewRepresentable {
    public let identifier: String
    public let label: String
    public let onTap: () -> Void

    public init(identifier: String, label: String, onTap: @escaping () -> Void) {
        self.identifier = identifier
        self.label = label
        self.onTap = onTap
    }

    public func makeUIView(context: Context) -> InvisibleAccessibleControl {
        let control = InvisibleAccessibleControl()
        control.backgroundColor = .clear
        control.isAccessibilityElement = true
        control.accessibilityTraits = .button
        control.accessibilityIdentifier = identifier
        control.accessibilityLabel = label
        control.onTap = onTap
        return control
    }

    public func updateUIView(_ uiView: InvisibleAccessibleControl, context: Context) {
        uiView.accessibilityIdentifier = identifier
        uiView.accessibilityLabel = label
        uiView.onTap = onTap
    }

    public final class InvisibleAccessibleControl: UIControl {
        var onTap: (() -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            addTarget(self, action: #selector(handleTouchUpInside), for: .touchUpInside)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc private func handleTouchUpInside() {
            onTap?()
        }
    }
}
