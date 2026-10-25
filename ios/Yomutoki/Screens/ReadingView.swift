import SwiftUI

/// 終える入力の下書き（contracts/data-model.md の「終える入力の下書き」。保存しない。SwiftData にも UserDefaults にも入れない）。
nonisolated struct FinishDraft: Equatable {
    var pageText = ""
    var minutesText = ""
    /// 分の欄の初めの値（finishedAt での経過の分。AC-30、AC-34）。
    var minutesInitial = 0
}

/// S4 のエラーの区画を出している操作（1画面に1つ。最後に失敗した操作。D-51、D-58）。
nonisolated enum ReadingFailure: Equatable {
    case pause
    case resume
    case finish
}

/// S5 のエラーの区画を出している操作（D-14、D-60）。
nonisolated enum FinishFailure: Equatable {
    case save
    case cancel
}

/// S4 読書中の画面のモデル（設計メモ 11 の 6、D-60）。終える入力の下書きと、S5 を出す Bool をシートの外に持つ。
/// 下へのスワイプでやめる保存に失敗したら、同じ値のままシートを開き直す。
@MainActor
@Observable
final class ReadingModel {
    let store: LibraryStore
    let router: AppRouter
    var draft = FinishDraft()
    var isFinishSheetPresented = false
    var failure: ReadingFailure?
    var finishFailure: FinishFailure?
    /// 初回復元と編集中の下書きを区別する。sheetを閉じている途中のS4再表示では作り直さない。
    private var hasFinishDraft = false

    init(store: LibraryStore, router: AppRouter, failure: ReadingFailure? = nil, finishFailure: FinishFailure? = nil) {
        self.store = store
        self.router = router
        self.failure = failure
        self.finishFailure = finishFailure
    }

    /// S4 が出たとき。finishing が残っていれば S5 を開く（起動して戻したとき。AC-34、D-25）。
    func appeared() {
        guard store.active?.state == .finishing, !isFinishSheetPresented, !hasFinishDraft else { return }
        openFinishSheet()
    }

    // MARK: S4 の操作

    func pause() {
        do {
            try store.pause()
            failure = nil
        } catch {
            fail(error, as: .pause)
        }
    }

    func resume() {
        do {
            try store.resume()
            failure = nil
        } catch {
            fail(error, as: .resume)
        }
    }

    /// 「終える」と「もう一度終える」（D-59：押した時点の経過で分ける）。
    func finish() {
        do {
            let outcome = try store.finish()
            failure = nil
            switch outcome {
            case .finishing:
                openFinishSheet()
            case .discarded(let bookID):
                router.tooShortBookID = bookID
                router.pendingAnnouncement = Loc.tooShortText
                router.leaveReading(toBook: bookID)
            }
        } catch {
            fail(error, as: .finish)
        }
    }

    private func fail(_ error: any Error, as operation: ReadingFailure) {
        guard Self.isSaveFailure(error) else { return }
        failure = operation
        Announce.saveFailed()
    }

    /// 下書きを作り直して S5 を開く。前にやめたときの値は残さない（AC-46、AC-47、D-4）。
    private func openFinishSheet() {
        let minutes = store.active?.initialMinutes ?? 0
        draft = FinishDraft(pageText: "", minutesText: String(minutes), minutesInitial: minutes)
        hasFinishDraft = true
        finishFailure = nil
        isFinishSheetPresented = true
    }

    // MARK: S5 の入力（design 7 の入力の決まり）

    var book: BookSnapshot? {
        guard let active = store.active else { return nil }
        return store.book(id: active.bookID)
    }

    /// 今のページの上限：総ページ数、未設定なら 9999（AC-11、AC-32）。
    var maxPage: Int {
        book?.totalPages ?? ReadingMath.pageRange.upperBound
    }

    var pageIsValid: Bool {
        switch NumberInput.parse(draft.pageText) {
        case .empty: true
        case .number(let page): (0...maxPage).contains(page)
        case .invalid: false
        }
    }

    /// 分の欄の値（1〜初めの値。AC-30）。
    var minutesValue: Int? {
        NumberInput.value(draft.minutesText, in: 1...max(1, draft.minutesInitial))
    }

    var canSave: Bool {
        pageIsValid && minutesValue != nil && store.active?.state == .finishing
    }

    // MARK: S5 の操作

    /// 「保存」とキーボードの上の「保存」と「もう一度保存」（AC-9〜AC-12、AC-19、AC-35、AC-50）。
    func saveSession(locale: Locale) {
        guard canSave, let minutes = minutesValue, let bookID = store.active?.bookID else { return }
        let endPage = NumberInput.value(draft.pageText, in: 0...maxPage)
        do {
            try store.finishSession(endPage: endPage, minutes: minutes)
            finishFailure = nil
            draft = FinishDraft()
            hasFinishDraft = false
            isFinishSheetPresented = false
            router.pendingAnnouncement = Loc.savedAnnouncement(minutes: minutes, locale: locale)
            router.leaveReading(toBook: bookID)
        } catch {
            guard Self.isSaveFailure(error) else { return }
            finishFailure = .save
            Announce.saveFailed()
        }
    }

