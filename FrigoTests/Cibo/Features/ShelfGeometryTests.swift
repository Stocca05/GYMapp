import CoreGraphics
import Testing
@testable import Frigo

/// Verifica la geometria pura usata dagli scaffali.
struct ShelfGeometryTests {
    /// Verifica che il frame rimanga sempre nello scaffale.
    @Test func frameIsClampedToShelfBounds() {
        let geometry = ShelfGeometry(width: 200, shelfCount: 4)
        let frame = geometry.frame(for: ShelfPlacement(shelfIndex: 99, xFraction: 2, depth: 0), nodeSize: CGSize(width: 80, height: 100))
        #expect(frame.minX >= 0); #expect(frame.maxX <= 200); #expect(frame.maxY == geometry.totalHeight)
    }

    /// Verifica che gli input degeneri non generino coordinate non finite.
    @Test func degenerateGeometryIsSafe() {
        let geometry = ShelfGeometry(width: .nan, shelfCount: -2)
        let placement = geometry.snap(bottomCenter: CGPoint(x: CGFloat.infinity, y: CGFloat.nan), nodeSize: .zero)
        #expect(geometry.totalHeight == 0); #expect(placement.shelfIndex == 0); #expect(placement.xFraction == 0)
    }
}
