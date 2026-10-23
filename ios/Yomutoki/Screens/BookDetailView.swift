import SwiftUI

/// S3 本の詳細（design 1、3、5、6、9）と、S6（記録を消す確認）と S7（記録を消せなかった知らせ）の alert。
/// その本の合計と記録を確かめ、その本で読み始める。
struct BookDetailView: View {
    let bookID: UUID
    @Environment(LibraryStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.appClock) private var clock
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var typeSize
    /// 読み始めの保存に失敗した（AC-56）。S3 を離れると消える。
    @State private var startFailed: Bool
    /// S6 で消そうとしている記録。
    @State private var pendingDelete: SessionSnapshot?
    @State private var isDeleteConfirmPresented: Bool
    @State private var isDeleteFailedPresented: Bool
    /// 読み込みが1秒を超えたら ProgressView を足す（D-39。S1 と同じ作り）。
    @State private var showsLoadingIndicator = false

    init(
        bookID: UUID, startFailed: Bool = false, pendingDelete: SessionSnapshot? = nil, deleteFailed: Bool = false
    ) {
        self.bookID = bookID
        _startFailed = State(initialValue: startFailed)
        _pendingDelete = State(initialValue: pendingDelete)
        _isDeleteConfirmPresented = State(initialValue: pendingDelete != nil)
        _isDeleteFailedPresented = State(initialValue: deleteFailed)
    }