    /// 「キャンセル」と「もう一度読書に戻る」：先に保存し、通ったときだけ閉じる（AC-46、AC-64、AC-65）。
    func cancelFinish() {
        do {
            try store.cancelFinish()
            finishFailure = nil
            draft = FinishDraft()
            hasFinishDraft = false
            isFinishSheetPresented = false
        } catch {
            guard Self.isSaveFailure(error) else { return }
            finishFailure = .cancel
            Announce.saveFailed()
        }
    }

    /// シートが閉じた後（sheet の onDismiss。下へのスワイプを含む）。まだ finishing なら下へのスワイプなので、やめる保存を呼ぶ。
    /// 失敗したら下書きを残したまま開き直し、先頭に error.saveFailed.cancel の区画を出す（AC-48、AC-64、D-60）。
    func finishSheetDismissed() {
        // 失敗で再提示したsheetに届く古い通知は、新しい取消操作として扱わない。
        guard !isFinishSheetPresented, store.active?.state == .finishing else { return }
        cancelFinish()
        if store.active?.state == .finishing {
            isFinishSheetPresented = true
        }
    }

    private static func isSaveFailure(_ error: any Error) -> Bool {
        guard let storeError = error as? StoreError, case .saveFailed = storeError else { return false }
        return true
    }
}

