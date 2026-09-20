import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            Color.white
                .ignoresSafeArea()
                .navigationTitle("")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {}) {
                            Image(systemName: "person.crop.circle")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
        }
    }
}

#Preview {
    HomeView()
}