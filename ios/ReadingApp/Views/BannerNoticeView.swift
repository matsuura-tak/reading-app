import SwiftUI
import ReadingCore
import ReadingStore

public enum BannerNoticeViewState: Equatable, Sendable {
    case hidden
    case notice(key: String, text: String)
    case error(key: String, text: String)
}

public struct BannerNoticeView: View {
    public let state: BannerNoticeViewState
    public let onDismiss: (() -> Void)?
    @Environment(\.themePalette) private var palette

    public init(state: BannerNoticeViewState, onDismiss: (() -> Void)? = nil) {
        self.state = state
        self.onDismiss = onDismiss
    }

    public init(model: ReadingAppModel, showCloseButton: Bool = true) {
        if let errKey = model.store.activeErrorKey {
            self.state = .error(key: errKey, text: Self.message(forKey: errKey))
            self.onDismiss = showCloseButton ? {
                model.store.activeErrorKey = nil
                model.notifyHookChanged()
            } : nil
        } else if let noticeKey = model.store.activeNoticeKey {
            self.state = .notice(key: noticeKey, text: Self.message(forKey: noticeKey))
            self.onDismiss = showCloseButton ? {
                model.store.activeNoticeKey = nil
                model.notifyHookChanged()
            } : nil
        } else {
            self.state = .hidden
            self.onDismiss = nil
        }
    }

    public var body: some View {
        switch state {
        case .hidden:
            EmptyView()
        case .notice(let key, let text):
            bannerCard(
                iconName: "info.circle",
                iconColor: palette.textSecondary,
                key: key,
                text: text,
                containerIdentifier: "banner.notice"
            )
        case .error(let key, let text):
            bannerCard(
                iconName: "exclamationmark.circle",
                iconColor: palette.stateError,
                key: key,
                text: text,
                containerIdentifier: "banner.error"
            )
        }
    }

    private func bannerCard(
        iconName: String,
        iconColor: Color,
        key: String,
        text: String,
        containerIdentifier: String
    ) -> some View {
        HStack(alignment: .center, spacing: ThemeSpace.s12) {
            Image(systemName: iconName)
                .font(.body)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(key)
                .accessibilityLabel(text)
                .accessibilityValue(text)

            Spacer(minLength: ThemeSpace.s4)

            if let onDismiss {
                Button(action: onDismiss) {
                    Text(AppL10n.pick("閉じる", "Close"))
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette, fullWidth: false))
                .accessibilityIdentifier("notice.close")
            }
        }
        .padding(ThemeSpace.s16)
        .background(
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .fill(palette.groupedRow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .stroke(palette.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(containerIdentifier)
    }

    /// 知らせと入力誤りの文（design/ 7 の同じ名前のキー）。String Catalog にないキーはキーの名前のまま出る。
    public static func message(forKey key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }
}

public enum VerticalBookmarkTextViewState: Equatable, Sendable {
    case empty
    case content(line: String, isVertical: Bool)
}

public struct VerticalBookmarkTextView: View {
    public let state: VerticalBookmarkTextViewState
    @Environment(\.themePalette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(state: VerticalBookmarkTextViewState) {
        self.state = state
    }

    public init(line: String?) {
        if let line, !line.isEmpty {
            self.state = .content(line: line, isVertical: VerticalLineLayout.containsJapaneseScript(line))
        } else {
            self.state = .empty
        }
    }

    public var body: some View {
        switch state {
        case .empty:
            let emptyLabel = AppL10n.pick("まだ一行はありません", "No saved line yet")
            Text(emptyLabel)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.vertical, ThemeSpace.s24)
                .accessibilityIdentifier("bookmark.line.empty")
                .accessibilityLabel(emptyLabel)
                .accessibilityValue("")
        case .content(let line, let isVertical):
            let useVertical = isVertical && !dynamicTypeSize.isAccessibilitySize
            Group {
                if useVertical {
                    let cells = VerticalLineLayout.layoutVerticalCells(text: line, maxColumns: 5, rowsPerColumn: 12)
                    let groupedCols = Dictionary(grouping: cells, by: \.column)
                    let colNumbers = (0..<5).reversed().filter { groupedCols[$0] != nil }
                    HStack(alignment: .top, spacing: ThemeSpace.s16) {
                        ForEach(colNumbers, id: \.self) { colNum in
                            let colCells = groupedCols[colNum] ?? []
                            VStack(spacing: ThemeSpace.s4) {
                                ForEach(Array(colCells.enumerated()), id: \.offset) { _, cell in
                                    Text(cell.display)
                                        .font(ThemeTypography.bookmarkLine(size: 28))
                                        .foregroundStyle(palette.textPrimary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, ThemeSpace.s24)
                } else {
                    Text(line)
                        .font(ThemeTypography.bookmarkLine(size: 28))
                        .foregroundStyle(palette.textPrimary)
                        .lineSpacing(ThemeSpace.s8)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, ThemeSpace.s16)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("bookmark.line")
            .accessibilityLabel(line)
            .accessibilityValue(line)
        }
    }
}

#Preview("BannerNotice - Notice") {
    BannerNoticeView(state: .notice(key: "session.tooShort", text: BannerNoticeView.message(forKey: "session.tooShort")))
        .padding()
}

#Preview("BannerNotice - Error") {
    BannerNoticeView(state: .error(key: "common.save.error", text: BannerNoticeView.message(forKey: "common.save.error")))
        .padding()
}

#Preview("BannerNotice - AX5 Dark") {
    BannerNoticeView(state: .error(key: "mark.line.invalid", text: BannerNoticeView.message(forKey: "mark.line.invalid")))
        .padding()
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}

#Preview("VerticalBookmarkText - Vertical") {
    VerticalBookmarkTextView(line: "ある日の暮方の事である。")
        .padding()
}
