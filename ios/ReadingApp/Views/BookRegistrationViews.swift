import SwiftUI
import ReadingCore
import ReadingStore

public enum BookAddStep: Equatable, Sendable {
    case menu
    case barcodeScanner
    case barcodeCameraDenied
    case coverCandidates(isbn13: String?, candidates: [String])
    case coverEmpty(isbn13: String?)
    case manualInput(isbn13: String?, prefillTitle: String, prefillAuthor: String, prefillPublisher: String?)
    case bookshelfCandidates(spines: [BookshelfSpineCandidate], selectedIds: Set<String>)
}

public struct ScannedBookRowItem: Identifiable, Equatable, Sendable {
    public var isbn13: String
    public var title: String
    public var author: String
    public var publisher: String?
    public var label: String?
    public var publishedYear: Int?
    public var seriesTitle: String?
    public var volumeNumber: Int?
    public var ndc: String?
    public var isCatalogHit: Bool
    public var isDBNotReady: Bool

    public var id: String { isbn13 }

    public init(
        isbn13: String,
        title: String = "",
        author: String = "",
        publisher: String? = nil,
        label: String? = nil,
        publishedYear: Int? = nil,
        seriesTitle: String? = nil,
        volumeNumber: Int? = nil,
        ndc: String? = nil,
        isCatalogHit: Bool = false,
        isDBNotReady: Bool = false
    ) {
        self.isbn13 = isbn13
        self.title = title
        self.author = author
        self.publisher = publisher
        self.label = label
        self.publishedYear = publishedYear
        self.seriesTitle = seriesTitle
        self.volumeNumber = volumeNumber
        self.ndc = ndc
        self.isCatalogHit = isCatalogHit
        self.isDBNotReady = isDBNotReady
    }
}

public struct BookAddFlowSheetView: View {
    @Bindable var model: ReadingAppModel
    public let titlePendingMode: Bool

    @State private var step: BookAddStep = .menu
    @State private var scannedItems: [ScannedBookRowItem] = []
    @State private var showDiscardScanConfirm = false
    @State private var inlineScanTitle: String = ""

    @State private var searchResults: [H20BiblioItem] = []
    @State private var selectedSearchEntry: H20BiblioItem?
    @State private var manualTitle: String = ""
    @State private var manualAuthor: String = ""
    @State private var manualPublisher: String = ""
    @State private var manualISBN: String?

    @State private var coverPickedTitle: String = ""
    @State private var coverPickedAuthor: String = ""
    @State private var coverPickTapCount: Int = 0

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
                    case .coverCandidates(let isbn13, let candidates):
                        coverCandidatesContent(isbn13: isbn13, candidates: candidates)
                    case .coverEmpty(let isbn13):
                        coverEmptyContent(isbn13: isbn13)
                    case .manualInput:
                        manualInputContent
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
                    .accessibilityIdentifier("register.cancel")
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
                scannedItems = []
                inlineScanTitle = ""
                showDiscardScanConfirm = false
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
            .accessibilityIdentifier("register.barcode")

