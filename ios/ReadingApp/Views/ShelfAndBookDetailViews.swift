import SwiftUI
import UIKit
import PhotosUI
import ReadingCore
import ReadingStore

public enum ShelfListViewState: Equatable, Sendable {
    case empty
    case loadError
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
        if model.store.isStoreLoadFailed {
            return .loadError
        }
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

    // S-6 の「読めない」（design 5）：shelf.load.error と shelf.retry。
    private var shelfLoadErrorSection: some View {
        let message = String(localized: "shelf.load.error")
        return ContentUnavailableView {
            Label(
                AppL10n.pick("本棚を読み込めませんでした", "Couldn't Load Bookshelf"),
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(message)
                .accessibilityIdentifier("shelf.load.error")
        } actions: {
            Button {
                model.store.loadFromDisk()
                model.notifyHookChanged()
            } label: {
                Text(String(localized: "shelf.retry"))
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("shelf.retry")
        }
        .padding(.vertical, ThemeSpace.s32)
    }

    private var shelfContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: ThemeSpace.s24) {
                BannerNoticeView(model: model)

                switch resolvedState {
                case .empty:
                    emptyShelfSection
                case .loadError:
                    shelfLoadErrorSection
                case .populated(let current, let tsundoku, let finished):
                    if let current {
                        VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                            Text(String(localized: "shelf.current"))
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.textSecondary)
                                .accessibilityIdentifier("shelf.current")

                            shelfBookButton(book: current)
                        }
                    }

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(String(localized: "shelf.tsundoku"))
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
                        Text(String(localized: "shelf.finished"))
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
        .navigationTitle(String(localized: "shelf.navTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.currentScreen = .bookAddActionSheet
                    model.activeSheet = .addBook(titlePendingMode: false)
                    model.notifyHookChanged()
                } label: {
                    Label(String(localized: "shelf.addBook"), systemImage: "plus")
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
        let msg = String(localized: "shelf.empty.message")
        return ContentUnavailableView {
            Label(
                String(localized: "shelf.empty.title"),
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
                Text(String(localized: "shelf.addBook"))
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("shelf.empty.addBook")
        }
        .padding(.vertical, ThemeSpace.s32)
    }

    private func shelfBookButton(book: BookSnapshot) -> some View {
        let displayTitle = book.isTitlePending ? String(localized: "widget.currentBookAsTitle") : book.title
        let rowId = "shelf.row.\(book.id.uuidString.lowercased())"
        let progressText = InputValidator.formatProgressDisplay(
            unit: book.progressUnit,
            page: book.currentPage,
            location: book.currentLocation,
            percent: book.currentPercent.map(Double.init),
            strings: ReadingWidgetStrings.spoken
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

    /// S-7 の題（名無しの今の本は `widget.currentBookAsTitle`。design/ 5 の S-7）。
    private var navigationTitleText: String {
        guard let book else { return "" }
        return book.isTitlePending ? String(localized: "widget.currentBookAsTitle") : book.title
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s24) {
                    // S-7a・S-7b・S-7c のシートは自分の帯を出す。iOS 26 のシートは下の画面を縮めず、
                    // 下の S-7 の帯も読み上げの木に残って `common.save.error` が2つになるため（AC-91）、シートの間は出さない。
                    if detailSheet == nil {
                        BannerNoticeView(model: model)
                    }

                    if let book {
                        bookHeaderSection(book: book)
                        bookActionsSection(book: book)
                        afterCandidatesSection(book: book)
                        // H33 book.load：0.3秒を超えたら記録の行の形の灰の帯（design 5 の S-7）。
                        GatedLoadView(gate: model.store.loadGate, point: .bookLoad) {
                            recordsSection(book: book)
                        } placeholder: {
                            RedactedRowsPlaceholderView(rowCount: 3)
                        }
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
                        Text(String(localized: "book.readThis"))
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
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // ナビゲーションバーの題は UIKit が描き、SwiftUI の `typesettingLanguage` も窓の trait も届かない。
            // 英語だけの端末で和文の書名が□になったため、題を SwiftUI の Text で描き、和文の組みを当てる（tokens.md 3）。
            ToolbarItem(placement: .principal) {
                Text(verbatim: navigationTitleText)
                    .font(.headline)
                    .lineLimit(1)
                    .japaneseTextTypesetting()
                    .accessibilityAddTraits(.isHeader)
            }
        }
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
        let displayTitle = book.isTitlePending ? String(localized: "widget.currentBookAsTitle") : book.title
        let nights = model.store.distinctNightCount(for: book.id)
        let mins = model.store.totalMinutes(for: book.id)
        // book.nights（英語は複数形）と book.total（分のまま。決定 82）。読み上げの分数は duration.minutes.spoken。
        let nightsText = String.localizedStringWithFormat(NSLocalizedString("book.nights", comment: ""), nights)
        let totalText = String(format: String(localized: "book.total"), ReadingWidgetStrings.durationMinutes(mins))
        let totalSpoken = String(format: String(localized: "book.total"), ReadingWidgetStrings.durationMinutesSpoken(mins))
        let reflection = (book.status == .finished)
            ? model.store.buildFinishReflectionSummary(for: book.id).map(BookTextFormat.finishReflection)
            : nil

        let formattedPublisher = BookTextFormat.publisherWithLabel(publisher: book.publisher, label: book.label)

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
            if let yr = book.publishedYear { parts.append(BookTextFormat.publishedYear(yr)) }
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
                    key: String(localized: "colophon.title.label"),
                    value: displayTitle,
                    id: "colophon.title",
                    isTitle: true
                )

                if !book.author.isEmpty {
                    colophonRow(
                        key: String(localized: "colophon.author.label"),
                        value: book.author,
                        id: "colophon.author"
                    )
                }

                if let formattedPublisher {
                    colophonRow(
                        key: String(localized: "colophon.publisher.label"),
                        value: formattedPublisher,
                        id: "colophon.publisher"
                    )
                }

                if let yr = book.publishedYear {
                    let yrText = BookTextFormat.publishedYear(yr)
                    colophonRow(
                        key: String(localized: "colophon.year.label"),
                        value: yrText,
                        id: "colophon.year"
                    )
                }

                if let awardDisplay {
                    colophonRow(
                        key: String(localized: "colophon.award.label"),
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
                    .accessibilityLabel(totalSpoken)
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
                Text(String(localized: "book.edit.isEbook"))
                    .font(.subheadline)
                    .foregroundStyle(palette.textPrimary)
                Spacer()
                Toggle(String(localized: "book.edit.isEbook"), isOn: Binding(
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
                unitButton(book: book, unit: .page, title: String(localized: "mark.progressUnit.page"), id: "book.unit.page")
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
        let deleteTitle = book.title.isEmpty ? ReadingWidgetStrings.currentBookAsTitle : book.title
        let confirmMessage = bookRecordCount > 0
            ? String.localizedStringWithFormat(NSLocalizedString("book.delete.confirm", comment: ""), deleteTitle, bookRecordCount)
            : String(format: String(localized: "book.delete.confirm.noRecords"), deleteTitle)

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
                    Text(String(localized: "bookmark.finish"))
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
                    Text(String(localized: "finish.card.share"))
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
                Text(String(localized: "book.edit"))
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("book.edit")

            // design 5 と screens.md の S-7：奥付がそろった本でも「奥付を撮って補う」は常に出す。
            Button {
                model.currentScreen = .colophonScan
                detailSheet = .colophonOCR
                model.notifyHookChanged()
            } label: {
                Label("colophon.capture", systemImage: "text.viewfinder")
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("colophon.capture")

            Button(role: .destructive) {
                showDeleteBookConfirm = true
                model.notifyHookChanged()
            } label: {
                HStack(spacing: ThemeSpace.s8) {
                    Image(systemName: "trash")
                        .foregroundStyle(palette.destructive)
                        .accessibilityHidden(true)
                    Text(String(localized: "book.delete"))
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
                            Text(String(localized: "book.delete.confirmButton"))
                        }
                        .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                        .accessibilityIdentifier("book.delete.confirmButton")

                        Button {
                            showDeleteBookConfirm = false
                            model.notifyHookChanged()
                        } label: {
                            Text(String(localized: "book.edit.cancel"))
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
                    Text(String(localized: "after.header"))
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
                                    Text(String(localized: "book.readThis"))
                                }
                                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                                .accessibilityIdentifier("after.readThis")
                            } else if isAlreadyInShelf {
                                Text(String(localized: "after.added"))
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
                                    Text(String(localized: "after.addToShelf"))
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
            Text(String(localized: "book.records.header"))
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            if bookRecords.isEmpty {
                Text(String(localized: "book.records.empty"))
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .accessibilityIdentifier("book.records.empty")
            } else {
                ForEach(bookRecords) { rec in
                    let rowId = "book.record.row.\(rec.id.uuidString.lowercased())"
                    // design/ 6 の S-7：読み上げは `book.record.spoken`（「10月17日の晩、10分」）、見える文字は「10/17」と `duration.minutes`（決定 60、82）。
                    let rowDayShort = BookTextFormat.nightDayText(rec.nightDate, wide: false)
                    let rowMinutes = ReadingWidgetStrings.durationMinutes(rec.durationMinutes)
                    let rowLabel = String(
                        format: String(localized: "book.record.spoken"),
                        BookTextFormat.nightDayText(rec.nightDate),
                        ReadingWidgetStrings.durationMinutesSpoken(rec.durationMinutes)
                    )

                    Button {
                        model.store.activeErrorKey = nil
                        model.currentScreen = .recordEdit
                        detailSheet = .editRecord(rec.id)
                        model.notifyHookChanged()
                    } label: {
                        VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                            HStack {
                                Text(rowDayShort)
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(palette.textSecondary)
                                Spacer()
                                Text(rowMinutes)
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
                    .accessibilityInputLabels([Text(verbatim: rowDayShort), Text(verbatim: rowLabel)])
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
    @Environment(\.themePalette) private var palette

    public init(model: ReadingAppModel, book: BookSnapshot, onClose: @escaping () -> Void) {
        self.model = model
        self.book = book
        self.onClose = onClose
        // design/ 5 の S-7a：今の本の値をそのまま欄に出す（著者が空の本は空で始まる。名無しの今の本の書名も空で始まる）。
        _editedTitle = State(initialValue: book.isTitlePending ? "" : book.title)
        _editedAuthor = State(initialValue: book.author)
        _editedPublisher = State(initialValue: book.publisher ?? "")
        _editedLabel = State(initialValue: book.label ?? "")
        _editedYear = State(initialValue: book.publishedYear.map(String.init) ?? "")
        _editedIsEbook = State(initialValue: book.isEbook)
        _editedUnit = State(initialValue: book.progressUnit)
    }

    public var body: some View {
        let titleLabel = String(localized: "book.edit.title")
        let authorLabel = String(localized: "book.edit.author")

        return VStack(spacing: 0) {
            SheetHeaderBar(
                title: String(localized: "book.edit.navTitle"),
                cancelTitle: String(localized: "book.edit.cancel"),
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
                        TextField(titleLabel, text: $editedTitle)
                        .themeField(palette)
                        .accessibilityIdentifier("book.edit.title")
                        .accessibilityLabel(titleLabel)
                    }

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(authorLabel)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                        TextField(authorLabel, text: $editedAuthor)
                        .themeField(palette)
                        .accessibilityIdentifier("book.edit.author")
                        .accessibilityLabel(authorLabel)
                    }

                    HStack {
                        Text(String(localized: "book.edit.isEbook"))
                            .font(.body)
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        Toggle(String(localized: "book.edit.isEbook"), isOn: $editedIsEbook)
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

                    Picker(String(localized: "mark.progressUnit.label"), selection: $editedUnit) {
                        Text(String(localized: "mark.progressUnit.page")).tag(ProgressUnit.page)
                        Text(String(localized: "mark.progressUnit.location")).tag(ProgressUnit.location)
                        Text("%").tag(ProgressUnit.percent)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("book.edit.progressUnit")
                }
                .padding(ThemeSpace.s24)
            }

            VStack(spacing: 0) {
                Button {
                    // 欄の値をそのまま渡す。書名が空なら book.title.invalid、著者が空なら著者なしで保存（design/ 5 の S-7a、AC-8）。
                    let res = model.store.updateBook(
                        bookId: book.id,
                        title: editedTitle,
                        author: editedAuthor,
                        isEbook: editedIsEbook,
                        progressUnit: editedUnit
                    )
                    if case .success = res {
                        onClose()
                    }
                    model.notifyHookChanged()
                } label: {
                    Text(String(localized: "book.edit.save"))
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
        let minutesLabel = String(localized: "record.minutes.label")

        return VStack(spacing: 0) {
            SheetHeaderBar(
                title: String(localized: "record.navTitle"),
                cancelTitle: String(localized: "record.cancel"),
                cancelIdentifier: "record.cancel",
                onCancel: onClose
            )

            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s16) {
                    BannerNoticeView(model: model)

                    HStack {
                        // design/ 6 の S-7b：`record.night`「10月16日の晩」（読むだけ）。
                        Text(String(format: String(localized: "record.night"), BookTextFormat.nightDayText(record.nightDate)))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(palette.textPrimary)
                            .accessibilityIdentifier("record.night")
                        Spacer(minLength: 0)
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
                            Text(String(localized: "record.delete"))
                                .foregroundStyle(palette.textPrimary)
                        }
                    }
                    .buttonStyle(ThemeSecondaryButtonStyle(palette: palette, isDestructive: true))
                    .accessibilityIdentifier("record.delete")

                    if showDeleteConfirm {
                        VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                            Text(String(format: String(localized: "record.delete.confirm"), record.nightDate))
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
                                    Text(String(localized: "record.delete.confirmButton"))
                                }
                                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                                .accessibilityIdentifier("record.delete.confirmButton")

                                Button {
                                    showDeleteConfirm = false
                                    model.notifyHookChanged()
                                } label: {
                                    Text(String(localized: "record.cancel"))
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
                    Text(String(localized: "record.save"))
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
                cancelTitle: String(localized: "mark.cancel"),
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

    private var isCameraDenied: Bool {
        let status = CameraAndOCRService.currentCameraAuthorizationStatus(overrideStatus: model.store.cameraAuthorization)
        return status == "denied" || status == "restricted"
    }

    public var body: some View {
        let authorFieldLabel = String(localized: "colophon.author.label")
        let publisherFieldLabel = String(localized: "colophon.publisher.label")
        let yearFieldLabel = String(localized: "colophon.year.label")
        let isbnFieldLabel = "ISBN-13"

        return VStack(spacing: 0) {
            SheetHeaderBar(
                title: String(localized: "colophon.capture"),
                cancelTitle: String(localized: "book.edit.cancel"),
                cancelIdentifier: "colophon.cancel",
                onCancel: onClose
            )

            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s16) {
                    BannerNoticeView(model: model)

                    if isCameraDenied {
                        // S-7c の「カメラ許可が拒否」（design 5）：camera.denied と camera.openSettings。
                        VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                            Label {
                                Text(String(localized: "camera.denied"))
                                .fixedSize(horizontal: false, vertical: true)
                            } icon: {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(palette.stateError)
                            }
                            .font(.subheadline)
                            .foregroundStyle(palette.textPrimary)
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("camera.denied")

                            Button {
                                model.store.openExternalURL("app-settings:")
                                model.notifyHookChanged()
                            } label: {
                                Text(String(localized: "camera.openSettings"))
                            }
                            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                            .accessibilityIdentifier("camera.openSettings")
                        }
                    }

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
                    Text(String(localized: "colophon.save"))
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

#Preview("S-6/empty") {
    NavigationStack {
        ShelfListView(model: ReadingAppModel(), previewState: .empty)
    }
}

#Preview("S-6/loadError") {
    NavigationStack {
        ShelfListView(model: ReadingAppModel(), previewState: .loadError)
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
