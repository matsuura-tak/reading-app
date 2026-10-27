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

    public init(state: BannerNoticeViewState, onDismiss: (() -> Void)? = nil) {
        self.state = state
        self.onDismiss = onDismiss
    }

    public init(model: ReadingAppModel) {
        if let errKey = model.store.activeErrorKey {
            self.state = .error(key: errKey, text: Self.message(forKey: errKey))
            self.onDismiss = {
                model.store.activeErrorKey = nil
                model.notifyHookChanged()
            }
        } else if let noticeKey = model.store.activeNoticeKey {
            self.state = .notice(key: noticeKey, text: Self.message(forKey: noticeKey))
            self.onDismiss = {
                model.store.activeNoticeKey = nil
                model.notifyHookChanged()
            }
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
            HStack(spacing: 8) {
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier(key)
                    .accessibilityLabel(text)
                    .accessibilityValue(text)
                Spacer(minLength: 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("banner.notice")
        case .error(let key, let text):
            HStack(spacing: 8) {
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier(key)
                    .accessibilityLabel(text)
                    .accessibilityValue(text)
                Spacer(minLength: 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("banner.error")
        }
    }

    public static func message(forKey key: String) -> String {
        switch key {
        case "session.tooShort":
            return String(localized: "session.tooShort", defaultValue: "1分未満のため記録しませんでした。")
        case "session.invalidTime":
            return String(localized: "session.invalidTime", defaultValue: "時刻が巻き戻ったため記録しませんでした。")
        case "session.capped":
            return String(localized: "session.capped", defaultValue: "24時間を上限として記録しました。")
        case "session.start.error":
            return String(localized: "session.start.error", defaultValue: "読書を始められませんでした。もう一度お試しください。")
        case "session.save.error":
            return String(localized: "session.save.error", defaultValue: "記録を保存できませんでした。もう一度お試しください。")
        case "common.save.error":
            return String(localized: "common.save.error", defaultValue: "保存できませんでした。もう一度お試しください。")
        case "store.load.error":
            return String(localized: "store.load.error", defaultValue: "データを読み込めませんでした。")
        case "book.title.invalid":
            return String(localized: "book.title.invalid", defaultValue: "書名を1〜100文字で入力してください。")
        case "book.author.invalid":
            return String(localized: "book.author.invalid", defaultValue: "著者名を100文字以内で入力してください。")
        case "mark.line.invalid":
            return String(localized: "mark.line.invalid", defaultValue: "一行を1〜60文字で入力してください。")
        case "mark.page.invalid":
            return String(localized: "mark.page.invalid", defaultValue: "正しい数値を入力してください。")
        case "record.minutes.invalid":
            return String(localized: "record.minutes.invalid", defaultValue: "1〜1440分の数値を入力してください。")
        case "store.unavailable":
            return String(localized: "store.unavailable", defaultValue: "この端末では購入が制限されています。")
        case "store.offline":
            return String(localized: "store.offline", defaultValue: "オフラインのため価格を取得できません。")
        case "store.purchase.error":
            return String(localized: "store.purchase.error", defaultValue: "購入を完了できませんでした。")
        case "store.restore.done":
            return String(localized: "store.restore.done", defaultValue: "購入を復元しました。")
        case "store.restore.none":
            return String(localized: "store.restore.none", defaultValue: "復元できる購入が見つかりませんでした。")
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
            let emptyLabel = String(localized: "bookmark.line.empty", defaultValue: "まだ一行はありません")
            Text(emptyLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("bookmark.line.empty")
                .accessibilityLabel(emptyLabel)
                .accessibilityValue("")
        case .content(let line, let isVertical):
            let cells = VerticalLineLayout.layoutVerticalCells(text: line, maxColumns: 2, rowsPerColumn: 18)
            let groupedCols = Dictionary(grouping: cells, by: \.column)
            let colNumbers = [1, 0].compactMap { groupedCols[$0] != nil ? $0 : nil }
            VStack(spacing: 8) {
                if isVertical && !colNumbers.isEmpty {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(colNumbers, id: \.self) { colNum in
                            let colCells = groupedCols[colNum] ?? []
                            VStack(spacing: 2) {
                                ForEach(Array(colCells.enumerated()), id: \.offset) { _, cell in
                                    Text(cell.display)
                                        .font(.system(.title3, design: .serif))
                                }
                            }
                        }
                    }
                    .accessibilityHidden(true)
                }
                Text(line)
                    .font(.system(.body, design: .serif))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("bookmark.line")
                    .accessibilityLabel(line)
                    .accessibilityValue(line)
            }
            .padding(.vertical, 12)
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
