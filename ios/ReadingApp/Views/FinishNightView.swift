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

    @State private var showShareCardSheet = false

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
        let candidates = model.store.buildNextBookCandidates(for: bookId)
        if let reflection = model.store.buildFinishReflection(for: bookId) {
            return .withReflection(title: title, author: author, summary: summary, reflection: reflection, candidates: candidates)
        }
        return .withoutReflection(title: title, author: author, summary: summary, candidates: candidates)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    BannerNoticeView(model: model)

                    switch resolvedState {
                    case .withReflection(let title, let author, let summary, let reflection, let candidates):
                        headerSection(title: title, author: author, summary: summary, reflection: reflection)
                        shareCardButtonSection
                        candidatesSection(candidates: candidates)
                        skipButtonSection(candidates: candidates)
                    case .withoutReflection(let title, let author, let summary, let candidates):
                        headerSection(title: title, author: author, summary: summary, reflection: nil)
                        shareCardButtonSection
                        candidatesSection(candidates: candidates)
                        skipButtonSection(candidates: candidates)
                    }
                }
                .padding(20)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("screen.finishNight")
            .navigationTitle("読了の夜")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShareCardSheet) {
                if let book {
                    ShareCardPreviewSheetView(model: model, book: book) {
                        showShareCardSheet = false
                        model.currentScreen = .finishNight
                        model.notifyHookChanged()
                    }
                }
            }
            .onAppear {
                model.currentScreen = .finishNight
                model.notifyHookChanged()
            }
        }
    }

    private func headerSection(title: String, author: String, summary: String, reflection: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2.bold())
                .accessibilityIdentifier("finish.title")
                .accessibilityLabel(title)
                .accessibilityValue(title)

            if !author.isEmpty {
                Text(author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("finish.author")
                    .accessibilityLabel(author)
                    .accessibilityValue(author)
            }

            Text(summary)
                .font(.headline.monospacedDigit())
                .accessibilityIdentifier("finish.summary")
                .accessibilityLabel(summary)
                .accessibilityValue(summary)

            if let reflection {
                Text(reflection)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .accessibilityIdentifier("finish.reflection")
                    .accessibilityLabel(reflection)
                    .accessibilityValue(reflection)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var shareCardButtonSection: some View {
        Button {
            model.store.recordShareCard(for: bookId)
            model.currentScreen = .shareCardPreview
            showShareCardSheet = true
            model.notifyHookChanged()
        } label: {
            Text("読了カードを作る")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityIdentifier("finish.shareCard")
    }

    private func candidatesSection(candidates: [RecommendationCandidate]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("次の一冊を選ぶ")
                .font(.headline)

            ForEach(Array(candidates.prefix(3).enumerated()), id: \.element.id) { idx, cand in
                VStack(alignment: .leading, spacing: 8) {
                    Text(cand.reason)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("finish.candidate.\(idx + 1).reason")
                        .accessibilityLabel(cand.reason)
                        .accessibilityValue(cand.reason)

                    Text(cand.title)
                        .font(.headline)
                        .accessibilityIdentifier("finish.candidate.\(idx + 1).title")
                        .accessibilityLabel(cand.title)
                        .accessibilityValue(cand.title)

                    if let author = cand.author, !author.isEmpty {
                        Text(author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("finish.candidate.\(idx + 1).author")
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
                            Text("これを読み始める")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("finish.candidate.\(idx + 1).action")
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
                                ndc: cand.ndc,
                                forceTsundoku: true
                            )
                            if case .success = res {
                                model.activeSheet = nil
                                model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
                            }
                            model.notifyHookChanged()
                        } label: {
                            Text("積読に置く")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("finish.candidate.\(idx + 1).action")
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("finish.candidate.\(idx + 1)")
            }
        }
    }

    private func skipButtonSection(candidates: [RecommendationCandidate]) -> some View {
        Button {
            let allCats = candidates.map { $0.axis.rawValue }
            model.store.recordRecommendationFeedback(
                chosenCategory: nil,
                allShownCategories: allCats
            )
            model.activeSheet = nil
            model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
            model.notifyHookChanged()
        } label: {
            Text("あとで決める")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .accessibilityIdentifier("finish.skip")
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
        reason: "積読から・この本を読み終えた人が、次に読んだ本",
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
