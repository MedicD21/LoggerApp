import SwiftUI

struct NLPLogView: View {
    let container: AppContainer

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NLPLogViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: NLPLogViewModel(repository: container.aiRepository))
    }

    var body: some View {
        Group {
            if let response = viewModel.response {
                PhotoReviewView(container: container, response: response)
            } else {
                Form {
                    Section("Food Text") {
                        TextEditor(text: $viewModel.input)
                            .frame(minHeight: 180)
                        Text("Example: 2 eggs and toast with butter")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        Button("Parse with AI") {
                            Task { await viewModel.parse() }
                        }
                        .buttonStyle(.borderedProminent)

                        if viewModel.isLoading {
                            ProgressView("Parsing…")
                        }
                    }
                }
                .navigationTitle("Natural Language")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { dismiss() }
                    }
                }
                .alert("AI Parsing Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") { viewModel.errorMessage = nil }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
            }
        }
    }
}

