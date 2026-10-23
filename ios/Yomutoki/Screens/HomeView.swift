import SwiftUI

/// S1 ホーム（design 1、3、5、6、9）。前の本の続きを1回で読み始め、今週読んだ時間と本の一覧を見る。
struct HomeView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.appClock) private var clock
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var typeSize
    /// 読み始めの保存に失敗した（AC-56）。S1 を離れると消える。
    @State private var startFailed: Bool
    /// 読み込みが1秒を超えたら ProgressView を足す（D-39、PRD 12 の線）。
    @State private var showsLoadingIndicator = false

    init(startFailed: Bool = false) {
        _startFailed = State(initialValue: startFailed)
    }

    var body: some View {
        content
            .navigationTitle(Text("home.title"))
            .toolbar {
                if store.loadState == .loaded, !store.books.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            router.isAddBookPresented = true
                        } label: {
                            Label("library.addBook", systemImage: "plus")
                        }
                        .accessibilityIdentifier("library.addBook")
                    }
                }
            }
            .onChange(of: router.path) { _, path in
                if !path.isEmpty { startFailed = false }
            }
    }

    @ViewBuilder private var content: some View {
        switch store.loadState {
        case .loading:
            loadingView
        case .failed:
            loadFailedView
        case .loaded:
            if store.books.isEmpty {
                emptyView
            } else {
                libraryList
            }
        }
    }

    // MARK: 読み込み中（形を先に出し、「0分」「0冊」と空の状態は出さない）

    private var loadingView: some View {
        List {
            Section {
                LabeledContent {
                    Text(verbatim: "00")
                } label: {
                    Text("home.weekTotal.label")
                }
            }
            Section {
                ForEach(0..<3, id: \.self) { _ in
                    Text("library.empty.title")
                }
            }
        }
        .listStyle(.insetGrouped)
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
        .overlay {
            if showsLoadingIndicator {
                ProgressView {
                    Text("common.loading")
                        .foregroundStyle(Color.primary)
                }
                .accessibilityIdentifier("home.loading")
            }
        }
        .task {
            do {
                try await Task.sleep(for: .seconds(1))
                showsLoadingIndicator = true
            } catch {
                // 画面が消えて止まった。何もしない。
            }
        }
    }

    // MARK: 読み込みの失敗（AC-54、AC-55、D-44）

    private var loadFailedView: some View {
        ContentUnavailableView {
            Label {
                Text("error.loadFailed.title")
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("error.loadFailed.title")
            } icon: {
                Image(systemName: "exclamationmark.triangle")
                    .accessibilityHidden(true)
            }
        } description: {
            Text("error.loadFailed.message")
                .foregroundStyle(Color.primary)
                .accessibilityIdentifier("error.loadFailed.message")
        } actions: {
            Button {
                store.retryLoad()
            } label: {
                Text("error.loadFailed.retry")
            }
            .accentProminentButton()
            .controlSize(.large)
            .accessibilityIdentifier("error.loadFailed.retry")
        }
    }

    // MARK: 本が0冊（AC-1、D-19）

    private var emptyView: some View {
        ContentUnavailableView {
            Label {
                Text("library.empty.title")
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("library.empty.title")
            } icon: {
                Image(systemName: "books.vertical")
                    .accessibilityHidden(true)
            }
        } description: {
            Text("library.empty.message")
                .foregroundStyle(Color.primary)
                .accessibilityIdentifier("library.empty.message")
        } actions: {
            Button {
                router.isAddBookPresented = true
            } label: {
                Text("library.addBook")
            }
            .accentProminentButton()
            .controlSize(.large)
            .accessibilityIdentifier("library.addBook")
        }
    }

    // MARK: 通常（本が1冊以上）

    private var libraryList: some View {
        List {
            if typeSize.isAccessibilitySize {
                Section {
                    primaryArea
                }
            }
            Section {
                StatRow(
                    label: "home.weekTotal.label",
                    value: Loc.minutes(store.weekTotalMinutes(now: clock.now()), locale: locale),
                    identifier: "home.weekTotal")
            }
            Section {
                ForEach(store.books) { book in
                    NavigationLink(value: Route.book(book.id)) {
                        Text(verbatim: book.title)
                            .lineLimit(3)
                            .foregroundStyle(Color.primary)
                    }
                    .accessibilityIdentifier("library.book.\(book.id.uuidString.lowercased())")
                }
            } header: {
                Text(verbatim: Loc.bookCount(store.books.count, locale: locale))
                    .font(.footnote)
                    .foregroundStyle(Color.primary)
                    .textCase(nil)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("home.bookCount")
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            if !typeSize.isAccessibilitySize {
                primaryArea.bottomActionBar()
            }
        }
    }

    // MARK: 下端の主操作（D-7、D-8。3 の逸脱：中身は標準の Button と .borderedProminent）

    @ViewBuilder private var primaryArea: some View {
        if let active = store.active, let book = store.book(id: active.bookID) {
            primaryButton(title: book.title, action: Loc.resumeAction(for: active.state), identifier: "home.resumeReading") {
                router.openReading()
            }
        } else if let bookID = store.previousBookID, let book = store.book(id: bookID) {
            if startFailed {
                VStack(alignment: .leading, spacing: Space.xs) {
                    VStack(alignment: .leading, spacing: Space.xxs) {
                        SaveFailedTitle()
                        Text("error.saveFailed.start")
                            .font(.footnote)
                            .foregroundStyle(Color.primary)
                            .accessibilityIdentifier("error.saveFailed.start")
                    }
                    primaryButton(title: book.title, action: Loc.retryStartText, identifier: "error.retry") {
                        start(bookID)
                    }
                }
            } else {
                primaryButton(title: book.title, action: Loc.startAction(for: book), identifier: "home.startReading") {
                    start(bookID)
                }
            }
        }
    }

    /// 2行の主操作（1行目は題名を2行まで、2行目は操作の文）。VoiceOver のラベルは home.primary.a11y（題名が先頭）。
    private func primaryButton(
        title: String, action actionText: String, identifier: String, perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(verbatim: title)
                    .font(.headline)
                    .lineLimit(2)
                Text(verbatim: actionText)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accentProminentButton()
        .controlSize(.large)
        .accessibilityLabel(Text(verbatim: Loc.homePrimary(title: title, action: actionText)))
        .accessibilityIdentifier(identifier)
    }

    /// 読み始める（AC-5、AC-25、AC-26、AC-56、AC-57）。計測の start_source は home（イベントは保存の層が出す）。
    private func start(_ bookID: UUID) {
        PerfSignpost.beginFirstElapsedShown()
        do {
            try store.startReading(bookID: bookID, source: .home)
            startFailed = false
            router.openReading()
        } catch let error as StoreError {
            PerfSignpost.discardFirstElapsedShown()
            if case .saveFailed = error {
                startFailed = true
                Announce.saveFailed()
            }
        } catch {
            PerfSignpost.discardFirstElapsedShown()
        }
    }
}

