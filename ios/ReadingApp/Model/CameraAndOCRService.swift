import SwiftUI
import UIKit
import Vision
import VisionKit
import AVFoundation
import PhotosUI
import ReadingCore
import ReadingStore

// MARK: - Vision OCR & Camera Service

@MainActor
public enum CameraAndOCRService {
    public struct RecognizedFragment: Sendable, Equatable {
        public let text: String
        public let boundingBox: CGRect

        public init(text: String, boundingBox: CGRect) {
            self.text = text
            self.boundingBox = boundingBox
        }
    }

    public static func currentCameraAuthorizationStatus(overrideStatus: String) -> String {
        if overrideStatus == "denied" || overrideStatus == "restricted" {
            return overrideStatus
        }
        #if UITEST_HOOKS
        if !overrideStatus.isEmpty {
            return overrideStatus
        }
        #endif
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return "authorized"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "authorized"
        @unknown default:
            return "authorized"
        }
    }

    public nonisolated static func recognizeTextFragments(
        in cgImage: CGImage,
        mode: H23OCRStubMode
    ) -> [RecognizedFragment] {
        var fragments: [RecognizedFragment] = []
        let request = VNRecognizeTextRequest { req, _ in
            guard let observations = req.results as? [VNRecognizedTextObservation] else { return }
            for obs in observations {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let trimmed = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                fragments.append(RecognizedFragment(text: trimmed, boundingBox: obs.boundingBox))
            }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.usesLanguageCorrection = true
        if mode == .bookshelf {
            request.minimumTextHeight = 0.005
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try? handler.perform([request])
        return fragments
    }

    public static func evaluatePageOCR(
        from image: UIImage,
        mode: H23OCRStubMode = .pageVertical
    ) -> OCRPageResult {
        guard let cgImage = image.cgImage else {
            return OCRPageResult(
                mode: mode,
                columns: [],
                initialSelectedIndices: [],
                initialLineText: "",
                detectedPageNumber: nil
            )
        }
        let fragments = recognizeTextFragments(in: cgImage, mode: mode)
        let columns: [H23OCRColumn] = fragments.map { frag in
            let isLikelyPageNumber = Int(frag.text) != nil && frag.boundingBox.height < 0.08
            return H23OCRColumn(
                text: frag.text,
                normalizedX: Double(frag.boundingBox.midX),
                normalizedY: Double(frag.boundingBox.midY),
                isPageNumber: isLikelyPageNumber
            )
        }
        return OCRPipeline.processPageOCR(
            rawColumns: columns,
            explicitPageNumber: nil,
            mode: mode
        )
    }

    public static func evaluateCoverLines(from image: UIImage) -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        let fragments = recognizeTextFragments(in: cgImage, mode: .cover)
        return fragments.map(\.text)
    }

    public static func evaluateColophon(from image: UIImage) -> ColophonExtractionResult {
        guard let cgImage = image.cgImage else {
            return ColophonExtractionResult()
        }
        let fragments = recognizeTextFragments(in: cgImage, mode: .colophon)
        let colophon = H23OCRColophon(rawLines: fragments.map(\.text))
        return OCRPipeline.parseColophon(colophon)
    }

    public static func evaluateBookshelfSpines(
        from image: UIImage,
        catalog: [H20BiblioItem]
    ) -> [BookshelfSpineCandidate] {
        guard let cgImage = image.cgImage else { return [] }
        let fragments = recognizeTextFragments(in: cgImage, mode: .bookshelf)
        let sorted = fragments.sorted { $0.boundingBox.midX < $1.boundingBox.midX }
        let spineItems: [H23OCRSpineItem] = sorted.map { frag in
            H23OCRSpineItem(
                title: frag.text,
                author: nil,
                normalizedX: Double(frag.boundingBox.midX)
            )
        }
        return OCRPipeline.processBookshelfSpines(spines: spineItems, catalog: catalog)
    }

    public static func loadUIImage(from item: PhotosPickerItem) async -> UIImage? {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            return nil
        }
        return UIImage(data: data)
    }
}

// MARK: - VisionKit Barcode Scanner Representable

@MainActor
public struct BarcodeDataScannerRepresentable: UIViewControllerRepresentable {
    public let isLiveScanningEnabled: Bool
    public let onScannedCode: (String) -> Void

