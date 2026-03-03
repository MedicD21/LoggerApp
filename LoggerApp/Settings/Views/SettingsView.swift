import SwiftUI

struct SettingsView: View {
    let container: AppContainer
    @Bindable var profile: UserProfile

    @StateObject private var viewModel: SettingsViewModel
    @State private var apiKey = ""
    @State private var usdaAPIKey = ""
    @State private var showDeleteAlert = false

    init(container: AppContainer, profile: UserProfile) {
        self.container = container
        self.profile = profile
        _viewModel = StateObject(wrappedValue: SettingsViewModel(container: container))
    }

    var body: some View {
        Form {
            Section("Smart Calculator Inputs") {
                TextField("Weight (lb)", value: weightPoundsBinding, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)

                HStack {
                    TextField("Height (ft)", value: heightFeetBinding, format: .number)
                        .keyboardType(.numberPad)
                    TextField("Height (in)", value: heightInchesBinding, format: .number)
                        .keyboardType(.numberPad)
                }

                Stepper("Age: \(profile.ageYears)", value: $profile.ageYears, in: 18...100)

                Picker("Sex", selection: sexBinding) {
                    ForEach(BiologicalSex.allCases) { sex in
                        Text(sex.rawValue.capitalized).tag(sex)
                    }
                }

                Picker("Activity", selection: activityLevelBinding) {
                    ForEach(ActivityLevel.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }

                Picker("Goal", selection: goalBinding) {
                    ForEach(NutritionGoal.allCases) { goal in
                        Text(goal.rawValue.capitalized).tag(goal)
                    }
                }
            }

            Section("Smart Calculator") {
                LabeledContent("BMR", value: "\(Int(profile.bmrValue.rounded())) kcal")
                LabeledContent("TDEE", value: "\(Int(profile.tdeeValue.rounded())) kcal")
                LabeledContent("Calories", value: "\(Int(profile.smartCalculatedTargets.calories.rounded()))")
                LabeledContent("Protein", value: "\(Int(profile.smartCalculatedTargets.proteinGrams.rounded())) g")
                LabeledContent("Carbs", value: "\(Int(profile.smartCalculatedTargets.carbGrams.rounded())) g")
                LabeledContent("Fat", value: "\(Int(profile.smartCalculatedTargets.fatGrams.rounded())) g")

                Button(profile.usesCustomTargets ? "Use Smart Calculator Targets" : "Smart Calculator Active") {
                    profile.customCalorieTarget = nil
                    profile.customProteinTarget = nil
                    profile.customCarbTarget = nil
                    profile.customFatTarget = nil
                }
                .disabled(!profile.usesCustomTargets)
            }

            Section("Custom Macro Overrides") {
                TextField("Calories", value: $profile.customCalorieTarget, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.numberPad)
                TextField("Protein (g)", value: $profile.customProteinTarget, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                TextField("Carbs (g)", value: $profile.customCarbTarget, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                TextField("Fat (g)", value: $profile.customFatTarget, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                Text("Leave these blank to use the smart calculator. Enter all four to override it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

            Section("USDA FoodData Central") {
                SecureField(
                    viewModel.hasUSDAAPIKey ? "Custom API key saved" : "Optional: paste USDA API key",
                    text: $usdaAPIKey
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button(viewModel.hasUSDAAPIKey ? "Replace USDA API Key" : "Save USDA API Key") {
                    guard !usdaAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    viewModel.saveUSDAAPIKey(usdaAPIKey)
                    usdaAPIKey = ""
                }

                if viewModel.hasUSDAAPIKey {
                    Button("Remove USDA API Key", role: .destructive) {
                        viewModel.deleteUSDAAPIKey()
                    }
                }

                Text(
                    viewModel.usingUSDAFallbackKey
                    ? "USDA search is active with DEMO_KEY. Add your own key for production throughput."
                    : "USDA search is active with your saved API key."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
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
        .scrollDismissesKeyboard(.immediately)
        .background(BrandBackdrop())
        .navigationTitle("Settings")
        .keyboardDoneToolbar()
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

    private var weightPoundsBinding: Binding<Double> {
        Binding(
            get: { profile.weightPounds },
            set: { profile.weightKg = UnitConverter.kilograms(fromPounds: max(0, $0)) }
        )
    }

    private var heightFeetBinding: Binding<Int> {
        Binding(
            get: { profile.heightFeetAndInches.feet },
            set: { newFeet in
                let inches = profile.heightFeetAndInches.inches
                profile.heightCm = UnitConverter.centimeters(feet: max(0, newFeet), inches: inches)
            }
        )
    }

    private var heightInchesBinding: Binding<Int> {
        Binding(
            get: { profile.heightFeetAndInches.inches },
            set: { newInches in
                let normalizedFeet = profile.heightFeetAndInches.feet + max(0, newInches) / 12
                let normalizedInches = max(0, newInches) % 12
                profile.heightCm = UnitConverter.centimeters(feet: normalizedFeet, inches: normalizedInches)
            }
        )
    }

    private var sexBinding: Binding<BiologicalSex> {
        Binding(
            get: { profile.sex },
            set: { profile.sex = $0 }
        )
    }

    private var activityLevelBinding: Binding<ActivityLevel> {
        Binding(
            get: { profile.activityLevel },
            set: { profile.activityLevel = $0 }
        )
    }

    private var goalBinding: Binding<NutritionGoal> {
        Binding(
            get: { profile.goal },
            set: { profile.goal = $0 }
        )
    }
}
