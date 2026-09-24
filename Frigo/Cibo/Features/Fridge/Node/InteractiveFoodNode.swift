import SwiftUI

/// Scheda alimento con quantità, confezioni e prima scadenza ben distinte.
struct InteractiveFoodNode: View {
    let group: StockGroup
    let product: ProductSnapshot?
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                if !typeSize.isAccessibilitySize {
                    ProductThumbnailView(data: product?.thumbnailPNG, category: product?.category ?? .other)
                        .frame(width: 60, height: 60)
                        .background(group.id.location.foodTint.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(product?.name ?? "Prodotto")
                        .font(.headline).foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(group.totalQuantity) \(group.representative.key.unit.abbreviation)")
                        .font(.title3.weight(.semibold)).monospacedDigit().foregroundStyle(.primary)
                    Text(packageLabel).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                    .padding(.top, 4).accessibilityHidden(true)
            }
            ViewThatFits(in: .horizontal) {
                HStack { expiryBadge; Spacer(minLength: 8); expiryDate }
                VStack(alignment: .leading, spacing: 8) { expiryBadge; expiryDate }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
        .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(Color.primary.opacity(0.045)) }
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    private var expiryBadge: some View {
        Label(freshnessLabel, systemImage: freshnessSymbol)
            .font(.caption.weight(.semibold)).foregroundStyle(freshnessColor)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(freshnessColor.opacity(0.1), in: Capsule())
    }
    private var expiryDate: some View {
        Text("\(group.count > 1 ? "Prima scadenza" : "Scadenza") \(group.representative.expirationDate.formatted(.dateTime.day().month(.abbreviated)))")
            .font(.caption).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
    private var packageLabel: String {
        if group.representative.key.unit == .pieces { return group.count == 1 ? "1 pezzo disponibile" : "\(group.count) pezzi disponibili" }
        return group.count == 1 ? "1 confezione disponibile" : "\(group.count) confezioni disponibili"
    }
    private var freshness: FreshnessState { ExpirationPolicy.freshness(until: group.representative.expirationDate, from: Date(), calendar: .current) }
    private var freshnessSymbol: String { switch freshness { case .fresh: "checkmark.circle"; case .expiringSoon: "clock"; case .expired: "exclamationmark.circle" } }
    private var freshnessColor: Color { switch freshness { case .fresh: .teal; case .expiringSoon: .orange; case .expired: .red } }
    private var freshnessLabel: String { switch freshness { case .fresh: "In scorta"; case .expiringSoon: "In scadenza"; case .expired: "Scaduto" } }
}