    var body: some View {
        content
            .navigationTitle(Text(verbatim: store.book(id: bookID)?.title ?? ""))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: announcePending)
            .onDisappear(perform: leave)
            .alert(Text("session.delete.title"), isPresented: $isDeleteConfirmPresented, presenting: pendingDelete) { session in
                Button(role: .cancel) {
                    pendingDelete = nil
                } label: {
                    Text("common.cancel")
                }
                .accessibilityIdentifier("session.delete.cancel")
                Button {
                    delete(session)
                } label: {
                    Text("session.delete.confirm")
                }
                .accessibilityIdentifier("session.delete.confirm")
            } message: { session in
                Text(verbatim: Loc.deleteMessage(minutes: session.minutes, locale: locale))
            }
            .alert(Text("error.saveFailed"), isPresented: $isDeleteFailedPresented) {
                Button(role: .cancel) {
                } label: {
                    Text("common.ok")
                }
            } message: {
                Text("error.saveFailed.delete")
            }
    }

    @ViewBuilder private var content: some View {
        switch store.loadState {
        case .loading:
            loadingView
        case .failed:
            loadFailedView
        case .loaded:
            if let book = store.book(id: bookID) {
                detail(book)
            } else {
                Color.clear
            }
        }
    }

    // MARK: 読み込み中と読み込みの失敗（S1 と同じ考え。主操作と「編集」は出さない）

    private var loadingView: some View {
        List {
            Section {
                ForEach(0..<3, id: \.self) { _ in
                    Text("book.stat.totalTime")
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

    // MARK: 通常と空

    private func detail(_ book: BookSnapshot) -> some View {
        let sessions = store.sessions(for: book.id)
        let now = clock.now()
        return List {
            Section {
                Text(verbatim: book.title)
                    .font(.title2.bold())
                    .foregroundStyle(Color.primary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("book.title")
                if router.tooShortBookID == book.id {
                    Text("session.finish.tooShort")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary)
                        .accessibilityIdentifier("session.finish.tooShort")
                }
                if typeSize.isAccessibilitySize {
                    primaryArea(book)
                }
            }
            Section {
                StatRow(label: "book.stat.lastPage", value: String(book.lastPage), identifier: "book.lastPage")
                if let totalPages = book.totalPages, let percent = book.progressPercent {
                    StatRow(
                        label: "book.stat.progress", value: Loc.percent(percent, locale: locale), identifier: "book.progress")
                    StatRow(label: "book.stat.totalPages", value: String(totalPages), identifier: "book.totalPages")
                }
                StatRow(
                    label: "book.stat.totalTime", value: Loc.minutes(book.totalMinutes, locale: locale),
                    identifier: "book.totalTime")
            }
            Section {
                if sessions.isEmpty {
                    Text("book.sessions.empty")
                        .foregroundStyle(Color.primary)
                        .accessibilityIdentifier("book.sessions.empty")
                } else {
                    ForEach(sessions) { session in
                        SessionRow(session: session, now: now, calendar: calendar, locale: locale)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    requestDelete(session)
                                } label: {
                                    Label("session.row.delete", systemImage: "trash")
                                }
                                .accessibilityIdentifier("session.row.delete")
                            }
                    }
                    .onDelete { offsets in
                        if let index = offsets.first, sessions.indices.contains(index) {
                            requestDelete(sessions[index])
                        }
                    }
                }
            } header: {
                Text(verbatim: Loc.sessionCount(book.sessionCount, locale: locale))
                    .font(.footnote)
                    .foregroundStyle(Color.primary)
                    .textCase(nil)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("book.sessionCount")
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            if !sessions.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                        .accessibilityIdentifier("book.edit")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !typeSize.isAccessibilitySize {
                primaryArea(book).bottomActionBar()
            }
        }
    }

    // MARK: 下端の主操作（S1 と同じ置き場所。D-33、D-51）

    @ViewBuilder private func primaryArea(_ book: BookSnapshot) -> some View {
        if let active = store.active {
            if active.bookID == book.id {
                Button {
                    router.openReading()
                } label: {
                    Text(verbatim: Loc.resumeAction(for: active.state))
                        .frame(maxWidth: .infinity)
                }
                .accentProminentButton()
                .controlSize(.large)
                .accessibilityIdentifier("book.resumeReading")
            } else {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text(verbatim: Loc.startBusy(title: store.book(id: active.bookID)?.title ?? ""))
                        .font(.footnote)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("book.start.busy")
                    Button {
                        router.openReading()
                    } label: {
                        Text(verbatim: Loc.resumeAction(for: active.state))
                            .frame(maxWidth: .infinity)
                    }
                    .secondaryBorderedButton()
                    .controlSize(.large)
                    .accessibilityIdentifier("book.openActiveReading")
                    Button {
                    } label: {
                        Text(verbatim: Loc.startAction(for: book))
                            .frame(maxWidth: .infinity)
                    }
                    .accentProminentButton()
                    .controlSize(.large)
                    .disabled(true)
                    .accessibilityIdentifier("book.startReading")
                }
            }
        } else if startFailed {
            VStack(alignment: .leading, spacing: Space.xs) {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    SaveFailedTitle()
                    Text("error.saveFailed.start")
                        .font(.footnote)
                        .foregroundStyle(Color.primary)
                        .accessibilityIdentifier("error.saveFailed.start")
                }
                Button {
                    start(book.id)
                } label: {
                    Text("error.retry.start")
                        .frame(maxWidth: .infinity)
                }
                .accentProminentButton()
                .controlSize(.large)
                .accessibilityIdentifier("error.retry")
            }
        } else {
            Button {
                start(book.id)
            } label: {
                Text(verbatim: Loc.startAction(for: book))
                    .frame(maxWidth: .infinity)
            }
            .accentProminentButton()
            .controlSize(.large)
            .accessibilityIdentifier("book.startReading")
        }
    }

    // MARK: 操作

    /// 読み始める。S2 で追加した直後の S3 からなら start_source は after_add、ほかは book_detail（design 1）。
    private func start(_ bookID: UUID) {
        PerfSignpost.beginFirstElapsedShown()
        let source: StartSource = router.afterAddBookID == bookID ? .afterAdd : .bookDetail
        do {
            try store.startReading(bookID: bookID, source: source)
            startFailed = false
            router.afterAddBookID = nil
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

    /// 行のスワイプか「編集」の「削除」→ S6（D-16、D-17）。
    private func requestDelete(_ session: SessionSnapshot) {
        pendingDelete = session
        isDeleteConfirmPresented = true
    }

    /// S6 の「記録を消す」。失敗したら S6 が閉じてから S7（AC-43）。
    private func delete(_ session: SessionSnapshot) {
        pendingDelete = nil
        do {
            try store.deleteSession(id: session.id)
        } catch {
            isDeleteFailedPresented = true
        }
    }

    private func announcePending() {
        guard let text = router.pendingAnnouncement else { return }
        router.pendingAnnouncement = nil
        Announce.post(text)
    }

    /// S3 を離れたら、読み始めの失敗の区画、60秒未満の知らせ、追加した直後の印を消す（design 5）。
    private func leave() {
        startFailed = false
        if router.tooShortBookID == bookID { router.tooShortBookID = nil }
        if router.afterAddBookID == bookID { router.afterAddBookID = nil }
    }
}

/// 記録の行（design 6：入れ物 session.row.id.<UUID> の中に日付、分、ページ。ページは入れた記録だけ）。
/// 分とページは label で読む（value は付けない）。AX サイズでは3つを縦に並べる（design 9）。
private struct SessionRow: View {
    let session: SessionSnapshot
    let now: Date
    let calendar: Calendar
    let locale: Locale
    @Environment(\.dynamicTypeSize) private var typeSize

    init(session: SessionSnapshot, now: Date, calendar: Calendar, locale: Locale) {
        self.session = session
        self.now = now
        self.calendar = calendar
        self.locale = locale
    }

    /// 端末の書式（月と日、時と分。今年でなければ年も。design 7）。
    private var dateText: String {
        var style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .month().day().hour().minute()
        if calendar.component(.year, from: session.startedAt) != calendar.component(.year, from: now) {
            style = style.year()
        }
        return session.startedAt.formatted(style)
    }

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    date
                    minutes
                    pages
                }
            } else {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    date
                    HStack(spacing: Space.xs) {
                        minutes
                        pages
                    }
                }
            }
        }
        .foregroundStyle(Color.primary)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("session.row.id.\(session.id.uuidString.lowercased())")
    }

    private var date: some View {
        Text(verbatim: dateText)
            .font(.subheadline)
            .accessibilityIdentifier("session.row.date")
    }

    private var minutes: some View {
        Text(verbatim: Loc.minutes(session.minutes, locale: locale))
            .font(.body.monospacedDigit())
            .accessibilityIdentifier("session.row.minutes")
    }

    @ViewBuilder private var pages: some View {
        if session.endPage != nil, let pagesRead = session.pagesRead {
            Text(verbatim: Loc.pagesRead(pagesRead))
                .font(.body)
                .accessibilityIdentifier("session.row.page")
        }
    }
}

