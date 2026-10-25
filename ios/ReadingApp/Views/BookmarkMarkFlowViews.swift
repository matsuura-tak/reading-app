import SwiftUI
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
    @State private var pageText: String = ""

    public init(model: ReadingAppModel, initialStep: BookmarkMarkFlowStep = .select) {
        self.model = model
        _step = State(initialValue: initialStep)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    BannerNoticeView(model: model)

                    switch step {
                    case .select:
                        markSelectContent
                    case .lineInput:
                        markLineInputContent
                    case .pageOnlyInput:
                        markPageOnlyInputContent
                    case .ocrCamera:
                        markOCRCameraContent
                    case .ocrCameraDenied:
                        markOCRCameraDeniedContent
                    case .ocrProcessing:
                        markOCRProcessingContent
                    case .ocrEmpty:
                        markOCREmptyContent
                    case .ocrCandidates(let columns, let selectedIndices):
                        markOCRCandidatesContent(columns: columns, selectedIndices: selectedIndices)
                    }
                }
                .padding(20)
            }
            .navigationTitle("しおりを挟む")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: model.store.isOCRHoldReleased) { _, released in
            if released, case .ocrProcessing = step {
                completePageOCREvaluation()
            }
        }
    }

    // MARK: - S-3 Selection

    private var markSelectContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                model.store.activeErrorKey = nil
                if model.store.cameraAuthorization == "denied" || model.store.cameraAuthorization == "restricted" {
                    step = .ocrCameraDenied
                    model.currentScreen = .bookmarkMarkCamera
                } else {
                    step = .ocrCamera
                    model.currentScreen = .bookmarkMarkCamera
                }
                model.notifyHookChanged()
            } label: {
                Text("ページを写して一行を選ぶ")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("mark.option.photo")

            Button {
                model.store.activeErrorKey = nil
                lineText = ""
                pageText = ""
                step = .lineInput
                model.currentScreen = .bookmarkMarkLineInput
                model.notifyHookChanged()
            } label: {
                Text("一行を手で書く")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("mark.option.line")

            Button {
                model.store.activeErrorKey = nil
                lineText = ""
                pageText = ""
                step = .pageOnlyInput
                model.currentScreen = .bookmarkMarkPageInput
                model.notifyHookChanged()
            } label: {
                Text("ページ数だけ残す")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("mark.option.pageOnly")

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
                Text("あとで")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .accessibilityIdentifier("mark.option.later")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark")
        .onAppear {
            model.currentScreen = .bookmarkMarkSelect
            model.notifyHookChanged()
        }
    }

    // MARK: - S-3a Manual Line Input

    private var markLineInputContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("心に残った一行（60文字まで）")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("一行を入力", text: $lineText)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("mark.lineField")
                .accessibilityValue(lineText)

            progressFieldSection

            Button {
                handleSaveBookmark(mode: "line", rawLine: lineText, rawProgress: pageText)
            } label: {
                Text("挟む")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("mark.save")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark.line")
    }

    // MARK: - S-3b Page Only Input

    private var markPageOnlyInputContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            progressFieldSection

            Button {
                handleSaveBookmark(mode: "pageOnly", rawLine: nil, rawProgress: pageText)
            } label: {
                Text("挟む")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("mark.save")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark.pageOnly")
    }

    // MARK: - S-3c OCR Camera & Candidates

    private var markOCRCameraContent: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(minHeight: 180)
                .overlay {
                    Text("ページの文字を枠内に合わせてください")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            Button {
                triggerPageOCR()
            } label: {
                Text("撮影する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("mark.shutter")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark.camera")
    }

    private var markOCRCameraDeniedContent: some View {
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
                lineText = ""
                pageText = ""
                step = .lineInput
                model.currentScreen = .bookmarkMarkLineInput
                model.notifyHookChanged()
            } label: {
                Text("一行を手で書く")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("camera.fallback.manual")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark.camera")
    }

    private var markOCRProcessingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("文字を読み取っています…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mark.ocr.processing")
    }

    private var markOCREmptyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("文字を読み取れませんでした")
                .font(.headline)
                .accessibilityIdentifier("mark.ocr.emptyGuide")

            Button {
                step = .ocrCamera
                model.currentScreen = .bookmarkMarkCamera
                model.notifyHookChanged()
            } label: {
                Text("撮り直す")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("mark.ocr.retake")

            Button {
                lineText = ""
                pageText = ""
                step = .lineInput
                model.currentScreen = .bookmarkMarkLineInput
                model.notifyHookChanged()
            } label: {
                Text("手入力に切り替える")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("mark.ocr.toManual")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark.ocr")
    }

    private func markOCRCandidatesContent(columns: [OCRPageColumnItem], selectedIndices: [Int]) -> some View {
        let selectedColumnText = OCRPipeline.combineSelectedColumns(columns: columns, selectedIndices: selectedIndices)
        let effectiveLineValue = lineText.isEmpty ? selectedColumnText : lineText

        return VStack(alignment: .leading, spacing: 16) {
            Text("残す一行をタップして選んでください")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(columns) { col in
                    let isSelected = selectedIndices.contains(col.index)
                    Button {
                        lineText = ""
                        let newIndices: [Int]
                        if selectedIndices == [columns.last?.index ?? 1] && col.index != (columns.last?.index ?? 1) {
                            newIndices = [col.index]
                        } else if selectedIndices.contains(col.index) {
                            newIndices = selectedIndices.count > 1 ? selectedIndices.filter { $0 != col.index } : [col.index]
                        } else {
                            newIndices = selectedIndices + [col.index]
                        }
                        step = .ocrCandidates(columns: columns, selectedIndices: newIndices)
                        #if UITEST_HOOKS
                        UITestHookCoordinator.shared.selectedOCRColumnIndex = col.index
                        #endif
                        model.notifyHookChanged()
                    } label: {
                        HStack {
                            Text(col.text)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding(12)
                        .background(
                            isSelected ? Color.accentColor.opacity(0.15) : Color(uiColor: .secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("mark.ocr.column.\(col.index)")
                    .accessibilityLabel(col.text)
                    .accessibilityValue(col.text)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }

            TextField(selectedColumnText, text: $lineText)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("mark.lineField")
                .accessibilityLabel(effectiveLineValue)
                .accessibilityValue(effectiveLineValue)

            progressFieldSection

            Button {
                handleSaveBookmark(mode: "ocr", rawLine: effectiveLineValue, rawProgress: pageText)
            } label: {
                Text("挟む")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("mark.save")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sheet.mark.ocr")
    }

    private var progressFieldSection: some View {
        let unit = model.store.currentBook?.progressUnit ?? .page
        let labelText: String
        switch unit {
        case .page: labelText = "ページ数（1〜9999）"
        case .location: labelText = "位置（Loc 1〜999999）"
        case .percent: labelText = "進捗（0〜100%）"
        }

        return VStack(alignment: .leading, spacing: 6) {
            Text(labelText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField(labelText, text: $pageText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("mark.pageField")
                .accessibilityValue(pageText)
        }
    }

    private func triggerPageOCR() {
        if model.store.ocrHoldEnabled && !model.store.isOCRHoldReleased {
            step = .ocrProcessing
            model.currentScreen = .bookmarkMarkCamera
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
            lineText = ""
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
