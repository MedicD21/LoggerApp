import SwiftUI

struct GLP1TrackerView: View {
    let container: AppContainer
    let profile: UserProfile

    @StateObject private var viewModel: MedicationViewModel
    @State private var showSetup = false
    @State private var showDoseSheet = false
    @State private var sideEffects = ""
    @State private var selectedSite = ""

    init(container: AppContainer, profile: UserProfile) {
        self.container = container
        self.profile = profile
        _viewModel = StateObject(wrappedValue: MedicationViewModel(repository: container.medicationRepository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let schedule = viewModel.schedule {
                    scheduledContent(schedule)
                } else {
                    emptyState
                }

                Text("Safety disclaimer: reminders and logs only. Confirm medication plans with your clinician.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .background(BrandBackdrop())
        .navigationTitle("GLP-1")
        .task { viewModel.load() }
        .sheet(isPresented: $showSetup) {
            MedicationSetupView(viewModel: viewModel)
        }
        .sheet(isPresented: $showDoseSheet) {
            NavigationStack {
                Form {
                    Section("Dose") {
                        TextField("Injection site", text: $selectedSite)
                        TextField("Side effects", text: $sideEffects, axis: .vertical)
                    }
                    Section {
                        Button("Save Dose") {
                            viewModel.logDose(site: selectedSite.isEmpty ? "Not specified" : selectedSite, sideEffects: sideEffects.nilIfEmpty)
                            showDoseSheet = false
                            let profileSnapshot = NotificationProfileSnapshot(profile: profile)
                            let medicationSnapshot = viewModel.schedule.map(MedicationReminderSnapshot.init)
                            Task { @MainActor in
                                try? await container.notificationManager.refreshNotifications(
                                    profile: profileSnapshot,
                                    medication: medicationSnapshot
                                )
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .navigationTitle("Log Dose")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { showDoseSheet = false }
                    }
                }
            }
        }
        .alert("Medication Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func scheduledContent(_ schedule: MedicationSchedule) -> some View {
        scheduleHero(schedule)

        Button("Log Dose") {
            selectedSite = schedule.nextSuggestedSite == "Not set" ? "" : schedule.nextSuggestedSite
            showDoseSheet = true
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)

        Button("Update Schedule") {
            showSetup = true
        }
        .buttonStyle(.bordered)
        .controlSize(.large)

        recentDosesSection
    }

    private func scheduleHero(_ schedule: MedicationSchedule) -> some View {
        let dueText = schedule.nextDueDate.timeIntervalSinceNow > 0
            ? schedule.nextDueDate.formatted(date: .abbreviated, time: .shortened)
            : "Due now"

        return VStack(alignment: .leading, spacing: 10) {
            Text(schedule.medicationName)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.brandInk)
            Text(schedule.doseDisplay)
                .font(.subheadline)
                .foregroundStyle(Color.brandMuted)
            Text(dueText)
                .font(.headline)
                .foregroundStyle(Color.brandInk)
            Text("Next suggested site: \(schedule.nextSuggestedSite)")
                .font(.subheadline)
                .foregroundStyle(Color.brandMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .brandHeroPanel(cornerRadius: 28, accent: .brandPrimary)
    }

    private var recentDosesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Doses")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.brandInk)

            ForEach(viewModel.doses, id: \.id) { dose in
                VStack(alignment: .leading, spacing: 4) {
                    Text(dose.administeredAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandInk)
                    Text("Site: \(dose.site)")
                        .font(.caption)
                        .foregroundStyle(Color.brandMuted)
                    if let sideEffects = dose.sideEffects, !sideEffects.isEmpty {
                        Text("Side effects: \(sideEffects)")
                            .font(.caption)
                            .foregroundStyle(Color.brandMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .brandPanel(cornerRadius: 18)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("No medication schedule yet.")
                .font(.headline)
                .foregroundStyle(Color.brandInk)
            Text("This tracker is for reminders and logs only. It does not provide dosage advice or medical guidance.")
                .font(.subheadline)
                .foregroundStyle(Color.brandMuted)
            Button("Set Up Tracker") {
                showSetup = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .brandPanel(cornerRadius: 24)
    }
}

private struct MedicationSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MedicationViewModel

    @State private var medicationName = ""
    @State private var doseDisplay = ""
    @State private var frequencyType: MedicationFrequencyType = .weekly
    @State private var intervalDays = 7
    @State private var siteRotation = "Left abdomen,Right abdomen,Left thigh,Right thigh"
    @State private var nextDueDate = Date().adding(days: 7)
    @State private var remainingDoses = 4
    @State private var refillReminderDaysAhead = 7

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Medication name", text: $medicationName)
                    TextField("Dose", text: $doseDisplay)
                    Picker("Frequency", selection: $frequencyType) {
                        ForEach(MedicationFrequencyType.allCases) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    if frequencyType == .custom {
                        Stepper("Every \(intervalDays) days", value: $intervalDays, in: 1...30)
                    }
                    DatePicker("Next due", selection: $nextDueDate)
                }

                Section("Inventory") {
                    Stepper("Remaining doses: \(remainingDoses)", value: $remainingDoses, in: 0...20)
                    Stepper("Refill reminder: \(refillReminderDaysAhead) days before", value: $refillReminderDaysAhead, in: 1...30)
                    TextField("Rotation sites", text: $siteRotation)
                }

                Section {
                    Button("Save Schedule") {
                        viewModel.saveSchedule(
                            medicationName: medicationName,
                            doseDisplay: doseDisplay,
                            frequencyType: frequencyType,
                            intervalDays: intervalDays,
                            siteRotation: siteRotation
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
                            nextDueDate: nextDueDate,
                            remainingDoses: remainingDoses,
                            refillReminderDaysAhead: refillReminderDaysAhead
                        )
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(BrandBackdrop())
            .navigationTitle("Medication Setup")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
