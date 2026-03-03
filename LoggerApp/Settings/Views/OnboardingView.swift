import SwiftUI

struct OnboardingView: View {
    let container: AppContainer

    @StateObject private var viewModel: SettingsViewModel
    @State private var weightPounds = 180.8
    @State private var heightFeet = 5
    @State private var heightInches = 10
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
                    BrandMarkView(size: 88)
                        .padding(.bottom, 6)
                    Text("Private nutrition tracking, built for fast daily use.")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.brandInk)
                    Text("Set the baseline once. Everything else can be adjusted later in Settings.")
                        .font(.subheadline)
                        .foregroundStyle(Color.brandMuted)
                }

                Form {
                    Section("Profile") {
                        TextField("Weight (lb)", value: $weightPounds, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                        HStack {
                            TextField("Height (ft)", value: $heightFeet, format: .number)
                                .keyboardType(.numberPad)
                            TextField("Height (in)", value: $heightInches, format: .number)
                                .keyboardType(.numberPad)
                        }
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
                .scrollDismissesKeyboard(.immediately)
                .background(Color.clear)
                .frame(maxHeight: 380)
                .brandPanel(cornerRadius: 28)

                Button("Continue") {
                    viewModel.completeOnboarding(
                        weightKg: UnitConverter.kilograms(fromPounds: weightPounds),
                        heightCm: UnitConverter.centimeters(feet: max(heightFeet, 0), inches: max(heightInches, 0)),
                        ageYears: ageYears,
                        sex: sex,
                        activityLevel: activityLevel,
                        goal: goal
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(24)
            .background(BrandBackdrop())
            .keyboardDoneToolbar()
        }
    }
}
