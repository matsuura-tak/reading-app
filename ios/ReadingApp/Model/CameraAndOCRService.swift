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

    /// UIImage の向き（カメラの写真は EXIF の向き、写真やスクリーンショットは保存された向き）を Vision に渡す形にする。
    public nonisolated static func visionOrientation(of image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    public nonisolated static func recognizeTextFragments(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation = .up,
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
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try? handler.perform([request])
        return fragments
    }

    /// Vision の文字認識を主スレッドの外で動かす（0.5〜1.5秒かかるため。主スレッドをふさがない）。
    /// 画像は引数の UIImage（記憶の中）だけを読み、ファイルにも写真ライブラリにも書かない（AC-69、H27）。
    @concurrent
    public nonisolated static func recognizeTextFragmentsOffMain(
        in image: UIImage,
        mode: H23OCRStubMode
    ) async -> [RecognizedFragment] {
        guard let cgImage = image.cgImage else { return [] }
        return recognizeTextFragments(in: cgImage, orientation: visionOrientation(of: image), mode: mode)
    }

    public static func evaluatePageOCR(
        from image: UIImage,
        mode: H23OCRStubMode = .pageVertical
    ) async -> OCRPageResult {
        let fragments = await recognizeTextFragmentsOffMain(in: image, mode: mode)
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

    public static func evaluateCoverLines(from image: UIImage) async -> [String] {
        let fragments = await recognizeTextFragmentsOffMain(in: image, mode: .cover)
        return fragments.map(\.text)
    }

    public static func evaluateColophon(from image: UIImage) async -> ColophonExtractionResult {
        let fragments = await recognizeTextFragmentsOffMain(in: image, mode: .colophon)
        let colophon = H23OCRColophon(rawLines: fragments.map(\.text))
        return OCRPipeline.parseColophon(colophon)
    }

    public static func evaluateBookshelfSpines(
        from image: UIImage,
        catalog: [H20BiblioItem]
    ) async -> [BookshelfSpineCandidate] {
        let fragments = await recognizeTextFragmentsOffMain(in: image, mode: .bookshelf)
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

// MARK: - 写す面（S-3c のページ、S-8 の表紙・背表紙・本棚、S-7c の奥付で使う。AVFoundation だけで作る）

/// 写す面のカメラの状態（design/ 5 の S-3c・S-7c・S-8）。
public enum PhotoCaptureAccess: Equatable, Sendable {
    /// 許可とカメラの有無を確かめている間（許可が未決定なら、このとき OS の許可ダイアログを出す）。
    case checking
    /// プレビューが動いていて「写す」を押せる。
    case ready
    /// カメラを持たない端末（シミュレーターを含む）や、カメラを開けなかったとき。写真から選ぶ道に案内する。
    case unavailable
    /// 許可が拒否・制限。呼び出し元が `camera.denied` と `camera.openSettings` を出す（決定 92）。
    case denied
}

/// AVCaptureSession を、主スレッドのプレビュー層（AVCaptureVideoPreviewLayer.session）に渡すためだけの入れ物。
/// AVCaptureSession は Sendable ではないが、構成・開始・停止・撮影は PhotoCaptureEngine（専用の直列のキューを実行者にした actor）の中だけで行い、
/// 主スレッドは AVCaptureVideoPreviewLayer.session に代入するだけにする（Apple の AVCam と同じ分け方）。
/// actor の外へ AVCaptureSession を渡す型の道が Swift 6 にはないため、この1か所だけ @unchecked Sendable にした（ios/docs の実装ノート 15）。
public final class CaptureSessionHandle: @unchecked Sendable {
    fileprivate let session: AVCaptureSession

    fileprivate init(session: AVCaptureSession) {
        self.session = session
    }
}

/// 1枚の写真の結果を受け取る。画像はファイルに書かず、記憶の中の Data のまま返す（AC-69、H27）。
private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let continuation: CheckedContinuation<Data?, Never>

    init(continuation: CheckedContinuation<Data?, Never>) {
        self.continuation = continuation
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        continuation.resume(returning: error == nil ? photo.fileDataRepresentation() : nil)
    }
}

/// 背面カメラで1枚写す。AVCaptureSession の構成・開始・停止は主スレッドの外の専用の直列のキューで行う
/// （startRunning は終わるまで呼んだスレッドを止めるため）。
public actor PhotoCaptureEngine {
    private let sessionQueue = DispatchSerialQueue(label: "app.yomuma.camera.session", qos: .userInitiated)
    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }

    private let session: AVCaptureSession
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var inFlightDelegate: PhotoCaptureDelegate?
    public nonisolated let previewHandle: CaptureSessionHandle

    public init() {
        let session = AVCaptureSession()
        self.session = session
        self.previewHandle = CaptureSessionHandle(session: session)
    }

    /// 背面の広角カメラがあるか（シミュレーターと一部の端末では false）。
    public nonisolated static var hasBackCamera: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    /// 構成して動かす。動けば true。
    public func start() -> Bool {
        if !isConfigured {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return false
            }
            session.beginConfiguration()
            session.sessionPreset = .photo
            guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
                session.commitConfiguration()
                return false
            }
            session.addInput(input)
            session.addOutput(photoOutput)
            session.commitConfiguration()
            isConfigured = true
        }
        if !session.isRunning {
            session.startRunning()
        }
        return session.isRunning
    }

    public func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    /// 1枚写して、写真のデータ（記憶の中だけ）を返す。写せなければ nil。
    public func capturePhoto() async -> Data? {
        guard session.isRunning, inFlightDelegate == nil else { return nil }
        // アプリは縦向き固定。写真に縦向き（90度）を付け、Vision には UIImage の向きとして渡す。
        if let connection = photoOutput.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        let settings = AVCapturePhotoSettings()
        let data: Data? = await withCheckedContinuation { continuation in
            let delegate = PhotoCaptureDelegate(continuation: continuation)
            inFlightDelegate = delegate
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
        inFlightDelegate = nil
        return data
    }
}

