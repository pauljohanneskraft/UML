import SwiftUI
import AcaiDiagram

// MARK: - State Inspectors (states, transitions)

extension FreeformDiagramInspector {

    func transitionSection(edge: FreeformDiagram.Edge) -> some View {
        let stateNodes = viewModel.nodes.filter { viewModel.state.isStateNode($0.id) }
        return Section {
            Picker(.app("FreeformDiagramInspector.Text"), selection: Binding(
                get: { edge.sourceNodeID },
                set: { viewModel.updateEdge(edge.id, sourceID: $0, targetID: edge.targetNodeID, kind: edge.kind) }
            )) {
                ForEach(stateNodes) { node in Text(stateDisplayName(node)).tag(node.id) }
            }

            Picker(.app("FreeformDiagramInspector.Text2"), selection: Binding(
                get: { edge.targetNodeID },
                set: { viewModel.updateEdge(edge.id, sourceID: edge.sourceNodeID, targetID: $0, kind: edge.kind) }
            )) {
                ForEach(stateNodes) { node in Text(stateDisplayName(node)).tag(node.id) }
            }

            TextField(text: Binding(
                get: { edge.transition?.event ?? "" },
                set: { viewModel.state.updateTransitionEdge(edge.id, event: $0) }
            )) {
                Text(.app("FreeformDiagramInspector.Event"))
            }
            .textFieldStyle(.roundedBorder)
            .focused($focusedField, equals: .name)

            TextField(text: Binding(
                get: { edge.transition?.guardCondition ?? "" },
                set: { viewModel.state.updateTransitionEdge(edge.id, guardCondition: $0) }
            )) {
                Text(.app("FreeformDiagramInspector.GuardCondition"))
            }
            .textFieldStyle(.roundedBorder)

            TextField(text: Binding(
                get: { edge.transition?.action ?? "" },
                set: { viewModel.state.updateTransitionEdge(edge.id, action: $0) }
            )) {
                Text(.app("FreeformDiagramInspector.Action"))
            }
            .textFieldStyle(.roundedBorder)
        } header: {
            Text(.app("FreeformDiagramInspector.Transition"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    func stateKindSection(nodeID: String, kind: StateDiagram.State.Kind) -> some View {
        Section {
            Picker(.app("FreeformDiagramInspector.StateKind"), selection: Binding(
                get: { kind },
                set: { viewModel.state.updateStateKind(nodeID, kind: $0) }
            )) {
                Text(.app("FreeformDiagramInspector.State")).tag(StateDiagram.State.Kind.normal)
                Text(.app("FreeformDiagramInspector.Initial")).tag(StateDiagram.State.Kind.initial)
                Text(.app("FreeformDiagramInspector.Final")).tag(StateDiagram.State.Kind.final)
                Text(.app("FreeformDiagramInspector.Choice")).tag(StateDiagram.State.Kind.choice)
            }
            .labelsHidden()
        } header: {
            Text(.app("FreeformDiagramInspector.StateKind2"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    /// Pseudo-states have empty names; fall back to their kind for picker rows.
    private func stateDisplayName(_ node: FreeformDiagram.Node) -> String {
        if !node.name.isEmpty { return node.name }
        if case .state(let kind) = node.content {
            return "(\(kind.rawValue))"
        }
        return "?"
    }
}
