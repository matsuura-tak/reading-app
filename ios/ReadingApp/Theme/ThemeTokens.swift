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

    /// 拡張の読み方（contracts/widget-snapshot.schema.json の読む側の決まり）。読めなければ理由を返す。
    public nonisolated static func readWidgetSnapshot() -> WidgetSnapshotReadResult {
        WidgetSnapshotReader.read(fileURL: widgetSnapshotFileURL())
    }

    public nonisolated static func loadWidgetSnapshot() -> WidgetSnapshot {
        let url = widgetSnapshotFileURL()
        if let data = try? Data(contentsOf: url) {
            return WidgetSnapshot.decodeForWidgetRenderer(from: data)
        }
        return WidgetSnapshot()
    }
}

/// 本のデータを design/ 7 の書式のキーで文にする（言語ごとの文は String Catalog が持つ）。
public enum BookTextFormat {
    /// `colophon.publisher.withLabel`。出版社とレーベルの片方だけなら、その値だけ。
    public static func publisherWithLabel(publisher: String?, label: String?) -> String? {
        let pub = publisher?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lbl = label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !pub.isEmpty && !lbl.isEmpty {
            return String(format: String(localized: "colophon.publisher.withLabel"), pub, lbl)
        }
        if !pub.isEmpty { return pub }
        if !lbl.isEmpty { return lbl }
        return nil
    }

    /// `colophon.year.value`（桁区切りのカンマを入れない）。
    public static func publishedYear(_ year: Int) -> String {
        String(format: String(localized: "colophon.year.value"), year)
    }

    /// `book.nights`（英語は複数形）。
    public static func nights(_ count: Int) -> String {
        String.localizedStringWithFormat(NSLocalizedString("book.nights", comment: ""), count)
    }

    /// `finish.reflection.single` / `finish.reflection.multi`。括弧の中は `duration.hoursMinutes`（分が0なら `duration.hours`）。
    public static func finishReflection(_ summary: FinishReflectionSummary) -> String {
        if summary.uniqueNights <= 1 {
            return String(format: String(localized: "finish.reflection.single"), summary.totalMinutes)
        }
        let longest = summary.longestNight
        return String(
            format: String(localized: "finish.reflection.multi"),
            summary.uniqueNights,
            summary.totalMinutes,
            hoursAndMinutes(summary.totalMinutes),
            nightDayText(longest),
            longest.totalMinutes
        )
    }

    static func hoursAndMinutes(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 {
            return String(format: String(localized: "duration.minutes"), totalMinutes)
        }
        if minutes == 0 {
            return String(format: String(localized: "duration.hours"), hours)
        }
        return String(format: String(localized: "duration.hoursMinutes"), hours, minutes)
    }

    /// 晩の月日（決定 56：端末の言語の書式。日本語は「10月15日」）。
    static func nightDayText(_ night: NightTotal) -> String {
        nightDayText(night.nightDate)
    }

    /// 晩の日付（`yyyy-MM-dd`）を月日にする。`wide` は読み上げと S-7b の「10月16日」、そうでなければ見える行の「10/16」（決定 60）。
    /// 読めない値はそのまま返す。
    public static func nightDayText(_ nightDate: String, wide: Bool = true) -> String {
        let parts = nightDate.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nightDate }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        guard let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) else {
            return nightDate
        }
        var style = Date.FormatStyle.dateTime.day()
        style = wide ? style.month(.wide) : style.month(.defaultDigits)
        style.timeZone = .gmt
        return date.formatted(style)
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

    /// ウィジェットの縦書きの字。枠に収める大きさを ReadingCore の WidgetLineComposer が決めるため、大きさを固定する（screens.md W-1、W-2）。
    public static func widgetLineFixed(size: CGFloat) -> Font {
        .custom("HiraMinProN-W6", fixedSize: size)
    }

    public static func finishCardTitle(size: CGFloat = 28) -> Font {
        .custom("HiraMinProN-W6", size: size, relativeTo: .title)
    }

    /// 和文の組みの言語（tokens.md 3「本文と操作はシステムの書体（SF Pro / ヒラギノ角ゴ）」）。
    /// 端末の言語が英語だけのとき、システムの書体の置き換え（cascade list）は漢字・かなを中国語の書体（PingFang SC）へ回す。
    /// 組みの言語を日本語にすると、置き換えがヒラギノ角ゴになる（ラテン文字は SF Pro のまま）。文言の言語は変えない。
    public static let japaneseTypesettingLanguage = Locale.Language(identifier: "ja")
}

public extension View {
    /// 書名・著者・一行・出版社など本のデータに和文が入る画面の根に付ける（ThemeTypography.japaneseTypesettingLanguage）。
    func japaneseTextTypesetting() -> some View {
        typesettingLanguage(ThemeTypography.japaneseTypesettingLanguage)
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // design/ 9・tokens.md 7（決定 93）：accessibility1 以上では帯に題を描かず、左のボタンだけを置く。
                // 題は内容の先頭の `SheetContentTitle` が見出しとして出す（帯の中で題とボタンを重ねない）。
                if !title.isEmpty && !dynamicTypeSize.isAccessibilitySize {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 88)
                        .accessibilityAddTraits(.isHeader)
                }

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

/// シートの題を内容の先頭の行に出す（accessibility1 以上のときだけ。design/ 9・tokens.md 7、決定 93）。
/// 標準の大きさでは帯（`SheetHeaderBar`）が題を出すので、ここは何も描かない。
public struct SheetContentTitle: View {
    public let title: String
    @Environment(\.themePalette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        if dynamicTypeSize.isAccessibilitySize && !title.isEmpty {
            Text(title)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
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
