import SwiftUI

// 見た目のトークン（design/tokens.md）の当て方を1か所に置く。画面のコードは色の値と文字の大きさを直接書かない。
// 文字は Dynamic Type の text style だけ（tokens.md 2）。色は Asset Catalog の Color Set と、システムの色（Color.primary など）。

/// 余白（tokens.md 3。4pt を元にした6段）。List、Form、toolbar、sheet の中はシステムの既定に任せる。
enum Space {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
}

/// 色のトークン（tokens.md 1）。color.accent.text は Asset Catalog の AccentColor（システムの tint）なので、ここには置かない。
enum AppColor {
    /// color.accent.fill（.borderedProminent の塗りだけ）。
    static let accentFill = Color("BookmarkFill")
    /// color.text.onAccent（塗りの上のラベル）。
    static let onAccent = Color("OnAccent")
    /// color.status.error（systemRed。誤りとエラーの区画の記号だけ）。
    static let statusError = Color.red
    /// color.background.grouped（下端の主操作の帯。不透明）。
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    /// color.background.screen（読書中の画面）。
    static let screenBackground = Color(uiColor: .systemBackground)
}

extension View {
    /// 目立つボタン（.borderedProminent）。tokens.md 1 の当て方：塗りは color.accent.fill、ラベルは color.text.onAccent（D-46、D-47）。
    func accentProminentButton() -> some View {
        buttonStyle(.borderedProminent)
            .tint(AppColor.accentFill)
            .foregroundStyle(AppColor.onAccent)
    }

    /// 主操作でないボタン（.bordered、tint は color.text.primary。D-41、D-50）。
    func secondaryBorderedButton() -> some View {
        buttonStyle(.bordered)
            .tint(Color.primary)
    }

    /// 下端の主操作の帯（S1、S3。3 の逸脱：中身は標準の Button。背景は不透明な color.background.grouped）。
    func bottomActionBar() -> some View {
        padding(.horizontal, Space.m)
            .padding(.top, Space.xs)
            .padding(.bottom, Space.xs)
            .frame(maxWidth: .infinity)
            .background(AppColor.groupedBackground)
    }
}

/// エラーの区画の題（記号 exclamationmark.triangle と error.saveFailed）。識別子は1つの要素にだけ付ける（記号は読まない）。
struct SaveFailedTitle: View {
    var body: some View {
        Label {
            Text("error.saveFailed")
                .font(.headline)
                .foregroundStyle(Color.primary)
        } icon: {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(AppColor.statusError)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("error.saveFailed"))
        .accessibilityIdentifier("error.saveFailed")
    }
}

/// 欄のすぐ下の誤りの文（D-13、D-37：記号は color.status.error、文は color.text.primary）。
struct FieldErrorText: View {
    let text: String
    let identifier: String

    var body: some View {
        Label {
            Text(verbatim: text)
                .font(.footnote)
                .foregroundStyle(Color.primary)
        } icon: {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(AppColor.statusError)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: text))
        .accessibilityIdentifier(identifier)
    }
}

/// 値を出す行（design 6：1つの要素にまとめ、label は項目名、value は値の文字。テストは value を読む）。
/// AX サイズでは項目名の下に値を置く縦並び（design 9）。中身は標準の LabeledContent と Text。
struct StatRow: View {
    let label: LocalizedStringKey
    let value: String
    let identifier: String
    @Environment(\.dynamicTypeSize) private var typeSize

    init(label: LocalizedStringKey, value: String, identifier: String) {
        self.label = label
        self.value = value
        self.identifier = identifier
    }

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text(label)
                    Text(verbatim: value)
                        .monospacedDigit()
                }
            } else {
                LabeledContent {
                    Text(verbatim: value)
                        .monospacedDigit()
                        .foregroundStyle(Color.primary)
                } label: {
                    Text(label)
                }
            }
        }
        .foregroundStyle(Color.primary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(verbatim: value))
        .accessibilityIdentifier(identifier)
    }
}
