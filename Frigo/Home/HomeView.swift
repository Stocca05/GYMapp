import SwiftUI

struct HomeView: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        NavigationStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
                .navigationTitle("")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: ProfileView()) {
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
        .environment(ThemeManager())
}