import SwiftUI

struct ProfileView: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        themeManager.currentTheme.backgroundColor
            .ignoresSafeArea()
            .navigationTitle("Profilo")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
        .environment(ThemeManager())
}