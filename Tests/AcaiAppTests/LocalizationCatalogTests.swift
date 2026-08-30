import Foundation
import Testing
@testable import AcaiApp

/// The app ships in English, German and French, and only Xcode compiles `Localizable.xcstrings` —
/// so a missing identifier or a missing translation is invisible under `swift build` and surfaces
/// as raw text in a shipped build. These checks read the source and the catalog directly, which is
/// why they hold regardless of whether the catalog was compiled.
@Suite("Localization catalog")
struct LocalizationCatalogTests {

    private static let shippedLanguages = ["en", "de", "fr"]

    private let sourceRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources/AcaiApp")

    /// One `.app("Identifier \(x)")` call site.
    private struct Usage {
        let identifier: String
        let argumentCount: Int
        let file: String
    }

    /// A localizable position that must never take a bare literal. The empty literal is the one
    /// exception — `Picker("", …)`/`Button("") { }` label an unlabelled control, not text.
    private static let localizablePrefixes = [
        "Text(", "Label(", "Button(", "Toggle(", "Picker(", "TextField(", "SecureField(",
        "Section(", "Menu(", "Link(", "NavigationLink(", "LabeledContent(", "DisclosureGroup(",
        "Stepper(", "ProgressView(", "ContentUnavailableView(", "TableColumn(", "GroupBox(",
        ".help(", ".navigationTitle(", ".accessibilityLabel(", ".accessibilityHint(",
        ".accessibilityValue(", ".alert(", ".confirmationDialog("
    ]

    // MARK: - Catalog

    private func catalogStrings() throws -> [String: [String: Any]] {
        let url = sourceRoot.appendingPathComponent("Resources/Localizable.xcstrings")
        let object = try JSONSerialization.jsonObject(with: try Data(contentsOf: url))
        let catalog = try #require(object as? [String: Any])
        return try #require(catalog["strings"] as? [String: [String: Any]])
    }

    private func languages(in entry: [String: Any]) -> Set<String> {
        Set((entry["localizations"] as? [String: Any])?.keys ?? [:].keys)
    }

    /// The entry's text in one language: either its flat value, or a plural's `other` form.
    private func text(of entry: [String: Any], _ language: String) -> String? {
        guard let localizations = entry["localizations"] as? [String: Any],
              let localization = localizations[language] as? [String: Any] else { return nil }
        if let unit = localization["stringUnit"] as? [String: Any] { return unit["value"] as? String }
        guard let variations = localization["variations"] as? [String: Any],
              let plural = variations["plural"] as? [String: Any],
              let other = plural["other"] as? [String: Any],
              let unit = other["stringUnit"] as? [String: Any] else { return nil }
        return unit["value"] as? String
    }

    // MARK: - Source

    private func swiftFiles() -> [URL] {
        guard let walker = FileManager.default.enumerator(at: sourceRoot, includingPropertiesForKeys: nil) else {
            return []
        }
        return walker.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
    }

    /// Every `.app("…")` in the module, with the number of interpolated arguments it passes.
    private func usages() -> [Usage] {
        var usages: [Usage] = []
        for file in swiftFiles() {
            guard let source = try? String(contentsOf: file, encoding: .utf8) else { continue }
            var remainder = Substring(source)
            while let start = remainder.range(of: ".app(\"") {
                remainder = remainder[start.upperBound...]
                guard let end = remainder.firstIndex(of: "\"") else { break }
                let literal = remainder[..<end]
                let identifier = literal.prefix { $0 != " " }
                usages.append(
                    Usage(
                        identifier: String(identifier),
                        argumentCount: literal.components(separatedBy: "\\(").count - 1,
                        file: file.lastPathComponent
                    )
                )
                remainder = remainder[end...]
            }
        }
        return usages
    }

    // MARK: - Tests

