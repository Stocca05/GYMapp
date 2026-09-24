import SwiftUI
import UIKit

/// Mostra una miniatura PNG o un placeholder semantico per categoria.
struct ProductThumbnailView: View {
    let data: Data?
    let category: ProductCategory

    /// Disegna la miniatura pronta per il display senza bloccare la lista.
    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(systemName: symbol).font(.title2).foregroundStyle(.secondary) }
        }
        .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityHidden(true)
    }

    private var symbol: String { switch category { case .vegetables: "leaf.fill"; case .fruits: "apple.logo"; case .dairy: "drop.fill"; case .beverages: "cup.and.saucer.fill"; default: "fork.knife" } }
}
