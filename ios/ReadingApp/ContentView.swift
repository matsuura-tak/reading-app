import SwiftUI
import ReadingCore
import ReadingStore

public struct ContentView: View {
    @Bindable var model: ReadingAppModel

    public init(model: ReadingAppModel) {
        self.model = model
    }

    private var palette: ThemePalette {
        ThemePalette(appearanceID: model.settings.appearanceID)
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            TabView(selection: $model.activeTab) {
                NavigationStack {
                    bookmarkTabContent
                }
                .tabItem {
                    Label("tab.bookmark.title", systemImage: "bookmark.fill")
                }
                .tag(AppActiveTab.bookmark)
                .accessibilityIdentifier("tab.bookmark")

                NavigationStack {
                    shelfTabContent
                }
                .tabItem {
                    Label("tab.shelf.title", systemImage: "books.vertical.fill")
                }
                .tag(AppActiveTab.shelf)
                .accessibilityIdentifier("tab.shelf")
            }
            .tint(palette.accent)

            #if UITEST_HOOKS
            UITestHookOverlayView(model: model)
            #endif
        }
        .environment(\.themePalette, palette)
        .preferredColorScheme(palette.preferredColorScheme)
    }

    @ViewBuilder
    private var bookmarkTabContent: some View {
        VStack(spacing: 24) {
            if let current = model.currentBook {
                Text(current.isTitlePending ? String(localized: "common.book.titlePending") : current.title)
                    .font(.custom("Hiragino Mincho ProN", size: 22, relativeTo: .title2))
                    .foregroundStyle(palette.textPrimary)
                    .accessibilityIdentifier("bookmark.book.title")

                if !current.author.isEmpty && !current.isTitlePending {
                    Text(current.author)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .accessibilityIdentifier("bookmark.book.author")
                }

                if let line = current.lastSavedLine, !line.isEmpty {
                    Text(line)
                        .font(.custom("Hiragino Mincho ProN", size: 17, relativeTo: .body))
                        .foregroundStyle(palette.textPrimary)
                        .accessibilityIdentifier("bookmark.latestLine")
                } else {
                    Text("bookmark.latestLine.empty")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .accessibilityIdentifier("bookmark.latestLine.empty")
                }

                Button {
                    _ = model.store.startReadingSession(startedBy: "tap", explicitEntry: .app)
                    model.currentScreen = .sessionActive
                    model.notifyHookChanged()
                } label: {
                    Text("bookmark.startReading.cta")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(palette.accent)
                .accessibilityIdentifier("bookmark.start.button")
            } else {
                Text("bookmark.empty.title")
                    .font(.custom("Hiragino Mincho ProN", size: 20, relativeTo: .title3))
                    .foregroundStyle(palette.textPrimary)
                    .accessibilityIdentifier("bookmark.empty.title")

                Text("bookmark.empty.body")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("bookmark.empty.body")

                Button {
                    model.currentScreen = .bookAdd
                    model.notifyHookChanged()
                } label: {
                    Text("bookmark.empty.primaryCta")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(palette.accent)
                .accessibilityIdentifier("bookmark.empty.addBookButton")

                Button {
                    _ = model.store.startReadingWithPendingTitleBook()
                    if model.store.sessionState == .reading {
                        model.currentScreen = .sessionActive
                    }
                    model.notifyHookChanged()
                } label: {
                    Text("bookmark.empty.secondaryCta")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.accent)
                        .frame(minHeight: 44)
                }
                .accessibilityIdentifier("bookmark.empty.startWithoutBookButton")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.bgPrimary)
        .navigationTitle(Text("tab.bookmark.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var shelfTabContent: some View {
        List {
            Section {
                ForEach(model.store.tsundokuBooks) { book in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.body)
                            .foregroundStyle(palette.textPrimary)
                        if !book.author.isEmpty {
                            Text(book.author)
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)
                        }
                    }
                    .accessibilityIdentifier("shelf.book.\(book.id.uuidString)")
                }
            } header: {
                Text("shelf.section.tsundoku")
            }

            Section {
                ForEach(model.store.finishedBooks) { book in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.body)
                            .foregroundStyle(palette.textPrimary)
                        if !book.author.isEmpty {
                            Text(book.author)
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)
                        }
                    }
                    .accessibilityIdentifier("shelf.book.\(book.id.uuidString)")
                }
            } header: {
                Text("shelf.section.finished")
            }
        }
        .scrollContentBackground(.hidden)
        .background(palette.bgPrimary)
        .navigationTitle(Text("shelf.navigation.title"))
    }
}
