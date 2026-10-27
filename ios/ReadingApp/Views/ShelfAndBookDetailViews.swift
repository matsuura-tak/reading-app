import SwiftUI
import UIKit
import PhotosUI
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
                                .accessibilityIdentifier("shelf.current")

                            shelfBookButton(book: current)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("積読（\(tsundoku.count)）")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("shelf.tsundoku")

                        ForEach(tsundoku) { book in
                            shelfBookButton(book: book)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("読み終えた（\(finished.count)）")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("shelf.finished")

                        ForEach(finished) { book in
                            shelfBookButton(book: book)
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

    private func shelfBookButton(book: BookSnapshot) -> some View {
        let displayTitle = book.isTitlePending ? "あとで書名を入れる本" : book.title
        let rowId = "shelf.row.\(book.id.uuidString.lowercased())"
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
        .accessibilityIdentifier(rowId)
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
    @State private var addedAfterCandidateIDs: Set<String> = []
    @State private var cachedAfterCandidates: [RecommendationCandidate]?

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
            if cachedAfterCandidates == nil, let book, book.status == .finished {
                cachedAfterCandidates = model.store.buildAfterBookCandidates(for: book.id)
            }
            _ = model.store.clock.endInterval(.bookOpen)
            model.currentScreen = .bookDetail
            model.notifyHookChanged()
        }
    }

    private func bookHeaderSection(book: BookSnapshot) -> some View {
        let displayTitle = book.isTitlePending ? "あとで書名を入れる本" : book.title
        let nights = model.store.distinctNightCount(for: book.id)
        let mins = model.store.totalMinutes(for: book.id)
        let nightsText = "\(nights)晩"
        let totalText = "\(mins)分"
        let reflection = (book.status == .finished) ? model.store.buildFinishReflection(for: book.id) : nil

        let formattedPublisher: String? = {
            let pub = (book.publisher ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lbl = (book.label ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !pub.isEmpty && !lbl.isEmpty {
                return "\(pub)（\(lbl)）"
            } else if !pub.isEmpty {
                return pub
            } else if !lbl.isEmpty {
                return lbl
            } else {
                return nil
            }
        }()

        let matchedAwards = AwardsCatalog.matchAwards(
            title: book.title,
            author: book.author,
            catalog: model.store.activeAwards
        )
        let awardDisplay: String? = {
            guard !matchedAwards.isEmpty else { return nil }
            return matchedAwards.map { "\($0.sessionOrYear) \($0.award)" }.joined(separator: " / ")
        }()

        let combinedColophonLabel: String = {
            var parts: [String] = [displayTitle]
            if !book.author.isEmpty { parts.append(book.author) }
            if let formattedPublisher { parts.append(formattedPublisher) }
            if let yr = book.publishedYear { parts.append("\(yr)年") }
            if let awardDisplay { parts.append(awardDisplay) }
            return parts.joined(separator: " ")
        }()

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(displayTitle)
                    .font(.title2.bold())
                    .accessibilityIdentifier("colophon.title")
                    .accessibilityLabel(displayTitle)
                    .accessibilityValue(displayTitle)

                if !book.author.isEmpty {
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("colophon.author")
                        .accessibilityLabel(book.author)
                        .accessibilityValue(book.author)
                }

                if let formattedPublisher {
                    Text(formattedPublisher)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("colophon.publisher")
                        .accessibilityLabel(formattedPublisher)
                        .accessibilityValue(formattedPublisher)
                }

                if let yr = book.publishedYear {
                    let yrText = "\(yr)年"
                    Text(yrText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("colophon.year")
                        .accessibilityLabel(yrText)
                        .accessibilityValue(yrText)
                }

                if let awardDisplay {
                    Text(awardDisplay)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("colophon.award")
                        .accessibilityLabel(awardDisplay)
                        .accessibilityValue(awardDisplay)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("book.colophon")
            .accessibilityLabel(combinedColophonLabel)

            HStack(spacing: 12) {
                Text(nightsText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("book.nights")
                    .accessibilityLabel(nightsText)
                    .accessibilityValue(nightsText)

                Text(totalText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("book.total")
                    .accessibilityLabel(totalText)
                    .accessibilityValue(totalText)
            }

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
        let bookRecordCount = model.store.records(for: book.id).count
        let confirmMessage = "この本と\(bookRecordCount)件の記録を削除しますか？"

        return VStack(alignment: .leading, spacing: 10) {
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
                .accessibilityIdentifier("book.readThis")
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
                    let nights = model.store.distinctNightCount(for: book.id)
                    let mins = model.store.totalMinutes(for: book.id)
                    let rendered = FinishCardRenderer.renderCard(
                        title: book.title,
                        author: book.author,
                        nightsCount: nights,
                        totalMinutes: mins
                    )
                    model.store.recordShareCard(
                        for: book.id,
                        renderedTexts: rendered.renderedTexts,
                        widthPx: rendered.widthPx,
                        heightPx: rendered.heightPx
                    )
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
                .accessibilityIdentifier("colophon.capture")
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
                VStack(alignment: .leading, spacing: 10) {
                    Text(confirmMessage)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier("book.delete.confirm")
                        .accessibilityLabel(confirmMessage)
                        .accessibilityValue(confirmMessage)

                    HStack(spacing: 12) {
                        Button(role: .destructive) {
                            if model.store.deleteBook(bookId: book.id) {
                                showDeleteBookConfirm = false
                                if !model.navigationPath.isEmpty {
                                    model.navigationPath.removeLast()
                                }
                                model.currentScreen = .shelfList
                            }
                            model.notifyHookChanged()
                        } label: {
                            Text("削除する")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .accessibilityIdentifier("book.delete.confirmButton")

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
                .padding(12)
                .background(Color(uiColor: .tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    @ViewBuilder
    private func afterCandidatesSection(book: BookSnapshot) -> some View {
        if book.status == .finished {
            let candidates = cachedAfterCandidates ?? model.store.buildAfterBookCandidates(for: book.id)
            if !candidates.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("この本のあとに")
                        .font(.headline)
                        .accessibilityIdentifier("after.header")

                    ForEach(Array(candidates.enumerated()), id: \.element.id) { _, cand in
                        let candIdentifierSuffix = cand.isbn13 ?? cand.bookId?.uuidString.lowercased() ?? cand.id
                        let isAlreadyInShelf = addedAfterCandidateIDs.contains(candIdentifierSuffix)
                        let combinedText = [cand.title, cand.author, cand.reason]
                            .compactMap { item -> String? in
                                guard let item, !item.isEmpty else { return nil }
                                return item
                            }
                            .joined(separator: " ")

                        VStack(alignment: .leading, spacing: 6) {
                            Text(cand.reason)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            Text(cand.title)
                                .font(.subheadline.bold())

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
                                .accessibilityIdentifier("after.readThis")
                            } else if isAlreadyInShelf {
                                Text("本棚に追加済み")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .accessibilityIdentifier("after.added")
                            } else {
                                Button {
                                    let allCats = candidates.map { $0.axis.rawValue }
                                    model.store.recordRecommendationFeedback(
                                        chosenCategory: cand.axis.rawValue,
                                        allShownCategories: allCats
                                    )
                                    let res = model.store.addBook(
                                        isbn13: cand.isbn13,
                                        title: cand.title,
                                        author: cand.author ?? "",
                                        publisher: cand.publisher,
                                        label: cand.label,
                                        publishedYear: cand.publishedYear,
                                        seriesTitle: cand.seriesTitle,
                                        volumeNumber: cand.volumeNumber,
                                        ndc: cand.ndc,
                                        forceTsundoku: true
                                    )
                                    if case .success = res {
                                        addedAfterCandidateIDs.insert(candIdentifierSuffix)
                                    }
                                    model.notifyHookChanged()
                                } label: {
                                    Text("積読に置く")
                                        .font(.caption.bold())
                                }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("after.addToShelf")
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("after.candidate.\(candIdentifierSuffix)")
                        .accessibilityLabel(combinedText)
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
                    .accessibilityIdentifier("book.records.empty")
            } else {
                ForEach(bookRecords) { rec in
                    let rowId = "book.record.row.\(rec.id.uuidString.lowercased())"
                    let rowLabel: String = {
                        var parts = [rec.nightDate, "\(rec.durationMinutes)分"]
                        if let line = rec.savedLine, !line.isEmpty {
                            parts.append(line)
                        }
                        return parts.joined(separator: " ")
                    }()

                    Button {
                        model.store.activeErrorKey = nil
                        model.currentScreen = .recordEdit
                        detailSheet = .editRecord(rec.id)
                        model.notifyHookChanged()
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(rec.nightDate)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(rec.durationMinutes)分")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                            }
                            if let line = rec.savedLine, !line.isEmpty {
                                Text(line)
                                    .font(.footnote)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier(rowId)
                    .accessibilityLabel(rowLabel)
                    .accessibilityValue(rowLabel)
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
    @State private var showDeleteConfirm = false

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

                Button(role: .destructive) {
                    showDeleteConfirm = true
                    model.notifyHookChanged()
                } label: {
                    Text("この記録を削除")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("record.delete")

                if showDeleteConfirm {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("この記録を削除しますか？")
                            .font(.subheadline)
                            .accessibilityIdentifier("record.delete.confirm")

                        HStack(spacing: 12) {
                            Button(role: .destructive) {
                                if model.store.deleteRecord(recordId: record.id) {
                                    showDeleteConfirm = false
                                    onClose()
                                }
                                model.notifyHookChanged()
                            } label: {
                                Text("削除する")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .accessibilityIdentifier("record.delete.confirmButton")

                            Button {
                                showDeleteConfirm = false
                                model.notifyHookChanged()
                            } label: {
                                Text("キャンセル")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("record.delete.cancel")
                        }
                    }
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                }

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

    @State private var renderedOutput: FinishCardRenderOutput?

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
                FinishCardCanvasView(
                    title: book.title,
                    author: book.author,
                    nightsCount: nights,
                    totalMinutes: mins
                )
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("shareCard.canvas")

                if let renderedOutput,
                   !renderedOutput.pngData.isEmpty,
                   let uiImage = UIImage(data: renderedOutput.pngData) {
                    let previewImage = Image(uiImage: uiImage)
                    ShareLink(
                        item: previewImage,
                        preview: SharePreview(book.title, image: previewImage)
                    ) {
                        Text("画像を共有")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityIdentifier("shareCard.share")
                }

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
            .onAppear {
                renderedOutput = FinishCardRenderer.renderCard(
                    title: book.title,
                    author: book.author,
                    nightsCount: nights,
                    totalMinutes: mins
                )
            }
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
    @State private var selectedPhotoItem: PhotosPickerItem?

    public init(model: ReadingAppModel, bookId: UUID, onClose: @escaping () -> Void) {
        self.model = model
        self.bookId = bookId
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                BannerNoticeView(model: model)

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Text("奥付の画像から読み取る")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("colophon.ocr.pickPhoto")
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let newItem else { return }
                    Task { @MainActor in
                        if let image = await CameraAndOCRService.loadUIImage(from: newItem) {
                            let res = CameraAndOCRService.evaluateColophon(from: image)
                            extracted = res
                            if let a = res.author, !a.isEmpty { authorText = a }
                            if let p = res.publisher, !p.isEmpty { publisherText = p }
                            if let y = res.publishedYear { yearText = String(y) }
                            if let i = res.isbn13, !i.isEmpty { isbnText = i }
                            model.notifyHookChanged()
                        }
                    }
                }

                TextField("著者名", text: $authorText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("colophon.ocr.author")
                TextField("出版社", text: $publisherText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("colophon.ocr.publisher")
                TextField("出版年", text: $yearText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("colophon.ocr.year")
                TextField("ISBN-13", text: $isbnText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("colophon.ocr.isbn")

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
                .accessibilityIdentifier("colophon.save")

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
            .onAppear {
                let colCfg = model.store.ocrConfiguration?.colophon ?? H23OCRColophon(rawLines: [])
                let res = OCRPipeline.parseColophon(colCfg)
                extracted = res
                authorText = res.author ?? ""
                publisherText = res.publisher ?? ""
                yearText = res.publishedYear.map(String.init) ?? ""
                isbnText = res.isbn13 ?? ""
                model.notifyHookChanged()
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
