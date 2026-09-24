import Foundation
import os

/// Espone i logger condivisi dal modulo Cibo.
enum CiboLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.frigo.cibo"

    /// Logger per operazioni di persistenza o per log generici in sostituzione ai print.
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
}
