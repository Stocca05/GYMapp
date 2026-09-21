import SwiftUI

struct FoodView: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        themeManager.currentTheme.backgroundColor
            .ignoresSafeArea()
    }
}

#Preview {
    FoodView()
        .environment(ThemeManager())
}