import Foundation

/// Enqueue snapshots synchronously; a shared serial queue preserves their order.
nonisolated final class WorkoutFileWriter: Sendable {
    private static let queue = DispatchQueue(label: "Frigo.workout.persistence", qos: .utility)

    func save(_ data: Data, to url: URL) {
        Self.queue.async {
            do {
                try data.write(to: url, options: [.atomic, .completeFileProtection])
            } catch {
                print("Impossibile salvare su disco (\(url.lastPathComponent)): \(error.localizedDescription)")
            }
        }
    }

    /// Wait until all previously enqueued writes have finished.
    func flush() async {
        await withCheckedContinuation { continuation in
            Self.queue.async { continuation.resume() }
        }
    }
}
