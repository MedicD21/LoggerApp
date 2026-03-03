import SwiftUI

struct FoodSearchView: View {
    let container: AppContainer
    let profile: UserProfile

    @StateObject private var viewModel: FoodSearchViewModel
    @State private var showScanner = false
    @State private var showCustomFoodEditor = false
    @State private var showPhotoCapture = false
    @State private var showNLP = false

    init(container: AppContainer, profile: UserProfile) {
        self.container = container
        self.profile = profile
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
                .disabled(!canUseAI)

                actionRow("Natural language log", systemImage: "text.bubble") {
                    showNLP = true
                }
                .disabled(!canUseAI)

                actionRow("Create custom food", systemImage: "square.and.pencil") {
                    showCustomFoodEditor = true
                }
            }

            if !canUseAI {
                Section("AI Setup") {
                    Text(
                        profile.aiEnabled
                        ? "Add your Anthropic API key in Settings to enable photo and natural-language logging."
                        : "AI logging is disabled in Settings."
                    )
                    .foregroundStyle(.secondary)
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
            } else if viewModel.hasSearched && !viewModel.isSearching {
                Section("Results") {
                    Text("No foods matched your search. Try a brand name, barcode, or a simpler generic food.")
                        .foregroundStyle(.secondary)
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
        .background(BrandBackdrop())
        .listStyle(.insetGrouped)
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
                Text("\(item.category.rawValue.capitalized) • \(item.nutrition(for: item.defaultServingGrams).calories.decimalString(maxFractionDigits: 0)) kcal / \(UnitConverter.displayWeight(item.defaultServingGrams))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(macroSummary(for: item))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if item.source == .off || item.source == .usda {
                Image(systemName: item.source.systemImage)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func macroSummary(for item: FoodItem) -> String {
        let nutrition = item.nutrition(for: item.defaultServingGrams)
        return "P \(nutrition.protein.decimalString())g • C \(nutrition.carbs.decimalString())g • F \(nutrition.fat.decimalString())g"
    }

    private var canUseAI: Bool {
        profile.aiEnabled && container.anthropicClient.hasAPIKey()
    }
}
