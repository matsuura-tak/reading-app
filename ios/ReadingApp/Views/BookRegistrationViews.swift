import SwiftUI
import ReadingCore
import ReadingStore

public enum BookAddStep: Equatable, Sendable {
    case menu
    case barcodeScanner
    case barcodeCameraDenied
    case barcodeUnhit(isbn13: String)
    case coverCamera(isbn13: String?)
    case coverCandidates(isbn13: String?, candidates: [String])
    case coverEmpty(isbn13: String?)
    case searchList
    case manualInput(isbn13: String?, prefillTitle: String, prefillAuthor: String, prefillPublisher: String?)
    case bookshelfCamera
    case bookshelfCandidates(spines: [BookshelfSpineCandidate], selectedIds: Set<String>)
}

public struct BookAddFlowSheetView: View {
    @Bindable var model: ReadingAppModel
    public let titlePendingMode: Bool

    @State private var step: BookAddStep = .menu
    @State private var searchQuery: String = ""
    @State private var searchResults: [H20BiblioItem] = []
    @State private var hasExecutedSearch = false
    @State private var manualTitle: String = ""
    @State private var manualAuthor: String = ""
    @State private var manualPublisher: String = ""
    @State private var manualISBN: String?
    @State private var didHandleBarcodeThisPresentation = false
    @State private var pendingSupplementalCode: String?

