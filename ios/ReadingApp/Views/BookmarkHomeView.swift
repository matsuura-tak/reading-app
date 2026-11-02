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
    @Environment(\.themePalette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        if !model.store.books.isEmpty {
            let candidates = model.store.buildNoCurrentCandidates()
            return .noCurrentWithTsundoku(candidates: candidates)
        }
        return .noBooks
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: ThemeSpace.s24) {
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
                .padding(.horizontal, ThemeSpace.s24)
                .padding(.vertical, ThemeSpace.s24)
            }
            // 下端に固定した「読み始める」の帯は safeAreaBar で置く（design/ 決まり 59）。スクロールの中身は帯の分だけ
            // 下に余白が付き、最後の行まで帯の上へ送れる。帯の裏に入る中身は OS の端の効果でぼかし、帯に自作の背景は
            // 付けない（G3 r2 の AX5 の S-1 の指摘）。
            .safeAreaBar(edge: .bottom) {
                if case .activeBook(let book) = resolvedState {
                    activeBookBottomBar(book: book)
                }
            }
        }
        .background(palette.bgPrimary.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.bookmark")
        .navigationTitle(AppL10n.pick("しおり", "Bookmark"))
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
                    Label(AppL10n.pick("本棚", "Shelf"), systemImage: "books.vertical")
                        .foregroundStyle(palette.actionTint)
                }
                .accessibilityIdentifier("toolbar.shelf")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.activeTab = .settings
                    model.currentScreen = .settingsMain
                    model.navigationPath.append(.settings)
                    model.notifyHookChanged()
                } label: {
                    Label(AppL10n.pick("設定", "Settings"), systemImage: "gearshape")
                        .foregroundStyle(palette.actionTint)
                }
                .accessibilityIdentifier("toolbar.settings")
            }
        }
        .onAppear {
            if model.navigationPath.isEmpty {
                model.activeTab = .bookmark
                model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
            }
            model.updateScreenStateFlags()
            model.notifyHookChanged()
        }
    }

    private var storeLoadFailedSection: some View {
        let errorMsg = AppL10n.pick(
            "データを読み込めませんでした。端末の空き容量を確かめて、もう一度お試しください。",
            "Could not load your data. Check available storage and try again."
        )
        return ContentUnavailableView {
            Label(
                AppL10n.pick("データの読み込みに失敗しました", "Could Not Load Data"),
                systemImage: "exclamationmark.triangle"
            )
            .foregroundStyle(palette.textPrimary)
        } description: {
            Text(errorMsg)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .accessibilityIdentifier("store.load.error")
                .accessibilityLabel(errorMsg)
                .accessibilityValue(errorMsg)
        } actions: {
            Button {
                model.store.loadFromDisk()
                model.notifyHookChanged()
            } label: {
                Text(AppL10n.pick("もう一度読み込む", "Try Again"))
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("store.retry")
        }
        .padding(.vertical, ThemeSpace.s32)
    }

    private var noBooksSection: some View {
        let emptyDesc = AppL10n.pick(
            "いま読んでいる本を1冊置くと、ここから1タップで読み始められます。",
            "Add the book you are reading to start with a single tap."
        )
        return ContentUnavailableView {
            Label(
                AppL10n.pick("まだ本が置かれていません", "No Books Yet"),
                systemImage: "book.closed"
            )
            .foregroundStyle(palette.textPrimary)
        } description: {
            Text(emptyDesc)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .accessibilityIdentifier("bookmark.empty.message")
                .accessibilityLabel(emptyDesc)
                .accessibilityValue(emptyDesc)
        } actions: {
            Button {
                model.currentScreen = .bookAddActionSheet
                model.activeSheet = .addBook(titlePendingMode: false)
                model.notifyHookChanged()
            } label: {
                Text(AppL10n.pick("本を加える", "Add a Book"))
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("bookmark.addBook")
        }
        .padding(.vertical, ThemeSpace.s32)
    }

    private func noCurrentWithTsundokuSection(candidates: [BookSnapshot]) -> some View {
        let msg = AppL10n.pick(
            "いま読む本が選ばれていません",
            "No Current Book Selected"
        )
        let subMsg = AppL10n.pick(
            "積読から選ぶか、新しい本を加えられます。",
            "Choose from your stack or add a new book."
        )
        return VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            VStack(spacing: ThemeSpace.s8) {
                Image(systemName: "books.vertical")
                    .font(.largeTitle)
                    .foregroundStyle(palette.textSecondary)
                    .accessibilityHidden(true)

                Text(msg)
                    .font(.title3.bold())
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("bookmark.noCurrent.message")
                    .accessibilityLabel(msg)
                    .accessibilityValue(msg)

                Text(subMsg)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ThemeSpace.s16)

            if !candidates.isEmpty {
                Text(AppL10n.pick("積読からすぐ読む", "Read Next from Stack"))
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.textSecondary)

                ForEach(Array(candidates.prefix(3).enumerated()), id: \.element.id) { _, book in
                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(book.title)
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)
                            .accessibilityIdentifier("bookmark.noCurrent.title.\(book.id.uuidString.lowercased())")
                            .accessibilityLabel(book.title)
                            .accessibilityValue(book.title)

                        if !book.author.isEmpty {
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)
                        }

                        Button {
                            if model.store.switchToCurrentBook(bookId: book.id) {
                                model.currentScreen = .bookmarkCurrent
                            }
                            model.notifyHookChanged()
                        } label: {
                            Text(AppL10n.pick("これを読む", "Read This"))
                        }
                        .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                        .accessibilityIdentifier("bookmark.noCurrent.choose")
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
                    .accessibilityIdentifier("bookmark.noCurrent.next.\(book.id.uuidString.lowercased())")
                }
            }

            VStack(spacing: ThemeSpace.s12) {
                Button {
                    model.store.clock.beginInterval(.shelfOpen)
                    model.activeTab = .shelf
                    model.currentScreen = .shelfList
                    model.navigationPath.append(.shelf)
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("本棚を開く", "Open Shelf"))
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("bookmark.openShelf")

                Button {
                    model.currentScreen = .bookAddActionSheet
                    model.activeSheet = .addBook(titlePendingMode: false)
                    model.notifyHookChanged()
                } label: {
                    Text(AppL10n.pick("本を加える", "Add a Book"))
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("bookmark.addBook")
            }
            .padding(.top, ThemeSpace.s8)
        }
    }

    private func activeBookSection(book: BookSnapshot) -> some View {
        let displayTitle = book.isTitlePending ? AppL10n.pick("今の本", "Reading Now") : book.title
        let progressStr = InputValidator.formatProgressDisplay(
            unit: book.progressUnit,
            page: book.currentPage,
            location: book.currentLocation,
            percent: book.currentPercent.map(Double.init),
            strings: ReadingWidgetStrings.spoken
        )

        return VStack(spacing: ThemeSpace.s32) {
            VStack(spacing: ThemeSpace.s8) {
                Text(displayTitle)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("bookmark.title")
                    .accessibilityLabel(displayTitle)
                    .accessibilityValue(displayTitle)

                if !book.author.isEmpty {
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("bookmark.author")
                        .accessibilityLabel(book.author)
                        .accessibilityValue(book.author)
                }

                if let progressStr, !progressStr.isEmpty {
                    Text(progressStr)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(palette.textSecondary)
                        .accessibilityIdentifier("bookmark.page")
                        .accessibilityLabel(progressStr)
                        .accessibilityValue(progressStr)
                } else {
                    let emptyProgress = AppL10n.pick("まだ記録はありません", "No position saved yet")
                    Text(emptyProgress)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .accessibilityIdentifier("bookmark.page")
                        .accessibilityLabel(emptyProgress)
                        .accessibilityValue(emptyProgress)
                }

                // AX1 以上は一行が横書きになり長くなるため、ボタンより上に置き、下端の bookmark.start の裏に回らないようにする
                // （G3 r2 verifier の S1_normal_ax5）。
                if dynamicTypeSize.isAccessibilitySize {
                    VerticalBookmarkTextView(line: book.lastSavedLine)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }

                secondaryActionButtons(book: book)
                    .padding(.top, ThemeSpace.s8)
            }
            .frame(maxWidth: .infinity)

            if !dynamicTypeSize.isAccessibilitySize {
                VerticalBookmarkTextView(line: book.lastSavedLine)
                    .frame(maxWidth: .infinity, minHeight: 200)
            }

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: ThemeSpace.s8) {
                    flipHints(book: book)
                }
                .frame(maxWidth: .infinity)
            }

            #if UITEST_HOOKS
            if UITestHookCoordinator.shared.areReadoutsEnabled {
                InvisibleAccessibleButtonRepresentable(
                    identifier: "bookmark.addBook",
                    label: AppL10n.pick("本を加える", "Add a Book")
                ) {
                    model.currentScreen = .bookAddActionSheet
                    model.activeSheet = .addBook(titlePendingMode: false)
                    model.notifyHookChanged()
                }
                .frame(minWidth: 44, maxWidth: 44, minHeight: 44, maxHeight: 44)
            }
            #endif
        }
    }

    @ViewBuilder
    private func secondaryActionButtons(book: BookSnapshot) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: ThemeSpace.s8) {
                if book.isTitlePending {
                    setBookTitleButton
                }
                setMarkButton
                finishBookButton(book: book)
            }
        } else {
            VStack(spacing: ThemeSpace.s8) {
                if book.isTitlePending {
                    setBookTitleButton
                }
                HStack(spacing: ThemeSpace.s12) {
                    setMarkButton
                    finishBookButton(book: book)
                }
            }
        }
    }

    private var setBookTitleButton: some View {
        Button {
            model.currentScreen = .bookAddActionSheet
            model.activeSheet = .addBook(titlePendingMode: true)
            model.notifyHookChanged()
        } label: {
            Text(AppL10n.pick("書名を入れる", "Set Book Title"))
        }
        .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
        .accessibilityIdentifier("bookmark.setBookTitle")
    }

    private var setMarkButton: some View {
        Button {
            model.store.pendingMarkRecordId = nil
            model.currentScreen = .bookmarkMarkSelect
            model.activeSheet = .markFlow
            model.notifyHookChanged()
        } label: {
            Text(AppL10n.pick("しおりを挟む", "Place Bookmark"))
        }
        .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
        .accessibilityIdentifier("bookmark.setMark")
    }

    private func finishBookButton(book: BookSnapshot) -> some View {
        Button {
            if model.store.markBookFinished(bookId: book.id) {
                model.currentScreen = .finishNight
                model.activeSheet = .finishNight(bookId: book.id)
            }
            model.notifyHookChanged()
        } label: {
            Text(AppL10n.pick("読み終えた", "Finish Book"))
        }
        .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
        .accessibilityIdentifier("bookmark.finish")
    }

    private func activeBookBottomBar(book: BookSnapshot) -> some View {
        VStack(spacing: ThemeSpace.s8) {
            Button {
                #if UITEST_HOOKS
                UITestHookCoordinator.shared.syncAllDarwinTokenStates()
                #endif
                if model.store.startReadingSession(startedBy: "tap", explicitEntry: nil) {
                    model.currentScreen = .sessionActive
                }
                model.notifyHookChanged()
            } label: {
                Text(AppL10n.pick("読み始める", "Start Reading"))
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("bookmark.start")

            // AX1 以上では伏せる案内をスクロールの一番下に移し、帯は「読み始める」だけにする（design/ 9 の S-1）。
            if !dynamicTypeSize.isAccessibilitySize {
                flipHints(book: book)
            }
        }
        .padding(.horizontal, ThemeSpace.s24)
        .padding(.top, ThemeSpace.s12)
        .padding(.bottom, ThemeSpace.s16)
    }

    /// 伏せる案内（紙の本は `bookmark.flipHint`、電子書籍は `bookmark.flipHint.ebook`）。
    @ViewBuilder
    private func flipHints(book: BookSnapshot) -> some View {
        if book.isEbook {
            Text(
                AppL10n.pick(
                    "電子書籍アプリへ移っても数え続けます。終えるときはロック画面の『終える』を押してください。",
                    "Keeps counting while you read in your e-book app. Tap End Reading on the Lock Screen when done."
                )
            )
            .font(.footnote)
            .foregroundStyle(palette.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("bookmark.flipHint.ebook")
        }

        if model.store.isFlipAvailable && model.store.settings.flipToStartEnabled {
            Text(AppL10n.pick("伏せても始まります", "Or place iPhone face down to start"))
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("bookmark.flipHint")
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
