import SwiftUI
import ReadingCore
import ReadingStore

public enum FinishNightViewState: Equatable, Sendable {
    case withReflection(title: String, author: String, summary: String, reflection: String, candidates: [RecommendationCandidate])
    case withoutReflection(title: String, author: String, summary: String, candidates: [RecommendationCandidate])
}

public struct FinishNightView: View {
    @Bindable var model: ReadingAppModel
    public let bookId: UUID
    public let previewState: FinishNightViewState?
    @Environment(\.themePalette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showShareCardSheet = false
    @State private var showColophonSheet = false
    @State private var cachedCandidates: [RecommendationCandidate]?
    @State private var addedCandidateIDs: Set<String> = []

    public init(model: ReadingAppModel, bookId: UUID, previewState: FinishNightViewState? = nil) {
        self.model = model
        self.bookId = bookId
        self.previewState = previewState
    }

    private var book: BookSnapshot? {
        model.store.books.first { $0.id == bookId }
    }

    private var resolvedState: FinishNightViewState {
        if let previewState { return previewState }
        let title = book?.title ?? ""
        let author = book?.author ?? ""
        let nights = model.store.distinctNightCount(for: bookId)
        let mins = model.store.totalMinutes(for: bookId)
        let summary = BookTextFormat.nightsAndMinutes(nights: nights, minutes: mins)
        let candidates = cachedCandidates ?? model.store.buildNextBookCandidates(for: bookId)
        if let reflectionSummary = model.store.buildFinishReflectionSummary(for: bookId) {
            let reflection = BookTextFormat.finishReflection(reflectionSummary)
            return .withReflection(title: title, author: author, summary: summary, reflection: reflection, candidates: candidates)
        }
        return .withoutReflection(title: title, author: author, summary: summary, candidates: candidates)
    }

    private var resolvedCandidates: [RecommendationCandidate] {
        switch resolvedState {
        case .withReflection(_, _, _, _, let candidates):
            return candidates
        case .withoutReflection(_, _, _, let candidates):
            return candidates
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            SheetHeaderBar(
                title: String(localized: "finish.title"),
                leftTitle: String(localized: "finish.close"),
                leftId: "finish.close",
                onLeft: {
                    closeFinishNight(candidates: resolvedCandidates)
                }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s24) {
                    BannerNoticeView(model: model)

                    switch resolvedState {
                    case .withReflection(let title, let author, let summary, let reflection, let candidates):
                        headerSection(title: title, author: author, summary: summary, reflection: reflection)
                        shareCardButtonSection
                        gatedCandidatesSection(candidates: candidates)
                        skipButtonSection(candidates: candidates)
                    case .withoutReflection(let title, let author, let summary, let candidates):
                        headerSection(title: title, author: author, summary: summary, reflection: nil)
                        shareCardButtonSection
                        gatedCandidatesSection(candidates: candidates)
                        skipButtonSection(candidates: candidates)
                    }
                }
                .padding(.horizontal, ThemeSpace.s24)
                .padding(.vertical, ThemeSpace.s16)
            }
        }
        .background(palette.bgPrimary.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.finishNight")
        .sheet(isPresented: $showShareCardSheet) {
            if let book {
                ShareCardPreviewSheetView(model: model, book: book) {
                    showShareCardSheet = false
                    model.currentScreen = .finishNight
                    model.notifyHookChanged()
                }
            }
        }
        .sheet(isPresented: $showColophonSheet) {
            ColophonOCRSheetView(model: model, bookId: bookId) {
                showColophonSheet = false
                model.currentScreen = .finishNight
                model.notifyHookChanged()
            }
        }
        .onAppear {
            if cachedCandidates == nil && previewState == nil {
                cachedCandidates = model.store.buildNextBookCandidates(for: bookId)
            }
            model.currentScreen = .finishNight
            model.notifyHookChanged()
        }
    }

    private func closeFinishNight(candidates: [RecommendationCandidate]) {
        let allCats = candidates.map { $0.axis.rawValue }
        model.store.recordRecommendationFeedback(
            chosenCategory: nil,
            allShownCategories: allCats
        )
        model.activeSheet = nil
        model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
        model.notifyHookChanged()
    }

    private func headerSection(title: String, author: String, summary: String, reflection: String?) -> some View {
        let displayTitle = title.isEmpty ? ReadingWidgetStrings.currentBookAsTitle : title
        let formattedPublisher = BookTextFormat.publisherWithLabel(publisher: book?.publisher, label: book?.label)
        let matchedAwards = AwardsCatalog.matchAwards(
            title: title,
            author: author,
            catalog: model.store.activeAwards
        )
        let awardDisplay: String? = {
            guard !matchedAwards.isEmpty else { return nil }
            return matchedAwards.map { "\($0.sessionOrYear) \($0.award)" }.joined(separator: " / ")
        }()
        let combinedColophonLabel: String = {
            var parts: [String] = [displayTitle]
            if !author.isEmpty { parts.append(author) }
            if let formattedPublisher { parts.append(formattedPublisher) }
            if let yr = book?.publishedYear { parts.append(BookTextFormat.publishedYear(yr)) }
            if let awardDisplay { parts.append(awardDisplay) }
            return parts.joined(separator: " ")
        }()

        return VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            Text(String(localized: "finish.title"))
                .font(.largeTitle.bold())
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("finish.title")

            Text(summary)
                .font(.headline.monospacedDigit())
                .foregroundStyle(palette.textPrimary)
                .accessibilityIdentifier("finish.summary")
                .accessibilityLabel(summary)
                .accessibilityValue(summary)

            if let reflection {
                Text(reflection)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("finish.reflection")
                    .accessibilityLabel(reflection)
                    .accessibilityValue(reflection)
            }

            VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                Rectangle()
                    .fill(palette.hairline)
                    .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)

                colophonRow(
                    key: String(localized: "colophon.title.label"),
                    value: displayTitle,
                    id: "colophon.title"
                )

                if !author.isEmpty {
                    colophonRow(
                        key: String(localized: "colophon.author.label"),
                        value: author,
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

                if let yr = book?.publishedYear {
                    colophonRow(
                        key: String(localized: "colophon.year.label"),
                        value: BookTextFormat.publishedYear(yr),
                        id: "colophon.year",
                        monospaced: true
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
            }
            .padding(.vertical, ThemeSpace.s4)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("finish.colophon")
            .accessibilityLabel(combinedColophonLabel)

            Button {
                model.currentScreen = .colophonScan
                showColophonSheet = true
                model.notifyHookChanged()
            } label: {
                Text("colophon.capture")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("colophon.capture")
        }
    }

    @ViewBuilder
    private func colophonRow(key: String, value: String, id: String, monospaced: Bool = false) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                Text(key)
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                Text(value)
                    .font(monospaced ? .subheadline.monospacedDigit() : .subheadline)
                    .foregroundStyle(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(id)
                    .accessibilityLabel(value)
                    .accessibilityValue(value)
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: ThemeSpace.s12) {
                Text(key)
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .frame(minWidth: 108, alignment: .leading)
                Text(value)
                    .font(monospaced ? .subheadline.monospacedDigit() : .subheadline)
                    .foregroundStyle(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(id)
                    .accessibilityLabel(value)
                    .accessibilityValue(value)
                Spacer(minLength: 0)
            }
        }
    }

    private var shareCardButtonSection: some View {
        Button {
            if let book {
                let nights = model.store.distinctNightCount(for: bookId)
                let mins = model.store.totalMinutes(for: bookId)
                let rendered = FinishCardRenderer.renderCard(
                    title: book.title,
                    author: book.author,
                    nightsCount: nights,
                    totalMinutes: mins
                )
                model.store.recordShareCard(
                    for: bookId,
                    renderedTexts: rendered.renderedTexts,
                    widthPx: rendered.widthPx,
                    heightPx: rendered.heightPx
                )
            } else {
                model.store.recordShareCard(for: bookId)
            }
            model.currentScreen = .shareCardPreview
            showShareCardSheet = true
            model.notifyHookChanged()
        } label: {
            Text(String(localized: "finish.card.share"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
        .accessibilityIdentifier("finish.card.share")
    }

    // H33 recommend.load：0.3秒を超えたら候補の行の形の灰の帯（design 5 の S-9）。
    private func gatedCandidatesSection(candidates: [RecommendationCandidate]) -> some View {
        GatedLoadView(gate: model.store.loadGate, point: .recommendLoad) {
            candidatesSection(candidates: candidates)
        } placeholder: {
            RedactedRowsPlaceholderView(rowCount: 3)
        }
    }

    private func candidatesSection(candidates: [RecommendationCandidate]) -> some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s12) {
            Text(String(localized: "next.header"))
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            if candidates.isEmpty {
                VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                    Text(String(localized: "next.empty.message"))
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("next.empty.message")

                    Button {
                        model.currentScreen = .bookAddActionSheet
                        model.activeSheet = .addBook(titlePendingMode: false)
                        model.notifyHookChanged()
                    } label: {
                        Text(String(localized: "next.addBook"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                    .accessibilityIdentifier("next.addBook")
                }
                .padding(ThemeSpace.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: ThemeRadius.card)
                        .fill(palette.groupedRow)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.card)
                        .strokeBorder(palette.hairline, lineWidth: 1)
                )
            } else {
                ForEach(Array(candidates.prefix(3).enumerated()), id: \.element.id) { _, cand in
                    let candIdentifier = cand.bookId?.uuidString.lowercased() ?? cand.isbn13 ?? cand.id
                    let isAdded = addedCandidateIDs.contains(candIdentifier)
                    let combinedCandidateLabel = [cand.title, cand.author, cand.reason]
                        .compactMap { item -> String? in
                            guard let item, !item.isEmpty else { return nil }
                            return item
                        }
                        .joined(separator: " ")

                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(cand.reason)
                            .font(.footnote)
                            .foregroundStyle(palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("next.reason")
                            .accessibilityLabel(cand.reason)
                            .accessibilityValue(cand.reason)

                        Text(cand.title)
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("next.title")
                            .accessibilityLabel(cand.title)
                            .accessibilityValue(cand.title)

                        if let author = cand.author, !author.isEmpty {
                            Text(author)
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("next.author")
                        }

                        if cand.isOwnedTsundoku, let candBookId = cand.bookId {
                            Button {
                                let allCats = candidates.map { $0.axis.rawValue }
                                model.store.recordRecommendationFeedback(
                                    chosenCategory: cand.axis.rawValue,
                                    allShownCategories: allCats
                                )
                                if model.store.switchToCurrentBook(bookId: candBookId) {
                                    model.activeSheet = nil
                                    model.currentScreen = .bookmarkCurrent
                                }
                                model.notifyHookChanged()
                            } label: {
                                Text(String(localized: "next.choose"))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                            .accessibilityIdentifier("next.choose")
                        } else if isAdded {
                            Text(String(localized: "next.added"))
                                .font(.footnote.bold())
                                .foregroundStyle(palette.textSecondary)
                                .accessibilityIdentifier("next.added")
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
                                    addedCandidateIDs.insert(candIdentifier)
                                }
                                model.notifyHookChanged()
                            } label: {
                                Text(String(localized: "next.addToShelf"))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                            .accessibilityIdentifier("next.addToShelf")
                        }
                    }
                    .padding(ThemeSpace.s16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: ThemeRadius.card)
                            .fill(palette.groupedRow)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ThemeRadius.card)
                            .strokeBorder(palette.hairline, lineWidth: 1)
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("next.candidate.\(candIdentifier)")
                    .accessibilityLabel(combinedCandidateLabel)
                }
            }
        }
    }

    private func skipButtonSection(candidates: [RecommendationCandidate]) -> some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s12) {
            Button {
                closeFinishNight(candidates: candidates)
            } label: {
                Text(String(localized: "next.skip"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("next.skip")

            Text(String(localized: "finish.undoNote"))
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("finish.undoNote")
        }
    }
}

#Preview("S-9 Finish Night With Reflection") {
    let model = ReadingAppModel()
    let c1 = RecommendationCandidate(
        id: "1",
        bookId: ReadingDataStore.uuidBookB,
        isbn13: "9784101010014",
        title: "こころ",
        author: "夏目漱石",
        publisher: "新潮社",
        label: "新潮文庫",
        axis: .readers,
        reason: RecommendationReasonStrings.localized.nextReaders,
        isOwnedTsundoku: true
    )
    FinishNightView(
        model: model,
        bookId: ReadingDataStore.uuidBookA,
        previewState: .withReflection(
            title: "羅生門",
            author: "芥川龍之介",
            summary: BookTextFormat.nightsAndMinutes(nights: 4, minutes: 85),
            reflection: "4晩、合計85分（1時間25分）。いちばん長かったのは10月18日の晩の30分でした。",
            candidates: [c1]
        )
    )
}

#Preview("S-9 Finish Night AX5 Dark") {
    let model = ReadingAppModel()
    FinishNightView(
        model: model,
        bookId: ReadingDataStore.uuidBookA,
        previewState: .withoutReflection(
            title: "羅生門",
            author: "芥川龍之介",
            summary: BookTextFormat.nightsAndMinutes(nights: 1, minutes: 20),
            candidates: []
        )
    )
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
