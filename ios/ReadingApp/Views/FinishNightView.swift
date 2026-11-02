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
        let summary = "\(nights)晩・\(mins)分"
        let candidates = cachedCandidates ?? model.store.buildNextBookCandidates(for: bookId)
        if let reflection = model.store.buildFinishReflection(for: bookId) {
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
                title: AppL10n.pick("読了の夜", "Finished Reading"),
                leftTitle: AppL10n.pick("閉じる", "Close"),
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
        let formattedPublisher: String? = {
            let pub = book?.publisher?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let lbl = book?.label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !pub.isEmpty && !lbl.isEmpty {
                return "\(pub)（\(lbl)）"
            } else if !pub.isEmpty {
                return pub
            } else if !lbl.isEmpty {
                return lbl
            }
            return nil
        }()
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
            if let yr = book?.publishedYear { parts.append("\(yr)年") }
            if let awardDisplay { parts.append(awardDisplay) }
            return parts.joined(separator: " ")
        }()

        return VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            Text(AppL10n.pick("読み終えました", "Finished Reading"))
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
                    key: AppL10n.pick("書名", "Title"),
                    value: displayTitle,
                    id: "colophon.title"
                )

                if !author.isEmpty {
                    colophonRow(
                        key: AppL10n.pick("著者", "Author"),
                        value: author,
                        id: "colophon.author"
                    )
                }

                if let formattedPublisher {
                    colophonRow(
                        key: AppL10n.pick("出版社・レーベル", "Publisher"),
                        value: formattedPublisher,
                        id: "colophon.publisher"
                    )
                }

                if let yr = book?.publishedYear {
                    colophonRow(
                        key: AppL10n.pick("出版年", "Published"),
                        value: "\(yr)年",
                        id: "colophon.year",
                        monospaced: true
                    )
                }

                if let awardDisplay {
                    colophonRow(
                        key: AppL10n.pick("受賞", "Award"),
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
            Text(AppL10n.pick("読了カードを共有", "Share Finish Card"))
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
            Text(AppL10n.pick("次の1冊", "Your Next Book"))
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            if candidates.isEmpty {
                VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                    Text(AppL10n.pick("本棚から次の本を選ぶか、新しく登録できます。", "Choose your next book from the shelf or add a new one."))
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("next.empty.message")

                    Button {
                        model.currentScreen = .bookAddActionSheet
                        model.activeSheet = .addBook(titlePendingMode: false)
                        model.notifyHookChanged()
                    } label: {
                        Text(AppL10n.pick("新しい本を加える", "Add a New Book"))
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
                                Text(AppL10n.pick("これを今の本にする", "Make Current Book"))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                            .accessibilityIdentifier("next.choose")
                        } else if isAdded {
                            Text(AppL10n.pick("積読に置きました", "Added to Tsundoku"))
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
                                Text(AppL10n.pick("積読に置く", "Add to Tsundoku"))
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
                Text(AppL10n.pick("今は読まない", "Skip for Now"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("next.skip")

            Text(AppL10n.pick("本棚からいつでも『今の本』に戻せます。", "You can switch it back to Current Book anytime from the Shelf."))
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
            summary: "4晩・85分",
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
            summary: "1晩・20分",
            candidates: []
        )
    )
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
