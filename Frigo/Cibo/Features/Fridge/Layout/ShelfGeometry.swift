import CoreGraphics

/// Concentra la matematica deterministica del posizionamento su scaffali.
nonisolated struct ShelfGeometry {
    let width: CGFloat
    let shelfCount: Int
    let shelfHeight: CGFloat

    /// Crea una geometria sicura anche con input degeneri.
    init(width: CGFloat, shelfCount: Int, shelfHeight: CGFloat = 140) { self.width = width.isFinite ? max(width, 0) : 0; self.shelfCount = max(shelfCount, 0); self.shelfHeight = shelfHeight.isFinite ? max(shelfHeight, 1) : 1 }

    /// Altezza totale dei ripiani.
    var totalHeight: CGFloat { CGFloat(shelfCount) * shelfHeight }

    /// Restituisce la baseline del ripiano richiesto.
    func baselineY(shelfIndex: Int) -> CGFloat { CGFloat(min(max(shelfIndex, 0), max(shelfCount - 1, 0)) + 1) * shelfHeight }

    /// Calcola un frame completamente contenuto nello scaffale.
    func frame(for placement: ShelfPlacement, nodeSize: CGSize) -> CGRect { let size = CGSize(width: min(max(nodeSize.width, 0), width), height: min(max(nodeSize.height, 0), shelfHeight)); let x = min(max(CGFloat(placement.xFraction.isFinite ? placement.xFraction : 0) * width - size.width / 2, 0), max(width - size.width, 0)); return CGRect(x: x, y: baselineY(shelfIndex: placement.shelfIndex) - size.height, width: size.width, height: size.height) }

    /// Converte un punto finale di drag nella posizione magnetica più vicina.
    func snap(bottomCenter: CGPoint, nodeSize: CGSize) -> ShelfPlacement { let index = shelfCount == 0 ? 0 : min(max(Int((bottomCenter.y / shelfHeight).rounded(.down)), 0), shelfCount - 1); let fraction = width == 0 ? 0 : min(max(Double(bottomCenter.x / width), 0), 1); return ShelfPlacement(shelfIndex: index, xFraction: fraction, depth: 0) }
}
