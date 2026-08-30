import SwiftUI
import AcaiQuality

/// Editor for the "`from` must not depend on `to`" forbidden-dependency rules.
struct ForbiddenRulesEditor: View {
    @Binding var rules: [DependencyRule]

    var body: some View {
        RuleSection(
            title: "Forbidden dependencies",
            total: rules.count,
            onAdd: add,
            content: {
                ForEach(rules.indices, id: \.self) { index in
                    row(index)
                }
            })
    }

    private func add() {
        rules.append(DependencyRule(from: AcaiQuality.Selector(), to: AcaiQuality.Selector()))
    }

    private func row(_ index: Int) -> some View {
        RuleCard(onRemove: { rules.remove(at: index) }, content: {
            SelectorEditor(title: "From", selector: $rules[index].from)
            SelectorEditor(title: "To", selector: $rules[index].to)
            HStack {
                Text(.app("View.ForbiddenRulesEditor.EdgeKinds")).font(.caption.bold()).foregroundStyle(.secondary)
                RelationshipKindPicker(kinds: $rules[index].kinds)
            }
            TextField(text: $rules[index].message.orEmpty) {
                Text(.app("View.ForbiddenRulesEditor.CustomMessageOptional"))
            }
            .textFieldStyle(.roundedBorder)
        })
    }
}

/// Editor for stereotype contracts: "only `only`-matching types may depend into `into`."
struct ContractsEditor: View {
    @Binding var contracts: [StereotypeContract]

    var body: some View {
        RuleSection(
            title: "Access contracts",
            total: contracts.count,
            onAdd: add,
            content: {
                ForEach(contracts.indices, id: \.self) { index in
                    row(index)
                }
            })
    }

    private func add() {
        contracts.append(StereotypeContract(into: AcaiQuality.Selector(), only: AcaiQuality.Selector()))
    }

    private func row(_ index: Int) -> some View {
        RuleCard(onRemove: { contracts.remove(at: index) }, content: {
            SelectorEditor(title: "Into (protected region)", selector: $contracts[index].into)
            SelectorEditor(title: "Only (allowed sources)", selector: $contracts[index].only)
            HStack {
                Text(.app("View.ContractsEditor.EdgeKinds")).font(.caption.bold()).foregroundStyle(.secondary)
                RelationshipKindPicker(kinds: $contracts[index].kinds)
            }
            TextField(text: $contracts[index].message.orEmpty) {
                Text(.app("View.ContractsEditor.CustomMessageOptional"))
            }
            .textFieldStyle(.roundedBorder)
        })
    }
}
