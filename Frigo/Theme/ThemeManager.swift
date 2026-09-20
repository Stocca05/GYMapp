import SwiftUI
import Observation

@Observable
final class ThemeManager {
    var currentTheme: AppTheme = .defaultTheme
}