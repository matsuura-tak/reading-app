import SwiftUI

/// S5 読書を終える（sheet。design 1、3、5、6、9）。今のページと読んだ時間を確かめて、記録に残す。
/// 下書きと Bool は S4 のモデル（ReadingModel）が持つ（D-60）。下へのスワイプは止めない（interactiveDismissDisabled なし。D-3）。
struct FinishSessionView: View {
    @Bindable var model: ReadingModel
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var typeSize
    @FocusState private var focusedField: Field?

    private nonisolated enum Field: Hashable {
        case page
        case minutes
    }

    init(model: ReadingModel) {
        _model = Bindable(model)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let failure = model.finishFailure {
                    errorSection(failure)
                }
                Section {
                    numberField(
                        label: "session.finish.page.label", text: $model.draft.pageText, field: .page,
                        identifier: "session.finish.page")
                } header: {
                    Text(verbatim: model.book?.title ?? "")
                        .font(.footnote)
                        .foregroundStyle(Color.primary)
                        .textCase(nil)
                        .lineLimit(2)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("session.finish.book")
                } footer: {
                    if model.pageIsValid {
                        pageHint
                    } else {
                        FieldErrorText(
                            text: Loc.pageOutOfRange(max: model.maxPage), identifier: "session.finish.pageOutOfRange")
                    }
                }
                Section {
                    numberField(
                        label: "session.finish.minutes.label", text: $model.draft.minutesText, field: .minutes,
                        identifier: "session.finish.minutes")
                } footer: {
                    if model.minutesValue != nil {
                        Text(verbatim: Loc.minutesHint(minutes: model.draft.minutesInitial, locale: locale))
                            .font(.footnote)
                            .foregroundStyle(Color.primary)
                            .accessibilityIdentifier("session.finish.minutes.hint")
                    } else {
                        FieldErrorText(
                            text: Loc.minutesOutOfRange(max: model.draft.minutesInitial),
                            identifier: "session.finish.minutesOutOfRange")
                    }
                }
            }
            .navigationTitle(Text("session.finish.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        model.cancelFinish()
                    } label: {
                        Text("common.cancel")
                    }
                    .accessibilityIdentifier("session.finish.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        model.saveSession(locale: locale)
                    } label: {
                        Text("session.finish.save")
                    }
                    .accentProminentButton()
                    .disabled(!model.canSave)
                    .accessibilityIdentifier("session.finish.save")
                }
                // 数字のキーボードには確定のキーがないので、キーボードの上の右端にも「保存」（.bordered。D-53）。
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        model.saveSession(locale: locale)
                    } label: {
                        Text("session.finish.save")
                    }
                    .secondaryBorderedButton()
                    .disabled(!model.canSave)
                    .accessibilityIdentifier("session.finish.saveKeyboard")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("session.state.finishing")
        .onAppear { focusedField = .page }
        .onChange(of: model.pageIsValid) { _, valid in
            if !valid { Announce.post(Loc.pageOutOfRange(max: model.maxPage)) }
        }
        .onChange(of: model.minutesValue == nil) { _, invalid in
            if invalid { Announce.post(Loc.minutesOutOfRange(max: model.draft.minutesInitial)) }
        }
    }

    /// 今のページのヒント：最後のページが1以上なら「前回は40ページでした。…」、0なら「入れずに保存もできます。」。
    @ViewBuilder private var pageHint: some View {
        let lastPage = model.book?.lastPage ?? 0
        Group {
            if lastPage >= 1 {
                Text(verbatim: Loc.pageHint(lastPage: lastPage))
            } else {
                Text("session.finish.page.hintFirst")
            }
        }
        .font(.footnote)
        .foregroundStyle(Color.primary)
        .accessibilityIdentifier("session.finish.page.hint")
    }

    /// 項目名と数字の欄（placeholder なし。D-49）。AX サイズでは項目名の下に欄（design 9）。
    /// 欄の VoiceOver のラベルは項目名、value は入れた文字（design 6）。見える項目名は欄のラベルと重なるので読まない。
    @ViewBuilder
    private func numberField(
        label: LocalizedStringKey, text: Binding<String>, field: Field, identifier: String
    ) -> some View {
        let input = TextField(String(), text: text)
            .keyboardType(.numberPad)
            .focused($focusedField, equals: field)
            .accessibilityLabel(Text(label))
            .accessibilityIdentifier(identifier)
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(label)
                    .foregroundStyle(Color.primary)
                    .accessibilityHidden(true)
                input
            }
        } else {
            HStack(spacing: Space.m) {
                Text(label)
                    .foregroundStyle(Color.primary)
                    .accessibilityHidden(true)
                input
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    /// 先頭のエラーの区画（記録の保存の失敗と、やめる保存の失敗。最後に失敗した方。D-14、D-60）。
    private func errorSection(_ failure: FinishFailure) -> some View {
        Section {
            VStack(alignment: .leading, spacing: Space.xs) {
                SaveFailedTitle()
                switch failure {
                case .save:
                    Text("error.saveFailed.session")
                        .font(.footnote)
                        .foregroundStyle(Color.primary)
                        .accessibilityIdentifier("error.saveFailed.session")
                    Button {
                        model.saveSession(locale: locale)
                    } label: {
                        Text("error.retry")
                    }
                    .secondaryBorderedButton()
                    .disabled(!model.canSave)
                    .accessibilityIdentifier("error.retry")
                case .cancel:
                    Text("error.saveFailed.cancel")
                        .font(.footnote)
                        .foregroundStyle(Color.primary)
                        .accessibilityIdentifier("error.saveFailed.cancel")
                    Button {
                        model.cancelFinish()
                    } label: {
                        Text("error.retry.cancel")
                    }
                    .secondaryBorderedButton()
                    .accessibilityIdentifier("error.retry")
                }
            }
        }
    }
}

#if DEBUG
#Preview("S5/通常") {
    let built = PreviewLibrary.make(active: .finishing)
    let model = PreviewLibrary.finishingModel(built)
    FinishSessionView(model: model).previewEnvironment(built)
}

#Preview("S5/空（今のページが空）") {
    let built = PreviewLibrary.make(sessions: false, active: .finishing)
    let model = PreviewLibrary.finishingModel(built)
    FinishSessionView(model: model).previewEnvironment(built)
}

#Preview("S5/エラー（範囲の外）") {
    let built = PreviewLibrary.make(active: .finishing)
    let model = PreviewLibrary.finishingModel(built, pageText: "301", minutesText: "0")
    FinishSessionView(model: model).previewEnvironment(built)
}

#Preview("S5/エラー（保存の失敗）") {
    let built = PreviewLibrary.make(active: .finishing)
    let model = PreviewLibrary.finishingModel(built, pageText: "72", finishFailure: .save)
    FinishSessionView(model: model).previewEnvironment(built)
}

#Preview("S5/エラー（やめる保存の失敗）") {
    let built = PreviewLibrary.make(active: .finishing)
    let model = PreviewLibrary.finishingModel(built, pageText: "72", finishFailure: .cancel)
    FinishSessionView(model: model).previewEnvironment(built)
}

#Preview("S5/AX5") {
    let built = PreviewLibrary.make(active: .finishing)
    let model = PreviewLibrary.finishingModel(built)
    FinishSessionView(model: model)
        .previewEnvironment(built)
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("S5/ダーク") {
    let built = PreviewLibrary.make(active: .finishing)
    let model = PreviewLibrary.finishingModel(built)
    FinishSessionView(model: model)
        .previewEnvironment(built)
        .preferredColorScheme(.dark)
}
#endif