    public init(
        isLiveScanningEnabled: Bool,
        onScannedCode: @escaping (String) -> Void
    ) {
        self.isLiveScanningEnabled = isLiveScanningEnabled
        self.onScannedCode = onScannedCode
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onScannedCode: onScannedCode)
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        if isLiveScanningEnabled && DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
            let scanner = DataScannerViewController(
                recognizedDataTypes: [.barcode(symbologies: [.ean13])],
                qualityLevel: .balanced,
                recognizesMultipleItems: true,
                isHighFrameRateTrackingEnabled: false,
                isHighlightingEnabled: true
            )
            scanner.delegate = context.coordinator
            try? scanner.startScanning()
            return scanner
        }
        return BarcodePreviewFallbackViewController()
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.onScannedCode = onScannedCode
    }

    public static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        if let scanner = uiViewController as? DataScannerViewController {
            scanner.stopScanning()
        }
    }

    @MainActor
    public final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        public var onScannedCode: (String) -> Void

        public init(onScannedCode: @escaping (String) -> Void) {
            self.onScannedCode = onScannedCode
        }

        public func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for item in addedItems {
                if case .barcode(let barcode) = item,
                   let payload = barcode.payloadStringValue,
                   !payload.isEmpty {
                    onScannedCode(payload)
                }
            }
        }

        public func dataScanner(
            _ dataScanner: DataScannerViewController,
            didTapOn item: RecognizedItem
        ) {
            if case .barcode(let barcode) = item,
               let payload = barcode.payloadStringValue,
               !payload.isEmpty {
                onScannedCode(payload)
            }
        }
    }
}

@MainActor
private final class BarcodePreviewFallbackViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
    }
}

// MARK: - Finish Card View & ImageRenderer (1080 x 1350 px at 3x scale)

public struct FinishCardRenderOutput: Sendable {
    public let pngData: Data
    public let widthPx: Int
    public let heightPx: Int
    public let renderedTexts: [String]

    public init(pngData: Data, widthPx: Int, heightPx: Int, renderedTexts: [String]) {
        self.pngData = pngData
        self.widthPx = widthPx
        self.heightPx = heightPx
        self.renderedTexts = renderedTexts
    }
}

public struct FinishCardCanvasView: View {
    public let title: String
    public let author: String
    public let nightsCount: Int
    public let totalMinutes: Int

    public init(title: String, author: String, nightsCount: Int, totalMinutes: Int) {
        self.title = title
        self.author = author
        self.nightsCount = nightsCount
        self.totalMinutes = totalMinutes
    }

    public var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 16)

            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            if !author.isEmpty {
                Text(author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.vertical, 8)

            HStack(spacing: 20) {
                Text("\(nightsCount)晩")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
                Text("\(totalMinutes)分")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 16)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

@MainActor
public enum FinishCardRenderer {
    public static let cardWidthPt: CGFloat = 360
    public static let cardHeightPt: CGFloat = 450
    public static let renderScale: CGFloat = 3.0

    public static func renderCard(
        title: String,
        author: String,
        nightsCount: Int,
        totalMinutes: Int
    ) -> FinishCardRenderOutput {
        let content = FinishCardCanvasView(
            title: title,
            author: author,
            nightsCount: nightsCount,
            totalMinutes: totalMinutes
        )
        .frame(
            minWidth: cardWidthPt,
            maxWidth: cardWidthPt,
            minHeight: cardHeightPt,
            maxHeight: cardHeightPt
        )

        let renderer = ImageRenderer(content: content)
        renderer.scale = renderScale
        renderer.proposedSize = ProposedViewSize(width: cardWidthPt, height: cardHeightPt)

        var texts: [String] = [title]
        if !author.isEmpty {
            texts.append(author)
        }
        texts.append("\(nightsCount)晩")
        texts.append("\(totalMinutes)分")

        if let uiImage = renderer.uiImage,
           let pngData = uiImage.pngData() {
            let widthPx = Int((uiImage.size.width * uiImage.scale).rounded())
            let heightPx = Int((uiImage.size.height * uiImage.scale).rounded())
            return FinishCardRenderOutput(
                pngData: pngData,
                widthPx: widthPx,
                heightPx: heightPx,
                renderedTexts: texts
            )
        }

        return FinishCardRenderOutput(
            pngData: Data(),
            widthPx: Int(cardWidthPt * renderScale),
            heightPx: Int(cardHeightPt * renderScale),
            renderedTexts: texts
        )
    }
}