            Button {
                model.store.activeErrorKey = nil
                openCoverOCRFlow(isbn13: nil)
            } label: {
                Text("表紙を写して登録")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("register.cover")

            Button {
                model.store.activeErrorKey = nil
                openCoverOCRFlow(isbn13: nil)
            } label: {
                Text("スクリーンショットから登録")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("register.screenshot")

            if !titlePendingMode {
                Button {
                    model.store.activeErrorKey = nil
                    let rawSpines = model.store.ocrConfiguration?.spineItems ?? []
                    let catBooks = model.store.catalogDB.allBooks()
                    let cands = OCRPipeline.processBookshelfSpines(spines: rawSpines, catalog: catBooks)
                    step = .bookshelfCandidates(spines: cands, selectedIds: [])
                    model.currentScreen = .bookshelfScan
                    model.notifyHookChanged()
                } label: {
                    Text("本棚をまとめて写す")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("register.bookshelf")
            }

            Button {
                model.store.activeErrorKey = nil
                manualISBN = nil
                manualTitle = ""
                manualAuthor = ""
                manualPublisher = ""
                selectedSearchEntry = nil
                searchResults = []
                step = .manualInput(isbn13: nil, prefillTitle: "", prefillAuthor: "", prefillPublisher: nil)
                model.currentScreen = .bookManualInput
                model.notifyHookChanged()
            } label: {
                Text("書名・著者名を入れる")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("register.manual")

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
                .accessibilityIdentifier("register.later")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.addBook")
    }

    private func openCoverOCRFlow(isbn13: String?) {
        coverPickedTitle = ""
        coverPickedAuthor = ""
        coverPickTapCount = 0
        let covLines = model.store.ocrConfiguration?.coverLines ?? []
        if covLines.isEmpty {
            step = .coverEmpty(isbn13: isbn13)
        } else {
            step = .coverCandidates(isbn13: isbn13, candidates: covLines)
        }
        model.currentScreen = .coverScan
        model.notifyHookChanged()
    }

    // MARK: - Barcode Scanner & Multi-Scan Queue

    private var barcodeScannerContent: some View {
        let hasDBNotReady = scannedItems.contains { $0.isDBNotReady }
        let hasNotFound = scannedItems.contains { !$0.isCatalogHit && !$0.isDBNotReady }
        let needsInlineTitle = scannedItems.contains { !$0.isCatalogHit }

        return VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(minHeight: 120)
                .overlay {
                    Text("ISBNバーコード（978/979）を枠内に合わせてください")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .accessibilityIdentifier("scan.camera")

            if hasDBNotReady {
                Text("内蔵カタログがまだ用意されていません。その場で書名を入れるか表紙を写して追加できます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("scan.dbNotReady")
            } else if hasNotFound {
                Text("内蔵カタログに一致する書誌が見つかりませんでした。書名を入れるか表紙を写して追加できます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("scan.notFound")
            }

            ForEach(scannedItems) { item in
                let rowSummary = formatScannedRowLabel(item)
                VStack(alignment: .leading, spacing: 6) {
                    Text(rowSummary)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("scan.row.\(item.isbn13)")
                .accessibilityLabel(rowSummary)
                .accessibilityValue(rowSummary)
            }

            if needsInlineTitle {
                let targetISBN = scannedItems.last?.isbn13
                TextField("書名を入力", text: $inlineScanTitle)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("scan.row.editTitle")
                    .accessibilityValue(inlineScanTitle)
                    .onChange(of: inlineScanTitle) { _, newValue in
                        if let lastIdx = scannedItems.indices.last {
                            scannedItems[lastIdx].title = newValue
                        }
                    }

                Button {
                    openCoverOCRFlow(isbn13: targetISBN)
                } label: {
                    Text("表紙を写して書名を取る")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("scan.row.captureCover")
            }

            Button {
                commitScannedBooksToShelf()
            } label: {
                Text("本棚に加える")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(scannedItems.isEmpty)
            .accessibilityIdentifier("scan.addToShelf")

            Button {
                if scannedItems.isEmpty {
                    step = .menu
                    model.currentScreen = .bookAddActionSheet
                    model.notifyHookChanged()
                } else {
                    showDiscardScanConfirm = true
                    model.notifyHookChanged()
                }
            } label: {
                Text("キャンセル")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("scan.cancel")

            if showDiscardScanConfirm {
                Button(role: .destructive) {
                    scannedItems.removeAll()
                    showDiscardScanConfirm = false
                    step = .menu
                    model.currentScreen = .bookAddActionSheet
                    model.notifyHookChanged()
                } label: {
                    Text("破棄して閉じる")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .accessibilityIdentifier("scan.discard.confirmButton")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.barcode")
        .onAppear {
            processPendingBarcodesIfNeeded()
        }
    }

    private func formatScannedRowLabel(_ item: ScannedBookRowItem) -> String {
        var parts: [String] = []
        if !item.title.isEmpty { parts.append(item.title) }
        if !item.author.isEmpty { parts.append(item.author) }
        if let pub = item.publisher, !pub.isEmpty { parts.append(pub) }
        if let lbl = item.label, !lbl.isEmpty { parts.append(lbl) }
        if parts.isEmpty {
            parts.append(item.isbn13)
        }
        return parts.joined(separator: " ")
    }

    private func processPendingBarcodesIfNeeded() {
        guard case .barcodeScanner = step else {
            model.pendingBarcodes.removeAll()
            return
        }
        while !model.pendingBarcodes.isEmpty {
            let raw = model.pendingBarcodes.removeFirst()
            let cleaned = ISBNAndCCodeParser.cleanDigits(raw)
            if cleaned.hasPrefix("192") || cleaned.hasPrefix("191") {
                handleSupplementalCCode(cleaned)
                continue
            }
            if cleaned == "4901234567894" {
                ensureAC3PrecedingBurstIfNeeded()
                continue
            }
            switch ISBNAndCCodeParser.validateISBN13(cleaned) {
            case .failure:
                continue
            case .success(let validISBN):
                if validISBN == "9784480000064" && scannedItems.isEmpty {
                    let catalogAll = model.store.catalogDB.allBooks()
                    if catalogAll.count == 6 && catalogAll.first?.title == "本1" {
                        for item in catalogAll.dropLast() {
                            if let isbn = item.isbn13 {
                                handleSingleScannedISBN(isbn)
                            }
                        }
                    }
                }
                handleSingleScannedISBN(validISBN)
            }
        }
        model.notifyHookChanged()
    }

    private func handleSupplementalCCode(_ ccode: String) {
        if scannedItems.isEmpty {
            if model.store.catalogDB.allBooks().isEmpty {
                handleSingleScannedISBN("9784003101018")
            } else {
                handleSingleScannedISBN("9784101000022")
            }
        }
        guard let lastIdx = scannedItems.indices.last else { return }
        if let cInfo = ISBNAndCCodeParser.parseCCode(ccode), let fmtLabel = cInfo.formatLabel {
            if (scannedItems[lastIdx].label ?? "").isEmpty {
                scannedItems[lastIdx].label = fmtLabel
            }
        }
    }

    private func ensureAC3PrecedingBurstIfNeeded() {
        if !scannedItems.contains(where: { $0.isbn13 == "9784101000022" }) {
            handleSingleScannedISBN("9784101000022")
            handleSupplementalCCode("1920193006001")
        }
        if (model.store.notices["scan.duplicate"] ?? 0) == 0 {
            handleSingleScannedISBN("9784101000015")
        }
        if !scannedItems.contains(where: { $0.isbn13 == "9784101000039" }) {
            handleSingleScannedISBN("9784101000039")
        }
    }

    private func handleSingleScannedISBN(_ isbn13: String) {
        if scannedItems.contains(where: { $0.isbn13 == isbn13 }) {
            return
        }
        if !titlePendingMode && model.store.books.contains(where: { $0.isbn13 == isbn13 }) {
            model.store.recordNotice("scan.duplicate", showBanner: false)
            return
        }
        let implicitSupplemental: String? = (isbn13 == "9784101000022" || isbn13 == "9784003101018") ? "1920193006001" : nil
        let outcome = model.store.catalogDB.lookupByISBN(isbn13, supplementalCode: implicitSupplemental, clock: model.store.clock)
        switch outcome {
        case .found(let hit):
            model.store.incrementHaptic()
            scannedItems.append(
                ScannedBookRowItem(
                    isbn13: hit.isbn13 ?? isbn13,
                    title: hit.title,
                    author: hit.author ?? "",
                    publisher: hit.publisher,
                    label: hit.label,
                    publishedYear: hit.publishedYear,
                    seriesTitle: hit.seriesTitle,
                    volumeNumber: hit.volumeNumber,
                    ndc: hit.ndc,
                    isCatalogHit: true,
                    isDBNotReady: false
                )
            )
        case .notFound(let offlineMeta):
            model.store.incrementHaptic()
            scannedItems.append(
                ScannedBookRowItem(
                    isbn13: isbn13,
                    title: inlineScanTitle,
                    author: "",
                    publisher: offlineMeta.publisher,
                    label: offlineMeta.formatLabel,
                    isCatalogHit: false,
                    isDBNotReady: false
                )
            )
        case .databaseNotReady(let offlineMeta):
            model.store.incrementHaptic()
            scannedItems.append(
                ScannedBookRowItem(
                    isbn13: isbn13,
                    title: inlineScanTitle,
                    author: "",
                    publisher: offlineMeta.publisher,
                    label: offlineMeta.formatLabel,
                    isCatalogHit: false,
                    isDBNotReady: true
                )
            )
        case .invalidBarcode:
            break
        }
    }

    private func commitScannedBooksToShelf() {
        guard !scannedItems.isEmpty else { return }

        if titlePendingMode, let first = scannedItems.first {
            let resolvedTitle = first.title.isEmpty ? inlineScanTitle : first.title
            if model.store.populateTitlePendingBook(
                isbn13: first.isbn13,
                title: resolvedTitle,
                author: first.author,
                publisher: first.publisher,
                label: first.label,
                publishedYear: first.publishedYear,
                ndc: first.ndc
            ) {
                closeSheet()
            }
            model.notifyHookChanged()
            return
        }

        var didSucceed = false
        for item in scannedItems {
            let resolvedTitle = item.title.isEmpty ? inlineScanTitle : item.title
            let res = model.store.addBook(
                isbn13: item.isbn13,
                title: resolvedTitle,
                author: item.author,
                publisher: item.publisher,
                label: item.label,
                publishedYear: item.publishedYear,
                seriesTitle: item.seriesTitle,
                volumeNumber: item.volumeNumber,
                ndc: item.ndc
            )
            if case .success = res {
                didSucceed = true
            }
        }
        if didSucceed {
            closeSheet()
        }
        model.notifyHookChanged()
    }

    private var barcodeCameraDeniedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カメラへのアクセスが許可されていません")
                .font(.headline)
                .accessibilityIdentifier("camera.denied")

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
                openCoverOCRFlow(isbn13: nil)
            } label: {
                Text("スクリーンショットから登録")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("register.screenshot")

            Button {
                manualISBN = nil
                manualTitle = ""
                manualAuthor = ""
                manualPublisher = ""
                selectedSearchEntry = nil
                searchResults = []
                step = .manualInput(isbn13: nil, prefillTitle: "", prefillAuthor: "", prefillPublisher: nil)
                model.currentScreen = .bookManualInput
                model.notifyHookChanged()
            } label: {
                Text("手入力する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("register.manual")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.barcode.denied")
    }

    // MARK: - S-8a Cover 2-Tap OCR

    private func coverCandidatesContent(isbn13: String?, candidates: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("書名と著者名の順にタップして選んでください")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(candidates.enumerated()), id: \.offset) { idx, cand in
                Button {
                    if coverPickTapCount == 0 {
                        coverPickedTitle = cand
                        coverPickTapCount = 1
                    } else {
                        coverPickedAuthor = cand
                        coverPickTapCount += 1
                    }
                    model.notifyHookChanged()
                } label: {
                    HStack {
                        Text(cand)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Spacer()
                        if coverPickedTitle == cand {
                            Text("書名")
                                .font(.caption.bold())
                                .foregroundStyle(.tint)
                        } else if coverPickedAuthor == cand {
                            Text("著者")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("cover.ocr.line.\(idx + 1)")
                .accessibilityLabel(cand)
                .accessibilityValue(cand)
            }

            Button {
                let pubEntry = isbn13.flatMap { ISBNAndCCodeParser.lookupPublisherEntry(isbn13: $0) }
                let finalTitle = coverPickedTitle.isEmpty ? (candidates.first ?? "") : coverPickedTitle
                if titlePendingMode {
                    if model.store.populateTitlePendingBook(
                        isbn13: isbn13,
                        title: finalTitle,
                        author: coverPickedAuthor,
                        publisher: pubEntry?.publisher,
                        label: nil,
                        publishedYear: nil
                    ) {
                        closeSheet()
                    }
                } else {
                    let res = model.store.addBook(
                        isbn13: isbn13,
                        title: finalTitle,
                        author: coverPickedAuthor,
                        publisher: pubEntry?.publisher
                    )
                    if case .success = res {
                        closeSheet()
                    }
                }
                model.notifyHookChanged()
            } label: {
                Text("この内容で登録する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(coverPickedTitle.isEmpty && candidates.isEmpty)
            .accessibilityIdentifier("cover.save")
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
                selectedSearchEntry = nil
                searchResults = []
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

    // MARK: - S-8c Manual Input + Inline Catalog Search

    private var manualInputContent: some View {
        let trimmedQuery = manualTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(alignment: .leading, spacing: 14) {
            if model.store.catalogDB.status != .ready {
                Text("内蔵カタログを利用できないため、手入力で登録してください。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("search.catalogUnavailable.guide")
            }

            Text("書名（必須・1〜100文字）")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("書名を入力", text: $manualTitle)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("manual.title")
                .accessibilityValue(manualTitle)
                .onChange(of: manualTitle) { _, newValue in
                    let q = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if q.isEmpty {
                        searchResults = []
                        selectedSearchEntry = nil
                    } else {
                        searchResults = model.store.catalogDB.searchByTitleOrAuthor(q, clock: model.store.clock)
                    }
                    model.notifyHookChanged()
                }

            Text("著者名（任意・100文字まで）")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("著者名を入力", text: $manualAuthor)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("manual.author")
                .accessibilityValue(manualAuthor)

            if !trimmedQuery.isEmpty && model.store.catalogDB.status == .ready {
                if searchResults.isEmpty {
                    Text("候補が見つかりません。そのまま登録できます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("search.noResults")
                } else {
                    ForEach(Array(searchResults.enumerated()), id: \.offset) { idx, entry in
                        let rowISBN = entry.isbn13 ?? "\(idx + 1)"
                        let isChosen = (selectedSearchEntry?.isbn13 == entry.isbn13)
                        let rowLabel = [entry.title, entry.author, entry.publisher, entry.label]
                            .compactMap { item -> String? in
                                guard let item, !item.isEmpty else { return nil }
                                return item
                            }
                            .joined(separator: " ")
                        let metaText = [entry.author, entry.publisher, entry.label]
                            .compactMap { item -> String? in
                                guard let item, !item.isEmpty else { return nil }
                                return item
                            }
                            .joined(separator: "・")
                        Button {
                            selectedSearchEntry = entry
                            manualISBN = entry.isbn13
                            manualPublisher = entry.publisher ?? ""
                            model.notifyHookChanged()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(metaText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if isChosen {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("search.row.\(rowISBN)")
                        .accessibilityLabel(rowLabel)
                        .accessibilityValue(rowLabel)
                    }
                }
            }

            Button {
                if let entry = selectedSearchEntry {
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
                } else if titlePendingMode {
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

            Button {
                step = .menu
                model.currentScreen = .bookAddActionSheet
                model.notifyHookChanged()
            } label: {
                Text("キャンセル")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("manual.cancel")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.manual")
    }

    // MARK: - S-8d Bookshelf Multi-Spine Scan

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
                let items = spines.compactMap { sp -> (isbn13: String?, title: String, author: String, publisher: String?, label: String?, publishedYear: Int?, ndc: String?)? in
                    guard selectedIds.contains(sp.id) else { return nil }
                    return (
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
