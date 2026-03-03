import Foundation
import UserNotifications

struct NotificationManager {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async throws {
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        guard granted else { throw AppError.notificationsDenied }
    }

    func refreshNotifications(profile: UserProfile, medication: MedicationSchedule?) async throws {
        try await requestAuthorization()
        await center.removeAllPendingNotificationRequests()

        if profile.mealReminderEnabled {
            await scheduleDaily(
                identifier: "meal-reminder",
                title: "Log meals",
                body: "Capture today’s meals while details are still fresh.",
                hour: 19
            )
        }

        if profile.proteinReminderEnabled {
            await scheduleDaily(
                identifier: "protein-reminder",
                title: "Protein check",
                body: "Protein is easiest to recover before dinner, not after.",
                hour: 16
            )
        }

        if profile.weighInReminderEnabled {
            await scheduleDaily(
                identifier: "weigh-in-reminder",
                title: "Weigh-in",
                body: "A consistent morning weigh-in keeps trends useful.",
                hour: 7
            )
        }

        if profile.hydrationReminderEnabled {
            await scheduleDaily(
                identifier: "hydration-reminder",
                title: "Hydration",
                body: "A quick water check-in supports appetite and recovery.",
                hour: 14
            )
        }

        if profile.medicationReminderEnabled, let medication {
            await scheduleMedicationNotifications(for: medication)
        }
    }

    func scheduleMedicationNotifications(for schedule: MedicationSchedule) async {
        await scheduleOneTime(
            identifier: "glp1-24h",
            title: "GLP-1 reminder",
            body: "\(schedule.medicationName) is due in 24 hours.",
            date: schedule.nextDueDate.adding(hours: -24)
        )

        await scheduleOneTime(
            identifier: "glp1-2h",
            title: "GLP-1 reminder",
            body: "\(schedule.medicationName) is due in 2 hours.",
            date: schedule.nextDueDate.adding(hours: -2)
        )

        await scheduleOneTime(
            identifier: "glp1-missed",
            title: "Dose not logged",
            body: "Your scheduled \(schedule.medicationName) dose has not been logged yet.",
            date: schedule.nextDueDate.adding(hours: 12)
        )

        if schedule.remainingDoses <= schedule.refillReminderThreshold {
            await scheduleOneTime(
                identifier: "glp1-refill",
                title: "Refill reminder",
                body: "Your \(schedule.medicationName) supply is running low.",
                date: Date().adding(hours: 9)
            )
        } else {
            await scheduleOneTime(
                identifier: "glp1-refill-advance",
                title: "Refill reminder",
                body: "Review your \(schedule.medicationName) supply before the next cycle.",
                date: schedule.nextDueDate.adding(days: -schedule.refillReminderDaysAhead)
            )
        }
    }

    private func scheduleDaily(identifier: String, title: String, body: String, hour: Int) async {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func scheduleOneTime(identifier: String, title: String, body: String, date: Date) async {
        guard date > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(60, date.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }
}