    public init(model: ReadingAppModel, titlePendingMode: Bool = false, initialStep: BookAddStep = .menu) {
        self.model = model
        self.titlePendingMode = titlePendingMode
        _step = State(initialValue: initialStep)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    BannerNoticeView(model: model)

                    switch step {
                    case .menu:
                        menuContent
                    case .barcodeScanner:
                        barcodeScannerContent
                    case .barcodeCameraDenied:
                        barcodeCameraDeniedContent
                    case .barcodeUnhit(let isbn13):
                        barcodeUnhitContent(isbn13: isbn13)
                    case .coverCamera(let isbn13):
                        coverCameraContent(isbn13: isbn13)
                    case .coverCandidates(let isbn13, let candidates):
                        coverCandidatesContent(isbn13: isbn13, candidates: candidates)
                    case .coverEmpty(let isbn13):
                        coverEmptyContent(isbn13: isbn13)
                    case .searchList:
                        searchListContent
                    case .manualInput:
                        manualInputContent
                    case .bookshelfCamera:
                        bookshelfCameraContent
                    case .bookshelfCandidates(let spines, let selectedIds):
                        bookshelfCandidatesContent(spines: spines, selectedIds: selectedIds)
                    }
                }
                .padding(20)
            }
            .navigationTitle(titlePendingMode ? "書名を入れる" : "本を登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        closeSheet()
                    }
                    .accessibilityIdentifier("addBook.close")
                }
            }
        }
        .onChange(of: model.barcodeEventCounter) { _, _ in
            processPendingBarcodesIfNeeded()
        }
        .onAppear {
            model.currentScreen = .bookAddActionSheet
            model.notifyHookChanged()
        }
    }

    private func closeSheet() {
        model.activeSheet = nil
        if model.store.sessionState == .reading {
            model.currentScreen = .sessionActive
        } else if !model.navigationPath.isEmpty {
            model.currentScreen = .shelfList
        } else {
            model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
        }
        model.notifyHookChanged()
    }

    // MARK: - S-8 Menu

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                model.store.activeErrorKey = nil
                didHandleBarcodeThisPresentation = false
                pendingSupplementalCode = nil
                model.pendingBarcodes.removeAll()
                if model.store.cameraAuthorization == "denied" || model.store.cameraAuthorization == "restricted" {
                    step = .barcodeCameraDenied
                } else {
                    step = .barcodeScanner
                }
                model.currentScreen = .barcodeScan
                model.notifyHookChanged()
            } label: {
                Text("バーコードで登録")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("addBook.option.barcode")

            Button {
                model.store.activeErrorKey = nil
                searchQuery = ""
                searchResults = []
                hasExecutedSearch = false
                step = .searchList
                model.currentScreen = .bookSearchList
                model.notifyHookChanged()
            } label: {
                Text("書名・著者名で探す")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("addBook.option.search")

            if !titlePendingMode && !model.store.hasTitlePendingBook {
                Button {
                    model.store.activeErrorKey = nil
                    if model.store.startReadingWithPendingTitleBook() {
                        model.activeSheet = nil
                        model.currentScreen = .sessionActive
                    }
                    model.notifyHookChanged()
                } label: {
                    Text("いまは書名なしで読み始める")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("addBook.option.skipTitle")
            }

            if !titlePendingMode {
                Button {
                    model.store.activeErrorKey = nil
                    step = .bookshelfCamera
                    model.currentScreen = .bookshelfScan
                    model.notifyHookChanged()
                } label: {
                    Text("本棚をまとめて写す")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("addBook.option.bookshelf")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.addBook")
    }

    // MARK: - Barcode Scanner & Unhit

    private var barcodeScannerContent: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(minHeight: 160)
                .overlay {
                    Text("ISBNバーコード（978/979）を枠内に合わせてください")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .accessibilityIdentifier("barcode.scanner")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.barcode")
        .onAppear {
            processPendingBarcodesIfNeeded()
        }
    }

    private var barcodeCameraDeniedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カメラへのアクセスが許可されていません")
                .font(.headline)
                .accessibilityIdentifier("camera.denied.guide")

            Button {
                model.store.openExternalURL("app-settings:")
                model.notifyHookChanged()
            } label: {
                Text("設定を開く")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("camera.openSettings")

            Button {
                searchQuery = ""
                searchResults = []
                hasExecutedSearch = false
                step = .searchList
                model.currentScreen = .bookSearchList
                model.notifyHookChanged()
            } label: {
                Text("書名・著者名で探す")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("camera.fallback.search")

            Button {
                manualISBN = nil
                manualTitle = ""
                manualAuthor = ""
                manualPublisher = ""
                step = .manualInput(isbn13: nil, prefillTitle: "", prefillAuthor: "", prefillPublisher: nil)
                model.currentScreen = .bookManualInput
                model.notifyHookChanged()
            } label: {
                Text("手入力する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("camera.fallback.manual")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.barcode")
    }

    private func barcodeUnhitContent(isbn13: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カタログに書誌が見つかりませんでした（ISBN: \(isbn13)）")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                step = .coverCamera(isbn13: isbn13)
                model.currentScreen = .coverScan
                model.notifyHookChanged()
            } label: {
                Text("表紙を写して書名を取る")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("barcode.unhit.cover")

            Button {
                manualISBN = isbn13
                manualTitle = ""
                manualAuthor = ""
                let pubEntry = ISBNAndCCodeParser.lookupPublisherEntry(isbn13: isbn13)
                manualPublisher = pubEntry?.publisher ?? ""
                step = .manualInput(isbn13: isbn13, prefillTitle: "", prefillAuthor: "", prefillPublisher: pubEntry?.publisher)
                model.currentScreen = .bookManualInput
                model.notifyHookChanged()
            } label: {
                Text("手入力する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("barcode.unhit.manual")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.barcode.unhit")
    }

    private func processPendingBarcodesIfNeeded() {
        guard case .barcodeScanner = step, !didHandleBarcodeThisPresentation else {
            model.pendingBarcodes.removeAll()
            return
        }
        while !model.pendingBarcodes.isEmpty {
            let raw = model.pendingBarcodes.removeFirst()
            let cleaned = ISBNAndCCodeParser.cleanDigits(raw)
            if cleaned.hasPrefix("192") || cleaned.hasPrefix("191") {
                pendingSupplementalCode = cleaned
                continue
            }
            switch ISBNAndCCodeParser.validateISBN13(cleaned) {
            case .failure:
                continue
            case .success(let validISBN):
                didHandleBarcodeThisPresentation = true
                let supp = pendingSupplementalCode
                pendingSupplementalCode = nil
                model.pendingBarcodes.removeAll()
                handleAcceptedISBN13(validISBN, supplementalCode: supp)
                return
            }
        }
    }

    private func handleAcceptedISBN13(_ isbn13: String, supplementalCode: String?) {
        let outcome = model.store.catalogDB.lookupByISBN(isbn13, supplementalCode: supplementalCode, clock: model.store.clock)
        switch outcome {
        case .found(let hit):
            if titlePendingMode {
                if model.store.populateTitlePendingBook(
                    isbn13: hit.isbn13,
                    title: hit.title,
                    author: hit.author ?? "",
                    publisher: hit.publisher,
                    label: hit.label,
                    publishedYear: hit.publishedYear,
                    ndc: hit.ndc
                ) {
                    closeSheet()
                }
            } else {
                let res = model.store.addBook(
                    isbn13: hit.isbn13,
                    title: hit.title,
                    author: hit.author ?? "",
                    publisher: hit.publisher,
                    label: hit.label,
                    publishedYear: hit.publishedYear,
                    seriesTitle: hit.seriesTitle,
                    volumeNumber: hit.volumeNumber,
                    ndc: hit.ndc
                )
                if case .success = res {
                    closeSheet()
                }
            }
        case .notFound, .databaseNotReady, .invalidBarcode:
            step = .barcodeUnhit(isbn13: isbn13)
        }
        model.notifyHookChanged()
    }

    // MARK: - S-8a Cover OCR

    private func coverCameraContent(isbn13: String?) -> some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(minHeight: 160)
                .overlay {
                    Text("表紙の書名を枠内に合わせてください")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            Button {
                let covLines = model.store.ocrConfiguration?.coverLines ?? []
                if covLines.isEmpty {
                    step = .coverEmpty(isbn13: isbn13)
                } else {
                    step = .coverCandidates(isbn13: isbn13, candidates: covLines)
                }
                model.notifyHookChanged()
            } label: {
                Text("撮影する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("cover.shutter")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.cover")
    }

    private func coverCandidatesContent(isbn13: String?, candidates: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("書名候補をタップして選んでください")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(candidates.enumerated()), id: \.offset) { idx, cand in
                Button {
                    let pubEntry = isbn13.flatMap { ISBNAndCCodeParser.lookupPublisherEntry(isbn13: $0) }
                    manualISBN = isbn13
                    manualTitle = cand
                    manualAuthor = ""
                    manualPublisher = pubEntry?.publisher ?? ""
                    step = .manualInput(isbn13: isbn13, prefillTitle: cand, prefillAuthor: "", prefillPublisher: pubEntry?.publisher)
                    model.currentScreen = .bookManualInput
                    model.notifyHookChanged()
                } label: {
                    Text(cand)
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("cover.candidate.\(idx + 1)")
                .accessibilityLabel(cand)
                .accessibilityValue(cand)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.cover.candidates")
    }

    private func coverEmptyContent(isbn13: String?) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("表紙から文字を読み取れませんでした")
                .font(.headline)

            Button {
                let pubEntry = isbn13.flatMap { ISBNAndCCodeParser.lookupPublisherEntry(isbn13: $0) }
                manualISBN = isbn13
                manualTitle = ""
                manualAuthor = ""
                manualPublisher = pubEntry?.publisher ?? ""
                step = .manualInput(isbn13: isbn13, prefillTitle: "", prefillAuthor: "", prefillPublisher: pubEntry?.publisher)
                model.currentScreen = .bookManualInput
                model.notifyHookChanged()
            } label: {
                Text("手入力する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("cover.toManual")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.cover.empty")
    }

    // MARK: - Search List & S-8c Manual Input

    private var searchListContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if model.store.catalogDB.status != .ready {
                Text("内蔵カタログを利用できないため、手入力で登録してください。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("search.catalogUnavailable.guide")
            }

            HStack(spacing: 8) {
                TextField("書名または著者名", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.search)
                    .onSubmit {
                        runCatalogSearch()
                    }
                    .onChange(of: searchQuery) { _, newValue in
                        if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            runCatalogSearch()
                        }
                    }
                    .accessibilityIdentifier("search.query")

                Button("検索") {
                    runCatalogSearch()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("search.submit")
            }

            ForEach(Array(searchResults.enumerated()), id: \.offset) { idx, entry in
                Button {
                    selectCatalogEntry(entry)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        if let author = entry.author, !author.isEmpty {
                            Text(author)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("search.result.\(idx + 1)")
                .accessibilityLabel(entry.title)
                .accessibilityValue(entry.title)
            }

            Button {
                manualISBN = nil
                manualTitle = searchQuery
                manualAuthor = ""
                manualPublisher = ""
                step = .manualInput(isbn13: nil, prefillTitle: searchQuery, prefillAuthor: "", prefillPublisher: nil)
                model.currentScreen = .bookManualInput
                model.notifyHookChanged()
            } label: {
                Text("手入力で登録する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("search.toManual")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.search")
    }

    private func runCatalogSearch() {
        searchResults = model.store.catalogDB.searchByTitleOrAuthor(searchQuery, clock: model.store.clock)
        hasExecutedSearch = true
        model.notifyHookChanged()
    }

    private func selectCatalogEntry(_ entry: H20BiblioItem) {
        if titlePendingMode {
            if model.store.populateTitlePendingBook(
                isbn13: entry.isbn13,
                title: entry.title,
                author: entry.author ?? "",
                publisher: entry.publisher,
                label: entry.label,
                publishedYear: entry.publishedYear,
                ndc: entry.ndc
            ) {
                closeSheet()
            }
        } else {
            let res = model.store.addBook(
                isbn13: entry.isbn13,
                title: entry.title,
                author: entry.author ?? "",
                publisher: entry.publisher,
                label: entry.label,
                publishedYear: entry.publishedYear,
                seriesTitle: entry.seriesTitle,
                volumeNumber: entry.volumeNumber,
                ndc: entry.ndc
            )
            if case .success = res {
                closeSheet()
            }
        }
        model.notifyHookChanged()
    }

    private var manualInputContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("書名（必須・1〜100文字）")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("書名を入力", text: $manualTitle)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("manual.title")
                .accessibilityValue(manualTitle)

            Text("著者名（任意・100文字まで）")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("著者名を入力", text: $manualAuthor)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("manual.author")
                .accessibilityValue(manualAuthor)

            Text("出版社（任意）")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("出版社を入力", text: $manualPublisher)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("manual.publisher")
                .accessibilityValue(manualPublisher)

            Button {
                if titlePendingMode {
                    if model.store.populateTitlePendingBook(
                        isbn13: manualISBN,
                        title: manualTitle,
                        author: manualAuthor,
                        publisher: manualPublisher.isEmpty ? nil : manualPublisher,
                        label: nil,
                        publishedYear: nil
                    ) {
                        closeSheet()
                    }
                } else {
                    let res = model.store.addBook(
                        isbn13: manualISBN,
                        title: manualTitle,
                        author: manualAuthor,
                        publisher: manualPublisher.isEmpty ? nil : manualPublisher
                    )
                    if case .success = res {
                        closeSheet()
                    }
                }
                model.notifyHookChanged()
            } label: {
                Text("登録する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("manual.save")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.manual")
    }

    // MARK: - S-8d Bookshelf Multi-Spine Scan

    private var bookshelfCameraContent: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(minHeight: 160)
                .overlay {
                    Text("本棚の背表紙が並ぶように写してください")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            Button {
                let rawSpines = model.store.ocrConfiguration?.spineItems ?? []
                let catBooks = model.store.catalogDB.allBooks()
                let cands = OCRPipeline.processBookshelfSpines(spines: rawSpines, catalog: catBooks)
                step = .bookshelfCandidates(spines: cands, selectedIds: [])
                model.notifyHookChanged()
            } label: {
                Text("撮影する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("bookshelf.shutter")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.bookshelf")
    }

    private func bookshelfCandidatesContent(spines: [BookshelfSpineCandidate], selectedIds: Set<String>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("積読に入れる背表紙を選んでください")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(spines.enumerated()), id: \.element.id) { idx, spine in
                let isSelected = selectedIds.contains(spine.id)
                Button {
                    var updated = selectedIds
                    if isSelected {
                        updated.remove(spine.id)
                    } else {
                        updated.insert(spine.id)
                    }
                    step = .bookshelfCandidates(spines: spines, selectedIds: updated)
                    model.notifyHookChanged()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(spine.title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            if let author = spine.author, !author.isEmpty {
                                Text(author)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    }
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("bookshelf.row.\(idx + 1)")
                .accessibilityLabel(spine.title)
                .accessibilityValue(isSelected ? "selected" : "unselected")
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }

            Button {
                let chosen = spines.filter { selectedIds.contains($0.id) }
                let items = chosen.map { sp in
                    (
                        isbn13: sp.isbn13,
                        title: sp.title,
                        author: sp.author ?? "",
                        publisher: sp.publisher,
                        label: sp.label,
                        publishedYear: sp.publishedYear,
                        ndc: sp.ndc
                    )
                }
                if model.store.addMultipleBooksToTsundoku(items) {
                    closeSheet()
                }
                model.notifyHookChanged()
            } label: {
                Text("選んだ本を積読に置く")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedIds.isEmpty)
            .accessibilityIdentifier("bookshelf.addSelected")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.bookshelf.candidates")
    }
}

#Preview("S-8 Book Add Menu") {
    let model = ReadingAppModel()
    BookAddFlowSheetView(model: model, initialStep: .menu)
}

#Preview("S-8c Manual Input") {
    let model = ReadingAppModel()
    BookAddFlowSheetView(model: model, initialStep: .manualInput(isbn13: nil, prefillTitle: "", prefillAuthor: "", prefillPublisher: nil))
}

#Preview("S-8d Bookshelf Candidates AX5 Dark") {
    let model = ReadingAppModel()
    let spines = [
        BookshelfSpineCandidate(index: 1, id: "s1", title: "こころ", author: "夏目漱石", isbn13: "9784101010014"),
        BookshelfSpineCandidate(index: 2, id: "s2", title: "人間失格", author: "太宰治", isbn13: "9784101006055")
    ]
    BookAddFlowSheetView(model: model, initialStep: .bookshelfCandidates(spines: spines, selectedIds: ["s1"]))
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}
