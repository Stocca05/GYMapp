import Foundation

nonisolated struct A: Sendable {
    nonisolated struct B: Sendable {}
}
