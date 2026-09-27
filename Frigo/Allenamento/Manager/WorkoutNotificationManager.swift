import Foundation
import UserNotifications

final class WorkoutNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = WorkoutNotificationManager()

    private enum Identifier {
        static let restCompletion = "workout.rest-completion"
    }

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    func configure() {
        notificationCenter.delegate = self
    }

    func scheduleRestCompletion(at endDate: Date) async {
        let settings = await notificationCenter.notificationSettings()
        guard !Task.isCancelled else { return }

        let isAuthorized: Bool
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            isAuthorized = true
        case .notDetermined:
            do {
                isAuthorized = try await notificationCenter.requestAuthorization(
                    options: [.alert, .sound]
                )
            } catch {
                return
            }
        case .denied:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }

        guard isAuthorized, !Task.isCancelled else { return }

        cancelRestCompletion()

        let content = UNMutableNotificationContent()
        content.title = "Recupero terminato"
        content.body = "È il momento della prossima serie."
        content.sound = .default
        content.categoryIdentifier = Identifier.restCompletion

        let interval = max(1, endDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Identifier.restCompletion,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Impossibile programmare la notifica del recupero: \(error.localizedDescription)")
        }
    }

    func cancelRestCompletion() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [Identifier.restCompletion]
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