/// カメラのプレビュー。AVCaptureVideoPreviewLayer を UIView に載せる。
public struct CameraPreviewRepresentable: UIViewRepresentable {
    public let handle: CaptureSessionHandle

    public init(handle: CaptureSessionHandle) {
        self.handle = handle
    }

    public func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = handle.session
        return view
    }

    public func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}

    public static func dismantleUIView(_ uiView: CameraPreviewUIView, coordinator: ()) {
        uiView.previewLayer.session = nil
    }
}

public final class CameraPreviewUIView: UIView {
    public let previewLayer = AVCaptureVideoPreviewLayer()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

/// 写す面（design/ 5 の S-3c「撮る前」、S-7c の上部、S-8 の「カメラで1枚写す」）。
/// プレビューと枠、案内の文、「写す」、写真から選ぶ道（`alternative`）を縦に並べる。
/// 撮った画像は記憶の中の UIImage のまま `onCaptured` に渡し、ここでは何も保存しない（AC-69、H27）。
public struct PhotoCaptureSurface<Alternative: View>: View {
    private let hint: String?
    private let hintIdentifier: String?
    private let shutterTitle: String
    private let shutterIdentifier: String
    private let previewLabel: String
    private let onCaptured: (UIImage?) -> Void
    private let onDenied: () -> Void
    private let alternative: Alternative
    #if UITEST_HOOKS
    /// H23（読み取りの差し替え）があるとき、「写す」はカメラの代わりにこれを呼ぶ。UITEST_HOOKS の外には無い。
    fileprivate var uiTestShutter: (() -> Void)?
    #endif

    @State private var access: PhotoCaptureAccess = .checking
    @State private var engine: PhotoCaptureEngine?
    @State private var isCapturing = false
    @Environment(\.themePalette) private var palette

    public init(
        hint: String?,
        hintIdentifier: String?,
        shutterTitle: String,
        shutterIdentifier: String,
        previewLabel: String,
        onCaptured: @escaping (UIImage?) -> Void,
        onDenied: @escaping () -> Void,
        @ViewBuilder alternative: () -> Alternative
    ) {
        self.hint = hint
        self.hintIdentifier = hintIdentifier
        self.shutterTitle = shutterTitle
        self.shutterIdentifier = shutterIdentifier
        self.previewLabel = previewLabel
        self.onCaptured = onCaptured
        self.onDenied = onDenied
        self.alternative = alternative()
    }

    #if UITEST_HOOKS
    /// H23 の差し替えを使う（テストのつなぎ口。Release には無い）。
    public func uiTestShutter(_ action: (() -> Void)?) -> Self {
        var copy = self
        copy.uiTestShutter = action
        return copy
    }
    #endif

    private var usesTestShutter: Bool {
        #if UITEST_HOOKS
        return uiTestShutter != nil
        #else
        return false
        #endif
    }

