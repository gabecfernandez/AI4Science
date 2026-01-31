@preconcurrency import SwiftUI

extension ProjectStatus {
    /// Status indicator color. Values are inlined to avoid pulling in ColorPalette's
    /// UIColor-based adaptive properties, which carry @MainActor isolation in Swift 6.
    public nonisolated var color: Color? {
        switch self {
        case .draft:      return Color(red: 0.50, green: 0.50, blue: 0.50)   // neutral_600
        case .active:     return Color(red: 0.051, green: 0.588, blue: 0.322) // success
        case .paused:     return Color(red: 1.0, green: 0.757, blue: 0.027)   // warning
        case .completed:  return Color(red: 0.004, green: 0.443, blue: 0.663) // utsa_primary
        case .archived:   return Color(red: 0.627, green: 0.627, blue: 0.627) // neutral_500
        }
    }
}
