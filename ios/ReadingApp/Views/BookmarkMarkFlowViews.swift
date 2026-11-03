import SwiftUI
import UIKit
import PhotosUI
import ReadingCore
import ReadingStore

public enum BookmarkMarkFlowStep: Equatable, Sendable {
    case select
    case lineInput
    case pageOnlyInput
    case ocrCamera
    case ocrCameraDenied
    case ocrProcessing
    case ocrEmpty
    case ocrCandidates(columns: [OCRPageColumnItem], selectedIndices: [Int])
}

public struct BookmarkMarkFlowSheet: View {
    @Bindable var model: ReadingAppModel
    @State private var step: BookmarkMarkFlowStep = .select
    @State private var lineText: String = ""
    /// S-3c：選んだ列の文を欄に入れたあと、最初に欄に触れたときは全体を選ぶ（打てば置き換わり、もう一度押せば字の間に入れて直せる）。
    @State private var lineSelection: TextSelection?
    @State private var selectsWholeLineOnFocus = false
    @FocusState private var isOCRLineFieldFocused: Bool
    @State private var pageText: String = ""
    @State private var selectedScreenshotItem: PhotosPickerItem?
    @Environment(\.themePalette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: ReadingAppModel, initialStep: BookmarkMarkFlowStep = .select) {
        self.model = model
        _step = State(initialValue: initialStep)
        if case .ocrCandidates(let columns, let selectedIndices) = initialStep {
            _lineText = State(initialValue: OCRPipeline.joinSelectedColumns(columns: columns, selectedIndices: selectedIndices))
            _selectsWholeLineOnFocus = State(initialValue: true)
        }
    }