    public var body: some View {
        VStack(spacing: ThemeSpace.s16) {
            ZStack {
                RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                    .fill(palette.groupedRow)
                if access == .ready, let engine {
                    CameraPreviewRepresentable(handle: engine.previewHandle)
                        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous))
                } else if access == .checking && !usesTestShutter {
                    ProgressView()
                        .tint(palette.actionTint)
                }
                // 枠（S-3c の読み取りの枠と同じ白黒の2重線）。この中に文字を入れて写す。
                RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                    .strokeBorder(Color.black, lineWidth: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: ThemeRadius.control, style: .continuous)
                            .strokeBorder(Color.white, lineWidth: 2)
                    )
                    .padding(ThemeSpace.s24)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.card, style: .continuous)
                    .stroke(palette.hairline, lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(previewLabel)

            if let hint {
                Text(hint)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(hintIdentifier ?? "")
            }

            if access == .unavailable && !usesTestShutter {
                // カメラがない所（シミュレーターなど）：写真から選ぶ道と手入力に案内する（design/ 7 の `register.scanUnavailable`）。
                Text(String(localized: "register.scanUnavailable"))
                    .font(.subheadline)
                    .foregroundStyle(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("register.scanUnavailable")
            }

            if access == .ready || usesTestShutter {
                Button {
                    shutterTapped()
                } label: {
                    Text(shutterTitle)
                }
                .buttonStyle(ThemePrimaryButtonStyle(palette: palette))
                .disabled(isCapturing)
                .accessibilityIdentifier(shutterIdentifier)
            }

            alternative
        }
        .task {
            await prepareCamera()
            // 面が消えるまで待ち、消えたら（.task が取り消されたら）カメラを止める。
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3600))
            }
            await engine?.stop()
        }
    }

    private func prepareCamera() async {
        if usesTestShutter { return }
        guard PhotoCaptureEngine.hasBackCamera else {
            access = .unavailable
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            // 許可がまだ決まっていなければ、写す面を開いたこのときだけ聞く（design/ 7-3、最初の起動では聞かない）。
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                access = .denied
                onDenied()
                return
            }
        case .denied, .restricted:
            access = .denied
            onDenied()
            return
        @unknown default:
            access = .denied
            onDenied()
            return
        }
        guard !Task.isCancelled else { return }
        let newEngine = PhotoCaptureEngine()
        engine = newEngine
        access = await newEngine.start() ? .ready : .unavailable
    }

    private func shutterTapped() {
        #if UITEST_HOOKS
        if let uiTestShutter {
            uiTestShutter()
            return
        }
        #endif
        guard let engine, !isCapturing else { return }
        isCapturing = true
        Task { @MainActor in
            let data = await engine.capturePhoto()
            isCapturing = false
            // Data から記憶の中の UIImage を作って渡すだけ。ファイルや写真ライブラリには書かない。
            onCaptured(data.flatMap { UIImage(data: $0) })
        }
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
    @Environment(\.themePalette) private var palette

    public init(title: String, author: String, nightsCount: Int, totalMinutes: Int) {
        self.title = title
        self.author = author
        self.nightsCount = nightsCount
        self.totalMinutes = totalMinutes
    }

    public var body: some View {
        VStack(spacing: ThemeSpace.s16) {
            Spacer(minLength: ThemeSpace.s16)

            Text(title)
                .font(ThemeTypography.finishCardTitle(size: 28))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.textPrimary)

            if !author.isEmpty {
                Text(author)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }

            Rectangle()
                .fill(palette.hairline)
                .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                .padding(.vertical, ThemeSpace.s8)

            HStack(spacing: ThemeSpace.s24) {
                Text(BookTextFormat.nights(nightsCount))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(palette.textPrimary)
                Text(ReadingWidgetStrings.durationMinutes(totalMinutes))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(palette.textPrimary)
            }

            Spacer(minLength: ThemeSpace.s16)
        }
        .padding(ThemeSpace.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .japaneseTextTypesetting()

        let renderer = ImageRenderer(content: content)
        renderer.scale = renderScale
        renderer.proposedSize = ProposedViewSize(width: cardWidthPt, height: cardHeightPt)

        var texts: [String] = [title]
        if !author.isEmpty {
            texts.append(author)
        }
        // design/ 7 の `book.nights` と `duration.minutes`（H24 の記録も画像と同じ文字）。
        texts.append(BookTextFormat.nights(nightsCount))
        texts.append(ReadingWidgetStrings.durationMinutes(totalMinutes))

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
