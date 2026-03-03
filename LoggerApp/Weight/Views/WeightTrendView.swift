import Charts
import SwiftUI

struct WeightTrendView: View {
    let container: AppContainer
    let profile: UserProfile

    @StateObject private var viewModel: WeightViewModel
    @State private var showAddEntry = false
    @State private var entryValue = 0.0

    init(container: AppContainer, profile: UserProfile) {
        self.container = container
        self.profile = profile
        _viewModel = StateObject(wrappedValue: WeightViewModel(repository: container.weightRepository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("90-Day Trend")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.brandInk)
                    Chart {
                        ForEach(viewModel.entries, id: \.id) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", entry.pounds)
                            )
                            .foregroundStyle(Color.brandSecondary.opacity(0.45))
                        }

                        ForEach(viewModel.movingAverage, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Average", UnitConverter.pounds(fromKilograms: point.value))
                            )
                            .lineStyle(.init(lineWidth: 3))
                            .foregroundStyle(Color.brandPrimary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4))
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartPlotStyle { plot in
                        plot
                            .background(Color.brandSurface.opacity(0.55))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .frame(height: 260)
                    .padding()
                    .brandPanel(cornerRadius: 24)
                }

                Button("Add Weight Entry") {
                    entryValue = profile.weightKg * 2.20462
                    showAddEntry = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Entries")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.brandInk)

                    ForEach(viewModel.entries.suffix(10).reversed(), id: \.id) { entry in
                        HStack {
                            Text(entry.date.shortDayLabel)
                                .foregroundStyle(Color.brandMuted)
                            Spacer()
                            Text(String(format: "%.1f lb", entry.pounds))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.brandInk)
                        }
                        .padding(16)
                        .brandPanel(cornerRadius: 18)
                    }
                }
            }
            .padding(20)
        }
        .background(BrandBackdrop())
        .navigationTitle("Trends")
        .task { viewModel.load() }
        .sheet(isPresented: $showAddEntry) {
            NavigationStack {
                Form {
                    Section("Weight") {
                        TextField("Weight (lb)", value: $entryValue, format: .number)
                            .keyboardType(.decimalPad)
                    }

                    Section {
                        Button("Save Entry") {
                            viewModel.add(value: entryValue, unit: .lb, profile: profile)
                            showAddEntry = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(BrandBackdrop())
                .navigationTitle("Add Weight")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { showAddEntry = false }
                    }
                }
            }
        }
        .alert("Weight Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
