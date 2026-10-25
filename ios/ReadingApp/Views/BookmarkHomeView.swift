import SwiftUI
import ReadingCore
import ReadingStore

public enum BookmarkHomeViewState: Equatable, Sendable {
    case storeLoadFailed
    case noBooks
    case noCurrentWithTsundoku(candidates: [BookSnapshot])
    case activeBook(book: BookSnapshot)
}

public struct BookmarkHomeView: View {
    @Bindable var model: ReadingAppModel
    public let previewState: BookmarkHomeViewState?

    public init(model: ReadingAppModel, previewState: BookmarkHomeViewState? = nil) {
        self.model = model
        self.previewState = previewState
    }

    private var resolvedState: BookmarkHomeViewState {
        if let previewState { return previewState }
        if model.store.isStoreLoadFailed {
            return .storeLoadFailed
        }
        if let current = model.store.currentBook {
            return .activeBook(book: current)
        }
        let candidates = model.store.buildNoCurrentCandidates()
        if !candidates.isEmpty {
            return .noCurrentWithTsundoku(candidates: candidates)
        }
        return .noBooks
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BannerNoticeView(model: model)

                switch resolvedState {
                case .storeLoadFailed:
                    storeLoadFailedSection
                case .noBooks:
                    noBooksSection
                case .noCurrentWithTsundoku(let candidates):
                    noCurrentWithTsundokuSection(candidates: candidates)
                case .activeBook(let book):
                    activeBookSection(book: book)
                }
            }
            .padding(20)
        }
        .accessibilityIdentifier("screen.bookmark")
        .navigationTitle("しおり")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    model.store.clock.beginInterval(.shelfOpen)
                    model.activeTab = .shelf
                    model.currentScreen = .shelfList
                    model.navigationPath.append(.shelf)
                    model.notifyHookChanged()
                } label: {
                    Label("本棚", systemImage: "books.vertical")
                }
                .accessibilityIdentifier("toolbar.shelf")
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    model.currentScreen = .bookAddActionSheet
                    model.activeSheet = .addBook(titlePendingMode: false)
                    model.notifyHookChanged()
                } label: {
                    Label("本を登録", systemImage: "plus")
                }
                .accessibilityIdentifier("bookmark.addBook")
                .disabled(model.store.isStoreLoadFailed)

                Button {
                    model.activeTab = .settings
                    model.currentScreen = .settingsMain
                    model.navigationPath.append(.settings)
                    model.notifyHookChanged()
                } label: {
                    Label("設定", systemImage: "gearshape")
                }
                .accessibilityIdentifier("toolbar.settings")
            }
        }
        .onAppear {
            model.activeTab = .bookmark
            model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
            model.updateScreenStateFlags()
            model.notifyHookChanged()
        }
    }

    private var storeLoadFailedSection: some View {
        VStack(spacing: 16) {
            Text("データを読み込めませんでした。")
                .font(.headline)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("error.store.load.error")
                .accessibilityLabel("データを読み込めませんでした。")
                .accessibilityValue("データを読み込めませんでした。")

            Button("読み始める") {}
                .buttonStyle(.borderedProminent)
                .disabled(true)
                .accessibilityIdentifier("bookmark.startReading")
        }
        .padding(.vertical, 32)
    }

    private var noBooksSection: some View {
        VStack(spacing: 16) {
            Text("いま読んでいる本はまだありません")
                .font(.headline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("bookmark.emptyTitle")

            Button {
                model.currentScreen = .bookAddActionSheet
                model.activeSheet = .addBook(titlePendingMode: false)
                model.notifyHookChanged()
            } label: {
                Text("最初の一冊を置く")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("bookmark.addFirstBook")
        }
        .padding(.vertical, 32)
    }

    private func noCurrentWithTsundokuSection(candidates: [BookSnapshot]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("次に読む本を選ぶ")
                .font(.headline)
                .accessibilityIdentifier("bookmark.noCurrent.header")

            ForEach(Array(candidates.prefix(3).enumerated()), id: \.element.id) { idx, book in
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.headline)
                        .accessibilityIdentifier("bookmark.noCurrent.candidate.\(idx + 1).title")
                        .accessibilityLabel(book.title)
                        .accessibilityValue(book.title)

                    if !book.author.isEmpty {
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        if model.store.switchToCurrentBook(bookId: book.id) {
                            model.currentScreen = .bookmarkCurrent
                        }
                        model.notifyHookChanged()
                    } label: {
                        Text("これを読み始める")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("bookmark.noCurrent.candidate.\(idx + 1).start")
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("bookmark.noCurrent.candidate.\(idx + 1)")
            }

            Button {
                model.currentScreen = .bookAddActionSheet
                model.activeSheet = .addBook(titlePendingMode: false)
                model.notifyHookChanged()
            } label: {
                Text("別の本を登録する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("bookmark.addFirstBook")
        }
    }

    private func activeBookSection(book: BookSnapshot) -> some View {
        let displayTitle = book.isTitlePending ? "あとで書名を入れる本" : book.title
        let progressStr = InputValidator.formatProgressDisplay(
            unit: book.progressUnit,
            page: book.currentPage,
            location: book.currentLocation,
            percent: book.currentPercent.map(Double.init)
        ) ?? ""

        return VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(displayTitle)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("bookmark.title")
                    .accessibilityLabel(displayTitle)
                    .accessibilityValue(displayTitle)

                if !book.author.isEmpty {
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("bookmark.author")
                        .accessibilityLabel(book.author)
                        .accessibilityValue(book.author)
                }

                if !progressStr.isEmpty {
                    Text(progressStr)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("bookmark.progress")
                        .accessibilityLabel(progressStr)
                        .accessibilityValue(progressStr)
                }
            }

            if book.isTitlePending {
                Button {
                    model.currentScreen = .bookAddActionSheet
                    model.activeSheet = .addBook(titlePendingMode: true)
                    model.notifyHookChanged()
                } label: {
                    Text("書名を入れる")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("bookmark.setTitle")
            }

            VerticalBookmarkTextView(line: book.lastSavedLine)
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

            Button {
                if model.store.startReadingSession(startedBy: "tap", explicitEntry: nil) {
                    model.currentScreen = .sessionActive
                }
                model.notifyHookChanged()
            } label: {
                Text("読み始める")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("bookmark.startReading")

            HStack(spacing: 12) {
                Button {
                    model.store.pendingMarkRecordId = nil
                    model.currentScreen = .bookmarkMarkSelect
                    model.activeSheet = .markFlow
                    model.notifyHookChanged()
                } label: {
                    Text("しおりを挟む")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("bookmark.updateMark")

                Button {
                    if model.store.markBookFinished(bookId: book.id) {
                        model.currentScreen = .finishNight
                        model.activeSheet = .finishNight(bookId: book.id)
                    }
                    model.notifyHookChanged()
                } label: {
                    Text("読み終えた")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("bookmark.finishBook")
            }
        }
    }
}

#Preview("S-1 Active Book") {
    let model = ReadingAppModel()
    let book = BookSnapshot(
        title: "羅生門",
        author: "芥川龍之介",
        status: .current,
        currentPage: 45,
        lastSavedLine: "ある日の暮方の事である。"
    )
    NavigationStack {
        BookmarkHomeView(model: model, previewState: .activeBook(book: book))
    }
}

#Preview("S-1 Empty") {
    let model = ReadingAppModel()
    NavigationStack {
        BookmarkHomeView(model: model, previewState: .noBooks)
    }
}

#Preview("S-1 NoCurrent Tsundoku") {
    let model = ReadingAppModel()
    let b1 = BookSnapshot(title: "こころ", author: "夏目漱石", status: .tsundoku)
    NavigationStack {
        BookmarkHomeView(model: model, previewState: .noCurrentWithTsundoku(candidates: [b1]))
    }
}

#Preview("S-1 AX5 Dark") {
    let model = ReadingAppModel()
    let book = BookSnapshot(
        title: "吾輩は猫である",
        author: "夏目漱石",
        status: .current,
        currentPage: 128,
        lastSavedLine: "吾輩は猫である。名前はまだ無い。"
    )
    NavigationStack {
        BookmarkHomeView(model: model, previewState: .activeBook(book: book))
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
