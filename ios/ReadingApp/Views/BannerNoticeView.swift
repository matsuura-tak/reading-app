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

    public static func message(forKey key: String) -> String {
        switch key {
        case "session.tooShort":
            return AppL10n.pick("1分未満のため記録しませんでした。", "Under 1 minute, so it was not recorded.")
        case "session.invalidTime":
            return AppL10n.pick("時刻が巻き戻ったため記録しませんでした。", "Clock moved backward, so it was not recorded.")
        case "session.capped":
            return AppL10n.pick("24時間を上限として記録しました。", "Recorded up to the 24-hour maximum.")
        case "session.start.error":
            return AppL10n.pick("読書を始められませんでした。もう一度お試しください。", "Could not start reading. Please try again.")
        case "session.save.error":
            return AppL10n.pick("記録を保存できませんでした。もう一度お試しください。", "Could not save your reading record. Please try again.")
        case "common.save.error":
            return AppL10n.pick("保存できませんでした。もう一度お試しください。", "Could not save. Please try again.")
        case "store.load.error":
            return AppL10n.pick("データを読み込めませんでした。", "Could not load your data.")
        case "book.title.invalid":
            return AppL10n.pick("書名を1〜100文字で入力してください。", "Enter a book title between 1 and 100 characters.")
        case "book.author.invalid":
            return AppL10n.pick("著者名を100文字以内で入力してください。", "Keep the author name within 100 characters.")
        case "mark.line.invalid":
            return AppL10n.pick("一行を1〜60文字で入力してください。", "Enter a line between 1 and 60 characters.")
        case "mark.page.invalid":
            return AppL10n.pick("正しい数値を入力してください。", "Enter a valid number.")
        case "record.minutes.invalid":
            return AppL10n.pick("1〜1440分の数値を入力してください。", "Enter minutes between 1 and 1440.")
        case "store.unavailable":
            return AppL10n.pick("この端末では購入が制限されています。", "Purchases are restricted on this device.")
        case "store.offline":
            return AppL10n.pick("オフラインのため価格を取得できません。", "Cannot fetch price while offline.")
        case "store.purchase.error":
            return AppL10n.pick("購入を完了できませんでした。", "Could not complete the purchase.")
        case "store.restore.done":
            return AppL10n.pick("購入を復元しました。", "Purchases restored.")
        case "store.restore.none":
            return AppL10n.pick("復元できる購入が見つかりませんでした。", "No purchases found to restore.")
        default:
            return key
        }
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
