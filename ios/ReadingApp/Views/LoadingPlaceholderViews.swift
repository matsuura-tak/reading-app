import SwiftUI
import ReadingStore

/// 読み込みに 0.3秒を超えてかかったときだけ、design/ 5 の読み込み中の形を出す入れ物。空の状態を先に出さない。
/// 読み込みの門（`LoadHoldGate`）が素通りのとき（Release とふつうの起動）は、最初から中身を出し、何も待たない。
struct GatedLoadView<Content: View, Placeholder: View>: View {
    let gate: LoadHoldGate
    let point: LoadHoldGate.Point
    @ViewBuilder let content: () -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @State private var isLoaded: Bool
    @State private var isPlaceholderVisible = false

    init(
        gate: LoadHoldGate,
        point: LoadHoldGate.Point,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.gate = gate
        self.point = point
        self.content = content
        self.placeholder = placeholder
        _isLoaded = State(initialValue: !gate.willHold(point))
    }

    var body: some View {
        Group {
            if isLoaded {
                content()
            } else if isPlaceholderVisible {
                placeholder()
                    .onAppear { gate.markShown(point) }
            } else {
                Color.clear
            }
        }
        .task {
            guard !isLoaded else { return }
            let clock = ContinuousClock()
            let deadline = clock.now.advanced(by: .milliseconds(300))
            let reveal = Task { @MainActor in
                try? await clock.sleep(until: deadline)
                if !Task.isCancelled {
                    isPlaceholderVisible = true
                }
            }
            await gate.pass(point)
            reveal.cancel()
            isLoaded = true
        }
    }
}

/// S-1 の読み込み中：書名と一行の形の灰の帯（redacted）。帯の文字は形を作るためだけのもので、画面には出ない。
struct BookmarkLoadingPlaceholderView: View {
    @Environment(\.themePalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            Text(verbatim: String(repeating: "■", count: 6))
                .font(.title2)
            Text(verbatim: String(repeating: "■", count: 4))
                .font(.subheadline)
            HStack(alignment: .top, spacing: ThemeSpace.s12) {
                Spacer(minLength: 0)
                ForEach(0..<3, id: \.self) { _ in
                    Text(verbatim: String(repeating: "■\n", count: 7))
                        .font(ThemeTypography.bookmarkLine())
                }
            }
            Spacer(minLength: 0)
        }
        .padding(ThemeSpace.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(palette.bgPrimary)
        .redacted(reason: .placeholder)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("common.loading"))
    }
}

/// 行の形の灰の帯を、画面の中の一覧の位置に並べる（S-8a の行、S-8c の候補）。
struct RedactedRowListView: View {
    let rowCount: Int
    @Environment(\.themePalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpace.s16) {
            ForEach(0..<rowCount, id: \.self) { _ in
                VStack(alignment: .leading, spacing: ThemeSpace.s4) {
                    Text(verbatim: String(repeating: "■", count: 10))
                        .font(.headline)
                    Text(verbatim: String(repeating: "■", count: 6))
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(ThemeSpace.s16)
                .background(RoundedRectangle(cornerRadius: ThemeRadius.card).fill(palette.groupedRow))
            }
        }
        .redacted(reason: .placeholder)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("common.loading"))
    }
}

/// 行の形の灰の帯（S-6 は5行）。画面全体を埋める。
struct RedactedRowsPlaceholderView: View {
    let rowCount: Int
    @Environment(\.themePalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RedactedRowListView(rowCount: rowCount)
            Spacer(minLength: 0)
        }
        .padding(ThemeSpace.s16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(palette.bgPrimary)
    }
}

#Preview("S-1/loading") {
    BookmarkLoadingPlaceholderView()
}

#Preview("S-6/loading") {
    RedactedRowsPlaceholderView(rowCount: 5)
}

#Preview("S-6/loading AX5") {
    RedactedRowsPlaceholderView(rowCount: 5)
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("S-8c/loading") {
    RedactedRowListView(rowCount: 3)
        .padding()
}

#Preview("S-1/loading dark") {
    BookmarkLoadingPlaceholderView()
        .preferredColorScheme(.dark)
}
