import SwiftUI

struct AppTheme: Equatable {
    let primaryColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
    let textColor: Color
}

extension AppTheme {
    static let defaultTheme = AppTheme(
        primaryColor: .blue,
        secondaryColor: .secondary,
        backgroundColor: Color(uiColor: .systemBackground),
        textColor: .primary
    )
}