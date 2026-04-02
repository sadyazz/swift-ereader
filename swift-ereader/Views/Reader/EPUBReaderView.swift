import SwiftUI
import SwiftData
import ReadiumNavigator
import ReadiumShared

struct EPUBReaderView: View {
    @Environment(\.modelContext) private var modelContext
    let book: Book
    @State private var publication: Publication?
    @State private var navigator: EPUBNavigatorViewController?
    @State private var error: String?
    @State private var currentTheme: Theme
    @State private var fontSize: Double
    @State private var showSettings = false
    @State private var showTOC = false

    init(book: Book) {
        self.book = book
        let savedTheme = UserDefaults.standard.string(forKey: "readerTheme") ?? "light"
        let savedFontSize = UserDefaults.standard.double(forKey: "readerFontSize")
        _currentTheme = State(initialValue: Theme(rawValue: savedTheme) ?? .light)
        _fontSize = State(initialValue: savedFontSize > 0 ? savedFontSize : 100)
    }

    var body: some View {
        Group {
            if let publication, let navigator {
                EPUBView(navigator: navigator)
            } else if let error {
                Text("Failed to open: \(error)")
            } else {
                ProgressView("Opening...")
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showTOC = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "textformat")
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ReaderSettingsSheet(
                currentTheme: $currentTheme,
                fontSize: $fontSize,
                onThemeChange: { theme in
                    setTheme(theme)
                },
                onFontSizeChange: { size in
                    setFontSize(size)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTOC) {
            if let publication {
                TOCView(publication: publication) { link in
                    showTOC = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        Task { await navigator?.go(to: link) }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onDisappear {
            if let locator = navigator?.currentLocation,
               let data = try? JSONSerialization.data(withJSONObject: locator.json),
               let json = String(data: data, encoding: .utf8) {
                book.epubLocator = json
                try? modelContext.save()
            }
        }
        .task {
            do {
                let pub = try await BookOpener.shared.open(url: book.fileURL)
                publication = pub

                var locator: Locator? = nil
                if let json = book.epubLocator {
                    locator = try? Locator(jsonString: json)
                }

                var config = EPUBNavigatorViewController.Configuration()
                config.preferences = EPUBPreferences(
                    fontSize: fontSize / 100.0,
                    theme: currentTheme
                )

                navigator = try EPUBNavigatorViewController(
                    publication: pub,
                    initialLocation: locator,
                    config: config
                )

                if book.coverImage == nil, let coverImage = try? await pub.cover().get() {
                    if let data = coverImage.jpegData(compressionQuality: 0.7) {
                        let filename = book.title.replacingOccurrences(of: " ", with: "_") + "_cover.jpg"
                        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        let coverURL = docsDir.appendingPathComponent(filename)
                        try? data.write(to: coverURL)
                        book.coverImage = filename
                    }
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func setTheme(_ theme: Theme) {
        currentTheme = theme
        applyPreferences()
    }

    private func setFontSize(_ size: Double) {
        fontSize = size
        applyPreferences()
    }

    private func applyPreferences() {
        var prefs = EPUBPreferences()
        prefs.theme = currentTheme
        prefs.fontSize = fontSize / 100.0
        navigator?.submitPreferences(prefs)
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "readerTheme")
        UserDefaults.standard.set(fontSize, forKey: "readerFontSize")
    }
}

struct ReaderSettingsSheet: View {
    @Binding var currentTheme: Theme
    @Binding var fontSize: Double
    var onThemeChange: (Theme) -> Void
    var onFontSizeChange: (Double) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Reader Settings")
                .font(.headline)

            // theme selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    ThemeButton(
                        label: "Light",
                        bgColor: SwiftUI.Color.white,
                        textColor: SwiftUI.Color.black,
                        isSelected: currentTheme == .light
                    ) {
                        currentTheme = .light
                        onThemeChange(.light)
                    }

                    ThemeButton(
                        label: "Sepia",
                        bgColor: SwiftUI.Color(red: 0.98, green: 0.95, blue: 0.9),
                        textColor: SwiftUI.Color(red: 0.35, green: 0.25, blue: 0.1),
                        isSelected: currentTheme == .sepia
                    ) {
                        currentTheme = .sepia
                        onThemeChange(.sepia)
                    }

                    ThemeButton(
                        label: "Dark",
                        bgColor: SwiftUI.Color(red: 0.15, green: 0.15, blue: 0.15),
                        textColor: SwiftUI.Color.white,
                        isSelected: currentTheme == .dark
                    ) {
                        currentTheme = .dark
                        onThemeChange(.dark)
                    }
                }
            }
            .padding(.horizontal)

            // font size
            VStack(alignment: .leading, spacing: 12) {
                Text("Font Size")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    Button {
                        let newSize = max(50, fontSize - 10)
                        fontSize = newSize
                        onFontSizeChange(newSize)
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(SwiftUI.Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }

                    Slider(value: $fontSize, in: 50...200, step: 10) { editing in
                        if !editing {
                            onFontSizeChange(fontSize)
                        }
                    }

                    Button {
                        let newSize = min(200, fontSize + 10)
                        fontSize = newSize
                        onFontSizeChange(newSize)
                    } label: {
                        Image(systemName: "textformat.size.larger")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(SwiftUI.Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                }

                Text("\(Int(fontSize))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct ThemeButton: View {
    let label: String
    let bgColor: SwiftUI.Color
    let textColor: SwiftUI.Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(bgColor)
                    .frame(height: 60)
                    .overlay(
                        Text("Aa")
                            .font(.title2)
                            .foregroundColor(textColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? SwiftUI.Color.pink : SwiftUI.Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )

                Text(label)
                    .font(.caption)
                    .foregroundColor(isSelected ? .pink : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct EPUBView: UIViewControllerRepresentable {
    let navigator: EPUBNavigatorViewController

    func makeUIViewController(context: Context) -> EPUBNavigatorViewController {
        navigator
    }

    func updateUIViewController(_ uiViewController: EPUBNavigatorViewController, context: Context) {}
}
