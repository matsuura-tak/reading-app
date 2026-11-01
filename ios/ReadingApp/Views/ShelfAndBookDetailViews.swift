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
    @Environment(\.themePalette) private var palette

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
        GatedLoadView(gate: model.store.loadGate, point: .shelfLoad) {
            shelfContent
        } placeholder: {
            RedactedRowsPlaceholderView(rowCount: 5)
        }
    }

    private var shelfContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: ThemeSpace.s24) {
                BannerNoticeView(model: model)

                switch resolvedState {
                case .empty:
                    emptyShelfSection
                case .populated(let current, let tsundoku, let finished):
                    if let current {
                        VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                            Text(AppL10n.pick("今の本", "Reading Now"))
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.textSecondary)
                                .accessibilityIdentifier("shelf.current")

                            shelfBookButton(book: current)
                        }
                    }

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(AppL10n.pick("積読（\(tsundoku.count)）", "Stack (\(tsundoku.count))"))
                            .font(.subheadline.bold())
                            .foregroundStyle(palette.textSecondary)
                            .accessibilityIdentifier("shelf.tsundoku")

                        if tsundoku.isEmpty {
                            Text(AppL10n.pick("積読の本はありません", "No books in your stack"))
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)
                                .padding(.vertical, ThemeSpace.s8)
                        } else {
                            ForEach(tsundoku) { book in
                                shelfBookButton(book: book)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(AppL10n.pick("読み終えた本（\(finished.count)）", "Finished (\(finished.count))"))
                            .font(.subheadline.bold())
                            .foregroundStyle(palette.textSecondary)
                            .accessibilityIdentifier("shelf.finished")

                        if finished.isEmpty {
                            Text(AppL10n.pick("読み終えた本はまだありません", "No finished books yet"))
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)
                                .padding(.vertical, ThemeSpace.s8)
                        } else {
                            ForEach(finished) { book in
                                shelfBookButton(book: book)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.vertical, ThemeSpace.s24)
        }
        .background(palette.bgPrimary.ignoresSafeArea())
        .accessibilityIdentifier("screen.shelf")
        .navigationTitle(AppL10n.pick("本棚", "Shelf"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.currentScreen = .bookAddActionSheet
                    model.activeSheet = .addBook(titlePendingMode: false)
                    model.notifyHookChanged()
                } label: {
                    Label(AppL10n.pick("本を加える", "Add a Book"), systemImage: "plus")
                        .foregroundStyle(palette.actionTint)
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

    private var emptyShelfSection: some View {
        let msg = AppL10n.pick(
            "読んでいる本や積読の本を加えると、ここに並びます。",
            "Books you are reading or stacking will appear here."
        )
        return ContentUnavailableView {
            Label(
                AppL10n.pick("まだ本が置かれていません", "No Books on Your Shelf"),
                systemImage: "books.vertical"
            )
            .foregroundStyle(palette.textPrimary)
        } description: {
            Text(msg)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .accessibilityIdentifier("shelf.empty.message")
        } actions: {
            Button {
                model.currentScreen = .bookAddActionSheet
                model.activeSheet = .addBook(titlePendingMode: false)
                model.notifyHookChanged()
            } label: {
                Text(AppL10n.pick("本を加える", "Add a Book"))
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("shelf.empty.addBook")
        }
        .padding(.vertical, ThemeSpace.s32)
    }

    private func shelfBookButton(book: BookSnapshot) -> some View {
        let displayTitle = book.isTitlePending ? AppL10n.pick("今の本", "Reading Now") : book.title
        let rowId = "shelf.row.\(book.id.uuidString.lowercased())"
        let progressText = InputValidator.formatProgressDisplay(
            unit: book.progressUnit,
            page: book.currentPage,
            location: book.currentLocation,
            percent: book.currentPercent.map(Double.init)
        )

        return Button {
            model.store.clock.beginInterval(.bookOpen)
            model.currentScreen = .bookDetail
            model.navigationPath.append(.bookDetail(book.id))
            model.notifyHookChanged()
        } label: {
            HStack(spacing: ThemeSpace.s12) {
                VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                    Text(displayTitle)
                        .font(.body.weight(.medium))
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.leading)
                    if !book.author.isEmpty {
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: ThemeSpace.s8)
                if let progressText, !progressText.isEmpty {
                    Text(progressText)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(palette.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)
            }
            .padding(ThemeSpace.s16)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                    .fill(palette.groupedRow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                    .stroke(palette.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
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
    @Environment(\.themePalette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: ReadingAppModel, bookId: UUID) {
        self.model = model
        self.bookId = bookId
    }

    private var book: BookSnapshot? {
        model.store.books.first { $0.id == bookId }
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s24) {
                    BannerNoticeView(model: model)

                    if let book {
                        bookHeaderSection(book: book)
                        bookActionsSection(book: book)
                        afterCandidatesSection(book: book)
                        recordsSection(book: book)
                    }
                }
                .padding(.horizontal, ThemeSpace.s24)
                .padding(.vertical, ThemeSpace.s24)
            }

            if let book, !book.status.isCurrentReading {
                VStack(spacing: 0) {
                    Button {
                        if model.store.switchToCurrentBook(bookId: book.id) {
                            model.navigationPath.removeAll()
                            model.activeTab = .bookmark
                            model.currentScreen = .bookmarkCurrent
                        }
                        model.notifyHookChanged()
                    } label: {
                        Text(AppL10n.pick("この本を読む", "Read This Book"))
                    }
                    .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                    .accessibilityIdentifier("book.readThis")
                }
                .padding(.horizontal, ThemeSpace.s24)
                .padding(.top, ThemeSpace.s12)
                .padding(.bottom, ThemeSpace.s16)
                .background(palette.bgPrimary)
            }
        }
        .background(palette.bgPrimary.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.bookDetail")
        .navigationTitle(book?.title ?? AppL10n.pick("本", "Book"))
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
                    .environment(\.themePalette, palette)
                }
            case .editRecord(let recId):
                if let rec = model.store.records.first(where: { $0.id == recId }) {
                    RecordEditSheetView(model: model, record: rec) {
                        detailSheet = nil
                        model.currentScreen = .bookDetail
                        model.notifyHookChanged()
                    }
                    .environment(\.themePalette, palette)
                }
            case .shareCard:
                if let book {
                    ShareCardPreviewSheetView(model: model, book: book) {
                        detailSheet = nil
                        model.currentScreen = .bookDetail
                        model.notifyHookChanged()
                    }
                    .environment(\.themePalette, palette)
                }
            case .colophonOCR:
                ColophonOCRSheetView(model: model, bookId: bookId) {
                    detailSheet = nil
                    model.currentScreen = .bookDetail
                    model.notifyHookChanged()
                }
                .environment(\.themePalette, palette)
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
        let displayTitle = book.isTitlePending ? AppL10n.pick("今の本", "Reading Now") : book.title
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

        return VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                Rectangle()
                    .fill(palette.hairline)
                    .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                    .accessibilityHidden(true)

                colophonRow(
                    key: AppL10n.pick("書名", "Title"),
                    value: displayTitle,
                    id: "colophon.title",
                    isTitle: true
                )

                if !book.author.isEmpty {
                    colophonRow(
                        key: AppL10n.pick("著者", "Author"),
                        value: book.author,
                        id: "colophon.author"
                    )
                }

                if let formattedPublisher {
                    colophonRow(
                        key: AppL10n.pick("出版社", "Publisher"),
                        value: formattedPublisher,
                        id: "colophon.publisher"
                    )
                }

                if let yr = book.publishedYear {
                    let yrText = "\(yr)年"
                    colophonRow(
                        key: AppL10n.pick("出版年", "Published"),
                        value: yrText,
                        id: "colophon.year"
                    )
                }

                if let awardDisplay {
                    colophonRow(
                        key: AppL10n.pick("受賞", "Awards"),
                        value: awardDisplay,
                        id: "colophon.award"
                    )
                }

                Rectangle()
                    .fill(palette.hairline)
                    .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("book.colophon")
            .accessibilityLabel(combinedColophonLabel)

            HStack(spacing: ThemeSpace.s12) {
                Text(nightsText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(palette.textSecondary)
                    .accessibilityIdentifier("book.nights")
                    .accessibilityLabel(nightsText)
                    .accessibilityValue(nightsText)

                Text(totalText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(palette.textSecondary)
                    .accessibilityIdentifier("book.total")
                    .accessibilityLabel(totalText)
                    .accessibilityValue(totalText)
            }

            if let reflection {
                Text(reflection)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("book.reflection")
                    .accessibilityLabel(reflection)
                    .accessibilityValue(reflection)
            }

            HStack(spacing: ThemeSpace.s12) {
                Text(AppL10n.pick("電子書籍", "E-book"))
                    .font(.subheadline)
                    .foregroundStyle(palette.textPrimary)
                Spacer()
                Toggle(AppL10n.pick("電子書籍", "E-book"), isOn: Binding(
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
                .tint(palette.actionTint)
                .accessibilityIdentifier("book.ebookToggle")
            }

            HStack(spacing: ThemeSpace.s8) {
                unitButton(book: book, unit: .page, title: AppL10n.pick("ページ", "Page"), id: "book.unit.page")
                unitButton(book: book, unit: .location, title: "Loc", id: "book.unit.location")
                unitButton(book: book, unit: .percent, title: "%", id: "book.unit.percent")
            }
        }
        .padding(ThemeSpace.s16)
        .background(
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .fill(palette.groupedRow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .stroke(palette.hairline, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func colophonRow(key: String, value: String, id: String, isTitle: Bool = false) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                Text(key)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .accessibilityHidden(true)
                Text(value)
                    .font(isTitle ? .headline : .subheadline)
                    .foregroundStyle(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(id)
                    .accessibilityLabel(value)
                    .accessibilityValue(value)
            }
            .padding(.vertical, 2)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: ThemeSpace.s12) {
                Text(key)
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .frame(minWidth: 56, alignment: .leading)
                    .accessibilityHidden(true)
                Text(value)
                    .font(isTitle ? .headline : .subheadline)
                    .foregroundStyle(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(id)
                    .accessibilityLabel(value)
                    .accessibilityValue(value)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func unitButton(book: BookSnapshot, unit: ProgressUnit, title: String, id: String) -> some View {
        let isSelected = (book.progressUnit == unit)
        if isSelected {
            Button {
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
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier(id)
            .accessibilityAddTraits(.isSelected)
        } else {
            Button {
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
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier(id)
        }
    }

    private func bookActionsSection(book: BookSnapshot) -> some View {
        let bookRecordCount = model.store.records(for: book.id).count
        let confirmMessage = AppL10n.pick(
            "この本と\(bookRecordCount)件の記録を削除しますか？",
            "Delete this book and \(bookRecordCount) reading records?"
        )

        return VStack(alignment: .leading, spacing: ThemeSpace.s12) {
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
                    Text(AppL10n.pick("読み終えたにする", "Mark as Finished"))
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
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
                    Text(AppL10n.pick("一枚のカードにする", "Share as a Card"))
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("book.shareCard")
            }

            Button {
                model.store.activeErrorKey = nil
                model.currentScreen = .bookEdit
                detailSheet = .editBook
                model.notifyHookChanged()
            } label: {
                Text(AppL10n.pick("直す", "Edit"))
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("book.edit")

            if book.author.isEmpty || book.publisher == nil || book.isbn13 == nil {
                Button {
                    model.currentScreen = .colophonScan
                    detailSheet = .colophonOCR
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("奥付を撮って補完する", "Snap Colophon to Fill Details"))
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("colophon.capture")
            }

            Button(role: .destructive) {
                showDeleteBookConfirm = true
                model.notifyHookChanged()
            } label: {
                HStack(spacing: ThemeSpace.s8) {
                    Image(systemName: "trash")
                        .foregroundStyle(palette.destructive)
                        .accessibilityHidden(true)
                    Text(AppL10n.pick("この本を本棚から消す", "Remove from Shelf"))
                        .foregroundStyle(palette.textPrimary)
                }
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette, isDestructive: true))
            .accessibilityIdentifier("book.delete")

            if showDeleteBookConfirm {
                VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                    Text(confirmMessage)
                        .font(.subheadline)
                        .foregroundStyle(palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("book.delete.confirm")
                        .accessibilityLabel(confirmMessage)
                        .accessibilityValue(confirmMessage)

                    HStack(spacing: ThemeSpace.s12) {
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
                            Text(AppL10n.pick("本棚から消す", "Delete"))
                        }
                        .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                        .accessibilityIdentifier("book.delete.confirmButton")

                        Button {
                            showDeleteBookConfirm = false
                            model.notifyHookChanged()
                        } label: {
                            Text(AppL10n.pick("やめる", "Cancel"))
                        }
                        .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                        .accessibilityIdentifier("book.delete.cancel")
                    }
                }
                .padding(ThemeSpace.s16)
                .background(
                    RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                        .fill(palette.groupedRow)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                        .stroke(palette.hairline, lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private func afterCandidatesSection(book: BookSnapshot) -> some View {
        if book.status == .finished {
            let candidates = cachedAfterCandidates ?? model.store.buildAfterBookCandidates(for: book.id)
            if !candidates.isEmpty {
                VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                    Text(AppL10n.pick("この本のあとに", "After This Book"))
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
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

                        VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                            Text(cand.reason)
                                .font(.caption.bold())
                                .foregroundStyle(palette.textSecondary)

                            Text(cand.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.textPrimary)

                            if let author = cand.author, !author.isEmpty {
                                Text(author)
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
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
                                    Text(AppL10n.pick("これを読む", "Read This"))
                                }
                                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                                .accessibilityIdentifier("after.readThis")
                            } else if isAlreadyInShelf {
                                Text(AppL10n.pick("積読に加えました", "Added to Stack"))
                                    .font(.caption.bold())
                                    .foregroundStyle(palette.textSecondary)
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
                                    Text(AppL10n.pick("積読に加える", "Add to Stack"))
                                }
                                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                                .accessibilityIdentifier("after.addToShelf")
                            }
                        }
                        .padding(ThemeSpace.s16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                                .fill(palette.groupedRow)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                                .stroke(palette.hairline, lineWidth: 1)
                        )
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
        return VStack(alignment: .leading, spacing: ThemeSpace.s12) {
            Text(AppL10n.pick("読んだ晩の記録", "Reading Nights"))
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            if bookRecords.isEmpty {
                Text(AppL10n.pick("まだ記録はありません", "No reading sessions recorded yet"))
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
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
                        VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                            HStack {
                                Text(rec.nightDate)
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(palette.textSecondary)
                                Spacer()
                                Text("\(rec.durationMinutes)分")
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundStyle(palette.textPrimary)
                            }
                            if let line = rec.savedLine, !line.isEmpty {
                                Text(line)
                                    .font(.footnote)
                                    .foregroundStyle(palette.textPrimary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(ThemeSpace.s16)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                                .fill(palette.groupedRow)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                                .stroke(palette.hairline, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
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
    @State private var editedPublisher: String = ""
    @State private var editedLabel: String = ""
    @State private var editedYear: String = ""
    @State private var editedIsEbook: Bool = false
    @State private var editedUnit: ProgressUnit = .page
    @State private var didTouchTitle = false
    @State private var didTouchAuthor = false
    @Environment(\.themePalette) private var palette

    public init(model: ReadingAppModel, book: BookSnapshot, onClose: @escaping () -> Void) {
        self.model = model
        self.book = book
        self.onClose = onClose
        _editedPublisher = State(initialValue: book.publisher ?? "")
        _editedLabel = State(initialValue: book.label ?? "")
        _editedYear = State(initialValue: book.publishedYear.map(String.init) ?? "")
        _editedIsEbook = State(initialValue: book.isEbook)
        _editedUnit = State(initialValue: book.progressUnit)
    }

    public var body: some View {
        let titleLabel = AppL10n.pick("書名（必須）", "Title (Required)")
        let authorLabel = AppL10n.pick("著者（任意）", "Author (Optional)")

        return VStack(spacing: 0) {
            SheetHeaderBar(
                title: AppL10n.pick("書誌を直す", "Edit Book Details"),
                cancelTitle: AppL10n.pick("やめる", "Cancel"),
                cancelIdentifier: "book.edit.cancel",
                onCancel: onClose
            )

            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s16) {
                    BannerNoticeView(model: model)

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(titleLabel)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                        TextField(book.title, text: $editedTitle, onEditingChanged: { editing in
                            if editing { didTouchTitle = true }
                        })
                        .themeField(palette)
                        .accessibilityIdentifier("book.edit.title")
                        .accessibilityLabel(titleLabel)
                        .accessibilityValue(didTouchTitle ? editedTitle : book.title)
                    }

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(authorLabel)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                        TextField(book.author.isEmpty ? AppL10n.pick("著者名", "Author") : book.author, text: $editedAuthor, onEditingChanged: { editing in
                            if editing { didTouchAuthor = true }
                        })
                        .themeField(palette)
                        .accessibilityIdentifier("book.edit.author")
                        .accessibilityLabel(authorLabel)
                        .accessibilityValue(didTouchAuthor ? editedAuthor : book.author)
                    }

                    HStack {
                        Text(AppL10n.pick("電子書籍", "E-book"))
                            .font(.body)
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        Toggle(AppL10n.pick("電子書籍", "E-book"), isOn: $editedIsEbook)
                            .labelsHidden()
                            .tint(palette.actionTint)
                            .accessibilityIdentifier("book.edit.isEbook")
                    }
                    .padding(ThemeSpace.s12)
                    .background(
                        RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                            .fill(palette.groupedRow)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                            .stroke(palette.hairline, lineWidth: 1)
                    )

                    Picker(AppL10n.pick("進み方の単位", "Progress Unit"), selection: $editedUnit) {
                        Text(AppL10n.pick("ページ", "Page")).tag(ProgressUnit.page)
                        Text(AppL10n.pick("位置番号", "Location")).tag(ProgressUnit.location)
                        Text("%").tag(ProgressUnit.percent)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("book.edit.progressUnit")
                }
                .padding(ThemeSpace.s24)
            }

            VStack(spacing: 0) {
                Button {
                    let finalTitle = didTouchTitle ? editedTitle : (editedTitle.isEmpty ? book.title : editedTitle)
                    let finalAuthor = didTouchAuthor ? editedAuthor : (editedAuthor.isEmpty ? book.author : editedAuthor)
                    let res = model.store.updateBook(
                        bookId: book.id,
                        title: finalTitle,
                        author: finalAuthor,
                        isEbook: editedIsEbook,
                        progressUnit: editedUnit
                    )
                    if case .success = res {
                        onClose()
                    }
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("保存", "Save"))
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("book.edit.save")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.top, ThemeSpace.s12)
            .padding(.bottom, ThemeSpace.s24)
            .background(palette.bgPrimary)
        }
        .background(palette.bgPrimary.ignoresSafeArea())
    }
}

// MARK: - S-7b Record Edit Sheet

public struct RecordEditSheetView: View {
    @Bindable var model: ReadingAppModel
    public let record: ReadingRecordSnapshot
    public let onClose: () -> Void

    @State private var editedMinutes: String = ""
    @State private var showDeleteConfirm = false
    @Environment(\.themePalette) private var palette

    public init(model: ReadingAppModel, record: ReadingRecordSnapshot, onClose: @escaping () -> Void) {
        self.model = model
        self.record = record
        self.onClose = onClose
    }

    public var body: some View {
        let minutesLabel = AppL10n.pick("読んだ時間（1〜1440分）", "Minutes Read (1–1440)")

        return VStack(spacing: 0) {
            SheetHeaderBar(
                title: AppL10n.pick("記録を直す", "Edit Session"),
                cancelTitle: AppL10n.pick("やめる", "Cancel"),
                cancelIdentifier: "record.cancel",
                onCancel: onClose
            )

            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s16) {
                    BannerNoticeView(model: model)

                    HStack {
                        Text(AppL10n.pick("読んだ晩", "Reading Night"))
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                        Spacer()
                        Text(record.nightDate)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(palette.textPrimary)
                            .accessibilityIdentifier("record.night")
                    }
                    .padding(ThemeSpace.s12)
                    .background(
                        RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                            .fill(palette.groupedRow)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                            .stroke(palette.hairline, lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(minutesLabel)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)

                        TextField("\(record.durationMinutes)", text: $editedMinutes)
                            .keyboardType(.numberPad)
                            .themeField(palette)
                            .accessibilityIdentifier("record.minutesField")
                            .accessibilityLabel(minutesLabel)
                            .accessibilityValue(editedMinutes)
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                        model.notifyHookChanged()
                    } label: {
                        HStack(spacing: ThemeSpace.s8) {
                            Image(systemName: "trash")
                                .foregroundStyle(palette.destructive)
                                .accessibilityHidden(true)
                            Text(AppL10n.pick("この記録を消す", "Delete This Session"))
                                .foregroundStyle(palette.textPrimary)
                        }
                    }
                    .buttonStyle(ThemeSecondaryButtonStyle(palette: palette, isDestructive: true))
                    .accessibilityIdentifier("record.delete")

                    if showDeleteConfirm {
                        VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                            Text(AppL10n.pick("この記録を削除しますか？", "Delete this reading session?"))
                                .font(.subheadline)
                                .foregroundStyle(palette.textPrimary)
                                .accessibilityIdentifier("record.delete.confirm")

                            HStack(spacing: ThemeSpace.s12) {
                                Button(role: .destructive) {
                                    if model.store.deleteRecord(recordId: record.id) {
                                        showDeleteConfirm = false
                                        onClose()
                                    }
                                    model.notifyHookChanged()
                                } label: {
                                    Text(AppL10n.pick("記録を消す", "Delete"))
                                }
                                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                                .accessibilityIdentifier("record.delete.confirmButton")

                                Button {
                                    showDeleteConfirm = false
                                    model.notifyHookChanged()
                                } label: {
                                    Text(AppL10n.pick("やめる", "Cancel"))
                                }
                                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                                .accessibilityIdentifier("record.delete.cancel")
                            }
                        }
                        .padding(ThemeSpace.s16)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                                .fill(palette.groupedRow)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                                .stroke(palette.hairline, lineWidth: 1)
                        )
                    }
                }
                .padding(ThemeSpace.s24)
            }

            VStack(spacing: 0) {
                Button {
                    let res = model.store.updateRecordMinutes(recordId: record.id, rawMinutes: editedMinutes)
                    if case .success = res {
                        onClose()
                    }
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("保存", "Save"))
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("record.save")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.top, ThemeSpace.s12)
            .padding(.bottom, ThemeSpace.s24)
            .background(palette.bgPrimary)
        }
        .background(palette.bgPrimary.ignoresSafeArea())
    }
}

// MARK: - Share Card Preview Sheet

public struct ShareCardPreviewSheetView: View {
    @Bindable var model: ReadingAppModel
    public let book: BookSnapshot
    public let onClose: () -> Void

    @State private var renderedOutput: FinishCardRenderOutput?
    @Environment(\.themePalette) private var palette

    public init(model: ReadingAppModel, book: BookSnapshot, onClose: @escaping () -> Void) {
        self.model = model
        self.book = book
        self.onClose = onClose
    }

    public var body: some View {
        let nights = model.store.distinctNightCount(for: book.id)
        let mins = model.store.totalMinutes(for: book.id)

        return VStack(spacing: 0) {
            SheetHeaderBar(
                title: AppL10n.pick("読了カード", "Finish Card"),
                cancelTitle: AppL10n.pick("閉じる", "Close"),
                cancelIdentifier: "shareCard.close",
                onCancel: onClose
            )

            VStack(spacing: ThemeSpace.s24) {
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
                        Text(AppL10n.pick("画像を共有", "Share Image"))
                    }
                    .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                    .accessibilityIdentifier("shareCard.share")
                }

                Spacer()
            }
            .padding(ThemeSpace.s24)
        }
        .background(palette.bgPrimary.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.shareCard")
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

// MARK: - S-7c Colophon OCR Sheet

public struct ColophonOCRSheetView: View {
    @Bindable var model: ReadingAppModel
    public let bookId: UUID
    public let onClose: () -> Void

    @State private var extracted: ColophonExtractionResult?
    @State private var authorText: String = ""
    @State private var publisherText: String = ""
    @State private var labelText: String = ""
    @State private var yearText: String = ""
    @State private var isbnText: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @Environment(\.themePalette) private var palette

    public init(model: ReadingAppModel, bookId: UUID, onClose: @escaping () -> Void) {
        self.model = model
        self.bookId = bookId
        self.onClose = onClose
    }

    public var body: some View {
        let authorFieldLabel = AppL10n.pick("著者", "Author")
        let publisherFieldLabel = AppL10n.pick("出版社", "Publisher")
        let yearFieldLabel = AppL10n.pick("出版年", "Published Year")
        let isbnFieldLabel = "ISBN-13"

        return VStack(spacing: 0) {
            SheetHeaderBar(
                title: AppL10n.pick("奥付を撮る", "Snap Colophon"),
                cancelTitle: AppL10n.pick("やめる", "Cancel"),
                cancelIdentifier: "colophon.cancel",
                onCancel: onClose
            )

            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s16) {
                    BannerNoticeView(model: model)

                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images
                    ) {
                        Text(AppL10n.pick("奥付の画像から読み取る", "Pick Colophon Image"))
                    }
                    .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                    .accessibilityIdentifier("colophon.ocr.pickPhoto")
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        guard let newItem else { return }
                        Task { @MainActor in
                            if let image = await CameraAndOCRService.loadUIImage(from: newItem) {
                                let res = CameraAndOCRService.evaluateColophon(from: image)
                                extracted = res
                                if let a = res.author, !a.isEmpty { authorText = a }
                                if let p = res.publisher, !p.isEmpty { publisherText = p }
                                if let l = res.label, !l.isEmpty { labelText = l }
                                if let y = res.publishedYear { yearText = String(y) }
                                if let i = res.isbn13, !i.isEmpty { isbnText = i }
                                model.notifyHookChanged()
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(authorFieldLabel)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                        TextField(authorFieldLabel, text: $authorText)
                            .themeField(palette)
                            .accessibilityIdentifier("colophon.ocr.author")
                            .accessibilityLabel(authorFieldLabel)
                            .accessibilityValue(authorText)
                    }

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(publisherFieldLabel)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                        TextField(publisherFieldLabel, text: $publisherText)
                            .themeField(palette)
                            .accessibilityIdentifier("colophon.ocr.publisher")
                            .accessibilityLabel(publisherFieldLabel)
                            .accessibilityValue(publisherText)
                    }

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(yearFieldLabel)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                        TextField(yearFieldLabel, text: $yearText)
                            .keyboardType(.numberPad)
                            .themeField(palette)
                            .accessibilityIdentifier("colophon.ocr.year")
                            .accessibilityLabel(yearFieldLabel)
                            .accessibilityValue(yearText)
                    }

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(isbnFieldLabel)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                        TextField(isbnFieldLabel, text: $isbnText)
                            .keyboardType(.numbersAndPunctuation)
                            .themeField(palette)
                            .accessibilityIdentifier("colophon.ocr.isbn")
                            .accessibilityLabel(isbnFieldLabel)
                            .accessibilityValue(isbnText)
                    }
                }
                .padding(ThemeSpace.s24)
            }

            VStack(spacing: 0) {
                Button {
                    let info = ColophonExtractionResult(
                        title: extracted?.title,
                        author: authorText.isEmpty ? nil : authorText,
                        publisher: publisherText.isEmpty ? nil : publisherText,
                        label: labelText.isEmpty ? extracted?.label : labelText,
                        publishedYear: Int(yearText),
                        isbn13: isbnText.isEmpty ? nil : isbnText
                    )
                    if model.store.applyColophonOCR(bookId: bookId, info: info) {
                        onClose()
                    }
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("この内容で補完する", "Save Details"))
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("colophon.save")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.top, ThemeSpace.s12)
            .padding(.bottom, ThemeSpace.s24)
            .background(palette.bgPrimary)
        }
        .background(palette.bgPrimary.ignoresSafeArea())
        .onAppear {
            let colCfg = model.store.ocrConfiguration?.colophon ?? H23OCRColophon(rawLines: [])
            let res = OCRPipeline.parseColophon(colCfg)
            extracted = res
            authorText = res.author ?? ""
            publisherText = res.publisher ?? ""
            labelText = res.label ?? ""
            yearText = res.publishedYear.map(String.init) ?? ""
            isbnText = res.isbn13 ?? ""
            model.notifyHookChanged()
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
