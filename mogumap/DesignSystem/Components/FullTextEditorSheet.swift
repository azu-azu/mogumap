import SwiftUI

struct FullTextEditorSheet: View {
    @Binding var text: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .padding()
                .background(DesignTokens.Background.base.ignoresSafeArea())
                .navigationTitle("section.thoughts".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("action.done".localized) { dismiss() }
                    }
                }
                .keyboardCloseToolbar()
                .task {
                    isFocused = true
                }
        }
    }
}
