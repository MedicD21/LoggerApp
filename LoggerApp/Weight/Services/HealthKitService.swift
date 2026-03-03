import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

struct HealthKitService {
    #if canImport(HealthKit)
    private let store = HKHealthStore()
    #endif

    var isAvailable: Bool {
        #if canImport(HealthKit)
        HKHealthStore.isHealthDataAvailable()
        #else
        false
        #endif
    }

    func requestAuthorization() async throws {
        #if canImport(HealthKit)
        guard isAvailable,
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw AppError.featureDisabled("Apple Health")
        }

        try await store.requestAuthorization(toShare: [weightType], read: [weightType])
        #else
        throw AppError.featureDisabled("Apple Health")
        #endif
    }

    func saveWeight(kilograms: Double) async throws {
        #if canImport(HealthKit)
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw AppError.featureDisabled("Apple Health")
        }

        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kilograms)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: .now, end: .now)
        try await store.save(sample)
        #else
        throw AppError.featureDisabled("Apple Health")
        #endif
    }
}