/// S4 読書中（design 1、3、5、6、8、9）。読んでいる間の経過を確かめ、一時停止するか終える。
struct ReadingView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.appClock) private var clock
    /// 時計が外から動かされた回数（Debug の T16 だけが増やす）。読むと、止めた時計でも AppClock の値で描き直す。
    @Environment(\.appClockRevision) private var clockRevision
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var model: ReadingModel

    init(store: LibraryStore, router: AppRouter, failure: ReadingFailure? = nil) {
        _model = State(initialValue: ReadingModel(store: store, router: router, failure: failure))
    }

    var body: some View {
        @Bindable var model = model
        Group {
            if let active = store.active, let book = store.book(id: active.bookID) {
                content(active: active, book: book)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.screenBackground)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.appeared() }
        .sheet(isPresented: $model.isFinishSheetPresented, onDismiss: { model.finishSheetDismissed() }) {
            FinishSessionView(model: model)
        }
    }

    @ViewBuilder
    private func content(active: ActiveSnapshot, book: BookSnapshot) -> some View {
        if typeSize.isAccessibilitySize {
            // AX サイズ：全体を ScrollView に入れ、上に「終える」、下に「一時停止」（design 9）。
            ScrollView {
                VStack(spacing: 0) {
                    header(book)
                    elapsedBlock(active)
                    VStack(spacing: Space.m) {
                        finishButton(active)
                        leftButton(active)
                    }
                    .padding(.top, Space.xl)
                }
                .padding(Space.m)
            }
        } else {
            VStack(spacing: 0) {
                Spacer(minLength: Space.m)
                header(book)
                elapsedBlock(active)
                Spacer(minLength: Space.xl)
                // 幅が足りなければ縦並び（design 9 の英語が長くなったとき）。
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Space.m) {
                        leftButton(active)
                        finishButton(active)
                    }
                    VStack(spacing: Space.m) {
                        finishButton(active)
                        leftButton(active)
                    }
                }
            }
            .padding(Space.m)
        }
    }

    private func header(_ book: BookSnapshot) -> some View {
        VStack(spacing: Space.s) {
            Text(verbatim: book.title)
                .font(.title3)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("reading.title")
            if book.lastPage > 0 {
                Text(verbatim: Loc.fromPage(book.lastPage))
                    .font(.subheadline)
                    .accessibilityIdentifier("reading.fromPage")
            }
        }
        .foregroundStyle(Color.primary)
    }

    private func elapsedBlock(_ active: ActiveSnapshot) -> some View {
        let stateKey: LocalizedStringKey = active.state == .paused ? "reading.state.paused" : "reading.state.reading"
        return VStack(spacing: Space.s) {
            // 刻みは端末の時刻で動くので、起点も端末の今にする（startedAt は AppClock の時刻で、先の時刻だと刻みが始まらない）。
            // 表示する経過は AppClock の今で計算し、止めた時計の描き直しは clockRevision で行う。
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                elapsedText(seconds: elapsedSeconds(active, revision: clockRevision), paused: active.state == .paused)
            }
            Text(stateKey)
                .font(.subheadline)
                .foregroundStyle(Color.primary)
                .accessibilityIdentifier("reading.state")
            if let failure = model.failure {
                errorArea(failure)
                    .padding(.top, Space.m - Space.s)
            }
        }
        .padding(.top, Space.l)
    }

    /// 経過は開始の時刻から AppClock の今で計算し直す（AC-7、AC-41：時計が戻っても負にしない）。
    private func elapsedSeconds(_ active: ActiveSnapshot, revision _: Int) -> Int {
        active.elapsedSeconds(now: clock.now())
    }

    /// 経過（type.timer：.largeTitle と等幅の数字。動きを付けない。D-22）。label は読み上げの形、value は付けない（design 6）。
    private func elapsedText(seconds: Int, paused: Bool) -> some View {
        Text(verbatim: ElapsedFormat.clock(seconds))
            .font(.largeTitle.monospacedDigit())
            .foregroundStyle(paused ? Color.secondary : Color.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .accessibilityLabel(Text(verbatim: Loc.elapsed(seconds, locale: locale)))
            .accessibilityIdentifier("reading.elapsed")
            .onAppear { PerfSignpost.endFirstElapsedShown() }
    }

    /// エラーの区画（状態の文字とボタンの間。D-51、D-58）。
    private func errorArea(_ failure: ReadingFailure) -> some View {
        let identifier: String =
            switch failure {
            case .pause: "error.saveFailed.pause"
            case .resume: "error.saveFailed.resume"
            case .finish: "error.saveFailed.finish"
            }
        return VStack(alignment: .leading, spacing: Space.xxs) {
            SaveFailedTitle()
            Text(LocalizedStringKey(identifier))
                .font(.subheadline)
                .foregroundStyle(Color.primary)
                .accessibilityIdentifier(identifier)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 左のボタン：一時停止か再開。失敗した間は同じ場所と形の error.retry（D-51）。
    @ViewBuilder private func leftButton(_ active: ActiveSnapshot) -> some View {
        switch active.state {
        case .reading:
            if model.failure == .pause {
                wideButton("error.retry.pause", identifier: "error.retry") { model.pause() }
                    .secondaryBorderedButton()
            } else {
                wideButton("reading.pause", identifier: "reading.pause") { model.pause() }
                    .secondaryBorderedButton()
            }
        case .paused:
            if model.failure == .resume {
                wideButton("error.retry.resume", identifier: "error.retry") { model.resume() }
                    .secondaryBorderedButton()
            } else {
                wideButton("reading.resume", identifier: "reading.resume") { model.resume() }
                    .secondaryBorderedButton()
            }
        case .finishing:
            // S5 が上に出ている間。押せない。
            wideButton("reading.pause", identifier: "reading.pause") {}
                .secondaryBorderedButton()
                .disabled(true)
        }
    }

    /// 右のボタン：「終える」。失敗した間は同じ場所と形（.borderedProminent）の error.retry「もう一度終える」（D-58）。
    @ViewBuilder private func finishButton(_ active: ActiveSnapshot) -> some View {
        if model.failure == .finish {
            wideButton("error.retry.finish", identifier: "error.retry") { model.finish() }
                .accentProminentButton()
        } else {
            wideButton("reading.finish", identifier: "reading.finish") { model.finish() }
                .accentProminentButton()
                .disabled(active.state == .finishing)
        }
    }

    private func wideButton(_ key: LocalizedStringKey, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(key)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .accessibilityIdentifier(identifier)
    }
}

#if DEBUG
#Preview("S4/通常（読書中）") {
    let built = PreviewLibrary.make(active: .reading)
    NavigationStack { ReadingView(store: built.store, router: built.router) }.previewEnvironment(built)
}

#Preview("S4/通常（一時停止中）") {
    let built = PreviewLibrary.make(active: .paused)
    NavigationStack { ReadingView(store: built.store, router: built.router) }.previewEnvironment(built)
}

#Preview("S4/エラー（一時停止の保存の失敗）") {
    let built = PreviewLibrary.make(active: .reading)
    NavigationStack { ReadingView(store: built.store, router: built.router, failure: .pause) }
        .previewEnvironment(built)
}

#Preview("S4/エラー（再開の保存の失敗）") {
    let built = PreviewLibrary.make(active: .paused)
    NavigationStack { ReadingView(store: built.store, router: built.router, failure: .resume) }
        .previewEnvironment(built)
}

#Preview("S4/エラー（終えるの保存の失敗）") {
    let built = PreviewLibrary.make(active: .reading)
    NavigationStack { ReadingView(store: built.store, router: built.router, failure: .finish) }
        .previewEnvironment(built)
}

#Preview("S4/AX5") {
    let built = PreviewLibrary.make(active: .reading)
    NavigationStack { ReadingView(store: built.store, router: built.router, failure: .finish) }
        .previewEnvironment(built)
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("S4/ダーク") {
    let built = PreviewLibrary.make(active: .paused)
    NavigationStack { ReadingView(store: built.store, router: built.router) }
        .previewEnvironment(built)
        .preferredColorScheme(.dark)
}
#endif