#if DEBUG
#Preview("S3/通常") {
    let built = PreviewLibrary.make()
    NavigationStack {
        if let bookID = built.botchan { BookDetailView(bookID: bookID) }
    }
    .previewEnvironment(built)
}

#Preview("S3/空") {
    let built = PreviewLibrary.make(sessions: false)
    NavigationStack {
        if let bookID = built.kokoro { BookDetailView(bookID: bookID) }
    }
    .previewEnvironment(built)
}

#Preview("S3/読み込み中") {
    let built = PreviewLibrary.make(load: false)
    NavigationStack { BookDetailView(bookID: PreviewLibrary.missingBookID) }.previewEnvironment(built)
}

#Preview("S3/エラー（読み込みの失敗）") {
    let built = PreviewLibrary.make(failLoad: true)
    NavigationStack { BookDetailView(bookID: PreviewLibrary.missingBookID) }.previewEnvironment(built)
}

#Preview("S3/エラー（読み始めの保存の失敗）") {
    let built = PreviewLibrary.make()
    NavigationStack {
        if let bookID = built.botchan { BookDetailView(bookID: bookID, startFailed: true) }
    }
    .previewEnvironment(built)
}

#Preview("S3/別の本が読書中") {
    let built = PreviewLibrary.make(active: .paused)
    NavigationStack {
        if let bookID = built.kokoro { BookDetailView(bookID: bookID) }
    }
    .previewEnvironment(built)
}

#Preview("S6/通常（記録を消す確認）") {
    let built = PreviewLibrary.make()
    NavigationStack {
        if let bookID = built.botchan {
            BookDetailView(bookID: bookID, pendingDelete: built.store.sessions(for: bookID).first)
        }
    }
    .previewEnvironment(built)
}

#Preview("S7/通常（記録を消せなかった知らせ）") {
    let built = PreviewLibrary.make()
    NavigationStack {
        if let bookID = built.botchan { BookDetailView(bookID: bookID, deleteFailed: true) }
    }
    .previewEnvironment(built)
}

#Preview("S3/AX5") {
    let built = PreviewLibrary.make()
    NavigationStack {
        if let bookID = built.botchan { BookDetailView(bookID: bookID) }
    }
    .previewEnvironment(built)
    .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("S3/ダーク") {
    let built = PreviewLibrary.make()
    NavigationStack {
        if let bookID = built.botchan { BookDetailView(bookID: bookID) }
    }
    .previewEnvironment(built)
    .preferredColorScheme(.dark)
}
#endif
