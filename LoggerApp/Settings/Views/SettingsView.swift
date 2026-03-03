import SwiftUI

struct SettingsView: View {
    let container: AppContainer
    @Bindable var profile: UserProfile

    @StateObject private var viewModel: SettingsViewModel
    @State private var apiKey = ""
    @State private var showDeleteAlert = false

    init(container: AppContainer, profile: UserProfile) {
        self.container = container
        self.profile = profile
        _viewModel = StateObject(wrappedValue: SettingsViewModel(container: container))
    }

    var body: some View {
        Form {
            Section("Macro Targets") {
                TextField("Calories", value: $profile.customCalorieTarget, format: .number)
                    .keyboardType(.numberPad)
                TextField("Protein (g)", value: $profile.customProteinTarget, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Carbs (g)", value: $profile.customCarbTarget, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Fat (g)", value: $profile.customFatTarget, format: .number)
                    .keyboardType(.decimalPad)
                Button("Use Smart Calculator") {
                    profile.customCalorieTarget = nil
                    profile.customProteinTarget = nil
                    profile.customCarbTarget = nil
                    profile.customFatTarget = nil
                }
            }

            Section("Privacy") {
                Toggle("Local-only mode", isOn: $profile.localOnlyMode)
                Toggle("Enable AI features", isOn: $profile.aiEnabled)
                Toggle("Enable Apple Health sync", isOn: $profile.appleHealthEnabled)
                Text("API keys stay in the iOS Keychain. Nutrition, medication, and weight logs are stored locally with iOS data protection.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Notifications") {
                Toggle("Meal reminders", isOn: $profile.mealReminderEnabled)
                Toggle("Protein reminders", isOn: $profile.proteinReminderEnabled)
                Toggle("Weigh-in reminders", isOn: $profile.weighInReminderEnabled)
                Toggle("Medication reminders", isOn: $profile.medicationReminderEnabled)
                Toggle("Hydration reminders", isOn: $profile.hydrationReminderEnabled)

                Button("Refresh Notification Schedule") {
                    container.save()
                    Task { await viewModel.refreshNotifications(profile: profile) }
                }
            }

            Section("Anthropic API") {
                SecureField(viewModel.hasAPIKey ? "API key saved" : "Paste API key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button(viewModel.hasAPIKey ? "Replace API Key" : "Save API Key") {
                    guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    viewModel.saveAPIKey(apiKey)
                    apiKey = ""
                }

                if viewModel.hasAPIKey {
                    Button("Remove API Key", role: .destructive) {
                        viewModel.deleteAPIKey()
                    }
                }
            }

            Section("Data") {
                if let exportURL = viewModel.exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share Latest Export", systemImage: "square.and.arrow.up")
                    }
                }

                Button("Export Data") {
                    viewModel.exportData()
                }

                Button("Delete All Data", role: .destructive) {
                    showDeleteAlert = true
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(BrandBackdrop())
        .navigationTitle("Settings")
        .onDisappear {
            profile.updatedAt = .now
            container.save()
        }
        .alert("Delete all data?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes local foods, logs, weights, medication schedules, and the saved API key.")
        }
        .alert("Settings Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
