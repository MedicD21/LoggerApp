import SwiftUI

struct OnboardingView: View {
    let container: AppContainer

    @StateObject private var viewModel: SettingsViewModel
    @State private var weightKg = 82.0
    @State private var heightCm = 178.0
    @State private var ageYears = 35
    @State private var sex: BiologicalSex = .male
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var goal: NutritionGoal = .maintain

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: SettingsViewModel(container: container))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 22) {
                Spacer(minLength: 20)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Private nutrition tracking, built for fast daily use.")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Set the baseline once. Everything else can be adjusted later in Settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Form {
                    Section("Profile") {
                        TextField("Weight (kg)", value: $weightKg, format: .number)
                            .keyboardType(.decimalPad)
                        TextField("Height (cm)", value: $heightCm, format: .number)
                            .keyboardType(.decimalPad)
                        Stepper("Age: \(ageYears)", value: $ageYears, in: 18...100)
                        Picker("Sex", selection: $sex) {
                            ForEach(BiologicalSex.allCases) { value in
                                Text(value.rawValue.capitalized).tag(value)
                            }
                        }
                        Picker("Activity", selection: $activityLevel) {
                            ForEach(ActivityLevel.allCases) { value in
                                Text(value.title).tag(value)
                            }
                        }
                        Picker("Goal", selection: $goal) {
                            ForEach(NutritionGoal.allCases) { value in
                                Text(value.rawValue.capitalized).tag(value)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(maxHeight: 380)

                Button("Continue") {
                    viewModel.completeOnboarding(
                        weightKg: weightKg,
                        heightCm: heightCm,
                        ageYears: ageYears,
                        sex: sex,
                        activityLevel: activityLevel,
                        goal: goal
                    )
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Color.brandBackground, Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
    }
}

