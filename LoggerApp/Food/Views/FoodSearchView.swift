import SwiftUI

struct FoodSearchView: View {
    let container: AppContainer

    @StateObject private var viewModel: FoodSearchViewModel
    @State private var showScanner = false
    @State private var showCustomFoodEditor = false
    @State private var showPhotoCapture = false
    @State private var showNLP = false

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: FoodSearchViewModel(repository: container.foodRepository))
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search packaged or generic foods", text: $viewModel.query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit {
                            Task { await viewModel.search() }
                        }

                    if viewModel.isSearching {
                        ProgressView()
                    } else {
                        Button("Search") {
                            Task { await viewModel.search() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Quick Actions") {
                actionRow("Scan barcode", systemImage: "barcode.viewfinder") {
                    showScanner = true
                }

                actionRow("Log from photo", systemImage: "camera") {
                    showPhotoCapture = true
                }

                actionRow("Natural language log", systemImage: "text.bubble") {
                    showNLP = true
                }

                actionRow("Create custom food", systemImage: "square.and.pencil") {
                    showCustomFoodEditor = true
                }
            }

            if !viewModel.results.isEmpty {
                Section("Results") {
                    ForEach(viewModel.results, id: \.id) { item in
                        NavigationLink {
                            FoodDetailView(container: container, food: item)
                        } label: {
                            foodRow(item)
                        }
                    }
                }
            } else {
                Section("Recent") {
                    if viewModel.recentFoods.isEmpty {
                        Text("Recent foods appear here after your first logs.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.recentFoods, id: \.id) { item in
                            NavigationLink {
                                FoodDetailView(container: container, food: item)
                            } label: {
                                foodRow(item)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
        .navigationTitle("Food Search")
        .task { viewModel.loadRecent() }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView { code in
                Task { await viewModel.searchBarcode(code) }
            }
        }
        .sheet(isPresented: $showCustomFoodEditor) {
            NavigationStack {
                CustomFoodEditorView(container: container)
            }
        }
        .sheet(isPresented: $showPhotoCapture) {
            NavigationStack {
                PhotoCaptureView(container: container)
            }
        }
        .sheet(isPresented: $showNLP) {
            NavigationStack {
                NLPLogView(container: container)
            }
        }
        .alert("Search Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func actionRow(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func foodRow(_ item: FoodItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.subheadline.weight(.semibold))
                Text("\(item.category.rawValue.capitalized) • \(Int((item.kcalPer100g ?? 0).rounded())) kcal / 100g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if item.source == .off {
                Image(systemName: "shippingbox")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

