import SwiftUI

/// S2 本を追加（sheet。design 1、3、5、6、9）。題名だけで本を登録する。
/// 題名の上限は形B（保存のときに先頭の100字に切る。設計メモ 5、design 6 の (f) の代わりの案）なので、標準の TextField のまま。
struct AddBookView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var title: String
    @State private var totalPagesText: String
    /// 追加の保存に失敗した（AC-42）。
    @State private var saveFailed: Bool
    @State private var isDiscardConfirmPresented = false
    /// 追加の保存が通った（design S2「保存の間は追加を無効」）。閉じるまでの二度押しで2冊できないようにする。
    @State private var didSave = false
    @FocusState private var focusedField: Field?

    private nonisolated enum Field: Hashable {
        case title
        case totalPages
    }

    init(title: String = "", totalPagesText: String = "", saveFailed: Bool = false) {
        _title = State(initialValue: title)
        _totalPagesText = State(initialValue: totalPagesText)
        _saveFailed = State(initialValue: saveFailed)
    }

    /// 入力があるか（あればスワイプで閉じさせず、キャンセルで確かめる。D-18、AC-53）。
    private var hasInput: Bool {
        !title.isEmpty || !totalPagesText.isEmpty
    }

    /// 総ページ数：空か 1〜9999（AC-31）。
    private var totalPagesIsValid: Bool {
        switch NumberInput.parse(totalPagesText) {
        case .empty: true
        case .number(let pages): ReadingMath.totalPagesRange.contains(pages)
        case .invalid: false
        }
    }

    /// 題名は整えた後に1字以上（AC-3）。100字を超えても誤りにしない（D-45）。
    private var canSave: Bool {
        TitleRules.isValid(title) && totalPagesIsValid
    }

    var body: some View {
        NavigationStack {
            Form {
                if saveFailed {
                    Section {
                        VStack(alignment: .leading, spacing: Space.xs) {
                            SaveFailedTitle()
                            Text("error.saveFailed.book")
                                .font(.footnote)
                                .foregroundStyle(Color.primary)
                                .accessibilityIdentifier("error.saveFailed.book")
                            Button {
                                save()
                            } label: {
                                Text("error.retry")
                            }
                            .secondaryBorderedButton()
                            .disabled(!canSave || didSave)
                            .accessibilityIdentifier("error.retry")
                        }
                    }
                }
                Section {
                    TextField(String(), text: $title)
                        .focused($focusedField, equals: .title)
                        .accessibilityLabel(Text("book.add.titleField"))
                        .accessibilityIdentifier("book.add.title")
                } header: {
                    Text("book.add.titleField")
                        .font(.footnote)
                        .foregroundStyle(Color.primary)
                        .textCase(nil)
                } footer: {
                    if TitleRules.exceedsLimit(title) {
                        Text(verbatim: Loc.titleLimitOnSave(TitleRules.maxLength, locale: locale))
                            .font(.footnote)
                            .foregroundStyle(Color.primary)
                            .accessibilityIdentifier("book.add.titleLimit")
                    }
                }
                Section {
                    TextField(String(), text: $totalPagesText)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .totalPages)
                        .accessibilityLabel(Text("book.add.totalPagesField"))
                        .accessibilityIdentifier("book.add.totalPages")
                } header: {
                    Text("book.add.totalPagesField")
                        .font(.footnote)
                        .foregroundStyle(Color.primary)
                        .textCase(nil)
                } footer: {
                    if totalPagesIsValid {
                        Text("book.add.totalPagesHint")
                            .font(.footnote)
                            .foregroundStyle(Color.primary)
                            .accessibilityIdentifier("book.add.totalPagesHint")
                    } else {
                        FieldErrorText(
                            text: String(
                                localized: "book.add.totalPagesOutOfRange", defaultValue: "1から9999までの数字で入れてください。"),
                            identifier: "book.add.totalPagesOutOfRange")
                    }
                }
            }
            .navigationTitle(Text("book.add.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        cancel()
                    } label: {
                        Text("common.cancel")
                    }
                    .accessibilityIdentifier("book.add.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Text("book.save")
                    }
                    .accentProminentButton()
                    .disabled(!canSave || didSave)
                    .accessibilityIdentifier("book.save")
                }
            }
            .confirmationDialog(
                Text("book.add.discard.title"), isPresented: $isDiscardConfirmPresented, titleVisibility: .visible
            ) {
                Button(role: .destructive) {
                    dismiss()
                } label: {
                    Text("book.add.discard.confirm")
                }
                .accessibilityIdentifier("book.add.discard.confirm")
                Button(role: .cancel) {
                } label: {
                    Text("common.cancel")
                }
            }
        }
        .interactiveDismissDisabled(hasInput)
        .onAppear { focusedField = .title }
        .onChange(of: totalPagesIsValid) { _, valid in
            if !valid {
                Announce.post(
                    String(localized: "book.add.totalPagesOutOfRange", defaultValue: "1から9999までの数字で入れてください。"))
            }
        }
        .onChange(of: TitleRules.exceedsLimit(title)) { _, exceeds in
            if exceeds { Announce.post(Loc.titleLimitOnSave(TitleRules.maxLength, locale: locale)) }
        }
    }

    /// 「追加」と「もう一度保存」（AC-2、AC-42、AC-49）。通ったら閉じて、追加した本の S3 を積む。
    private func save() {
        guard canSave, !didSave else { return }
        let totalPages = NumberInput.value(totalPagesText, in: ReadingMath.totalPagesRange)
        do {
            let bookID = try store.addBook(title: title, totalPages: totalPages)
            didSave = true
            saveFailed = false
            router.bookAdded(bookID)
        } catch let error as StoreError {
            if case .saveFailed = error {
                saveFailed = true
                Announce.saveFailed()
            }
        } catch {
            // 範囲の外の入力は canSave で止めている。ほかの失敗は画面を変えない。
        }
    }

    /// 「キャンセル」：入力が空なら閉じる。入力があれば確かめてから閉じる（AC-53）。
    private func cancel() {
        if hasInput {
            isDiscardConfirmPresented = true
        } else {
            dismiss()
        }
    }
}

#if DEBUG
#Preview("S2/通常") {
    let built = PreviewLibrary.make()
    AddBookView(title: "坊っちゃん").previewEnvironment(built)
}

#Preview("S2/空") {
    let built = PreviewLibrary.make()
    AddBookView().previewEnvironment(built)
}

#Preview("S2/エラー（総ページ数が範囲の外）") {
    let built = PreviewLibrary.make()
    AddBookView(title: "こころ", totalPagesText: "0").previewEnvironment(built)
}

#Preview("S2/エラー（保存の失敗）") {
    let built = PreviewLibrary.make()
    AddBookView(title: "こころ", saveFailed: true).previewEnvironment(built)
}

#Preview("S2/題名の上限（形B）") {
    let built = PreviewLibrary.make()
    AddBookView(title: String(repeating: "あ", count: 101)).previewEnvironment(built)
}

#Preview("S2/AX5") {
    let built = PreviewLibrary.make()
    AddBookView(title: "坊っちゃん")
        .previewEnvironment(built)
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("S2/ダーク") {
    let built = PreviewLibrary.make()
    AddBookView(title: "坊っちゃん")
        .previewEnvironment(built)
        .preferredColorScheme(.dark)
}
#endif