    @Test("Every identifier used in the app exists in the catalog")
    func everyIdentifierIsInTheCatalog() throws {
        let strings = try catalogStrings()
        for usage in usages() {
            let matches = strings.keys.filter {
                $0 == usage.identifier || $0.hasPrefix(usage.identifier + " %")
            }
            #expect(
                matches.count == 1,
                "\(usage.file): '\(usage.identifier)' matches \(matches.count) catalog keys, expected 1"
            )
        }
    }

    @Test("A call site passes exactly as many arguments as its catalog key has placeholders")
    func argumentCountsMatchPlaceholders() throws {
        let strings = try catalogStrings()
        for usage in usages() {
            let key = strings.keys.first { $0 == usage.identifier || $0.hasPrefix(usage.identifier + " %") }
            guard let key else { continue }
            let placeholders = key.components(separatedBy: " %").count - 1
            #expect(
                placeholders == usage.argumentCount,
                """
                \(usage.file): '\(usage.identifier)' passes \(usage.argumentCount) arguments, \
                catalog key expects \(placeholders)
                """
            )
        }
    }

    @Test("No catalog entry is orphaned")
    func noOrphanedEntries() throws {
        let strings = try catalogStrings()
        let used = Set(usages().map(\.identifier))
        for key in strings.keys {
            let identifier = key.prefix { $0 != " " }
            #expect(used.contains(String(identifier)), "'\(key)' is in the catalog but nothing uses it")
        }
    }

    @Test("Every entry is translated into every shipped language")
    func everyEntryIsTranslated() throws {
        for (key, entry) in try catalogStrings() {
            let present = languages(in: entry)
            let missing = Set(Self.shippedLanguages).subtracting(present).sorted()
            #expect(missing.isEmpty, "'\(key)' is missing \(missing.joined(separator: ", "))")
        }
    }

    /// One English string must not come out two different ways in the same language — the reader
    /// sees the same control named differently on two screens.
    @Test("A term is translated the same way everywhere", arguments: ["de", "fr"])
    func translationsAreConsistent(_ language: String) throws {
        var byEnglish: [String: [String: [String]]] = [:]
        for (key, entry) in try catalogStrings() {
            guard let english = text(of: entry, "en"), let translated = text(of: entry, language) else { continue }
            byEnglish[english, default: [:]][translated, default: []].append(key)
        }
        for (english, renderings) in byEnglish where renderings.count > 1 {
            let detail = renderings
                .sorted { $0.key < $1.key }
                .map { "\"\($0.key)\" (\($0.value.sorted().joined(separator: ", ")))" }
                .joined(separator: " vs ")
            Issue.record("\(language): \"\(english)\" is translated \(renderings.count) ways — \(detail)")
        }
    }

    /// The diagram kinds are one family: translating some names and leaving others in English reads
    /// as an oversight. A name may stay English only as a deliberate loanword, listed here.
    private static let loanwordDiagramNames: [String: Set<String>] = [
        "de": ["DiagramType.Hotspots"],
        "fr": []
    ]

    @Test("Diagram names are translated as one family", arguments: ["de", "fr"])
    func diagramNamesAgree(_ language: String) throws {
        let strings = try catalogStrings()
        let loanwords = Self.loanwordDiagramNames[language] ?? []
        let names = strings.keys.filter { $0.hasPrefix("DiagramType.") }
        var untranslated: [String] = []
        var translated: [String] = []
        for key in names.sorted() {
            guard let entry = strings[key], let english = text(of: entry, "en"),
                  let localized = text(of: entry, language) else { continue }
            guard !loanwords.contains(key) else { continue }
            if localized == english { untranslated.append(key) } else { translated.append(key) }
        }
        #expect(
            untranslated.isEmpty || translated.isEmpty,
            """
            \(language): \(translated.count) diagram names are translated but \
            \(untranslated.joined(separator: ", ")) stayed English — translate them too, or add \
            them to `loanwordDiagramNames` if that is deliberate
            """
        )
    }

    @Test("No string reaches the interface as a bare literal")
    func noBareLiterals() throws {
        for file in swiftFiles() {
            guard let source = try? String(contentsOf: file, encoding: .utf8) else { continue }
            for prefix in Self.localizablePrefixes {
                var searched = source.startIndex
                while let start = source.range(of: prefix + "\"", range: searched..<source.endIndex) {
                    searched = start.upperBound
                    // `Label(` must be the whole word, not the tail of `chartXAxisLabel(`.
                    let isWholeWord = prefix.hasPrefix(".") || start.lowerBound == source.startIndex
                        || !(source[source.index(before: start.lowerBound)].isLetter
                             || source[source.index(before: start.lowerBound)] == ".")
                    guard isWholeWord else { continue }
                    #expect(
                        source[start.upperBound...].first == "\"",
                        "\(file.lastPathComponent): \(prefix)\"…\") takes a bare literal — use .app(\"…\")"
                    )
                }
            }
        }
    }
}
