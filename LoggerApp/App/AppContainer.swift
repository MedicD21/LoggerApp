import Foundation
import OSLog
import SwiftData

@MainActor
final class AppContainer: ObservableObject {
    let logger = Logger(subsystem: "LoggerApp", category: "AppContainer")
    let modelContainer: ModelContainer
    let keychain = KeychainService()
    let notificationManager = NotificationManager()
    let healthKitService = HealthKitService()

    let genericFoodDatabase: GenericFoodDatabase
    let offClient: OFFClient
    let usdaClient: USDAClient
    let anthropicClient: AnthropicClient

    let foodRepository: FoodRepository
    let logRepository: LogRepository
    let weightRepository: WeightRepository
    let medicationRepository: MedicationRepository
    let aiRepository: AIRepository

    init() {
        let schema = Schema([
            FoodItem.self,
            FoodLog.self,
            LoggedFood.self,
            WeightEntry.self,
            MedicationSchedule.self,
            MedicationDose.self,
            UserProfile.self,
        ])

        self.modelContainer = Self.makeContainer(schema: schema)
        let context = modelContainer.mainContext

        self.genericFoodDatabase = GenericFoodDatabase()
        self.offClient = OFFClient()
        self.usdaClient = USDAClient(keychain: keychain)
        self.anthropicClient = AnthropicClient(keychain: keychain)
        self.foodRepository = FoodRepository(
            modelContext: context,
            genericDatabase: genericFoodDatabase,
            offClient: offClient,
            usdaClient: usdaClient
        )
        self.logRepository = LogRepository(modelContext: context)
        self.weightRepository = WeightRepository(
            modelContext: context,
            healthKitService: healthKitService
        )
        self.medicationRepository = MedicationRepository(
            modelContext: context,
            notificationManager: notificationManager
        )
        self.aiRepository = AIRepository(client: anthropicClient)
    }

    var modelContext: ModelContext {
        modelContainer.mainContext
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save context: \(String(describing: error), privacy: .public)")
        }
    }

    private static func makeContainer(schema: Schema) -> ModelContainer {
        let logger = Logger(subsystem: "LoggerApp", category: "Persistence")
        let fm = FileManager.default
        let directory = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LoggerApp", isDirectory: true)
        let storeURL = directory.appendingPathComponent("LoggerApp.store")

        do {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            try fm.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: directory.path)
            let configuration = ModelConfiguration(url: storeURL)
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            logger.error("Persistent store unavailable, falling back to in-memory container: \(String(describing: error), privacy: .public)")
            let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: fallback)
        }
    }
}
