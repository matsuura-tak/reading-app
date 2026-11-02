import SwiftUI
import UIKit
import PhotosUI
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
    @Environment(\.themePalette) private var palette

    @State private var step: BookAddStep = .menu
    @State private var scannedItems: [ScannedBookRowItem] = []
    @State private var pendingSupplementalCCode: String?
    @State private var showDiscardScanConfirm = false
    @State private var inlineScanTitle: String = ""

    @State private var searchResults: [H20BiblioItem] = []
    /// H33 の `catalog.lookup` の門で止めている間 true（Release とふつうの起動では常に false）。
    @State private var catalogLookupPending = false
    @State private var catalogLookupPlaceholderVisible = false
    @State private var selectedSearchEntry: H20BiblioItem?
    @State private var manualTitle: String = ""
    @State private var manualAuthor: String = ""
    @State private var manualPublisher: String = ""
    @State private var manualISBN: String?
    @State private var manualIsEbook: Bool = false
    @State private var manualProgressUnit: ProgressUnit = .page

    @State private var coverPickedTitle: String = ""
    @State private var coverPickedAuthor: String = ""
    @State private var coverPickTapCount: Int = 0
    @State private var selectedCoverPhotoItem: PhotosPickerItem?
    @State private var selectedBookshelfPhotoItem: PhotosPickerItem?

    public init(model: ReadingAppModel, titlePendingMode: Bool = false, initialStep: BookAddStep = .menu) {
        self.model = model
        self.titlePendingMode = titlePendingMode
        _step = State(initialValue: initialStep)
    }

    private var headerTitle: String {
        switch step {
        case .menu, .barcodeCameraDenied:
            return titlePendingMode
                ? AppL10n.pick("書名を入れる", "Add Title")
                : AppL10n.pick("本を加える", "Add Book")
        case .barcodeScanner:
            return AppL10n.pick("バーコード読み取り", "Scan Barcode")
        case .coverCandidates, .coverEmpty:
            return AppL10n.pick("表紙から選ぶ", "Pick from Cover")
        case .manualInput:
            return AppL10n.pick("書名・著者を入れる", "Enter Title & Author")
        case .bookshelfCandidates:
            return AppL10n.pick("積読に置く本を選ぶ", "Select Books for Shelf")
        }
    }

    private var headerCancelTitle: String {
        switch step {
        case .menu, .barcodeCameraDenied:
            return AppL10n.pick("閉じる", "Close")
        default:
            return AppL10n.pick("キャンセル", "Cancel")
        }
    }

    private var headerCancelId: String {
        switch step {
        case .menu, .barcodeCameraDenied:
            return "register.cancel"
        case .barcodeScanner:
            return "scan.cancel"
        case .coverCandidates, .coverEmpty:
            return "cover.cancel"
        case .manualInput:
            return "manual.cancel"
        case .bookshelfCandidates:
            return "bookshelf.cancel"
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            SheetHeaderBar(
                title: headerTitle,
                leftTitle: headerCancelTitle,
                leftId: headerCancelId,
                onLeft: {
                    handleHeaderCancel()
                }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s16) {
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
                .padding(.horizontal, ThemeSpace.s24)
                .padding(.vertical, ThemeSpace.s16)
            }

            bottomActionBar
        }
        .background(palette.bgPrimary.ignoresSafeArea())
        .onChange(of: model.barcodeEventCounter) { _, _ in
            processPendingBarcodesIfNeeded()
        }
        .onChange(of: selectedCoverPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task { @MainActor in
                if let image = await CameraAndOCRService.loadUIImage(from: newItem) {
                    let lines = CameraAndOCRService.evaluateCoverLines(from: image)
                    coverPickedTitle = ""
                    coverPickedAuthor = ""
                    coverPickTapCount = 0
                    if lines.isEmpty {
                        step = .coverEmpty(isbn13: nil)
                    } else {
                        step = .coverCandidates(isbn13: nil, candidates: lines)
                    }
                    model.currentScreen = .coverScan
                    model.notifyHookChanged()
                }
            }
        }
        .onChange(of: selectedBookshelfPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task { @MainActor in
                if let image = await CameraAndOCRService.loadUIImage(from: newItem) {
                    let catBooks = model.store.catalogDB.allBooks()
                    let cands = CameraAndOCRService.evaluateBookshelfSpines(from: image, catalog: catBooks)
                    step = .bookshelfCandidates(spines: cands, selectedIds: [])
                    model.currentScreen = .bookshelfScan
                    model.notifyHookChanged()
                }
            }
        }
        .onAppear {
            model.currentScreen = .bookAddActionSheet
            model.notifyHookChanged()
        }
    }

    @ViewBuilder
    private var bottomActionBar: some View {
        switch step {
        case .barcodeScanner:
            VStack(spacing: ThemeSpace.s8) {
                Button {
                    commitScannedBooksToShelf()
                } label: {
                    let count = scannedItems.count
                    let titleText = count > 0
                        ? AppL10n.pick("この\(count)冊を本棚に加える", "Add \(count) to Shelf")
                        : AppL10n.pick("本棚に加える", "Add to Shelf")
                    Text(titleText)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .disabled(scannedItems.isEmpty)
                .accessibilityIdentifier("scan.addToShelf")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.vertical, ThemeSpace.s12)
            .background(palette.bgPrimary)

        case .coverCandidates(let isbn13, _):
            VStack(spacing: ThemeSpace.s8) {
                Button {
                    let pubEntry = isbn13.flatMap { ISBNAndCCodeParser.lookupPublisherEntry(isbn13: $0) }
                    // design 5 の S-8b：書名が空・101字以上で保存を押したら book.title.invalid を出して保存しない。
                    guard case .success(let finalTitle) = InputValidator.validateTitle(coverPickedTitle) else {
                        model.store.activeErrorKey = "book.title.invalid"
                        model.notifyHookChanged()
                        return
                    }
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
                    Text(AppL10n.pick("この内容で登録", "Save with These Details"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("cover.save")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.vertical, ThemeSpace.s12)
            .background(palette.bgPrimary)

        case .manualInput:
            VStack(spacing: ThemeSpace.s8) {
                Button {
                    saveManualInput()
                } label: {
                    Text(AppL10n.pick("保存", "Save"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("manual.save")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.vertical, ThemeSpace.s12)
            .background(palette.bgPrimary)

        case .bookshelfCandidates(let spines, let selectedIds):
            VStack(spacing: ThemeSpace.s8) {
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
                    let count = selectedIds.count
                    let label = count > 0
                        ? AppL10n.pick("選んだ\(count)冊を積読に置く", "Add \(count) Selected to Tsundoku")
                        : AppL10n.pick("選んだ本を積読に置く", "Add Selected to Tsundoku")
                    Text(label)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .disabled(selectedIds.isEmpty)
                .accessibilityIdentifier("bookshelf.addSelected")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.vertical, ThemeSpace.s12)
            .background(palette.bgPrimary)

        default:
            EmptyView()
        }
    }

    private func handleHeaderCancel() {
        switch step {
        case .menu, .barcodeCameraDenied:
            closeSheet()
        case .barcodeScanner:
            if scannedItems.isEmpty {
                step = .menu
                model.currentScreen = .bookAddActionSheet
                model.notifyHookChanged()
            } else {
                showDiscardScanConfirm = true
                model.notifyHookChanged()
            }
        case .coverCandidates, .coverEmpty, .manualInput, .bookshelfCandidates:
            step = .menu
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
        VStack(alignment: .leading, spacing: ThemeSpace.s12) {
            Button {
                model.store.activeErrorKey = nil
                scannedItems = []
                pendingSupplementalCCode = nil
                inlineScanTitle = ""
                showDiscardScanConfirm = false
                model.pendingBarcodes.removeAll()
                let authStatus = CameraAndOCRService.currentCameraAuthorizationStatus(overrideStatus: model.store.cameraAuthorization)
                if authStatus == "denied" || authStatus == "restricted" {
                    step = .barcodeCameraDenied
                } else {
                    step = .barcodeScanner
                }
                model.currentScreen = .barcodeScan
                model.notifyHookChanged()
            } label: {
                Text(AppL10n.pick("裏表紙のバーコードを読む", "Scan Back-Cover Barcode"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("register.barcode")

            Button {
                model.store.activeErrorKey = nil
                openCoverOCRFlow(isbn13: nil)
            } label: {
                Text(AppL10n.pick("表紙を写して登録", "Capture Cover to Add"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("register.cover")

            if model.store.ocrConfiguration != nil {
                Button {
                    model.store.activeErrorKey = nil
                    openCoverOCRFlow(isbn13: nil)
                } label: {
                    Text(AppL10n.pick("スクリーンショットから登録", "Add from Screenshot"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("register.screenshot")
            } else {
                let screenshotLabel = PhotosPickerThemedLabel(
                    text: AppL10n.pick("スクリーンショットから登録", "Add from Screenshot"),
                    palette: palette
                )
                PhotosPicker(
                    selection: $selectedCoverPhotoItem,
                    matching: .screenshots
                ) {
                    screenshotLabel
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("register.screenshot")
            }

            if !titlePendingMode {
                if model.store.ocrConfiguration != nil {
                    Button {
                        model.store.activeErrorKey = nil
                        let rawSpines = model.store.ocrConfiguration?.spineItems ?? []
                        let catBooks = model.store.catalogDB.allBooks()
                        let cands = OCRPipeline.processBookshelfSpines(spines: rawSpines, catalog: catBooks)
                        step = .bookshelfCandidates(spines: cands, selectedIds: [])
                        model.currentScreen = .bookshelfScan
                        model.notifyHookChanged()
                    } label: {
                        Text(AppL10n.pick("本棚をまとめて写す", "Scan Bookshelf Spines"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                    .accessibilityIdentifier("register.bookshelf")
                } else {
                    let bookshelfLabel = PhotosPickerThemedLabel(
                        text: AppL10n.pick("本棚をまとめて写す", "Scan Bookshelf Spines"),
                        palette: palette
                    )
                    PhotosPicker(
                        selection: $selectedBookshelfPhotoItem,
                        matching: .images
                    ) {
                        bookshelfLabel
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("register.bookshelf")
                }
            }

            Button {
                model.store.activeErrorKey = nil
                manualISBN = nil
                manualTitle = ""
                manualAuthor = ""
                manualPublisher = ""
                manualIsEbook = false
                manualProgressUnit = .page
                selectedSearchEntry = nil
                searchResults = []
                step = .manualInput(isbn13: nil, prefillTitle: "", prefillAuthor: "", prefillPublisher: nil)
                model.currentScreen = .bookManualInput
                model.notifyHookChanged()
            } label: {
                Text(AppL10n.pick("書名・著者を入れる", "Enter Title & Author"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
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
                    Text(AppL10n.pick("書名はあとで、今すぐ読み始める", "Add Title Later & Start Reading"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("register.later")
            }

            let footerCopy = AppL10n.pick(
                "バーコードや書名から加えるときも、外部へ通信せず端末内の書誌データだけを引きます。",
                "Even when adding by barcode or title, lookups use only the on-device catalog with zero network calls."
            )
            Text(footerCopy)
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, ThemeSpace.s4)
                .accessibilityIdentifier("register.footer")
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

    // MARK: - S-8a Barcode Scanner & Multi-Scan Queue

    private var barcodeScannerContent: some View {
        let hasDBNotReady = scannedItems.contains { $0.isDBNotReady }
        let hasNotFound = scannedItems.contains { !$0.isCatalogHit && !$0.isDBNotReady }
        let needsInlineTitle = scannedItems.contains { !$0.isCatalogHit }
        let isLiveScanning: Bool = {
            #if UITEST_HOOKS
            return !UITestHookCoordinator.shared.isFakeBarcodeScannerEnabled
            #else
            return true
            #endif
        }()

        return VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            ZStack {
                BarcodeDataScannerRepresentable(isLiveScanningEnabled: isLiveScanning) { payload in
                    model.pendingBarcodes.append(payload)
                    model.barcodeEventCounter += 1
                }
                .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.card))

                Text(AppL10n.pick("上段のバーコード（978…）を枠に入れてください。", "Align the top ISBN barcode (978…) inside the frame."))
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(ThemeSpace.s16)
            }
            .frame(minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .fill(palette.groupedRow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.card)
                    .strokeBorder(palette.hairline, lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("scan.camera")
            .accessibilityLabel(AppL10n.pick("上段のバーコード（978…）を枠に入れてください。", "Align the top ISBN barcode (978…) inside the frame."))

            if hasDBNotReady {
                Text(AppL10n.pick(
                    "書誌データの準備ができていません。書名を1行入れるか、表紙を写して加えられます。",
                    "The catalog database is not ready yet. Enter a title below or capture the cover."
                ))
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("scan.dbNotReady")
            } else if hasNotFound {
                Text(AppL10n.pick(
                    "書誌データに見つかりませんでした。書名を入れるか、表紙を写して加えられます。",
                    "Not found in catalog. Enter the title below or capture the cover."
                ))
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("scan.notFound")
            }

            if catalogLookupPending {
                // H33 の catalog.lookup を止めている間：一覧の所に行の形の灰の帯。
                catalogLookupPlaceholder(rowCount: 1)
            } else if scannedItems.isEmpty {
                // S-8a の「まだ読んでいない」（design 5）：一覧の所に scan.hint。
                Text(AppL10n.pick(
                    "本の裏のバーコード（2段あるときは両方）を写してください。続けて読めます。",
                    "Point the camera at the barcode on the back of a book. You can scan one after another."
                ))
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("scan.hint")
            }

            ForEach(scannedItems) { item in
                let rowSummary = formatScannedRowLabel(item)
                VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                    Text(rowSummary)
                        .font(.body)
                        .foregroundStyle(palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(ThemeSpace.s12)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: ThemeRadius.control)
                        .fill(palette.groupedRow)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.control)
                        .strokeBorder(palette.hairline, lineWidth: 1)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("scan.row.\(item.isbn13)")
                .accessibilityLabel(rowSummary)
                .accessibilityValue(rowSummary)
            }

            if needsInlineTitle {
                let targetISBN = scannedItems.last?.isbn13
                VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                    Text(AppL10n.pick("書名を入力", "Enter Title"))
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)

                    TextField(AppL10n.pick("書名を入力", "Enter Title"), text: $inlineScanTitle)
                        .themeField(palette)
                        .accessibilityIdentifier("scan.row.editTitle")
                        .accessibilityLabel(AppL10n.pick("書名を入力", "Enter Title"))
                        .accessibilityValue(inlineScanTitle)
                        .onChange(of: inlineScanTitle) { _, newValue in
                            if let lastIdx = scannedItems.indices.last {
                                scannedItems[lastIdx].title = newValue
                            }
                        }

                    Button {
                        openCoverOCRFlow(isbn13: targetISBN)
                    } label: {
                        Text(AppL10n.pick("表紙を写す", "Capture Cover"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                    .accessibilityIdentifier("scan.row.captureCover")
                }
            }

            if showDiscardScanConfirm {
                VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                    Text(AppL10n.pick("読み取った本を破棄して閉じますか？", "Discard scanned books and close?"))
                        .font(.footnote)
                        .foregroundStyle(palette.textSecondary)

                    Button(role: .destructive) {
                        scannedItems.removeAll()
                        showDiscardScanConfirm = false
                        step = .menu
                        model.currentScreen = .bookAddActionSheet
                        model.notifyHookChanged()
                    } label: {
                        HStack(spacing: ThemeSpace.s8) {
                            Image(systemName: "trash")
                                .foregroundStyle(palette.destructive)
                            Text(AppL10n.pick("破棄して閉じる", "Discard and Close"))
                                .foregroundStyle(palette.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                    .accessibilityIdentifier("scan.discard.confirmButton")
                }
                .padding(ThemeSpace.s12)
                .background(
                    RoundedRectangle(cornerRadius: ThemeRadius.card)
                        .fill(palette.groupedRow)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.card)
                        .strokeBorder(palette.hairline, lineWidth: 1)
                )
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
            switch ISBNAndCCodeParser.validateISBN13(cleaned) {
            case .failure:
                continue
            case .success(let validISBN):
                handleSingleScannedISBN(validISBN)
            }
        }
        model.notifyHookChanged()
    }

    private func handleSupplementalCCode(_ ccode: String) {
        guard let lastIdx = scannedItems.indices.last else {
            pendingSupplementalCCode = ccode
            return
        }
        if let cInfo = ISBNAndCCodeParser.parseCCode(ccode), let fmtLabel = cInfo.formatLabel {
            if (scannedItems[lastIdx].label ?? "").isEmpty {
                scannedItems[lastIdx].label = fmtLabel
            }
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
        let supplemental = pendingSupplementalCCode
        pendingSupplementalCCode = nil
        runCatalogLookup(coalesce: false) {
            appendScannedRow(isbn13: isbn13, supplemental: supplemental)
            model.notifyHookChanged()
        }
    }

    /// H33 の `catalog.lookup`（contracts/test-hooks.md）。門が素通りのとき（Release とふつうの起動）は、すぐに `perform` を呼び、
    /// 何も待たない。止めるときは、0.3秒（ContinuousClock）を超えたら S-8a の行・S-8c の候補の灰の帯を出し、放されてから `perform` を呼ぶ。
    /// `coalesce` が true（S-8c の書名の候補）なら、止めている間の入力では新しく引かず、放したあとの `perform` が最新の入力で引く。
    private func runCatalogLookup(coalesce: Bool, perform: @escaping @MainActor () -> Void) {
        if coalesce && catalogLookupPending { return }
        let gate = model.store.loadGate
        guard gate.willHold(.catalogLookup) else {
            perform()
            return
        }
        catalogLookupPending = true
        Task { @MainActor in
            let clock = ContinuousClock()
            let deadline = clock.now.advanced(by: .milliseconds(300))
            let reveal = Task { @MainActor in
                try? await clock.sleep(until: deadline)
                if !Task.isCancelled {
                    catalogLookupPlaceholderVisible = true
                }
            }
            await gate.pass(.catalogLookup)
            reveal.cancel()
            catalogLookupPending = false
            catalogLookupPlaceholderVisible = false
            perform()
        }
    }

    private func appendScannedRow(isbn13: String, supplemental: String?) {
        let outcome = model.store.catalogDB.lookupByISBN(isbn13, supplementalCode: supplemental, clock: model.store.clock)
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
        VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            Text(AppL10n.pick(
                "カメラが許可されていません。設定で許可するか、スクリーンショットや手入力から登録できます。",
                "Camera access is not allowed. Enable it in Settings, or add from a screenshot or manual entry."
            ))
            .font(.body)
            .foregroundStyle(palette.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("camera.denied")

            Button {
                model.store.openExternalURL("app-settings:")
                model.notifyHookChanged()
            } label: {
                Text(AppL10n.pick("設定を開く", "Open Settings"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("camera.openSettings")

            Button {
                openCoverOCRFlow(isbn13: nil)
            } label: {
                Text(AppL10n.pick("スクリーンショットから登録", "Add from Screenshot"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("register.screenshot")

            Button {
                manualISBN = nil
                manualTitle = ""
                manualAuthor = ""
                manualPublisher = ""
                manualIsEbook = false
                manualProgressUnit = .page
                selectedSearchEntry = nil
                searchResults = []
                step = .manualInput(isbn13: nil, prefillTitle: "", prefillAuthor: "", prefillPublisher: nil)
                model.currentScreen = .bookManualInput
                model.notifyHookChanged()
            } label: {
                Text(AppL10n.pick("書名・著者を入れる", "Enter Title & Author"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("register.manual")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.barcode.denied")
    }

    // MARK: - S-8b Cover 2-Tap OCR

    private func coverCandidatesContent(isbn13: String?, candidates: [String]) -> some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s12) {
            Text(AppL10n.pick("書名と著者の順にタップしてください（著者がないときは書名だけで登録できます）。", "Tap the title first, then the author (or save with title only)."))
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(candidates.enumerated()), id: \.offset) { idx, cand in
                let isTitle = (coverPickedTitle == cand)
                let isAuthor = (!isTitle && coverPickedAuthor == cand)
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
                    HStack(spacing: ThemeSpace.s12) {
                        Text(cand)
                            .font(.body)
                            .foregroundStyle(palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        if isTitle {
                            Text(AppL10n.pick("書名", "Title"))
                                .font(.caption.bold())
                                .foregroundStyle(palette.ocrBadgeLabel)
                                .padding(.horizontal, ThemeSpace.s8)
                                .padding(.vertical, ThemeSpace.s4)
                                .background(
                                    RoundedRectangle(cornerRadius: ThemeRadius.ocrBox)
                                        .fill(palette.ocrBadgeBg)
                                )
                        } else if isAuthor {
                            Text(AppL10n.pick("著者", "Author"))
                                .font(.caption.bold())
                                .foregroundStyle(palette.ocrBadgeLabel)
                                .padding(.horizontal, ThemeSpace.s8)
                                .padding(.vertical, ThemeSpace.s4)
                                .background(
                                    RoundedRectangle(cornerRadius: ThemeRadius.ocrBox)
                                        .fill(palette.ocrBadgeBg)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(ThemeSpace.s12)
                    .background(
                        RoundedRectangle(cornerRadius: ThemeRadius.ocrBox)
                            .fill(palette.groupedRow)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ThemeRadius.ocrBox)
                            .strokeBorder(palette.ocrBoxOuter, lineWidth: 2)
                            .padding(1)
                            .overlay(
                                RoundedRectangle(cornerRadius: ThemeRadius.ocrBox)
                                    .strokeBorder(palette.ocrBoxInner, lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("cover.ocr.line.\(idx + 1)")
                .accessibilityLabel(cand)
                .accessibilityValue(cand)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.cover.candidates")
    }

    // S-8b の「読み取れた行が0個」（design 5）：ContentUnavailableView で mark.ocr.none、
    // 撮り直す（cover.retake）、手で入れる（register.manual → S-8c）。
    private func coverEmptyContent(isbn13: String?) -> some View {
        ContentUnavailableView {
            Label(
                AppL10n.pick("文字を読み取れませんでした", "No Text Found"),
                systemImage: "text.viewfinder"
            )
        } description: {
            Text(AppL10n.pick(
                "文字を読み取れませんでした。明るい所で撮り直すか、手で入れてください。",
                "No text was found. Retake the photo in better light, or enter it manually."
            ))
            .accessibilityIdentifier("mark.ocr.none")
        } actions: {
            Button {
                openCoverOCRFlow(isbn13: isbn13)
            } label: {
                Text(AppL10n.pick("撮り直す", "Retake"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("cover.retake")

            Button {
                let pubEntry = isbn13.flatMap { ISBNAndCCodeParser.lookupPublisherEntry(isbn13: $0) }
                manualISBN = isbn13
                manualTitle = ""
                manualAuthor = ""
                manualPublisher = pubEntry?.publisher ?? ""
                manualIsEbook = false
                manualProgressUnit = .page
                selectedSearchEntry = nil
                searchResults = []
                step = .manualInput(isbn13: isbn13, prefillTitle: "", prefillAuthor: "", prefillPublisher: pubEntry?.publisher)
                model.currentScreen = .bookManualInput
                model.notifyHookChanged()
            } label: {
                Text(AppL10n.pick("手で入れる", "Enter Manually"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("register.manual")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.cover.empty")
    }

    @ViewBuilder
    private func catalogLookupPlaceholder(rowCount: Int) -> some View {
        if catalogLookupPlaceholderVisible {
            RedactedRowListView(rowCount: rowCount)
                .onAppear { model.store.loadGate.markShown(.catalogLookup) }
        }
    }

    // MARK: - S-8c Manual Input + Inline Catalog Search

    private var manualInputContent: some View {
        let trimmedQuery = manualTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            if model.store.catalogDB.status != .ready {
                Text(AppL10n.pick("書誌データの準備ができていません。そのまま手入力で登録できます。", "Catalog data is not ready. You can save manually as entered."))
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("search.catalogUnavailable.guide")
            }

            VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                Text(AppL10n.pick("書名（必須）", "Title (Required)"))
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                TextField(AppL10n.pick("書名を入力", "Enter Title"), text: $manualTitle)
                    .themeField(palette)
                    .accessibilityIdentifier("manual.title")
                    .accessibilityLabel(AppL10n.pick("書名（必須）", "Title (Required)"))
                    .accessibilityValue(manualTitle)
                    .onChange(of: manualTitle) { _, newValue in
                        let q = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if q.count < 3 {
                            searchResults = []
                            selectedSearchEntry = nil
                        } else {
                            runCatalogLookup(coalesce: true) {
                                let latest = manualTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                searchResults = latest.count < 3
                                    ? []
                                    : model.store.catalogDB.searchByTitleOrAuthor(latest, clock: model.store.clock)
                                model.notifyHookChanged()
                            }
                        }
                        model.notifyHookChanged()
                    }
            }

            VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                Text(AppL10n.pick("著者（任意）", "Author (Optional)"))
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                TextField(AppL10n.pick("著者名を入力", "Enter Author"), text: $manualAuthor)
                    .themeField(palette)
                    .accessibilityIdentifier("manual.author")
                    .accessibilityLabel(AppL10n.pick("著者（任意）", "Author (Optional)"))
                    .accessibilityValue(manualAuthor)
            }

            if catalogLookupPending {
                // H33 の catalog.lookup を止めている間：0件の文を先に出さず、0.3秒を超えたら候補の行の形の灰の帯。
                catalogLookupPlaceholder(rowCount: 3)
            } else if trimmedQuery.count >= 3 && model.store.catalogDB.status == .ready {
                if searchResults.isEmpty {
                    Text(AppL10n.pick("書誌データに一致する本はありません。入力した内容でそのまま登録できます。", "No matching book in catalog. You can save the title as entered."))
                        .font(.footnote)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("search.noResults")
                } else {
                    VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                        Text(AppL10n.pick("端末内の書誌データから選ぶ（任意）", "Choose from On-Device Catalog (Optional)"))
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)

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
                                    VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                                        Text(entry.title)
                                            .font(.body)
                                            .foregroundStyle(palette.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        if !metaText.isEmpty {
                                            Text(metaText)
                                                .font(.subheadline)
                                                .foregroundStyle(palette.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    Spacer()
                                    if isChosen {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(palette.actionTint)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .padding(ThemeSpace.s12)
                                .background(
                                    RoundedRectangle(cornerRadius: ThemeRadius.control)
                                        .fill(palette.groupedRow)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: ThemeRadius.control)
                                        .strokeBorder(palette.hairline, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("search.row.\(rowISBN)")
                            .accessibilityLabel(rowLabel)
                            .accessibilityValue(rowLabel)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.manual")
    }

    private func saveManualInput() {
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
    }

    // MARK: - S-8d Bookshelf Multi-Spine Scan

    private func bookshelfCandidatesContent(spines: [BookshelfSpineCandidate], selectedIds: Set<String>) -> some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s12) {
            Text(AppL10n.pick("積読に置く背表紙を選んでください。", "Select the book spines to add to Tsundoku."))
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

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
                    HStack(spacing: ThemeSpace.s12) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? palette.actionTint : palette.textSecondary)

                        VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                            Text(spine.title)
                                .font(.body)
                                .foregroundStyle(palette.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            if let author = spine.author, !author.isEmpty {
                                Text(author)
                                    .font(.subheadline)
                                    .foregroundStyle(palette.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(ThemeSpace.s12)
                    .background(
                        RoundedRectangle(cornerRadius: ThemeRadius.control)
                            .fill(palette.groupedRow)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ThemeRadius.control)
                            .strokeBorder(palette.hairline, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("bookshelf.row.\(idx + 1)")
                .accessibilityLabel(spine.title)
                .accessibilityValue(isSelected ? "selected" : "unselected")
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
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

/// PhotosPicker のラベル（Sendable な閉包の外で作り、main actor の値を閉包の中で読まない）。
struct PhotosPickerThemedLabel: View {
    let text: String
    let palette: ThemePalette

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(palette.actionTint)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, ThemeSpace.s16)
            .padding(.vertical, ThemeSpace.s12)
            .background(
                RoundedRectangle(cornerRadius: ThemeRadius.control)
                    .fill(palette.groupedRow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.control)
                    .strokeBorder(palette.hairline, lineWidth: 1)
            )
    }
}
