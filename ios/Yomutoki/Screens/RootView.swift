import SwiftUI

/// 積む画面（design 1 の S3 と S4）。S4 は進行中の読書（1件だけ）を出すので、本の ID を持たない。
enum Route: Hashable {
    case book(UUID)
    case reading
}

/// 画面の積み方と、画面をまたいで渡す一時の値（どれも保存しない）。
@MainActor
@Observable
final class AppRouter {
    /// NavigationStack の積み方。置き換えの決まり（design 1）でスタックの中を見るので、型のある配列で持つ。
    var path: [Route] = []
    /// S2（本を追加）を出しているか。
    var isAddBookPresented = false
    /// S2 で追加した直後の S3 の本（その S3 を離れる前に読み始めたら start_source は after_add。design 1）。
    var afterAddBookID: UUID?
    /// 60秒未満で終えた直後の本（その S3 の先頭に session.finish.tooShort。AC-13、AC-51）。
    var tooShortBookID: UUID?
    /// S3 に出たときに1回だけ VoiceOver に知らせる文（session.saved.announcement か session.finish.tooShort）。
    var pendingAnnouncement: String?
    /// 追加の保存が通った本。S2 が閉じてから S3 を積む（AC-49、design 6 の (g)）。
    @ObservationIgnored private var pendingAddedBookID: UUID?

    init(path: [Route] = []) {
        self.path = path
    }

    /// S4 を積む（S1 の主操作、S3 の主操作と book.openActiveReading）。
    func openReading() {
        guard path.last != .reading else { return }
        path.append(.reading)
    }

    /// 追加の保存が通った（S2 を閉じる）。
    func bookAdded(_ bookID: UUID) {
        pendingAddedBookID = bookID
        isAddBookPresented = false
    }

    /// S2 が閉じた後（sheet の onDismiss）。追加した本の S3 を積む（スタック：S1 > S3）。
    func addBookSheetDismissed() {
        guard let bookID = pendingAddedBookID else { return }
        pendingAddedBookID = nil
        afterAddBookID = bookID
        path.append(.book(bookID))
    }

    /// S4 からその本の S3 へ（design 1 の置き換えの決まり）。スタックに同じ本の S3 があればそこまで戻り、なければ S4 を S3 に置き換える。
    func leaveReading(toBook bookID: UUID) {
        if let index = path.lastIndex(of: .book(bookID)) {
            path.removeSubrange(path.index(after: index)...)
        } else if let index = path.lastIndex(of: .reading) {
            path[index] = .book(bookID)
            path.removeSubrange(path.index(after: index)...)
        } else {
            path.append(.book(bookID))
        }
    }

    /// 起動と、読み込みのやり直しが通った後の分かれ道（design 1）。reading か paused なら S1 の上に S4、
    /// finishing なら S4 を積み、S4 が S5 を開く（ReadingModel.appeared）。idle なら S1 のまま。
    func restore(_ active: ActiveSnapshot?) {
        guard let active else { return }
        switch active.state {
        case .reading: path = [.reading]
        case .paused: path = [.reading]
        case .finishing: path = [.reading]
        }
    }
}

/// 根の View（S1 を根にした NavigationStack）。読み込みの3状態は S1 が出し分ける。
struct RootView: View {
    @Environment(LibraryStore.self) private var store
    @State private var router: AppRouter
    /// -UITest のときだけ true（YomutokiApp の #if DEBUG の中で渡す）。design 6 の (a) の代わりの案の 1pt の要素を置く。
    private let showsStateMarker: Bool

    init(showsStateMarker: Bool = false, router: AppRouter = AppRouter()) {
        self.showsStateMarker = showsStateMarker
        _router = State(initialValue: router)
    }

    /// 状態の名前（T8。design 6 の session.state.*）。S5 が出ている間も finishing。読み込み中と読み込みの失敗は idle。
    private var stateName: String {
        guard let active = store.active else { return "idle" }
        return active.state.rawValue
    }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .book(let bookID):
                        BookDetailView(bookID: bookID)
                    case .reading:
                        ReadingView(store: store, router: router, showsStateMarker: showsStateMarker)
                    }
                }
        }
        .sheet(isPresented: $router.isAddBookPresented, onDismiss: { router.addBookSheetDismissed() }) {
            AddBookView()
        }
        .onChange(of: store.loadState, initial: true) { _, state in
            switch state {
            case .loaded: router.restore(store.active)
            case .loading: break
            case .failed: router.path = []
            }
        }
        .overlay(alignment: .bottomLeading) { stateMarker }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("session.state.\(stateName)")
        .environment(router)
    }

    /// design 6 の (a) の代わりの案：-UITest のときだけ、画面の隅に 1pt の要素を置き、同じ session.state.* を付ける。
    @ViewBuilder private var stateMarker: some View {
        #if DEBUG
        if showsStateMarker {
            UITestMarker(identifier: "session.state.\(stateName)", label: "", value: "")
                .allowsHitTesting(false)
        }
        #endif
    }
}

#if DEBUG
#Preview("RootView/通常") {
    let built = PreviewLibrary.make()
    RootView(router: built.router).previewEnvironment(built)
}

#Preview("RootView/読書中を戻す") {
    let built = PreviewLibrary.make(active: .reading)
    RootView(router: built.router).previewEnvironment(built)
}

#Preview("RootView/終える入力を戻す") {
    let built = PreviewLibrary.make(active: .finishing)
    RootView(router: built.router).previewEnvironment(built)
}
#endif
