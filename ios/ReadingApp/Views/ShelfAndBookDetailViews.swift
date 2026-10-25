import SwiftUI
import ReadingCore
import ReadingStore

public enum ShelfListViewState: Equatable, Sendable {
    case empty
    case populated(current: BookSnapshot?, tsundoku: [BookSnapshot], finished: [BookSnapshot])
}

public struct ShelfListView: View {
    @Bindable var model: ReadingAppModel
    public let previewState: ShelfListViewState?

    public init(model: ReadingAppModel, previewState: ShelfListViewState? = nil) {
        self.model = model
        self.previewState = previewState
    }

    private var resolvedState: ShelfListViewState {
        if let previewState { return previewState }
        if model.store.books.isEmpty {
            return .empty
        }
        return .populated(
            current: model.store.currentBook,
            tsundoku: model.store.tsundokuBooks,
            finished: model.store.finishedBooks
        )
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                BannerNoticeView(model: model)

                switch resolvedState {
                case .empty:
                    VStack(spacing: 12) {
                        Text("まだ本が登録されていません")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                case .populated(let current, let tsundoku, let finished):
                    if let current {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("いま読んでいる")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("shelf.section.current")

                            shelfBookButton(book: current, identifier: "shelf.current.0")
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("積読（\(tsundoku.count)）")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("shelf.section.tsundoku")

                        ForEach(Array(tsundoku.enumerated()), id: \.element.id) { idx, book in
                            shelfBookButton(book: book, identifier: "shelf.tsundoku.\(idx)")
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("読み終えた（\(finished.count)）")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("shelf.section.finished")

                        ForEach(Array(finished.enumerated()), id: \.element.id) { idx, book in
                            shelfBookButton(book: book, identifier: "shelf.finished.\(idx)")
                        }
                    }
                }
            }
            .padding(20)
        }
        .accessibilityIdentifier("screen.shelf")
        .navigationTitle("本棚")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.currentScreen = .bookAddActionSheet
                    model.activeSheet = .addBook(titlePendingMode: false)
                    model.notifyHookChanged()
                } label: {
                    Label("本を登録", systemImage: "plus")
                }
                .accessibilityIdentifier("shelf.addBook")
            }
        }
        .onAppear {
            _ = model.store.clock.endInterval(.shelfOpen)
            model.activeTab = .shelf
            model.currentScreen = .shelfList
            model.notifyHookChanged()
        }
    }

    private func shelfBookButton(book: BookSnapshot, identifier: String) -> some View {
        let displayTitle = book.isTitlePending ? "あとで書名を入れる本" : book.title
        return Button {
            model.store.clock.beginInterval(.bookOpen)
            model.currentScreen = .bookDetail
            model.navigationPath.append(.bookDetail(book.id))
            model.notifyHookChanged()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayTitle)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if !book.author.isEmpty {
                        Text(book.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(displayTitle)
        .accessibilityValue(displayTitle)
    }
}

public enum BookDetailSheetKind: Identifiable, Equatable, Sendable {
    case editBook
    case editRecord(UUID)
    case shareCard
    case colophonOCR

    public var id: String {
        switch self {
        case .editBook: return "editBook"
        case .editRecord(let rId): return "editRecord-\(rId.uuidString)"
        case .shareCard: return "shareCard"
        case .colophonOCR: return "colophonOCR"
        }
    }
}

public struct BookDetailView: View {
    @Bindable var model: ReadingAppModel
    public let bookId: UUID
    @State private var detailSheet: BookDetailSheetKind?
    @State private var showDeleteBookConfirm = false
    @State private var recordIdPendingDelete: UUID?

    public init(model: ReadingAppModel, bookId: UUID) {
        self.model = model
        self.bookId = bookId
    }

    private var book: BookSnapshot? {
        model.store.books.first { $0.id == bookId }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BannerNoticeView(model: model)

                if let book {
                    bookHeaderSection(book: book)
                    bookActionsSection(book: book)
                    afterCandidatesSection(book: book)
                    recordsSection(book: book)
                }
            }
            .padding(20)
        }
        .accessibilityIdentifier("screen.bookDetail")
        .navigationTitle(book?.title ?? "本の詳細")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $detailSheet) { sheet in
            switch sheet {
            case .editBook:
                if let book {
                    BookEditSheetView(model: model, book: book) {
                        detailSheet = nil
                        model.currentScreen = .bookDetail
                        model.notifyHookChanged()
                    }
                }
            case .editRecord(let recId):
                if let rec = model.store.records.first(where: { $0.id == recId }) {
                    RecordEditSheetView(model: model, record: rec) {
                        detailSheet = nil
                        model.currentScreen = .bookDetail
                        model.notifyHookChanged()
                    }
                }
            case .shareCard:
                if let book {
                    ShareCardPreviewSheetView(model: model, book: book) {
                        detailSheet = nil
                        model.currentScreen = .bookDetail
                        model.notifyHookChanged()
                    }
                }
            case .colophonOCR:
                ColophonOCRSheetView(model: model, bookId: bookId) {
                    detailSheet = nil
                    model.currentScreen = .bookDetail
                    model.notifyHookChanged()
                }
            }
        }
        .onAppear {
            _ = model.store.clock.endInterval(.bookOpen)
            model.currentScreen = .bookDetail
            model.notifyHookChanged()
        }
    }

    private func bookHeaderSection(book: BookSnapshot) -> some View {
        let displayTitle = book.isTitlePending ? "あとで書名を入れる本" : book.title
        let nights = model.store.distinctNightCount(for: book.id)
        let mins = model.store.totalMinutes(for: book.id)
        let summaryText = "\(nights)晩・\(mins)分"
        let reflection = (book.status == .finished) ? model.store.buildFinishReflection(for: book.id) : nil

        return VStack(alignment: .leading, spacing: 8) {
            Text(displayTitle)
                .font(.title2.bold())
                .accessibilityIdentifier("book.detail.title")
                .accessibilityLabel(displayTitle)
                .accessibilityValue(displayTitle)

            if !book.author.isEmpty {
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("book.detail.author")
                    .accessibilityLabel(book.author)
                    .accessibilityValue(book.author)
            }

            if let publisher = book.publisher, !publisher.isEmpty {
                Text(publisher)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("book.detail.publisher")
            }

            Text(summaryText)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("book.detail.summary")
                .accessibilityLabel(summaryText)
                .accessibilityValue(summaryText)

            if let reflection {
                Text(reflection)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .accessibilityIdentifier("book.reflection")
                    .accessibilityLabel(reflection)
                    .accessibilityValue(reflection)
            }

            HStack(spacing: 12) {
                Text("電子書籍")
                    .font(.subheadline)
                Spacer()
                Toggle("電子書籍", isOn: Binding(
                    get: { book.isEbook },
                    set: { newVal in
                        let newUnit: ProgressUnit = newVal ? (book.progressUnit == .page ? .location : book.progressUnit) : .page
                        _ = model.store.updateBook(
                            bookId: book.id,
                            title: book.title,
                            author: book.author,
                            isEbook: newVal,
                            progressUnit: newUnit
                        )
                        model.notifyHookChanged()
                    }
                ))
                .labelsHidden()
                .accessibilityIdentifier("book.ebookToggle")
            }
            .padding(.top, 8)

            HStack(spacing: 8) {
                unitButton(book: book, unit: .page, title: "ページ", id: "book.unit.page")
                unitButton(book: book, unit: .location, title: "Loc", id: "book.unit.location")
                unitButton(book: book, unit: .percent, title: "%", id: "book.unit.percent")
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func unitButton(book: BookSnapshot, unit: ProgressUnit, title: String, id: String) -> some View {
        let isSelected = (book.progressUnit == unit)
        return Button {
            _ = model.store.updateBook(
                bookId: book.id,
                title: book.title,
                author: book.author,
                isEbook: unit != .page ? true : book.isEbook,
                progressUnit: unit
            )
            model.notifyHookChanged()
        } label: {
            Text(title)
                .font(.caption.weight(isSelected ? .bold : .regular))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : .secondary)
        .accessibilityIdentifier(id)
    }

    private func bookActionsSection(book: BookSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !book.status.isCurrentReading {
                Button {
                    if model.store.switchToCurrentBook(bookId: book.id) {
                        model.navigationPath.removeAll()
                        model.activeTab = .bookmark
                        model.currentScreen = .bookmarkCurrent
                    }
                    model.notifyHookChanged()
                } label: {
                    Text("いま読んでいる本にする")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("book.switchToCurrent")
            }

            if book.status != .finished {
                Button {
                    if model.store.markBookFinished(bookId: book.id) {
                        model.navigationPath.removeAll()
                        model.activeTab = .bookmark
                        model.currentScreen = .finishNight
                        model.activeSheet = .finishNight(bookId: book.id)
                    }
                    model.notifyHookChanged()
                } label: {
                    Text("読み終えたにする")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("book.markFinished")
            }

            if book.status == .finished {
                Button {
                    model.store.recordShareCard(for: book.id)
                    model.currentScreen = .shareCardPreview
                    detailSheet = .shareCard
                    model.notifyHookChanged()
                } label: {
                    Text("読了カードを作る")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("book.shareCard")
            }

            Button {
                model.store.activeErrorKey = nil
                model.currentScreen = .bookEdit
                detailSheet = .editBook
                model.notifyHookChanged()
            } label: {
                Text("書誌を編集")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("book.edit")

            if book.author.isEmpty || book.publisher == nil || book.isbn13 == nil {
                Button {
                    model.currentScreen = .colophonScan
                    detailSheet = .colophonOCR
                    model.notifyHookChanged()
                } label: {
                    Text("奥付を写して補う")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("book.scanColophon")
            }

            Button(role: .destructive) {
                showDeleteBookConfirm = true
                model.notifyHookChanged()
            } label: {
                Text("この本を削除")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("book.delete")

            if showDeleteBookConfirm {
                HStack(spacing: 12) {
                    Button(role: .destructive) {
                        if model.store.deleteBook(bookId: book.id) {
                            showDeleteBookConfirm = false
                            model.navigationPath.removeLast()
                            model.currentScreen = .shelfList
                        }
                        model.notifyHookChanged()
                    } label: {
                        Text("削除する")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .accessibilityIdentifier("book.delete.confirm")

                    Button {
                        showDeleteBookConfirm = false
                        model.notifyHookChanged()
                    } label: {
                        Text("キャンセル")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("book.delete.cancel")
                }
            }
        }
    }

    @ViewBuilder
    private func afterCandidatesSection(book: BookSnapshot) -> some View {
        if book.status == .finished {
            let candidates = model.store.buildAfterBookCandidates(for: book.id)
            if !candidates.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("この本のあとに")
                        .font(.headline)
                        .accessibilityIdentifier("book.after.header")

                    ForEach(Array(candidates.enumerated()), id: \.element.id) { idx, cand in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(cand.reason)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("book.after.candidate.\(idx + 1).reason")
                                .accessibilityLabel(cand.reason)
                                .accessibilityValue(cand.reason)

                            Text(cand.title)
                                .font(.subheadline.bold())
                                .accessibilityIdentifier("book.after.candidate.\(idx + 1).title")
                                .accessibilityLabel(cand.title)
                                .accessibilityValue(cand.title)

                            if let author = cand.author, !author.isEmpty {
                                Text(author)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if cand.isOwnedTsundoku, let candBookId = cand.bookId {
                                Button {
                                    let allCats = candidates.map { $0.axis.rawValue }
                                    model.store.recordRecommendationFeedback(
                                        chosenCategory: cand.axis.rawValue,
                                        allShownCategories: allCats
                                    )
                                    if model.store.switchToCurrentBook(bookId: candBookId) {
                                        model.navigationPath.removeAll()
                                        model.activeTab = .bookmark
                                        model.currentScreen = .bookmarkCurrent
                                    }
                                    model.notifyHookChanged()
                                } label: {
                                    Text("これを読み始める")
                                        .font(.caption.bold())
                                }
                                .buttonStyle(.borderedProminent)
                                .accessibilityIdentifier("book.after.candidate.\(idx + 1).action")
                            } else {
                                Button {
                                    let allCats = candidates.map { $0.axis.rawValue }
                                    model.store.recordRecommendationFeedback(
                                        chosenCategory: cand.axis.rawValue,
                                        allShownCategories: allCats
                                    )
                                    _ = model.store.addBook(
                                        isbn13: cand.isbn13,
                                        title: cand.title,
                                        author: cand.author ?? "",
                                        publisher: cand.publisher,
                                        label: cand.label,
                                        ndc: cand.ndc,
                                        forceTsundoku: true
                                    )
                                    model.notifyHookChanged()
                                } label: {
                                    Text("積読に置く")
                                        .font(.caption.bold())
                                }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("book.after.candidate.\(idx + 1).action")
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("book.after.candidate.\(idx + 1)")
                    }
                }
            }
        }
    }

    private func recordsSection(book: BookSnapshot) -> some View {
        let bookRecords = model.store.records(for: book.id)
        return VStack(alignment: .leading, spacing: 10) {
            Text("読書の記録")
                .font(.headline)

            if bookRecords.isEmpty {
                Text("まだ記録はありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(bookRecords.enumerated()), id: \.element.id) { idx, rec in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(rec.nightDate)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(rec.durationMinutes)分")
                                .font(.subheadline.bold())
                        }
                        if let line = rec.savedLine, !line.isEmpty {
                            Text(line)
                                .font(.footnote)
                                .foregroundStyle(.primary)
                        }
                        HStack(spacing: 12) {
                            Button {
                                model.store.activeErrorKey = nil
                                model.currentScreen = .recordEdit
                                detailSheet = .editRecord(rec.id)
                                model.notifyHookChanged()
                            } label: {
                                Text("時間を直す")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("record.edit.\(idx)")

                            Button(role: .destructive) {
                                recordIdPendingDelete = rec.id
                                model.notifyHookChanged()
                            } label: {
                                Text("削除")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("record.delete.\(idx)")
                        }

                        if recordIdPendingDelete == rec.id {
                            HStack(spacing: 8) {
                                Button(role: .destructive) {
                                    if model.store.deleteRecord(recordId: rec.id) {
                                        recordIdPendingDelete = nil
                                    }
                                    model.notifyHookChanged()
                                } label: {
                                    Text("削除する")
                                        .font(.caption.bold())
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .accessibilityIdentifier("record.delete.confirm")

                                Button {
                                    recordIdPendingDelete = nil
                                    model.notifyHookChanged()
                                } label: {
                                    Text("キャンセル")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("record.delete.cancel")
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("record.row.\(idx)")
                }
            }
        }
    }
}

// MARK: - S-7a Book Edit Sheet

public struct BookEditSheetView: View {
    @Bindable var model: ReadingAppModel
    public let book: BookSnapshot
    public let onClose: () -> Void

    @State private var editedTitle: String = ""
    @State private var editedAuthor: String = ""
    @State private var editedPublisher: String = ""
    @State private var didTouchTitle = false
    @State private var didTouchAuthor = false

    public init(model: ReadingAppModel, book: BookSnapshot, onClose: @escaping () -> Void) {
        self.model = model
        self.book = book
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                BannerNoticeView(model: model)

                Text("書名")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField(book.title, text: $editedTitle, onEditingChanged: { editing in
                    if editing { didTouchTitle = true }
                })
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("book.edit.title")
                .accessibilityValue(didTouchTitle ? editedTitle : book.title)

                Text("著者名")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField(book.author, text: $editedAuthor, onEditingChanged: { editing in
                    if editing { didTouchAuthor = true }
                })
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("book.edit.author")
                .accessibilityValue(didTouchAuthor ? editedAuthor : book.author)

                Button {
                    let finalTitle = didTouchTitle ? editedTitle : (editedTitle.isEmpty ? book.title : editedTitle)
                    let finalAuthor = didTouchAuthor ? editedAuthor : (editedAuthor.isEmpty ? book.author : editedAuthor)
                    let res = model.store.updateBook(
                        bookId: book.id,
                        title: finalTitle,
                        author: finalAuthor
                    )
                    if case .success = res {
                        onClose()
                    }
                    model.notifyHookChanged()
                } label: {
                    Text("保存")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("book.edit.save")

                Spacer()
            }
            .padding(20)
            .navigationTitle("書誌を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        onClose()
                    }
                }
            }
        }
    }
}

// MARK: - S-7b Record Edit Sheet

public struct RecordEditSheetView: View {
    @Bindable var model: ReadingAppModel
    public let record: ReadingRecordSnapshot
    public let onClose: () -> Void

    @State private var editedMinutes: String = ""

    public init(model: ReadingAppModel, record: ReadingRecordSnapshot, onClose: @escaping () -> Void) {
        self.model = model
        self.record = record
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                BannerNoticeView(model: model)

                Text("読書時間（1〜1440分）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("\(record.durationMinutes)", text: $editedMinutes)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("record.minutesField")
                    .accessibilityValue(editedMinutes)

                Button {
                    let res = model.store.updateRecordMinutes(recordId: record.id, rawMinutes: editedMinutes)
                    if case .success = res {
                        onClose()
                    }
                    model.notifyHookChanged()
                } label: {
                    Text("保存")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("record.save")

                Spacer()
            }
            .padding(20)
            .navigationTitle("読書時間を直す")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        onClose()
                    }
                }
            }
        }
    }
}

// MARK: - S-7c Share Card Preview Sheet

public struct ShareCardPreviewSheetView: View {
    @Bindable var model: ReadingAppModel
    public let book: BookSnapshot
    public let onClose: () -> Void

    public init(model: ReadingAppModel, book: BookSnapshot, onClose: @escaping () -> Void) {
        self.model = model
        self.book = book
        self.onClose = onClose
    }

    public var body: some View {
        let nights = model.store.distinctNightCount(for: book.id)
        let mins = model.store.totalMinutes(for: book.id)

        return NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text(book.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    if !book.author.isEmpty {
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                    HStack(spacing: 16) {
                        Text("\(nights)晩")
                            .font(.headline)
                        Text("\(mins)分")
                            .font(.headline)
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("shareCard.canvas")

                Spacer()

                Button {
                    onClose()
                } label: {
                    Text("閉じる")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("shareCard.close")
            }
            .padding(24)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("sheet.shareCard")
            .navigationTitle("読了カード")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - S-8b Colophon OCR Sheet

public struct ColophonOCRSheetView: View {
    @Bindable var model: ReadingAppModel
    public let bookId: UUID
    public let onClose: () -> Void

    @State private var extracted: ColophonExtractionResult?
    @State private var authorText: String = ""
    @State private var publisherText: String = ""
    @State private var yearText: String = ""
    @State private var isbnText: String = ""

    public init(model: ReadingAppModel, bookId: UUID, onClose: @escaping () -> Void) {
        self.model = model
        self.bookId = bookId
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                BannerNoticeView(model: model)

                if extracted == nil {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(minHeight: 160)
                        .overlay {
                            Text("奥付ページを枠内に合わせてください")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                    Button {
                        let colCfg = model.store.ocrConfiguration?.colophon ?? H23OCRColophon(rawLines: [])
                        let res = OCRPipeline.parseColophon(colCfg)
                        extracted = res
                        authorText = res.author ?? ""
                        publisherText = res.publisher ?? ""
                        yearText = res.publishedYear.map(String.init) ?? ""
                        isbnText = res.isbn13 ?? ""
                        model.notifyHookChanged()
                    } label: {
                        Text("撮影する")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("colophon.shutter")
                } else {
                    TextField("著者名", text: $authorText)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("colophon.author")
                    TextField("出版社", text: $publisherText)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("colophon.publisher")
                    TextField("出版年", text: $yearText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("colophon.year")
                    TextField("ISBN-13", text: $isbnText)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("colophon.isbn")

                    Button {
                        let info = ColophonExtractionResult(
                            title: extracted?.title,
                            author: authorText.isEmpty ? nil : authorText,
                            publisher: publisherText.isEmpty ? nil : publisherText,
                            label: extracted?.label,
                            publishedYear: Int(yearText),
                            isbn13: isbnText.isEmpty ? nil : isbnText
                        )
                        if model.store.applyColophonOCR(bookId: bookId, info: info) {
                            onClose()
                        }
                        model.notifyHookChanged()
                    } label: {
                        Text("書誌を反映する")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("colophon.apply")
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("奥付を写す")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        onClose()
                    }
                }
            }
        }
    }
}

#Preview("S-6 Shelf List") {
    let model = ReadingAppModel()
    let b1 = BookSnapshot(title: "羅生門", author: "芥川龍之介", status: .current)
    let b2 = BookSnapshot(title: "こころ", author: "夏目漱石", status: .tsundoku)
    let b3 = BookSnapshot(title: "銀河鉄道の夜", author: "宮沢賢治", status: .finished)
    NavigationStack {
        ShelfListView(model: model, previewState: .populated(current: b1, tsundoku: [b2], finished: [b3]))
    }
}

#Preview("S-7 Book Detail AX5 Dark") {
    let model = ReadingAppModel()
    NavigationStack {
        BookDetailView(model: model, bookId: ReadingDataStore.uuidBookA)
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
