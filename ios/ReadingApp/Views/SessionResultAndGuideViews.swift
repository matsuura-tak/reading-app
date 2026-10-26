import SwiftUI
import ReadingCore
import ReadingStore

public enum SessionResultSheetState: Equatable, Sendable {
    case standard(summaryText: String)
    case capped(summaryText: String, noticeText: String)
}

public struct SessionResultSheetView: View {
    @Bindable var model: ReadingAppModel
    public let previewState: SessionResultSheetState?

    public init(model: ReadingAppModel, previewState: SessionResultSheetState? = nil) {
        self.model = model
        self.previewState = previewState
    }

    private var resolvedState: SessionResultSheetState {
        if let previewState { return previewState }
        let summary = model.store.latestResultSummary ?? "15分"
        if model.store.activeNoticeKey == "session.capped" {
            return .capped(summaryText: summary, noticeText: BannerNoticeView.message(forKey: "session.capped"))
        }
        return .standard(summaryText: summary)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                BannerNoticeView(model: model)

                Spacer()

                switch resolvedState {
                case .standard(let summaryText):
                    Text(summaryText)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("result.summary")
                        .accessibilityLabel(summaryText)
                        .accessibilityValue(summaryText)
                case .capped(let summaryText, _):
                    Text(summaryText)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("result.summary")
                        .accessibilityLabel(summaryText)
                        .accessibilityValue(summaryText)
                }

                Spacer()

                Button {
                    model.store.activeNoticeKey = nil
                    if model.store.showWidgetGuide {
                        model.currentScreen = .widgetGuide
                        model.activeSheet = .widgetGuide
                    } else {
                        model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
                        model.activeSheet = nil
                    }
                    model.notifyHookChanged()
                } label: {
                    Text("おやすみ")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("result.close")
            }
            .padding(24)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("sheet.result")
            .navigationTitle("今夜の読書")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                model.currentScreen = .sessionResult
                model.notifyHookChanged()
            }
        }
    }
}

public enum WidgetGuideSheetState: Equatable, Sendable {
    case visible
}

public struct WidgetGuideSheetView: View {
    @Bindable var model: ReadingAppModel
    public let state: WidgetGuideSheetState

    public init(model: ReadingAppModel, state: WidgetGuideSheetState = .visible) {
        self.model = model
        self.state = state
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("ロック画面やホーム画面にしおりを置く")
                    .font(.title3.bold())
                    .accessibilityIdentifier("widgetGuide.title")

                Text("ロック画面を長押しして「カスタマイズ」から「よむま」のウィジェットを追加すると、残した一行がいつでも目に入ります。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("widgetGuide.steps")

                Spacer()

                Button {
                    model.store.showWidgetGuide = false
                    model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
                    model.activeSheet = nil
                    model.notifyHookChanged()
                } label: {
                    Text("閉じる")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("widgetGuide.close")
            }
            .padding(24)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("widgetGuide")
            .navigationTitle("ウィジェットの案内")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                model.currentScreen = .widgetGuide
                model.notifyHookChanged()
            }
        }
    }
}

#Preview("S-4 Session Result Standard") {
    let model = ReadingAppModel()
    SessionResultSheetView(model: model, previewState: .standard(summaryText: "p.45 → p.62　25分"))
}

#Preview("S-4 Session Result Capped") {
    let model = ReadingAppModel()
    SessionResultSheetView(model: model, previewState: .capped(summaryText: "1440分", noticeText: "24時間を上限として記録しました。"))
}

#Preview("S-5 Widget Guide AX5 Dark") {
    let model = ReadingAppModel()
    WidgetGuideSheetView(model: model)
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}