#if DEBUG
#Preview("S1/通常") {
    let built = PreviewLibrary.make()
    NavigationStack { HomeView() }.previewEnvironment(built)
}

#Preview("S1/通常（読書中）") {
    let built = PreviewLibrary.make(active: .paused)
    NavigationStack { HomeView() }.previewEnvironment(built)
}

#Preview("S1/空") {
    let built = PreviewLibrary.make(books: false)
    NavigationStack { HomeView() }.previewEnvironment(built)
}

#Preview("S1/読み込み中") {
    let built = PreviewLibrary.make(load: false)
    NavigationStack { HomeView() }.previewEnvironment(built)
}

#Preview("S1/エラー（読み込みの失敗）") {
    let built = PreviewLibrary.make(failLoad: true)
    NavigationStack { HomeView() }.previewEnvironment(built)
}

#Preview("S1/エラー（読み始めの保存の失敗）") {
    let built = PreviewLibrary.make()
    NavigationStack { HomeView(startFailed: true) }.previewEnvironment(built)
}

#Preview("S1/AX5") {
    let built = PreviewLibrary.make()
    NavigationStack { HomeView() }
        .previewEnvironment(built)
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("S1/ダーク") {
    let built = PreviewLibrary.make()
    NavigationStack { HomeView() }
        .previewEnvironment(built)
        .preferredColorScheme(.dark)
}
#endif
