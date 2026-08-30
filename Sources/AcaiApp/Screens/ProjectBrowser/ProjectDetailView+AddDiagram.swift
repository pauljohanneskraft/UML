import SwiftUI

extension ProjectDetailView {
    /// Shown instead of the header's action buttons + two empty sections when a project has
    /// neither codebases nor diagrams yet, reusing `FreeformDiagramView.emptyCanvasHint`'s visual
    /// language.
    var emptyProjectContentState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.full")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(.app("ProjectDetailView.LetSAddFirst"))
                .font(.title3)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button {
                    addingCodebase = true
                } label: {
                    Label(.app("ProjectDetailView.AddCodebase"), systemImage: "plus")
                }
                .accessibilityIdentifier("projectDetail.addCodebaseButton")
                addDiagramButton
            }
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    var addDiagramButton: some View {
        Button {
            createDiagram(name: "New Freeform Diagram")
        } label: {
            Label(.app("ProjectDetailView.AddDiagram"), systemImage: "rectangle.3.group")
        }
        .accessibilityIdentifier("projectDetail.addDiagramButton")
    }

    func createDiagram(name: String) {
        if let id = model.freeforms.add(to: projectID, name: name) {
            model.selection = .freeformDiagram(id)
        }
    }
}