    private var headerTitle: String {
        switch step {
        case .select, .ocrCameraDenied:
            return String(localized: "mark.navTitle")
        case .lineInput:
            return String(localized: "mark.manual")
        case .pageOnlyInput:
            return String(localized: "mark.pageOnly")
        case .ocrCamera, .ocrProcessing, .ocrEmpty, .ocrCandidates:
            return String(localized: "mark.navTitle")
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            SheetHeaderBar(
                title: headerTitle,
                cancelTitle: String(localized: "mark.cancel"),
                cancelIdentifier: "mark.cancel"
            ) {
                model.store.activeErrorKey = nil
                model.activeSheet = nil
                model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
                model.notifyHookChanged()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: ThemeSpace.s16) {
                    BannerNoticeView(model: model)

                    switch step {
                    case .select:
                        markSelectContent(showCameraDenied: false)
                    case .ocrCameraDenied:
                        markSelectContent(showCameraDenied: true)
                    case .lineInput:
                        markLineInputContent
                    case .pageOnlyInput:
                        markPageOnlyInputContent
                    case .ocrCamera:
                        markOCRCameraContent
                    case .ocrProcessing:
                        markOCRProcessingContent
                    case .ocrEmpty:
                        markOCREmptyContent
                    case .ocrCandidates(let columns, let selectedIndices):
                        markOCRCandidatesContent(columns: columns, selectedIndices: selectedIndices)
                    }
                }
                .padding(.horizontal, ThemeSpace.s24)
                .padding(.vertical, ThemeSpace.s16)
            }

            bottomSaveInset
        }
        .background(palette.bgPrimary.ignoresSafeArea())
        .onChange(of: model.store.isOCRHoldReleased) { _, released in
            if released, case .ocrProcessing = step {
                completePageOCREvaluation()
            }
        }
        .onChange(of: selectedScreenshotItem) { _, newItem in
            guard let newItem else { return }
            Task { @MainActor in
                if let image = await CameraAndOCRService.loadUIImage(from: newItem) {
                    applyVisionPageOCRResult(CameraAndOCRService.evaluatePageOCR(from: image))
                }
            }
        }
    }

    @ViewBuilder
    private var bottomSaveInset: some View {
        switch step {
        case .lineInput:
            VStack(spacing: 0) {
                Button {
                    handleSaveBookmark(mode: "line", rawLine: lineText, rawProgress: pageText)
                } label: {
                    Text(String(localized: "mark.save"))
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("mark.save")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.top, ThemeSpace.s12)
            .padding(.bottom, ThemeSpace.s16)
            .background(palette.bgPrimary)
        case .pageOnlyInput:
            VStack(spacing: 0) {
                Button {
                    handleSaveBookmark(mode: "pageOnly", rawLine: nil, rawProgress: pageText)
                } label: {
                    Text(String(localized: "mark.save"))
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("mark.save")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.top, ThemeSpace.s12)
            .padding(.bottom, ThemeSpace.s16)
            .background(palette.bgPrimary)
        case .ocrCandidates:
            VStack(spacing: 0) {
                Button {
                    // 欄の値（選んだ列の文、または手で直した文）をそのまま保存する。空なら mark.line.invalid（AC-67、AC-72）。
                    handleSaveBookmark(mode: "ocr", rawLine: lineText, rawProgress: pageText)
                } label: {
                    Text(String(localized: "mark.save"))
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .accessibilityIdentifier("mark.save")
            }
            .padding(.horizontal, ThemeSpace.s24)
            .padding(.top, ThemeSpace.s12)
            .padding(.bottom, ThemeSpace.s16)
            .background(palette.bgPrimary)
        case .select, .ocrCamera, .ocrCameraDenied, .ocrProcessing, .ocrEmpty:
            EmptyView()
        }
    }

    // MARK: - S-3 Selection

    private func markSelectContent(showCameraDenied: Bool) -> some View {
        let book = model.store.currentBook
        let displayTitle = (book?.isTitlePending == true) ? String(localized: "widget.currentBookAsTitle") : (book?.title ?? "")
        let hasPreviousMark = (book?.lastSavedLine != nil) || (book?.currentPage != nil) || (book?.currentLocation != nil) || (book?.currentPercent != nil)
        let laterNoteText = hasPreviousMark
            ? String(localized: "mark.later.note")
            : String(localized: "mark.later.note.empty")

        return VStack(alignment: .leading, spacing: ThemeSpace.s12) {
            VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                Text(String(localized: "mark.question"))
                    .font(.title3.bold())
                    .foregroundStyle(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("mark.question")

                if !displayTitle.isEmpty {
                    Text(displayTitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, ThemeSpace.s4)

            if showCameraDenied {
                VStack(alignment: .leading, spacing: ThemeSpace.s12) {
                    HStack(spacing: ThemeSpace.s8) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(palette.stateError)
                            .accessibilityHidden(true)
                        Text(String(localized: "camera.denied"))
                        .font(.subheadline)
                        .foregroundStyle(palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("camera.denied")
                    }

                    Button {
                        model.store.openExternalURL("app-settings:")
                        model.notifyHookChanged()
                    } label: {
                        Text(String(localized: "camera.openSettings"))
                    }
                    .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                    .accessibilityIdentifier("camera.openSettings")
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

            Button {
                model.store.activeErrorKey = nil
                if model.store.cameraAuthorization == "denied" || model.store.cameraAuthorization == "restricted" {
                    step = .ocrCameraDenied
                    model.currentScreen = .bookmarkMarkCamera
                } else {
                    triggerPageOCR()
                }
                model.notifyHookChanged()
            } label: {
                Text(String(localized: "mark.photo"))
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("mark.photo")

            if model.store.ocrConfiguration != nil {
                Button {
                    model.store.activeErrorKey = nil
                    triggerPageOCR()
                    model.notifyHookChanged()
                } label: {
                    Text(String(localized: "mark.screenshot"))
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("mark.screenshot")
            } else {
                PhotosPicker(
                    selection: $selectedScreenshotItem,
                    matching: .screenshots
                ) {
                    Text(String(localized: "mark.screenshot"))
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("mark.screenshot")
            }

            Button {
                model.store.activeErrorKey = nil
                lineText = ""
                pageText = ""
                step = .lineInput
                model.currentScreen = .bookmarkMarkLineInput
                model.notifyHookChanged()
            } label: {
                Text(String(localized: "mark.manual"))
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("mark.manual")

            Button {
                model.store.activeErrorKey = nil
                lineText = ""
                pageText = ""
                step = .pageOnlyInput
                model.currentScreen = .bookmarkMarkPageInput
                model.notifyHookChanged()
            } label: {
                Text(String(localized: "mark.pageOnly"))
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("mark.pageOnly")

            Button {
                model.store.activeErrorKey = nil
                let isAfterSession = (model.store.pendingMarkRecordId != nil)
                model.store.completeMarkLater()
                if isAfterSession {
                    model.currentScreen = .sessionResult
                    model.activeSheet = .resultSheet
                } else {
                    model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
                    model.activeSheet = nil
                }
                model.notifyHookChanged()
            } label: {
                Text(String(localized: "mark.later"))
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("mark.later")

            Text(laterNoteText)
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, ThemeSpace.s4)
                .accessibilityIdentifier(hasPreviousMark ? "mark.later.note" : "mark.later.note.empty")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(showCameraDenied ? "sheet.mark.camera" : "sheet.mark")
        .onAppear {
            if !showCameraDenied {
                model.currentScreen = .bookmarkMarkSelect
                model.notifyHookChanged()
            }
        }
    }

    // MARK: - S-3a Manual Line Input

    private var markLineInputContent: some View {
        let lineFieldLabel = String(localized: "mark.line.label")
        return VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            VStack(alignment: .leading, spacing: ThemeSpace.s8) {
                HStack {
                    Text(lineFieldLabel)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                    Spacer()
                    Text("\(lineText.count) / 60")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(palette.textSecondary)
                        .accessibilityIdentifier("mark.line.count")
                }

                // 大きい文字で欄の幅を超える一行とプレースホルダーを折り返す（1行の欄だと横に切れる。監査の Text clipped）。
                TextField(String(localized: "mark.line.placeholder"), text: $lineText, axis: .vertical)
                    .lineLimit(1...6)
                    .onChange(of: lineText) { _, value in
                        // 縦に伸びる欄でも改行は受けない（一行と場所は1行の値）。
                        if value.contains("\n") { lineText = value.replacingOccurrences(of: "\n", with: "") }
                    }
                    .themeField(palette)
                    .accessibilityIdentifier("mark.lineField")
                    .accessibilityLabel(lineFieldLabel)
                    .accessibilityValue(lineText)
            }

            progressFieldSection
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark.line")
    }

    // MARK: - S-3b Page Only Input

    private var markPageOnlyInputContent: some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            progressFieldSection
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark.pageOnly")
    }

    // MARK: - S-3c OCR Camera & Candidates

    private var markOCRCameraContent: some View {
        VStack(spacing: ThemeSpace.s24) {
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .fill(palette.groupedRow)
                .frame(minHeight: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                        .stroke(palette.hairline, lineWidth: 1)
                )
                .overlay {
                    Text(AppL10n.pick("ページの文字を枠内に合わせてください", "Align the page text within the frame"))
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(ThemeSpace.s16)
                }

            Button {
                triggerPageOCR()
            } label: {
                Text(AppL10n.pick("撮影する", "Capture"))
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("mark.shutter")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark.camera")
    }

    private var markOCRProcessingContent: some View {
        VStack(spacing: ThemeSpace.s16) {
            ProgressView()
                .controlSize(.large)
                .tint(palette.actionTint)
            Text(AppL10n.pick("文字を読み取っています…", "Recognizing text..."))
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)

            Button {
                model.store.clock.beginInterval(.markWait)
                lineText = ""
                pageText = ""
                step = .lineInput
                model.currentScreen = .bookmarkMarkLineInput
                _ = model.store.clock.endInterval(.markWait)
                model.notifyHookChanged()
            } label: {
                Text(String(localized: "mark.manual"))
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("mark.manual")

            Button {
                model.store.clock.beginInterval(.markWait)
                lineText = ""
                pageText = ""
                step = .pageOnlyInput
                model.currentScreen = .bookmarkMarkPageInput
                _ = model.store.clock.endInterval(.markWait)
                model.notifyHookChanged()
            } label: {
                Text(String(localized: "mark.pageOnly"))
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("mark.pageOnly")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ThemeSpace.s24)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mark.ocr.processing")
    }

    private var markOCREmptyContent: some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            HStack(spacing: ThemeSpace.s8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(palette.textSecondary)
                    .accessibilityHidden(true)
                Text(String(localized: "mark.ocr.none"))
                .font(.subheadline)
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("mark.ocr.none")
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

            Button {
                step = .ocrCamera
                model.currentScreen = .bookmarkMarkCamera
                model.notifyHookChanged()
            } label: {
                Text(String(localized: "mark.retake"))
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("mark.retake")

            Button {
                lineText = ""
                pageText = ""
                step = .lineInput
                model.currentScreen = .bookmarkMarkLineInput
                model.notifyHookChanged()
            } label: {
                Text(String(localized: "mark.manual"))
            }
            .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
            .accessibilityIdentifier("mark.manual")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark.ocr")
    }

    private func markOCRCandidatesContent(columns: [OCRPageColumnItem], selectedIndices: [Int]) -> some View {
        let lineFieldLabel = String(localized: "mark.line.label")

        return VStack(alignment: .leading, spacing: ThemeSpace.s12) {
            Text(String(localized: "mark.ocr.hint"))
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)

            if !dynamicTypeSize.isAccessibilitySize {
                ocrPagePreviewBox(columns: columns, selectedIndices: selectedIndices)
            }

            VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                ForEach(columns) { col in
                    let isSelected = selectedIndices.contains(col.index)
                    Button {
                        toggleOCRColumn(col: col, columns: columns, selectedIndices: selectedIndices)
                    } label: {
                        HStack(spacing: ThemeSpace.s12) {
                            Text("\(col.index)")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(palette.ocrBadgeLabel)
                                .padding(.horizontal, ThemeSpace.s8)
                                .padding(.vertical, 2)
                                .background(palette.ocrBadgeBg, in: RoundedRectangle(cornerRadius: ThemeRadius.ocrBox, style: .continuous))

                            Text(col.text)
                                .font(.body)
                                .foregroundStyle(palette.textPrimary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: ThemeSpace.s4)

                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.body)
                                .foregroundStyle(isSelected ? palette.actionTint : palette.textSecondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, ThemeSpace.s12)
                        .padding(.vertical, ThemeSpace.s8)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                                .fill(palette.groupedRow)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                                .stroke(isSelected ? palette.actionTint : palette.hairline, lineWidth: isSelected ? 2 : 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("mark.ocr.column.\(col.index)")
                    .accessibilityLabel(col.text)
                    .accessibilityValue(col.text)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }

            VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                Text(lineFieldLabel)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)

                // design/ 5 の S-3c：選んだ列の文字を欄の値に入れる（placeholder は mark.line.placeholder）。
                TextField(String(localized: "mark.line.placeholder"), text: $lineText, selection: $lineSelection, axis: .vertical)
                    .lineLimit(1...6)
                    .focused($isOCRLineFieldFocused)
                    .onChange(of: lineText) { _, value in
                        // 縦に伸びる欄でも改行は受けない（一行と場所は1行の値）。
                        if value.contains("\n") { lineText = value.replacingOccurrences(of: "\n", with: "") }
                    }
                    .onChange(of: isOCRLineFieldFocused) { _, focused in
                        guard focused, selectsWholeLineOnFocus else { return }
                        selectsWholeLineOnFocus = false
                        lineSelection = TextSelection(range: lineText.startIndex..<lineText.endIndex)
                    }
                    .themeField(palette)
                    .accessibilityIdentifier("mark.lineField")
                    .accessibilityLabel(lineFieldLabel)
            }

            progressFieldSection

            HStack(spacing: ThemeSpace.s12) {
                Button {
                    step = .ocrCamera
                    model.currentScreen = .bookmarkMarkCamera
                    model.notifyHookChanged()
                } label: {
                    Text(String(localized: "mark.retake"))
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("mark.retake")

                Button {
                    lineText = ""
                    pageText = ""
                    step = .lineInput
                    model.currentScreen = .bookmarkMarkLineInput
                    model.notifyHookChanged()
                } label: {
                    Text(String(localized: "mark.manual"))
                }
                .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
                .accessibilityIdentifier("mark.manual")
            }

            Button {
                model.store.activeErrorKey = nil
                let isAfterSession = (model.store.pendingMarkRecordId != nil)
                model.store.completeMarkLater()
                if isAfterSession {
                    model.currentScreen = .sessionResult
                    model.activeSheet = .resultSheet
                } else {
                    model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
                    model.activeSheet = nil
                }
                model.notifyHookChanged()
            } label: {
                Text(String(localized: "mark.later"))
            }
            .buttonStyle(ThemeSecondaryButtonStyle(palette: palette))
            .accessibilityIdentifier("mark.later")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark.ocr")
    }

    private func ocrPagePreviewBox(columns: [OCRPageColumnItem], selectedIndices: [Int]) -> some View {
        HStack(alignment: .top, spacing: ThemeSpace.s8) {
            ForEach(columns.reversed()) { col in
                let isSelected = selectedIndices.contains(col.index)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(col.index)")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(palette.ocrBadgeLabel)
                        .padding(.horizontal, ThemeSpace.s4)
                        .padding(.vertical, 1)
                        .background(palette.ocrBadgeBg, in: RoundedRectangle(cornerRadius: ThemeRadius.ocrBox, style: .continuous))

                    Text(String(col.text.prefix(8)))
                        .font(.caption2)
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(ThemeSpace.s4)
                .background(
                    RoundedRectangle(cornerRadius: ThemeRadius.ocrBox, style: .continuous)
                        .fill(palette.bgPrimary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.ocrBox, style: .continuous)
                        .stroke(palette.ocrBoxInner, lineWidth: isSelected ? 3 : 2)
                        .padding(2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.ocrBox, style: .continuous)
                        .stroke(palette.ocrBoxOuter, lineWidth: 2)
                )
            }
        }
        .padding(ThemeSpace.s8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .fill(palette.groupedRow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                .stroke(palette.hairline, lineWidth: 1)
        )
        .accessibilityHidden(true)
    }

    private func toggleOCRColumn(col: OCRPageColumnItem, columns: [OCRPageColumnItem], selectedIndices: [Int]) {
        let newIndices: [Int]
        if selectedIndices == [columns.last?.index ?? 1] && col.index != (columns.last?.index ?? 1) {
            newIndices = [col.index]
        } else if selectedIndices.contains(col.index) {
            newIndices = selectedIndices.count > 1 ? selectedIndices.compactMap { $0 != col.index ? $0 : nil } : [col.index]
        } else {
            newIndices = selectedIndices + [col.index]
        }
        step = .ocrCandidates(columns: columns, selectedIndices: newIndices)
        fillLineField(columns: columns, selectedIndices: newIndices)
        #if UITEST_HOOKS
        UITestHookCoordinator.shared.selectedOCRColumnIndex = col.index
        #endif
        model.notifyHookChanged()
    }

    private var progressFieldSection: some View {
        let book = model.store.currentBook
        let unit = book?.progressUnit ?? .page
        let labelText: String = {
            switch unit {
            case .page: return String(localized: "mark.page.label")
            case .location: return String(localized: "mark.progressUnit.location")
            case .percent: return String(localized: "mark.progressUnit.percent")
            }
        }()
        let previousValue: Int? = {
            switch unit {
            case .page: return book?.currentPage
            case .location: return book?.currentLocation
            case .percent: return book?.currentPercent
            }
        }()

        return VStack(alignment: .leading, spacing: ThemeSpace.s8) {
            if let book {
                Picker(String(localized: "mark.progressUnit.label"), selection: Binding(
                    get: { book.progressUnit },
                    set: { newUnit in
                        _ = model.store.updateBook(
                            bookId: book.id,
                            title: book.title,
                            author: book.author,
                            isEbook: newUnit != .page ? true : book.isEbook,
                            progressUnit: newUnit
                        )
                        model.notifyHookChanged()
                    }
                )) {
                    Text(String(localized: "mark.progressUnit.page")).tag(ProgressUnit.page)
                    Text(String(localized: "mark.progressUnit.location")).tag(ProgressUnit.location)
                    Text("%").tag(ProgressUnit.percent)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("mark.progressUnit")
            }

            Text(labelText)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)

            TextField(labelText, text: $pageText, axis: .vertical)
                .lineLimit(1...3)
                .onChange(of: pageText) { _, value in
                    // 縦に伸びる欄でも改行は受けない（一行と場所は1行の値）。
                    if value.contains("\n") { pageText = value.replacingOccurrences(of: "\n", with: "") }
                }
                .keyboardType(.numbersAndPunctuation)
                .themeField(palette)
                .accessibilityIdentifier("mark.pageField")
                .accessibilityLabel(labelText)
                .accessibilityValue(pageText)

            if let prev = previousValue {
                // design/ 7 の `mark.page.footer.keep`。%1$@ は場所の見える形（`page.short`、`location.short`、`percent.short`）。
                let prevPlace: String = {
                    switch unit {
                    case .page:
                        return String(format: String(localized: "page.short"), prev)
                    case .location:
                        return String(format: String(localized: "location.short"), prev)
                    case .percent:
                        return String(format: String(localized: "percent.short"), prev)
                    }
                }()
                let prevText = String(format: String(localized: "mark.page.footer.keep"), prevPlace)
                Text(prevText)
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("mark.page.previous")
            }
        }
    }

    private func triggerPageOCR() {
        model.store.clock.beginInterval(.markWait)
        if model.store.ocrHoldEnabled && !model.store.isOCRHoldReleased {
            step = .ocrProcessing
            model.currentScreen = .bookmarkMarkCamera
            _ = model.store.clock.endInterval(.markWait)
            model.notifyHookChanged()
            return
        }
        completePageOCREvaluation()
    }

    private func completePageOCREvaluation() {
        model.store.clock.beginInterval(.markWait)
        let cfg = model.store.ocrConfiguration
        let rawCols = cfg?.columns ?? []
        let mode = cfg?.mode ?? .pageVertical
        let result = OCRPipeline.processPageOCR(
            rawColumns: rawCols,
            explicitPageNumber: cfg?.detectedPageNumber,
            mode: mode
        )
        _ = model.store.clock.endInterval(.markWait)

        if mode == .empty || result.columns.isEmpty {
            step = .ocrEmpty
            model.currentScreen = .bookmarkMarkCamera
        } else {
            applyVisionPageOCRResult(result)
            return
        }
        model.notifyHookChanged()
    }

    /// 選んだ列の文を mark.lineField の値にする（AC-65、AC-66）。次に欄に触れたときは全体を選ぶ。
    private func fillLineField(columns: [OCRPageColumnItem], selectedIndices: [Int]) {
        lineText = OCRPipeline.joinSelectedColumns(columns: columns, selectedIndices: selectedIndices)
        lineSelection = nil
        selectsWholeLineOnFocus = true
        isOCRLineFieldFocused = false
    }

    private func applyVisionPageOCRResult(_ result: OCRPageResult) {
        if result.columns.isEmpty {
            step = .ocrEmpty
            model.currentScreen = .bookmarkMarkCamera
        } else {
            fillLineField(columns: result.columns, selectedIndices: result.initialSelectedIndices)
            if let detPage = result.detectedPageNumber {
                pageText = "\(detPage)"
            } else {
                pageText = ""
            }
            #if UITEST_HOOKS
            UITestHookCoordinator.shared.selectedOCRColumnIndex = result.initialSelectedIndices.first
            #endif
            step = .ocrCandidates(columns: result.columns, selectedIndices: result.initialSelectedIndices)
            model.currentScreen = .bookmarkMarkCamera
        }
        model.notifyHookChanged()
    }

    private func handleSaveBookmark(mode: String, rawLine: String?, rawProgress: String?) {
        let isAfterSession = (model.store.pendingMarkRecordId != nil)
        let result = model.store.saveBookmark(mode: mode, rawLine: rawLine, rawProgress: rawProgress)
        switch result {
        case .saved(_, let showedGuide):
            if isAfterSession {
                model.currentScreen = .sessionResult
                model.activeSheet = .resultSheet
            } else if showedGuide {
                model.currentScreen = .widgetGuide
                model.activeSheet = .widgetGuide
            } else {
                model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
                model.activeSheet = nil
            }
        case .invalidLine, .invalidPage, .failedSave:
            break
        }
        model.notifyHookChanged()
    }
}

#Preview("S-3 Mark Select") {
    let model = ReadingAppModel()
    BookmarkMarkFlowSheet(model: model, initialStep: .select)
}

#Preview("S-3a Line Input") {
    let model = ReadingAppModel()
    BookmarkMarkFlowSheet(model: model, initialStep: .lineInput)
}

#Preview("S-3b Page Only Input") {
    let model = ReadingAppModel()
    BookmarkMarkFlowSheet(model: model, initialStep: .pageOnlyInput)
}

#Preview("S-3c OCR Candidates AX5 Dark") {
    let model = ReadingAppModel()
    let cols = [
        OCRPageColumnItem(index: 1, text: "ある日の暮方の事である。", normalizedX: 0.82),
        OCRPageColumnItem(index: 2, text: "一人の下人が、羅生門の下で雨やみを待っていた。", normalizedX: 0.50)
    ]
    BookmarkMarkFlowSheet(model: model, initialStep: .ocrCandidates(columns: cols, selectedIndices: [2]))
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}
