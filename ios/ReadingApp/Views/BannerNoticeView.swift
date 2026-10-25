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
                    .accessibilityIdentifier("notice.\(key)")
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
                    .accessibilityIdentifier("error.\(key)")
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
            return "1分未満のため記録しませんでした。"
        case "session.invalidTime":
            return "時刻が巻き戻ったため記録しませんでした。"
        case "session.capped":
            return "24時間を上限として記録しました。"
        case "session.start.error":
            return "読書を始められませんでした。もう一度お試しください。"
        case "session.save.error":
            return "記録を保存できませんでした。もう一度お試しください。"
        case "common.save.error":
            return "保存できませんでした。もう一度お試しください。"
        case "store.load.error":
            return "データを読み込めませんでした。"
        case "book.title.invalid":
            return "書名を1〜200文字で入力してください。"
        case "book.author.invalid":
            return "著者名を200文字以内で入力してください。"
        case "mark.line.invalid":
            return "一行を1〜120文字で入力してください。"
        case "mark.page.invalid":
            return "正しい数値を入力してください。"
        case "record.minutes.invalid":
            return "1〜1440分の数値を入力してください。"
        case "store.unavailable":
            return "この端末では購入が制限されています。"
        case "store.offline":
            return "オフラインのため価格を取得できません。"
        case "store.purchase.error":
            return "購入を完了できませんでした。"
        case "store.restore.done":
            return "購入を復元しました。"
        case "store.restore.none":
            return "復元できる購入が見つかりませんでした。"
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
            Text("まだ一行はありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("bookmark.line.empty")
                .accessibilityLabel("まだ一行はありません")
                .accessibilityValue("")
        case .content(let line, let isVertical):
            let cells = VerticalLineLayout.layoutVerticalCells(text: line, maxColumns: 2, rowsPerColumn: 18)
            let groupedCols = Dictionary(grouping: cells, by: \.column)
            let sortedColNumbers = groupedCols.keys.sorted(by: >)
            VStack(spacing: 8) {
                if isVertical && !sortedColNumbers.isEmpty {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(sortedColNumbers, id: \.self) { colNum in
                            let colCells = (groupedCols[colNum] ?? []).sorted { $0.row < $1.row }
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
    BannerNoticeView(state: .notice(key: "session.tooShort", text: "1分未満のため記録しませんでした。"))
        .padding()
}

#Preview("BannerNotice - Error") {
    BannerNoticeView(state: .error(key: "common.save.error", text: "保存できませんでした。もう一度お試しください。"))
        .padding()
}

#Preview("BannerNotice - AX5 Dark") {
    BannerNoticeView(state: .error(key: "mark.line.invalid", text: "一行を1〜120文字で入力してください。"))
        .padding()
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}

#Preview("VerticalBookmarkText - Vertical") {
    VerticalBookmarkTextView(line: "ある日の暮方の事である。")
        .padding()
}
